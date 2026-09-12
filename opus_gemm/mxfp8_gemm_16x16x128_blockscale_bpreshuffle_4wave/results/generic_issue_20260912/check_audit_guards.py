#!/usr/bin/env python3
"""Negative controls for the typed output-store publication audit; no GPU run."""
import copy
import importlib.util
import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("candidate_audit", HERE / "audit.py")
module = importlib.util.module_from_spec(spec)
saved = sys.argv
sys.argv = sys.argv[:1]
try:
    spec.loader.exec_module(module)
finally:
    sys.argv = saved
work = Path((HERE / "work_path.txt").read_text().strip())
records = []
for name in sys.argv[1:]:
    directory = work / name
    metadata = json.loads((directory / "candidate.json").read_text())
    allowed = metadata["config"]["output_barriers_without_vmem_drain"]
    function = next(f for f in module.audit.parse(directory / "build/device.isa") if "ILb1E" in f["name"])
    positive = module.audit_output_vmem(function, allowed)
    assert positive["barriers_with_independent_output_stores"]
    records.append(dict(name=name, case="declared C stores only", status="PASS"))

    def expect_rejection(test, allowed_barriers, label):
        try:
            module.audit_output_vmem(test, allowed_barriers)
        except AssertionError as error:
            records.append(dict(name=name, case=label, status="REJECTED_AS_EXPECTED", reason=str(error)[:700]))
        else:
            raise AssertionError((name, label, "hazard was not rejected"))

    expect_rejection(function, (), "no declared output-store exception")
    barriers = [i for i, ins in enumerate(function["code"]) if ins["asm"] == "s_barrier"]
    for kind, instruction in [
        ("matrix-to-LDS input", "buffer_load_dwordx4 v0, s[24:27], 0 offen lds"),
        ("register input", "buffer_load_dword v250, v0, s[24:27], 0 offen"),
    ]:
        altered = copy.deepcopy(function)
        # Insert an unretired input immediately before an otherwise allowed
        # output barrier. The original executable and ISA files stay intact.
        altered["code"].insert(barriers[-allowed[0]], dict(addr=-1, line=0, asm=instruction))
        expect_rejection(altered, allowed, kind + " pending at allowed output barrier")

(HERE / "audit_guard_checks.json").write_text(json.dumps(dict(status="PASS", gpu_executed=False, records=records), indent=2) + "\n")
print(json.dumps(records, indent=2))
