#!/usr/bin/env python3
"""Tune publication and epilogue around the validated A0/B0 spread schedule."""
from collections import defaultdict
import difflib
import hashlib
import json
from pathlib import Path
import re
import shutil

here = Path(__file__).resolve().parent
work = Path((here / "work_path.txt").read_text().strip())
base = work / "baseline"
original = (base / "tmpl.hpp").read_text()
parent = (work / "ab0_spread/tmpl.hpp").read_text()
index = json.loads((here / "candidate_index.json").read_text())
assert hashlib.sha256(original.encode()).hexdigest() == index["baseline_tmpl_sha256"]

def publication(release, sites):
    begin = parent.index("#pragma unroll 4")
    end = parent.index("    // Consume the final resident tile with")
    loop = parent[begin:end]
    loop, count = re.subn(
        r"\n        prefetch_matrix_issue\(opus::number<\d+>\{\}, stage, future_tile\);\n"
        r"        __builtin_amdgcn_sched_group_barrier\(0x20, 1, 0\);\n"
        r"        __builtin_amdgcn_sched_barrier\(0\);\n", "\n", loop)
    assert count == 16
    loop, count = re.subn(
        r"\n        // MFMA8: finish the previous iteration's operand reads,\n"
        r"        // publish t\+1, and release the old stage for the t\+2 producers\.\n"
        r"        __builtin_amdgcn_s_setprio\(0\);\n"
        r"        s_waitcnt_vmcnt\(0_I\);\n"
        r"        s_waitcnt_lgkmcnt\(0_I\);\n"
        r"        __builtin_amdgcn_s_barrier\(\);\n"
        r"        __builtin_amdgcn_sched_barrier\(0\);\n"
        r"        __builtin_amdgcn_s_setprio\(1\);\n", "\n", loop)
    assert count == 1
    positions = {}
    count = 0
    for match in re.finditer(
        r"        MXFP8_MMA_(PAIR|ONE)\(.*?\);\n        (?:sched_barrier_pairs_scale|__builtin_amdgcn_sched_barrier)\([^;]*\);", loop, re.S):
        if not count:
            positions[0] = match.start()
        count += 2 if match[1] == "PAIR" else 1
        positions[count] = match.end()
    assert count == 64 and len(sites) == 16 and min(sites) >= release
    edits = defaultdict(str)
    edits[release] = f"""

        // MFMA{release}: complete operand reads, publish t+1, and release stage t.
        __builtin_amdgcn_s_setprio(0);
        s_waitcnt_vmcnt(0_I);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);
        __builtin_amdgcn_s_setprio(1);
"""
    for issue, site in enumerate(sites):
        edits[site] += (f"\n        prefetch_matrix_issue(opus::number<{issue}>{{}}, stage, future_tile);\n"
                        "        __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);\n"
                        "        __builtin_amdgcn_sched_barrier(0);\n")
    for site, text in sorted(edits.items(), key=lambda item: positions[item[0]], reverse=True):
        pos = positions[site]
        loop = loop[:pos] + text + loop[pos:]
    return parent[:begin] + loop + parent[end:]

def with_epilogue(name):
    source = (work / name / "tmpl.hpp").read_text()
    tail = source[source.index("    // The final A1/B1 operands"):]
    return parent[:parent.index("    // Consume the final resident tile with")] + tail

configs = {
    "ab0_release4": (publication(4, list(range(4, 35, 2))), dict(release=4, request_sites=list(range(4, 35, 2)))),
    "ab0_release4_keep": (publication(4, list(range(8, 39, 2))), dict(release=4, request_sites=list(range(8, 39, 2)))),
    "ab0_release12": (publication(12, list(range(12, 43, 2))), dict(release=12, request_sites=list(range(12, 43, 2)))),
    "ab0_release0": (publication(0, list(range(0, 31, 2))), dict(release=0, request_sites=list(range(0, 31, 2)))),
    "ab0_noprio": (re.sub(r"^\s*__builtin_amdgcn_s_setprio\(\d\);\n", "", parent, flags=re.M), dict(priority="default throughout")),
    "ab0_unroll2": (parent.replace("#pragma unroll 4", "#pragma unroll 2", 1), dict(unroll=2)),
    "ab0_resident": (with_epilogue("epilogue_resident"), dict(epilogue="reuse final resident operands")),
    "ab0_earlystore": (with_epilogue("early_store_resident"), dict(epilogue="resident operands and early C00/C01 stores")),
}
for name, (candidate, config) in configs.items():
    directory = work / name
    directory.mkdir(exist_ok=False)
    for file in base.iterdir():
        if file.is_file():
            shutil.copy2(file, directory / file.name)
    (directory / "tmpl.hpp").write_text(candidate)
    patch_dir = here / "candidate_patches" / name
    patch_dir.mkdir(parents=True, exist_ok=False)
    (patch_dir / "tmpl.patch").write_text("".join(difflib.unified_diff(
        original.splitlines(True), candidate.splitlines(True), fromfile="a/tmpl.hpp", tofile="b/tmpl.hpp")))
    record = dict(name=name, parent="ab0_spread", config=config, source_sha256=hashlib.sha256(candidate.encode()).hexdigest(),
                  output_tiles_per_wg=1, num_waves=4, source_mfma_order_unchanged=True)
    (patch_dir / "candidate.json").write_text(json.dumps(record, indent=2) + "\n")
    index["candidates"].append(record)
    print(name, config)
(here / "candidate_index.json").write_text(json.dumps(index, indent=2) + "\n")
