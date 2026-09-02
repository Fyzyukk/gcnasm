#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
TOP=$(cd "$HERE/../.." && pwd)
BASE="$TOP/variants/early_c_store_full_stack"
PATCHER="$TOP/variants/isa_schedule_search/patch_schedule.py"
TOOLCHAIN=/opt/rocm-llvm23-46fcb339
CLANG23="$TOOLCHAIN/bin/clang++"
ROCM=/opt/rocm
OPUS_INCLUDE_DIR=${OPUS_INCLUDE_DIR:-/root/workspace/aiter/csrc/include}
ARCH=gfx950
BUILD_DIR="$HERE/build"

FLAGS=(
    -I"$HERE" -I"$BASE" -I"$TOP" -I"$OPUS_INCLUDE_DIR"
    -std=c++17 -O3 -ffast-math
    --offload-arch="$ARCH" --rocm-path="$ROCM"
)
DEVICE_DEFINES=(
    -D__HIPCC_RTC__
    -DMXFP8_OUTPUT_B1_HANDOFF_PAIRS=1
    -DMXFP8_EARLY_C_STORE
)
SCHED_FLAGS=(-Xarch_device -mllvm=-misched-prera-direction=topdown)
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
[[ -x "$PATCHER" ]] || { echo "missing patcher: $PATCHER" >&2; exit 1; }

# This path is deliberately fixed below HERE so a fresh build cannot erase an
# environment-selected directory.
rm -rf "$HERE/build"
mkdir -p "$BUILD_DIR"
python3 "$HERE/make_direct_template.py" \
    "$BASE/tmpl.hpp" "$BUILD_DIR/tmpl_direct.hpp"

"$CLANG23" -x hip \
    "$TOP/gemm_a8w8_mxfp8_scale_host_fixed_b_asym_b_read2_unified_scale.cc" \
    "${FLAGS[@]}" -fopenmp -I"$ROCM/lib/llvm/include" \
    -c -o "$BUILD_DIR/host.o"

# Fresh host registration/fatbin container for this exact kernel symbol.
"$CLANG23" -x hip "$BASE/kern.cc" "${FLAGS[@]}" \
    "${DEVICE_DEFINES[@]}" "${SCHED_FLAGS[@]}" \
    -c -o "$BUILD_DIR/container.o"
"$CLANG23" "$BUILD_DIR/container.o" "$BUILD_DIR/host.o" \
    --offload-arch="$ARCH" --rocm-path="$ROCM" "${LDFLAGS[@]}" \
    -o "$BUILD_DIR/container.exe"

"$TOOLCHAIN/bin/llvm-objcopy" \
    --dump-section=.hip_fatbin="$BUILD_DIR/container.fb" \
    "$BUILD_DIR/container.exe"
"$TOOLCHAIN/bin/clang-offload-bundler" -type=o \
    -targets=host-x86_64-unknown-linux-gnu- \
    -input="$BUILD_DIR/container.fb" -output="$BUILD_DIR/host.empty" -unbundle

