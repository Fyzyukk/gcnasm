# Combined winner validation

Independent clang23 validation of the two retained positive changes for the
unified-scale gfx950 kernel:

1. remove all uniform `s_setprio` calls;
2. move the persistent-output B1 handoff to
   `MXFP8_OUTPUT_B1_HANDOFF_PAIRS=1` (18/14 split).

The directory builds four fresh controls from the same host:

- `retained`: original retained template with `s_setprio`;
- `noprio`: original retained template with only `s_setprio` removed;
- `p8`: no-setprio output-handoff 32/0 control;
- `combined`: no-setprio output-handoff winner at 18/14.

All compilation is pinned to `/opt/rocm-llvm23-46fcb339/bin/clang++` and
`/root/workspace/aiter/csrc/include`.

Run:

```bash
./build.sh
```

The shipped end-to-end correctness and performance driver is
`../mi355_3p_validation/run_mi355.sh`; it exposes these stages as
`00_baseline`, `01_no_setprio`, `02_p8_control`, and `03_p18`.

## Fresh clang23 static gate

Compiler:

```text
clang version 23.0.0git
ROCm llvm-project 46fcb339fb61119b337f973c7ca9e710a319fdd0
```

| Binary | Instructions | MFMA | setprio | waitcnt | nop | Branch | VGPR | SGPR |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| retained | 1599 | 192 | 22 | 45 | 110 | 33 | 240 | 101 |
| noprio | 1582 | 192 | 0 | 50 | 110 | 33 | 240 | 101 |
| p8 | 1605 | 192 | 0 | 50 | 112 | 36 | 240 | 101 |
| combined | 1608 | 192 | 0 | 50 | 115 | 36 | 240 | 101 |

All four use 139264 bytes of LDS, contain 32 output stores and seven
barriers, and have zero VGPR spill, SGPR spill, scratch, and private segment.
The generated `noprio` source differs from the retained source by exactly the
six source-level `s_setprio` deletions.  LLVM regenerates the wait scheduling,
so the linked instruction difference is intentionally not limited to those
22 dynamically unrolled `s_setprio` instructions.

After removing disassembly headers and PC comments, the fresh `p8` and
`combined` instruction streams match the earlier independently built
`output_b1_overlap` p8 and p1 streams exactly.

## Correctness

All four binaries passed all six unified-scale cases, for 24 successful
binary/shape combinations:

```text
256x256x128 batch=2
256x512x256 batch=1
512x512x512 batch=1
768x512x1024 batch=1
1024x512x1024 batch=1
1280x768x384 batch=1
```

Every launch was made on GPU7 while holding
`flock /tmp/mxfp8_gpu7.lock`.

## Long steady-state ABBA

Shape `8192x8192x8192`, batch 1, unified-scale, `warmup=1000`,
`iterations=500`.  The complete 96-invocation run held the GPU7 lock for its
entire duration.  Each table entry is the mean of the two measurements for
that side of one `A-B-B-A` round.

### Removing `s_setprio`: retained versus noprio

| Round | retained ms | noprio ms | Throughput gain |
| ---: | ---: | ---: | ---: |
| 1 | 0.463800 | 0.461400 | +0.5202% |
| 2 | 0.465100 | 0.463150 | +0.4210% |
| 3 | 0.465500 | 0.463150 | +0.5074% |
| 4 | 0.466500 | 0.463450 | +0.6581% |
| 5 | 0.466500 | 0.462950 | +0.7668% |
| 6 | 0.466150 | 0.462750 | +0.7347% |
| 7 | 0.466450 | 0.463100 | +0.7234% |
| 8 | 0.466150 | 0.462400 | +0.8110% |

Geometric-mean times are `0.465768 / 0.462793 ms`; medians are
`0.466100 / 0.463100 ms`.  The geometric paired throughput gain is
**+0.6427%**, with **8/8 wins**.

### Handoff position: p8 (32/0) versus combined p1 (18/14)

| Round | p8 ms | combined ms | Throughput gain |
| ---: | ---: | ---: | ---: |
| 1 | 0.461850 | 0.461250 | +0.1301% |
| 2 | 0.463350 | 0.462500 | +0.1838% |
| 3 | 0.463650 | 0.462100 | +0.3354% |
| 4 | 0.463350 | 0.461700 | +0.3574% |
| 5 | 0.462650 | 0.461450 | +0.2600% |
| 6 | 0.463150 | 0.462500 | +0.1405% |
| 7 | 0.463200 | 0.461650 | +0.3358% |
| 8 | 0.462950 | 0.461600 | +0.2925% |

Geometric-mean times are `0.463018 / 0.461844 ms`; medians are
`0.463050 / 0.461700 ms`.  The geometric paired throughput gain is
**+0.2544%**, with **8/8 wins**.

### Complete stack: retained versus combined

| Round | retained ms | combined ms | Throughput gain |
| ---: | ---: | ---: | ---: |
| 1 | 0.464900 | 0.462150 | +0.5950% |
| 2 | 0.465100 | 0.462100 | +0.6492% |
| 3 | 0.466400 | 0.462600 | +0.8214% |
| 4 | 0.466500 | 0.461750 | +1.0287% |
| 5 | 0.466250 | 0.461850 | +0.9527% |
| 6 | 0.466550 | 0.462900 | +0.7885% |
| 7 | 0.466400 | 0.461400 | +1.0837% |
| 8 | 0.466550 | 0.461800 | +1.0286% |

Geometric-mean times are `0.466081 / 0.462069 ms`; medians are
`0.466350 / 0.462000 ms`.  The geometric paired throughput gain is
**+0.8683%**, with **8/8 wins**.  At this machine's observed clocks that is
approximately `2.3591 -> 2.3795 P`.

The independently measured gains are almost multiplicative:
`1.006427 * 1.002544 - 1 = +0.8987%`, only 0.0304 percentage point above the
direct combined measurement.  There is therefore no material negative
interaction between the two optimizations.

The raw timing file used for this historical measurement was a local
experiment artifact and is not part of the MI355X validation bundle.
