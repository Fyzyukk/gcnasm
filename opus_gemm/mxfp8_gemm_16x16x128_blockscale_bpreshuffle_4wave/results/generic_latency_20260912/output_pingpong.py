#!/usr/bin/env python3
"""Stage BF16 quadrants in two reusable LDS slots with coalesced global copies."""
from make_candidates import BASE, record, replace_n


def transform(source, pitch, xor=False):
    source = replace_n(source, "constexpr int c_lds_pitch = T::B_N + 8;",
                        f"constexpr int c_lds_pitch = {pitch};")
    source = replace_n(source,
                        "static_assert(!T::OUTPUT_BF16 || T::B_M * c_lds_pitch * sizeof(D_C) == matrix_lds_bytes);",
                        "static_assert(!T::OUTPUT_BF16 || 2 * T::HALF_B_M * c_lds_pitch * sizeof(D_C) <= matrix_lds_bytes);")
    old = """    auto c_offset = [&](int half_tile_m, int half_tile_n) {
        return half_tile_m * T::HALF_B_M * (T::OUTPUT_BF16 ? c_lds_pitch : kargs.stride_c) +
               half_tile_n * T::HALF_B_N;
    };
"""
    new = """    auto c_offset = [&](int half_tile_m, int half_tile_n) {
        if constexpr (T::OUTPUT_BF16) return half_tile_m * T::HALF_B_M * c_lds_pitch;
        else return half_tile_m * T::HALF_B_M * kargs.stride_c + half_tile_n * T::HALF_B_N;
    };
"""
    source = replace_n(source, old, new)
    start = source.index("    auto copy_output_quarter =")
    end = source.index("    const auto gc_offsets", start)
    helper = """    // C00/C10 use slot 0/1, then C01/C11 reuse slot 0/1. The existing
    // publication before copying the intervening quadrant retires all readers
    // of the reused slot; no additional workgroup barrier is needed.
    auto copy_output_quarter = [&](int half_m, int half_n, int copy_index) {
        const int linear = thread_id_x() * 8 + copy_index * T::BLOCK_SIZE * 8;
        const int local_row = linear / T::HALF_B_N;
        const int local_col = linear % T::HALF_B_N;
        const int slot_row = half_m * T::HALF_B_M + local_row;
"""
    if xor:
        helper += """        const int swizzle = (local_row & 15) * 4;
        const auto low = s_c.template load<4>(slot_row * c_lds_pitch + (local_col ^ swizzle));
        const auto high = s_c.template load<4>(slot_row * c_lds_pitch + ((local_col + 4) ^ swizzle));
"""
    elif pitch % 8:
        helper += """        const int lds_offset = slot_row * c_lds_pitch + local_col;
        const auto low = s_c.template load<4>(lds_offset);
        const auto high = s_c.template load<4>(lds_offset + 4);
"""
    else:
        helper += """        const auto value = s_c.template load<8>(slot_row * c_lds_pitch + local_col);
"""
    if xor or pitch % 8:
        helper += """        opus::vector_t<D_C, 8> value;
        opus::set_slice(value, low, opus::number<0>{}, opus::number<4>{});
        opus::set_slice(value, high, opus::number<4>{}, opus::number<8>{});
"""
    helper += """        const int output_row = local_row + half_m * T::HALF_B_M;
        const int output_col = local_col + half_n * T::HALF_B_N;
        g_c.template store<8>(value, output_row * kargs.stride_c + output_col,
                             0, opus::number<2>{});
    };

"""
    source = source[:start] + helper + source[end:]
    if xor:
        anchor = "    const auto gc_offsets = opus::layout_to_offsets<T::VEC_C>(u_gc);\n"
        base = """    opus::vector_t<int, 4> output_lds_byte_bases;
    if constexpr (T::OUTPUT_BF16) {
        const int native_row = wave_id_m * 16 + (lane_id & 15);
        const int native_col = wave_id_n * 16 + (lane_id / 16) * 4;
        const int swizzle = (native_row & 15) * 4;
        opus::static_for<4>([&](auto nr_i) {
            constexpr int nr = decltype(nr_i)::value;
            int address = (native_row * c_lds_pitch + ((native_col + nr * 32) ^ swizzle)) * sizeof(D_C);
            asm volatile("" : "+v"(address));
            output_lds_byte_bases[nr] = address;
        });
    }
"""
        source = replace_n(source, anchor, anchor + base)
        old = """            s_c.template store<T::VEC_C>(cast<D_C>(ACC),                         \\
                gc_offsets[INDEX] + soff);                                      \\
"""
        new = """            s_c.template _store<T::VEC_C>(cast<D_C>(ACC),                        \\
                output_lds_byte_bases[(INDEX) % 4]                              \\
                    + sizeof(D_C) * (soff + (INDEX) / 4 * 32 * c_lds_pitch));   \\
"""
        source = replace_n(source, old, new)
    return source


if __name__ == "__main__":
    source = (BASE / "tmpl_generic.hpp").read_text()
    for pitch, xor in ((132, False), (136, False), (128, True)):
        name = f"output_pingpong_{'xor' if xor else ''}{pitch}"
        record(name, transform(source, pitch, xor),
               dict(output_lds_scope="two_quadrant_slots", output_lds_pitch=pitch,
                    output_lds_swizzle="row_low4_xor_col_bit2" if xor else "none",
                    output_lds_read_alignment=8 if xor or pitch % 8 else 16,
                    output_global_store_bytes=16, output_slot_reuse="C00_to_C01_and_C10_to_C11"))
