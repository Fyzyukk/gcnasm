#!/usr/bin/env python3
"""Full output checks; intentionally contains no kernel performance timing."""
import argparse
import ctypes
import hashlib
import json
import os
from pathlib import Path
import sys

parser = argparse.ArgumentParser()
parser.add_argument("names", nargs="+")
parser.add_argument("--tag", required=True)
parser.add_argument("--pci", required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parent
work = Path(os.environ.get("MXFP8_WORK_DIR") or (root / "work_path.txt").read_text().strip())
baseline = work / "baseline"
dest = root / "full_validation" / args.tag
dest.mkdir(parents=True, exist_ok=False)

hip = ctypes.CDLL("/opt/rocm/lib/libamdhip64.so")
bus = ctypes.create_string_buffer(64)
assert hip.hipDeviceGetPCIBusId(bus, 64, 0) == 0
actual_pci = bus.value.decode().lower()
assert actual_pci == args.pci.lower(), (actual_pci, args.pci)
import torch
from aiter.ops.shuffle import shuffle_weight
sys.path.insert(0, str(baseline))
from blockscale_bpreshuffle import _Args

torch.set_num_threads(16)
torch.manual_seed(20260911)
torch.cuda.set_device(0)
torch.set_float32_matmul_precision("highest")
m = n = k = 8192
names = ["baseline"] + [name for name in args.names if name != "baseline"]
libraries = {}
metadata = {}
for name in names:
    directory = work / name
    library = ctypes.CDLL(str(directory / "build/libblockscale_bpreshuffle.so"), mode=ctypes.RTLD_LOCAL)
    fn = library.launch_blockscale_bpreshuffle
    fn.argtypes = [ctypes.POINTER(_Args), ctypes.c_int, ctypes.c_int, ctypes.c_void_p]
    fn.restype = ctypes.c_int
    libraries[name] = (library, fn)
    metadata[name] = {file: hashlib.sha256((directory / file).read_bytes()).hexdigest() for file in ["tmpl.hpp", "traits.hpp", "build/libblockscale_bpreshuffle.so"]}
records = []
manifest = dict(pci=actual_pci, hip_visible_devices=os.environ.get("HIP_VISIBLE_DEVICES"), shape=[m, n, k], batch=1, performance_measured=False, versions=metadata, records=records)
stream = ctypes.c_void_p(torch.cuda.current_stream().cuda_stream)
outputs = {"fp32": torch.empty((m, n), dtype=torch.float32, device="cuda"), "bf16": torch.empty((m, n), dtype=torch.bfloat16, device="cuda")}

def launch(name, a, b, sa, sb, dtype):
    output = outputs[dtype]
    output.fill_(float("nan"))
    payload = _Args(a.data_ptr(), b.data_ptr(), output.data_ptr(), m, n, k, 1, k, k, n, m*k, n*k, m*n, sa.data_ptr(), sb.data_ptr(), m, k//128, m*(k//128), (n//128)*(k//128))
    assert libraries[name][1](ctypes.byref(payload), int(dtype == "bf16"), 1, stream) == 0
    torch.cuda.synchronize()
    return output

def check(name, pattern, dtype, output, reference):
    torch.testing.assert_close(output, reference.to(output.dtype), rtol=0, atol=0)
    records.append(dict(name=name, pattern=pattern, dtype=dtype, elements=m*n, exact_equal=True, output_prefilled_nan=True))
    (dest / "results.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print("PASS", pattern, name, dtype, m*n, "outputs exactly equal", flush=True)

# Every dyadic product and its absolute sum fits exactly in FP32, allowing
# an independent dequantized GEMM reference with strict BF16 rounding checks.
a = (torch.randint(-4, 5, (m, k), device="cuda").float() / 2).to(torch.float8_e4m3fn)
raw_b = (torch.randint(-4, 5, (n, k), device="cuda").float() / 2).to(torch.float8_e4m3fn)
sa = torch.randint(126, 129, (k//128, m), dtype=torch.uint8, device="cuda")
sb = torch.randint(126, 129, (n//128, k//128), dtype=torch.uint8, device="cuda")
ad = a.float() * torch.exp2(sa.T.float() - 127).repeat_interleave(128, 1)
bd = raw_b.float() * torch.exp2(sb.float() - 127).repeat_interleave(128, 0).repeat_interleave(128, 1)
reference = ad @ bd.T
b = shuffle_weight(raw_b, layout=(16, 16))
del ad, bd, raw_b
for name in names:
    for dtype in outputs:
        check(name, "dyadic_independent_dequantized_gemm", dtype, launch(name, a, b, sa, sb, dtype), reference)
del a, b, sa, sb, reference

# Match the standard CLI FP8 conversion and E8M0 RNG exactly. The validated
# baseline is the oracle here because K accumulation order is unchanged.
generator = ctypes.CDLL(str(root / "support/cli_input_generator.so"))
for fn in [generator.make_fp8, generator.make_scale]:
    fn.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_uint64]
    fn.restype = None

def filled(shape, seed, scale=False):
    host = torch.empty(shape, dtype=torch.uint8)
    fn = generator.make_scale if scale else generator.make_fp8
    fn(ctypes.c_void_p(host.data_ptr()), host.numel(), seed)
    return host.cuda()

a = filled((m, k), 1).view(torch.float8_e4m3fn)
raw_b = filled((n, k), 1 ^ 0x3141592653589793).view(torch.float8_e4m3fn)
b = shuffle_weight(raw_b, layout=(16, 16))
sa = filled((k//128, m), 1 ^ 0x2718281828459045, True)
sb = filled((n//128, k//128), 1 ^ 0x6a09e667f3bcc909, True)
del raw_b
reference_outputs = {}
for name in names:
    for dtype in outputs:
        output = launch(name, a, b, sa, sb, dtype)
        if name == "baseline":
            reference_outputs[dtype] = output.clone()
            assert torch.isfinite(output).all()
        else:
            check(name, "cli_seed1_validated_baseline", dtype, output, reference_outputs[dtype])
print("ALL FULL OUTPUT CHECKS PASSED; no performance timing", flush=True)
