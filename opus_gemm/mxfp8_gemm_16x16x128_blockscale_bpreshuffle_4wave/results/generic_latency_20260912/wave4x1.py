#!/usr/bin/env python3
"""Test four M waves within the same 256x256 output tile, with generic K."""
import re
import sys

from make_candidates import BASE, record, replace_n


def replace_function(source, name, text):
    start = source.index("template<class T>\n__device__ inline auto " + name)
    end = source.index("\n}\n", start) + len("\n}\n")
    return source[:start] + text + source[end:]


def source_prefix(source):
    # Keep the proven physical producer layout. Producer ownership remains
    # two A waves/two B waves even though consumers now partition M four ways.
    for name in ["make_layout_ga_scale", "make_layout_sa_scale", "make_layout_gb_scale", "make_layout_sb_scale"]:
        start = source.index("template<class T>\n__device__ inline auto " + name)
        end = source.index("\n}\n", start) + len("\n}\n")
        body = source[start:end]
        body = body.replace("static_assert(T::T_M == 2 && T::T_N == 2);", "static_assert(T::NUM_WAVES == 4);")
        body = body.replace("T::T_M", "2").replace("T::T_N", "2")
        source = source[:start] + body + source[end:]
    source = replace_function(source, "make_layout_ra_scale", """template<class T>
__device__ inline auto make_layout_ra_scale(int lane_id, int wave_id_m) {
    constexpr int pitch = T::smem_linear_wave + T::smem_padding;
    const int lane_row = lane_id % T::W_M;
    // Invert the unchanged paired-row producer image for an M-partitioned wave.
    return opus::make_layout<T::VEC_A>(
        opus::make_tuple(opus::number<T::E_M>{}, 2_I, opus::number<T::VEC_A>{}),
        opus::make_tuple(opus::number<T::T_M * 2 * pitch>{}, 64_I, 1_I),
        opus::make_tuple(opus::underscore{}, opus::underscore{}, opus::underscore{}))
        + wave_id_m * 2 * pitch + (lane_row % 2) * pitch
        + (lane_row / 2) * T::B_K + (lane_id / T::W_M) * 16;
}
""")
    source = replace_function(source, "make_layout_rb_scale", """template<class T>
__device__ inline auto make_layout_rb_scale(int lane_id, int wave_id_n) {
    constexpr int pitch = T::smem_linear_wave + T::smem_padding;
    return opus::make_layout<T::VEC_B>(
        opus::make_tuple(opus::number<T::E_N>{}, 2_I, opus::number<T::VEC_B>{}),
        opus::make_tuple(opus::number<T::T_N * 2 * pitch>{}, opus::number<pitch>{}, 1_I),
        opus::make_tuple(opus::underscore{}, opus::underscore{}, opus::underscore{}))
        + 2 * wave_id_n * pitch + lane_id * T::VEC_B;
}
""")
    for name in ["ga", "sa", "gb", "sb"]:
        # Only producer calls receive the fixed physical 2x2 coordinates.
        source = source.replace(f"make_layout_{name}_scale<T>(lane_id, wave_id_m, wave_id_n",
                                f"make_layout_{name}_scale<T>(lane_id, wave_id % 2, wave_id / 2")
        source = source.replace(f"make_layout_{name}_scale<T>(wave_id_m, wave_id_n)",
                                f"make_layout_{name}_scale<T>(wave_id % 2, wave_id / 2)")
    start = source.index("    const bool produces_a =")
    end = source.index("    alignas(8) __shared__ char smem_sfa", start)
    body = source[start:end].replace("wave_id_m", "producer_half")
    body = replace_n(body, "    const bool produces_a = wave_id_n == 0;",
                     "    const int producer_half = wave_id % 2;\n    const bool produces_a = wave_id < 2;")
    source = source[:start] + body + source[end:]

    source = source.replace("T::E_M == 4", "T::E_M == 2")
    source = replace_n(source, "constexpr int scale_op_sel_a = M_REPEAT;",
                       "constexpr int scale_op_sel_a = HALF_TILE_M * T::E_M + M_REPEAT;")
    source = replace_n(source, "opus::number<N_REPEAT>{});", "opus::number<N_REPEAT % 4>{});")
    source = replace_n(source, """        const int source_row = (owner_wave / T::T_M) * T::HALF_B_M +
            (owner_wave % T::T_M) * T::W_M + call * T::T_M * T::W_M;""",
        "        const int source_row = owner_wave * T::W_M + call * T::T_M * T::W_M;")
    source = replace_n(source, """                const int dst = k_column * T::SFA_PANEL_PITCH
                    + ((owner_wave % T::T_M) * T::W_M + output_row) * 8
                    + (owner_wave / T::T_M) * 4;""", """                const int dst = k_column * T::SFA_PANEL_PITCH
                    + (owner_wave * T::W_M + output_row) * 4;""")
    source = replace_n(source, """        const int addr = (k_tile & panel_mask) * T::SFA_PANEL_PITCH
            + (wave_id_m * T::W_M + (lane_id & 15)) * 8 + half_tile_m * 4;""", """        (void)half_tile_m;
        const int addr = (k_tile & panel_mask) * T::SFA_PANEL_PITCH
            + (wave_id_m * T::W_M + (lane_id & 15)) * 4;""")
    source = replace_n(source, "    v_sfa[1] = load_sfa_dword(0, 1);", "    v_sfa[1] = v_sfa[0];")
    return source


