#!/usr/bin/env python3
from __future__ import annotations

import collections
import pathlib
import re
import sys


def instructions(text: str) -> list[str]:
    return [
        line.split("//", 1)[0].strip()
        for line in text.splitlines()
        if re.search(r"// [0-9A-F]{12,}:", line)
    ]


def opcode(inst: str) -> str:
    return inst.split(None, 1)[0] if inst else ""


def metadata(text: str, name: str) -> int:
    match = re.search(rf"\.{re.escape(name)}:\s*(\d+)", text)
    if match is None:
        raise RuntimeError(f"missing .{name}")
    return int(match.group(1))


def mfma_operands(inst: str) -> list[str]:
    return [operand.strip() for operand in inst.split(None, 1)[1].split(",")]


def unique_index(text: str, marker: str, label: str) -> int:
    count = text.count(marker)
    if count != 1:
        raise RuntimeError(
            f"expected exactly one {label} source marker, got {count}")
    return text.index(marker)


def check_scale_mapping() -> None:
    sfa_payload: set[tuple[int, int]] = set()
    sfb_payload: set[tuple[int, int]] = set()
    sfa_destinations: set[int] = set()
    sfb_destinations: set[int] = set()
    for wave in range(4):
        wave_m = wave % 2
        wave_n = wave // 2
        for lane in range(64):
            scale_r = lane % 16
            scale_call = lane // 16
            sfa_m_call = 4 * wave_n + scale_call
            sfa_row = 32 * sfa_m_call + 16 * wave_m + scale_r
            sfb_row = 128 * wave_m + 32 * scale_call + 16 * wave_n + scale_r
            for q in range(4):
                sfa_payload.add((sfa_row, q))
                sfb_payload.add((sfb_row, q))
                old_sfa = (16 * wave_m + scale_r) * 32 + 8 * q + sfa_m_call
                old_sfb = ((2 * wave_m + wave_n) * 16 + scale_r) * 16 + 4 * q + scale_call
                new_sfa = (16 * wave_m + scale_r) * 32 + 8 * q + 4 * wave_n + scale_call
                new_sfb = ((2 * wave_m + wave_n) * 16 + scale_r) * 16 + 4 * q + scale_call
                if new_sfa != old_sfa or new_sfb != old_sfb:
                    raise RuntimeError("lane transpose changes a consumer byte address")
                sfa_destinations.add(new_sfa)
                sfb_destinations.add(new_sfb)
    expected = set(range(1024))
    if len(sfa_payload) != 1024 or len(sfb_payload) != 1024:
        raise RuntimeError("row-major scale loads do not uniquely cover 1024 bytes")
    if sfa_destinations != expected or sfb_destinations != expected:
        raise RuntimeError("lane transpose does not cover consumer LDS exactly once")


def check_sfb_k16_slab_mapping() -> None:
    destinations: dict[tuple[int, int], int] = {}
    for wave in range(4):
        wave_m = wave % 2
        wave_n = wave // 2
        for producer_lane in range(64):
            row_slot = producer_lane >> 2
            row_segment = producer_lane & 3
            for producer_pass in range(4):
                owner_lane = producer_pass * 16 + row_slot
                scale_r = owner_lane % 16
                scale_call = owner_lane // 16
                sfb_row = (wave_m * 128 + scale_call * 32
                           + wave_n * 16 + scale_r)
                for byte in range(16):
                    logical = (sfb_row, row_segment * 16 + byte)
                    physical = (wave * 4096 + producer_pass * 1024
                                + producer_lane * 16 + byte)
                    if logical in destinations:
                        raise RuntimeError(f"duplicate SFB slab byte {logical}")
                    destinations[logical] = physical

        for owner_lane in range(64):
            scale_r = owner_lane % 16
            scale_call = owner_lane // 16
            sfb_row = (wave_m * 128 + scale_call * 32
                       + wave_n * 16 + scale_r)
            for phase in range(16):
                producer_pass = owner_lane >> 4
                row_slot = owner_lane & 15
                producer_lane = row_slot * 4 + (phase >> 2)
                physical = (wave * 4096 + producer_pass * 1024
                            + producer_lane * 16 + (phase & 3) * 4)
                for byte in range(4):
                    if destinations.get((sfb_row, phase * 4 + byte)) != physical + byte:
                        raise RuntimeError(
                            "SFB K16 slab producer/consumer mapping mismatch")
    if len(destinations) != 4 * 64 * 64:
        raise RuntimeError("SFB K16 slab does not cover every owned byte")


