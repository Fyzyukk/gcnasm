#!/usr/bin/env python3
"""Generate a local template whose mapping produces coordinates directly."""

from __future__ import annotations

import pathlib
import sys


OLD = """    const int block_n = block_id_x() % num_tiles_n;
    const int first_block_m =
        (block_id_x() / num_tiles_n) * T::OUTPUT_TILES_PER_WG;
"""

NEW = """    const int physical_block_id = block_id_x();
    int block_n;
    int block_mgroup;
    if (__builtin_expect(kargs.m == 8192 && kargs.n == 8192, 1)) {
#if MXFP8_DIRECT_ORDER == 0
        block_n = physical_block_id & 31;
        block_mgroup = physical_block_id >> 5;
#elif MXFP8_DIRECT_ORDER == 1
        const int macro_id = physical_block_id >> 5;
        const int local_id = physical_block_id & 31;
        block_n = ((macro_id & 1) << 4) + (local_id & 15);
        block_mgroup = ((macro_id >> 1) << 1) + (local_id >> 4);
#else
#error \"unknown MXFP8_DIRECT_ORDER\"
#endif
    } else {
        block_n = physical_block_id % num_tiles_n;
        block_mgroup = physical_block_id / num_tiles_n;
    }
    const int first_block_m = block_mgroup * T::OUTPUT_TILES_PER_WG;
"""


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: make_direct_template.py INPUT OUTPUT")
    source = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
    if source.count(OLD) != 1:
        raise SystemExit("expected exactly one retained block mapping")
    pathlib.Path(sys.argv[2]).write_text(source.replace(OLD, NEW), encoding="utf-8")


if __name__ == "__main__":
    main()
