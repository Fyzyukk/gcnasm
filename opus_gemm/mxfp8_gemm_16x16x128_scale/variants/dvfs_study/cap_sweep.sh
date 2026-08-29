#!/bin/bash
# Power-cap sweep: does kernel perf track the cap? Establishes power-limit causality.
set -u
GPU=5; HIPDEV=7
BIN=/root/workspace/gcnasm/opus_gemm/mxfp8_gemm_16x16x128_scale/build/gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2.exe
export LD_LIBRARY_PATH=/opt/rocm/lib/llvm/lib:${LD_LIBRARY_PATH:-}
trap 'echo "[restore] cap -> 1400W"; amd-smi set -g $GPU -o 1400 >/dev/null 2>&1' EXIT

for CAP in 1400 1200 1000 800; do
  amd-smi set -g $GPU -o $CAP >/dev/null 2>&1 || { echo "cap $CAP FAILED"; continue; }
  sleep 3
  echo "=== CAP ${CAP}W ==="
  HIP_VISIBLE_DEVICES=$HIPDEV python3 /root/workspace/gcnasm/opus_gemm/mxfp8_gemm_16x16x128_scale/variants/dvfs_study/sample.py $GPU \
     $BIN -m 8192 -n 8192 -k 8192 -v 0 -w 300 -i 800 2>&1 | grep -E 'TFlops|SCLK|POWER|HOTSPOT|PPT'
done
