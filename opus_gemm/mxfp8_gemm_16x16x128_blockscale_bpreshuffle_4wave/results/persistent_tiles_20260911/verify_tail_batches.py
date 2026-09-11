#!/usr/bin/env python3
"""CPU-reference checks for a partial persistent group and batch offsets."""
import argparse
import ctypes
import json
import os
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("--pci", required=True)
args = parser.parse_args()
hip = ctypes.CDLL("/opt/rocm/lib/libamdhip64.so")
bus = ctypes.create_string_buffer(64)
assert hip.hipDeviceGetPCIBusId(bus, 64, 0) == 0
assert bus.value.decode().lower() == args.pci.lower()
here = Path(__file__).resolve().parent
work = Path((here / "work_path.txt").read_text().strip())
dest = here / "tail_batch_validation"
dest.mkdir(exist_ok=False)
records = []
for name, tiles in [("tile2", 2), ("tile4", 4)]:
    for dtype in ["bf16", "fp32"]:
        command = [str(work / name / "build/gemm_a8w8_blockscale_bpreshuffle.exe"),
                   "-m", "1280", "-n", "256", "-k", "8192", "-b", "2",
                   "-w", "0", "-i", "1", "-v", "1", "--dtype", dtype,
                   "--tiles", str(tiles), "--seed", "1"]
        result = subprocess.run(command, text=True, capture_output=True, timeout=180)
        output = result.stdout + result.stderr
        logfile = name + "_" + dtype + ".log"
        (dest / logfile).write_text(output)
        valid = result.returncode == 0 and "ALL BATCHES VALID" in output
        valid = valid and f"output_tiles_per_wg={tiles} (forced)" in output
        records.append(dict(name=name, output_tiles_per_wg=tiles, dtype=dtype,
                            shape=[1280, 256, 8192], batch=2, valid=valid,
                            pci=args.pci.lower(), hip_visible_devices=os.environ.get("HIP_VISIBLE_DEVICES"),
                            performance_claim=False, command=command, log=logfile))
        (dest / "results.json").write_text(json.dumps(records, indent=2) + "\n")
        print(name, dtype, "PASS" if valid else "FAIL", "partial output group and batch2", flush=True)
        assert valid, output
