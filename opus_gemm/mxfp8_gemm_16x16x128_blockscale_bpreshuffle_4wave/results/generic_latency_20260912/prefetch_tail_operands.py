#!/usr/bin/env python3
"""Use the scalar-group address savings for earlier next-K operand reads."""
import sys

from make_candidates import BASE, record, replace_n, resident_operands
from scalar_matrix_groups import transform as scalar_addresses


def transform(source, operands):
    assert operands and set(operands) <= {"a1_m2", "b1_n3"}
    start = source.index("    for (tile = 0; tile + 2 < loops; ++tile)")
    end = source.index("    // Consume the final resident tile", start)
    body = source[start:end]
    marker = """        MXFP8_MMA_PAIR(1, 1, 0, v_a[1], v_b_n1, c11_4, c11_5, v_sfa, v_sfb[1]);
        sched_barrier_pairs_scale();
"""
    extra = "\n        // MFMA54: use independent registers until the old operand dies.\n"
    for operand in operands:
        is_a = operand.startswith("a")
        mem, offsets, first = ("s_a", "ra1_next_offsets", 4) if is_a else ("s_b", "rb1_next_offsets", 6)
        extra += f"""        auto {operand}_early_0 = {mem}.template load<16>({offsets}[{first}]);
        auto {operand}_early_1 = {mem}.template load<16>({offsets}[{first + 1}]);
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);
"""
        old = ("        load_a_mrepeat_scale<T, 2>(s_a, ra1_next_offsets, v_a[1]);\n" if is_a
               else "        load_b_range_scale<T, 6, 8>(s_b, rb1_next_offsets, v_b_second);\n")
        dst = "v_a[1]" if is_a else "v_b_second"
        install = "".join(
            f"        opus::set_slice({dst}, {operand}_early_{piece}, opus::number<{(first + piece) * 16}>{{}}, opus::number<{(first + piece + 1) * 16}>{{}});\n"
            for piece in range(2))
        body = replace_n(body, old, install, 2)
    body = replace_n(body, marker, marker + extra, 2)
    return source[:start] + body + source[end:]


if __name__ == "__main__":
    choices = {
        "scalar4_a1m2_prefetch54": (["a1_m2"], False),
        "scalar4_b1n3_prefetch54": (["b1_n3"], False),
        "scalar4_tail_prefetch54": (["a1_m2", "b1_n3"], False),
        "scalar4_resident_b1n3_prefetch54": (["b1_n3"], True),
    }
    base = scalar_addresses((BASE / "tmpl_generic.hpp").read_text(), 4)
    for name in sys.argv[1:]:
        operands, resident = choices[name]
        source = transform(resident_operands(base) if resident else base, operands)
        config = dict(matrix_cached_lane_addresses=4,
                      matrix_uniform_row_group_issues=4,
                      matrix_group_source_offsets_nonnegative=True,
                      operand_schedule_parent="scalar_matrix_group4" + ("_resident" if resident else ""),
                      tail_operand_prefetch={operand: 54 for operand in operands},
                      tail_operand_install={operand: 63 if operand == "a1_m2" else 64 for operand in operands})
        if resident:
            config["final_operands_resident"] = True
        record(name, source, config)