build_one() {
    local tag=$1
    local source=$2
    local order=${3:-}
    local schedule=${4:-prera_top}
    local order_macro=${5:-MXFP8_BLOCK_ORDER}
    local order_flag=()
    local schedule_flags=()
    if [[ -n "$order" ]]; then
        order_flag=(-D"$order_macro"="$order")
    fi
    if [[ "$schedule" == prera_top ]]; then
        schedule_flags=("${SCHED_FLAGS[@]}")
    elif [[ "$schedule" != default ]]; then
        echo "unknown schedule mode: $schedule" >&2
        exit 1
    fi

    "$CLANG23" -x hip "$source" "${FLAGS[@]}" \
        "${DEVICE_DEFINES[@]}" "${schedule_flags[@]}" "${order_flag[@]}" \
        --cuda-device-only -S -o "$BUILD_DIR/${tag}_source.s"
    python3 "$PATCHER" ctrl_fill \
        "$BUILD_DIR/${tag}_source.s" "$BUILD_DIR/$tag.s"
    "$CLANG23" -x assembler -target amdgcn-amd-amdhsa -mcpu="$ARCH" \
        "$BUILD_DIR/$tag.s" -o "$BUILD_DIR/$tag.co"
    "$TOOLCHAIN/bin/clang-offload-bundler" -type=o \
        -targets=host-x86_64-unknown-linux-gnu-,hipv4-amdgcn-amd-amdhsa--"$ARCH" \
        -input="$BUILD_DIR/host.empty" -input="$BUILD_DIR/$tag.co" \
        -output="$BUILD_DIR/$tag.fb"
    cp "$BUILD_DIR/container.exe" "$BUILD_DIR/$tag.exe"
    "$TOOLCHAIN/bin/llvm-objcopy" \
        --update-section=.hip_fatbin="$BUILD_DIR/$tag.fb" \
        "$BUILD_DIR/$tag.exe"
    chmod +x "$BUILD_DIR/$tag.exe"

    # Inspect the image linked into the executable, not an intermediate object.
    "$TOOLCHAIN/bin/llvm-objcopy" \
        --dump-section=.hip_fatbin="$BUILD_DIR/${tag}_linked.fb" \
        "$BUILD_DIR/$tag.exe"
    "$TOOLCHAIN/bin/clang-offload-bundler" -type=o \
        -targets=hipv4-amdgcn-amd-amdhsa--"$ARCH" \
        -input="$BUILD_DIR/${tag}_linked.fb" \
        -output="$BUILD_DIR/${tag}_linked.dev" -unbundle
    "$TOOLCHAIN/bin/llvm-objdump" -d --mcpu="$ARCH" \
        "$BUILD_DIR/${tag}_linked.dev" > "$BUILD_DIR/$tag.isa"
    "$TOOLCHAIN/bin/llvm-readelf" --notes \
        "$BUILD_DIR/${tag}_linked.dev" > "$BUILD_DIR/$tag.notes"
}

build_one ref "$BASE/kern.cc"
build_one t4x8_nfast "$HERE/kern.cc" 1
build_one t4x8_mfast "$HERE/kern.cc" 2
build_one t8x4_nfast "$HERE/kern.cc" 3
build_one t8x4_mfast "$HERE/kern.cc" 4
build_one nmajor "$HERE/kern.cc" 5
build_one t2x16_nfast_exact "$HERE/kern.cc" 6
build_one t4x8_nfast_exact "$HERE/kern.cc" 7
build_one t8x4_nfast_exact "$HERE/kern.cc" 8
build_one t2x16_direct "$HERE/kern.cc" 9
build_one identity_direct "$HERE/kern.cc" 10
build_one identity_coords "$HERE/kern_direct.cc" 0 prera_top MXFP8_DIRECT_ORDER
build_one t2x16_coords "$HERE/kern_direct.cc" 1 prera_top MXFP8_DIRECT_ORDER
build_one t2x16_xor_m8 "$HERE/kern.cc" 11
build_one t2x16_serpentine "$HERE/kern.cc" 12
build_one t2x16_gray "$HERE/kern.cc" 13
build_one t2x16_xor_macro8 "$HERE/kern.cc" 14
build_one t2x16_insert_p1 "$HERE/kern.cc" 15
build_one t2x16_insert_p2 "$HERE/kern.cc" 16
build_one t2x16_insert_p3 "$HERE/kern.cc" 17
build_one t2x16_n_bitreverse "$HERE/kern.cc" 18
build_one t2x16_n_rotl1 "$HERE/kern.cc" 19
build_one t2x16_n_rotl2 "$HERE/kern.cc" 20
build_one t2x16_n_rotl3 "$HERE/kern.cc" 21
build_one retained "$BASE/kern.cc" "" default

python3 "$HERE/map_check.py"
python3 "$HERE/gate.py" "$BUILD_DIR"
