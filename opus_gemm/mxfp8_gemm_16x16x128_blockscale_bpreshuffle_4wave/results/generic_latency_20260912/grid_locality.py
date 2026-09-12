#!/usr/bin/env python3
"""Swap tile-index fields at several XCC-relevant spacings, with generic fallback."""
from make_candidates import BASE, record, replace_n


def transform(source, nshift, mshift, bits):
    mask = (1 << bits) - 1
    nmask, mmask = mask << nshift, mask << mshift
    old = """    const int block_m = block_id_y();
    const int block_n = block_id_x();
"""
    new = f"""    int block_m = block_id_y();
    int block_n = block_id_x();
    // Exchange complete tile-index fields; partial groups keep direct mapping.
    if ((kargs.m & {(1 << (mshift + bits + 8)) - 1}) == 0 &&
        (kargs.n & {(1 << (nshift + bits + 8)) - 1}) == 0) {{
        const int old_m = block_m;
        block_m = (block_m & ~{mmask}) | (((block_n >> {nshift}) & {mask}) << {mshift});
        block_n = (block_n & ~{nmask}) | (((old_m >> {mshift}) & {mask}) << {nshift});
    }}
"""
    return replace_n(source, old, new)


if __name__ == "__main__":
    source = (BASE / "tmpl_generic.hpp").read_text()
    for ns, ms, bits in [(2, 0, 1), (3, 0, 1), (4, 0, 1), (3, 0, 2), (3, 1, 1)]:
        name = f"grid_n{ns}_m{ms}_b{bits}"
        record(name, transform(source, ns, ms, bits),
               dict(grid_order="swap_coordinate_bitfields", grid_n_shift=ns,
                    grid_m_shift=ms, grid_bits=bits))
