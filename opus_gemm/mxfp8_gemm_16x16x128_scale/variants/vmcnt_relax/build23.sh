#!/bin/sh
# clang 23 rebuild of the section-28 vmcnt relaxations.
#
# Section 28 measured these on clang 20 and found nothing (VMCNT_RELAX left the
# structure unchanged, SINK_A_PRODUCER lost 3.2%).  Section 30.3 showed why the
# reading was uninformative: clang 20 was already emitting six redundant
# `s_waitcnt vmcnt(0)` in the hot span, so the hand relaxation was competing
# with a much larger compiler-inserted wall.  clang 23 removes those six, and
# the retained u4 build still carries one combined `vmcnt(0) lgkmcnt(0)` per
# unrolled iteration with 32 MFMAs behind it.  That is what this re-tests.
#
#   ./build23.sh                       # off + the default DEF
#   DEF="-DMXFP8_VMCNT_RELAX=2" ./build23.sh
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

CLANG23=${CLANG23:-${CLANG23_ROOT:-/root/workspace/llvm-src/build}/bin/clang++}
ROCM=${ROCM_PATH:-/opt/rocm}
ARCH=${ARCH:-gfx950}
DEF=${DEF:--DMXFP8_VMCNT_RELAX=2}
TAG=${TAG:-on}
[ -x "$CLANG23" ] || { echo "ERROR: no clang 23 at $CLANG23" >&2; exit 1; }

FLAGS="-I$HERE -I$TOP -I$OPUS_INCLUDE_DIR -std=c++17 -O3 -ffast-math \
       --offload-arch=$ARCH --rocm-path=$ROCM"
LDFLAGS="-fopenmp -L$ROCM/lib/llvm/lib -lomp -Wl,-rpath,$ROCM/lib/llvm/lib \
         -L$ROCM/lib -lamdhip64 -Wl,-rpath,$ROCM/lib"
B="$HERE/build23"; mkdir -p "$B"

[ -f "$B/host.o" ] || $CLANG23 -x hip "$TOP/gemm_a8w8_mxfp8_scale_host_fixed_b_asym_b_read2.cc" \
    $FLAGS -fopenmp -I$ROCM/lib/llvm/include -c -o "$B/host.o"

build_one() {   # $1 = tag, $2 = extra defines
    $CLANG23 -x hip "$HERE/gemm_a8w8_mxfp8_scale_kernel_vmcnt_relax.cc" \
        $FLAGS -D__HIPCC_RTC__ $2 -c -o "$B/k_$1.o" 2>&1 | grep -E "error" && exit 1
    $CLANG23 "$B/k_$1.o" "$B/host.o" --offload-arch=$ARCH --rocm-path=$ROCM \
        $LDFLAGS -o "$B/$1.exe"

    # Always read the LINKED exe (section 29.3).
    $ROCM/llvm/bin/llvm-objcopy --dump-section=.hip_fatbin="$B/.fb" "$B/$1.exe" 2>/dev/null
    $ROCM/llvm/bin/clang-offload-bundler -type=o \
        -targets=hipv4-amdgcn-amd-amdhsa--$ARCH -input="$B/.fb" \
        -output="$B/dev_$1.elf" -unbundle 2>/dev/null
    rm -f "$B/.fb"
    python3 - "$B/dev_$1.elf" "$1" <<'PY'
import subprocess,re,sys
L=subprocess.run(['/opt/rocm/llvm/bin/llvm-objdump','-d',sys.argv[1]],
                 capture_output=True,text=True).stdout.split('\n')
idx=[i for i,l in enumerate(L) if 'v_mfma' in l]
seg=[l for l in L[min(idx):max(idx)+1] if re.match(r'\t[a-z]',l)]
vm=sum(1 for l in seg if re.match(r'\ts_waitcnt',l) and 'vmcnt' in l)
lg=sum(1 for l in seg if re.match(r'\ts_waitcnt',l) and 'vmcnt' not in l)
mf=sum(1 for l in seg if 'v_mfma' in l)
n=subprocess.run(['/opt/rocm/llvm/bin/llvm-readelf','--notes',sys.argv[1]],
                 capture_output=True,text=True).stdout
g=lambda k:(re.search(k+r':\s*(\d+)',n) or [0,'?'])[1]
print(f"  {sys.argv[2]:6s} mfma={mf:4d} hot_vmcnt_waits={vm:3d} lgkm={lg:3d} "
      f"VGPR={g('vgpr_count')} vspill={g('vgpr_spill_count')}")
PY
}

echo "=== off (retained behaviour) ==="; build_one off ""
echo "=== $TAG ($DEF) ===";             build_one "$TAG" "$DEF"
