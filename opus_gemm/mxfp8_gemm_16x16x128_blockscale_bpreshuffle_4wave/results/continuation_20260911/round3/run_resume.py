#!/usr/bin/env python3
"""Record sequential, same-device comparisons for the recovered third round."""
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
import time

parser = argparse.ArgumentParser()
parser.add_argument("names", nargs="+")
parser.add_argument("--tag", required=True)
parser.add_argument("--gpu", type=int, default=2, help="Physical rocm-smi card index; resolve HIP index by PCI bus")
parser.add_argument("--max-initial-vram-percent", type=int, default=1, help="Permit idle resident allocations up to this percent; still require <=5%% GPU activity")
parser.add_argument("--rounds", type=int, default=1)
parser.add_argument("--verify", action="store_true")
parser.add_argument("--verify-only", action="store_true", help="Only validate outputs; do not collect performance")
parser.add_argument("--dtypes", nargs="+", choices=["bf16", "fp32"], default=["bf16", "fp32"])
args = parser.parse_args()
root = Path(__file__).resolve().parent
work = Path(os.environ.get("MXFP8_WORK_DIR") or (root / "work_path.txt").read_text().strip())
output = root / "measurements" / args.tag
output.mkdir(parents=True, exist_ok=False)
visibility_keys = {"HIP_VISIBLE_DEVICES", "ROCR_VISIBLE_DEVICES", "CUDA_VISIBLE_DEVICES", "GPU_DEVICE_ORDINAL"}
probe_env = {key: value for key, value in os.environ.items() if key not in visibility_keys}
probe = """
import ctypes,json
lib=ctypes.CDLL('/opt/rocm/lib/libamdhip64.so')
count=ctypes.c_int(); assert lib.hipGetDeviceCount(ctypes.byref(count))==0
devices=[]
for i in range(count.value):
    bus=ctypes.create_string_buffer(64)
    assert lib.hipDeviceGetPCIBusId(bus,64,i)==0
    devices.append(dict(hip_index=i,pci=bus.value.decode().lower()))
print(json.dumps(devices))
"""
devices = json.loads(subprocess.run([sys.executable, "-c", probe], env=probe_env, capture_output=True, text=True, check=True).stdout)
status = json.loads(subprocess.run(["rocm-smi", "--showbus", "--showuse", "--showmemuse", "--json"], capture_output=True, text=True, check=True).stdout)
card = status[f"card{args.gpu}"]
pci = card["PCI Bus"].lower()
hip_index = next(device["hip_index"] for device in devices if device["pci"] == pci)
binding_device = dict(physical_gpu=args.gpu, pci=pci, hip_index=hip_index, all_devices=devices, initial_status=card)
(output / "device_binding.json").write_text(json.dumps(binding_device, indent=2) + "\n")
if int(card["GPU use (%)"]) > 5 or int(card["GPU Memory Allocated (VRAM%)"]) > args.max_initial_vram_percent:
    raise SystemExit(f"Physical GPU{args.gpu} ({pci}) is occupied; no benchmark launched.")
env = dict(probe_env, HIP_VISIBLE_DEVICES=str(hip_index), OMP_TOOL="disabled", OMP_NUM_THREADS="16")
print(f"Physical GPU{args.gpu}, PCI {pci}, HIP index {hip_index}", flush=True)

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def snapshot(label):
    proc = subprocess.run(["rocm-smi", "--showbus", "--showuse", "--showmemuse", "--showclocks", "--showpower", "--json"], capture_output=True, text=True)
    (output / (label + ".json")).write_text(proc.stdout)

snapshot("gpu_before")
records = []
for round_index in range(args.rounds):
    order = args.names if round_index % 2 == 0 else args.names[::-1]
    for name in order:
        directory = work / name
        executable = directory / "build/gemm_a8w8_blockscale_bpreshuffle.exe"
        binding = {file: digest(directory / file) for file in ["tmpl.hpp", "traits.hpp", "tmpl_generic.hpp", "build/gemm_a8w8_blockscale_bpreshuffle.exe"]}
        checks = []
        if (args.verify or args.verify_only) and round_index == 0 and name != "baseline":
            checks = [("verify_" + dtype, 256, 512, dtype, True) for dtype in args.dtypes]
        if not args.verify_only:
            checks += [("perf_" + dtype, 8192, 8192, dtype, False) for dtype in args.dtypes]
        for label, m, n, dtype, verify in checks:
            command = [str(executable), "-m", str(m), "-n", str(n), "-k", "8192", "-b", "1", "-w", "0" if verify else "200", "-i", "1" if verify else "100", "-v", "1" if verify else "0", "--dtype", dtype, "--seed", "1"]
            start = time.monotonic()
            proc = subprocess.run(command, env=env, capture_output=True, text=True, timeout=120)
            log = f"r{round_index + 1}_{name.replace('/', '__')}_{label}.log"
            (output / log).write_text(proc.stdout + proc.stderr)
            record = dict(name=name, round=round_index + 1, dtype=dtype, label=label, command=command, gpu=args.gpu, pci=pci, hip_index=hip_index, timestamp_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(), returncode=proc.returncode, wall_seconds=time.monotonic() - start, hashes=binding, log=log)
            match = re.findall(r"avg_time=([0-9.]+) ms, ([0-9.]+) TFlops", proc.stdout)
            if match:
                record.update(ms=float(match[-1][0]), pflops=float(match[-1][1]) / 1000)
            valid = proc.returncode == 0 and ("ALL BATCHES VALID" in proc.stdout if verify else bool(match))
            record["valid"] = valid
            records.append(record)
            (output / "records.json").write_text(json.dumps(records, indent=2) + "\n")
            print(round_index + 1, name, label, "PASS" if valid else "FAIL", "" if verify else f"{record.get('ms')} ms / {record.get('pflops')} P", flush=True)
            if not valid:
                print(proc.stdout + proc.stderr, flush=True)
                raise SystemExit(1)

summary = []
for name in args.names:
    for dtype in args.dtypes:
        values = [r["ms"] for r in records if r["name"] == name and r["dtype"] == dtype and r["label"].startswith("perf_")]
        if not values:
            continue
        ms = statistics.median(values)
        summary.append(dict(name=name, dtype=dtype, gpu=args.gpu, rounds=len(values), median_ms=ms, min_ms=min(values), max_ms=max(values), median_pflops=2 * 8192**3 / (ms * 1e12)))
(output / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
snapshot("gpu_after")
print(json.dumps(summary, indent=2), flush=True)
