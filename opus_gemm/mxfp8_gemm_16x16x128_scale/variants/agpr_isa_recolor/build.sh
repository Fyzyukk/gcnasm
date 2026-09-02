#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
TOP=$(cd "$HERE/../.." && pwd)
BASE="$TOP/variants/early_c_store_full_stack"
SOURCE_DIR="$TOP/variants/block_order_sweep"
CTRL_PATCHER="$TOP/variants/isa_schedule_search/patch_schedule.py"
TOOLCHAIN=/opt/rocm-llvm23-46fcb339
CLANG23="$TOOLCHAIN/bin/clang++"
ROCM=/opt/rocm
OPUS_INCLUDE_DIR=${OPUS_INCLUDE_DIR:-/root/workspace/aiter/csrc/include}
ARCH=gfx950
BUILD_DIR="$HERE/build"

FLAGS=(
    -I"$SOURCE_DIR" -I"$BASE" -I"$TOP" -I"$OPUS_INCLUDE_DIR"
    -std=c++17 -O3 -ffast-math
    --offload-arch="$ARCH" --rocm-path="$ROCM"
)
DEVICE_FLAGS=(
    -D__HIPCC_RTC__
    -DMXFP8_OUTPUT_B1_HANDOFF_PAIRS=1
    -DMXFP8_EARLY_C_STORE
    -DMXFP8_BLOCK_ORDER=6
    -Xarch_device -mllvm=-misched-prera-direction=topdown
)
LDFLAGS=(
    -fopenmp -L"$ROCM/lib/llvm/lib" -lomp
    -Wl,-rpath,"$ROCM/lib/llvm/lib"
    -L"$ROCM/lib" -lamdhip64 -Wl,-rpath,"$ROCM/lib"
)

[[ -x "$CLANG23" ]] || { echo "missing clang23: $CLANG23" >&2; exit 1; }
mkdir -p "$BUILD_DIR"

"$CLANG23" -x hip \
    "$TOP/gemm_a8w8_mxfp8_scale_host_fixed_b_asym_b_read2_unified_scale.cc" \
    "${FLAGS[@]}" -fopenmp -I"$ROCM/lib/llvm/include" \
    -c -o "$BUILD_DIR/host.o"
"$CLANG23" -x hip "$SOURCE_DIR/kern.cc" "${FLAGS[@]}" "${DEVICE_FLAGS[@]}" \
    -c -o "$BUILD_DIR/kernel.o"
"$CLANG23" "$BUILD_DIR/kernel.o" "$BUILD_DIR/host.o" \
    --offload-arch="$ARCH" --rocm-path="$ROCM" "${LDFLAGS[@]}" \
    -o "$BUILD_DIR/container.exe"

"$TOOLCHAIN/bin/llvm-objcopy" \
    --dump-section=.hip_fatbin="$BUILD_DIR/container.fb" "$BUILD_DIR/container.exe"
"$TOOLCHAIN/bin/clang-offload-bundler" -type=o \
    -targets=host-x86_64-unknown-linux-gnu- \
    -input="$BUILD_DIR/container.fb" -output="$BUILD_DIR/host.empty" -unbundle

"$CLANG23" -x hip "$SOURCE_DIR/kern.cc" "${FLAGS[@]}" "${DEVICE_FLAGS[@]}" \
    --cuda-device-only -S -o "$BUILD_DIR/source.s"
python3 "$CTRL_PATCHER" ctrl_fill "$BUILD_DIR/source.s" "$BUILD_DIR/ref.s"
python3 "$HERE/patch_recolor.py" --accum-offset 112 \
    "$BUILD_DIR/ref.s" "$BUILD_DIR/agpr_recolor.s"
for offset in 116 120 124 128; do
    python3 "$HERE/patch_recolor.py" --accum-offset "$offset" \
        "$BUILD_DIR/ref.s" "$BUILD_DIR/offset${offset}.s"
done
for rotate in 4 8 16; do
    python3 "$HERE/patch_recolor.py" --accum-offset 112 --agpr-rotate "$rotate" \
        "$BUILD_DIR/ref.s" "$BUILD_DIR/rotate${rotate}.s"
done
python3 "$HERE/patch_half_upper.py" \
    "$BUILD_DIR/ref.s" "$BUILD_DIR/half_upper.s"

for tag in ref agpr_recolor offset116 offset120 offset124 offset128 rotate4 rotate8 rotate16 half_upper; do
    "$CLANG23" -x assembler -target amdgcn-amd-amdhsa -mcpu="$ARCH" \
        "$BUILD_DIR/$tag.s" -o "$BUILD_DIR/$tag.co"
    "$TOOLCHAIN/bin/clang-offload-bundler" -type=o \
        -targets=host-x86_64-unknown-linux-gnu-,hipv4-amdgcn-amd-amdhsa--"$ARCH" \
        -input="$BUILD_DIR/host.empty" -input="$BUILD_DIR/$tag.co" \
        -output="$BUILD_DIR/$tag.fb"
    cp "$BUILD_DIR/container.exe" "$BUILD_DIR/$tag.exe"
    "$TOOLCHAIN/bin/llvm-objcopy" \
        --update-section=.hip_fatbin="$BUILD_DIR/$tag.fb" "$BUILD_DIR/$tag.exe"
    chmod +x "$BUILD_DIR/$tag.exe"
    "$TOOLCHAIN/bin/llvm-objcopy" \
        --dump-section=.hip_fatbin="$BUILD_DIR/${tag}_linked.fb" \
        "$BUILD_DIR/$tag.exe"
    "$TOOLCHAIN/bin/clang-offload-bundler" -type=o \
        -targets=hipv4-amdgcn-amd-amdhsa--"$ARCH" \
        -input="$BUILD_DIR/${tag}_linked.fb" \
        -output="$BUILD_DIR/${tag}_linked.dev" -unbundle
    "$TOOLCHAIN/bin/llvm-objdump" -d --mcpu="$ARCH" \
        "$BUILD_DIR/${tag}_linked.dev" > "$BUILD_DIR/$tag.isa"
    "$TOOLCHAIN/bin/llvm-readelf" --notes "$BUILD_DIR/${tag}_linked.dev" \
        > "$BUILD_DIR/$tag.notes"
done

python3 "$HERE/gate.py" "$BUILD_DIR"
