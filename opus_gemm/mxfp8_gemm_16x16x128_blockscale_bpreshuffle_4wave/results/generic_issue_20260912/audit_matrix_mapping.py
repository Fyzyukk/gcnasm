#!/usr/bin/env python3
"""Compare grouped MUBUF addresses with independent A/B matrix coordinates."""
import hashlib
import json
from pathlib import Path

here = Path(__file__).resolve().parent
work = Path((here / "work_path.txt").read_text().strip())
rows = []
for k in [128,256,384,896,1152,8192,8320,32896]:
    for matrix in ["a", "b"]:
        negative_voffsets = 0
        for half in range(2):
            coverage = set()
            for issue in range(16):
                local = issue % 4
                old_immediate = local * 1056 - (32 if local else 0)
                immediate = local * 1056
                for lane in range(64):
                    if matrix == "a":
                        row = half * 128 + issue // 2 * 16 + lane // 8 * 2 + issue % 2
                        column = lane % 8 * 16
                        expected_global = row * k + column
                        expected_lds = (row // 16 * 2 + row % 2) * 1056 + row % 16 // 2 * 128 + column
                        vector_base = (half * 128 + lane // 8 * 2) * k + lane % 8 * 16
                        odd_stride, tile_stride = k, 128
                    else:
                        row = half * 128 + issue // 2 * 16 + lane % 16
                        column = issue % 2 * 64 + lane // 16 * 16
                        # Independently flatten the AITER (16,16) B shuffle.
                        expected_global = row // 16 * 16 * k + column // 64 * 1024 + column % 64 // 16 * 256 + row % 16 * 16
                        expected_lds = (row // 16 * 2 + column // 64) * 1056 + (column % 64 // 16 * 16 + row % 16) * 16
                        vector_base = half * 128 * k + lane * 16
                        odd_stride, tile_stride = 1024, 2048
                    vector_offset = vector_base + issue // 2 * 16 * k + issue % 2 * odd_stride - immediate
                    negative_voffsets += int(vector_offset < 0)
                    # VOFFSET + IOFFSET is a 32-bit vector address component;
                    # the nonnegative scalar K offset is added separately.
                    vector_component = (vector_offset + immediate) & 0xffffffff
                    assert vector_component == expected_global
                    old_vector = vector_base + issue // 2 * 16 * k + issue % 2 * odd_stride - old_immediate
                    assert ((old_vector + old_immediate) & 0xffffffff) == vector_component
                    for tile in [0,1,k//128-1]:
                        if tile >= k//128:
                            continue
                        absolute = vector_component + tile * tile_stride
                        assert 0 <= absolute and absolute + 16 <= 256 * k
                    new_lds = half * 16 * 1056 + issue // 4 * 4 * 1056 + immediate + lane * 16
                    old_lds = half * 16 * 1056 + issue // 4 * 4 * 1056 + (32 if local else 0) + old_immediate + lane * 16
                    assert new_lds == old_lds == expected_lds
                    assert expected_global % 16 == new_lds % 16 == 0
                    for byte in range(16):
                        assert (row,column+byte) not in coverage
                        coverage.add((row,column+byte))
            assert coverage == {(r,c) for r in range(half*128,(half+1)*128) for c in range(128)}
        rows.append(dict(k=k,matrix=matrix,bytes_per_k128=32768,negative_voffsets=negative_voffsets,
                         original_mapping_equal=True,complete_coordinate_coverage=True))

report = dict(status="PASS",scope="CPU address algebra and independent producer-layout coverage; GPU checks validate the emitted MUBUF semantics",
              candidate="m0_group4", source_sha256=hashlib.sha256((work/"m0_group4/tmpl_generic.hpp").read_bytes()).hexdigest(),
              immediate_offsets=[0,1056,2112,3168],m0_adjustments=[0,0,0,0],records=rows)
(here/"matrix_mapping_audit.json").write_text(json.dumps(report,indent=2)+"\n")
print("PASS: A/B source coordinates and padded LDS image preserved; every 16-byte transfer covered.")
