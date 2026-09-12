#!/usr/bin/env python3
"""Share cached lane addresses across matrix groups using uniform row offsets."""
from make_candidates import BASE, record, replace_n, resident_operands


def transform(source, group):
    assert group in (4, 8)
    source = replace_n(source, """    opus::vector_t<int, 16> matrix_addresses;
    opus::static_for<16>([&](auto issue_i) {""", f"""    // Only the lane-dependent addresses are cached in ordinary VGPRs.
    // Later row groups reuse them with nonnegative, wave-uniform SOFFSETs.
    opus::vector_t<int, {group}> matrix_addresses;
    opus::static_for<{group}>([&](auto issue_i) {{""")
    old = """            matrix_addresses[issue], k_tile * matrix_k_stride,
            opus::number<immediate>{}, opus::number<0>{});"""
    new = f"""            matrix_addresses[issue % {group}],
            __builtin_amdgcn_readfirstlane(k_tile * matrix_k_stride
                + (issue / {group}) * {group // 2} * matrix_pair_stride),
            opus::number<immediate>{{}}, opus::number<0>{{}});"""
    return replace_n(source, old, new)


if __name__ == "__main__":
    source = (BASE / "tmpl_generic.hpp").read_text()
    for group in (4, 8):
        shared = transform(source, group)
        config = dict(matrix_cached_lane_addresses=group,
                      matrix_uniform_row_group_issues=group,
                      matrix_group_source_offsets_nonnegative=True)
        record(f"scalar_matrix_group{group}", shared, config)
        record(f"scalar_matrix_group{group}_resident", resident_operands(shared),
               dict(config, final_operands_resident=True))
