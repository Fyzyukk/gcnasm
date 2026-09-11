#!/usr/bin/env python3
"""Conservative linked-ISA checks, with canonical VMEM destination states."""
from collections import Counter, deque
from pathlib import Path
import hashlib
import json
import os
import re
import sys

root = Path(__file__).resolve().parent
sys.path.insert(0, str(root / "support"))
from audit_lds_waits import parse, audit, regs

work = Path(os.environ.get("MXFP8_WORK_DIR") or (root / "work_path.txt").read_text().strip())
baseline = work / "baseline"
baseline_functions = {f["name"]: f for f in parse(baseline / "build/device.isa")}

def audit_vmem(function):
    # The original audit distinguished the PC of every pending DTLDS event.
    # Many fine-grain branches generated >1M equivalent states. For register
    # readiness, only the ordered destination sets matter. DTLDS and stores
    # have empty VGPR destination sets, so canonicalize these equivalent
    # states while retaining their count and ordering for partial waits.
    code = function["code"]
    positions = {ins["addr"]: i for i, ins in enumerate(code)}
    events = {}
    for i, ins in enumerate(code):
        text = ins["asm"]
        if text.startswith(("buffer_load", "global_load", "flat_load")):
            events[i] = frozenset() if " lds" in text else frozenset(regs(text.split(",")[0]))
        elif text.startswith(("buffer_store", "global_store", "flat_store")):
            events[i] = frozenset()
    queue = deque([(0, ())])
    seen = set()
    publications = set()
    while queue:
        i, pending = queue.popleft()
        if (i, pending) in seen:
            continue
        seen.add((i, pending))
        assert len(seen) < 1000000, "Unexpected canonical VMEM state growth"
        ins = code[i]
        text = ins["asm"]
        wait = re.search(r"\bvmcnt\((\d+)\)", text)
        if wait:
            count = int(wait[1])
            pending = pending[-count:] if count else ()
        busy = set().union(*pending) if pending else set()
        assert not regs(text) & busy, (ins, sorted(regs(text) & busy))
        if i in events:
            pending += (events[i],)
        if text == "s_barrier":
            assert not pending, ("VMEM pending at publication", ins, pending)
            publications.add(ins["line"])
        if text.startswith("s_endpgm"):
            continue
        successors = [positions[ins["target"]]] if "target" in ins else []
        if not text.startswith("s_branch ") and i + 1 < len(code):
            successors.append(i + 1)
        queue.extend((successor, pending) for successor in successors)
    return dict(status="PASS", cfg_states=len(seen), hazards=[], barriers_with_zero_pending_vmem=sorted(publications), scope="VMEM register waits and full VMEM publication; LDS content lifetimes checked separately")

def expanded_mfmas(source):
    result = []
    pattern = re.compile(r"^\s+MXFP8_MMA_(PAIR|ONE)\(\s*(.*?)\);", re.M | re.S)
    for match in pattern.finditer(source):
        fields = [x.strip() for x in match[2].split(",")]
        if match[1] == "ONE":
            result.append(tuple(fields))
        else:
            hm, mr, ng, a, b, c0, c1, sa, sb = fields
            for n, c in enumerate([c0, c1]):
                result.append((hm, mr, str(int(ng) * 2 + n), a, b, c, sa, sb))
    return result

for name in sys.argv[1:]:
    directory = work / name
    source = (directory / "tmpl.hpp").read_text()
    parent = (baseline / "tmpl.hpp").read_text()
    assert expanded_mfmas(source) == expanded_mfmas(parent)
    for file in ["traits.hpp", "tmpl_generic.hpp", "kernel_dispatch.hpp", "gemm_a8w8_mxfp8_scale_common.h", "gemm_a8w8_mxfp8_scale_kernel.cc", "gemm_a8w8_blockscale_bpreshuffle_launch.cc"]:
        assert (directory / file).read_bytes() == (baseline / file).read_bytes(), file
    if name.startswith("asym_"):
        calls = re.compile(r"            async_load_issue(?:_b_contiguous)?_scale<[^>]+>\(.*?\);", re.S)
        assert calls.findall(source) == calls.findall(parent)
        assert source.count("__builtin_amdgcn_s_barrier();") == parent.count("__builtin_amdgcn_s_barrier();")
    reports = []
    functions = parse(directory / "build/device.isa")
    notes = re.split(r"  - \.agpr_count:", (directory / "build/device.notes").read_text())[1:]
    assert len(functions) == len(notes) == 4
    for function, note in zip(functions, notes):
        code = [ins["asm"] for ins in function["code"] if not ins["asm"].startswith("s_code_end")]
        resources = {key: int(re.search(r"\." + key + r":\s*(\d+)", note)[1]) for key in ["vgpr_count", "sgpr_count", "group_segment_fixed_size", "private_segment_fixed_size", "vgpr_spill_count", "sgpr_spill_count", "wavefront_size", "max_flat_workgroup_size"]}
        resources["agpr_count"] = int(note.splitlines()[0])
        assert resources["agpr_count"] == 256 and resources["wavefront_size"] == 64 and resources["max_flat_workgroup_size"] == 256
        assert resources["private_segment_fixed_size"] == resources["vgpr_spill_count"] == resources["sgpr_spill_count"] == 0
        assert not any(re.match(r"\S+\s+exec(?:_lo|_hi)?(?:\s|,)", text) or text.startswith("v_cmpx") for text in code)
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
        assert sorted(counts) == list(range(0, 256, 4)) and set(counts.values()) == {6}
        generic = "blockscale_generic" in function["name"]
        old = [ins["asm"] for ins in baseline_functions[function["name"]]["code"] if not ins["asm"].startswith("s_code_end")]
        if generic:
            assert code == old
        assert sum("vmcnt(0)" in text for text in code) == sum("vmcnt(0)" in text for text in old)
        lds = audit(function)
        assert not lds["hazards"]
        vmem = audit_vmem(function)
        reports.append(dict(name=function["name"], resources=resources, generic_isa_identical=generic, lds_wait=lds, vmem_wait=vmem, exec_unchanged=True, native_mfma_tied_c256=True, no_additional_vmem_drains=True))
    hashes = {file: hashlib.sha256((directory / file).read_bytes()).hexdigest() for file in ["tmpl.hpp", "traits.hpp", "build/device.isa", "build/device.notes", "build/gemm_a8w8_blockscale_bpreshuffle.exe", "build/libblockscale_bpreshuffle.so"]}
    (directory / "resumed_static_audit.json").write_text(json.dumps(dict(status="PASS", hashes=hashes, source_mfma_sequence_unchanged=True, kernels=reports), indent=2) + "\n")
    print(name, "PASS", [(r["resources"]["vgpr_count"], r["resources"]["sgpr_count"], r["vmem_wait"]["cfg_states"]) for r in reports[:2]], flush=True)
