#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
TOOLCHAIN=${TOOLCHAIN:-/root/toolchains/rocm-llvm23-46fcb339-build}
CLANG23="$TOOLCHAIN/bin/clang++"
ROCM=${ROCM_PATH:-/opt/rocm}
OPUS_INCLUDE_DIR=${OPUS_INCLUDE_DIR:-/root/workspace/aiter/csrc/include}
BUILD_NAME=${1:-build}
if [[ ! "$BUILD_NAME" =~ ^[a-zA-Z0-9_][a-zA-Z0-9_.-]*$ ]]; then
    echo "build name must be a direct child directory name" >&2
    exit 1
fi
BUILD_DIR="$HERE/$BUILD_NAME"
[[ ! -e "$BUILD_DIR" ]] || {
    echo "refusing to overwrite $BUILD_DIR; pass a new build name" >&2
    exit 1
}
[[ -x "$CLANG23" ]] || { echo "missing clang23: $CLANG23" >&2; exit 1; }
[[ -f "$OPUS_INCLUDE_DIR/opus/hip_minimal.hpp" ]] || {
    echo "missing OPUS headers: $OPUS_INCLUDE_DIR" >&2; exit 1;
}
mkdir "$BUILD_DIR"
exec > >(tee "$BUILD_DIR/build.log") 2>&1

FLAGS=(-I"$HERE" -I"$OPUS_INCLUDE_DIR" -std=c++17 -O3 -ffast-math
       --offload-arch=gfx950 --rocm-path="$ROCM")
LDFLAGS=(-fopenmp -L"$ROCM/lib/llvm/lib" -lomp
         -Wl,-rpath,"$ROCM/lib/llvm/lib" -L"$ROCM/lib" -lamdhip64
         -Wl,-rpath,"$ROCM/lib")
"$CLANG23" --version
"$CLANG23" -x hip "$HERE/host.cc" "${FLAGS[@]}" \
    -fopenmp -I"$ROCM/lib/llvm/include" -c -o "$BUILD_DIR/host.o"
"$CLANG23" -x hip "$HERE/kern.cc" "${FLAGS[@]}" \
    -D__HIPCC_RTC__ -c -o "$BUILD_DIR/kernel.o"
"$CLANG23" "$BUILD_DIR/kernel.o" "$BUILD_DIR/host.o" \
    --offload-arch=gfx950 --rocm-path="$ROCM" "${LDFLAGS[@]}" \
    -o "$BUILD_DIR/kernel.exe"
"$TOOLCHAIN/bin/llvm-objcopy" \
    --dump-section=.hip_fatbin="$BUILD_DIR/kernel.fb" "$BUILD_DIR/kernel.exe"
"$TOOLCHAIN/bin/clang-offload-bundler" -type=o \
    -targets=hipv4-amdgcn-amd-amdhsa--gfx950 \
    -input="$BUILD_DIR/kernel.fb" -output="$BUILD_DIR/kernel.co" -unbundle
"$TOOLCHAIN/bin/llvm-objdump" -d --mcpu=gfx950 "$BUILD_DIR/kernel.co" \
    > "$BUILD_DIR/kernel.isa"
"$TOOLCHAIN/bin/llvm-readelf" --notes "$BUILD_DIR/kernel.co" \
    > "$BUILD_DIR/kernel.notes"
python3 -B "$HERE/gate.py" "$BUILD_DIR" | tee "$BUILD_DIR/static_gate.log"
python3 -B "$HERE/tools/build_manifest.py" "$BUILD_DIR"
echo "PASS: $BUILD_DIR/kernel.exe"
