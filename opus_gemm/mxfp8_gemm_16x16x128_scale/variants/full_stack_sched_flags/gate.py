#!/usr/bin/env python3
from __future__ import annotations

import pathlib
import re
import sys


def main() -> None:
    root = pathlib.Path(sys.argv[1])
    for tag in ("ref", "iter_ilp", "prera_top", "iter_minreg", "ilpmax", "maxilp"):
        isa = (root / f"{tag}.isa").read_text()
        notes = (root / f"{tag}.notes").read_text()
        ins = [
            line.split("//", 1)[0].strip()
            for line in isa.splitlines()
            if re.search(r"// [0-9A-F]{12,}:", line)
        ]
        op = lambda inst: inst.split(None, 1)[0]
        meta = lambda name: int(re.search(rf"\.{name}:\s*(\d+)", notes).group(1))
        values = {
            "inst": len(ins),
            "nop": sum(op(x) == "s_nop" for x in ins),
            "wait": sum(op(x) == "s_waitcnt" for x in ins),
            "mfma": sum("v_mfma_scale_f32_16x16x128_f8f6f4" in x for x in ins),
            "barrier": sum(op(x) == "s_barrier" for x in ins),
            "loads": sum(op(x) == "buffer_load_dwordx4" and " lds" in x for x in ins),
            "stores": sum(op(x) == "buffer_store_dwordx4" for x in ins),
            "vgpr": meta("vgpr_count"),
            "sgpr": meta("sgpr_count"),
            "vspill": meta("vgpr_spill_count"),
            "sspill": meta("sgpr_spill_count"),
            "private": meta("private_segment_fixed_size"),
        }
        print(tag, " ".join(f"{key}={value}" for key, value in values.items()))
        expected = {"mfma": 192, "barrier": 7, "loads": 91, "stores": 32,
                    "vgpr": 240, "sgpr": 101, "vspill": 0, "sspill": 0,
                    "private": 0}
        for key, value in expected.items():
            if values[key] != value:
                raise RuntimeError(f"{tag}: expected {key}={value}, got {values[key]}")


if __name__ == "__main__":
    main()
