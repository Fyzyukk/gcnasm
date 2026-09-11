#!/usr/bin/env python3
"""Audit persistent tile4 ISA, preserving reported spill/resource costs."""
from collections import Counter
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import sys

here = Path(__file__).resolve().parent
name = sys.argv[1] if len(sys.argv) == 2 else "tile4"
assert name in ("tile2", "tile4") and len(sys.argv) <= 2
work = Path((here / "work_path.txt").read_text().strip())
os.environ["MXFP8_WORK_DIR"] = str(work)
previous = here.parent / "continuation_20260911/round3/audit_resumed.py"
spec = importlib.util.spec_from_file_location("round3_audit", previous)
auditor = importlib.util.module_from_spec(spec)
saved_argv = sys.argv
sys.argv = sys.argv[:1]
try:
    spec.loader.exec_module(auditor)
finally:
    sys.argv = saved_argv
baseline, candidate = work / "baseline", work / name
assert auditor.expanded_mfmas((baseline / "tmpl.hpp").read_text()) == auditor.expanded_mfmas((candidate / "tmpl.hpp").read_text())
functions = auditor.parse(candidate / "build/device.isa")
notes = re.split(r"  - \.agpr_count:", (candidate / "build/device.notes").read_text())[1:]
assert len(functions) == len(notes) == 4
reports = []
for function, note in zip(functions, notes):
    resources = {key: int(re.search(r"\." + key + r":\s*(\d+)", note)[1]) for key in [
        "vgpr_count", "sgpr_count", "group_segment_fixed_size", "private_segment_fixed_size",
        "vgpr_spill_count", "sgpr_spill_count", "wavefront_size", "max_flat_workgroup_size",
    ]}
    resources["agpr_count"] = int(note.splitlines()[0])
    code = [ins["asm"] for ins in function["code"] if not ins["asm"].startswith("s_code_end")]
    assert resources["agpr_count"] == 256 and resources["wavefront_size"] == 64
    assert resources["max_flat_workgroup_size"] == 256
    assert not any(re.match(r"\S+\s+exec(?:_lo|_hi)?(?:\s|,)", text) or text.startswith("v_cmpx") or "saveexec" in text for text in code)
    counts = Counter()
    for text in code:
        if not text.startswith("v_mfma"):
            continue
        assert text.startswith("v_mfma_scale_f32_16x16x128_f8f6f4")
        fields = [part.strip() for part in text.split(" ", 1)[1].split(",")]
        assert fields[0] == fields[3]
        lo, hi = map(int, re.fullmatch(r"a\[(\d+):(\d+)\]", fields[0]).groups())
        assert lo % 4 == 0 and hi == lo + 3 and hi < 256
        counts[lo] += 1
    assert sorted(counts) == list(range(0, 256, 4))
    generic = "blockscale_generic" in function["name"]
    old = [ins["asm"] for ins in auditor.baseline_functions[function["name"]]["code"] if not ins["asm"].startswith("s_code_end")]
    if generic:
        assert code == old
    lds = auditor.audit(function)
    assert not lds["hazards"]
    vmem = auditor.audit_vmem(function)
    reports.append({
        "name": function["name"], "resources": resources,
        "generic_isa_identical": generic, "native_mfma_tied_c256": True,
        "exec_unchanged": True, "static_mfma_count": sum(counts.values()),
        "scratch_instruction_count": sum(text.startswith("scratch_") for text in code),
        "lds_wait": lds, "vmem_wait": vmem,
        "vmem_audit_scope": "Normal VMEM and LDS publication; scratch traffic is reported separately",
    })
hashes = {file: hashlib.sha256((candidate / file).read_bytes()).hexdigest() for file in [
    "tmpl.hpp", "traits.hpp", "build/device.isa", "build/device.notes",
    "build/gemm_a8w8_blockscale_bpreshuffle.exe", "build/libblockscale_bpreshuffle.so",
]}
result = {"status": "PASS", "source_mfma_sequence_unchanged": True, "kernels": reports, "hashes": hashes}
(here / (name + "_static_audit.json")).write_text(json.dumps(result, indent=2) + "\n")
for report in reports:
    print(report["name"], report["resources"], flush=True)
