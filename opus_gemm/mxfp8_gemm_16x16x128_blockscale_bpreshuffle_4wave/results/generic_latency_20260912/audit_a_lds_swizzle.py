#!/usr/bin/env python3
"""Enumerate global A producers and native MFMA consumers for each LDS stage."""
import hashlib
import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
WORK = Path((HERE / "work_path.txt").read_text().strip())
DEST = HERE / "a_mapping"
DEST.mkdir(exist_ok=True)
PITCH = 1056
HALF = 16 * PITCH
STAGE = 2 * HALF

for name in sys.argv[1:]:
    directory = WORK / name
    metadata = json.loads((directory / "candidate.json").read_text())
    mask = metadata["config"]["a_lds_k_vector_xor_mask"]
    assert mask in (3, 7)
    assert metadata["config"]["initial_matrix_producer"] == "same_A_B_roles_as_main"
    source = (directory / "tmpl_generic.hpp").read_text()
    assert f"(2 * (lane_id / 8) - (issue & 1)) & {mask}" in source
    assert f"(2 * row_pair - parity) & {mask}" in source
    assert "(swizzle & 4) ? -64 : 64" in source
    assert "address += (logical_k_vector - physical_k_vector) * 16;" in source
    producers = {}
    logical = set()
    for stage in range(2):
        for half in range(2):
            for issue in range(16):
                for lane in range(64):
                    row_pair, physical_k = divmod(lane, 8)
                    parity = issue & 1
                    swizzle = (2 * row_pair - parity) & mask
                    row = half * 128 + 2 * row_pair + 16 * (issue // 2) + parity
                    kval = (physical_k ^ swizzle) * 16
                    address = stage * STAGE + half * HALF + issue * PITCH + lane * 16
                    assert address % 16 == kval % 16 == 0
                    assert 0 <= row < 256 and 0 <= kval <= 112
                    for byte in range(16):
                        key = (stage, row, kval + byte)
                        assert key not in logical and address + byte not in producers
                        assert stage * STAGE <= address + byte < (stage + 1) * STAGE
                        logical.add(key)
                        producers[address + byte] = key
    assert len(logical) == 2 * 256 * 128
    consumed = set()
    negative_piece_reads = 0
    for stage in range(2):
        for half in range(2):
            for wave_m in range(2):
                for m_repeat in range(4):
                    for lane in range(64):
                        row_pair = (lane & 15) // 2
                        parity = lane & 1
                        swizzle = (2 * row_pair - parity) & mask
                        delta = -64 if swizzle & 4 else 64
                        physical_row = wave_m * 2 + parity + m_repeat * 4
                        physical_row_base = stage * STAGE + half * HALF + physical_row * PITCH
                        row = half * 128 + wave_m * 16 + m_repeat * 32 + lane % 16
                        for k_piece in range(2):
                            kval = (lane // 16) * 16 + k_piece * 64
                            address = (physical_row_base + row_pair * 128
                                       + ((lane // 16) ^ swizzle) * 16 + k_piece * delta)
                            assert address % 16 == 0
                            assert physical_row_base <= address < address + 15 < physical_row_base + 1024
                            negative_piece_reads += int(k_piece == 1 and delta < 0)
                            for byte in range(16):
                                key = (stage, row, kval + byte)
                                assert producers[address + byte] == key, (name, address, key)
                                assert key not in consumed
                                consumed.add(key)
    assert consumed == logical
    report = dict(name=name, status="PASS", mask=mask, stages=2,
                  producer_bytes=len(producers), consumer_bytes=len(consumed),
                  matrix_shape_per_stage=[256, 128], vector_alignment_bytes=16,
                  highest_a_lds_byte=max(producers), a_lds_capacity_bytes=2 * STAGE,
                  negative_k64_piece_reads=negative_piece_reads,
                  source_sha256=hashlib.sha256(source.encode()).hexdigest(),
                  scope="Bijective global-A to LDS and native MFMA coordinates, both stages and K64 pieces; linked ISA and GPU correctness audited separately.")
    (DEST / (name + ".json")).write_text(json.dumps(report, indent=2) + "\n")
    print(name, "PASS", len(consumed), "bytes;", negative_piece_reads, "negative-stride pieces")
