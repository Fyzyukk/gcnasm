#!/usr/bin/env python3
"""Check generic migration resources, pinned accumulators and linked-ISA waits."""
from collections import Counter, deque
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import sys

here = Path(__file__).resolve().parent
work = Path(os.environ.get("MXFP8_WORK_DIR") or (here/"work_path.txt").read_text().strip())
os.environ["MXFP8_WORK_DIR"] = str(work)
previous = here.parent/"continuation_20260911/round3/audit_resumed.py"
spec = importlib.util.spec_from_file_location("previous_audit", previous)
audit = importlib.util.module_from_spec(spec)
saved = sys.argv
sys.argv = sys.argv[:1]
try:
    spec.loader.exec_module(audit)
finally:
    sys.argv = saved

dest = Path(os.environ.get("MXFP8_AUDIT_OUTPUT_DIR") or here/"audits")
dest.mkdir(exist_ok=True)


def audit_output_vmem(function, allowed_from_end=(1,)):
    """Allow only C stores at explicitly declared output-publication barriers.

    Final-half LDS producers and consumers have no alias with global C.
    LDS reads must still complete before that barrier. All earlier barriers
    retain the original full VMEM-drain requirement, and every global read
    still participates in the register-readiness proof.
    """
    code = function["code"]
    positions = {ins["addr"]: i for i, ins in enumerate(code)}
    barriers = [i for i, ins in enumerate(code) if ins["asm"] == "s_barrier"]
    allowed_barriers = {barriers[-offset] for offset in allowed_from_end}
    events = {}
    for i, ins in enumerate(code):
        text = ins["asm"]
        if text.startswith(("buffer_load", "global_load", "flat_load")):
            if " lds" in text:
                events[i] = ("matrix_to_lds", frozenset())
            else:
                events[i] = ("register_load", frozenset(audit.regs(text.split(",")[0])))
        elif text.startswith(("buffer_store", "global_store", "flat_store")):
            events[i] = ("output_store", frozenset())
    queue = deque([(0, ())])
    seen, publications, store_publications = set(), set(), set()
    while queue:
        i, pending = queue.popleft()
        if (i, pending) in seen:
            continue
        seen.add((i, pending))
        assert len(seen) < 1000000, "Unexpected typed VMEM state growth"
        ins = code[i]
        text = ins["asm"]
        wait = re.search(r"\bvmcnt\((\d+)\)", text)
        if wait:
            count = int(wait[1])
            pending = pending[-count:] if count else ()
        busy = set().union(*(dest for kind, dest in pending)) if pending else set()
        assert not audit.regs(text) & busy, (ins, sorted(audit.regs(text) & busy))
        if i in events:
            pending += (events[i],)
        if text == "s_barrier":
            if pending:
                assert i in allowed_barriers and all(kind == "output_store" for kind, dest in pending), (
                    "Non-output VMEM pending at publication", ins, pending)
                store_publications.add((ins["line"], len(pending)))
            else:
                publications.add(ins["line"])
        if text.startswith("s_endpgm"):
            continue
        successors = [positions[ins["target"]]] if "target" in ins else []
        if not text.startswith("s_branch ") and i + 1 < len(code):
            successors.append(i + 1)
        queue.extend((successor, pending) for successor in successors)
    return dict(status="PASS", cfg_states=len(seen), hazards=[],
                barriers_with_zero_pending_vmem=sorted(publications),
                barriers_with_independent_output_stores=sorted(store_publications),
                allowed_output_barriers_from_end=list(allowed_from_end),
                scope="Typed VMEM readiness; only global C stores may cross the declared LDS-output barriers")


def encoding_fingerprint(function, isa_lines):
    encoded = []
    instructions = 0
    for ins in function["code"]:
        if ins["asm"].startswith("s_code_end"):
            continue
        tail = isa_lines[ins["line"] - 1].split("//", 1)[1].split(":", 1)[1]
        match = re.match(r"\s*((?:[0-9A-Fa-f]{8}(?:\s+|$))+)", tail)
        assert match, (ins, tail)
        encoded.extend(match[1].split())
        instructions += 1
        if ins["asm"].startswith("s_endpgm"):
            break
    return dict(instructions=instructions, words=len(encoded),
                encoding_sha256=hashlib.sha256(" ".join(encoded).encode()).hexdigest())


