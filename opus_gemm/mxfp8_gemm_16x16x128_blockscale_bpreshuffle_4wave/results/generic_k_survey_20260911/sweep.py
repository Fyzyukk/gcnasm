#!/usr/bin/env python3
"""Compare specialized and forced generic paths at M=N=K=8192 only."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import statistics
import subprocess
import sys

here = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--gpu", type=int, required=True, help="Physical rocm-smi card number")
parser.add_argument("--hip-index", type=int, required=True)
parser.add_argument("--pci", required=True)
parser.add_argument("--tag", required=True)
args = parser.parse_args()
work = Path(os.environ.get("MXFP8_WORK_DIR") or (here / "work_path.txt").read_text().strip())
dest = here / "measurements" / args.tag
dest.mkdir(parents=True, exist_ok=False)
visibility = ["HIP_VISIBLE_DEVICES", "ROCR_VISIBLE_DEVICES", "CUDA_VISIBLE_DEVICES", "GPU_DEVICE_ORDINAL"]
env = {k: v for k, v in os.environ.items() if k not in visibility}
status = json.loads(subprocess.check_output(["rocm-smi", "--showbus", "--showuse", "--showmemuse", "--json"], text=True))[f"card{args.gpu}"]
assert status["PCI Bus"].lower() == args.pci.lower()
assert int(status["GPU use (%)"]) <= 5 and int(status["GPU Memory Allocated (VRAM%)"]) <= 1, status
env.update(HIP_VISIBLE_DEVICES=str(args.hip_index), OMP_TOOL="disabled", OMP_NUM_THREADS="16")
probe = """import ctypes,json
h=ctypes.CDLL('/opt/rocm/lib/libamdhip64.so')
b=ctypes.create_string_buffer(64)
assert h.hipDeviceGetPCIBusId(b,64,0)==0
print(json.dumps(b.value.decode().lower()))
"""
assert json.loads(subprocess.check_output([sys.executable, "-c", probe], env=env, text=True)) == args.pci.lower()
metadata = dict(physical_gpu=args.gpu, pci=args.pci.lower(), hip_index=args.hip_index, initial_status=status,
                m=8192, n=8192, batch=1, warmup=200, iterations=100, rounds=5, seed=1,
                telemetry_during_timing=False, timing="CLI HIP-event kernel-only",
                timestamp_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                versions={name: {f: hashlib.sha256((work / name / f).read_bytes()).hexdigest()
                           for f in ["tmpl.hpp", "tmpl_generic.hpp", "kernel_dispatch.hpp",
                                     "build/gemm_a8w8_blockscale_bpreshuffle.exe"]}
                          for name in ["specialized", "generic"]})
(dest / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
configs = [("specialized", 8192), ("generic", 8192)]
records = []
for round_index in range(5):
    order = configs if round_index % 2 == 0 else configs[::-1]
    for name, k in order:
        for dtype in ["bf16", "fp32"]:
            command = [str(work / name / "build/gemm_a8w8_blockscale_bpreshuffle.exe"),
                       "-m", "8192", "-n", "8192", "-k", str(k), "-b", "1", "-w", "200",
                       "-i", "100", "-v", "0", "--dtype", dtype, "--seed", "1"]
            proc = subprocess.run(command, env=env, capture_output=True, text=True, timeout=120)
            log = f"r{round_index+1}_{name}_k{k}_{dtype}.log"
            (dest / log).write_text(proc.stdout + proc.stderr)
            matches = re.findall(r"avg_time=([0-9.]+) ms, ([0-9.]+) TFlops", proc.stdout)
            if proc.returncode or not matches:
                print(proc.stdout + proc.stderr)
                raise SystemExit(f"Failed {command}")
            ms = float(matches[-1][0])
            row = dict(name=name, round=round_index+1, m=8192, n=8192, k=k, dtype=dtype,
                       ms=ms, pflops=2*8192**2*k/(ms*1e12), command=command, log=log,
                       timestamp_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
            records.append(row)
            (dest / "records.json").write_text(json.dumps(records, indent=2) + "\n")
            print(round_index+1, name, "K="+str(k), dtype, f"{ms:.9f} ms / {row['pflops']:.6f} P", flush=True)
summary = []
for name, k in configs:
    for dtype in ["bf16", "fp32"]:
        values = [r["ms"] for r in records if r["name"] == name and r["k"] == k and r["dtype"] == dtype]
        ms = statistics.median(values)
        summary.append(dict(name=name, k=k, dtype=dtype, rounds=len(values), median_ms=ms,
                            min_ms=min(values), max_ms=max(values), median_pflops=2*8192**2*k/(ms*1e12)))
(dest / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
print(json.dumps(summary, indent=2), flush=True)
