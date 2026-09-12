#!/usr/bin/env python3
"""Benchmark the final generic kernel on ordered square GEMM sizes."""
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


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--gpu", type=int, required=True, help="Physical rocm-smi card index")
    parser.add_argument("--sizes", nargs="+", type=int, default=[8192, 1024, 2048, 4096])
    parser.add_argument("--rounds", type=int, default=5)
    parser.add_argument("--tag", required=True, help="Unique result directory name")
    args = parser.parse_args()
    if args.rounds <= 0 or any(size <= 0 or size % 256 for size in args.sizes):
        parser.error("rounds must be positive and square sizes must be positive multiples of 256")
    root = Path(__file__).resolve().parents[1]
    dest = root / "results/final_generic_20260912" / args.tag
    dest.mkdir(parents=True, exist_ok=False)
    visibility = {"HIP_VISIBLE_DEVICES", "CUDA_VISIBLE_DEVICES", "ROCR_VISIBLE_DEVICES", "GPU_DEVICE_ORDINAL"}
    env = {k: v for k, v in os.environ.items() if k not in visibility}
    probe = """import ctypes,json
h=ctypes.CDLL('/opt/rocm/lib/libamdhip64.so')
n=ctypes.c_int();assert h.hipGetDeviceCount(ctypes.byref(n))==0
devices=[]
for i in range(n.value):
 b=ctypes.create_string_buffer(64);assert h.hipDeviceGetPCIBusId(b,64,i)==0
 devices.append(dict(hip_index=i,pci=b.value.decode().lower()))
print(json.dumps(devices))
"""
    devices = json.loads(subprocess.check_output([sys.executable, "-c", probe], env=env, text=True))
    card = json.loads(subprocess.check_output([
        "rocm-smi", "--showbus", "--showuse", "--showmemuse", "--json"], text=True))[f"card{args.gpu}"]
    pci = card["PCI Bus"].lower()
    hip_index = next(d["hip_index"] for d in devices if d["pci"] == pci)
    if int(card["GPU use (%)"]) > 5 or int(card["GPU Memory Allocated (VRAM%)"]) > 1:
        raise SystemExit(f"GPU{args.gpu} {pci} is occupied: {card}")
    env.update(HIP_VISIBLE_DEVICES=str(hip_index), OMP_TOOL="disabled", OMP_NUM_THREADS="16")
    sources = ["tmpl_generic.hpp", "traits.hpp", "kernel_dispatch.hpp", "gemm_a8w8_mxfp8_scale_kernel.cc",
               "build/gemm_a8w8_blockscale_bpreshuffle.exe", "build/libblockscale_bpreshuffle.so"]
    hashes = {name: hashlib.sha256((root / name).read_bytes()).hexdigest() for name in sources}
    metadata = dict(timestamp_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                    physical_gpu=args.gpu, hip_index=hip_index, pci=pci, initial_status=card,
                    all_devices=devices, sizes=args.sizes, batch=1, warmup=200, iterations=100,
                    rounds=args.rounds, seed=1, hashes=hashes, kernel_only=True,
                    scope="Square M=N=K shapes, in requested order; serial HIP-event CLI measurements")
    (dest / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
    print(f"GPU{args.gpu}, HIP{hip_index}, PCI {pci}; sizes {args.sizes}", flush=True)
    records = []
    summary = []
    for size in args.sizes:
        for round_index in range(args.rounds):
            dtypes = ["bf16", "fp32"] if round_index % 2 == 0 else ["fp32", "bf16"]
            for dtype in dtypes:
                command = [str(root / "build/gemm_a8w8_blockscale_bpreshuffle.exe"),
                           "-m", str(size), "-n", str(size), "-k", str(size), "-b", "1",
                           "-w", "200", "-i", "100", "-v", "0", "--dtype", dtype, "--seed", "1"]
                result = subprocess.run(command, env=env, capture_output=True, text=True, timeout=120)
                log = f"n{size}_r{round_index + 1}_{dtype}.log"
                (dest / log).write_text(result.stdout + result.stderr)
                result.check_returncode()
                match = re.findall(r"avg_time=([0-9.]+) ms, ([0-9.]+) TFlops", result.stdout)
                assert match, result.stdout
                ms = float(match[-1][0])
                record = dict(size=size, shape=[size] * 3, dtype=dtype, round=round_index + 1,
                              ms=ms, pflops=2 * size**3 / (ms * 1e12), command=command, log=log,
                              timestamp_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
                records.append(record)
                (dest / "records.json").write_text(json.dumps(records, indent=2) + "\n")
                print(size, dtype, round_index + 1, f"{ms:.9f} ms / {record['pflops']:.6f} P", flush=True)
        for dtype in ["bf16", "fp32"]:
            values = [r["ms"] for r in records if r["size"] == size and r["dtype"] == dtype]
            median = statistics.median(values)
            summary.append(dict(shape=[size] * 3, dtype=dtype, rounds=len(values), median_ms=median,
                                min_ms=min(values), max_ms=max(values),
                                median_pflops=2 * size**3 / (median * 1e12)))
        (dest / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    final_status = subprocess.check_output([
        "rocm-smi", "--showbus", "--showuse", "--showmemuse", "--json"], text=True)
    (dest / "gpu_after.json").write_text(final_status)
    print(json.dumps(summary, indent=2), flush=True)


if __name__ == "__main__":
    main()
