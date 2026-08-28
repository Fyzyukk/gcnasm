#!/bin/sh
# Stage-1 screen: compile every candidate and report structure metrics only.
# No timing here -- the point is to reject candidates cheaply so that only
# structurally-improved ones cost ABBA blocks.
#
# Candidates:
#   base            control, unchanged
#   vmem            +0x20 VMEM group barrier, ALL sched_barrier(0) kept
#   vmem+bN         +0x20 and release barrier N only  (N = 0..7)
#   vmem+all        +0x20 and release all eight (== rejected vmem_interleave)
#
#   ONLY=<list>     restrict to given candidate names, e.g. ONLY="base vmem"
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
TOP=$(cd "$HERE/../.." && pwd)

if [ -z "$OPUS_INCLUDE_DIR" ]; then
    for cand in /root/workspace/aiter/csrc/include \
                /root/workspace/yanze/aiter/csrc/include \
                "$HOME/aiter/csrc/include"; do
        [ -f "$cand/opus/hip_minimal.hpp" ] && OPUS_INCLUDE_DIR=$cand && break
    done
fi
[ -f "$OPUS_INCLUDE_DIR/opus/hip_minimal.hpp" ] || {
    echo "ERROR: set OPUS_INCLUDE_DIR=<aiter>/csrc/include" >&2; exit 1; }

HIPCC=${HIPCC:-/opt/rocm/bin/hipcc}
ARCH=${ARCH:-gfx950}
FLAGS="-I$HERE -I$TOP -I$OPUS_INCLUDE_DIR -std=c++17 -fopenmp -O3 --offload-arch=$ARCH -ffast-math"

mkdir -p "$HERE/build"
cd "$HERE/build"

[ -f host.o ] || $HIPCC "$TOP/gemm_a8w8_mxfp8_scale_host_fixed_b_asym_b_read2.cc" $FLAGS -c -o host.o

CANDS="base vmem"
i=0
while [ $i -le 7 ]; do CANDS="$CANDS vmem+b$i"; i=$((i + 1)); done
CANDS="$CANDS vmem+all"
[ -n "$ONLY" ] && CANDS="$ONLY"

for c in $CANDS; do
    case "$c" in
        base)     DEF="" ;;
        vmem)     DEF="-DMXFP8_VMEM_GROUP=1 -DMXFP8_SCHED_RELEASE=0" ;;
        vmem+all) DEF="-DMXFP8_VMEM_GROUP=1 -DMXFP8_SCHED_RELEASE=255" ;;
        vmem+b*)  N=${c#vmem+b}; M=$((1 << N))
                  DEF="-DMXFP8_VMEM_GROUP=1 -DMXFP8_SCHED_RELEASE=$M" ;;
    esac
    TAG=$(echo "$c" | tr '+' '_')
    RES=$($HIPCC "$HERE/gemm_a8w8_mxfp8_scale_kernel_sched_probe.cc" $FLAGS $DEF \
              -D__HIPCC_RTC__ -Rpass-analysis=kernel-resource-usage \
              -save-temps=obj -c -o "k_$TAG.o" 2>&1) || { echo "$c BUILD FAILED"; continue; }
    mv -f *gfx950.s "isa_$TAG.s"
    V=$(echo "$RES"  | grep -oP 'VGPRs: \K[0-9]+'                | head -1)
    SG=$(echo "$RES" | grep -oP 'TotalSGPRs: \K[0-9]+'           | head -1)
    SP=$(echo "$RES" | grep -oP 'VGPRs Spill: \K[0-9]+'          | head -1)
    SS=$(echo "$RES" | grep -oP 'SGPRs Spill: \K[0-9]+'          | head -1)
    OC=$(echo "$RES" | grep -oP 'Occupancy \[waves/SIMD\]: \K[0-9]+' | head -1)
    echo "$c|$TAG|$V|$SG|$SP|$SS|$OC" >> .res.txt
    $HIPCC "k_$TAG.o" host.o --offload-arch=$ARCH -fopenmp -o "$TAG.exe" 2>/dev/null || true
done

python3 "$HERE/decile.py"
rm -f .res.txt
