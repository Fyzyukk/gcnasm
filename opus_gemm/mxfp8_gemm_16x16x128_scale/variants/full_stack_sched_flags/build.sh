#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
TOP=$(cd "$HERE/../.." && pwd)
BASE="$TOP/variants/early_c_store_full_stack"
PATCHER="$TOP/variants/isa_schedule_search/patch_schedule.py"
TOOLCHAIN=/opt/rocm-llvm23-46fcb339
CLANG23="$TOOLCHAIN/bin/clang++"
OPUS_INCLUDE_DIR=${OPUS_INCLUDE_DIR:-/root/workspace/aiter/csrc/include}
BUILD_DIR="$HERE/build"

mkdir -p "$BUILD_DIR"
OPUS_INCLUDE_DIR="$OPUS_INCLUDE_DIR" bash "$BASE/build.sh"

build_one() {
    local tag=$1
    local option=$2
    "$CLANG23" -x hip "$BASE/kern.cc" \
        -I"$BASE" -I"$TOP" -I"$OPUS_INCLUDE_DIR" \
        -std=c++17 -O3 -ffast-math \
        --offload-arch=gfx950 --rocm-path=/opt/rocm \
        -D__HIPCC_RTC__ -DMXFP8_OUTPUT_B1_HANDOFF_PAIRS=1 \
        -DMXFP8_EARLY_C_STORE \
        -Xarch_device "-mllvm=$option" \
        --cuda-device-only -S -o "$BUILD_DIR/${tag}_source.s"
    python3 "$PATCHER" ctrl_fill \
        "$BUILD_DIR/${tag}_source.s" "$BUILD_DIR/$tag.s"
    "$CLANG23" -x assembler -target amdgcn-amd-amdhsa -mcpu=gfx950 \
        "$BUILD_DIR/$tag.s" -o "$BUILD_DIR/$tag.co"
    "$TOOLCHAIN/bin/clang-offload-bundler" -type=o \
        -targets=host-x86_64-unknown-linux-gnu-,hipv4-amdgcn-amd-amdhsa--gfx950 \
        -input="$BASE/build/host.empty" -input="$BUILD_DIR/$tag.co" \
        -output="$BUILD_DIR/$tag.fb"
    "$TOOLCHAIN/bin/llvm-objcopy" \
        --update-section=.hip_fatbin="$BUILD_DIR/$tag.fb" \
        "$BASE/build/source_ref.exe" "$BUILD_DIR/$tag.exe"
    chmod +x "$BUILD_DIR/$tag.exe"
    "$TOOLCHAIN/bin/llvm-objdump" -d --mcpu=gfx950 \
        "$BUILD_DIR/$tag.co" > "$BUILD_DIR/$tag.isa"
    "$TOOLCHAIN/bin/llvm-readelf" --notes "$BUILD_DIR/$tag.co" \
        > "$BUILD_DIR/$tag.notes"
}

build_one iter_ilp -misched=gcn-iterative-ilp
build_one prera_top -misched-prera-direction=topdown
build_one iter_minreg -misched=gcn-iterative-minreg
build_one ilpmax -misched=ilpmax
build_one maxilp -misched=gcn-max-ilp

cp "$BASE/build/ctrl_early.exe" "$BUILD_DIR/ref.exe"
cp "$BASE/build/ctrl_early.isa" "$BUILD_DIR/ref.isa"
cp "$BASE/build/ctrl_early.notes" "$BUILD_DIR/ref.notes"

python3 "$HERE/gate.py" "$BUILD_DIR"
