#!/usr/bin/env python3
"""Clean the measured candidate; require linked-instruction equality before promotion."""
import argparse
import difflib
import json
import re

from make_candidates import HERE, WORK, record, replace_n


def clean(source):
    source = replace_n(source, """    // Materialize immutable address deltas once in VGPRs, leaving only
    // the shared K offset in the scalar issue path. IOFFSET shifts both ends.
""", """    // Cache immutable address deltas in VGPRs; only K advances in SGPRs.
    // Four requests share one m0 base, with IOFFSET 0/1056/2112/3168.
    // Subtract that same immediate from VOFFSET to preserve the input address.
""", 1)
    source = replace_n(source, """    // Prefetch while two later K128 blocks exist; peel the penultimate block.
    // Future matrix addresses always use the complete runtime K index.
""", """    // Prefetch while two later K128 blocks exist; peel the penultimate block.
    // Future matrix addresses always use the complete runtime K index.
    // Keep priority 1 across main iterations; scale-panel refill uses 0/1.
""", 1)
    source = replace_n(source, """        // After publication at MFMA5, all waves issue one t+2 request
        // at the recorded issue sites through MFMA37. Wave-uniform resources select
        // the A or B producer without role branches inside the K loop.
""", """        // After publication at MFMA5, all waves issue one t+2 request
        // after MFMA7,9,...,37. Wave-uniform resources select the A or B
        // producer without role branches inside the K loop.
""", 1)
    return re.sub(r"\n{3,}", "\n\n", source)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("candidate")
    parser.add_argument("--name", default="generic_tile1_issue_20260912")
    args = parser.parse_args()
    metadata = json.loads((WORK / args.candidate / "candidate.json").read_text())
    audit = json.loads((HERE / "audits" / (args.candidate + ".json")).read_text())
    assert audit["status"] == "PASS"
    original = (WORK / args.candidate / "tmpl_generic.hpp").read_text()
    source = clean(original)
    support = {name: (WORK / args.candidate / name).read_text()
               for name in metadata.get("changed_support_files", [])}
    record(args.name, source, metadata["config"], support_changes=support)
    for directory in [WORK / args.name, HERE / "candidate_patches" / args.name]:
        path = directory / "candidate.json"
        data = json.loads(path.read_text())
        data.update(selected_from=args.candidate, cleanup_requires_instruction_equality=True)
        path.write_text(json.dumps(data, indent=2) + "\n")
    patch = "".join(difflib.unified_diff(original.splitlines(True), source.splitlines(True),
                                        fromfile="a/tmpl_generic.hpp", tofile="b/tmpl_generic.hpp"))
    (HERE / "candidate_patches" / args.name / "cleanup.patch").write_text(patch)


if __name__ == "__main__":
    main()
