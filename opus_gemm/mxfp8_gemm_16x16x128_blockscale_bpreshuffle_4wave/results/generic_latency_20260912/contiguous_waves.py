#!/usr/bin/env python3
"""Keep four waves/tile1 and assign contiguous 64x64 regions in each quarter."""
from make_candidates import BASE, record, replace_n
from wave4x1 import replace_function


def transform(source):
    source = replace_function(source, "make_layout_ra_scale", """template<class T>
__device__ inline auto make_layout_ra_scale(int lane_id, int wave_id_m) {
    static_assert(T::E_M == 4 && T::T_M == 2 && T::E_K == 1);
    constexpr int pitch = T::smem_linear_wave + T::smem_padding;
    const int lane_row = lane_id & 15;
    // Global row in this M128 half: wave_m*64 + repeat*16 + lane_row.
    // Producers retain their original paired-row LDS layout.
    return opus::make_layout<T::VEC_A>(
        opus::make_tuple(4_I, 2_I, opus::number<T::VEC_A>{}),
        opus::make_tuple(opus::number<2 * pitch>{}, 64_I, 1_I),
        opus::make_tuple(opus::underscore{}, opus::underscore{}, opus::underscore{}))
        + wave_id_m * 8 * pitch + (lane_row & 1) * pitch
        + (lane_row / 2) * 128 + (lane_id / 16) * 16;
}
""")
    source = replace_function(source, "make_layout_rb_scale", """template<class T>
__device__ inline auto make_layout_rb_scale(int lane_id, int wave_id_n) {
    static_assert(T::E_N == 4 && T::T_N == 2 && T::E_K == 1);
    constexpr int pitch = T::smem_linear_wave + T::smem_padding;
    // Global column in this N128 half: wave_n*64 + repeat*16 + lane%16.
    return opus::make_layout<T::VEC_B>(
        opus::make_tuple(4_I, 2_I, opus::number<T::VEC_B>{}),
        opus::make_tuple(opus::number<2 * pitch>{}, opus::number<pitch>{}, 1_I),
        opus::make_tuple(opus::underscore{}, opus::underscore{}, opus::underscore{}))
        + wave_id_n * 8 * pitch + lane_id * 16;
}
""")
    source = replace_n(source, """        const int source_row = (owner_wave / T::T_M) * T::HALF_B_M +
            (owner_wave % T::T_M) * T::W_M + call * T::T_M * T::W_M;""", """        const int source_row = (owner_wave / T::T_M) * T::HALF_B_M +
            (owner_wave % T::T_M) * 64 + call * T::W_M;""")
    old = """    auto p_coord_c = opus::make_tuple(
        wave_id_m, lane_id % mma.grpn_c,
        wave_id_n, lane_id / mma.grpn_c);
    auto u_gc = partition_layout_c<T::VEC_C>(
        mma, opus::make_tuple(T::OUTPUT_BF16 ? c_lds_pitch : kargs.stride_c, 1_I), p_coord_c);
"""
    new = """    const int native_row = wave_id_m * 64 + (lane_id & 15);
    const int native_col = wave_id_n * 64 + (lane_id / 16) * 4;
    const int output_stride = T::OUTPUT_BF16 ? c_lds_pitch : kargs.stride_c;
    auto u_gc = opus::make_layout<T::VEC_C>(
        opus::make_tuple(4_I, 4_I, opus::number<T::VEC_C>{}),
        opus::make_tuple(16 * output_stride, 16_I, 1_I),
        opus::make_tuple(opus::underscore{}, opus::underscore{}, opus::underscore{}))
        + native_row * output_stride + native_col;
"""
    return replace_n(source, old, new)


