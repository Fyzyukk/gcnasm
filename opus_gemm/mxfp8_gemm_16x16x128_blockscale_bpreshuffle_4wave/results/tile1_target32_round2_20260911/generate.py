#!/usr/bin/env python3
"""Continue from aabad81 with bounded epilogue and scalar scheduling trials."""
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


def stores_by_row(delay):
    start = original.index("    MXFP8_MMA_PAIR(0, 0, 0, v_a[0], v_b, c00_0", original.index("    // Consume the final resident tile"))
    prefix, body = original[:start], original[start:]
    for c, m, n in [("c00", 0, 0), ("c10", 1, 0), ("c01", 0, 1), ("c11", 1, 1)]:
        old = f"    MXFP8_STORE_QUADRANT({c}, {m}, {n});"
        assert body.count(old) == 1
        body = body.replace(old, "    if constexpr (!T::OUTPUT_BF16) {\n    " + old + "\n    }")
    matches = list(re.finditer(r"    MXFP8_MMA_PAIR\([^\n]+\);\n    sched_barrier_pairs_scale\(\);", body))
    assert len(matches) == 32
    edits = {}
    for quadrant, (c, m, n) in enumerate([("c00", 0, 0), ("c10", 1, 0), ("c01", 0, 1), ("c11", 1, 1)]):
        for row in range(4):
            site = min(64, quadrant * 16 + (row + 1) * 4 + delay)
            fragment = row * 4
            edits.setdefault(site, "")
            edits[site] += f"""

    // Convert and write this completed row after {delay} independent MFMAs.
    if constexpr (T::OUTPUT_BF16) {{
        const int soff = c_offset({m}, {n});
        MXFP8_STORE_AGPR_PAIR8({c}_{fragment}, {c}_{fragment+1}, {fragment});
        MXFP8_STORE_AGPR_PAIR8({c}_{fragment+2}, {c}_{fragment+3}, {fragment+2});
    }}"""
    for site, code in sorted(edits.items(), reverse=True):
        at = matches[site // 2 - 1].end()
        body = body[:at] + code + body[at:]
    return prefix + body


def release_at(site):
    pattern = re.compile(r"        // MFMA4: complete operand reads, publish t\+1, and release stage t\.\n"
                         r"        __builtin_amdgcn_s_setprio\(0\);\n"
                         r"        s_waitcnt_vmcnt\(0_I\);\n"
                         r"        s_waitcnt_lgkmcnt\(0_I\);\n"
                         r"        __builtin_amdgcn_s_barrier\(\);\n"
                         r"        __builtin_amdgcn_sched_barrier\(0\);\n"
                         r"        __builtin_amdgcn_s_setprio\(1\);\n")
    blocks = list(pattern.finditer(original))
    assert len(blocks) == 2
    source = original
    for match in reversed(blocks):
        publication = match[0].replace("MFMA4:", f"MFMA{site}:")
        source = source[:match.start()] + source[match.end():]
        begin = source.rfind("        // A half 0 x B half 0", 0, match.start())
        mma_pattern = re.compile(r"        MXFP8_MMA_PAIR\(\s*[^;]+\);\n        sched_barrier_pairs_scale\(\);")
        calls = list(mma_pattern.finditer(source, begin))
        at = calls[site // 2 - 1].end()
        source = source[:at] + "\n\n" + publication + source[at:]
    return source


def resident_epilogue():
    before, after = original.split("    // Consume the final resident tile", 1)
    for statement in ["v_a[1] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 1));",
                      "v_sfb[1] = load_sfb_dword(loops - 1, 1);"]:
        assert after.count(statement) == 1
        after = after.replace(statement, "if constexpr (!T::OUTPUT_BF16) " + statement)
    old = "    v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 1));"
    assert after.count(old) == 1
    after = after.replace(old, "    if constexpr (T::OUTPUT_BF16) v_b = v_b_second;\n    else " + old.strip())
    return before + "    // Consume the final resident tile" + after


configs = {
    "bf16_store_rows4": (stores_by_row(4), {"epilogue_row_store_delay": 4}),
    "bf16_store_rows8": (stores_by_row(8), {"epilogue_row_store_delay": 8}),
    "bf16_store_cache2": (original.replace("offset, soff, opus::number<0>{}); \\", "offset, soff, opus::number<2>{}); \\"), {"bf16_store_aux": 2}),
    "bf16_resident_epilogue": (resident_epilogue(), {"bf16_epilogue_resident": True}),
    "release6": (release_at(6), {"release_mfma": 6, "request_sites_unchanged": True}),
    "release2": (release_at(2), {"release_mfma": 2, "request_sites_unchanged": True}),
    "keep_loop_priority": (original.replace("        __builtin_amdgcn_s_setprio(0);\n        v_sfb[1]", "        v_sfb[1]"), {"omit_loop_tail_priority_reset": True}),
}

for name, (source, config) in configs.items():
    assert source != original, name
    target = work / name
    shutil.copytree(base, target)
    (target / "tmpl.hpp").write_text(source)
    patches = here / "candidate_patches" / name
    patches.mkdir(parents=True)
    (patches / "tmpl.patch").write_text("".join(difflib.unified_diff(original.splitlines(True), source.splitlines(True), fromfile="a/tmpl.hpp", tofile="b/tmpl.hpp")))
    record = dict(name=name, config=config, source_sha256=hashlib.sha256(source.encode()).hexdigest(),
                  num_waves=4, output_tiles_per_wg=1, per_accumulator_k_order_unchanged=True)
    (patches / "candidate.json").write_text(json.dumps(record, indent=2) + "\n")
    (target / "candidate.json").write_text(json.dumps(record, indent=2) + "\n")
    index["candidates"].append(record)
    print(name, config)
(here / "candidate_index.json").write_text(json.dumps(index, indent=2) + "\n")