def iteration(main_loop):
    lines = ["        refill_scale_panel(tile + 1);",
             "        const int next_stage = stage ^ 1;"]
    if main_loop:
        lines.append("        const int future_tile = tile + 2;")
    lines += ["        __builtin_amdgcn_sched_barrier(0);"]
    for operand, layout, offset in [("ra0", "u_ra", "sa_offset(next_stage, 0)"),
                                    ("ra1", "u_ra", "sa_offset(next_stage, 1)"),
                                    ("rb0", "u_rb", "sb_offset(next_stage, 0)"),
                                    ("rb1", "u_rb", "sb_offset(next_stage, 1)")]:
        vec = "A" if operand.startswith("ra") else "B"
        lines.append(f"        const auto {operand}_next_offsets = opus::layout_to_offsets<T::VEC_{vec}>({layout} + {offset});")
    lines.append("        __builtin_amdgcn_sched_barrier(0);")
    sites = list(range(7, 38, 2)) if main_loop else []
    events = set(sites) | {2, 5, 20, 32, 34, 36, 38, 40, 42, 44, 46, 48, 56, 57, 58, 59, 60, 61, 62, 63, 64}
    count = 0
    for hm, hn in [(0, 0), (1, 0), (0, 1), (1, 1)]:
        index = 0
        vb = "v_b_second" if hn else "v_b"
        while index < 16:
            pair = count + 1 not in events and index % 2 == 0
            mr, nr = divmod(index, 8)
            if pair:
                lines.append(f"        MXFP8_MMA_PAIR({hm}, {mr}, {nr // 2}, v_a[{hm}], {vb}, c{hm}{hn}_{index}, c{hm}{hn}_{index+1}, v_sfa, v_sfb[{hn}]);")
                lines.append("        sched_barrier_pairs_scale();")
                count += 2
                index += 2
            else:
                lines.append(f"        MXFP8_MMA_ONE({hm}, {mr}, {nr}, v_a[{hm}], {vb}, c{hm}{hn}_{index}, v_sfa, v_sfb[{hn}]);")
                lines.append("        __builtin_amdgcn_sched_barrier(0);")
                count += 1
                index += 1
            if count == 2:
                lines += ["        v_sfa_next[0] = load_sfa_dword(tile + 1, 0);",
                          "        __builtin_amdgcn_sched_barrier(0);"]
            if count == 5:
                lines += ["        s_waitcnt_vmcnt(0_I);", "        s_waitcnt_lgkmcnt(0_I);",
                          "        __builtin_amdgcn_s_barrier();", "        __builtin_amdgcn_sched_barrier(0);"]
            if count == 20:
                lines += ["        v_sfb_next = __builtin_bit_cast(opus::vector_t<D_SF_PACK, 2>,",
                          "            load<8>(s_sfb, ((tile + 1) & panel_mask) * T::SCALE_N_HALVES * 4));",
                          "        __builtin_amdgcn_sched_barrier(0);"]
            if count in sites:
                lines += [f"        prefetch_matrix_issue(opus::number<{sites.index(count)}>{{}}, stage, future_tile);",
                          "        __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);",
                          "        __builtin_amdgcn_sched_barrier(0);"]
            if count in range(32, 47, 2):
                begin = count - 32
                lines += [f"        load_b_range_scale<T, {begin}, {begin+2}>(s_b, rb0_next_offsets, v_b);",
                          "        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);",
                          "        __builtin_amdgcn_sched_barrier(0);"]
            if count == 32:
                lines.append("        v_sfb[0] = v_sfb_next[0];")
            if count in [40, 48, 56, 64]:
                half = int(count >= 56)
                repeat = int(count in [48, 64])
                lines += [f"        load_a_mrepeat_scale<T, {repeat}>(s_a, ra{half}_next_offsets, v_a[{half}]);",
                          "        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);",
                          "        __builtin_amdgcn_sched_barrier(0);"]
            if count >= 57:
                begin = (count - 57) * 2
                lines += [f"        load_b_range_scale<T, {begin}, {begin+2}>(s_b, rb1_next_offsets, v_b_second);",
                          "        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);",
                          "        __builtin_amdgcn_sched_barrier(0);"]
    assert count == 64
    lines += ["        v_sfa[0] = v_sfa_next[0];", "        v_sfa[1] = v_sfa_next[0];",
              "        v_sfb[1] = v_sfb_next[1];", "        stage = next_stage;"]
    return "\n".join(lines) + "\n"


