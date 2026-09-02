#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
TOP=$(cd "$HERE/../.." && pwd)
BASE="$TOP/variants/agpr_isa_recolor"
TOOLCHAIN=/opt/rocm-llvm23-46fcb339
CLANG23="$TOOLCHAIN/bin/clang++"
ARCH=gfx950
BUILD_DIR=${BUILD_DIR:-$HERE/build}

[[ -x "$CLANG23" ]] || { echo "missing clang23: $CLANG23" >&2; exit 1; }
(cd "$BASE" && ./build.sh)

mkdir -p "$BUILD_DIR"
cp "$BASE/build/agpr_recolor.s" "$BUILD_DIR/ref.s"
python3 "$HERE/patch_zero_srcc_first.py" "$BUILD_DIR/ref.s" "$BUILD_DIR/zero_first.s"

for tag in ref zero_first; do
    "$CLANG23" -x assembler -target amdgcn-amd-amdhsa -mcpu="$ARCH" \
        "$BUILD_DIR/$tag.s" -o "$BUILD_DIR/$tag.co"
    "$TOOLCHAIN/bin/clang-offload-bundler" -type=o \
        -targets=host-x86_64-unknown-linux-gnu-,hipv4-amdgcn-amd-amdhsa--"$ARCH" \
        -input="$BASE/build/host.empty" -input="$BUILD_DIR/$tag.co" \
        -output="$BUILD_DIR/$tag.fb"
    cp "$BASE/build/container.exe" "$BUILD_DIR/$tag.exe"
    "$TOOLCHAIN/bin/llvm-objcopy" \
        --update-section=.hip_fatbin="$BUILD_DIR/$tag.fb" "$BUILD_DIR/$tag.exe"
    chmod +x "$BUILD_DIR/$tag.exe"
    "$TOOLCHAIN/bin/llvm-objcopy" \
        --dump-section=.hip_fatbin="$BUILD_DIR/${tag}_linked.fb" "$BUILD_DIR/$tag.exe"
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
