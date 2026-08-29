#!/bin/sh
# Sweep the main K-loop unroll factor on clang 23.
#
# Section 29 established that unrolling is worth +16%, but never varied the
# factor -- `#pragma unroll 4` is simply what the source said, and clang
# answers it with a 3x body (64 -> 192 MFMA).  This builds one exe per factor
# and records what the compiler actually produced (MFMA count, VGPR, spills)
# alongside it, because the pragma is a request, not an instruction.
#
#   ./build.sh            # all factors
#   FACTORS="4 6" ./build.sh
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
TOP=$(cd "$HERE/../.." && pwd)

if [ -z "$OPUS_INCLUDE_DIR" ]; then
    for cand in /root/workspace/yanze/aiter/csrc/include \
                /root/workspace/aiter/csrc/include "$HOME/aiter/csrc/include"; do
        [ -f "$cand/opus/hip_minimal.hpp" ] && OPUS_INCLUDE_DIR=$cand && break
    done
fi
[ -f "$OPUS_INCLUDE_DIR/opus/hip_minimal.hpp" ] || {
    echo "ERROR: set OPUS_INCLUDE_DIR=<aiter>/csrc/include" >&2; exit 1; }

CLANG23_ROOT=${CLANG23_ROOT:-/root/workspace/llvm-src/build}
CLANG23=${CLANG23:-$CLANG23_ROOT/bin/clang++}
ROCM=${ROCM_PATH:-/opt/rocm}
ARCH=${ARCH:-gfx950}
FACTORS=${FACTORS:-"1 2 3 4 6 8"}

[ -x "$CLANG23" ] || { echo "ERROR: no clang 23 at $CLANG23 -- run tools/build_clang23.sh" >&2; exit 1; }

FLAGS="-I$TOP -I$OPUS_INCLUDE_DIR -std=c++17 -O3 -ffast-math --offload-arch=$ARCH --rocm-path=$ROCM"
LDFLAGS="-fopenmp -L$ROCM/lib/llvm/lib -lomp -Wl,-rpath,$ROCM/lib/llvm/lib \
         -L$ROCM/lib -lamdhip64 -Wl,-rpath,$ROCM/lib"

B="$HERE/build"; mkdir -p "$B"

# Host TU is factor-independent -- build once.
[ -f "$B/host.o" ] || $CLANG23 -x hip "$TOP/gemm_a8w8_mxfp8_scale_host_fixed_b_asym_b_read2.cc" \
    $FLAGS -fopenmp -I$ROCM/lib/llvm/include -c -o "$B/host.o"

for f in $FACTORS; do
    echo "=== unroll $f ==="
    $CLANG23 -x hip "$TOP/gemm_a8w8_mxfp8_scale_kernel_fixed_b_asym_b_read2.cc" \
        $FLAGS -D__HIPCC_RTC__ -DMXFP8_MAIN_LOOP_UNROLL=$f -c -o "$B/k$f.o"
    $CLANG23 "$B/k$f.o" "$B/host.o" --offload-arch=$ARCH --rocm-path=$ROCM \
        $LDFLAGS -o "$B/u$f.exe"

    # What the compiler actually did.  Read the LINKED exe, never the kernel
    # TU's .s -- section 29.3 is exactly the bug of trusting the earlier step.
    $ROCM/llvm/bin/llvm-objcopy --dump-section=.hip_fatbin="$B/.fb" "$B/u$f.exe" 2>/dev/null
    $ROCM/llvm/bin/clang-offload-bundler -type=o \
        -targets=hipv4-amdgcn-amd-amdhsa--$ARCH -input="$B/.fb" \
        -output="$B/.dev" -unbundle 2>/dev/null
    MFMA=$($ROCM/llvm/bin/llvm-objdump -d "$B/.dev" 2>/dev/null \
           | grep -c v_mfma_scale_f32_16x16x128)
    VGPR=$($ROCM/llvm/bin/llvm-readelf --notes "$B/.dev" 2>/dev/null \
           | awk '/vgpr_count/{print $2}')
    SPILL=$($ROCM/llvm/bin/llvm-readelf --notes "$B/.dev" 2>/dev/null \
            | awk '/vgpr_spill_count/{print $2}')
    SGSP=$($ROCM/llvm/bin/llvm-readelf --notes "$B/.dev" 2>/dev/null \
           | awk '/sgpr_spill_count/{print $2}')
    cp -f "$B/.dev" "$B/dev_u$f.elf"
    rm -f "$B/.fb" "$B/.dev"
    echo "$f $MFMA $VGPR $SPILL $SGSP" >> "$B/isa.txt"
    printf "  MFMA=%-5s VGPR=%-4s vspill=%-3s sspill=%s\n" "$MFMA" "$VGPR" "$SPILL" "$SGSP"
done

echo ""
echo "factor  MFMA  VGPR  vspill  sspill"
sort -n -u -k1,1 "$B/isa.txt" | awk '{printf "%-7s %-5s %-5s %-7s %s\n",$1,$2,$3,$4,$5}'
