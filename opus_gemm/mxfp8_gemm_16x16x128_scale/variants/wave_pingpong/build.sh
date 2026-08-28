#!/bin/sh
# Self-contained A/B build for the MXFP8_WAVE_PINGPONG change.
#
# Builds two binaries from the SAME template file:
#   build/off.exe  -- retained winner behaviour (if / else-if scale producer)
#   build/on.exe   -- MXFP8_WAVE_PINGPONG=1  (independent predicated blocks)
#
# The only difference between them is one preprocessor define, so any delta is
# attributable to the descriptor-sinking fix alone.
#
# Usage:  ./build.sh          then  ./bench.sh
set -e

HERE=$(cd "$(dirname "$0")" && pwd)
TOP=$(cd "$HERE/../.." && pwd)

# Where opus/hip_minimal.hpp lives.  Override with OPUS_INCLUDE_DIR=... if the
# aiter checkout sits somewhere else on your machine.
if [ -z "$OPUS_INCLUDE_DIR" ]; then
    for cand in /root/workspace/aiter/csrc/include \
                /root/workspace/yanze/aiter/csrc/include \
                "$HOME/aiter/csrc/include"; do
        [ -f "$cand/opus/hip_minimal.hpp" ] && OPUS_INCLUDE_DIR=$cand && break
    done
fi
if [ ! -f "$OPUS_INCLUDE_DIR/opus/hip_minimal.hpp" ]; then
    echo "ERROR: opus headers not found. Set OPUS_INCLUDE_DIR=<aiter>/csrc/include" >&2
    exit 1
fi
echo "OPUS_INCLUDE_DIR=$OPUS_INCLUDE_DIR"
HIPCC=${HIPCC:-/opt/rocm/bin/hipcc}
ARCH=${ARCH:-gfx950}

FLAGS="-I$HERE -I$TOP -I$OPUS_INCLUDE_DIR -std=c++17 -fopenmp -O3 -Wall --offload-arch=$ARCH -ffast-math"

mkdir -p "$HERE/build"
cd "$HERE/build"

# Host launcher is shared and unmodified.
if [ ! -f host.o ]; then
    echo "=== host ==="
    $HIPCC "$TOP/gemm_a8w8_mxfp8_scale_host_fixed_b_asym_b_read2.cc" $FLAGS -c -o host.o
fi

for cfg in off on; do
    if [ "$cfg" = "on" ]; then
        DEF="-DMXFP8_WAVE_PINGPONG=1"
    else
        DEF=""
    fi
    echo "=== kernel: $cfg ==="
    $HIPCC "$HERE/gemm_a8w8_mxfp8_scale_kernel_wave_pingpong.cc" $FLAGS $DEF \
           -D__HIPCC_RTC__ -Rpass-analysis=kernel-resource-usage \
           -save-temps=obj -c -o "kernel_$cfg.o" 2>&1 \
        | grep -E "VGPRs|SGPRs|Occupancy|ScratchSize|LDS" || true
    # -save-temps=obj drops temps beside -o; keep the gfx950 asm per config.
    mv -f *gfx950.s "isa_$cfg.s"
    $HIPCC "kernel_$cfg.o" host.o --offload-arch=$ARCH -fopenmp -o "$cfg.exe"
done

echo ""
echo "=== ISA scratch / vmcnt(0) counts (lower is better) ==="
for cfg in off on; do
    S="isa_$cfg.s"
    if [ -f "$S" ]; then
        printf "%-4s scratch_load=%-4s scratch_store=%-4s vmcnt(0)=%-4s  (%s)\n" \
            "$cfg" \
            "$(grep -c 'scratch_load' "$S")" \
            "$(grep -c 'scratch_store' "$S")" \
            "$(grep -c 's_waitcnt vmcnt(0)' "$S")" \
            "$S"
    fi
done
echo ""
echo "Built: $HERE/build/off.exe  $HERE/build/on.exe"
