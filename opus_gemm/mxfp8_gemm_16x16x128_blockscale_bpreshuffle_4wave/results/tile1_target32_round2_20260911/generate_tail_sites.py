#!/usr/bin/env python3
"""Tune the lead distance and stagger the last matrix operand reads."""
from collections import defaultdict
from experiment_utils import WORK, record_candidate

PARENT = "lds_release5_k1"
parent = (WORK / PARENT / "tmpl.hpp").read_text()
markers = {
    52: "        MXFP8_MMA_PAIR(1, 1, 0, v_a[1], v_b_n1, c11_4, c11_5, v_sfa, v_sfb[1]);",
    54: "        MXFP8_MMA_PAIR(1, 1, 1, v_a[1], v_b_n1, c11_6, c11_7, v_sfa, v_sfb[1]);",
    56: "        MXFP8_MMA_ONE(1, 2, 0, v_a[1], v_b_n1, c11_8, v_sfa, v_sfb[1]);",
    58: "        MXFP8_MMA_ONE(1, 2, 1, v_a[1], v_b_n1, c11_9, v_sfa, v_sfb[1]);",
    60: "        MXFP8_MMA_ONE(1, 2, 2, v_a[1], v_b_n1, c11_10, v_sfa, v_sfb[1]);",
    62: "        MXFP8_MMA_ONE(1, 2, 3, v_a[1], v_b_n1, c11_11, v_sfa, v_sfb[1]);",
}
configs = {
    **{f"tail_a3_prefetch{site}": [("a", 3, site)] for site in [52, 54, 58, 60]},
    "tail_b3_prefetch60": [("b", 3, 60)],
    "tail_a3_56_b3_60": [("a", 3, 56), ("b", 3, 60)],
    "tail_a2_54_a3_56": [("a", 2, 54), ("a", 3, 56)],
    "tail_a3_56_b2_58": [("a", 3, 56), ("b", 2, 58)],
}
for name, requests in configs.items():
    source = parent
    pending = defaultdict(list)
    for operand, repeat, site in requests:
        prefix, memory, offsets, vector = (
            (f"a1_m{repeat}", "s_a", "ra1_next_offsets", "v_a[1]") if operand == "a" else
            (f"b1_n{repeat}", "s_b", "rb1_next_offsets", "v_b_second"))
        for half in range(2):
            pending[site].append(f"        auto {prefix}_next_{half} = {memory}.template load<16>({offsets}[{repeat*2 + half}]);")
        old = (f"        load_a_mrepeat_scale<T, {repeat}>(s_a, ra1_next_offsets, v_a[1]);" if operand == "a" else
               f"        load_b_range_scale<T, {repeat*2}, {repeat*2+2}>(s_b, rb1_next_offsets, v_b_second);")
        replacement = "\n".join(
            f"        opus::set_slice({vector}, {prefix}_next_{half}, opus::number<{repeat*32 + half*16}>{{}}, opus::number<{repeat*32 + (half+1)*16}>{{}});"
            for half in range(2))
        assert source.count(old) == 2
        source = source.replace(old, replacement)
    for site, reads in sorted(pending.items()):
        prefetch = (f"        // MFMA{site}: preload the final operand slices into independent registers.\n"
                    + "\n".join(reads)
                    + f"\n        __builtin_amdgcn_sched_group_barrier(0x100, {len(reads)}, 0);\n"
                    + "        __builtin_amdgcn_sched_barrier(0);\n\n")
        marker = markers[site]
        assert source.count(marker) == 2
        source = source.replace(marker, prefetch + marker)
    record_candidate(name, source, dict(tail_prefetch_schedule=requests,
                     bf16_lds_epilogue=True, release_mfma=5,
                     unified_initial_matrix_stages=[1]), PARENT)
