#!/bin/sh
# How many of the four cold-B loads for tile t+2 stay on the primary producer.
#
# 27.12 measured 4 (retained) and 2 (even split, ~1% slower).  3 and 1 were
# never measured.  ATT motivation: the 4/0 producer carries 9 outstanding VMEM
# at the boundary against its partner's 5 and is last to arrive at 95% of
# boundaries, ~860 cyc late; the pair's joint stall window is 12.09% of kernel
# latency and 3 P needs only 24% of it back.
#
# u_gb_producer_0/1 hard-code wave_id_n = 0/1 and vary only with wave_id_m and
# lane_id, and the partner shares wave_id_m -- so a load moved to the partner
# addresses exactly the same bytes.  Correctness gate still applies.
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
    $ROCM/llvm/bin/llvm-objcopy --dump-section=.hip_fatbin="$B/.fb" "$B/$tag.exe"
    $ROCM/llvm/bin/clang-offload-bundler -type=o \
        -targets=hipv4-amdgcn-amd-amdhsa--$ARCH -input="$B/.fb" \
        -output="$B/dev_$tag.elf" -unbundle
    $ROCM/llvm/bin/llvm-objdump -d --mcpu=$ARCH "$B/dev_$tag.elf" > "$B/isa_$tag.s"
    n=$(grep -c v_mfma_scale_f32_16x16x128 "$B/isa_$tag.s")
    scr=$(grep -c 'scratch_' "$B/isa_$tag.s" || true)
    ld=$(grep -c 'buffer_load_dwordx4.* lds' "$B/isa_$tag.s" || true)
    vg=$($ROCM/llvm/bin/llvm-readelf --notes "$B/dev_$tag.elf" \
         | grep -o '\.vgpr_count:[^,}]*' | head -1)
    printf 'built %-4s MFMA=%-4s load2lds=%-4s scratch=%-3s %s\n' "$tag" "$n" "$ld" "$scr" "$vg"
    [ "$n" -ge 192 ] || { echo "FAIL $tag: loop did not unroll ($n MFMA)"; exit 1; }
    [ "$scr" = 0 ]   || { echo "FAIL $tag: $scr scratch instructions"; exit 1; }
}

TAGS=${TAGS:-"s4 s3 s2 s1"}
for t in $TAGS; do
    case $t in
    s4) build_one s4 -DMXFP8_B_SPLIT=4 ;;   # == retained
    s3) build_one s3 -DMXFP8_B_SPLIT=3 ;;   # never measured
    s2) build_one s2 -DMXFP8_B_SPLIT=2 ;;   # 27.12's even split
    s1) build_one s1 -DMXFP8_B_SPLIT=1 ;;   # never measured
    esac
done
rm -f "$B/.fb"
