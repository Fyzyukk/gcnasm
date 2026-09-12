#!/usr/bin/env python3
"""Finish A0 consumers before C10 and schedule its next-K reads earlier."""
from experiment_utils import WORK, record_candidate

PARENT = "lds_release5_k1"
parent = (WORK / PARENT / "tmpl.hpp").read_text()


def body(columns, prefetch):
    code = ["""        const int next_stage = stage ^ 1;"""]
    if prefetch:
        code += ["        const int future_tile = (tile + 2) & 63;"]
    code += ["""        __builtin_amdgcn_sched_barrier(0);
        const auto u_sa_next_0 = u_sa + sa_offset(next_stage, 0);
        const auto u_sa_next_1 = u_sa + sa_offset(next_stage, 1);
        __builtin_amdgcn_sched_barrier(0);
        const auto rb0_next_offsets = opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 0));
        const auto ra0_next_offsets = opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 0));
        const auto ra1_next_offsets = opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 1));
        const auto rb1_next_offsets = opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 1));
        const auto& v_b_n1 = v_b_second;
        __builtin_amdgcn_s_setprio(1);"""]
    c10_order = [m * 4 + n for n in range(4) for m in range(4)] if columns else list(range(16))
    c11_order = list(range(8)) + [8, 12, 9, 13, 10, 14, 11, 15]
    schedule = ([(0, 0, i) for i in range(16)] + [(0, 1, i) for i in range(16)]
                + [(1, 0, i) for i in c10_order] + [(1, 1, i) for i in c11_order])
    a_sites = {20: (0, 0), 24: (0, 1), 28: (0, 2), 32: (0, 3),
               52: (1, 0), 56: (1, 1), 63: (1, 2), 64: (1, 3)}
    b_sites = ({36: (0, 0), 40: (0, 1), 44: (0, 2), 48: (0, 3)} if columns else
               {48: (0, 0), 50: (0, 1), 52: (0, 2), 54: (0, 3)})
    b_sites.update({58: (1, 0), 60: (1, 1), 62: (1, 2), 64: (1, 3)})
    for position, (hm, hn, fragment) in enumerate(schedule, 1):
        m, n = divmod(fragment, 4)
        vb = "v_b" if hn == 0 else "v_b_n1"
        code += [f"        MXFP8_MMA_ONE({hm}, {m}, {n}, v_a[{hm}], {vb}, c{hm}{hn}_{fragment}, v_sfa, v_sfb[{hn}]);"]
        # Keep existing pair boundaries, splitting only publication and C11's tail.
        if position in [5, 6] or position >= 57:
            code += ["        __builtin_amdgcn_sched_barrier(0);"]
        elif position % 2 == 0:
            code += ["        sched_barrier_pairs_scale();"]
        if position == 5:
            code += ["""        __builtin_amdgcn_s_setprio(0);
        s_waitcnt_vmcnt(0_I);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);
        __builtin_amdgcn_s_setprio(1);"""]
        if prefetch and position in range(8, 39, 2):
            code += [f"        prefetch_matrix_issue(opus::number<{(position - 8) // 2}>{{}}, stage, future_tile);",
                     "        __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);",
                     "        __builtin_amdgcn_sched_barrier(0);"]
        requests = 0
        if position in a_sites:
            half, repeat = a_sites[position]
            code += [f"        load_a_mrepeat_scale<T, {repeat}>(s_a, ra{half}_next_offsets, v_a[{half}]);"]
            requests += 2
        if position in b_sites:
            half, repeat = b_sites[position]
            target = "v_b" if half == 0 else "v_b_second"
            code += [f"        load_b_range_scale<T, {2*repeat}, {2*repeat+2}>(s_b, rb{half}_next_offsets, {target});"]
            requests += 2
        if requests:
            code += [f"        __builtin_amdgcn_sched_group_barrier(0x100, {requests}, 0);",
                     "        __builtin_amdgcn_sched_barrier(0);"]
        if position == 32:
            code += ["        v_sfa[0] = load_sfa_dword(tile + 1, 0);",
                     "        __builtin_amdgcn_sched_barrier(0);"]
        if position == 38:
            code += ["        v_sfa1_next = load_sfa_dword(tile + 1, 1);",
                     "        __builtin_amdgcn_sched_barrier(0);"]
        if position == 48:
            code += ["""        v_sfb_next = __builtin_bit_cast(opus::vector_t<D_SF_PACK, 2>,
            load<8>(s_sfb, (tile + 1) * T::SCALE_N_HALVES * 4));
        v_sfb[0] = v_sfb_next[0];
        __builtin_amdgcn_sched_barrier(0);"""]
    code += ["""        __builtin_amdgcn_s_setprio(0);
        v_sfb[1] = v_sfb_next[1];
        v_sfa[1] = v_sfa1_next;
        stage = next_stage;"""]
    return "\n".join(code) + "\n"


for columns in [False, True]:
    start = parent.index("    for (tile = 0; tile + 2 < loops; ++tile) {")
    start = parent.index("\n", start) + 1
    end = parent.index("    }\n\n    // Consume K62", start)
    source = parent[:start] + body(columns, True) + parent[end:]
    start = source.index("    // Consume K62")
    start = source.index("    {\n", start) + len("    {\n")
    end = source.index("    }\n\n    // Consume the final", start)
    source = source[:start] + body(columns, False) + source[end:]
    name = "a_first_" + ("c10_columns" if columns else "c10_rows")
    record_candidate(name, source, dict(quadrant_order=["c00", "c01", "c10", "c11"],
                     c10_order="columns" if columns else "rows", release_mfma=5,
                     bf16_lds_epilogue=True, unified_initial_matrix_stages=[1]), PARENT)
