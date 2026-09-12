#!/usr/bin/env python3
"""Independently check bitfield permutations and the partial-group fallback."""
import hashlib
import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
WORK = Path((HERE / "work_path.txt").read_text().strip())
shapes = [(m, n) for m in range(1, 66) for n in range(1, 66)]
shapes += [(1, 16383), (16383, 1), (8, 2040), (4, 4095), (64, 255), (128, 127)]
reports = []
for name in sys.argv[1:]:
    cfg = json.loads((WORK / name / "candidate.json").read_text())["config"]
    ns, ms, bits = (cfg[key] for key in ("grid_n_shift", "grid_m_shift", "grid_bits"))
    mask = (1 << bits) - 1
    enabled = fallback = 0
    for m, n in shapes:
        mapping_enabled = m % (1 << (ms + bits)) == n % (1 << (ns + bits)) == 0
        enabled += mapping_enabled
        fallback += not mapping_enabled
        coords = set()
        for y in range(m):
            for x in range(n):
                row, col = y, x
                if mapping_enabled:
                    delta = ((y >> ms) ^ (x >> ns)) & mask
                    row ^= delta << ms
                    col ^= delta << ns
                assert 0 <= row < m and 0 <= col < n, (name, m, n, y, x, row, col)
                assert (row, col) not in coords
                coords.add((row, col))
        assert len(coords) == m * n
    reports.append(dict(name=name, status="PASS", cases=len(shapes), enabled_cases=enabled,
                        fallback_cases=fallback, bijective=True, in_bounds=True,
                        source_sha256=hashlib.sha256((WORK/name/"tmpl_generic.hpp").read_bytes()).hexdigest()))
    print(name, "PASS", len(shapes), "tile grids")
(HERE / "grid_locality_audit.json").write_text(json.dumps(reports, indent=2) + "\n")
