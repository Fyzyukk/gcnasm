#!/bin/bash
# Portable cross-machine measurement protocol.
#
#   ./measure.sh <amd_smi_gpu_id> <hip_device_id> [label]
#
# Produces the full record needed to compare two machines: contention check,
# pure-MFMA peak, GEMM at short AND long protocol, all with load-synchronous
# telemetry filtered to busy samples, plus the clock-normalized efficiency.
set -u
GPU=${1:?amd-smi gpu id}; HIPDEV=${2:?hip device id}; LABEL=${3:-$(hostname)}
HERE=$(cd "$(dirname "$0")" && pwd)
BIN=${BIN:-$HERE/../../build/gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2.exe}
export LD_LIBRARY_PATH=/opt/rocm/lib/llvm/lib:${LD_LIBRARY_PATH:-}

echo "================================================================"
echo "MACHINE: $LABEL   amd-smi GPU=$GPU  HIP_VISIBLE_DEVICES=$HIPDEV"
echo "date: $(date -Is)"
echo "================================================================"

echo; echo "### 0. identity"
amd-smi static -g $GPU --asic 2>/dev/null | grep -iE 'market|vram|name|rev' | head -6
amd-smi static -g $GPU --limit 2>/dev/null | grep -iE 'max_power|socket_power'
amd-smi partition -g $GPU 2>/dev/null | grep -iE 'memory|accelerator|nps|spx' | head -4
echo "hipcc: $(/opt/rocm/bin/hipcc --version 2>/dev/null | head -1)"
echo "kfd/driver: $(cat /sys/module/amdgpu/version 2>/dev/null || echo n/a)"
amd-smi static -g $GPU --vbios 2>/dev/null | grep -iE 'version|part' | head -3

echo; echo "### 1. contention guard (MUST be CLEAN)"
python3 "$HERE/guard.py" $GPU || echo ">>> WARNING: results below are NOT comparable across machines <<<"

echo; echo "### 2. pure-MFMA peak (denominator)"
HIP_VISIBLE_DEVICES=$HIPDEV python3 "$HERE/sample.py" $GPU "$HERE/mfma_peak" 20000 5 2>&1 \
  | grep -E 'MFMA_PEAK|SCLK|POWER|HOTSPOT|PPT'

echo; echo "### 3. GEMM 8192^3 -- SHORT protocol (200 warmup + 100 iters)"
echo "    [this is the protocol that produced the 2.65 P number]"
for r in 1 2 3; do
  HIP_VISIBLE_DEVICES=$HIPDEV $BIN -m 8192 -n 8192 -k 8192 -v 0 -w 200 -i 100 2>&1 \
    | grep -o 'avg_time=[0-9.]* ms, [0-9.]* TFlops'
done
HIP_VISIBLE_DEVICES=$HIPDEV python3 "$HERE/sample.py" $GPU $BIN -m 8192 -n 8192 -k 8192 -v 0 -w 200 -i 100 2>&1 \
  | grep -E 'SCLK|POWER|HOTSPOT|PPT'

echo; echo "### 4. GEMM 8192^3 -- LONG protocol (1000 warmup + 1000 iters, steady state)"
for r in 1 2 3; do
  HIP_VISIBLE_DEVICES=$HIPDEV $BIN -m 8192 -n 8192 -k 8192 -v 0 -w 1000 -i 1000 2>&1 \
    | grep -o 'avg_time=[0-9.]* ms, [0-9.]* TFlops'
done
HIP_VISIBLE_DEVICES=$HIPDEV python3 "$HERE/sample.py" $GPU $BIN -m 8192 -n 8192 -k 8192 -v 0 -w 1000 -i 1000 2>&1 \
  | grep -E 'SCLK|POWER|HOTSPOT|PPT'

echo; echo "### 5. soak time-series (is the clock stable, or decaying?)"
HIP_VISIBLE_DEVICES=$HIPDEV python3 "$HERE/series.py" $GPU $BIN -m 8192 -n 8192 -k 8192 -v 0 -w 2000 -i 6000 2>&1 | tail -45

echo; echo "================================================================"
echo "Report sections 1-5 verbatim.  Compare machines on:"
echo "  (a) LONG-protocol PFLOPS  (b) busy-only SCLK  (c) eff = FLOP/cyc ratio"
echo "Do NOT compare short-protocol numbers across machines -- they capture boost."
echo "================================================================"
