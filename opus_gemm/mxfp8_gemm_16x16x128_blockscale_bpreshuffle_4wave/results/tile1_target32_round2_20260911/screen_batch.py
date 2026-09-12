#!/usr/bin/env python3
"""Audit, fully validate, then screen one new batch on the recorded GPU2."""
import argparse
import os
from pathlib import Path
import subprocess
import sys

parser = argparse.ArgumentParser()
parser.add_argument("--tag", required=True)
parser.add_argument("--rounds", type=int, default=3)
parser.add_argument("names", nargs="+")
args = parser.parse_args()
here = Path(__file__).resolve().parent
env = {k: v for k, v in os.environ.items() if k not in [
    "HIP_VISIBLE_DEVICES", "CUDA_VISIBLE_DEVICES", "ROCR_VISIBLE_DEVICES", "GPU_DEVICE_ORDINAL"]}
env.update(HIP_VISIBLE_DEVICES="2", MXFP8_EXPECTED_PCI="0000:65:00.0",
           MXFP8_SHARED_ROUNDS=str(args.rounds), MXFP8_BRACKETED="1",
           MXFP8_NATIVE_TIMING="1", MXFP8_TELEMETRY="0",
           MXFP8_MAX_INITIAL_VRAM_PERCENT="1", OMP_TOOL="disabled", OMP_NUM_THREADS="16")
commands = [
    (args.tag + "_audit", ["audit.py", *args.names]),
    (args.tag + "_full_gpu2", ["run.py", "verify", "--tag", args.tag + "_full_gpu2",
                               "--pci", "0000:65:00.0", *args.names]),
    (args.tag + "_screen_gpu2", ["run.py", "shared", args.tag + "_screen_gpu2", *args.names]),
]
for tag, command in commands:
    log = here / (tag + ".log")
    assert not log.exists(), log
    print("START", tag, flush=True)
    with log.open("w") as f:
        proc = subprocess.run([sys.executable, str(here / command[0]), *command[1:]],
                              env=env, stdout=f, stderr=subprocess.STDOUT)
    print("DONE", tag, proc.returncode, flush=True)
    print(log.read_text()[-12000 if proc.returncode else -8000:], flush=True)
    if proc.returncode:
        sys.exit(proc.returncode)
