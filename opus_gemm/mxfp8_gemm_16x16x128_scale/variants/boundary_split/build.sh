#!/bin/sh
# Boundary-cost candidates on the unified-scale kernel.
#
# ATT (trace_att_dec) attribution of the retained unified-scale build:
#   main-loop boundary `s_waitcnt vmcnt(0) lgkmcnt(0)` + `s_barrier` = 27.0%
#   of all kernel latency.  Most of that is NOT recoverable: the resident pair
#   interleaves, so one wave stalling while the other computes is free.  The
#   recoverable part is the window where BOTH waves of a SIMD are stalled:
#     sl0 in BARRIER + sl1 in WAIT   12.09%   <- the target
#     sl0 in BARRIER + sl1 in BARRIER 1.71%
#     sl0 in WAIT    + sl1 in WAIT    1.48%
#
# off  -- retained unified-scale behaviour, byte-for-byte
# a    -- MXFP8_HOIST_A:        issue A(t+1)/scale(t+1) at the top of the body
# b    -- MXFP8_ALT_PRODUCER:   alternate the B-producer wave by tile parity
# ab   -- both
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
TOP=$(cd "$HERE/../.." && pwd)

if [ -z "$OPUS_INCLUDE_DIR" ]; then
    for cand in /root/workspace/aiter/csrc/include \
                /root/workspace/yanze/aiter/csrc/include "$HOME/aiter/csrc/include"; do
        [ -f "$cand/opus/hip_minimal.hpp" ] && OPUS_INCLUDE_DIR=$cand && break
    done
fi
CLANG23=${CLANG23:-${CLANG23_ROOT:-/root/workspace/llvm-src/build}/bin/clang++}
ROCM=${ROCM_PATH:-/opt/rocm}
ARCH=${ARCH:-gfx950}
OMP_LIB=$ROCM/lib/llvm/lib
[ -x "$CLANG23" ] || { echo "ERROR: no clang 23 at $CLANG23" >&2; exit 1; }

FLAGS="-I$HERE -I$TOP -I$OPUS_INCLUDE_DIR -std=c++17 -O3 -ffast-math \
       --offload-arch=$ARCH --rocm-path=$ROCM"
LDFLAGS="-fopenmp -L$OMP_LIB -lomp -Wl,-rpath,$OMP_LIB \
         -L$ROCM/lib -lamdhip64 -Wl,-rpath,$ROCM/lib"
B="$HERE/build"; mkdir -p "$B"

[ -f "$B/host.o" ] || $CLANG23 -x hip \
    "$TOP/gemm_a8w8_mxfp8_scale_host_fixed_b_asym_b_read2_unified_scale.cc" \
    $FLAGS -fopenmp -I$ROCM/lib/llvm/include -c -o "$B/host.o"

build_one() {
    tag=$1; shift
    $CLANG23 -x hip "$HERE/kern.cc" $FLAGS -D__HIPCC_RTC__ "$@" -c -o "$B/k_$tag.o"
    $CLANG23 "$B/k_$tag.o" "$B/host.o" --offload-arch=$ARCH --rocm-path=$ROCM \
        $LDFLAGS -o "$B/$tag.exe"
    # Gate: the loop must still unroll, and we must see the real device image.
    $ROCM/llvm/bin/llvm-objcopy --dump-section=.hip_fatbin="$B/.fb" "$B/$tag.exe"
    $ROCM/llvm/bin/clang-offload-bundler -type=o \
        -targets=hipv4-amdgcn-amd-amdhsa--$ARCH -input="$B/.fb" \
        -output="$B/dev_$tag.elf" -unbundle
    $ROCM/llvm/bin/llvm-objdump -d --mcpu=$ARCH "$B/dev_$tag.elf" > "$B/isa_$tag.s"
    n=$(grep -c v_mfma_scale_f32_16x16x128 "$B/isa_$tag.s")
    scr=$(grep -c 'scratch_' "$B/isa_$tag.s" || true)
    vg=$($ROCM/llvm/bin/llvm-readelf --notes "$B/dev_$tag.elf" \
         | grep -o '\.vgpr_count:[^,}]*' | head -1)
    printf 'built %-4s  MFMA=%-4s scratch=%-3s %s\n' "$tag" "$n" "$scr" "$vg"
    [ "$n" -ge 192 ] || { echo "FAIL $tag: loop did not unroll ($n MFMA)"; exit 1; }
    [ "$scr" = 0 ]   || { echo "FAIL $tag: $scr scratch instructions"; exit 1; }
}

TAGS=${TAGS:-"off a b ab"}
for t in $TAGS; do
    case $t in
    off) build_one off -DMXFP8_HOIST_A=0 -DMXFP8_ALT_PRODUCER=0 ;;
    a)   build_one a   -DMXFP8_HOIST_A=1 -DMXFP8_ALT_PRODUCER=0 ;;
    b)   build_one b   -DMXFP8_HOIST_A=0 -DMXFP8_ALT_PRODUCER=1 ;;
    ab)  build_one ab  -DMXFP8_HOIST_A=1 -DMXFP8_ALT_PRODUCER=1 ;;
    esac
done
rm -f "$B/.fb"
