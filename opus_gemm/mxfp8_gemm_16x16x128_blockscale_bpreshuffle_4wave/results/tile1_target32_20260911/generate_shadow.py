#!/usr/bin/env python3
"""Use limited extra VGPRs to move next-K operand reads out of the loop tail."""
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
parent = (work / "ab0_r4_peel/tmpl.hpp").read_text()
index = json.loads((here / "candidate_index.json").read_text())

configs = {
    "peel_early_a01": dict(a_sites={0: 12, 1: 16}, b_sites={}),
    "peel_early_b01": dict(a_sites={}, b_sites={0: 16, 1: 20}),
    "peel_early_a0b0": dict(a_sites={0: 12}, b_sites={0: 20}),
}
for name, config in configs.items():
    source = parent
    if config["a_sites"]:
        source = source.replace("    typename decltype(mma)::vtype_a v_a[2];",
                                "    typename decltype(mma)::vtype_a v_a[2];\n"
                                "    typename decltype(mma)::vtype_a v_a0_early = {};")
    if config["b_sites"]:
        source = source.replace("    typename decltype(mma)::vtype_b v_b;",
                                "    typename decltype(mma)::vtype_b v_b;\n"
                                "    typename decltype(mma)::vtype_b v_b0_early = {};")
    begin = source.index("#pragma unroll 4")
    end = source.index("    // Consume K62 and roll K63 without")
    loop = source[begin:end]
    if config["a_sites"]:
        offsets = "        const auto ra0_next_offsets =\n            opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 0));\n"
        assert loop.count(offsets) == 1
        loop = loop.replace(offsets, "")
        marker = "        const int future_tile = (tile + 2) & 63;\n"
        loop = loop.replace(marker, marker + offsets, 1)
    for m in config["a_sites"]:
        old = (f"            load_a_mrepeat_scale<T, {m}>(s_a, ra0_next_offsets, v_a[0]);\n"
               "            __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);")
        assert loop.count(old) == 1
        lo, hi = m * 32, (m + 1) * 32
        loop = loop.replace(old,
            f"            opus::set_slice(v_a[0], opus::slice(v_a0_early, opus::number<{lo}>{{}}, opus::number<{hi}>{{}}),\n"
            f"                            opus::number<{lo}>{{}}, opus::number<{hi}>{{}});\n"
            "            __builtin_amdgcn_sched_barrier(0);", 1)
    for n in config["b_sites"]:
        old = (f"        load_b_range_scale<T, {2*n}, {2*n+2}>(s_b, rb0_next_offsets, v_b);\n"
               "        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);")
        assert loop.count(old) == 1
        lo, hi = n * 32, (n + 1) * 32
        loop = loop.replace(old,
            f"        opus::set_slice(v_b, opus::slice(v_b0_early, opus::number<{lo}>{{}}, opus::number<{hi}>{{}}),\n"
            f"                        opus::number<{lo}>{{}}, opus::number<{hi}>{{}});", 1)
    positions, count = {}, 0
    for match in re.finditer(
        r"        MXFP8_MMA_(PAIR|ONE)\(.*?\);\n        (?:sched_barrier_pairs_scale|__builtin_amdgcn_sched_barrier)\([^;]*\);", loop, re.S):
        count += 2 if match[1] == "PAIR" else 1
        positions[count] = match.end()
    assert count == 64
    edits = {}
    for matrix, sites in (("a", config["a_sites"]), ("b", config["b_sites"])):
        for repeat, site in sites.items():
            text = f"\n        // Read next-K {matrix.upper()}0 repeat {repeat} early into a separate operand slice.\n"
            if matrix == "a":
                text += f"        load_a_mrepeat_scale<T, {repeat}>(s_a, ra0_next_offsets, v_a0_early);\n"
            else:
                text += f"        load_b_range_scale<T, {2*repeat}, {2*repeat+2}>(s_b, rb0_next_offsets, v_b0_early);\n"
            text += "        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);\n        __builtin_amdgcn_sched_barrier(0);\n"
            edits[site] = edits.get(site, "") + text
    for site, text in sorted(edits.items(), key=lambda item: positions[item[0]], reverse=True):
        pos = positions[site]
        loop = loop[:pos] + text + loop[pos:]
    candidate = source[:begin] + loop + source[end:]
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
    record = dict(name=name, parent="ab0_r4_peel", config=dict(config, final_iteration_peeled=True),
                  source_sha256=hashlib.sha256(candidate.encode()).hexdigest(), output_tiles_per_wg=1,
                  num_waves=4, per_accumulator_k_order_unchanged=True)
    (patch_dir / "candidate.json").write_text(json.dumps(record, indent=2) + "\n")
    index["candidates"].append(record)
    print(name, config)
(here / "candidate_index.json").write_text(json.dumps(index, indent=2) + "\n")
