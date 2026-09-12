#!/usr/bin/env python3
"""Reproduce generic latency candidates from frozen f483077 source."""
import difflib
import hashlib
import json
from pathlib import Path
import shutil
import sys

HERE = Path(__file__).resolve().parent
WORK = Path((HERE / "work_path.txt").read_text().strip())
BASE = HERE / "baseline_source"


def replace_n(source, old, new, count=1):
    assert source.count(old) == count, (old, source.count(old), count)
    return source.replace(old, new)


def record(name, source, config, support_changes=None):
    directory = WORK / name
    directory.mkdir(exist_ok=False)
    metadata = json.loads((BASE / "candidate.json").read_text())
    for filename in metadata["source_hashes"]:
        shutil.copy2(BASE / filename, directory / filename)
    (directory / "tmpl_generic.hpp").write_text(source)
    for filename, contents in (support_changes or {}).items():
        (directory / filename).write_text(contents)
    (directory / "build").mkdir()
    for filename in ["host.o", "launch.o"]:
        shutil.copy2(WORK / "baseline/build" / filename, directory / "build" / filename)
    metadata.pop("expected_generic_isa", None)
    metadata.update(name=name, parent="baseline", parent_commit=metadata["parent"])
    metadata["config"].update(config)
    if support_changes:
        metadata["changed_support_files"] = sorted(support_changes)
    metadata["source_hashes"] = {f: hashlib.sha256((directory/f).read_bytes()).hexdigest()
                                 for f in metadata["source_hashes"]}
    (directory / "candidate.json").write_text(json.dumps(metadata, indent=2) + "\n")
    dest = HERE / "candidate_patches" / name
    dest.mkdir(parents=True, exist_ok=False)
    (dest / "candidate.json").write_text(json.dumps(metadata, indent=2) + "\n")
    patch = ""
    for filename in ["tmpl_generic.hpp", *sorted(support_changes or {})]:
        original = (BASE / filename).read_text()
        final = (directory / filename).read_text()
        patch += "".join(difflib.unified_diff(original.splitlines(True), final.splitlines(True),
                                             fromfile="a/"+filename, tofile="b/"+filename))
    (dest / "change.patch").write_text(patch)
    print(name, metadata["source_hashes"]["tmpl_generic.hpp"], flush=True)


def resident_operands(source):
    prefix, tail = source.split("    // Consume the final resident tile", 1)
    tail = replace_n(tail, "    v_a[1] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 1));\n", "")
    tail = replace_n(tail, "    v_sfb[1] = load_sfb_dword(loops - 1, 1);\n", "")
    tail = replace_n(tail, """    if constexpr (T::OUTPUT_BF16) {
        // Final B1 is resident from the operand seed or the penultimate block.
        v_b = v_b_second;
    } else {
        v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 1));
    }
""", "    v_b = v_b_second;\n")
    return prefix + "    // Consume the final resident tile" + tail


def initial_k1_block(source):
    start = source.index("    // A single K128 block has no K1 producer.\n")
    end = source.index("    // Seed all four matrix halves", start)
    return source[start:end]


def move_k1(source, location):
    block = initial_k1_block(source)
    source = replace_n(source, block, "")
    if location == "before_transpose":
        marker = "    // B matrix requests can progress while the scale transpose publishes.\n"
        return replace_n(source, marker, block + marker)
    if location == "after_seed":
        marker = "    // Prefetch while two later K128 blocks exist; peel the penultimate block.\n"
        return replace_n(source, marker, block + marker)
    raise ValueError(location)


def interleave_initial_scales(source):
    source = replace_n(source, initial_k1_block(source), "")
    source = replace_n(source, "    auto publish_sfa_panel = [&]() {", "    auto publish_sfa_panel = [&](auto preload_k1) {")
    marker = """                store<4>(s_sfa, __builtin_bit_cast(opus::vector_t<D_SF, 4>, packed), dst);
"""
    source = replace_n(source, marker, marker + """                if constexpr (decltype(preload_k1)::value) {
                    prefetch_matrix_issue(opus::number<pass * 4 + word>{}, 1, 1);
                    __builtin_amdgcn_sched_barrier(0);
                }
""")
    source = replace_n(source, "            publish_sfa_panel();", "            publish_sfa_panel(opus::number<0>{});")
    source = replace_n(source, "    publish_sfa_panel();", """    // Fill the disjoint K1 matrix stage while compact scales transpose.
    if (loops > 1) publish_sfa_panel(opus::number<1>{});
    else publish_sfa_panel(opus::number<0>{});""")
    return source


def grouped_grid(source, group):
    old = """    const int block_m = block_id_y();
    const int block_n = block_id_x();
"""
    new = f"""    int block_m = block_id_y();
    int block_n = block_id_x();
    // Transpose low tile-coordinate bits only for complete square groups.
    // Other legal shapes retain the original direct two-dimensional mapping.
    if (((kargs.m | kargs.n) & {group * 256 - 1}) == 0) {{
        const int old_m = block_m;
        block_m = (block_m & ~{group - 1}) | (block_n & {group - 1});
        block_n = (block_n & ~{group - 1}) | (old_m & {group - 1});
    }}
"""
    return replace_n(source, old, new)


def main():
    source = (BASE / "tmpl_generic.hpp").read_text()
    for name in sys.argv[1:]:
        if name in ["unroll1", "unroll2"]:
            count = int(name.removeprefix("unroll"))
            record(name, replace_n(source, "#pragma unroll 4", f"#pragma unroll {count}"), dict(unroll=count))
        elif name == "final_resident":
            record(name, resident_operands(source), dict(final_operands_resident=True))
        elif name in ["k1_before_transpose", "k1_after_seed"]:
            record(name, move_k1(source, name.removeprefix("k1_")), dict(initial_k1_position=name))
        elif name == "k1_interleave_scales":
            record(name, interleave_initial_scales(source), dict(initial_k1_position=name))
        elif name in ["grid_group2", "grid_group4", "grid_group8"]:
            group = int(name.removeprefix("grid_group"))
            record(name, grouped_grid(source, group), dict(grid_order="transpose_low_bits", grid_group=group))
        elif name in ["output_cache0", "output_cache3"]:
            policy = int(name.removeprefix("output_cache"))
            prefix, tail = source.split("    // Consume the final resident tile", 1)
            tail = replace_n(tail, "opus::number<2>{}", f"opus::number<{policy}>{{}}", 2)
            record(name, prefix + "    // Consume the final resident tile" + tail, dict(output_cache_policy=policy))
        else:
            raise ValueError(name)


if __name__ == "__main__":
    main()
