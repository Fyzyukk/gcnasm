#!/usr/bin/env python3
"""Prove unchanged matrix producer images, scale packs, and contiguous C ownership."""
import hashlib
import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
WORK = Path((HERE / "work_path.txt").read_text().strip())
DEST = HERE / "wave_mapping"
DEST.mkdir(exist_ok=True)
PITCH, HALF = 1056, 16896

for name in sys.argv[1:]:
    directory = WORK / name
    source = (directory / "tmpl_generic.hpp").read_text()
    cfg = json.loads((directory / "candidate.json").read_text())["config"]
    assert cfg["wave_quarter_coordinates"] == "contiguous"
    assert cfg["matrix_producers"] == "unchanged" and cfg["sfa_repeat_rows"] == 16
    for literal in ["wave_id_m * 8 * pitch", "wave_id_n * 8 * pitch",
                    "(owner_wave % T::T_M) * 64 + call * T::W_M"]:
        assert literal in source
    producer_a, producer_b = {}, {}
    for stage in range(2):
        for half in range(2):
            for issue in range(16):
                for lane in range(64):
                    address = (stage * 2 + half) * HALF + issue * PITCH + lane * 16
                    arow = half * 128 + issue // 2 * 16 + lane // 8 * 2 + issue % 2
                    ak = lane % 8 * 16
                    bcol = half * 128 + issue // 2 * 16 + lane % 16
                    bk = issue % 2 * 64 + lane // 16 * 16
                    for byte in range(16):
                        assert address + byte not in producer_a
                        producer_a[address + byte] = (stage, arow, ak + byte)
                        producer_b[address + byte] = (stage, bcol, bk + byte)
    assert len(producer_a) == len(producer_b) == 65536
    read_a, read_b = set(), set()
    for stage in range(2):
        for half in range(2):
            for wave_coord in range(2):
                for repeat in range(4):
                    for lane in range(64):
                        coord = half * 128 + wave_coord * 64 + repeat * 16 + lane % 16
                        for piece in range(2):
                            kval = lane // 16 * 16 + piece * 64
                            aaddress = ((stage * 2 + half) * HALF + (wave_coord * 8 + repeat * 2 + lane % 2) * PITCH
                                        + (lane % 16 // 2) * 128 + lane // 16 * 16 + piece * 64)
                            baddress = ((stage * 2 + half) * HALF + (wave_coord * 8 + repeat * 2 + piece) * PITCH
                                        + lane * 16)
                            assert aaddress % 16 == baddress % 16 == 0
                            for byte in range(16):
                                expected = (stage, coord, kval + byte)
                                assert producer_a[aaddress + byte] == expected
                                assert producer_b[baddress + byte] == expected
                                assert expected not in read_a and expected not in read_b
                                read_a.add(expected)
                                read_b.add(expected)
    assert len(read_a) == len(read_b) == 65536
    # The existing 4x4 register transpose packs all four 16-row-spaced source
    # groups for one native lane row. Validate the new source-group order.
    scales = {}
    for owner in range(4):
        half, wm = divmod(owner, 2)
        for native_row in range(16):
            address = (wm * 16 + native_row) * 8 + half * 4
            for repeat in range(4):
                logical_row = half * 128 + wm * 64 + repeat * 16 + native_row
                assert address + repeat not in scales
                scales[address + repeat] = logical_row
    assert set(scales.values()) == set(range(256))
    for half in range(2):
        for wm in range(2):
            for row in range(16):
                for repeat in range(4):
                    address = (wm * 16 + row) * 8 + half * 4 + repeat
                    assert scales[address] == half * 128 + wm * 64 + row + repeat * 16

    private = cfg.get("output_lds_scope") == "wave_private"
    cpitch = cfg["output_wave_pitch"] if private else 264
    alignment = cfg["output_lds_read_alignment"] if private else 16
    copies = set()
    highest = 0
    for q, (hm, hn) in enumerate([(0, 0), (1, 0), (0, 1), (1, 1)]):
        storage = {}
        for wave in range(4):
            wm, wn = wave % 2, wave // 2
            for mr in range(4):
                for nr in range(4):
                    for lane in range(64):
                        lr, lc = mr * 16 + lane % 16, nr * 16 + lane // 16 * 4
                        row, col = hm * 128 + wm * 64 + lr, hn * 128 + wn * 64 + lc
                        address = ((wave * 128 + hm * 64 + lr) * cpitch + lc
                                   if private else row * cpitch + col)
                        assert address * 2 % 8 == 0
                        for byte in range(4):
                            assert address + byte not in storage
                            storage[address + byte] = (row, col + byte, wave)
        for wave in range(4):
            wm, wn = wave % 2, wave // 2
            for lane in range(64):
                for copy in range(8):
                    if private:
                        lr, lc = divmod(lane * 8 + copy * 64 * 8, 64)
                        address = (wave * 128 + hm * 64 + lr) * cpitch + lc
                        row, col = hm * 128 + wm * 64 + lr, hn * 128 + wn * 64 + lc
                        assert wave * 128 * cpitch <= address < address + 7 < (wave + 1) * 128 * cpitch
                    else:
                        lr, lc = divmod((wave * 64 + lane) * 8 + copy * 256 * 8, 128)
                        row, col = hm * 128 + lr, hn * 128 + lc
                        address = row * cpitch + col
                    assert col * 2 % 16 == 0
                    for part in range(0, 8, alignment // 2):
                        assert (address + part) * 2 % alignment == 0
                    for byte in range(8):
                        value = storage[address + byte]
                        assert value[:2] == (row, col + byte)
                        if private:
                            assert value[2] == wave
                        assert value[:2] not in copies
                        copies.add(value[:2])
                        highest = max(highest, (address + byte) * 2 + 1)
    assert copies == {(row, col) for row in range(256) for col in range(256)}
    assert highest < 135168
    if private:
        # Reuse follows a same-wave LDS drain at publication 36/52. There are
        # no inter-wave C dependencies; the initial matrix drain remains WG-wide.
        assert 36 < 40 and 52 < 56
        tail = source[source.index("    MXFP8_MMA_PAIR", source.index("#define MXFP8_STORE_QUADRANT")):]
        assert "__builtin_amdgcn_s_barrier();" not in tail
        assert tail.count("s_waitcnt_lgkmcnt(0_I);") == 4
    report = dict(name=name, status="PASS", a_consumer_bytes=len(read_a), b_consumer_bytes=len(read_b),
                  matrix_stages=2, compact_sfa_rows=len(scales), native_c_elements=len(copies),
                  exclusive_wave_ownership=private, slot_reuse_after_reader_retirement=private,
                  highest_output_lds_byte=highest, read_alignment_bytes=alignment,
                  global_store_alignment_bytes=16, source_sha256=hashlib.sha256(source.encode()).hexdigest(),
                  scope="Independent producer/consumer coordinates, SFA pack order, all native C elements and output copy vectors; linked waits and runtime checks are separate.")
    (DEST / (name + ".json")).write_text(json.dumps(report, indent=2) + "\n")
    if private:
        (HERE / "output_mapping" / (name + ".json")).write_text(json.dumps(report, indent=2) + "\n")
    print(name, "PASS", len(read_a), len(read_b), len(copies), "highest C LDS byte", highest)
