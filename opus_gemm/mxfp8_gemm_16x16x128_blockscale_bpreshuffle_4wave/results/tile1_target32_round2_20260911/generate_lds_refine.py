#!/usr/bin/env python3
"""Reduce address arithmetic and lane shuffles in the coalesced output path."""
import difflib
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

here = Path(__file__).resolve().parent
work = Path((here / "work_path.txt").read_text().strip())
base = here / "baseline_source"
original = (base / "tmpl.hpp").read_text()
parent = (work / "bf16_lds_epilogue_aux2/tmpl.hpp").read_text()
index = json.loads((here / "candidate_index.json").read_text())
index["intermediate_target_bf16_pflops"] = 3.2
index["target_bf16_pflops"] = 3.5


def scalar_copy(source):
    start = source.index("        opus::static_for<T::B_M * T::B_N / (T::BLOCK_SIZE * 8)>")
    end = source.index("        });", start) + len("        });")
    code = """        const int copy_row = thread_id_x() / (T::B_N / 8);
        const int copy_col = (thread_id_x() % (T::B_N / 8)) * 8;
        int copy_global_base = copy_row * kargs.stride_c + copy_col;
        int copy_lds_base = copy_row * c_lds_pitch + copy_col;
        asm volatile("" : "+v"(copy_global_base), "+v"(copy_lds_base));
        opus::static_for<T::B_M * T::B_N / (T::BLOCK_SIZE * 8)>([&](auto copy_i) {
            constexpr int row_delta = decltype(copy_i)::value * T::BLOCK_SIZE * 8 / T::B_N;
            const auto value = s_c.template load<8>(copy_lds_base + row_delta * c_lds_pitch);
            g_c.template store<8>(value, copy_global_base, row_delta * kargs.stride_c,
                                  opus::number<2>{});
        });"""
    return source[:start] + code + source[end:]


def vec4(source):
    old = "mma, opus::make_tuple(kargs.stride_c, 1_I), p_coord_c);"
    assert source.count(old) == 1
    source = source.replace(old, "mma, opus::make_tuple(T::OUTPUT_BF16 ? c_lds_pitch : kargs.stride_c, 1_I), p_coord_c);")
    old = """            g_c.template store<T::VEC_C>(cast<D_C>(ACC),                         \\
                gc_offsets[INDEX], soff, opus::number<0>{});                     \\"""
    new = """            s_c.template store<T::VEC_C>(cast<D_C>(ACC),                         \\
                gc_offsets[INDEX] + soff);                                     \\"""
    assert source.count(old) == 1
    source = source.replace(old, new)
    start = source.index("#define MXFP8_STORE_QUADRANT(")
    end = source.index("    MXFP8_MMA_PAIR(0, 0, 0, v_a[0], v_b, c00_0", start)
    lines = ["#define MXFP8_STORE_QUADRANT(PREFIX, HALF_M, HALF_N)",
             "    do {", "        const int soff = c_offset(HALF_M, HALF_N);"]
    lines += [f"        MXFP8_STORE_AGPR_FRAGMENT(PREFIX##_{i}, {i});" for i in range(16)]
    macro = " \\\n".join(lines) + " \\\n    } while (false)\n\n"
    return source[:start] + macro + source[end:]


def combine(source, names):
    with tempfile.TemporaryDirectory(prefix="mxfp8_combine_lds_") as tmp:
        path = Path(tmp)
        (path / "tmpl.hpp").write_text(source)
        for name in names:
            subprocess.run(["patch", "--batch", "-p1", "-i", str(here / "candidate_patches" / name / "tmpl.patch")],
                           cwd=path, check=True, capture_output=True)
        return (path / "tmpl.hpp").read_text()


configs = {
    "lds_copy_scalar": (scalar_copy(parent), {"scalar_copy_offsets": True}),
    "lds_vec4": (vec4(parent), {"lds_fragment_elements": 4}),
    "lds_vec4_copy_scalar": (scalar_copy(vec4(parent)), {"lds_fragment_elements": 4, "scalar_copy_offsets": True}),
    "lds_release5_k1": (combine(parent, ["release5_single", "unified_k1"]), {"release_mfma": 5, "unified_initial_matrix_stages": [1]}),
}
for name, (source, config) in configs.items():
    target = work / name
    shutil.copytree(base, target)
    (target / "tmpl.hpp").write_text(source)
    patches = here / "candidate_patches" / name
    patches.mkdir(parents=True)
    (patches / "tmpl.patch").write_text("".join(difflib.unified_diff(original.splitlines(True), source.splitlines(True), fromfile="a/tmpl.hpp", tofile="b/tmpl.hpp")))
    record = dict(name=name, parent="bf16_lds_epilogue_aux2", config=dict(bf16_lds_epilogue=True, bf16_store_aux=2, c_lds_pitch=264, **config),
                  source_sha256=hashlib.sha256(source.encode()).hexdigest(), num_waves=4,
                  output_tiles_per_wg=1, per_accumulator_k_order_unchanged=True)
    (patches / "candidate.json").write_text(json.dumps(record, indent=2)+"\n")
    (target / "candidate.json").write_text(json.dumps(record, indent=2)+"\n")
    index["candidates"].append(record)
    print(name, config)
(here / "candidate_index.json").write_text(json.dumps(index, indent=2)+"\n")
