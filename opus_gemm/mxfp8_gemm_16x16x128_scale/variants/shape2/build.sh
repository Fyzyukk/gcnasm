#!/bin/sh
# Gate: does deriving sfb_half_st64 change the 256x256 opcode stream?
#
# The K sweep (K=256..8192, M=N=8192) fits to
#     t(K) = 0.0460 ms + 4.060e-5 ms/K
# i.e. at K=8192 the main loop is 0.3314 ms (steady state 3.31 P) and a
# K-independent 0.0460 ms (12.2%) sits on top.  0.0460 ms is also exactly
# what 134 MB of bf16 C at ~2.9 TB/s would cost, so the epilogue store is the
# prime suspect.  This ablation tests that directly.
#
# base    -- retained unified-scale behaviour, byte-for-byte
# nocs    -- MXFP8_NO_CSTORE: 3 of 4 C stores removed (WRONG results, timing only)
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


build_one() {
    tag=$1; bm=$2; bn=$3; shift 3
    TR="-DMXFP8_SCALE_TRAITS=gemm_a8w8_mxfp8_scale_traits<$bm,$bn,128,1,1,32>"
    $CLANG23 -x hip "$HERE/kern.cc" $FLAGS -D__HIPCC_RTC__ "$TR" "$@" -c -o "$B/k_$tag.o"
    $CLANG23 -x hip \
        "$TOP/gemm_a8w8_mxfp8_scale_host_fixed_b_asym_b_read2_unified_scale.cc" \
        $FLAGS "$TR" -fopenmp -I$ROCM/lib/llvm/include -c -o "$B/h_$tag.o"
    $CLANG23 "$B/k_$tag.o" "$B/h_$tag.o" --offload-arch=$ARCH --rocm-path=$ROCM \
        $LDFLAGS -o "$B/$tag.exe"
    # Always disassemble the LINKED exe, never the kernel TU's .s.
    $ROCM/llvm/bin/llvm-objcopy --dump-section=.hip_fatbin="$B/.fb" "$B/$tag.exe"
    $ROCM/llvm/bin/clang-offload-bundler -type=o \
        -targets=hipv4-amdgcn-amd-amdhsa--$ARCH -input="$B/.fb" \
        -output="$B/dev_$tag.elf" -unbundle
    $ROCM/llvm/bin/llvm-objdump -d --mcpu=$ARCH "$B/dev_$tag.elf" > "$B/isa_$tag.s"
    n=$(grep -c v_mfma_scale_f32_16x16x128 "$B/isa_$tag.s")
    scr=$(grep -c 'scratch_' "$B/isa_$tag.s" || true)
    st=$(grep -cE 'global_store|buffer_store' "$B/isa_$tag.s" || true)
    bar=$(grep -c 's_barrier' "$B/isa_$tag.s" || true)
    vg=$($ROCM/llvm/bin/llvm-readelf --notes "$B/dev_$tag.elf" \
         | grep -o '\.vgpr_count:[^,}]*' | head -1)
    lds=$($ROCM/llvm/bin/llvm-readelf --notes "$B/dev_$tag.elf" \
         | grep -o '\.group_segment_fixed_size:[^,}]*' | head -1)
    printf 'built %-5s MFMA=%-4s bar=%-4s stores=%-4s scratch=%-3s %s %s\n' "$tag" "$n" "$bar" "$st" "$scr" "$vg" "$lds"
    [ "$n" -ge 192 ] || { echo "FAIL $tag: loop did not unroll ($n MFMA)"; exit 1; }
    [ "$scr" = 0 ]   || { echo "FAIL $tag: $scr scratch instructions"; exit 1; }
}

TAGS=${TAGS:-"sq n128 m128"}
for t in $TAGS; do
    case $t in
    sq)    build_one sq    256 256 ;;
    n128)  build_one n128  256 128 ;;
    m128)  build_one m128  128 256 ;;
    esac
done
rm -f "$B/.fb"
