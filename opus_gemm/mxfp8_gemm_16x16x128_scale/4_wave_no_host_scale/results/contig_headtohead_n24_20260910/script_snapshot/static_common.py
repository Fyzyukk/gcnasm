#!/usr/bin/env python3
"""Schedule-independent safety/resource audit for four-wave closeout candidates."""
import collections
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import sys

def audit(build):
    build = Path(build).resolve(strict=True)
    spec = importlib.util.spec_from_file_location("four_wave_gate", Path(__file__).resolve().parents[1] / "gate.py")
    gate = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(gate)
    gate.check_scale_mapping()
    gate.check_sfa_k8_slab_mapping()
    gate.check_sfb_k16_slab_mapping()
    ins = gate.instructions((build / "kernel.isa").read_text())
    notes = (build / "kernel.notes").read_text()
    counts = collections.Counter(map(gate.opcode, ins))
    fields = ("agpr_count", "vgpr_count", "sgpr_count", "vgpr_spill_count",
              "sgpr_spill_count", "private_segment_fixed_size", "group_segment_fixed_size",
              "max_flat_workgroup_size", "wavefront_size", "kernarg_segment_size")
    resources = {field: gate.metadata(notes, field) for field in fields}
    for field, expected in {"agpr_count": 256, "vgpr_spill_count": 0,
        "sgpr_spill_count": 0, "private_segment_fixed_size": 0,
        "group_segment_fixed_size": 163840, "max_flat_workgroup_size": 256,
        "wavefront_size": 64, "kernarg_segment_size": 96}.items():
        if resources[field] != expected:
            raise RuntimeError(f"{build}: {field}={resources[field]} != {expected}")
    if resources["vgpr_count"] - resources["agpr_count"] > 256:
        raise RuntimeError("ordinary VGPR budget exceeded")
    if len(re.findall(r"^\s+\.name:", notes, re.M)) != 1 or "--gfx950" not in notes:
        raise RuntimeError("expected one gfx950 kernel")
    mfmas = [line for line in ins if line.startswith("v_mfma_scale_f32_16x16x128_f8f6f4")]
    expected_acc = {f"a[{i}:{i+3}]" for i in range(0, 256, 4)}
    operands = [gate.mfma_operands(line) for line in mfmas]
    if len(mfmas) != 384 or {op[0] for op in operands} != expected_acc:
        raise RuntimeError("unexpected scaled MFMA/accumulator set")
    if any(op[0] != op[3] for op in operands):
        raise RuntimeError("MFMA destination and accumulator differ")
    stores = [line for line in ins if line.startswith(("buffer_store_dwordx4", "global_store_dwordx4"))]
    if len(stores) != 64 or {x.split(None, 1)[1].split(",", 1)[0].strip() for x in stores} != expected_acc:
        raise RuntimeError("expected 64 direct AGPR output stores")
    if any(op.startswith(("scratch_", "v_accvgpr_read")) for op in counts):
        raise RuntimeError("unexpected scratch or accumulator bridge")
    windows, srds = gate.coexec_vmem4_windows(ins)
    if windows != 21 or sorted(srds.values()) != [1, 10, 10]:
        raise RuntimeError(f"A/B co-execution windows lost: {windows}")
    return {"resources": resources, "instructions": len(ins), "scaled_mfma": len(mfmas),
            "coexec_windows": windows, "coexec_srd_distribution": sorted(srds.values()),
            "normalized_isa_sha256": hashlib.sha256(("\n".join(ins) + "\n").encode()).hexdigest(),
            "status": "static_pass_requires_gpu_correctness", "opcodes": dict(counts)}

if __name__ == "__main__":
    print(json.dumps(audit(sys.argv[1]), indent=2))
