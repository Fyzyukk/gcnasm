#!/usr/bin/env python3
"""Record one diagnostic ATT per candidate; do not shadow stdlib profile."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("names", nargs="+")
parser.add_argument("--gpu", type=int, default=2)
args = parser.parse_args()
here = Path(__file__).resolve().parent
work = Path((here / "work_path.txt").read_text().strip())
env = {k:v for k,v in os.environ.items() if k not in [
    "HIP_VISIBLE_DEVICES", "CUDA_VISIBLE_DEVICES", "ROCR_VISIBLE_DEVICES", "GPU_DEVICE_ORDINAL"]}
probe = """import ctypes,json
h=ctypes.CDLL('/opt/rocm/lib/libamdhip64.so')
n=ctypes.c_int();assert h.hipGetDeviceCount(ctypes.byref(n))==0
out=[]
for i in range(n.value):
 b=ctypes.create_string_buffer(64);assert h.hipDeviceGetPCIBusId(b,64,i)==0
 out.append(dict(hip_index=i,pci=b.value.decode().lower()))
print(json.dumps(out))
"""
devices = json.loads(subprocess.check_output([sys.executable,"-c",probe],env=env,text=True))
for name in args.names:
    status = json.loads(subprocess.check_output([
        "rocm-smi", "--showbus", "--showuse", "--showmemuse", "--json"],text=True))[f"card{args.gpu}"]
    pci = status["PCI Bus"].lower()
    hip_index = next(d["hip_index"] for d in devices if d["pci"] == pci)
    assert int(status["GPU use (%)"]) <= 5 and int(status["GPU Memory Allocated (VRAM%)"]) <= 1, status
    env.update(HIP_VISIBLE_DEVICES=str(hip_index), OMP_TOOL="disabled", OMP_NUM_THREADS="16")
    directory = work / name
    dest = here / "profiles_gpu2" / name
    raw = work / "profiles" / name
    dest.mkdir(parents=True, exist_ok=False)
    raw.mkdir(parents=True, exist_ok=False)
    command = ["rocprofv3", "--att", "--att-target-cu", "0", "--att-simd-select", "15",
               "--att-buffer-size", "16777216", "--kernel-iteration-range", "201-201",
               "-d", str(raw), "-o", "profile", "--output-format", "csv", "--",
               str(directory / "build/gemm_a8w8_blockscale_bpreshuffle.exe"),
               "-m", "8192", "-n", "8192", "-k", "8192", "-b", "1",
               "-w", "200", "-i", "100", "-v", "0", "--dtype", "bf16"]
    metadata = dict(command=command, hip_visible_devices=str(hip_index), physical_gpu=args.gpu,
                    pci=pci, raw_profile=str(raw), initial_status=status,
                    timestamp_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                    source_sha256=hashlib.sha256((directory / "tmpl_generic.hpp").read_bytes()).hexdigest(),
                    scope="Diagnostic ATT only; instrumented timing is not benchmark evidence")
    (dest / "command.json").write_text(json.dumps(metadata, indent=2) + "\n")
    with (dest / "run.log").open("x") as log:
        result = subprocess.run(command, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=120)
    print(name, result.returncode, sorted(p.name for p in raw.iterdir()), flush=True)
    result.check_returncode()
