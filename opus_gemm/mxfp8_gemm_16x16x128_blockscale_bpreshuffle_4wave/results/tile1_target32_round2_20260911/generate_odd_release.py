#!/usr/bin/env python3
"""Place the LDS publication between native MFMAs of a source pair."""
import difflib
import hashlib
import json
from pathlib import Path
import re
import shutil

here = Path(__file__).resolve().parent
work = Path((here / "work_path.txt").read_text().strip())
base = here / "baseline_source"
original = (base / "tmpl.hpp").read_text()
index = json.loads((here / "candidate_index.json").read_text())
pattern = re.compile(r"        MXFP8_MMA_PAIR\(\n            0, 0, 0, v_a\[0\], v_b, c00_0, c00_1, v_sfa, v_sfb\[0\]\);.*?"
                     r"        MXFP8_MMA_PAIR\(\n            0, 1, 1, v_a\[0\], v_b, c00_6, c00_7, v_sfa, v_sfb\[0\]\);\n        sched_barrier_pairs_scale\(\);", re.S)
assert len(list(pattern.finditer(original))) == 2
for site in [1, 3, 5, 7]:
    publication = f"""

        // MFMA{site}: publish t+1 and release stage t between independent MFMAs.
        __builtin_amdgcn_s_setprio(0);
        s_waitcnt_vmcnt(0_I);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);
        __builtin_amdgcn_s_setprio(1);
"""
    body = ""
    i = 0
    while i < 8:
        if i % 2 == 0 and i + 1 != site:
            body += f"        MXFP8_MMA_PAIR(0, {i//4}, {(i%4)//2}, v_a[0], v_b, c00_{i}, c00_{i+1}, v_sfa, v_sfb[0]);\n        sched_barrier_pairs_scale();"
            i += 2
        else:
            body += f"        MXFP8_MMA_ONE(0, {i//4}, {i%4}, v_a[0], v_b, c00_{i}, v_sfa, v_sfb[0]);\n        __builtin_amdgcn_sched_barrier(0);"
            i += 1
        if i == site:
            body += publication
        if i < 8:
            body += "\n\n"
    source = pattern.sub(body, original)
    source = source.replace("After publication at MFMA4", f"After publication at MFMA{site}").replace("K63 operands at MFMA4", f"K63 operands at MFMA{site}")
    name = f"release{site}_single"
    target = work / name
    shutil.copytree(base, target)
    (target / "tmpl.hpp").write_text(source)
    patches = here / "candidate_patches" / name
    patches.mkdir(parents=True)
    (patches / "tmpl.patch").write_text("".join(difflib.unified_diff(original.splitlines(True), source.splitlines(True), fromfile="a/tmpl.hpp", tofile="b/tmpl.hpp")))
    record = dict(name=name, config=dict(release_mfma=site, split_pair_for_publication=True, request_sites_unchanged=True),
                  source_sha256=hashlib.sha256(source.encode()).hexdigest(), num_waves=4,
                  output_tiles_per_wg=1, per_accumulator_k_order_unchanged=True)
    (patches / "candidate.json").write_text(json.dumps(record, indent=2)+"\n")
    (target / "candidate.json").write_text(json.dumps(record, indent=2)+"\n")
    index["candidates"].append(record)
    print(name)
(here / "candidate_index.json").write_text(json.dumps(index, indent=2)+"\n")
