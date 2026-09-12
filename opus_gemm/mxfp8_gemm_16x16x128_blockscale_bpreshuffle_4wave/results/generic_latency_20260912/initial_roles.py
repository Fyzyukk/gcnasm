#!/usr/bin/env python3
"""Use the verified A/B role producer in K0 and vary its startup overlap."""
from make_candidates import BASE, WORK, grouped_grid, record, replace_n


def group(begin, end):
    return "\n".join(f"    prefetch_matrix_issue(opus::number<{i}>{{}}, 0, 0);" for i in range(begin, end)) + "\n"


def transform(source, kind):
    first = """    async_load<T::VEC_A>(g_a, s_a.ptr, u_ga, u_sa + sa_offset(0, 0), ga_offset(0, 0));
    async_load<T::VEC_A>(g_a, s_a.ptr, u_ga, u_sa + sa_offset(0, 1), ga_offset(1, 0));
"""
    second = """    async_load<T::VEC_B>(g_b, s_b.ptr, u_gb, u_sb + sb_offset(0, 0), gb_offset(0, 0));
    async_load<T::VEC_B>(g_b, s_b.ptr, u_gb, u_sb + sb_offset(0, 1), gb_offset(1, 0));
"""
    if kind == "split":
        source = replace_n(source, first, group(0, 8))
        source = replace_n(source, second, group(8, 16))
    elif kind == "early":
        source = replace_n(source, first, group(0, 16))
        source = replace_n(source, second, "")
    elif kind == "quads":
        source = replace_n(source, first, group(0, 4))
        source = replace_n(source, second, group(8, 12))
        source = replace_n(source, "    MXFP8_MATERIALIZE_C_QUADRANT(c00);\n",
                            "    MXFP8_MATERIALIZE_C_QUADRANT(c00);\n" + group(4, 8))
        source = replace_n(source, "    MXFP8_MATERIALIZE_C_QUADRANT(c10);\n",
                            "    MXFP8_MATERIALIZE_C_QUADRANT(c10);\n" + group(12, 16))
    else:
        raise ValueError(kind)
    return source


if __name__ == "__main__":
    source = (BASE / "tmpl_generic.hpp").read_text()
    for kind in ("split", "early", "quads"):
        record(f"initial_roles_{kind}", transform(source, kind),
               dict(initial_matrix_producer="same_A_B_roles_as_main", initial_matrix_overlap=kind))
    m0_source = (WORK / "prepare_m0_explicit1/tmpl_generic.hpp").read_text()
    record("m0_grid_group2", grouped_grid(m0_source, 2),
           dict(main_matrix_issue="explicit_m0_and_MUBUF", m0_setup_mfmas_before_request=1,
                future_matrix_soffset="materialized_before_main_MFMA", preserve_prior_group_m0=True,
                explicit_inline_asm_captures=True, grid_order="transpose_low_bits", grid_group=2))
