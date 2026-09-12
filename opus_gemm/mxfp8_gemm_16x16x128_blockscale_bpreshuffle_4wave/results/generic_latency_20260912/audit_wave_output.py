#!/usr/bin/env python3
"""Independent native C coordinates versus wave-owned LDS/copy coordinates."""
import hashlib
import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
WORK = Path((HERE / "work_path.txt").read_text().strip())
dest = HERE / "output_mapping"
dest.mkdir(exist_ok=True)
for name in sys.argv[1:]:
    cfg = json.loads((WORK/name/"candidate.json").read_text())["config"]
    tm, tn = cfg["wave_partition"]
    pitch = cfg["output_wave_pitch"]
    em, en = 128 // (tm * 16), 128 // (tn * 16)
    wave_rows, half_rows, half_cols = 256 // tm, 128 // tm, 128 // tn
    alignment = cfg["output_lds_read_alignment"]
    assert tm * tn == 4 and pitch * 2 % alignment == 0
    lds, stores, copies = {}, set(), set()
    for wave in range(4):
        wm, wn = wave % tm, wave // tm
        for hm in range(2):
            for hn in range(2):
                for mr in range(em):
                    for nr in range(en):
                        for lane in range(64):
                            row = hm*128 + mr*tm*16 + wm*16 + lane%16
                            col = hn*128 + nr*tn*16 + wn*16 + lane//16*4
                            lr = hm*half_rows + mr*16 + lane%16
                            lc = hn*half_cols + nr*16 + lane//16*4
                            addr = wave*wave_rows*pitch + lr*pitch + lc
                            assert addr*2 % 8 == 0
                            for j in range(4):
                                assert addr+j not in lds and (row,col+j) not in stores
                                lds[addr+j] = (wave,row,col+j,hm,hn)
                                stores.add((row,col+j))
                for copy in range(8):
                    for lane in range(64):
                        linear = lane*8 + copy*64*8
                        lr,lc = hm*half_rows + linear//half_cols, hn*half_cols + linear%half_cols
                        addr = wave*wave_rows*pitch + lr*pitch + lc
                        row = lr//16*tm*16 + wm*16 + lr%16
                        col = lc//16*tn*16 + wn*16 + lc%16
                        assert addr*2 % alignment == 0 and col*2 % 16 == 0
                        for j in range(8):
                            assert lds[addr+j] == (wave,row,col+j,hm,hn)
                            assert (row,col+j) not in copies
                            copies.add((row,col+j))
    assert copies == stores == {(r,c) for r in range(256) for c in range(256)}
    assert (max(lds)+1)*2 <= 135168
    report = dict(status="PASS",name=name,source_sha256=hashlib.sha256((WORK/name/"tmpl_generic.hpp").read_bytes()).hexdigest(),
                  wave_partition=[tm,tn],elements=65536,exclusive_wave_ownership=True,
                  exact_native_coordinate_coverage=True,read_alignment_bytes=alignment,
                  global_store_alignment_bytes=16,matrix_lds_allocation_bytes=135168,
                  highest_output_lds_byte=(max(lds)+1)*2-1,
                  scope="Native output coordinate coverage, vector alignment, and exclusive per-wave LDS ownership")
    (dest/(name+".json")).write_text(json.dumps(report,indent=2)+"\n")
    print(name,"PASS",flush=True)
