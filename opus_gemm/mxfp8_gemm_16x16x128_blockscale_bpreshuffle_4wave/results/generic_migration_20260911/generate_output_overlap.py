#!/usr/bin/env python3
"""Overlap generic final-K compute with coalesced BF16 output-half copies."""
import re

from generate_streaming import WORK, once, record


def overlap(source, schedule):
    prefix, tail = source.split("    // Consume the final resident tile", 1)
    definition = """    // Each half covers all output rows and 128 contiguous columns.
    // The first half is published before its copy overlaps second-half MFMAs.
    auto copy_output_half = [&](int half_n, int copy_index) {
        const int linear = thread_id_x() * 8 + copy_index * T::BLOCK_SIZE * 8;
        const int output_row = linear / T::HALF_B_N;
        const int output_col = linear % T::HALF_B_N + half_n * T::HALF_B_N;
        const auto value = s_c.template load<8>(output_row * c_lds_pitch + output_col);
        g_c.template store<8>(value, output_row * kargs.stride_c + output_col,
                             0, opus::number<2>{});
    };

"""
    tail = once(tail, "    const auto gc_offsets =", definition + "    const auto gc_offsets =")
    boundary = """        MXFP8_STORE_AGPR_PAIR8(c10_12, c10_13, 12);
        MXFP8_STORE_AGPR_PAIR8(c10_14, c10_15, 14);
    }
"""
    publication = """
    if constexpr (T::OUTPUT_BF16) {
        // All first-half rows are complete; the second half is disjoint.
        __builtin_amdgcn_sched_barrier(0);
        s_waitcnt_vmcnt(0_I);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);
INITIAL_COPIES
    }
"""
    count = 2 if schedule == "spread" else 16
    publication = publication.replace("INITIAL_COPIES", "\n".join(
        f"        copy_output_half(0, {i});" for i in range(count)))
    before, after = tail.split(boundary)
    if schedule == "spread":
        pattern = r"(    MXFP8_MMA_PAIR\([^\n]+;\n    sched_barrier_pairs_scale\(\);\n)"
        issue = 2

        def insert_copy(match):
            nonlocal issue
            text = match[0] + "\n    if constexpr (T::OUTPUT_BF16) {\n"
            text += f"        copy_output_half(0, {issue});\n    }}\n"
            issue += 1
            return text

        after, matches = re.subn(pattern, insert_copy, after)
        assert matches == 14 and issue == 16
    tail = before + boundary + publication + after
    final_copy = """        opus::static_for<T::B_M * T::B_N / (T::BLOCK_SIZE * 8)>([&](auto copy_i) {
            const int linear = thread_id_x() * 8 + decltype(copy_i)::value * T::BLOCK_SIZE * 8;
            const int output_row = linear / T::B_N;
            const int output_col = linear % T::B_N;
            const auto value = s_c.template load<8>(output_row * c_lds_pitch + output_col);
            g_c.template store<8>(value, output_row * kargs.stride_c + output_col,
                                  0, opus::number<2>{});
        });"""
    tail = once(tail, final_copy, """        opus::static_for<T::B_M * T::HALF_B_N / (T::BLOCK_SIZE * 8)>([&](auto copy_i) {
            copy_output_half(1, decltype(copy_i)::value);
        });""")
    tail = once(tail, """        // Publish the complete output, then write contiguous rows per wave.
        __builtin_amdgcn_sched_barrier(0);
        s_waitcnt_lgkmcnt(0_I);""", """        // Retire first-half copies and publish the remaining output half.
        __builtin_amdgcn_sched_barrier(0);
        s_waitcnt_vmcnt(0_I);
        s_waitcnt_lgkmcnt(0_I);""")
    return prefix + "    // Consume the final resident tile" + tail


if __name__ == "__main__":
    parent = "stream64_rows4"
    source = (WORK / parent / "tmpl_generic.hpp").read_text()
    for schedule in ("spread", "burst"):
        record("stream64_output_" + schedule, overlap(source, schedule), parent,
               dict(scale_panel_tiles=64, unroll=8, lds_output=True,
                    output_half_overlap=schedule, first_half_publication_mfma=36,
                    final_barrier_vmem_drain=True))
