#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
TOP=$(cd "$HERE/../.." && pwd)
PATCHER="$TOP/variants/isa_schedule_search/patch_schedule.py"
TOOLCHAIN=/opt/rocm-llvm23-46fcb339
CLANG23="$TOOLCHAIN/bin/clang++"
ROCM=/opt/rocm
OPUS_INCLUDE_DIR=${OPUS_INCLUDE_DIR:-/root/workspace/aiter/csrc/include}
ARCH=gfx950
BUILD_DIR="$HERE/build"

FLAGS=(
    -I"$HERE" -I"$TOP" -I"$OPUS_INCLUDE_DIR"
    -std=c++17 -O3 -ffast-math
    --offload-arch="$ARCH" --rocm-path="$ROCM"
)
LDFLAGS=(
    -fopenmp -L"$ROCM/lib/llvm/lib" -lomp
    -Wl,-rpath,"$ROCM/lib/llvm/lib"
    -L"$ROCM/lib" -lamdhip64 -Wl,-rpath,"$ROCM/lib"
)

[[ -x "$CLANG23" ]] || { echo "missing clang23: $CLANG23" >&2; exit 1; }
[[ -f "$OPUS_INCLUDE_DIR/opus/hip_minimal.hpp" ]] || {
    echo "missing OPUS headers: $OPUS_INCLUDE_DIR" >&2
    exit 1
}
[[ -x "$PATCHER" ]] || { echo "missing ctrl_fill patcher: $PATCHER" >&2; exit 1; }

mkdir -p "$BUILD_DIR"
"$CLANG23" -x hip \
    "$TOP/gemm_a8w8_mxfp8_scale_host_fixed_b_asym_b_read2_unified_scale.cc" \
    "${FLAGS[@]}" -fopenmp -I"$ROCM/lib/llvm/include" \
    -c -o "$BUILD_DIR/host.o"

# Build one ordinary p18 executable as the host/fatbin container and as an
# identity control against output_b1_overlap/p1.
"$CLANG23" -x hip "$HERE/kern.cc" "${FLAGS[@]}" -D__HIPCC_RTC__ \
    -DMXFP8_OUTPUT_B1_HANDOFF_PAIRS=1 \
    -c -o "$BUILD_DIR/source_ref.o"
"$CLANG23" "$BUILD_DIR/source_ref.o" "$BUILD_DIR/host.o" \
    --offload-arch="$ARCH" --rocm-path="$ROCM" "${LDFLAGS[@]}" \
    -o "$BUILD_DIR/source_ref.exe"

"$TOOLCHAIN/bin/llvm-objcopy" \
    --dump-section=.hip_fatbin="$BUILD_DIR/source_ref.fb" \
    "$BUILD_DIR/source_ref.exe"
"$TOOLCHAIN/bin/clang-offload-bundler" -type=o \
    -targets=host-x86_64-unknown-linux-gnu- \
    -input="$BUILD_DIR/source_ref.fb" -output="$BUILD_DIR/host.empty" -unbundle

for tag in ref early; do
    extra=()
    if [[ "$tag" == early ]]; then extra=(-DMXFP8_EARLY_C_STORE); fi
    "$CLANG23" -x hip "$HERE/kern.cc" "${FLAGS[@]}" -D__HIPCC_RTC__ \
        -DMXFP8_OUTPUT_B1_HANDOFF_PAIRS=1 "${extra[@]}" \
        --cuda-device-only -S -o "$BUILD_DIR/source_$tag.s"

    python3 "$PATCHER" ctrl_fill \
        "$BUILD_DIR/source_$tag.s" "$BUILD_DIR/ctrl_$tag.s"
    "$CLANG23" -x assembler -target amdgcn-amd-amdhsa -mcpu="$ARCH" \
        "$BUILD_DIR/ctrl_$tag.s" -o "$BUILD_DIR/ctrl_$tag.co"
    "$TOOLCHAIN/bin/clang-offload-bundler" -type=o \
        -targets=host-x86_64-unknown-linux-gnu-,hipv4-amdgcn-amd-amdhsa--"$ARCH" \
        -input="$BUILD_DIR/host.empty" -input="$BUILD_DIR/ctrl_$tag.co" \
        -output="$BUILD_DIR/ctrl_$tag.fb"
    "$TOOLCHAIN/bin/llvm-objcopy" \
        --update-section=.hip_fatbin="$BUILD_DIR/ctrl_$tag.fb" \
        "$BUILD_DIR/source_ref.exe" "$BUILD_DIR/ctrl_$tag.exe"
    chmod +x "$BUILD_DIR/ctrl_$tag.exe"
    "$TOOLCHAIN/bin/llvm-objdump" -d --mcpu="$ARCH" \
        "$BUILD_DIR/ctrl_$tag.co" > "$BUILD_DIR/ctrl_$tag.isa"
    "$TOOLCHAIN/bin/llvm-readelf" --notes "$BUILD_DIR/ctrl_$tag.co" \
        > "$BUILD_DIR/ctrl_$tag.notes"
done

"$TOOLCHAIN/bin/clang-offload-bundler" -type=o \
    -targets="hipv4-amdgcn-amd-amdhsa--$ARCH" \
    -input="$BUILD_DIR/source_ref.fb" -output="$BUILD_DIR/source_ref.dev" -unbundle
"$TOOLCHAIN/bin/llvm-objdump" -d --mcpu="$ARCH" \
    "$BUILD_DIR/source_ref.dev" > "$BUILD_DIR/source_ref.isa"
rm -f "$BUILD_DIR/source_ref.fb" "$BUILD_DIR/ctrl_ref.fb" "$BUILD_DIR/ctrl_early.fb"

python3 "$HERE/gate.py" "$BUILD_DIR"
