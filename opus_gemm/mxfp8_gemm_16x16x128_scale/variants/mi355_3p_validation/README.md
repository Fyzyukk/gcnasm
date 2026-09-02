# MI355X 3P validation bundle

This directory is the single entry point for validating the current
`gfx950` unified-scale MXFP8 GEMM candidate on MI355X.  It keeps every
cumulative optimization stage as a separate executable so each change can be
measured against the immediately preceding version:

| Tag | Contents |
| --- | --- |
| `00_baseline` | Original clang23 unified-scale kernel used for the 2.913 P baseline |
| `01_no_setprio` | Remove `s_setprio` |
| `02_p8_control` | No-setprio control using the output-handoff implementation, 32/0 split |
| `03_p18` | Change that control to the retained 18/14 output handoff |
| `04_ctrl_fill` | Fill MFMA NOP slots with existing scalar control instructions |
| `05_early_c` | Add two-quadrant early-C stores and exact `vmcnt(16)` |
| `06_prera_top` | Add clang23 pre-RA top-down scheduling |
| `07_t2x16` | Add exact-8192 2x16 N-fast workgroup order |
| `08_agpr` | Add offset-112 full-C AGPR recoloring |

`02_p8_control` is an extra isolation control, not a claimed optimization.
The p18 number must be measured as `03_p18` versus `02_p8_control`; comparing
it directly with `01_no_setprio` would also include template-structure changes.

Every build is fixed to:

```text
/opt/rocm-llvm23-46fcb339/bin/clang++
gfx950
```

The build also needs the AITER OPUS headers.  The default path is
`/root/workspace/aiter/csrc/include`; override it with
`OPUS_INCLUDE_DIR=/path/to/aiter/csrc/include` if needed.  The validated local
AITER commit is `6df2316d1dea9b4cbb0200e5e939d41844b2655c`, and `build/manifest.txt`
records the actual commit and header hashes used by each rebuild.

Every GPU launch removes `MXFP8_UNIT_SCALE` from the environment and rejects
output that does not contain `unified scale producer`.

## Current evidence

The first two source changes were validated together, so their direct
combined result is used instead of multiplying their separate measurements.

| Retained change | Paired throughput gain | Evidence window |
| --- | ---: | --- |
| no `s_setprio` + p18 output handoff | +0.8683% | 8/8, w1000/i500 |
| `ctrl_fill` linked-ISA scheduling | +0.7062% | 8/8, w1000/i500 |
| two-quadrant early-C store + `vmcnt(16)` | +0.3371% | 8/8, w1000/i500 |
| clang23 pre-RA top-down scheduler | +0.15635% | 8/8, w1000/i500 |
| exact 2x16 N-fast block order | +0.0921% | 7/8, w1000/i500 |

The compounded six-change gain is `+2.1764%`, projecting the measured MI355X
baseline from `2.913 P` to `2.9764 P`.

Under the user-selected production screen of four ABBA rounds at
`warmup=200, iterations=100`, offset-112 AGPR recoloring adds `+1.1744%`
geometric throughput, `+0.8299%` median throughput, and wins 3/4 rounds.  The
conservative combined projection is therefore:

```text
2.913 P * 1.02176435 * 1.011744 = 3.01135 P
total projected gain = +3.3764%
```

The AGPR result must retain its qualification: its eight-round w1000/i500
result was `-0.0082%` (4/8), effectively neutral.  The MI355X direct ABBA in
this bundle is the authoritative decision point.

## Local package self-test

The complete bundle was freshly rebuilt with clang23 on 2026-09-02.  All
nine executables passed all eight shared unified-scale shapes; the retained
2x16 block-order path also passed an active `8192x8192x128` check.  A single-lock GPU7
matrix at w200/i100 then measured:

```text
07_t2x16 vs 00_baseline  +0.9885%, 4/4
08_agpr vs 07_t2x16      +0.3703%, 4/4
08_agpr vs 00_baseline   +0.4133%, 2/4

aggregate absolute geometric means:
00_baseline   2.68865 P
07_t2x16      2.70761 P
08_agpr       2.71299 P
```

A separate direct-only four-round ABBA immediately before the matrix measured
`08_agpr` versus `00_baseline` at `-0.0184%` (3/4), with `2.70558 P` versus
`2.70529 P`.  Thus the direct total signal on this MI350-class host ranges
from neutral to roughly +0.4%, despite both adjacent matrix comparisons
winning 4/4.  The cross-run compounded projection is not a direct result.
Therefore `3.01135 P` is a MI355X target, not a completed measurement.
Promotion should be based on the MI355X
`08_agpr_vs_00_baseline_gpu*_w200_i100.summary.txt` result produced by this
bundle.

## One-command MI355X run

From this directory, select the physical GPU and run:

```bash
GPU=0 ./run_mi355.sh
```

The command performs:

1. fresh clang23 builds of all eight cumulative stages plus the p8 control;
2. eight shared unified-scale correctness shapes for all nine executables,
   plus an active `8192x8192x128` block-order check for `07_t2x16` and
   `08_agpr`;
3. seven adjacent four-round ABBA comparisons at w200/i100;
4. a final direct `00_baseline` versus `08_agpr` ABBA comparison.

Use `QUICK=1` to run only the direct total ABBA after correctness, or
`REBUILD=0` to reuse an already verified local build:

```bash
GPU=0 QUICK=1 ./run_mi355.sh
GPU=0 REBUILD=0 ./run_mi355.sh
```

Results are written under `results/`.  Each comparison produces raw `.tsv`,
kernel `.log`, and `.summary.txt` files.  The summary contains geometric and
median gains, paired-round wins, geometric-mean milliseconds and PFlop/s,
and an explicit `PASS_3P` or `BELOW_3P` line.

To run only one adjacent comparison after building, select the two tags
explicitly.  For example, this measures only the AGPR step:

```bash
GPU=0 REF=07_t2x16 CANDIDATE=08_agpr \
  WARMUP=200 ITERS=100 ROUNDS=4 ./bench.sh
```

Use these isolated pairs for the seven changes:

```text
00_baseline   -> 01_no_setprio
02_p8_control -> 03_p18
03_p18        -> 04_ctrl_fill
04_ctrl_fill  -> 05_early_c
05_early_c    -> 06_prera_top
06_prera_top  -> 07_t2x16
07_t2x16      -> 08_agpr
```

The candidate to promote after a successful MI355X run is:

```text
build/08_agpr.exe
```
