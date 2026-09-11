#!/usr/bin/env python3
"""Independent-wave A/B register rolling, with only immutable scales in LDS."""
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
source = (work / "ab0_resident/tmpl.hpp").read_text()
index = json.loads((here / "candidate_index.json").read_text())

# Each lane's operand consists of K16 pieces at k=16*(lane/16) and k+64.
# B's preshuffle linearizes (N16 group, K16 group, N16 lane, K16 byte).
source = source.replace("    auto u_ra = make_layout_ra_scale<T>(lane_id, wave_id_m);",
    "    auto u_ra = opus::make_layout<T::VEC_A>(\n"
    "        opus::make_tuple(4_I, 2_I, opus::number<T::VEC_A>{}),\n"
    "        opus::make_tuple(32 * kargs.stride_a, 64_I, 1_I),\n"
    "        opus::make_tuple(opus::underscore{}, opus::underscore{}, opus::underscore{}))\n"
    "        + (16 * wave_id_m + lane_id % 16) * kargs.stride_a + 16 * (lane_id / 16);")
source = source.replace("    auto u_rb = make_layout_rb_scale<T>(lane_id, wave_id_n);",
    "    auto u_rb = opus::make_layout<T::VEC_B>(\n"
    "        opus::make_tuple(4_I, 2_I, opus::number<T::VEC_B>{}),\n"
    "        opus::make_tuple(32 * kargs.stride_b, 1024_I, 1_I),\n"
    "        opus::make_tuple(opus::underscore{}, opus::underscore{}, opus::underscore{}))\n"
    "        + 16 * wave_id_n * kargs.stride_b + 16 * lane_id;")
start = source.index("    constexpr int smem_a_elem =")
end = source.index("    alignas(8) __shared__ char smem_sfa", start)
source = source[:start] + "    auto s_a = g_a;\n    auto s_b = g_b;\n\n" + source[end:]
source, count = re.subn(r"^    auto s[ab]_offset = .*?;\n", "", source, flags=re.M)
assert count == 2
source, count = re.subn(r"^    async_load<T::VEC_[AB]>\(.*?;\n", "", source, flags=re.M)
assert count == 8
source, count = re.subn(
    r"        prefetch_matrix_issue\(opus::number<\d+>\{\}, stage, future_tile\);\n"
    r"        __builtin_amdgcn_sched_group_barrier\(0x20, 1, 0\);\n"
    r"        __builtin_amdgcn_sched_barrier\(0\);\n", "", source)
assert count == 16
source, count = re.subn(
    r"        // MFMA8: finish the previous iteration's operand reads,\n"
    r"        // publish t\+1, and release the old stage for the t\+2 producers\.\n"
    r"        __builtin_amdgcn_s_setprio\(0\);\n"
    r"        s_waitcnt_vmcnt\(0_I\);\n"
    r"        s_waitcnt_lgkmcnt\(0_I\);\n"
    r"        __builtin_amdgcn_s_barrier\(\);\n"
    r"        __builtin_amdgcn_sched_barrier\(0\);\n"
    r"        __builtin_amdgcn_s_setprio\(1\);\n", "", source)
assert count == 1
source, count = re.subn(r"        const auto u_sa_next_[01] = .*?;\n", "", source)
assert count == 2
source = source.replace("        const int future_tile = (tile + 2) & 63;\n", "")
for matrix in ("a", "b"):
    for half in (0, 1):
        source = source.replace(f"s{matrix}_offset(next_stage, {half})", f"g{matrix}_offset({half}, tile + 1)")
        source = source.replace(f"s{matrix}_offset(stage, {half})", f"g{matrix}_offset({half}, 0)")
source = source.replace("__builtin_amdgcn_sched_group_barrier(0x100,", "__builtin_amdgcn_sched_group_barrier(0x20,")
assert "sa_offset(" not in source and "sb_offset(" not in source
assert source.count("__builtin_amdgcn_s_barrier();") == 1

name = "direct_ab_regroll"
directory = work / name
directory.mkdir(exist_ok=False)
for file in base.iterdir():
    if file.is_file():
        shutil.copy2(file, directory / file.name)
(directory / "tmpl.hpp").write_text(source)
patch_dir = here / "candidate_patches" / name
patch_dir.mkdir(parents=True, exist_ok=False)
(patch_dir / "tmpl.patch").write_text("".join(difflib.unified_diff(
    original.splitlines(True), source.splitlines(True), fromfile="a/tmpl.hpp", tofile="b/tmpl.hpp")))
record = dict(name=name, parent="ab0_resident", config=dict(direct_ab_global=True, expected_lds_bytes=16896),
              source_sha256=hashlib.sha256(source.encode()).hexdigest(), output_tiles_per_wg=1,
              num_waves=4, source_mfma_order_unchanged=True,
              global_matrix_traffic="Each wave loads its own operands; twice the aggregate bytes of shared LDS staging")
(patch_dir / "candidate.json").write_text(json.dumps(record, indent=2) + "\n")
index["candidates"].append(record)
(here / "candidate_index.json").write_text(json.dumps(index, indent=2) + "\n")
print(name)
