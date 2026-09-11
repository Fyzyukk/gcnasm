#!/usr/bin/env python3
"""Spread B1 rolls by reordering independent C11 accumulators within each K."""
import difflib
import hashlib
import json
from pathlib import Path
import shutil

here = Path(__file__).resolve().parent
work = Path((here / "work_path.txt").read_text().strip())
base = work / "baseline"
original = (base / "tmpl.hpp").read_text()
index = json.loads((here / "candidate_index.json").read_text())

orders = {
    "tail_columns": list(range(8)) + [8, 12, 9, 13, 10, 14, 11, 15],
    "full_columns": [4 * m + n for n in range(4) for m in range(4)],
}
for parent_name in ("ab0_spread", "ab0_release4_keep"):
    parent = (work / parent_name / "tmpl.hpp").read_text()
    for label, order in orders.items():
        name = ("ab0" if parent_name == "ab0_spread" else "ab0_r4") + "_" + label
        start = parent.index("        // A half 1 x B half 1 -> C[1][1] (128x128 wave quadrant).")
        end = parent.index("        __builtin_amdgcn_s_setprio(0);", start)
        assert sorted(order) == list(range(16))
        last_a = {m: max(i for i, acc in enumerate(order) if acc // 4 == m) for m in range(4)}
        last_b = {n: max(i for i, acc in enumerate(order) if acc % 4 == n) for n in range(4)}
        code = ["        // C11: reorder independent accumulators and roll each operand after its last use.\n"]
        i = 0
        while i < 16:
            acc = order[i]
            m, n = divmod(acc, 4)
            paired = (i + 1 < 16 and n % 2 == 0 and order[i + 1] == acc + 1
                      and i not in last_a.values() and i not in last_b.values())
            if paired:
                code.append(f"        MXFP8_MMA_PAIR(1, {m}, {n // 2}, v_a[1], v_b_n1, c11_{acc}, c11_{acc + 1}, v_sfa, v_sfb[1]);\n")
                code.append("        sched_barrier_pairs_scale();\n")
                i += 1
            else:
                code.append(f"        MXFP8_MMA_ONE(1, {m}, {n}, v_a[1], v_b_n1, c11_{acc}, v_sfa, v_sfb[1]);\n")
                code.append("        __builtin_amdgcn_sched_barrier(0);\n")
            dead_a = [m for m, position in last_a.items() if position == i]
            dead_b = [n for n, position in last_b.items() if position == i]
            if dead_a or dead_b:
                code.append(f"        // MFMA{49 + i}: these operand slices have no remaining current-K consumers.\n")
                code.append("        __builtin_amdgcn_sched_barrier(0);\n")
                for m in dead_a:
                    code.append(f"        load_a_mrepeat_scale<T, {m}>(s_a, ra1_next_offsets, v_a[1]);\n")
                for n in dead_b:
                    code.append(f"        load_b_range_scale<T, {2 * n}, {2 * n + 2}>(s_b, rb1_next_offsets, v_b_second);\n")
                code.append(f"        __builtin_amdgcn_sched_group_barrier(0x100, {2 * (len(dead_a) + len(dead_b))}, 0);\n")
                code.append("        __builtin_amdgcn_sched_barrier(0);\n")
            code.append("\n")
            i += 1
        candidate = parent[:start] + "".join(code) + parent[end:]
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
        record = dict(name=name, parent=parent_name, config=dict(c11_order=order, last_a=last_a, last_b=last_b),
                      source_sha256=hashlib.sha256(candidate.encode()).hexdigest(), output_tiles_per_wg=1,
                      num_waves=4, source_mfma_order_unchanged=False, per_accumulator_k_order_unchanged=True)
        (patch_dir / "candidate.json").write_text(json.dumps(record, indent=2) + "\n")
        index["candidates"].append(record)
        print(name, order)
(here / "candidate_index.json").write_text(json.dumps(index, indent=2) + "\n")
