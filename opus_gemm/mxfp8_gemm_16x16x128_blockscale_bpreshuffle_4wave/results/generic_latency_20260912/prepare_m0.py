#!/usr/bin/env python3
"""Separate main-loop m0 setup from matrix issue so an MFMA covers its delay."""
import sys

from make_candidates import BASE, record, replace_n


def transform(source, lead, ordered=False):
    marker = "    alignas(8) __shared__ char smem_sfa[T::SFA_PANEL_BYTES];\n"
    helper = """    opus::i32x4_t matrix_raw_rsrc;
    __builtin_memcpy(&matrix_raw_rsrc, &g_matrix.cached_rsrc, sizeof(matrix_raw_rsrc));
    auto prepare_matrix_group = [&](auto group_i, int matrix_stage) {
        constexpr int group = decltype(group_i)::value;
        auto* dst = matrix_lds_base + matrix_stage * 2 * smem_a_elem
            + group * 4 * matrix_pitch;
        const unsigned int address = static_cast<unsigned int>(reinterpret_cast<__UINTPTR_TYPE__>(dst));
        asm volatile("s_mov_b32 m0, %0" : : "s"(address) : "m0", "memory");
    };
    auto issue_matrix_prepared = [&](auto issue_i, int scalar_offset) {
        constexpr int issue = decltype(issue_i)::value;
        constexpr int immediate = (issue % 4) * matrix_pitch;
        // The preceding prepare and the load both declare m0 to preserve order.
        // Every matrix publication retains explicit VMEM/LGKM retirement.
        asm volatile("buffer_load_dwordx4 %0, %1, %2 offen offset:%3 lds"
            : : "v"(matrix_addresses[issue]), "s"(matrix_raw_rsrc),
                "s"(scalar_offset), "n"(immediate) : "m0", "memory");
    };

"""
    source = replace_n(source, marker, helper + marker)
    start = source.index("    for (tile = 0; tile + 2 < loops; ++tile) {")
    end = source.index("    // Penultimate runtime K128 block", start)
    body = source[start:end]
    body = replace_n(body, "        const int future_tile = tile + 2;\n", """        const int future_tile = tile + 2;
        int future_matrix_offset = future_tile * matrix_k_stride;
        asm volatile("" : "+s"(future_matrix_offset));
""")
    for issue in range(16):
        body = replace_n(body, f"prefetch_matrix_issue(opus::number<{issue}>{{}}, stage, future_tile);",
                         f"issue_matrix_prepared(opus::number<{issue}>{{}}, future_matrix_offset);")
    # The first request of each group is after MFMA7/15/23/31. The named
    # fragments provide exact points one or two MFMAs earlier.
    fragments = (["c00_5", "c00_13", "c10_5", "c10_13"] if lead == 1 else
                 ["c00_4", "c00_12", "c10_4", "c10_12"])
    for group, fragment in enumerate(fragments):
        lines = body.splitlines(True)
        matches = [i for i, line in enumerate(lines) if "MXFP8_MMA_ONE(" in line and fragment + "," in line]
        assert len(matches) == 1, (fragment, matches)
        index = matches[0]
        assert "__builtin_amdgcn_sched_barrier(0);" in lines[index+1]
        # For the first group with lead2, put setup after the release barrier.
        if group == 0 and lead == 2:
            index = next(i for i in range(index, len(lines)) if "__builtin_amdgcn_s_barrier();" in lines[i])
        insertion = index + 2
        if group > 0 and lead == 2 and ordered:
            # The last request of the previous group shares this MFMA site.
            # Its old m0 must remain live until that request has issued.
            previous_issue = group * 4 - 1
            insertion = next(i for i,line in enumerate(lines)
                             if f"issue_matrix_prepared(opus::number<{previous_issue}>{{}}" in line) + 3
        lines.insert(insertion, f"        prepare_matrix_group(opus::number<{group}>{{}}, stage);\n        __builtin_amdgcn_sched_barrier(0);\n")
        body = "".join(lines)
    return source[:start] + body + source[end:]


if __name__ == "__main__":
    for value in sys.argv[1:]:
        ordered = value.endswith("fixed")
        lead = int(value.removesuffix("fixed"))
        record(f"prepare_m0_lead{value}", transform((BASE / "tmpl_generic.hpp").read_text(), lead, ordered),
               dict(main_matrix_issue="explicit_m0_and_MUBUF", m0_setup_mfmas_before_request=lead,
                    future_matrix_soffset="materialized_before_main_MFMA",
                    preserve_prior_group_m0=ordered or lead==1))