def private_output(source, pitch):
    source = replace_n(source, "constexpr int c_lds_pitch = T::B_N + 8;",
                        f"constexpr int c_lds_pitch = {pitch};")
    source = replace_n(source,
        "static_assert(!T::OUTPUT_BF16 || T::B_M * c_lds_pitch * sizeof(D_C) == matrix_lds_bytes);",
        "static_assert(!T::OUTPUT_BF16 || 4 * 128 * c_lds_pitch * sizeof(D_C) <= matrix_lds_bytes);")
    start = source.index("    auto c_offset =")
    end = source.index("    const auto gc_offsets =", start)
    helper = """    // Each wave owns two padded 64x64 output slots. C00/C10 use slot 0/1,
    // and C01/C11 reuse them after intervening LDS-reader retirement.
    const int wave_output_base = wave_id * 128 * c_lds_pitch;
    auto c_offset = [&](int half_m, int half_n) {
        if constexpr (T::OUTPUT_BF16) return half_m * 64 * c_lds_pitch;
        else return half_m * 128 * kargs.stride_c + half_n * 128;
    };
    auto copy_output_quarter = [&](int half_m, int half_n, int copy_index) {
        const int linear = lane_id * 8 + copy_index * 64 * 8;
        const int local_row = linear / 64;
        const int local_col = linear % 64;
        const int address = wave_output_base + (half_m * 64 + local_row) * c_lds_pitch + local_col;
"""
    if pitch % 8:
        helper += """        opus::vector_t<D_C, 8> value;
        opus::set_slice(value, s_c.template load<4>(address), opus::number<0>{}, opus::number<4>{});
        opus::set_slice(value, s_c.template load<4>(address + 4), opus::number<4>{}, opus::number<8>{});
"""
    else:
        helper += "        const auto value = s_c.template load<8>(address);\n"
    helper += """        const int output_row = half_m * 128 + wave_id_m * 64 + local_row;
        const int output_col = half_n * 128 + wave_id_n * 64 + local_col;
        g_c.template store<8>(value, output_row * kargs.stride_c + output_col,
                             0, opus::number<2>{});
    };

"""
    source = source[:start] + helper + source[end:]
    anchor = "    const auto gc_offsets = opus::layout_to_offsets<T::VEC_C>(u_gc);\n"
    source = replace_n(source, anchor, anchor + """    int output_lds_byte_base = 0;
    if constexpr (T::OUTPUT_BF16) {
        output_lds_byte_base = (wave_output_base + (lane_id & 15) * c_lds_pitch + (lane_id / 16) * 4) * sizeof(D_C);
        asm volatile("" : "+v"(output_lds_byte_base));
    }
""")
    old = """            s_c.template store<T::VEC_C>(cast<D_C>(ACC),                         \\
                gc_offsets[INDEX] + soff);                                      \\
"""
    new = """            s_c.template _store<T::VEC_C>(cast<D_C>(ACC),                        \\
                output_lds_byte_base + sizeof(D_C) * (soff                     \\
                    + (INDEX) / 4 * 16 * c_lds_pitch + (INDEX) % 4 * 16));      \\
"""
    source = replace_n(source, old, new)
    start = source.index("    MXFP8_MMA_PAIR", source.index("#define MXFP8_STORE_QUADRANT"))
    tail = source[start:]
    tail = replace_n(tail, "        __builtin_amdgcn_s_barrier();\n", "", 4)
    tail = replace_n(tail, "        s_waitcnt_vmcnt(0_I);\n", "", 3)
    return source[:start] + tail


if __name__ == "__main__":
    source = transform((BASE / "tmpl_generic.hpp").read_text())
    config = dict(wave_partition=[2, 2], wave_quarter_geometry=[64, 64],
                  wave_quarter_coordinates="contiguous", matrix_producers="unchanged",
                  sfa_repeat_rows=16)
    record("contiguous_waves", source, config)
    for pitch in (68, 72):
        cfg = dict(config, output_lds_scope="wave_private", output_wave_pitch=pitch,
                   output_lds_read_alignment=8 if pitch % 8 else 16,
                   output_quarter_barriers=0, output_barriers_without_vmem_drain=[],
                   output_slot_reuse="C00_to_C01_and_C10_to_C11")
        record(f"contiguous_waves_private{pitch}", private_output(source, pitch), cfg)
