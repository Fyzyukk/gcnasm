#!/usr/bin/env python3
"""Interleave local M/N tile bits without changing workgroup tile ownership."""
from make_candidates import BASE, record, replace_n


def transform(source, bits, first):
    group = 1 << bits
    mask = group - 1

    def coordinate(axis):
        parity = int(axis != first)
        pieces = []
        for dest in range(bits):
            bit = dest * 2 + parity
            original = "old_n" if bit < bits else "old_m"
            shift = bit if bit < bits else bit - bits
            pieces.append(f"((({original} >> {shift}) & 1) << {dest})")
        return " | ".join(pieces)

    old = """    const int block_m = block_id_y();
    const int block_n = block_id_x();
"""
    new = f"""    int block_m = block_id_y();
    int block_n = block_id_x();
    // Interleave coordinates only in complete {group}x{group} tile groups.
    // Each workgroup still computes one independent 256x256 output tile.
    if (((kargs.m | kargs.n) & {group * 256 - 1}) == 0) {{
        const int old_m = block_m;
        const int old_n = block_n;
        block_m = (old_m & ~{mask}) | {coordinate('m')};
        block_n = (old_n & ~{mask}) | {coordinate('n')};
    }}
"""
    return replace_n(source, old, new)


if __name__ == "__main__":
    source = (BASE / "tmpl_generic.hpp").read_text()
    for bits, first in [(2, "n"), (2, "m"), (3, "n"), (3, "m"), (4, "m")]:
        name = f"grid_morton_g{1 << bits}_{first}first"
        record(name, transform(source, bits, first),
               dict(grid_order="morton_local_bits", grid_group=1 << bits,
                    grid_low_bit_first=first, grid_partial_groups="identity"))
