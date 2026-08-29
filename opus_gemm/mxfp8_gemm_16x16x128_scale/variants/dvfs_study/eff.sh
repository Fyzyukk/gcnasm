#!/bin/bash
# Normalized efficiency: eff = kernel FLOP/cycle / pure-MFMA FLOP/cycle.
# Both measured at the SAME locked clock so DVFS cancels out of the ratio.
set -u
GPU=5; HIPDEV=7
D=/root/workspace/gcnasm/opus_gemm/mxfp8_gemm_16x16x128_scale
BIN=$D/build/gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2.exe
export LD_LIBRARY_PATH=/opt/rocm/lib/llvm/lib:${LD_LIBRARY_PATH:-}
S=$D/variants/dvfs_study/sample.py
trap 'echo "[restore] AUTO / 1400W"; amd-smi set -g $GPU -l AUTO >/dev/null 2>&1; amd-smi set -g $GPU -o 1400 >/dev/null 2>&1' EXIT

run() {  # $1=label $2...=cmd
  local label=$1; shift
  echo "--- $label"
  HIP_VISIBLE_DEVICES=$HIPDEV python3 $S $GPU "$@" 2>&1 | grep -E 'TFlops|MFMA_PEAK|SCLK|POWER|PPT'
}

for LOCK in "$@"; do
  if [ "$LOCK" = "auto" ]; then
    amd-smi set -g $GPU -l AUTO >/dev/null 2>&1
  else
    amd-smi set -g $GPU -d $LOCK >/dev/null 2>&1
  fi
  sleep 3
  echo "================ LOCK=$LOCK ================"
  run "pure MFMA" ./mfma_peak 20000 5
  run "GEMM 8192^3" $BIN -m 8192 -n 8192 -k 8192 -v 0 -w 300 -i 800
done
