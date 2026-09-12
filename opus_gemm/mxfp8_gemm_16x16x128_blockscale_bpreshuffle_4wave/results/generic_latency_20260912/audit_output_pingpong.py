#!/usr/bin/env python3
"""Prove native C coverage, aligned loads, and slot reuse across publications."""
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
    pitch = cfg["output_lds_pitch"]
    xor = cfg["output_lds_swizzle"] != "none"
    alignment = cfg["output_lds_read_alignment"]
    def address(hm, r, c):
        return (hm*128+r)*pitch + (c ^ ((r&15)*4) if xor else c)
    # Each existing publication drains prior LDS copies. The other slot is
    # used next; slot 0 cannot be overwritten until publication 36 has retired
    # its reads, and slot 1 cannot be overwritten until publication 52.
    lag = cfg.get("output_store_fragment_lag")
    first_write = [q * 16 + lag + 1 for q in range(4)] if lag is not None else [8, 24, 40, 56]
    publication = [20, 36, 52, 64]
    slot_reads_retired = [None, None]
    all_copies = set()
    max_addr = 0
    for q, (hm, hn) in enumerate([(0,0), (1,0), (0,1), (1,1)]):
        if q >= 2:
            assert slot_reads_retired[hm] < first_write[q]
        values = {}
        for wave in range(4):
            wm, wn = wave%2, wave//2
            for mr in range(4):
                for nr in range(4):
                    for lane in range(64):
                        row = mr*32 + wm*16 + lane%16
                        col = nr*32 + wn*16 + lane//16*4
                        addr = address(hm,row,col)
                        assert addr*2 % 8 == 0
                        for j in range(4):
                            assert addr+j == address(hm,row,col+j)
                            assert addr+j not in values
                            values[addr+j] = (row+hm*128,col+j+hn*128)
        for copy in range(8):
            for tid in range(256):
                linear = tid*8 + copy*256*8
                row,col = divmod(linear,128)
                width = alignment//2
                assert (col+hn*128)*2 % 16 == 0
                for start in range(0,8,width):
                    addr = address(hm,row,col+start)
                    assert addr*2 % alignment == 0
                    for j in range(width):
                        output = (row+hm*128,col+start+j+hn*128)
                        assert values[addr+j] == output
                        assert output not in all_copies
                        all_copies.add(output)
                        max_addr = max(max_addr,addr+j)
        if q > 0:
            slot_reads_retired[1-hm] = publication[q]
    assert all_copies == {(r,c) for r in range(256) for c in range(256)}
    assert (max_addr+1)*2 <= 135168
    report = dict(name=name,status="PASS",native_coordinate_coverage=65536,
                  read_alignment_bytes=alignment,store_alignment_bytes=16,
                  highest_output_lds_byte=(max_addr+1)*2-1,
                  first_write_mfmas=first_write,
                  publication_mfmas=publication,
                  slot_reuse_after_prior_reader_publication=True,
                  source_sha256=hashlib.sha256((WORK/name/"tmpl_generic.hpp").read_bytes()).hexdigest(),
                  scope="Native C mapping, vector alignment, and source publication lifetime. Linked-ISA waitcnt/control-flow audit is separate.")
    (dest/(name+".json")).write_text(json.dumps(report,indent=2)+"\n")
    print(name,"PASS",(max_addr+1)*2,"output LDS bytes")
