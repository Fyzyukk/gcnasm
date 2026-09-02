# `ctrl_fill` retained result (2026-09-01)

## Contract

- Unified-scale only, p1/no-setprio baseline.
- Compiler: `/opt/rocm-llvm23-46fcb339/bin/clang++`.
- GPU: `HIP_VISIBLE_DEVICES=7`, protected by
  `flock /tmp/mxfp8_gpu7.lock`.
- Performance shape: `8192x8192x8192`, batch 1, verification disabled.
- Each timed process used `-w 1000 -i 500`.

`ctrl_fill` moves each producer predicate (`s_andn2`, `s_add`, `s_cmp`) from
after its handoff barrier into existing MFMA-spacing `s_nop` slots.  Four
regions consume three slots and one region consumes two slots, removing 14
dynamic NOPs without changing the non-NOP instruction multiset.

Linked resource gate:

```text
192 MFMA
240 VGPR
101 SGPR
139264 B LDS
7 barriers
91 direct-to-LDS buffer loads
32 global stores
0 VGPR/SGPR spill
0 scratch/private bytes
```

## Correctness

All of the following reported `[Overall] ALL BATCHES VALID`:

```text
256x256x128 b1
512x512x256 b1
1024x512x1024 b1
1280x256x512 b2
8192x512x16384 b1
```

## Fresh eight-round ABBA

Each row contains the four raw process measurements.  Odd rounds use
`ref,candidate,candidate,ref`; even rounds use the mirrored order.

| Round | A1 | B1 | B2 | A2 | Ref mean ms | Candidate mean ms | Gain |
| ---: | --- | --- | --- | --- | ---: | ---: | ---: |
| 1 | ref 0.4591 | ctrl 0.4561 | ctrl 0.4560 | ref 0.4587 | 0.458900 | 0.456050 | +0.6249% |
| 2 | ctrl 0.4565 | ref 0.4591 | ref 0.4593 | ctrl 0.4560 | 0.459200 | 0.456250 | +0.6466% |
| 3 | ref 0.4594 | ctrl 0.4567 | ctrl 0.4568 | ref 0.4598 | 0.459600 | 0.456750 | +0.6240% |
| 4 | ctrl 0.4576 | ref 0.4602 | ref 0.4604 | ctrl 0.4585 | 0.460300 | 0.458050 | +0.4912% |
| 5 | ref 0.4615 | ctrl 0.4585 | ctrl 0.4587 | ref 0.4617 | 0.461600 | 0.458600 | +0.6542% |
| 6 | ctrl 0.4589 | ref 0.4624 | ref 0.4624 | ctrl 0.4584 | 0.462400 | 0.458650 | +0.8176% |
| 7 | ref 0.4621 | ctrl 0.4577 | ctrl 0.4582 | ref 0.4620 | 0.462050 | 0.457950 | +0.8953% |
| 8 | ctrl 0.4578 | ref 0.4620 | ref 0.4620 | ctrl 0.4580 | 0.462000 | 0.457900 | +0.8954% |

Aggregate:

```text
reference mean       0.460756 ms
ctrl_fill mean       0.457525 ms
mean-ratio gain      +0.7062%
mean paired gain     +0.7061%
paired wins          8/8
reference median     0.460950 ms
ctrl_fill median     0.457925 ms
```

An earlier independent eight-round ABBA also produced `+0.6416%`, 8/8.
Standalone `vadd_gap` (`-0.0325%`) and selective B1 WAR repair (`-0.0406%`)
were neutral/slightly negative and are not retained.

## Reproduction

```bash
MODES=ctrl_fill \
TOOLCHAIN=/opt/rocm-llvm23-46fcb339 \
OPUS_INCLUDE_DIR=/root/workspace/aiter/csrc/include \
bash opus_gemm/mxfp8_gemm_16x16x128_scale/variants/isa_schedule_search/build.sh
```

Reference executable: `build/ref.exe`.

Retained executable: `build/ctrl_fill.exe`.

Patch generator: `patch_schedule.py`.
