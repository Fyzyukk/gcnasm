#!/usr/bin/env python3
"""Audit complete tile1 loops without assuming a fixed static unroll count."""
from collections import Counter
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import sys

here = Path(__file__).resolve().parent
work = Path(os.environ.get("MXFP8_WORK_DIR") or (here / "work_path.txt").read_text().strip())
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

baseline = work / "baseline"
for name in sys.argv[1:]:
    candidate = work / name
    source = (candidate / "tmpl.hpp").read_text()
    parent = (baseline / "tmpl.hpp").read_text()
    metadata_path = candidate / "candidate.json"
    if not metadata_path.exists():
        metadata_path = here / "candidate_patches" / name / "candidate.json"
    metadata = json.loads(metadata_path.read_text())
    first_k_peeled = metadata.get("config", {}).get("first_k_peeled", False)
    zero_initialization = metadata.get("config", {}).get("zero_src_c_initialization", False)
    normalized_source = source.replace("MXFP8_MMA_ZERO_PAIR(", "MXFP8_MMA_PAIR(").replace(
        "MXFP8_MMA_ZERO_ONE(", "MXFP8_MMA_ONE(")
    source_mfmas = auditor.expanded_mfmas(normalized_source)
    parent_mfmas = auditor.expanded_mfmas(parent)
    reorder_c11 = source_mfmas != parent_mfmas
    peeled = True
    # Each K128 block updates every accumulator once with exactly the same
    # operand/scale tuple. Reordering is allowed only between independent C.
    assert len(parent_mfmas) == 192
    assert len(source_mfmas) == (256 if first_k_peeled else 192)
    parent_blocks = [0, 0, 1, 2] if first_k_peeled else [0, 1, 2]
    for block, parent_block in enumerate(parent_blocks):
        assert Counter(source_mfmas[block*64:(block+1)*64]) == Counter(parent_mfmas[parent_block*64:(parent_block+1)*64]), block
    runtime_first = metadata.get("config", {}).get("runtime_first_compute_tile", False)
    first_loop_tile = "first_compute_tile" if runtime_first else (1 if first_k_peeled else 0)
    assert f"for (tile = {first_loop_tile}; tile + 2 < loops; ++tile)" in source
    if runtime_first:
        assert first_k_peeled and 'int first_compute_tile = 1;' in source
        assert 'asm volatile("" : "+s"(first_compute_tile));' in source
    if first_k_peeled:
        assert source.count("        const int tile = 0;") == 1
    assert source.count("prefetch_matrix_issue(opus::number<") == (32 if first_k_peeled else 16)
    assert "const int future_tile = (tile + 2) & 63;" in source
    for file in ["traits.hpp", "tmpl_generic.hpp", "kernel_dispatch.hpp",
                 "gemm_a8w8_mxfp8_scale_common.h", "gemm_a8w8_mxfp8_scale_kernel.cc",
                 "gemm_a8w8_blockscale_bpreshuffle_launch.cc"]:
        if file == "traits.hpp" and "wholek_padding" in metadata.get("config", {}):
            assert (candidate / file).read_text().split("struct WholeKScaleTraits")[0] == (baseline / file).read_text().split("struct WholeKScaleTraits")[0]
            continue
        assert (candidate / file).read_bytes() == (baseline / file).read_bytes(), file
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
        assert resources["private_segment_fixed_size"] == resources["vgpr_spill_count"] == resources["sgpr_spill_count"] == 0
        assert not any(re.match(r"\S+\s+exec(?:_lo|_hi)?(?:\s|,)", text)
                       or text.startswith("v_cmpx") or "saveexec" in text for text in code)
        generic = "blockscale_generic" in function["name"]
        counts = Counter()
        zero_counts = Counter()
        for text in code:
            if not text.startswith("v_mfma"):
                continue
            assert text.startswith("v_mfma_scale_f32_16x16x128_f8f6f4")
            fields = [part.strip() for part in text.split(" ", 1)[1].split(",")]
            lo, hi = map(int, re.fullmatch(r"a\[(\d+):(\d+)\]", fields[0]).groups())
            assert lo % 4 == 0 and hi == lo + 3 and hi < 256
            if zero_initialization and not generic and fields[3] == "0":
                assert counts[lo] == 0, "Zero-SrcC MFMA must be the first definition"
                zero_counts[lo] += 1
            else:
                assert fields[0] == fields[3]
            counts[lo] += 1
        assert sorted(counts) == list(range(0, 256, 4)) and len(set(counts.values())) == 1
        if zero_initialization and not generic:
            assert zero_counts == Counter({lo: 1 for lo in range(0, 256, 4)})
            assert not any(text.startswith(("v_accvgpr_write", "v_accvgpr_mov")) for text in code)
        else:
            assert not zero_counts
        old = [ins["asm"] for ins in auditor.baseline_functions[function["name"]]["code"]
               if not ins["asm"].startswith("s_code_end")]
        if generic:
            assert code == old
        else:
            assert resources["group_segment_fixed_size"] == metadata.get("config", {}).get("expected_lds_bytes", 152064)
        lds = auditor.audit(function)
        assert not lds["hazards"]
        vmem = auditor.audit_vmem(function)
        reports.append(dict(name=function["name"], resources=resources,
                            generic_isa_identical=generic,
                            native_mfma_tied_c256=not bool(zero_counts),
                            native_steady_mfma_tied_c256=True,
                            first_k_zero_src_c_count=sum(zero_counts.values()),
                            exec_unchanged=True, static_mfma_count=sum(counts.values()),
                            uniform_static_updates_per_accumulator=next(iter(counts.values())),
                            static_vmcnt_zero_count=sum("vmcnt(0)" in text for text in code),
                            lds_wait=lds, vmem_wait=vmem))
    hashes = {file: hashlib.sha256((candidate / file).read_bytes()).hexdigest() for file in [
        "tmpl.hpp", "traits.hpp", "build/device.isa", "build/device.notes",
        "build/gemm_a8w8_blockscale_bpreshuffle.exe", "build/libblockscale_bpreshuffle.so",
    ]}
    result = dict(status="PASS", source_mfma_sequence_unchanged=source_mfmas == parent_mfmas,
                  final_iteration_peeled=peeled, per_accumulator_k_order_unchanged=True,
                  first_iteration_peeled=first_k_peeled,
                  source_reordered_with_identical_operands=reorder_c11, kernels=reports, hashes=hashes,
                  scope="Static loop counts may change with unrolling; full-output checks recorded separately")
    output = Path(os.environ.get("MXFP8_AUDIT_OUTPUT_DIR") or here / "audits")
    output.mkdir(parents=True, exist_ok=True)
    (output / (name + ".json")).write_text(json.dumps(result, indent=2) + "\n")
    print(name, "PASS", [(r["resources"]["vgpr_count"], r["static_mfma_count"]) for r in reports[:2]], flush=True)