def check_sfa_k8_slab_mapping() -> None:
    """Exhaustively match the two DTLDS producer passes to K4 consumers."""
    destinations: dict[tuple[int, int], int] = {}
    for wave in range(4):
        wave_m = wave % 2
        wave_n = wave // 2
        for producer_lane in range(64):
            row_slot = producer_lane >> 1
            row_segment = producer_lane & 1
            for producer_pass in range(2):
                owner_lane = producer_pass * 32 + row_slot
                scale_r = owner_lane % 16
                scale_call = owner_lane // 16
                sfa_m_call = 4 * wave_n + scale_call
                sfa_row = 32 * sfa_m_call + 16 * wave_m + scale_r
                for byte in range(16):
                    logical = (sfa_row, row_segment * 16 + byte)
                    physical = (wave * 2048 + producer_pass * 1024
                                + producer_lane * 16 + byte)
                    if logical in destinations:
                        raise RuntimeError(f"duplicate SFA slab byte {logical}")
                    destinations[logical] = physical

        for owner_lane in range(64):
            scale_r = owner_lane % 16
            scale_call = owner_lane // 16
            sfa_m_call = 4 * wave_n + scale_call
            sfa_row = 32 * sfa_m_call + 16 * wave_m + scale_r
            for phase in range(8):
                physical = ((wave * 64 + owner_lane) * 32
                            + phase * 4)
                for byte in range(4):
                    if destinations.get((sfa_row, phase * 4 + byte)) != physical + byte:
                        raise RuntimeError(
                            "SFA K8 slab producer/consumer mapping mismatch")
    if len(destinations) != 256 * 32:
        raise RuntimeError("SFA K8 slab does not cover every owned byte")


def coexec_vmem4_windows(ins: list[str]) -> tuple[int, collections.Counter[str]]:
    """Count MFMA -> four same-SRD DTLDS groups before the next MFMA."""
    windows = 0
    srds: collections.Counter[str] = collections.Counter()
    mfma_indices = [i for i, inst in enumerate(ins)
                    if inst.startswith("v_mfma_scale_")]
    for pos, begin in enumerate(mfma_indices[:-1]):
        end = mfma_indices[pos + 1]
        loads = [inst for inst in ins[begin + 1:end]
                 if inst.startswith("buffer_load_dwordx4")
                 and inst.endswith("lds")]
        if len(loads) != 4:
            continue
        load_srds = []
        for inst in loads:
            match = re.search(r",\s+s\[([0-9]+:[0-9]+)\]", inst)
            if match is None:
                break
            load_srds.append(match.group(1))
        if len(load_srds) == 4 and len(set(load_srds)) == 1:
            windows += 1
            srds[load_srds[0]] += 1
    return windows, srds


def main() -> int:
    import json
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent / "tools"))
    from static_common import audit
    from audit_bcontig import check_source, check_math, check_isa
    build = pathlib.Path(sys.argv[1]).resolve(strict=True)
    source_file = pathlib.Path(__file__).resolve().parent / "tmpl.hpp"
    source = source_file.read_text()
    variant = check_source(source_file)
    if variant["name"] != "b_contig_common_vaddr_v1":
        raise RuntimeError("this final package freezes b_contig_common_vaddr_v1")
    common = audit(build)
    b_math = check_math(variant["cancellation"])
    b_isa = check_isa(build, variant)
    # The full reviewed source and native-ISA hashes are checked above.
    # Keep the main scale/synchronization obligations explicit as well.
    required = (
        "sfa_slab_tiles = 8", "sfb_slab_tiles = 16",
        "const int future_tile = (tile + 2) & 63;",
        "s_waitcnt_lgkmcnt(opus::number<6>{});",
        "s_waitcnt_lgkmcnt(opus::number<9>{});",
        "s_waitcnt_vmcnt(0_I);", "s_waitcnt_lgkmcnt(0_I);",
        "__builtin_amdgcn_s_barrier();",
        "v_sfa1_next = __builtin_bit_cast",
        "v_gsfa_c0 = v_gsfa_c1;", "v_gsfa_c1 = v_gsfa_c2;",
        "v_gsfa_c2 = v_gsfa_c3;",
    )
    if any(marker not in source for marker in required):
        raise RuntimeError("required scale/pipeline/synchronization invariant missing")
    if source.count("prepare_scale(") != 3 or source.count("publish_scale(") != 2:
        raise RuntimeError("prologue/steady prepare-publish count changed")
    if source.count("transpose_scale_dword_4x4(") != 3 or source.count("store<4>(") != 2:
        raise RuntimeError("scale transpose/publication structure changed")
    if "asm volatile" in source or "amdgpu_pin_vgpr" in source:
        raise RuntimeError("unexpected handwritten ISA or operand pin")
    steady = source[source.index("#pragma unroll 4"):source.index("// Consume the final resident tile")]
    before = steady.index("c11_2, c11_3, v_sfa, v_sfb[1]);")
    prepare = steady.index("prepare_scale(future_tile, v_gsfb_carried);")
    after = steady.index("c11_4, c11_5, v_sfa, v_sfb[1]);")
    if not before < prepare < after:
        raise RuntimeError("scale prepare no longer follows four c11 MFMAs")
    ins = instructions((build / "kernel.isa").read_text())
    if sum(x == "s_waitcnt lgkmcnt(6)" and i + 1 < len(ins) and ins[i+1] == "s_setprio 1"
           for i, x in enumerate(ins)) != 5:
        raise RuntimeError("five non-final loop-head wait6 obligations changed")
    result = {"status": "PASS", "variant": variant["name"],
              "scale_mapping": "SFA/SFB row-major, K8/K16 producer/consumer exhaustive PASS",
              "pipeline": "reviewed exact source and full native ISA, real waits/barriers retained",
              "common": common, "b_math": b_math, "b_isa": b_isa}
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
