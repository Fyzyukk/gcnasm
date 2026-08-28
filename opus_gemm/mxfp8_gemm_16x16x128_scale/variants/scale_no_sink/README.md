# MXFP8_SCALE_NO_SINK — standalone A/B

Isolates one change to the retained winner
(`gemm_a8w8_mxfp8_scale_kernel_template_fixed_b_asym_b_read2.hpp`), so it can be
evaluated on a different machine / compiler without any other differences.

## The change

In the steady K-loop, the scale producer was:

```cpp
if (wave_id == 0) {
    async_load<16>(g_sfa, ...);       // buffer resource A
} else if (wave_id == 1) {
    async_load<16>(g_sfb, ...);       // buffer resource B
}
```

The `if / else-if` makes these two branches mutually exclusive, so they
reconverge into a single join block. The two arms use *different* buffer
resources, and under this kernel's register pressure (236 VGPR, occupancy 2)
the backend answers that by sinking one descriptor to scratch and reloading it
on every steady iteration:

```
.LBB0_16:                        ; %.sink.split.i.i
    scratch_load_dword v152, off, s24
    s_waitcnt vmcnt(0)               ; <-- drains ALL in-flight A/B prefetches
    buffer_load_dwordx4 v152, s[0:3], s24 offen lds
```

The `s_waitcnt vmcnt(0)` is the real cost. It is not there for the scale load —
it is the scratch reload's own dependency — but it waits on the *global* vmcnt
counter, so it also drains the outstanding A/B tile prefetches that the whole
pipeline depends on.

The fix emits the two requests as independent, non-exclusive predicated blocks
so each descriptor stays local to its own branch and neither is sunk:

```cpp
if (wave_id < 2) {
    const bool is_a = (wave_id == 0);
    if (is_a)  { async_load<16>(g_sfa, ...); }
    if (!is_a) { async_load<16>(g_sfb, ...); }
}
```

Semantics are identical — wave 0 issues sfa, wave 1 issues sfb, all other waves
issue nothing. Only the control-flow shape presented to the register allocator
changes.

## Build / run

```sh
./build.sh                # builds build/off.exe and build/on.exe
GPU=7 ROUNDS=10 ./bench.sh
```

Both binaries come from the same template; `on` adds only
`-DMXFP8_SCALE_NO_SINK=1`. `build.sh` prints the ISA `scratch_load` /
`s_waitcnt vmcnt(0)` counts for each.

## Measured here (gfx950, clang 20, GPU7, b=1, M=N=K=8192, best of N)

| build | time | perf |
|---|---:|---:|
| baseline (no unroll, no fix) | 0.4520 ms | 2.433 P |
| + manual unroll U=6 & A three-slot only | 0.4492 ms | 2.448 P |
| + NO_SINK only (no unroll) | 0.4495 ms | 2.447 P |
| **unroll U=6 + A three-slot + NO_SINK** | **0.4277 ms** | **2.572 P** |

**The two changes are not additive — they are multiplicative.** Alone each is
worth ~0.6%; together they are worth 5.7%. That is consistent with the
mechanism: the K-loop body is long enough that one drained prefetch queue per
iteration is partly absorbed, but once the loop is unrolled the pipeline depends
on prefetches staying in flight across iteration boundaries, and the `vmcnt(0)`
becomes the binding constraint.

ISA, unrolled build: `scratch_load` 9 → 4, `s_waitcnt vmcnt(0)` 34 → 20.

## What to expect on a clang-23 machine

clang 23 auto-unrolls the K-loop, so a clang-23 baseline is *already in the
unrolled regime*. If it also sinks the descriptor, this fix should give close to
the full ~5%, not the isolated 0.6%. Check the baseline ISA first:

```sh
grep -c scratch_load        build/isa_off.s
grep -c 's_waitcnt vmcnt(0)' build/isa_off.s
```

If `off` already shows no scratch reload inside the steady loop body, clang 23
avoided the spill on its own and this change will do nothing.
