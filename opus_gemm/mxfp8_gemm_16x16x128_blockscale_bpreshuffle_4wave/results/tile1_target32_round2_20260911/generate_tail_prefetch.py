#!/usr/bin/env python3
"""Read the final A1/B1 slices before their old values reach last use."""
from experiment_utils import WORK, record_candidate

PARENT = "lds_release5_k1"
parent = (WORK / PARENT / "tmpl.hpp").read_text()
configs = [(["a"], 56), (["b"], 56), (["a", "b"], 56), (["a", "b"], 48)]
for operands, site in configs:
    source = parent
    reads = []
    for operand in operands:
        prefix, memory, offsets, vector = (
            ("a1_m3", "s_a", "ra1_next_offsets", "v_a[1]") if operand == "a" else
            ("b1_n3", "s_b", "rb1_next_offsets", "v_b_second"))
        for half in range(2):
            reads.append(f"        auto {prefix}_next_{half} = {memory}.template load<16>({offsets}[{6 + half}]);")
        old = ("        load_a_mrepeat_scale<T, 3>(s_a, ra1_next_offsets, v_a[1]);" if operand == "a" else
               "        load_b_range_scale<T, 6, 8>(s_b, rb1_next_offsets, v_b_second);")
        replacement = "\n".join(
            f"        opus::set_slice({vector}, {prefix}_next_{half}, opus::number<{96 + half * 16}>{{}}, opus::number<{112 + half * 16}>{{}});"
            for half in range(2))
        assert source.count(old) == 2
        source = source.replace(old, replacement)
    prefetch = (f"        // MFMA{site}: preload the final operand slices into independent registers.\n"
                + "\n".join(reads)
                + f"\n        __builtin_amdgcn_sched_group_barrier(0x100, {len(reads)}, 0);\n"
                + "        __builtin_amdgcn_sched_barrier(0);\n\n")
    if site == 48:
        marker = "        // C11: reorder independent accumulators and roll each operand after its last use."
    else:
        marker = "        MXFP8_MMA_ONE(1, 2, 0, v_a[1], v_b_n1, c11_8, v_sfa, v_sfb[1]);"
    assert source.count(marker) == 2
    source = source.replace(marker, prefetch + marker)
    name = "tail_" + "".join(operands) + f"3_prefetch{site}"
    record_candidate(name, source, dict(tail_operand_prefetch=operands,
                     prefetch_site=site, extra_operand_vgprs=len(operands) * 8,
                     bf16_lds_epilogue=True, release_mfma=5,
                     unified_initial_matrix_stages=[1]), PARENT)
