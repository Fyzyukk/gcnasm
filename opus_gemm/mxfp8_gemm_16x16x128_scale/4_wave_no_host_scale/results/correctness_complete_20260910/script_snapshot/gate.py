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
    check_scale_mapping()
    check_sfa_k8_slab_mapping()
    check_sfb_k16_slab_mapping()
    build = pathlib.Path(sys.argv[1]).resolve()
    isa = (build / "kernel.isa").read_text()
    notes = (build / "kernel.notes").read_text()
    source = (build.parent / "tmpl.hpp").read_text()
    ins = instructions(isa)
    counts = collections.Counter(map(opcode, ins))
    direct_to_lds_srds = collections.Counter(
        match.group(1)
        for line in ins
        if (match := re.search(
            r"^buffer_load_dwordx4\s+[^,]+,\s+s\[([0-9]+:[0-9]+)\].*\blds$",
            line))
    )
    mfma_indices = [
        i for i, inst in enumerate(ins)
        if inst.startswith("v_mfma_scale_f32_16x16x128_f8f6f4")
    ]
    mfmas = [ins[i] for i in mfma_indices]
    mfma_ops = [mfma_operands(inst) for inst in mfmas]
    accumulator_tuples = collections.Counter(ops[0] for ops in mfma_ops)
    store_indices = [
        i for i, inst in enumerate(ins)
        if inst.startswith(("buffer_store_dwordx4",
                            "global_store_dwordx4"))
    ]
    stores = [ins[i] for i in store_indices]
    store_values = [inst.split(None, 1)[1].split(",", 1)[0].strip()
                    for inst in stores]
    expected_accumulators = {
        f"a[{base}:{base + 3}]" for base in range(0, 256, 4)
    }
    b0_accumulators = [
        f"a[{base}:{base + 3}]"
        for first in (0, 128)
        for base in range(first, first + 64, 4)
    ]
    b1_accumulators = [
        f"a[{base}:{base + 3}]"
        for first in (64, 192)
        for base in range(first, first + 64, 4)
    ]
    expected_store_values = b0_accumulators + b1_accumulators
    coexec_windows, coexec_srds = coexec_vmem4_windows(ins)
    scale_load16 = [
        inst for inst in ins
        if inst.startswith("buffer_load_dwordx4") and not inst.endswith("lds")
    ]

    values = {
        "instructions": len(ins),
        "mfma": counts["v_mfma_scale_f32_16x16x128_f8f6f4"],
        "valu": sum(count for op, count in counts.items()
                    if op.startswith("v_") and not op.startswith("v_mfma_")),
        "salu": sum(count for op, count in counts.items() if op.startswith("s_")),
        "vmem_load": sum(count for op, count in counts.items()
                         if op.startswith(("buffer_load", "global_load"))),
        "vmem_store": sum(count for op, count in counts.items()
                          if op.startswith(("buffer_store", "global_store"))),
        "ds_read": sum(count for op, count in counts.items()
                       if op.startswith("ds_read")),
        "ds_write": sum(count for op, count in counts.items()
                        if op.startswith("ds_write")),
        "wait": counts["s_waitcnt"],
        "nop": sum(count for op, count in counts.items()
                   if op.endswith("_nop")),
        "barrier": counts["s_barrier"],
        "branch": sum(count for op, count in counts.items()
                      if op == "s_branch" or op.startswith("s_cbranch_")),
        "copy_moves": sum(count for op, count in counts.items()
                          if op.startswith(("v_mov", "s_mov"))),
        "acc_read": sum(count for op, count in counts.items()
                        if op.startswith("v_accvgpr_read")),
        "acc_write": sum(count for op, count in counts.items()
                         if op.startswith("v_accvgpr_write")),
        "vgpr": metadata(notes, "vgpr_count"),
        "agpr": metadata(notes, "agpr_count"),
        "sgpr": metadata(notes, "sgpr_count"),
        "vgpr_spill": metadata(notes, "vgpr_spill_count"),
        "sgpr_spill": metadata(notes, "sgpr_spill_count"),
        "private": metadata(notes, "private_segment_fixed_size"),
        "lds": metadata(notes, "group_segment_fixed_size"),
        "max_workgroup": metadata(notes, "max_flat_workgroup_size"),
        "wavefront": metadata(notes, "wavefront_size"),
        "scratch_ops": sum(count for op, count in counts.items()
                           if op.startswith("scratch_")),
        "direct_to_lds_srds": len(direct_to_lds_srds),
        "coexec_windows": coexec_windows,
    }
    # On gfx950 metadata vgpr_count is the combined architectural-VGPR plus
    # AGPR allocation.  Subtract the AGPR extent to expose the ordinary VGPR
    # demand that must remain within v0:v255.
    values["arch_vgpr"] = values["vgpr"] - values["agpr"]
    print("SFB-K16-CARRIED-RAW-COEXEC: "
          + " ".join(f"{key}={value}" for key, value in values.items()))

    expected = {
        "instructions": 1934,
        "mfma": 384,
        "valu": 499,
        "salu": 628,
        "vmem_load": 122,
        "vmem_store": 64,
        "ds_read": 225,
        "ds_write": 12,
        "wait": 76,
        "nop": 100,
        "branch": 23,
        "copy_moves": 187,
        "agpr": 256,
        "sgpr": 83,
        "vgpr_spill": 0,
        "sgpr_spill": 0,
        "private": 0,
        "lds": 163840,
        "max_workgroup": 256,
        "wavefront": 64,
        "scratch_ops": 0,
        "direct_to_lds_srds": 5,
        "coexec_windows": 21,
        "arch_vgpr": 180,
        "vgpr": 436,
    }
    for key, expected_value in expected.items():
        if values[key] != expected_value:
            raise RuntimeError(
                f"SFB-K16-CARRIED-RAW-COEXEC: expected {key}={expected_value}, "
                f"got {values[key]}")
    if counts["buffer_load_dword"] != 0:
        raise RuntimeError(
            "aligned K16 path must not emit scalar global scale loads, "
            f"got {counts['buffer_load_dword']}")
    if scale_load16:
        raise RuntimeError(
            "SFA/SFB slab path must eliminate ordinary global-to-VGPR "
            f"dwordx4 scale loads, got {len(scale_load16)}")
    if counts["ds_read_b128"] != 195:
        raise RuntimeError(
            "SFA K4 queue refill must retain the expected ds_read_b128 set, "
            f"got {counts['ds_read_b128']}")
    if counts["ds_read_b32"] != 29:
        raise RuntimeError(
            "raw SFA/SFB slab reads changed unexpectedly, got "
            f"{counts['ds_read_b32']} ds_read_b32 instructions")
    selector_counts = {
        "v_cmp_eq_u32_e32": counts["v_cmp_eq_u32_e32"],
        "v_cndmask_b32_e32": counts["v_cndmask_b32_e32"],
        "v_ashrrev_i32_e32": counts["v_ashrrev_i32_e32"],
        "v_min_i32_e32": counts["v_min_i32_e32"],
        "v_sub_u32_e32": counts["v_sub_u32_e32"],
    }
    expected_selector_counts = {
        "v_cmp_eq_u32_e32": 1,
        "v_cndmask_b32_e32": 3,
        "v_ashrrev_i32_e32": 0,
        "v_min_i32_e32": 0,
        "v_sub_u32_e32": 0,
    }
    if selector_counts != expected_selector_counts:
        raise RuntimeError(
            "SFB K16 carried selector/clamp opcode set changed: "
            f"expected {expected_selector_counts}, got {selector_counts}")
    if counts["ds_write_b32"] != 12:
        raise RuntimeError(
            "rolling store4 path must emit twelve static LDS dword writes")
    if sum(count for op, count in counts.items()
           if op.startswith("ds_write_b8")):
        raise RuntimeError("rolling store4 path must not retain byte scatters")
    if counts["v_permlane16_swap_b32_e64"] != 14:
        raise RuntimeError("expected fourteen permlane16 scale swaps")
    if counts["v_permlane32_swap_b32_e64"] != 14:
        raise RuntimeError("expected fourteen permlane32 scale swaps")
    if counts["v_perm_b32"] != 28:
        raise RuntimeError("expected twenty-eight scale byte permutes")
    if values["coexec_windows"] != 21:
        raise RuntimeError(
            "prepared-scale cadence changed: expected twenty-one "
            f"MFMA->4xDTLDS windows, got {values['coexec_windows']}")
    if sorted(coexec_srds.values()) != [1, 10, 10]:
        raise RuntimeError(
            "prepared scale must retain twenty A/B groups plus one scale group, got "
            f"{coexec_srds}")
    if values["arch_vgpr"] > 256 or values["vgpr"] > 512:
        raise RuntimeError(
            "SFB-K16-CARRIED-RAW-COEXEC: vector register budget overflow "
            f"arch_vgpr={values['arch_vgpr']} total={values['vgpr']}")
    expected_source_pins = []
    for quadrant, first in (("c00", 0), ("c01", 64),
                            ("c10", 128), ("c11", 192)):
        for fragment in range(16):
            expected_source_pins.append(
                (f"{quadrant}_{fragment}", first + 4 * fragment))
    for name, base in expected_source_pins:
        pattern = rf"MXFP8_PIN_C\(\s*{name}\s*,\s*{base}\s*\)"
        if re.search(pattern, source) is None:
            raise RuntimeError(
                f"SCALE-LOAD16-K4-ROLLING-LANE-TRANSPOSE-STORE4: missing {name} -> a{base}:a{base + 3}")
    if "amdgpu_pin_vgpr" in source:
        raise RuntimeError(
            "SFB K16 carried variant must leave ordinary operands to RA")
    if "asm volatile" in source:
        raise RuntimeError(
            "SFB K16 carried variant must not use handwritten ISA")
    if source.count("load<T::SCALE_CACHE_VEC>(") != 3:
        raise RuntimeError(
            "source must contain two scale-slab DTLDS producers and one "
            "SFA K4 LDS-to-VGPR refill")
    if "if ((tile_k & (T::SCALE_CACHE_TILES - 1)) == 0)" not in source:
        raise RuntimeError(
            "SFA rolling source must refresh only at K4 phase zero")
    if source.count("load<T::SCALE_TILE_VEC>(") != 1:
        raise RuntimeError(
            "source must contain exactly one raw-SFB LDS dword load helper")
    for marker in ("v_gsfa_c0", "v_gsfa_c1", "v_gsfa_c2", "v_gsfa_c3"):
        if marker not in source:
            raise RuntimeError(
                f"SFA K4 source is missing explicit queue register {marker}")
    for marker in ("v_gsfb_c0", "v_gsfb_c1", "v_gsfb_c2", "v_gsfb_c3"):
        if marker in source:
            raise RuntimeError(
                f"SFB K16 source unexpectedly retains queue register {marker}")
    for marker in ("sfa_slab_tiles = 8", "sfa_slab_row_elem",
                   "smem_sfa_raw", "prefetch_sfa_slab",
                   "sfb_slab_tiles = 16", "smem_sfb_raw",
                   "load_sfb_slab_dword", "v_gsfb_carried"):
        if marker not in source:
            raise RuntimeError(f"missing raw scale-slab marker {marker}")
    for marker in ("sfa_cache_tile", "sfb_cache_tile", "sfa_row_last_load",
                   "sfb_row_last_load", "sfa_block_last_load",
                   "sfb_block_last_load"):
        if marker in source:
            raise RuntimeError(
                f"rolling K4 source retains dynamic selector/clamp {marker}")
    if source.count("transpose_scale_dword_4x4(") != 3:
        raise RuntimeError(
            "source must define one transpose and call it for SFA/SFB")
    if source.count("store<4>(") != 2 or "store<1>(" in source:
        raise RuntimeError(
            "source must use exactly one store<4> each for SFA and SFB")
    ds_group = "__builtin_amdgcn_sched_group_barrier(0x100, 4, 0)"
    if source.count(ds_group) != 3:
        raise RuntimeError(
            "B1 head plus split tail must have exactly three count-4 DS "
            f"groups, got {source.count(ds_group)}")
    if any(len(ops) < 4 or ops[0] != ops[3] for ops in mfma_ops):
        raise RuntimeError("MFMA destination/SrcC accumulator tie changed")
    if set(accumulator_tuples) != expected_accumulators:
        raise RuntimeError(
            "accumulator tuples are not exactly the pinned a0:a255 range: "
            f"{sorted(accumulator_tuples)}")
    if any(count != 6 for count in accumulator_tuples.values()):
        raise RuntimeError(
            f"unexpected per-tuple MFMA counts: {accumulator_tuples}")
    if counts["ds_read2_b32"] != 1:
        raise RuntimeError(
            "hybrid SFA rolling must fuse only the prologue SFA seed into one "
            f"ds_read2_b32, got {counts['ds_read2_b32']}")

    # The row-major scale cache adds VMEM-to-VGPR dependencies and eight LDS
    # byte stores to each static tile body, so clang23 legitimately changes
    # the deferred partial-wait sequence. Preserve the retained wait6 loop
    # entry without freezing those secondary waits to the packed-scale ISA.
    all_wait6_indices = [
        index for index, inst in enumerate(ins)
        if inst == "s_waitcnt lgkmcnt(6)"
    ]
    loop_head_wait6_indices = [
        index for index in all_wait6_indices
        if index + 1 < len(ins) and ins[index + 1] == "s_setprio 1"
    ]
    if len(loop_head_wait6_indices) != 5:
        raise RuntimeError(
            "load16/K4 variant must retain five non-final loop-head "
            f"lgkmcnt(6) waits, got {len(loop_head_wait6_indices)}")

    if store_values != expected_store_values:
        raise RuntimeError(
            "C stores do not preserve the early-B0 then tail-B1 logical-fragment "
            f"order: {store_values}")
    if values["acc_read"]:
        raise RuntimeError(
            "C-AGPR epilogue unexpectedly uses v_accvgpr_read bridges")

    steady_begin = source.index("#pragma unroll 4")
    steady_end = source.index(
        "// Consume the final resident tile", steady_begin)
    steady = source[steady_begin:steady_end]
    if "auto load_scale" in source:
        raise RuntimeError("monolithic load_scale helper must be removed")
    if source.count("auto prepare_scale") != 1:
        raise RuntimeError("expected exactly one prepare_scale helper")
    if source.count("auto publish_scale") != 1:
        raise RuntimeError("expected exactly one publish_scale helper")
    if source.count("prepare_scale(") != 3:
        raise RuntimeError("expected tile0, tile1, and future prepare calls")
    if source.count("publish_scale(") != 2:
        raise RuntimeError("expected tile0 and steady publish calls")
    markers = {
        "early SFB1 read": "v_sfb[1] = __builtin_bit_cast",
        "first-source wait6":
            "s_waitcnt_lgkmcnt(opus::number<6>{});",
        "first c00 MFMA":
            "0, 0, 0, v_a[0], v_b, c00_0, v_sfa, v_sfb[0]);",
        "A1 read":
            "v_a[1] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 1));",
        "A1-following wait9":
            "s_waitcnt_lgkmcnt(opus::number<9>{});",
        "first post-A1 c00 pair":
            "0, 0, 1, v_a[0], v_b, c00_2, c00_3, v_sfa, v_sfb[0]);",
        "B1 head read": "load_b_range_scale<T, 0, 4>(",
        "B1 tail first read": "load_b_range_scale<T, 4, 6>(",
        "B1 tail second read": "load_b_range_scale<T, 6, 8>(",
        "first c10 MFMA":
            "1, 0, 0, v_a[1], v_b, c10_0, c10_1, v_sfa, v_sfb[0]);",
    }
    positions = {
        label: unique_index(steady, marker, label)
        for label, marker in markers.items()
    }
    c00_markers = [
        "0, 0, 0, v_a[0], v_b, c00_0, v_sfa, v_sfb[0]);",
        "0, 0, 1, v_a[0], v_b, c00_1, v_sfa, v_sfb[0]);",
        "0, 0, 1, v_a[0], v_b, c00_2, c00_3, v_sfa, v_sfb[0]);",
        "0, 1, 0, v_a[0], v_b, c00_4, c00_5, v_sfa, v_sfb[0]);",
        "0, 1, 1, v_a[0], v_b, c00_6, c00_7, v_sfa, v_sfb[0]);",
        "0, 2, 0, v_a[0], v_b, c00_8, c00_9, v_sfa, v_sfb[0]);",
        "0, 2, 1, v_a[0], v_b, c00_10, c00_11, v_sfa, v_sfb[0]);",
        "0, 3, 0, v_a[0], v_b, c00_12, c00_13, v_sfa, v_sfb[0]);",
        "0, 3, 1, v_a[0], v_b, c00_14, c00_15, v_sfa, v_sfb[0]);",
    ]
    c00_weights = [1, 1, 2, 2, 2, 2, 2, 2, 2]
    c00_positions = [
        unique_index(steady, marker, f"c00 call {index}")
        for index, marker in enumerate(c00_markers)
    ]
    if c00_positions != sorted(c00_positions):
        raise RuntimeError("steady c00 MFMA source order changed")
    completed_before_head = sum(
        weight for position, weight in zip(c00_positions, c00_weights)
        if position < positions["B1 head read"]
    )
    if completed_before_head != 4:
        raise RuntimeError(
            "B1 head must follow exactly 4 c00 MFMAs, got "
            f"{completed_before_head}")
    fixed_prefix = [
        positions["early SFB1 read"],
        positions["first-source wait6"],
        positions["first c00 MFMA"],
        positions["A1 read"],
        positions["A1-following wait9"],
        positions["first post-A1 c00 pair"],
    ]
    if fixed_prefix != sorted(fixed_prefix):
        raise RuntimeError(
            "steady prefix changed: expected early SFB1 -> wait6 -> first c00 "
            "-> A1 -> wait9 -> first post-A1 c00 pair")
    group_positions = [
        match.start() for match in re.finditer(re.escape(ds_group), steady)
    ]
    if len(group_positions) != 3:
        raise RuntimeError("all three B1 DS groups must be in the steady loop")
    if not (positions["B1 head read"] < group_positions[0]
            < positions["B1 tail first read"] < group_positions[1]
            < positions["first c10 MFMA"]):
        raise RuntimeError(
            "B1 head and first tail half must precede c10 in source order")
    c10_prefix_markers = [
        "1, 0, 0, v_a[1], v_b, c10_0, c10_1, v_sfa, v_sfb[0]);",
        "1, 0, 1, v_a[1], v_b, c10_2, c10_3, v_sfa, v_sfb[0]);",
    ]
    c10_prefix_positions = [
        unique_index(steady, marker, f"c10 prefix call {index}")
        for index, marker in enumerate(c10_prefix_markers)
    ]
    if not (c10_prefix_positions[0] < c10_prefix_positions[1]
            < positions["B1 tail second read"] < group_positions[2]):
        raise RuntimeError(
            "second tail half must follow exactly four c10 MFMAs")

    sfa_refill = unique_index(
        steady, "prefetch_sfa_slab(future_tile);", "SFA K8 slab refill")
    source_c10_10 = unique_index(
        steady,
        "1, 2, 1, v_a[1], v_b, c10_10, c10_11, v_sfa, v_sfb[0]);",
        "c10_10/c10_11 pair",
    )
    source_c10_12 = unique_index(
        steady,
        "1, 3, 0, v_a[1], v_b, c10_12, c10_13, v_sfa, v_sfb[0]);",
        "c10_12/c10_13 pair",
    )
    if not source_c10_10 < sfa_refill < source_c10_12:
        raise RuntimeError(
            "SFA K8 DTLDS refill must follow c10_10/11 and precede "
            "c10_12/13")

    source_c01_5 = unique_index(
        steady,
        "0, 1, 1, v_a[0], v_b_n1, c01_5, v_sfa, v_sfb[1]);",
        "single c01_5 MFMA",
    )
    source_sfa1_next = unique_index(
        steady, "v_sfa1_next = __builtin_bit_cast", "rolling SFA1 read")
    source_c01_6 = unique_index(
        steady,
        "0, 1, 1, v_a[0], v_b_n1, c01_6, c01_7, v_sfa, v_sfb[1]);",
        "c01_6/c01_7 pair",
    )
    if not source_c01_5 < source_sfa1_next < source_c01_6:
        raise RuntimeError(
            "next SFA1 source read must follow c01_5 and precede c01_6")

    source_carried_sfb = unique_index(
        steady,
        "v_gsfb_carried = load_sfb_slab_dword(future_tile);",
        "carried raw-SFB read",
    )
    source_c01_8 = unique_index(
        steady,
        "0, 2, 0, v_a[0], v_b_n1, c01_8, c01_9, v_sfa, v_sfb[1]);",
        "c01_8/c01_9 pair",
    )
    source_c01_10 = unique_index(
        steady,
        "0, 2, 1, v_a[0], v_b_n1, c01_10, c01_11, v_sfa, v_sfb[1]);",
        "c01_10/c01_11 pair",
    )
    if not source_c01_8 < source_carried_sfb < source_c01_10:
        raise RuntimeError(
            "carried raw-SFB read must follow c01_8/c01_9 and precede "
            "c01_10/c01_11")
    if "v_gsfb_carried = load_sfb_slab_dword(1);" not in source[:steady_begin]:
        raise RuntimeError("prologue must seed the carried tile-1 raw SFB dword")

    ds_read_destinations = collections.Counter()
    for inst in ins:
        match = re.match(r"ds_read_b32\s+(v\d+),", inst)
        if match:
            ds_read_destinations[match.group(1)] += 1
    carried_regs = [reg for reg, count in ds_read_destinations.items()
                    if count == 6]
    if len(carried_regs) != 1:
        raise RuntimeError(
            "expected one physical VGPR with six carried raw-SFB reads, got "
            f"{carried_regs}")
    carried_reg = carried_regs[0]
    carried_read_indices = [
        index for index, inst in enumerate(ins)
        if re.match(rf"ds_read_b32\s+{re.escape(carried_reg)},", inst)
    ]
    carried_distances = []
    for read_index in carried_read_indices[:-1]:
        use_index = next(
            index for index in range(read_index + 1, len(ins))
            if re.search(
                rf"(?<![A-Za-z0-9_]){re.escape(carried_reg)}(?![0-9])",
                ins[index],
            )
        )
        carried_distances.append(sum(
            read_index < index < use_index for index in mfma_indices))
    if carried_distances != [39, 25, 25, 16, 4]:
        raise RuntimeError(
            "prepared-scale raw-SFB schedule changed before "
            f"their first linear use, got {carried_distances}")

    last_c01 = unique_index(
        steady,
        "0, 3, 1, v_a[0], v_b_n1, c01_14, c01_15, v_sfa, v_sfb[1]);",
        "last c01 MFMA",
    )
    rolling_sfa0 = unique_index(
        steady,
        "v_sfa[0] = __builtin_bit_cast(\n            D_SF_PACK, load<4>(s_sfa, next_rsfa_offsets[0]));",
        "rolling SFA0 read",
    )
    first_c11 = unique_index(
        steady,
        "1, 0, 0, v_a[1], v_b_n1, c11_0, c11_1, v_sfa, v_sfb[1]);",
        "first c11 MFMA",
    )
    if not last_c01 < rolling_sfa0 < first_c11:
        raise RuntimeError(
            "rolling SFA0 source read must be between final c01 and first c11")
    future_prepare = unique_index(
        steady,
        "prepare_scale(future_tile, v_gsfb_carried);",
        "future prepared-scale transpose",
    )
    c11_after4 = unique_index(
        steady,
        "1, 0, 1, v_a[1], v_b_n1, c11_2, c11_3, v_sfa, v_sfb[1]);",
        "fourth c11 MFMA",
    )
    c11_after4_next = unique_index(
        steady,
        "1, 1, 0, v_a[1], v_b_n1, c11_4, c11_5, v_sfa, v_sfb[1]);",
        "fifth c11 MFMA",
    )
    if not (rolling_sfa0 < first_c11 < c11_after4
            < future_prepare < c11_after4_next):
        raise RuntimeError(
            "future scale preparation must follow exactly four c11 MFMAs")
    steady_publish = unique_index(
        steady, "publish_scale(next_stage);", "steady prepared-scale publish")
    if steady_publish > positions["first-source wait6"]:
        raise RuntimeError("prepared scale must publish before loop-head wait6")
    if "const auto rsfa_offsets =" in steady:
        raise RuntimeError("steady-loop header still reloads current SFA1")
    latch_sfa1 = unique_index(
        steady, "v_sfa[1] = v_sfa1_next;", "SFA1 loop latch")
    if latch_sfa1 < first_c11:
        raise RuntimeError("next SFA1 must not become current before c11")

    prologue = source[:steady_begin]
    if not (prologue.index("prepare_scale(0, v_gsfb_tile0);")
            < prologue.index("publish_scale(0);")
            < prologue.index("prepare_scale(1, v_gsfb_carried);")):
        raise RuntimeError(
            "prologue must publish tile0 before carrying prepared tile1")
    if "const auto seed_rsfa_offsets =" not in prologue:
        raise RuntimeError("missing tile-0 SFA0 seed before the steady loop")
    if "seed_rsfa_offsets[0] + 4" not in prologue:
        raise RuntimeError("missing tile-0 SFA1 seed before the steady loop")

    mfma_positions_by_accumulator: dict[str, list[int]] = collections.defaultdict(list)
    for index, operands in zip(mfma_indices, mfma_ops):
        mfma_positions_by_accumulator[operands[0]].append(index)
    store_positions = dict(zip(store_values, store_indices))
    b0_store_indices = [store_positions[value] for value in b0_accumulators]
    b1_store_indices = [store_positions[value] for value in b1_accumulators]
    final_b0_mfma = max(
        mfma_positions_by_accumulator[value][-1] for value in b0_accumulators)
    first_final_b1_mfma = min(
        mfma_positions_by_accumulator[value][-1] for value in b1_accumulators)
    last_final_b1_mfma = max(
        mfma_positions_by_accumulator[value][-1] for value in b1_accumulators)
    if min(b0_store_indices) >= first_final_b1_mfma:
        raise RuntimeError(
            "final-tile B0 stores must start before the first B1 MFMA")
    if max(b0_store_indices) >= last_final_b1_mfma:
        raise RuntimeError(
            "final-tile B0 stores must finish issuing before the B1 MFMA tail")
    if any(
        mfma_positions_by_accumulator[value][-1] >= store_positions[value]
        for value in b0_accumulators + b1_accumulators
    ):
        raise RuntimeError("a C fragment is stored before its final MFMA update")
    overlapped_mfmas = [
        index for index in mfma_indices
        if min(b0_store_indices) < index < max(b0_store_indices)
    ]
    overlapped_b1_mfmas = [
        index for index in overlapped_mfmas
        if mfma_ops[mfma_indices.index(index)][0] in b1_accumulators
    ]
    if not overlapped_mfmas or not overlapped_b1_mfmas:
        raise RuntimeError(
            "clang23 final-K early-store/XDL overlap disappeared: "
            f"got total={len(overlapped_mfmas)} B1={len(overlapped_b1_mfmas)}")
    if any(
        "vmcnt" in inst
        for inst in ins[min(b0_store_indices):last_final_b1_mfma]
        if inst.startswith("s_waitcnt")
    ):
        raise RuntimeError(
            "a VMEM wait drains early C stores before the final B1 MFMA tail")

    final_source = source.split(
        "// Consume the final resident tile without issuing more global loads.",
        1,
    )[1]
    if "load<4>(s_sfa" in final_source:
        raise RuntimeError("final resident path redundantly reloads carried SFA")
    source_b0_store = final_source.index("MXFP8_STORE_QUADRANT(c00, 0, 0);")
    source_b1_mfma = final_source.index(
        "MXFP8_MMA_PAIR(0, 0, 0, v_a[0], v_b, c01_0, c01_1")
    if source_b0_store >= source_b1_mfma:
        raise RuntimeError("source no longer issues final B0 stores before B1 MFMAs")

    print("PASS: 256 threads = 4 Wave64, 163840 B LDS = one WG/CU by LDS")
    print("PASS: no scratch/private segment or compiler-reported spills")
    print("PASS: exhaustive SFA/SFB mapping covers 1024 unique bytes each")
    print("PASS: exhaustive SFA K8 slab producer/consumer mapping is exact")
    print("PASS: exhaustive SFB K16 slab producer/consumer mapping is exact")
    print("PASS: scale path uses only DTLDS global loads plus K4/K16 LDS reads")
    print("PASS: explicit SFA c0..c3 queue removes dynamic selectors and safety clamps")
    print("PASS: fourteen permlane16 + fourteen permlane32 + twenty-eight byte permutes")
    print("PASS: all 384 MFMA Dst/SrcC tuples are pinned exactly to a0:a255")
    print("PASS: 64 direct AGPR stores, no accvgpr-read bridge or handwritten ISA")
    if "const int future_tile = (tile + 2) & 63;" not in steady:
        raise RuntimeError("exact-K64 source is missing the power-of-two wrap")
    if "tile + 2 < loops" in steady:
        raise RuntimeError("exact-K64 steady loop still contains a future guard")
    if steady.count("gb_offset(0, future_tile)") != 4:
        raise RuntimeError("exact-K64 B0 producer does not use wrapped offsets")
    if steady.count("gb_offset(1, future_tile)") != 4:
        raise RuntimeError("exact-K64 B1 producer does not use wrapped offsets")

    print("PASS: twenty A/B MFMA -> 4xDTLDS windows plus one scale window retained")
    print("PASS: exact-K64 future producers use a guard-free modulo-64 wrap")
    print("PASS: prepared raw-SFB first-use distances match the linked ISA")
    print("PASS: future scale prepare follows exactly four c11 MFMAs")
    print("PASS: tile0/tile1/future prepare and header-only publish ordering is exact")
    print("PASS: source retains the SFA1/SFA0 rolling pipeline")
    print("PASS: B1 head follows 4 c00 MFMAs; tail is split across c00/c10")
    print("PASS: five non-final loop-head wait6 waits are retained")
    print("PASS: steady source keeps wait6 before c00 and wait9 after A1")
    print("PASS: final B0 store span overlaps the B1 MFMA tail")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
