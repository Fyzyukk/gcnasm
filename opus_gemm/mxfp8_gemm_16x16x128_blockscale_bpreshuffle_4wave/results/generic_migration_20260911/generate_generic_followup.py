#!/usr/bin/env python3
"""Combine measured generic gains and distribute scale/address work."""
import json
import re

from generate_output_overlap import overlap
from generate_streaming import WORK, once, record


def distribute_scales(source, a_after, b_after, packed=False):
    a_load = "        v_sfa1_next = load_sfa_dword(tile + 1, 1);\n"
    b_load = """        v_sfb_next = __builtin_bit_cast(opus::vector_t<D_SF_PACK, 2>,
            load<8>(s_sfb, ((tile + 1) & panel_mask) * T::SCALE_N_HALVES * 4));
"""
    assert source.count(a_load) == source.count(b_load) == 2
    source = source.replace(a_load, "").replace(b_load, "")
    if packed:
        source = once(source, "    D_SF_PACK v_sfa1_next;", "    opus::vector_t<D_SF_PACK, 2> v_sfa_next;")
        assert source.count("v_sfa1_next") == 2
        source = source.replace("v_sfa1_next", "v_sfa_next[1]")
        old = "v_sfa[0] = load_sfa_dword(tile + 1, 0);"
        assert source.count(old) == 2
        source = source.replace(old, "v_sfa[0] = v_sfa_next[0];")
        a_load = """        v_sfa_next = __builtin_bit_cast(opus::vector_t<D_SF_PACK, 2>,
            load<8>(s_sfa, ((tile + 1) & panel_mask) * T::SFA_PANEL_PITCH
                + (wave_id_m * T::W_M + (lane_id & 15)) * 8));
"""
    start = source.index("    for (tile = 0; tile + 2 < loops; ++tile) {")
    middle = source.index("    // Penultimate runtime K128 block", start)
    end = source.index("    // Consume the final resident tile", middle)
    pieces = [source[:start], source[start:middle], source[middle:end], source[end:]]
    pattern = re.compile(r"        MXFP8_MMA_(PAIR|ONE)\(\s*[^;]+\);\n"
                         r"        (?:sched_barrier_pairs_scale\(\)|__builtin_amdgcn_sched_barrier\(0\));\n")
    for index in [1, 2]:
        count = 0

        def insert(match):
            nonlocal count
            count += 2 if match[1] == "PAIR" else 1
            extra = ""
            if count == a_after:
                extra += a_load
            if count == b_after:
                extra += b_load
            if extra:
                return match[0] + "\n        // Scales are ready in the published panel; read ahead of the operand roll.\n" + extra + "        __builtin_amdgcn_sched_barrier(0);\n"
            return match[0]

        pieces[index] = pattern.sub(insert, pieces[index])
        assert count == 64, count
    return "".join(pieces)


def pin_operands(source, mode):
    a0 = "__attribute__((amdgpu_pin_vgpr(64))) "
    a1 = "__attribute__((amdgpu_pin_vgpr(96))) " if mode != "a0" else ""
    source = once(source, "    typename decltype(mma)::vtype_a v_a[2];",
                  f"    {a0}typename decltype(mma)::vtype_a v_a0;\n"
                  f"    {a1}typename decltype(mma)::vtype_a v_a1;")
    source = source.replace("v_a[0]", "v_a0").replace("v_a[1]", "v_a1")
    if mode == "ab":
        source = once(source, "    typename decltype(mma)::vtype_b v_b;",
                      "    __attribute__((amdgpu_pin_vgpr(128))) typename decltype(mma)::vtype_b v_b;")
        source = once(source, "    typename decltype(mma)::vtype_b v_b_second;",
                      "    __attribute__((amdgpu_pin_vgpr(160))) typename decltype(mma)::vtype_b v_b_second;")
    return source


if __name__ == "__main__":
    parent = "stream64_batch_scale"
    source = (WORK / parent / "tmpl_generic.hpp").read_text()
    config = json.loads((WORK / parent / "candidate.json").read_text())["config"]
    for schedule in ["burst", "spread"]:
        record("stream64_batch_output_" + schedule, overlap(source, schedule), parent,
               dict(config, output_half_overlap=schedule, first_half_publication_mfma=36,
                    final_barrier_vmem_drain=True))
    parent = "stream64_rows4"
    source = (WORK / parent / "tmpl_generic.hpp").read_text()
    config = json.loads((WORK / parent / "candidate.json").read_text())["config"]
    for name, a_after, b_after, packed in [
        ("stream64_scale_early6", 6, 6, False),
        ("stream64_scale_split8_20", 8, 20, False),
        ("stream64_scale_packed6", 6, 6, True),
    ]:
        record(name, distribute_scales(source, a_after, b_after, packed), parent,
               dict(config, sfa_next_read_mfma=a_after, sfb_next_read_mfma=b_after,
                    sfa_read_pair=packed))
    for mode in ["a0", "a01", "ab"]:
        record("stream64_pin_" + mode, pin_operands(source, mode), parent,
               dict(config, operand_vgpr_pinning=mode))
