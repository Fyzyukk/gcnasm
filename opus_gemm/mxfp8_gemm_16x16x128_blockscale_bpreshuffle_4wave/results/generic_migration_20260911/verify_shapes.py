#!/usr/bin/env python3
"""Independent exact references across K lengths, output geometries and batches.

This is correctness-only. Performance comparisons use M=N=K=8192 separately.
"""
import argparse
import ctypes
import datetime
import hashlib
import json
import os
from pathlib import Path
import sys

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("names",nargs="+")
parser.add_argument("--tag",required=True)
parser.add_argument("--pci",required=True)
args = parser.parse_args()
here = Path(__file__).resolve().parent
work = Path(os.environ.get("MXFP8_WORK_DIR") or (here/"work_path.txt").read_text().strip())
dest = here/"shape_validation"/args.tag
dest.mkdir(parents=True,exist_ok=False)
hip = ctypes.CDLL("/opt/rocm/lib/libamdhip64.so")
bus = ctypes.create_string_buffer(64)
assert hip.hipDeviceGetPCIBusId(bus,64,0) == 0
assert bus.value.decode().lower() == args.pci.lower()
import torch
from aiter.ops.shuffle import shuffle_weight
sys.path.insert(0,str(work/"baseline"))
from blockscale_bpreshuffle import _Args

torch.set_num_threads(16)
torch.set_float32_matmul_precision("highest")
torch.manual_seed(20260911)
torch.cuda.set_device(0)
stream = ctypes.c_void_p(torch.cuda.current_stream().cuda_stream)
names = ["baseline"]+[name for name in args.names if name != "baseline"]
libraries = {}
versions = {}
for name in names:
    lib = ctypes.CDLL(str(work/name/"build/libblockscale_bpreshuffle.so"),mode=ctypes.RTLD_LOCAL)
    fn = lib.launch_blockscale_bpreshuffle
    fn.argtypes = [ctypes.POINTER(_Args),ctypes.c_int,ctypes.c_int,ctypes.c_void_p]
    fn.restype = ctypes.c_int
    libraries[name] = (lib,fn)
    versions[name] = {file:hashlib.sha256((work/name/file).read_bytes()).hexdigest() for file in [
        "tmpl_generic.hpp","traits.hpp","kernel_dispatch.hpp","build/libblockscale_bpreshuffle.so"]}

shapes = [(512,256,128,2),(256,512,256,1),(256,256,384,1),
          (256,768,896,1),(512,256,1152,2),
          (256,512,3968,1),(512,256,4096,1),(256,256,4224,2),(256,512,4352,1),
          (256,512,8064,1),
          (256,256,8192,1),(512,256,8320,1),(256,512,8448,1),
          (256,256,16384,1),(256,512,16512,2),(256,256,32896,1)]
records = []
metadata = dict(pci=args.pci,hip_visible_devices=os.environ.get("HIP_VISIBLE_DEVICES"),
                timestamp_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                performance_measured=False,versions=versions,records=records)
for m,n,k,batch in shapes:
    q = k//128
    a = (torch.randint(-4,5,(batch,m,k),device="cuda").float()/2).to(torch.float8_e4m3fn)
    raw_b = (torch.randint(-4,5,(batch,n,k),device="cuda").float()/2).to(torch.float8_e4m3fn)
    sa = torch.randint(126,129,(batch,q,m),dtype=torch.uint8,device="cuda")
    sb = torch.randint(126,129,(batch,n//128,q),dtype=torch.uint8,device="cuda")
    ad = a.float()*torch.exp2(sa.transpose(1,2).float()-127).repeat_interleave(128,2)
    bd = raw_b.float()*torch.exp2(sb.float()-127).repeat_interleave(128,1).repeat_interleave(128,2)
    reference = torch.bmm(ad,bd.transpose(1,2))
    b = torch.stack([shuffle_weight(raw_b[i],layout=(16,16)) for i in range(batch)])
    del ad,bd,raw_b
    for dtype in ["fp32","bf16"]:
        output = torch.empty((batch,m,n),dtype=torch.float32 if dtype=="fp32" else torch.bfloat16,device="cuda")
        target = reference.to(output.dtype)
        payload = _Args(a.data_ptr(),b.data_ptr(),output.data_ptr(),m,n,k,batch,k,k,n,m*k,n*k,m*n,
                        sa.data_ptr(),sb.data_ptr(),m,q,m*q,(n//128)*q)
        for name in names:
            output.fill_(float("nan"))
            assert libraries[name][1](ctypes.byref(payload),int(dtype=="bf16"),1,stream)==0
            torch.cuda.synchronize()
            torch.testing.assert_close(output,target,rtol=0,atol=0)
            records.append(dict(name=name,shape=[m,n,k],batch=batch,dtype=dtype,elements=batch*m*n,
                                reference="independent dequantized FP32 bmm",exact_equal=True))
            (dest/"results.json").write_text(json.dumps(metadata,indent=2)+"\n")
            print("PASS",name,dtype,(m,n,k,batch),flush=True)
        del output,target
    del a,b,sa,sb,reference
print("ALL GENERIC SHAPES PASSED; no performance timing",flush=True)