def transform(source, unroll):
    start = source.index("    // Prefetch while two later K128 blocks exist;")
    end = source.index("    // Consume the final resident tile", start)
    prefix = source_prefix(source[:start])
    loops = f"""    // All four waves partition M inside this workgroup's single output tile.
    __builtin_amdgcn_s_setprio(1);
#pragma unroll {unroll}
    for (tile = 0; tile + 2 < loops; ++tile) {{
""" + iteration(True) + "    }\n\n"
    loops += "    // Roll the final K block without an unused future request.\n    if (loops > 1) {\n" + iteration(False) + "    }\n\n"
    tail = source[end:]
    pattern = re.compile(r"    MXFP8_MMA_PAIR\(([^;]+)\);", re.MULTILINE)
    def remap(match):
        args = [x.strip() for x in match[1].split(",")]
        assert len(args) == 9
        index = int(args[5].rsplit("_", 1)[1])
        assert int(args[6].rsplit("_", 1)[1]) == index + 1
        args[1], args[2] = str(index // 8), str(index % 8 // 2)
        return "    MXFP8_MMA_PAIR(" + ", ".join(args) + ");"
    tail, count = pattern.subn(remap, tail)
    assert count == 32
    return prefix + loops + tail


def private_output(source):
    start = source.index("    auto c_offset =")
    end = source.index("    const auto gc_offsets =", start)
    source = source[:start] + """    constexpr int wave_output_rows = T::B_M / T::T_M;
    constexpr int wave_half_rows = T::HALF_B_M / T::T_M;
    static_assert(T::T_M == 4 && T::T_N == 1);
    // Each wave owns full output columns and a private padded LDS image.
    const int wave_c_lds_base = wave_id * wave_output_rows * c_lds_pitch
        + (lane_id % 16) * c_lds_pitch + (lane_id / 16) * T::VEC_C;
    auto c_offset = [&](int half_m, int half_n) {
        return half_m * (T::OUTPUT_BF16 ? wave_half_rows * c_lds_pitch
                                        : T::HALF_B_M * kargs.stride_c)
             + half_n * T::HALF_B_N;
    };
    auto copy_output_quarter = [&](int half_m, int half_n, int copy_index) {
        const int linear = lane_id * 8 + copy_index * T::WARP_SIZE * 8;
        const int local_row = linear / T::HALF_B_N + half_m * wave_half_rows;
        const int local_col = linear % T::HALF_B_N + half_n * T::HALF_B_N;
        const auto value = s_c.template load<8>(
            wave_id * wave_output_rows * c_lds_pitch + local_row * c_lds_pitch + local_col);
        const int output_row = (local_row / T::W_M) * T::T_M * T::W_M
            + wave_id_m * T::W_M + local_row % T::W_M;
        g_c.template store<8>(value, output_row * kargs.stride_c + local_col,
                             0, opus::number<2>{});
    };

""" + source[end:]
    old = """            s_c.template store<T::VEC_C>(cast<D_C>(ACC),                         \\
                gc_offsets[INDEX] + soff);                                      \\
"""
    new = """            s_c.template store<T::VEC_C>(cast<D_C>(ACC),                         \\
                wave_c_lds_base + (INDEX) / T::E_N * T::W_M * c_lds_pitch        \\
                + (INDEX) % T::E_N * T::W_N + soff);                            \\
"""
    source = replace_n(source, old, new)
    # Keep the workgroup-wide retirement before matrix LDS is first reused.
    # All subsequent C reads/writes stay inside the same wave's allocation.
    begin = source.index("    MXFP8_MMA_PAIR", source.index("#define MXFP8_STORE_QUADRANT"))
    tail = source[begin:]
    tail = replace_n(tail, "        __builtin_amdgcn_s_barrier();\n", "", 4)
    tail = replace_n(tail, "        s_waitcnt_vmcnt(0_I);\n", "", 3)
    return source[:begin] + tail


def main():
    for arg in sys.argv[1:]:
        private = arg.startswith("private")
        unroll = int(arg.removeprefix("private"))
        source = transform((BASE / "tmpl_generic.hpp").read_text(), unroll)
        if private:
            source = private_output(source)
        traits = (BASE / "traits.hpp").read_text()
        traits = replace_n(traits, "static constexpr int T_M = 2;", "static constexpr int T_M = 4;")
        traits = replace_n(traits, "static constexpr int T_N = 2;", "static constexpr int T_N = 1;")
        traits = replace_n(traits, "static_assert(E_M == 4 && E_N == 4 && E_K == 1);", "static_assert(E_M == 2 && E_N == 8 && E_K == 1);")
        traits = replace_n(traits, "static_assert(a_ds_read_insts == 8 && b_ds_read_insts == 8);", "static_assert(a_ds_read_insts == 4 && b_ds_read_insts == 16);")
        config = dict(unroll=unroll, wave_partition=[4,1], repeats_per_quarter=[2,8],
                    sfa_pack="four_M_repeats_across_both_halves", sfa_read_pair=False,
                    a0_m0_prefetch_mfma=None, a0_m0_install_mfma=40,
                    operand_roll="A0_after40_48_A1_after56_64_B0_after32to46_B1_after57to64")
        if private:
            config.update(output_lds_scope="wave_private",output_wave_pitch=264,
                          output_lds_read_alignment=16,output_quarter_barriers=0,
                          output_barriers_without_vmem_drain=[])
        record(f"wave4x1_{'private_' if private else ''}u{unroll}", source, config,
               support_changes={"traits.hpp": traits})


if __name__ == "__main__":
    main()
