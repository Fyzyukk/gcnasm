# MXFP8 Scaled-MFMA GEMM Kernel for AMD GPU

A batched MXFP8 × MXFP8 → FP32 GEMM kernel built on the [OPUS](https://github.com/ROCm/aiter/tree/main/csrc/include/opus) template library, targeting AMD gfx950 (MI355X).

## What the kernel does

The kernel computes a batched matrix multiply `C = A · B^T` per batch, where:

- `A` is `fp8 e4m3` of shape `[batch, M, K]`
- `B` is `fp8 e4m3` of shape `[batch, N, K]`
- `C` is `fp32` of shape `[batch, M, N]`

The multiply itself is `V_MFMA_SCALE_F32_16X16X128_F8F6F4`: the scale factors are consumed by the MFMA instruction, not applied afterwards in VALU. Each MFMA reads one `e8m0` scale byte for A and one for B out of a packed dword, selected by the `op_sel` operands.

### Microscaling (MX) scheme

Scale factors follow the OCP MX convention: one `e8m0` exponent per 32 contiguous K elements.

| Scale tensor | Logical shape (per batch) | Group granularity | Meaning |
|---|---|---|---|
| `SFA` (A scale) | `[M, K/32]` | `GROUP_M × GROUP_K = 1 × 32` | one e8m0 scale per 32-element K run of a row of `A` |
| `SFB` (B scale) | `[N, K/32]` | `GROUP_N × GROUP_K = 1 × 32` | one e8m0 scale per 32-element K run of a row of `B` |

- `GROUP_M = 1`, `GROUP_N = 1`, `GROUP_K = 32`
- All scale factors are `e8m0` (`uint8`), one byte each

#### SFA and SFB share a single code path

`SFA` is `[M, K/32]` and `SFB` is `[N, K/32]` — the same shape, differing only in which of `M` or `N` names the rows. The kernel exploits this: the global→LDS scale producer is written once and parameterised by a base pointer and a stride, with wave 0 driving the `SFA` copy and wave 1 the `SFB` copy through the same instructions. Both legs must therefore use the same LDS stage stride, which a `static_assert` in the kernel enforces.

The two scale tensors are stored pre-swizzled per `(tile, k-tile)` block (`stride_sfa = packed_sfa_tile_elem`), so the producer's global reads are fully coalesced.

### Pipeline shape

**Persistent fixed-B tile.** One workgroup walks `OUTPUT_TILES_PER_WG = 4` adjacent M tiles while holding N fixed. `B` and the `B` scales never move across those four output tiles, so their global loads and address arithmetic are hoisted out of the output loop entirely — only `A`, `C` and the `A` scales are re-based per tile. The grid is sized accordingly: `ceil_div(num_tiles_m, 4) * num_tiles_n`.

`OUTPUT_TILES_PER_WG` is a traits parameter, and the device TU instantiates the kernel twice — once with 4 and once with 1. The host picks between them at launch: it keeps 4 when `ceil_div(num_tiles_m, 4) * num_tiles_n` still reaches the CU count, and falls back to 1 when it does not. See [Performance](#performance) for why.

**Early-C output handoff.** The LDS handoff to the next output tile is moved about 30 MFMAs earlier than the naive position. It can be moved there because the two C quadrants belonging to the `B` half-0 half are final as soon as the half-0 MFMAs retire, so they are stored immediately; gfx9 completes VMEM in order, so the handoff can then wait on `s_waitcnt vmcnt(16)` instead of `vmcnt(0)`. This also spreads the epilogue's 32 stores across the remaining MFMAs instead of bunching them after the last one.

**`ds_read2st64_b32` for the B scales.** Both N halves of the `SFB` scale are 512 bytes apart in LDS. The ST64 addressing unit is 64 dwords (256 bytes), so `offset0:0 offset1:2` fetches both halves in a single instruction, and only the `half_tile_n = 0` register layout has to be built.

### Kernel configuration

Default traits (`gemm_a8w8_mxfp8_scale_traits<>`):

| Parameter | Value |
|---|---|
| BLOCK_M × BLOCK_N × BLOCK_K | 256 × 256 × 128 |
| GROUP_M × GROUP_N × GROUP_K | 1 × 1 × 32 |
| Warps per block / block size | 8 / 512 |
| MFMA tile (W_M × W_N × W_K) | 16 × 16 × 128 |
| Warp tiling (T_M × T_N × T_K) | 4 × 2 × 1 |
| Output tiles per workgroup | 4 or 1, chosen at launch |
| A/B global-load vector (fp8) | 16 elems |
| C global-store vector (fp32) | 4 elems |
| Scale global-load vector (e8m0) | 16 bytes |

## Files

```
mxfp8_gemm_16x16x128_scale/
├── Makefile
├── rebuild.sh
├── bench.sh
├── gemm_a8w8_mxfp8_scale_common.h            # kargs + traits
├── gemm_a8w8_mxfp8_scale_kernel_template.hpp # kernel body
├── gemm_a8w8_mxfp8_scale_kernel.cc           # device TU: the two instantiations
└── gemm_a8w8_mxfp8_scale_host.cc             # host launcher / benchmark / CPU reference
```

The kernel body is laid out as `// Prologue` → `// Main Loop` → `// Epilogue`. The main loop deliberately stops one K tile short (`tile + 1 < loops`); that last tile is consumed in the epilogue from LDS with no further global loads, which is what makes room for the output handoff.

## Prerequisites

- ROCm with hipcc (for the HIP runtime and the binutils used by `make check`)
- gfx950 GPU target (e.g. MI355X)
- OPUS headers from [aiter](https://github.com/ROCm/aiter): set `OPUS_INCLUDE_DIR` to `<aiter_root>/csrc/include`
- OpenMP (for CPU reference and random init)
- **clang 23 or newer.** clang 20/21/22 refuse the `#pragma unroll 4` on the main K loop (they report `loop not unrolled` and emit 64 MFMA); clang 23 unrolls it to 192 MFMA, which is worth roughly **+13%**. Set `CLANG23_ROOT` to such a build, or override `HIPCC=/opt/rocm/bin/hipcc` and accept the slower code — `make check` will fail in that case, by design.

## Build

```bash
cd opus_gemm/mxfp8_gemm_16x16x128_scale
export OPUS_INCLUDE_DIR=/path/to/aiter/csrc/include
make -j
```

Or use the convenience script (clean build + gate + a default 8192³ run):

```bash
./rebuild.sh
```

### Build gates

Two properties of the generated code have regressed silently in the past, so they are checked mechanically against the **linked executable** (never the `.o` — the linker is what decides the code that actually runs):

```bash
make check   # >=192 v_mfma_scale_f32_16x16x128, and 0 s_setprio
             # (reports 384: 192 per instantiation, two of them)
make regs    # VGPR / SGPR / spill / LDS
```

Expected `make regs` output — one block per instantiation, persistent first:

| Instantiation | VGPR | SGPR | VGPR spill | SGPR spill | LDS (bytes) | Blocks/CU |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| 4 tiles/WG | 242 | 101 | 0 | 0 | 139264 | 1 |
| 1 tile/WG  | 226 |  76 | 0 | 0 | 139264 | 1 |

Any nonzero spill count is a regression: an earlier version of the loop-invariant hoisting pushed SGPR from 101 to 106 with 6 spills and cost 1.2%.

## Run

```bash
./build/gemm_a8w8_mxfp8_scale.exe                                    # defaults: b=8, m=256, n=512, k=256
./build/gemm_a8w8_mxfp8_scale.exe -m 8192 -n 8192 -k 8192 -b 1       # timing
./build/gemm_a8w8_mxfp8_scale.exe -m 8192 -n 8192 -k 8192 -b 1 -v 1  # validate vs CPU
```

Or through make, which runs `check` first:

```bash
make benchmark            # 8192^3, -w 200 -i 100
make verify               # 8192^3, -v 1
make benchmark GPU=2      # pin to one card
make benchmark SHAPE="-m 4096 -n 4096 -k 4096 -b 1"
```

### Command-line options

| Flag | Description | Default |
|---|---|---|
| `-b`, `--b` | Batch size | 8 |
| `-m`, `--m` | M dimension | 256 |
| `-n`, `--n` | N dimension | 512 |
| `-k`, `--k` | K dimension | 256 |
| `-v`, `--verify` | CPU reference verification (0=off, 1=on) | 0 |
| `-w`, `--warmup` | Warmup iterations | 200 |
| `-i`, `--iterations` | Timed iterations | 100 |
| `--timeline` | Per-kernel timeline of consecutive launches (requires `-v 0`) | off |

All flags accept both `-m 4096` and `-m=4096` syntax. `M / N / K` must be multiples of `BLOCK_M / BLOCK_N / BLOCK_K`, and `K` a multiple of `GROUP_K = 32`.

## Benchmarking

```bash
./bench.sh              # 5 runs on the default card
./bench.sh 5 2          # 5 runs pinned to GPU 2
```

## Performance

Measured on MI355X, `batch = 1`, square problem size `M = N = K`, `-w 200 -i 100`:

| M=N=K | Tiles per WG | Grid | Avg Time (ms) | TFlops |
|---:|:--:|---|---:|---:|
| 1024  | 1 | (16,   1, 1) | 0.0173 |  124.46 |
| 2048  | 1 | (64,   1, 1) | 0.0258 |  667.15 |
| 4096  | 1 | (256,  1, 1) | 0.0563 | 2440.74 |
| 8192  | 4 | (256,  1, 1) | 0.3663 | 3004.94 |
| 16384 | 4 | (1024, 1, 1) | 3.1919 | 2755.78 |

### Why the persistent tile is switched off below 8192

LDS is 139264 bytes, so exactly one workgroup fits per CU and the workgroup count *is* the CU count in use. On a 256-CU MI355X that makes the tradeoff arithmetic:

| M=N=K | Tiles (m×n) | WGs at 4 | WGs at 1 | Rounds at 4 | Rounds at 1 |
|---:|:--:|--:|--:|--:|--:|
| 1024  | 4×4   | 4    | 16   | 1 | 1 |
| 2048  | 8×8   | 16   | 64   | 1 | 1 |
| 4096  | 16×16 | 64   | 256  | 1 | 1 |
| 8192  | 32×32 | 256  | 1024 | 1 | 4 |
| 16384 | 64×64 | 1024 | 4096 | 4 | 16 |

Dividing the grid by four only saves work once there are more workgroups than CUs — first true at 8192. Below that it just parks CUs: at 4096 the persistent form runs 64 workgroups and leaves 192 CUs idle, whereas one tile per workgroup fills the chip exactly. Measured on one card, forcing the persistent form at the small sizes costs:

| M=N=K | 1 tile/WG | 4 tiles/WG | forcing 4 |
|---:|---:|---:|:--|
| 1024 |  124.46 |   35.80 | −71% |
| 2048 |  667.15 |  188.34 | −72% |
| 4096 | 2440.74 |  893.95 | −63% |
| 8192 | ~2940   | 2968.44 | +1.0% |
| 16384| ~2580   | 2755.78 | +6.8% |

4096 is the sharpest case for the reason above — it is the largest size where the non-persistent grid still fits in one round. The single-tile instantiation is also cheaper in registers (VGPR 226 / SGPR 76 versus 242 / 101), though with LDS pinning occupancy at one block per CU that buys nothing.

The same binary measures 2863–3005 TFlops at 8192³ depending on which card it lands on: DVFS under a shared power wall spreads results by about 5%, while per-card repeatability is under 0.2%. The 8192 row above is the fastest card. For any change to the kernel, the meaningful check is a paired same-card comparison against the previous build, not an absolute number.
