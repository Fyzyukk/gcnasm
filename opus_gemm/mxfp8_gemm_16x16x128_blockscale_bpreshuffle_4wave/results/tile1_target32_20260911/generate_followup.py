#!/usr/bin/env python3
"""Trace-guided tile1 candidates relative to the frozen regroll_release8."""
import difflib
import hashlib
import json
from pathlib import Path
import re
import shutil

here = Path(__file__).resolve().parent
work = Path((here / "work_path.txt").read_text().strip())
baseline = work / "baseline"
original = (baseline / "tmpl.hpp").read_text()
index = json.loads((here / "candidate_index.json").read_text())
assert hashlib.sha256(original.encode()).hexdigest() == index["baseline_tmpl_sha256"]

def a0_per_m(source):
    assert source.count("if constexpr (!T::OUTPUT_BF16)") == 3
    source = source.replace("if constexpr (!T::OUTPUT_BF16)", "if constexpr (true)")
    pattern = re.compile(r"        if constexpr \(T::OUTPUT_BF16\) \{\n"
                         r"            // BF16 retains the full A0 roll;.*?"
                         r"        \} else \{\n(.*?)        \}\n", re.S)
    source, count = pattern.subn(lambda m: m[1], source)
    assert count == 1
    return source

def b0_spread(source):
    marker = "        // All LDS reads here are compiler-visible intrinsics."
    source = source.replace(marker,
        "        const auto rb0_next_offsets =\n"
        "            opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 0));\n\n" + marker, 1)
    old = "        v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(next_stage, 0));\n"
    assert source.count(old) == 1
    source = source.replace(old, "", 1)
    for group, acc in enumerate(("c10_14, c10_15", "c01_0, c01_1", "c01_2, c01_3", "c01_5")):
        start = source.index(acc, source.index("#pragma unroll 4"))
        end = source.index(";\n", source.index(";\n", start) + 2) + 2
        insertion = (f"        // Spread the dead B0 operand reads after MFMA{32 + 2 * group}.\n"
                     f"        load_b_range_scale<T, {2 * group}, {2 * group + 2}>(s_b, rb0_next_offsets, v_b);\n"
                     "        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);\n"
                     "        __builtin_amdgcn_sched_barrier(0);\n")
        source = source[:end] + insertion + source[end:]
    return source

def resident_epilogue(source):
    start = source.index("    // Consume the final resident tile with")
    prefix, epilogue = source[:start], source[start:]
    epilogue = epilogue.replace(
        "    // Consume the final resident tile with the original direct-store\n"
        "    // epilogue. Retain its conservative A1 and B1 reloads.\n"
        "    v_a[1] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 1));\n\n"
        "    s_waitcnt_lgkmcnt(0_I);\n"
        "    v_sfb[1] = load_sfb_dword(loops - 1, 1);\n",
        "    // The final A1/B1 operands and scale words were rolled by the K loop.\n"
        "    // Keep their register values; compiler-visible reads retain operand waits.\n", 1)
    old = "    v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 1));"
    assert epilogue.count(old) == 1
    epilogue = epilogue.replace(old, "    v_b = v_b_second;", 1)
    return prefix + epilogue

def early_stores(source):
    start = source.index("    // The final A1/B1 operands")
    prefix, epilogue = source[:start], source[start:]
    for name, half_m, half_n in (("c00", 0, 0), ("c01", 0, 1)):
        call = f"    MXFP8_STORE_QUADRANT({name}, {half_m}, {half_n});\n"
        assert epilogue.count(call) == 1
        epilogue = epilogue.replace(call, "", 1)
        marker = f"{name}_14, {name}_15, v_sfa, v_sfb[{half_n}]);\n    sched_barrier_pairs_scale();\n"
        assert epilogue.count(marker) == 1
        epilogue = epilogue.replace(marker, marker + "\n" + call, 1)
    return prefix + epilogue

def relaxed_rolls(source):
    start = source.index("        // A1 M-repeat 0 has no further current-tile consumers.")
    end = source.index("        __builtin_amdgcn_s_setprio(0);", start)
    tail = source[start:end]
    tail, count = re.subn(r"        __builtin_amdgcn_sched_(?:group_)?barrier\([^;]*\);\n", "", tail)
    assert count == 18
    return source[:start] + tail + source[end:]

configs = {
    "a0_per_m": (a0_per_m(original), "BF16 A0 reads after its M-repeat last use at 36/40/44/48"),
    "b0_spread": (b0_spread(original), "B0 reads spread in pairs after MFMA32/34/36/38"),
    "ab0_spread": (b0_spread(a0_per_m(original)), "Combine A0 per-M roll and B0 spread"),
    "epilogue_resident": (resident_epilogue(original), "Reuse final resident A1/B1/scales; remove redundant reloads"),
    "early_store_resident": (early_stores(resident_epilogue(original)), "Reuse resident operands and store C00/C01 earlier"),
    "roll_relaxed": (relaxed_rolls(original), "Let LLVM interleave A1/B1 roll reads without extra scheduling fences"),
}
for name, (candidate, reason) in configs.items():
    directory = work / name
    directory.mkdir(exist_ok=False)
    for file in baseline.iterdir():
        if file.is_file():
            shutil.copy2(file, directory / file.name)
    (directory / "tmpl.hpp").write_text(candidate)
    patch_dir = here / "candidate_patches" / name
    patch_dir.mkdir(parents=True, exist_ok=False)
    (patch_dir / "tmpl.patch").write_text("".join(difflib.unified_diff(
        original.splitlines(True), candidate.splitlines(True), fromfile="a/tmpl.hpp", tofile="b/tmpl.hpp")))
    record = dict(name=name, config=dict(reason=reason), source_sha256=hashlib.sha256(candidate.encode()).hexdigest(),
                  output_tiles_per_wg=1, num_waves=4, source_mfma_order_unchanged=True)
    (patch_dir / "candidate.json").write_text(json.dumps(record, indent=2) + "\n")
    index["candidates"].append(record)
    print(name, reason)
(here / "candidate_index.json").write_text(json.dumps(index, indent=2) + "\n")
