#!/usr/bin/env python3
"""Try tile1 workgroup ordering for matrix reuse and output cache traffic."""
import difflib
import hashlib
import json
from pathlib import Path
import shutil

here = Path(__file__).resolve().parent
work = Path((here / "work_path.txt").read_text().strip())
base = work / "baseline"
original = (base / "tmpl.hpp").read_text()
parent = (work / "ab0_release4_keep/tmpl.hpp").read_text()
index = json.loads((here / "candidate_index.json").read_text())
old = "    const int block_m = wgid / num_tiles_n;\n    const int block_n = wgid % num_tiles_n;\n"
assert parent.count(old) == 1
configs = {}
for group in (2, 4, 8):
    replacement = f"""    // Reorder independent tile1 workgroups; each still owns one 256x256 output.
    constexpr int group_m = {group};
    const int num_tiles_m = ceil_div_scale(kargs.m, T::B_M);
    const int group_id = wgid / (group_m * num_tiles_n);
    const int first_m = group_id * group_m;
    const int remaining_m = num_tiles_m - first_m;
    const int active_m = remaining_m < group_m ? remaining_m : group_m;
    const int local_wg = wgid % (group_m * num_tiles_n);
    const int block_m = first_m + local_wg % active_m;
    const int block_n = local_wg / active_m;
"""
    configs[f"ab0_r4_group{group}"] = (dict(group_m=group), replacement)
configs["ab0_r4_diagonal"] = (dict(grid="diagonal"),
    "    const int block_m = wgid / num_tiles_n;\n"
    "    const int block_n = (wgid % num_tiles_n + block_m) % num_tiles_n;\n")
configs["ab0_r4_xor"] = (dict(grid="xor for power-of-two N tile counts, diagonal otherwise"),
    "    const int block_m = wgid / num_tiles_n;\n"
    "    const int raw_n = wgid % num_tiles_n;\n"
    "    const int block_n = (num_tiles_n & (num_tiles_n - 1)) == 0\n"
    "        ? raw_n ^ (block_m & (num_tiles_n - 1))\n"
    "        : (raw_n + block_m) % num_tiles_n;\n")
for name, (config, replacement) in configs.items():
    candidate = parent.replace(old, replacement, 1)
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
                  num_waves=4, source_mfma_order_unchanged=True)
    (patch_dir / "candidate.json").write_text(json.dumps(record, indent=2) + "\n")
    index["candidates"].append(record)
    print(name, config)
(here / "candidate_index.json").write_text(json.dumps(index, indent=2) + "\n")
