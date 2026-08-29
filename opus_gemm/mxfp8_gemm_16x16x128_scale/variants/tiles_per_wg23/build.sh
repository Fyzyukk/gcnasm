#!/bin/sh
# OUTPUT_TILES_PER_WG on the clang 23 baseline.
#
# Section 28.7 closed 8/16 as "no gain", but that was measured on clang 20,
# where the hot span carried six redundant `s_waitcnt vmcnt(0)` (section 30.3)
# and the kernel was wait-bound.  The clang 23 ablations re-priced it: killing
# every wait now buys 1%, while removing global traffic buys 19%, and the
# kernel runs at ~7.6 TB/s against an ~8 TB/s practical HBM ceiling.  This knob
# is the direct lever on that traffic -- it sets how many M tiles reuse one
# fetched B tile, so A's re-read factor is tiles_n and B's is tiles_m/PER_WG.
#
# Both TUs must agree on the value: the host computes grid.x from it.
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
VALUES=${VALUES:-"2 4 8 16"}
[ -x "$CLANG23" ] || { echo "ERROR: no clang 23 at $CLANG23" >&2; exit 1; }

FLAGS="-I$TOP -I$OPUS_INCLUDE_DIR -std=c++17 -O3 -ffast-math \
       --offload-arch=$ARCH --rocm-path=$ROCM"
LDFLAGS="-fopenmp -L$ROCM/lib/llvm/lib -lomp -Wl,-rpath,$ROCM/lib/llvm/lib \
         -L$ROCM/lib -lamdhip64 -Wl,-rpath,$ROCM/lib"
B="$HERE/build"; mkdir -p "$B"

for v in $VALUES; do
    D="-DMXFP8_SCALE_OUTPUT_TILES_PER_WG=$v"
    echo "=== PER_WG=$v ==="
    $CLANG23 -x hip "$TOP/gemm_a8w8_mxfp8_scale_kernel_fixed_b_asym_b_read2.cc" \
        $FLAGS $D -D__HIPCC_RTC__ -c -o "$B/k$v.o" 2>&1 | grep -E "error" && exit 1
    $CLANG23 -x hip "$TOP/gemm_a8w8_mxfp8_scale_host_fixed_b_asym_b_read2.cc" \
        $FLAGS $D -fopenmp -I$ROCM/lib/llvm/include -c -o "$B/h$v.o" 2>&1 | grep -E "error" && exit 1
    $CLANG23 "$B/k$v.o" "$B/h$v.o" --offload-arch=$ARCH --rocm-path=$ROCM \
        $LDFLAGS -o "$B/t$v.exe"

    $ROCM/llvm/bin/llvm-objcopy --dump-section=.hip_fatbin="$B/.fb" "$B/t$v.exe" 2>/dev/null
    $ROCM/llvm/bin/clang-offload-bundler -type=o \
        -targets=hipv4-amdgcn-amd-amdhsa--$ARCH -input="$B/.fb" \
        -output="$B/dev_t$v.elf" -unbundle 2>/dev/null; rm -f "$B/.fb"
    n=$($ROCM/llvm/bin/llvm-readelf --notes "$B/dev_t$v.elf" 2>/dev/null)
    printf "  VGPR=%s vspill=%s LDS=%s\n" \
        "$(echo "$n"|awk '/vgpr_count/{print $2}')" \
        "$(echo "$n"|awk '/vgpr_spill_count/{print $2}')" \
        "$(echo "$n"|awk '/group_segment_fixed_size/{print $2}')"
done
