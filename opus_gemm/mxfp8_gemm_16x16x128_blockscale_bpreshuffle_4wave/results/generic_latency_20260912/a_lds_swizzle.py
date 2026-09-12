#!/usr/bin/env python3
"""Swizzle A's intra-row K vectors while preserving row-major global input."""
import json
from make_candidates import BASE, WORK, record, replace_n
from initial_roles import transform as initial_roles


def transform(source, mask):
    source = initial_roles(source, "split")
    begin = source.index("template<class T>\n__device__ inline auto make_layout_ra_scale(")
    end = source.index("template<class T>\n__device__ inline auto make_layout_rb_scale(", begin)
    layout = f"""template<class T>
__device__ inline auto make_layout_ra_scale(int lane_id, int wave_id_m) {{
    static_assert(T::E_M == 4 && T::E_K == 1 && T::T_M == 2);
    constexpr int pitch = T::smem_linear_wave + T::smem_padding;
    const int parity = lane_id & 1;
    const int row_pair = (lane_id & 15) / 2;
    const int swizzle = (2 * row_pair - parity) & {mask};
    const int first_k_vector = (lane_id / 16) ^ swizzle;
    const int second_k_delta = (swizzle & 4) ? -64 : 64;
    return opus::make_layout<T::VEC_A>(
        opus::make_tuple(4_I, 2_I, opus::number<T::VEC_A>{{}}),
        opus::make_tuple(opus::number<4 * pitch>{{}}, second_k_delta, 1_I),
        opus::make_tuple(opus::underscore{{}}, opus::underscore{{}}, opus::underscore{{}})) +
        (wave_id_m * 2 + parity) * pitch + row_pair * 128 + first_k_vector * 16;
}}

"""
    source = source[:begin] + layout + source[end:]
    old = """        int address = matrix_vector_offset + (issue / 2) * matrix_pair_stride
            + (issue % 2) * matrix_odd_stride - immediate;
"""
    new = old + f"""        if (produces_a) {{
            // buffer-to-LDS still writes lane*16; permute its global K source
            // so the inverse consumer map spreads neighboring rows over banks.
            const int physical_k_vector = lane_id & 7;
            const int swizzle = (2 * (lane_id / 8) - (issue & 1)) & {mask};
            const int logical_k_vector = physical_k_vector ^ swizzle;
            address += (logical_k_vector - physical_k_vector) * 16;
        }}
"""
    return replace_n(source, old, new)


if __name__ == "__main__":
    for parent in ("baseline", "output_pingpong_136"):
        directory = BASE if parent=="baseline" else WORK/parent
        original = (directory/"tmpl_generic.hpp").read_text()
        for mask in (3, 7):
            suffix = "" if parent=="baseline" else "_out136"
            cfg = json.loads((directory/"candidate.json").read_text())["config"]
            cfg.update(a_lds_k_vector_xor_mask=mask,
                       a_lds_swizzle="two_times_row_pair_minus_row_parity",
                       initial_matrix_producer="same_A_B_roles_as_main")
            record(f"a_xor{mask}{suffix}", transform(original, mask), cfg)
