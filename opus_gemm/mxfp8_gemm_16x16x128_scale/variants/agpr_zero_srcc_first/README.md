# AGPR zero-SrcC first-K variant

This is an isolated unified-scale gfx950 experiment built on the retained
clang23 + top-down pre-RA + `ctrl_fill` + exact block-order + direct-AGPR-store
stack (`variants/agpr_isa_recolor/agpr_recolor`).

The gfx950 scaled MFMA accepts literal `0` as SrcC.  This variant removes the
128 `v_accvgpr_write_b32` instructions on the main-loop entry path and routes
that path through a cold clone of the first K-tile body whose 32 MFMAs use
SrcC `0`.  The normal body remains unchanged for every later K tile, so the
accumulator is reset exactly once.

Linked-image invariants:

```text
112 VGPR + 128 AGPR, 101 SGPR
0 spill, 0 scratch/private, 139264-byte LDS
32 zero-SrcC MFMAs in the entry clone
256 remaining static AGPR clear writes
32 direct AGPR stores
```

All GPU commands unset `MXFP8_UNIT_SCALE`, require the `unified scale
producer` banner, and serialize GPU7 with `/tmp/mxfp8_gpu7.lock` by default.
The nine-shape correctness suite passed, including batch 2, K=128, K=16384,
multiple N tiles, and persistent/tail output cases.

On the local MI350X, `8192^3`, batch 1, warmup 200, iterations 100:

```text
4-round ABBA:  +1.3728% geometric, +1.1921% median, 4/4 wins
12-round ABBA: +0.2511% geometric, +0.3343% median, 7/12 wins
```

The longer run is the conservative result.  This is a positive candidate
under the requested w200/i100 screen, but MI355X must be measured directly.

Build and run:

```bash
cd opus_gemm/mxfp8_gemm_16x16x128_scale/variants/agpr_zero_srcc_first
./build.sh
GPU=7 ./correctness.sh
GPU=7 WARMUP=200 ITERS=100 ROUNDS=4 ./bench.sh
```

The build is fixed to:

```text
/opt/rocm-llvm23-46fcb339/bin/clang++
```
