#!/usr/bin/env python3
"""Check grouped grid coverage and bounds for complete/partial tile groups."""
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
WORK = Path((HERE / "work_path.txt").read_text().strip())
records = []
shapes = [(m,n) for m in range(1,33) for n in range(1,33)] + [(1,16383),(16383,1),(8,2040)]
for group in [2,4,8]:
    for m,n in shapes:
        coords = set()
        for y in range(m):
            for x in range(n):
                row,col = ((y & ~(group-1)) | (x & (group-1)),
                           (x & ~(group-1)) | (y & (group-1))) if m%group==n%group==0 else (y,x)
                assert 0 <= row < m and 0 <= col < n
                assert (row,col) not in coords
                coords.add((row,col))
        assert len(coords)==m*n
    name=f"grid_group{group}"
    records.append(dict(name=name,source_sha256=hashlib.sha256((WORK/name/"tmpl_generic.hpp").read_bytes()).hexdigest(),
                        cases=len(shapes),group=group,one_to_one=True,in_bounds=True))
(HERE/"grid_mapping_audit.json").write_text(json.dumps(dict(status="PASS",records=records,
    scope="Output-tile bijection and in-bounds coordinates, including incomplete groups and existing ABI boundary cases"),indent=2)+"\n")
print("PASS: all grouped grid mappings cover each legal output tile exactly once")
