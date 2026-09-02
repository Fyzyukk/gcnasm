# Early C store on the current full stack

This independently revalidates the historical `MXFP8_EARLY_C_STORE` result
on the current unified-scale stack:

- no `s_setprio`;
- output B1 handoff p18 (`MXFP8_OUTPUT_B1_HANDOFF_PAIRS=1`, 18/14);
- linked-assembly `ctrl_fill` scheduling.

The reference and candidate are generated from the same local template and
then receive the same `ctrl_fill` patch.  The candidate moves the finalized
`C[0][0]` and `C[1][0]` quadrants (16 VMEM stores) ahead of the p18 handoff and
changes that handoff wait from `vmcnt(0)` to the exact `vmcnt(16)`.

## Result

Retain.  On GPU7, the candidate won all eight paired rounds and improved the
geometric mean by `+0.3371%`:

| Round | Reference (ms) | Early store (ms) | Gain |
| ---: | ---: | ---: | ---: |
| 1 | 0.456350 | 0.454850 | +0.3298% |
| 2 | 0.456800 | 0.456050 | +0.1645% |
| 3 | 0.457550 | 0.456400 | +0.2520% |
| 4 | 0.458400 | 0.456200 | +0.4822% |
| 5 | 0.458600 | 0.455600 | +0.6585% |
| 6 | 0.457850 | 0.455550 | +0.5049% |
| 7 | 0.457450 | 0.456600 | +0.1862% |
| 8 | 0.457450 | 0.456900 | +0.1204% |

```text
reference mean/gmean/median = 0.457556 / 0.457556 / 0.457550 ms
early mean/gmean/median     = 0.456019 / 0.456018 / 0.456150 ms
geometric gain             = +0.3371%
median gain                = +0.3069%
paired wins                = 8/8
```

The run used the unified-scale executable at `8192x8192x8192`, batch 1,
`-w 1000 -i 500`, and `HIP_VISIBLE_DEVICES=7`.

## Static and correctness gates

Both variants were rebuilt with
`/opt/rocm-llvm23-46fcb339/bin/clang++` for `gfx950`, with OPUS headers from
`/root/workspace/aiter/csrc/include`.

```text
                     reference   early store
instructions              1594          1593
s_nop                       101           100
MFMA                        192           192
waitcnt                      50            50
barrier                       7             7
direct-to-LDS loads          91            91
global stores                32            32
VGPR / SGPR             240 / 101     240 / 101
spill / scratch               0             0
```

The linked-ISA gate verified the candidate's handoff queue exactly as:

```text
[all required direct-to-LDS loads] [16 early stores] -> vmcnt(16) -> barrier
```

VMEM retires in order, so `vmcnt(16)` waits for every older handoff load while
allowing the 16 younger stores to remain outstanding.  There is no younger
direct-to-LDS load between the stores and the wait.  The source reference also
matched the retained p18 linked instruction stream.

Reference and candidate both reported `[Overall] ALL BATCHES VALID` for all
seven checks, including `8192x512x16384`:

```text
256x256x128 batch2
256x512x256
512x512x512
768x512x1024
1024x512x1024
1280x768x384
8192x512x16384
```

The raw timing file used for this historical measurement was a local
experiment artifact and is not part of the MI355X validation bundle.

## Reproduction

```bash
./build.sh
```

The shipped end-to-end correctness and performance driver is
`../mi355_3p_validation/run_mi355.sh`; this candidate is `05_early_c`.
