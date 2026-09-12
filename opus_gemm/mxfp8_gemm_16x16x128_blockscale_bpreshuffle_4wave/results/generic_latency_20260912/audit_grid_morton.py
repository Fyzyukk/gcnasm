#!/usr/bin/env python3
"""Prove local Morton tile permutations and complete-group translation."""
import hashlib
import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
WORK = Path((HERE / "work_path.txt").read_text().strip())
DEST = HERE / "grid_mapping"
DEST.mkdir(exist_ok=True)

for name in sys.argv[1:]:
    directory = WORK / name
    source = (directory / "tmpl_generic.hpp").read_text()
    cfg = json.loads((directory / "candidate.json").read_text())["config"]
    group, first = cfg["grid_group"], cfg["grid_low_bit_first"]
    bits = group.bit_length() - 1
    assert group == 1 << bits and first in ("m", "n")
    assert f"((kargs.m | kargs.n) & {group * 256 - 1}) == 0" in source
    expressions = {}
    for axis in ["m", "n"]:
        expressions[axis] = source.split(f"        block_{axis} = ", 1)[1].split(";", 1)[0]

    def source_coordinate(y, x):
        return tuple(eval(expressions[axis], {"__builtins__": {}}, {"old_m": y, "old_n": x}) for axis in ["m", "n"])

    def inverse(y, x):
        # Independently interleave the target coordinate bits to recover the
        # original local row-major workgroup index.
        a, b = (y, x) if first == "m" else (x, y)
        linear = sum(((a >> i) & 1) << (2 * i) | ((b >> i) & 1) << (2 * i + 1) for i in range(bits))
        return linear // group, linear % group

    cells = set()
    for y in range(group):
        for x in range(group):
            row, col = source_coordinate(y, x)
            assert 0 <= row < group and 0 <= col < group
            assert (row, col) not in cells and inverse(row, col) == (y, x)
            cells.add((row, col))
            # High coordinate bits are independent group translations.
            for gy, gx in [(1, 0), (0, 1), (3, 7), (255, 511)]:
                assert source_coordinate(gy * group + y, gx * group + x) == (gy * group + row, gx * group + col)
    assert len(cells) == group * group
    sizes = sorted({1, 2, group - 1, group, group + 1, group * 2 - 1, group * 2, group * 2 + 1, 32, 33, 65})
    enabled = fallback = 0
    for m in sizes:
        for n in sizes:
            use = m % group == n % group == 0
            enabled += use
            fallback += not use
            coords = set()
            for y in range(m):
                for x in range(n):
                    row, col = source_coordinate(y, x) if use else (y, x)
                    assert 0 <= row < m and 0 <= col < n
                    assert (row, col) not in coords
                    coords.add((row, col))
            assert len(coords) == m * n
    report = dict(name=name, status="PASS", bijective=True, in_bounds=True,
                  local_cells_proved=len(cells), high_bits_translate_complete_groups=True,
                  enabled_grid_cases=enabled, identity_fallback_cases=fallback,
                  source_sha256=hashlib.sha256(source.encode()).hexdigest(),
                  scope="Exact generated coordinate expressions, independent inverse bit interleave and partial-grid identity fallback; each WG remains tile1.")
    (DEST / (name + ".json")).write_text(json.dumps(report, indent=2) + "\n")
    print(name, "PASS", len(cells), "local cells;", enabled + fallback, "tile grids")
