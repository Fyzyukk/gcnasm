#!/usr/bin/env python3
"""Prove wave-owned output reads cover the original native MFMA coordinates."""
import hashlib
import json
from pathlib import Path
import sys

here = Path(__file__).resolve().parent
work = Path((here / "work_path.txt").read_text().strip())
dest = here / "output_mapping"
dest.mkdir(exist_ok=True)
for name in sys.argv[1:]:
    metadata = json.loads((work/name/"candidate.json").read_text())
    config = metadata["config"]
    pitch = config["output_wave_pitch"]
    alignment = config.get("output_lds_read_alignment",16)
    swizzle = "output_column_xor" in config
    assert pitch * 2 % alignment == 0, (name,"unaligned vector row",pitch,alignment)
    lds, stores = {}, set()
    for wave in range(4):
        wm, wn = wave % 2, wave // 2
        for hm in range(2):
            for hn in range(2):
                for fragment in range(16):
                    mr, nr = fragment // 4, fragment % 4
                    for lane in range(64):
                        # Original native MFMA C coordinates, independent of the new copy mapping.
                        row = hm * 128 + mr * 32 + wm * 16 + lane % 16
                        col = hn * 128 + nr * 32 + wn * 16 + lane // 16 * 4
                        lr = hm * 64 + mr * 16 + lane % 16
                        lc = hn * 64 + nr * 16 + lane // 16 * 4
                        physical_col = lc ^ ((lr & 7) * 8) if swizzle else lc
                        address = wave * 128 * pitch + lr * pitch + physical_col
                        assert address * 2 % 8 == 0
                        for j in range(4):
                            assert address+j not in lds and (row,col+j) not in stores
                            lds[address+j] = (wave,row,col+j,hm,hn)
                            stores.add((row,col+j))
    assert stores == {(r,c) for r in range(256) for c in range(256)}
    copies = set()
    for wave in range(4):
        for hm in range(2):
            for hn in range(2):
                for copy in range(8):
                    for lane in range(64):
                        linear = lane * 8 + copy * 64 * 8
                        lr, lc = hm * 64 + linear // 64, hn * 64 + linear % 64
                        physical_col = lc ^ ((lr & 7) * 8) if swizzle else lc
                        address = wave * 128 * pitch + lr * pitch + physical_col
                        row = lr // 16 * 32 + wave % 2 * 16 + lr % 16
                        col = lc // 16 * 32 + wave // 2 * 16 + lc % 16
                        assert address * 2 % alignment == 0
                        assert col * 2 % 16 == 0
                        for j in range(8):
                            assert lds[address+j] == (wave,row,col+j,hm,hn)
                            assert (row,col+j) not in copies
                            copies.add((row,col+j))
    assert copies == stores
    assert (max(lds)+1)*2 <= 135168
    report = dict(status="PASS",name=name,source_sha256=hashlib.sha256((work/name/"tmpl_generic.hpp").read_bytes()).hexdigest(),
                  elements=65536,exclusive_wave_ownership=True,exact_native_coordinate_coverage=True,
                  read_alignment_bytes=alignment,global_store_alignment_bytes=16,
                  matrix_lds_allocation_bytes=135168,highest_output_lds_byte=(max(lds)+1)*2-1,
                  scope="CPU proof of native output coordinates, alignment, and no cross-wave or cross-quadrant LDS reader")
    (dest/(name+".json")).write_text(json.dumps(report,indent=2)+"\n")
    print(name,"PASS",flush=True)
