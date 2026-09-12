#!/usr/bin/env python3
"""Reuse recorded correctness and same-address timing drivers."""
from pathlib import Path
import os
import sys

here = Path(__file__).resolve().parent
previous = here.parent / "continuation_20260911/round3"
mode = sys.argv.pop(1)
driver = {"verify":"verify_full.py", "shared":"benchmark_shared_cli.py", "cli":"run_resume.py"}[mode]
source = (previous / driver).read_text()
source = source.replace("root/'support/", "root.parent/'continuation_20260911/round3/support/")
source = source.replace('root / "support/', 'root.parent / "continuation_20260911/round3/support/')
source = source.replace('root / "support"', 'root.parent / "continuation_20260911/round3/support"')
if mode == "verify":
    source = source.replace('["tmpl.hpp", "traits.hpp", "build/libblockscale_bpreshuffle.so"]', '["tmpl.hpp", "tmpl_generic.hpp", "traits.hpp", "kernel_dispatch.hpp", "gemm_a8w8_blockscale_bpreshuffle_launch.cc", "gemm_a8w8_mxfp8_scale_host.cc", "build/libblockscale_bpreshuffle.so"] if (directory / file).is_file()')
if mode == "shared":
    source = source.replace("'source_sha256':hashlib.sha256((d/'tmpl.hpp').read_bytes()).hexdigest()", "'source_sha256':hashlib.sha256((d/'tmpl_generic.hpp').read_bytes()).hexdigest(),'specialized_source_sha256':hashlib.sha256((d/'tmpl.hpp').read_bytes()).hexdigest() if (d/'tmpl.hpp').is_file() else None,'traits_sha256':hashlib.sha256((d/'traits.hpp').read_bytes()).hexdigest(),'dispatch_sha256':hashlib.sha256((d/'kernel_dispatch.hpp').read_bytes()).hexdigest(),'launch_sha256':hashlib.sha256((d/'gemm_a8w8_blockscale_bpreshuffle_launch.cc').read_bytes()).hexdigest(),'host_sha256':hashlib.sha256((d/'gemm_a8w8_mxfp8_scale_host.cc').read_bytes()).hexdigest()")
    reference = os.environ.get("MXFP8_BENCHMARK_REFERENCE", "baseline")
    source = source.replace("'baseline'", repr(reference))
    source = source.replace("dict(gpu=torch.cuda.get_device_name()", "dict(comparison_reference="+repr(reference)+",gpu=torch.cuda.get_device_name()")
namespace = {"__name__":"__main__", "__file__":str(Path(__file__).resolve())}
exec(compile(source,str(previous/driver),"exec"),namespace)
