# clang23 AMDGPU hard-pin patches

The 4-wave pin experiments require a local ROCm clang23 built from ROCm LLVM
commit `46fcb339fb61119b337f973c7ca9e710a319fdd0` plus both patches in this
directory, applied in this exact order:

1. `clang23_amdgpu_hard_pin.patch`
2. `clang23_amdgpu_agpr_accumulator_pin.patch`

The supplemental accumulator patch modifies `SIPreColorPins.cpp`, which is
introduced by the base patch, so it cannot be applied first or directly to the
stock tree. The stock clang23 tree does not understand
`amdgpu_pin_vgpr(N)` or `amdgpu_pin_agpr(N)`.

The attributes are hard constraints by default. A compilation that cannot
honor the requested physical tuple fails; it must not silently allocate a
different tuple. `-mllvm -amdgpu-hard-pin-regs=0` exists only as an explicit
soft-hint compiler experiment and is not used by the validated binaries.

## Patch responsibilities

The base patch adds the Clang attributes and LLVM intrinsics, pre-RA hard-pin
and post-RA verification passes, exact VGPR/AGPR tuple allocation, direct
LDS-to-AGPR operand placement, and the VGPRCD MFMA path used by the existing
C-VGPR/A-B-AGPR variants.

The supplemental patch adds native C-accumulator AGPR support. It distinguishes
an MFMA input pin from a pin on the MFMA `Dst/SrcC` accumulator chain. For a C
AGPR pin, it converts every connected MFMA to the native AGPR destination and
SrcC form, selects the tied/in-place MAC form, enforces `Dst == SrcC`, and
recomputes the connected PHI/copy/MFMA register classes as AGPRs. It also keeps
shared all-zero accumulator splats from acquiring incompatible scalar
subregister pins. A/B-only AGPR pins retain their prior behavior and can still
use a VGPRCD accumulator.

## Build

```bash
git clone https://github.com/ROCm/llvm-project.git rocm-llvm23-pin
cd rocm-llvm23-pin
git checkout 46fcb339fb61119b337f973c7ca9e710a319fdd0
git apply /path/to/clang23_amdgpu_hard_pin.patch
git apply /path/to/clang23_amdgpu_agpr_accumulator_pin.patch

cmake -S llvm -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_PROJECTS='clang;lld' \
  -DLLVM_TARGETS_TO_BUILD='AMDGPU;X86' \
  -DLLVM_ENABLE_ASSERTIONS=OFF \
  -DCLANG_DEFAULT_LINKER=lld \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DCLANG_INCLUDE_TESTS=OFF \
  -DLLVM_INCLUDE_BENCHMARKS=OFF \
  -DLLVM_INCLUDE_EXAMPLES=OFF

ninja -C build clang llc llvm-objcopy llvm-objdump llvm-readelf \
  clang-offload-bundler lld
```

Use that build directly when compiling both the CX2 baseline and a pin variant:

```bash
TOOLCHAIN=/path/to/rocm-llvm23-pin/build \
  ../four_wave_coexec_b0_wait5_v2/build.sh
TOOLCHAIN=/path/to/rocm-llvm23-pin/build ./build.sh
./correctness.sh
```

`build.sh` disassembles the linked gfx950 code object and runs the variant's ISA
gate. The gate checks the exact physical tuples, direct LDS-to-AGPR writes,
native AGPR or VGPRCD accumulator placement as requested, MFMA `Dst == SrcC`,
retained CX2 co-execution windows, resource counts, and the absence of bridge
moves, spills, and scratch as appropriate for each variant.

## Validated source variants

- `four_wave_cx2_pin_c_vgpr_v1`: C accumulator at `v0:v127`.
- `four_wave_cx2_pin_ab_agpr_v1`: A at `a0:a31`, B at `a32:a95`.
- `four_wave_cx2_pin_c_vgpr_ab_agpr_v1`: both layouts together.
- `four_wave_cx2_tile256x256_c_agpr_v1`: C accumulator at `a0:a255`, using
  native/tied AGPR `Dst/SrcC` chains without `v_accvgpr_read` bridges.

The first three keep the pure CX2 `128x256x128` unified-scale pipeline
unchanged. The C-AGPR prototype expands the block tile to `256x256x128` while
retaining the CX2 co-execution pipeline.
