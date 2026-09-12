#!/usr/bin/env python3
"""Free B0 slices earlier by reordering independent C10 accumulators."""
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
configs = {
    "c10_tail_columns": [0, 1, 2, 3, 4, 5, 6, 7, 8, 12, 9, 13, 10, 14, 11, 15],
    "c10_full_columns": [n + 4*m for n in range(4) for m in range(4)],
    "c10_pair_columns": [0, 1, 4, 5, 8, 9, 12, 13, 2, 3, 6, 7, 10, 11, 14, 15],
}

for name, order in configs.items():
    last_b = {n: max(i + 17 for i, c in enumerate(order) if c % 4 == n) for n in range(4)}
    # Pair-columns frees the two adjacent N repeats at the pair boundary.
    sites = {n: (last_b[n] + 1) // 2 * 2 for n in range(4)}
    source = original
    old_b_reads = re.compile(r"        // Spread the dead B0 operand reads after MFMA\d+\.\n"
                            r"        load_b_range_scale<T, \d, \d>\(s_b, rb0_next_offsets, v_b\);\n"
                            r"        __builtin_amdgcn_sched_group_barrier\(0x100, 2, 0\);\n"
                            r"        __builtin_amdgcn_sched_barrier\(0\);\n")
    source, count = old_b_reads.subn("", source)
    assert count == 8
    regions = list(re.finditer(r"        // A half 1 x B half 0 -> C\[1\]\[0\] \(128x128 wave quadrant\)\.\n.*?(?=        const auto& v_b_n1)", source, re.S))
    assert len(regions) == 2
    for region_index in [1, 0]:
        region = regions[region_index]
        body = "        // C10 visits independent accumulators in the recorded order.\n"
        i = 0
        while i < 16:
            c = order[i]
            paired = i+1 < 16 and c % 2 == 0 and order[i+1] == c+1
            if paired:
                body += f"        MXFP8_MMA_PAIR(1, {c//4}, {(c%4)//2}, v_a[1], v_b, c10_{c}, c10_{c+1}, v_sfa, v_sfb[0]);\n        sched_barrier_pairs_scale();\n"
                i += 2
            else:
                body += f"        MXFP8_MMA_ONE(1, {c//4}, {c%4}, v_a[1], v_b, c10_{c}, v_sfa, v_sfb[0]);\n        __builtin_amdgcn_sched_barrier(0);\n"
                i += 1
            site = 16 + i
            if region_index == 0 and site % 2 == 0:
                issue = (site - 8) // 2
                body += f"        prefetch_matrix_issue(opus::number<{issue}>{{}}, stage, future_tile);\n        __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);\n        __builtin_amdgcn_sched_barrier(0);\n"
            freed = [n for n in range(4) if sites[n] == site]
            if freed:
                body += f"        // MFMA{site}: these B0 slices have no remaining current-K consumer.\n"
                for n in freed:
                    body += f"        load_b_range_scale<T, {n*2}, {n*2+2}>(s_b, rb0_next_offsets, v_b);\n"
                body += f"        __builtin_amdgcn_sched_group_barrier(0x100, {2*len(freed)}, 0);\n        __builtin_amdgcn_sched_barrier(0);\n"
            body += "\n"
        source = source[:region.start()] + body + source[region.end():]
    target = work / name
    shutil.copytree(base, target)
    (target / "tmpl.hpp").write_text(source)
    patches = here / "candidate_patches" / name
    patches.mkdir(parents=True)
    (patches / "tmpl.patch").write_text("".join(difflib.unified_diff(original.splitlines(True), source.splitlines(True), fromfile="a/tmpl.hpp", tofile="b/tmpl.hpp")))
    record = dict(name=name, config=dict(c10_order=order, b0_load_sites=sites),
                  source_sha256=hashlib.sha256(source.encode()).hexdigest(),
                  num_waves=4, output_tiles_per_wg=1, per_accumulator_k_order_unchanged=True)
    (patches / "candidate.json").write_text(json.dumps(record, indent=2)+"\n")
    (target / "candidate.json").write_text(json.dumps(record, indent=2)+"\n")
    index["candidates"].append(record)
    print(name, sites)
(here / "candidate_index.json").write_text(json.dumps(index, indent=2)+"\n")
