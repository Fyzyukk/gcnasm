#!/bin/sh
# Ablation attribution on the clang 23 baseline.
#
# These diag_* kernels are DELIBERATELY INCORRECT -- they neuter a wait, a
# barrier, or the global loads to price what that construct costs.  Never ship
# one; the numbers are upper bounds on what removing the construct could buy.
#
# Section 28 ran them against clang 20.  Section 30.3 then showed clang 20 was
# carrying six redundant vmcnt(0) in the hot span that clang 23 does not, so
# every one of those attributions was measured against the wrong baseline.
# This re-prices them.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
TOP=$(cd "$HERE/../.." && pwd)

if [ -z "$OPUS_INCLUDE_DIR" ]; then
    for cand in /root/workspace/yanze/aiter/csrc/include \
                /root/workspace/aiter/csrc/include "$HOME/aiter/csrc/include"; do
        [ -f "$cand/opus/hip_minimal.hpp" ] && OPUS_INCLUDE_DIR=$cand && break
    done
fi
CLANG23=${CLANG23:-${CLANG23_ROOT:-/root/workspace/llvm-src/build}/bin/clang++}
ROCM=${ROCM_PATH:-/opt/rocm}
ARCH=${ARCH:-gfx950}
[ -x "$CLANG23" ] || { echo "ERROR: no clang 23 at $CLANG23" >&2; exit 1; }

FLAGS="-I$HERE -I$TOP -I$OPUS_INCLUDE_DIR -std=c++17 -O3 -ffast-math \
       --offload-arch=$ARCH --rocm-path=$ROCM"
LDFLAGS="-fopenmp -L$ROCM/lib/llvm/lib -lomp -Wl,-rpath,$ROCM/lib/llvm/lib \
         -L$ROCM/lib -lamdhip64 -Wl,-rpath,$ROCM/lib"
B="$HERE/build23"; mkdir -p "$B"

[ -f "$B/host.o" ] || $CLANG23 -x hip "$TOP/gemm_a8w8_mxfp8_scale_host_fixed_b_asym_b_read2.cc" \
    $FLAGS -fopenmp -I$ROCM/lib/llvm/include -c -o "$B/host.o"

for k in pure nowait novmwait nobarrier noglobal; do
    [ -f "$HERE/kern_$k.cc" ] || continue
    $CLANG23 -x hip "$HERE/kern_$k.cc" $FLAGS -D__HIPCC_RTC__ -c -o "$B/k_$k.o" 2>&1 \
        | grep -E "^.*error" && exit 1
    $CLANG23 "$B/k_$k.o" "$B/host.o" --offload-arch=$ARCH --rocm-path=$ROCM \
        $LDFLAGS -o "$B/$k.exe"
    echo "built $k"
done
