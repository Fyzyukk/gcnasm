#!/usr/bin/env python3
"""Audit, verify generic shapes, then time only 8192 cubed on one idle GPU."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys

from gpu_window import LIMITS, after_process, snapshot, window_status

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("names",nargs="+")
parser.add_argument("--tag",required=True)
parser.add_argument("--gpu",type=int,default=2)
parser.add_argument("--expected-pci",help="GPU2 defaults to the frozen physical device 0000:65:00.0")
parser.add_argument("--rounds",type=int,default=3)
parser.add_argument("--reference",default="baseline")
parser.add_argument("--skip-shapes",action="store_true",help="For changes whose K control and output geometry are already verified")
args = parser.parse_args()
here = Path(__file__).resolve().parent
env = {k:v for k,v in os.environ.items() if k not in ["HIP_VISIBLE_DEVICES","CUDA_VISIBLE_DEVICES","ROCR_VISIBLE_DEVICES","GPU_DEVICE_ORDINAL"]}
probe = """import ctypes,json
h=ctypes.CDLL('/opt/rocm/lib/libamdhip64.so')
n=ctypes.c_int();assert h.hipGetDeviceCount(ctypes.byref(n))==0
out=[]
for i in range(n.value):
 b=ctypes.create_string_buffer(64);assert h.hipDeviceGetPCIBusId(b,64,i)==0
 out.append(dict(hip_index=i,pci=b.value.decode().lower()))
print(json.dumps(out))
"""
expected_pci = args.expected_pci or ("0000:65:00.0" if args.gpu == 2 else None)
initial = snapshot(args.gpu, expected_pci)
if not initial["idle"]:
    raise SystemExit(f"GPU is busy; no validation or timing process launched: {initial}")
pci, status = initial["pci"], initial["status"]
devices = json.loads(subprocess.check_output([sys.executable,"-c",probe],env=env,text=True))
hip_index = next(d["hip_index"] for d in devices if d["pci"]==pci)
env.update(HIP_VISIBLE_DEVICES=str(hip_index),MXFP8_EXPECTED_PCI=pci,
           MXFP8_SHARED_ROUNDS=str(args.rounds),MXFP8_BRACKETED="1",MXFP8_NATIVE_TIMING="1",
           MXFP8_TELEMETRY="0",MXFP8_MAX_INITIAL_VRAM_PERCENT="1",
           MXFP8_BENCHMARK_REFERENCE=args.reference,OMP_TOOL="disabled",OMP_NUM_THREADS="16")
jobs = [("audit",[sys.executable,str(here/"audit.py"),*args.names])]
if not args.skip_shapes:
    jobs.append(("shapes",[sys.executable,str(here/"verify_shapes.py"),"--tag",args.tag,"--pci",pci,*args.names]))
jobs.append(("full",[sys.executable,str(here/"run.py"),"verify","--tag",args.tag,"--pci",pci,*args.names]))
jobs.append(("shared",[sys.executable,str(here/"run.py"),"shared",args.tag,*args.names]))
record = dict(tag=args.tag,physical_gpu=args.gpu,hip_index=hip_index,pci=pci,initial_status=status,
              initial_snapshot=initial,availability_limits=LIMITS,phase_records=[],
              timing_reference=args.reference,candidates=args.names,performance_shape=[8192,8192,8192],jobs=jobs)
manifest = here/(args.tag+"_manifest.json")
with manifest.open("x") as stream:
    stream.write(json.dumps(record,indent=2)+"\n")
for label,command in jobs:
    log = here/(args.tag+"_"+label+".log")
    phase = dict(label=label,command=command)
    record["phase_records"].append(phase)
    if label != "audit":
        phase["before"] = snapshot(args.gpu, pci)
        if not phase["before"]["idle"]:
            phase["status"] = "BUSY_BEFORE"
            manifest.write_text(json.dumps(record,indent=2)+"\n")
            raise SystemExit(f"GPU became busy before {label}; no {label} process launched. See {manifest}")
    phase["status"] = "RUNNING"
    manifest.write_text(json.dumps(record,indent=2)+"\n")
    print("START",label,flush=True)
    try:
        with log.open("x") as stream:
            proc = subprocess.run(command,env=env,stdout=stream,stderr=subprocess.STDOUT,timeout=300)
        phase["returncode"] = proc.returncode
        if label != "audit":
            phase["after"] = after_process(args.gpu, pci)
            phase["status"] = window_status(phase["before"],phase["after"],proc.returncode)
        else:
            phase["status"] = "PASS" if proc.returncode == 0 else "COMMAND_FAILED"
    except Exception as error:
        phase.update(status="CHECK_OR_COMMAND_FAILED",error=repr(error))
        raise
    finally:
        manifest.write_text(json.dumps(record,indent=2)+"\n")
        shared = here/"shared_allocations"/args.tag
        if label == "shared" and shared.is_dir():
            evidence = dict(**phase,limits=LIMITS,physical_gpu=args.gpu,pci=pci)
            (shared/"device_window.json").write_text(json.dumps(evidence,indent=2)+"\n")
    print("DONE",label,proc.returncode,flush=True)
    print(log.read_text()[-2500:],flush=True)
    if proc.returncode:
        raise SystemExit(proc.returncode)
    if phase["status"] not in ("PASS", "CLEAR_BOUNDARIES"):
        raise SystemExit(f"{label}: {phase['status']}; preserve raw results and repeat when idle. See {manifest}")