for name in sys.argv[1:]:
    directory = work/name
    source = (directory/"tmpl_generic.hpp").read_text()
    metadata = json.loads((directory/"candidate.json").read_text())
    production = metadata.get("production_single_generic", False)
    if production:
        assert not (directory/"tmpl.hpp").exists()
        assert "blockscale_panel" not in (directory/"gemm_a8w8_mxfp8_scale_kernel.cc").read_text()
        assert "WholeKScaleTraits" not in (directory/"traits.hpp").read_text()
        for filename, expected in metadata["source_hashes"].items():
            assert hashlib.sha256((directory/filename).read_bytes()).hexdigest() == expected, filename
    else:
        assert (directory/"tmpl.hpp").read_bytes() == (work/"baseline/tmpl.hpp").read_bytes()
    dispatch = (directory/"kernel_dispatch.hpp").read_text()
    if dispatch != (work/"baseline/kernel_dispatch.hpp").read_text():
        # Production removes the constant-false harness branch and directly
        # launches generic. Require that exact single-expression function body.
        body = dispatch.split("inline void launch_blockscale_kernel",1)[1].split("{",1)[1].rsplit("}",1)[0]
        assert "".join(body.split()) == "blockscale_generic::gemm_a8w8_mxfp8_scale_kernel<FourWaveTraits<OutputBF16>><<<grid,block,0,stream>>>(args);"
    assert "REQUIRED_K" not in source and "8192" not in source
    assert "const int future_tile = tile + 2;" in source
    if metadata["config"].get("loop_style") == "panel_segments":
        assert "const int main_end = loops - 2;" in source
        assert "while (tile < main_end)" in source
        assert "for (; tile < panel_end; ++tile)" in source
    else:
        assert "for (tile = 0; tile + 2 < loops; ++tile)" in source
    assert "if (loops > 1)" in source
    functions = audit.parse(directory/"build/device.isa")
    isa_lines = (directory/"build/device.isa").read_text().splitlines()
    notes = re.split(r"  - \.agpr_count:", (directory/"build/device.notes").read_text())[1:]
    assert len(functions) == len(notes) == (2 if production else 4)
    reports = []
    for function, note in zip(functions, notes):
        resources = {key:int(re.search(r"\."+key+r":\s*(\d+)",note)[1]) for key in [
            "vgpr_count", "sgpr_count", "group_segment_fixed_size", "private_segment_fixed_size",
            "vgpr_spill_count", "sgpr_spill_count", "wavefront_size", "max_flat_workgroup_size"]}
        resources["agpr_count"] = int(note.splitlines()[0])
        assert resources["wavefront_size"] == 64 and resources["max_flat_workgroup_size"] == 256
        assert resources["agpr_count"] == 256
        assert resources["private_segment_fixed_size"] == resources["vgpr_spill_count"] == resources["sgpr_spill_count"] == 0
        assert resources["group_segment_fixed_size"] <= 163840
        code = [ins["asm"] for ins in function["code"] if not ins["asm"].startswith("s_code_end")]
        generic = "blockscale_generic" in function["name"]
        if production:
            assert generic
            if "expected_generic_isa" in metadata:
                assert encoding_fingerprint(function, isa_lines) == metadata["expected_generic_isa"][function["name"]]
        old = [ins["asm"] for ins in audit.baseline_functions[function["name"]]["code"] if not ins["asm"].startswith("s_code_end")]
        if not generic:
            assert code == old, "Preserved specialized device code changed"
        counts = Counter()
        for text in code:
            if not text.startswith("v_mfma"):
                continue
            assert text.startswith("v_mfma_scale_f32_16x16x128_f8f6f4")
            fields = [x.strip() for x in text.split(" ",1)[1].split(",")]
            assert fields[0] == fields[3]
            lo, hi = map(int,re.fullmatch(r"a\[(\d+):(\d+)\]",fields[0]).groups())
            assert lo % 4 == 0 and hi == lo+3 and hi < 256
            counts[lo] += 1
        assert sorted(counts) == list(range(0,256,4)) and len(set(counts.values())) == 1
        assert not any(re.match(r"\S+\s+exec(?:_lo|_hi)?(?:\s|,)",text) or text.startswith("v_cmpx") or "saveexec" in text for text in code)
        lds = audit.audit(function)
        assert not lds["hazards"]
        if generic and "ILb1E" in function["name"] and metadata["config"].get("output_barriers_without_vmem_drain"):
            allowed = metadata["config"]["output_barriers_without_vmem_drain"]
            assert all(offset in [1, 2, 3, 4] for offset in allowed)
            assert metadata["config"]["output_quarter_publication_mfmas"] == [20, 36, 52, 64]
            assert "auto copy_output_quarter =" in source
            assert not re.search(r"(?:g_a|g_b|g_sfa|g_sfb)\.(?:template )?store", source)
            vmem = audit_output_vmem(function, allowed)
        elif generic and "ILb1E" in function["name"] and metadata["config"].get("final_barrier_vmem_drain") is False:
            assert metadata["config"]["output_half_overlap"] in ["spread", "burst"]
            assert "auto copy_output_half =" in source
            assert "copy_output_half(1, decltype(copy_i)::value);" in source
            # Global stores in this kernel all target the distinct C allocation.
            assert not re.search(r"(?:g_a|g_b|g_sfa|g_sfb)\.(?:template )?store", source)
            vmem = audit_output_vmem(function)
        else:
            vmem = audit.audit_vmem(function)
        reports.append(dict(name=function["name"],generic=generic,resources=resources,
                            unchanged_specialized_isa=not generic,static_mfma_count=sum(counts.values()),
                            native_mfma_tied_c256=True,exec_unchanged=True,lds_wait=lds,vmem_wait=vmem))
    hashes = {f:hashlib.sha256((directory/f).read_bytes()).hexdigest() for f in [
        "tmpl.hpp", "tmpl_generic.hpp", "traits.hpp", "kernel_dispatch.hpp",
        "build/device.isa", "build/device.notes", "build/libblockscale_bpreshuffle.so",
        "build/gemm_a8w8_blockscale_bpreshuffle.exe"] if (directory/f).is_file()}
    report = dict(status="PASS",generic_runtime_k=True,kernel_reports=reports,hashes=hashes,
                  production_single_generic=production, kernel_count=len(functions),
                  measured_generic_instructions_identical=(production and "expected_generic_isa" in metadata),
                  scope="Static linked-ISA checks; runtime panel/tail correctness checked independently")
    (dest/(name+".json")).write_text(json.dumps(report,indent=2)+"\n")
    print(name,"PASS",[r["resources"] for r in reports if r["generic"]],flush=True)
