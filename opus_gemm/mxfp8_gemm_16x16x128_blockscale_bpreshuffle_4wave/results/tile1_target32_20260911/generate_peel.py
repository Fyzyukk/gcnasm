#!/usr/bin/env python3
"""Remove unused final matrix producers and combine adjacent scale reads."""
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
parent = (work / "ab0_release4_keep/tmpl.hpp").read_text()
index = json.loads((here / "candidate_index.json").read_text())

def peel(source):
    begin = source.index("    for (tile = 0; tile + 1 < loops; ++tile) {")
    end = source.index("    // Consume the final resident tile with")
    loop = source[begin:end]
    assert loop.endswith("    }\n\n")
    body = loop[loop.index("\n") + 1:loop.rindex("    }")]
    body, count = re.subn(
        r"        prefetch_matrix_issue\(opus::number<\d+>\{\}, stage, future_tile\);\n"
        r"        __builtin_amdgcn_sched_group_barrier\(0x20, 1, 0\);\n"
        r"        __builtin_amdgcn_sched_barrier\(0\);\n", "", body)
    assert count == 16
    body = body.replace("        const int future_tile = (tile + 2) & 63;\n", "")
    main = loop.replace("tile + 1 < loops", "tile + 2 < loops", 1)
    return (source[:begin] + main
            + "    // Consume K62 and roll K63 without issuing the unused K64 matrix requests.\n"
            + "    {\n" + body + "    }\n\n" + source[end:])

def paired_sfa(source):
    source = source.replace("    D_SF_PACK v_sfa1_next;", "    opus::vector_t<D_SF_PACK, 2> v_sfa_next;")
    old = "        v_sfa1_next = load_sfa_dword(tile + 1, 1);"
    assert source.count(old) == 1
    source = source.replace(old,
        "        v_sfa_next = __builtin_bit_cast(opus::vector_t<D_SF_PACK, 2>,\n"
        "            load<8>(s_sfa, (tile + 1) * T::SFA_PANEL_PITCH\n"
        "                + (wave_id_m * T::W_M + (lane_id & 15)) * 8));")
    source = source.replace("        v_sfa[0] = load_sfa_dword(tile + 1, 0);", "        v_sfa[0] = v_sfa_next[0];")
    source = source.replace("        v_sfa[1] = v_sfa1_next;", "        v_sfa[1] = v_sfa_next[1];")
    return source

configs = {
    "ab0_r4_peel": (peel(parent), dict(final_iteration_peeled=True)),
    "ab0_r4_sfa_pair": (paired_sfa(parent), dict(sfa_next_pair=True)),
    "ab0_r4_peel_sfa": (peel(paired_sfa(parent)), dict(final_iteration_peeled=True, sfa_next_pair=True)),
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
    record = dict(name=name, parent="ab0_release4_keep", config=config,
                  source_sha256=hashlib.sha256(candidate.encode()).hexdigest(), output_tiles_per_wg=1,
                  num_waves=4, per_accumulator_k_order_unchanged=True)
    (patch_dir / "candidate.json").write_text(json.dumps(record, indent=2) + "\n")
    index["candidates"].append(record)
    print(name, config)
(here / "candidate_index.json").write_text(json.dumps(index, indent=2) + "\n")
