#!/usr/bin/env bash
# Build clang 23 from ROCm's llvm-project fork.
#
# Why: clang 20/21/22 refuse to unroll the main K loop in
# gemm_a8w8_mxfp8_scale_kernel_template_fixed_b_asym_b_read2.hpp -- they emit
# "loop not unrolled" for the `#pragma unroll 4` and leave 64 MFMA in the body.
# clang 23 unrolls it 3x (192 MFMA), worth ~+13% on gfx950 (2.45 P -> 2.77 P).
# No apt repo ships clang 23 yet, so it has to come from source.
#
# ~5 min on 256 cores.  Needs ~30 GB of disk for the build tree.
set -euo pipefail

SRC=${SRC:-/root/workspace/llvm-src}
# Pinned to the revision the 192-MFMA result was measured against.
REV=${REV:-46fcb339fb61119b337f973c7ca9e710a319fdd0}
JOBS=${JOBS:-$(nproc)}

if [ ! -d "$SRC/.git" ]; then
  git clone https://github.com/ROCm/llvm-project.git "$SRC"
fi
git -C "$SRC" fetch --all
git -C "$SRC" checkout "$REV"

cmake -S "$SRC/llvm" -B "$SRC/build" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_TARGETS_TO_BUILD="AMDGPU;X86" \
  -DLLVM_ENABLE_ASSERTIONS=OFF \
  -DCLANG_DEFAULT_LINKER=lld \
  -DLLVM_INCLUDE_TESTS=OFF -DCLANG_INCLUDE_TESTS=OFF \
  -DLLVM_INCLUDE_BENCHMARKS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF

ninja -C "$SRC/build" -j "$JOBS" clang lld

"$SRC/build/bin/clang++" --version
echo "Now: make clang23 CLANG23_ROOT=$SRC/build"
