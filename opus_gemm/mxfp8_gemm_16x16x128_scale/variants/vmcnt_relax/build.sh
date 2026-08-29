#!/bin/sh
# Single-variable A/B build for the hot-path vmcnt wall.
#   build/off.exe  -- retained winner behaviour
#   build/on.exe   -- one -D only
# DEF may be overridden:  DEF="-DMXFP8_SINK_A_PRODUCER=1" ./build.sh
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
TOP=$(cd "$HERE/../.." && pwd)
if [ -z "$OPUS_INCLUDE_DIR" ]; then
    for cand in /root/workspace/aiter/csrc/include \
                /root/workspace/yanze/aiter/csrc/include "$HOME/aiter/csrc/include"; do
        [ -f "$cand/opus/hip_minimal.hpp" ] && OPUS_INCLUDE_DIR=$cand && break
    done
fi
[ -f "$OPUS_INCLUDE_DIR/opus/hip_minimal.hpp" ] || {
    echo "ERROR: set OPUS_INCLUDE_DIR=<aiter>/csrc/include" >&2; exit 1; }
HIPCC=${HIPCC:-/opt/rocm/bin/hipcc}
ARCH=${ARCH:-gfx950}
DEF=${DEF:--DMXFP8_SINK_A_PRODUCER=1}
FLAGS="-I$HERE -I$TOP -I$OPUS_INCLUDE_DIR -std=c++17 -fopenmp -O3 --offload-arch=$ARCH -ffast-math"
mkdir -p "$HERE/build"; cd "$HERE/build"
[ -f host.o ] || $HIPCC "$TOP/gemm_a8w8_mxfp8_scale_host_fixed_b_asym_b_read2.cc" $FLAGS -c -o host.o
for cfg in off on; do
    [ "$cfg" = on ] && D="$DEF" || D=""
    echo "=== $cfg ($D) ==="
    $HIPCC "$HERE/gemm_a8w8_mxfp8_scale_kernel_vmcnt_relax.cc" $FLAGS $D \
        -D__HIPCC_RTC__ -Rpass-analysis=kernel-resource-usage -save-temps=obj \
        -c -o "kernel_$cfg.o" 2>&1 | grep -E "VGPRs|SGPRs|Occupancy|Spill|LDS" || true
    mv -f *gfx950.s "isa_$cfg.s"
    $HIPCC "kernel_$cfg.o" host.o --offload-arch=$ARCH -fopenmp -o "$cfg.exe"
done
echo ""
python3 "$HERE/hotpath.py"
