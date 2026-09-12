#!/usr/bin/env python3
"""Reuse the validated common matrix producer for K0/K1 and scalar addresses."""
import difflib
import hashlib
import json
from pathlib import Path
import shutil

here = Path(__file__).resolve().parent
work = Path((here / "work_path.txt").read_text().strip())
base = here / "baseline_source"
original = (base / "tmpl.hpp").read_text()
index = json.loads((here / "candidate_index.json").read_text())


def unified(k0, k1):
    source = original
    for tile, selected in [(0, k0), (1, k1)]:
        if not selected:
            continue
        for matrix, start in [("a", 0), ("b", 8)]:
            old = "".join(f"    async_load<T::VEC_{matrix.upper()}>(g_{matrix}, s_{matrix}.ptr, u_g{matrix}, u_s{matrix} + s{matrix}_offset({tile}, {half}), g{matrix}_offset({half}, {tile}));\n" for half in range(2))
            assert source.count(old) == 1
            new = f"""    // The main-loop producer mapping also covers this initial matrix stage.
    opus::static_for<8>([&](auto initial_issue) {{
        using Issue = opus::number<decltype(initial_issue)::value + {start}>;
        prefetch_matrix_issue(Issue{{}}, {tile}, {tile});
    }});
"""
            source = source.replace(old, new)
    return source


def early_offset():
    source = original.replace("matrix_addresses[issue], k_tile * matrix_k_stride,", "matrix_addresses[issue], k_tile,")
    marker = "        const int future_tile = (tile + 2) & 63;"
    assert source.count(marker) == 1
    source = source.replace(marker, marker + "\n        int future_byte_offset = future_tile * matrix_k_stride;\n        asm volatile(\"\" : \"+s\"(future_byte_offset));")
    assert source.count("{}, stage, future_tile);") == 16
    return source.replace("{}, stage, future_tile);", "{}, stage, future_byte_offset);")


configs = {
    "unified_prologue": (unified(True, True), {"unified_initial_matrix_stages": [0, 1]}),
    "unified_k0": (unified(True, False), {"unified_initial_matrix_stages": [0]}),
    "unified_k1": (unified(False, True), {"unified_initial_matrix_stages": [1]}),
    "early_scalar_offset": (early_offset(), {"matrix_byte_offset_materialized_before_mfma": True}),
    "matrix_shift": (original.replace("const int matrix_k_stride = produces_a ? T::B_K : T::B_K * 16;", "const int matrix_k_shift = produces_a ? 7 : 11;").replace("k_tile * matrix_k_stride", "k_tile << matrix_k_shift"), {"matrix_offset_uses_shift": True}),
}

for name, (source, config) in configs.items():
    assert source != original
    target = work / name
    shutil.copytree(base, target)
    (target / "tmpl.hpp").write_text(source)
    patches = here / "candidate_patches" / name
    patches.mkdir(parents=True)
    (patches / "tmpl.patch").write_text("".join(difflib.unified_diff(original.splitlines(True), source.splitlines(True), fromfile="a/tmpl.hpp", tofile="b/tmpl.hpp")))
    record = dict(name=name, config=config, source_sha256=hashlib.sha256(source.encode()).hexdigest(),
                  num_waves=4, output_tiles_per_wg=1, per_accumulator_k_order_unchanged=True)
    (patches / "candidate.json").write_text(json.dumps(record, indent=2)+"\n")
    (target / "candidate.json").write_text(json.dumps(record, indent=2)+"\n")
    index["candidates"].append(record)
    print(name, config)
(here / "candidate_index.json").write_text(json.dumps(index, indent=2)+"\n")
