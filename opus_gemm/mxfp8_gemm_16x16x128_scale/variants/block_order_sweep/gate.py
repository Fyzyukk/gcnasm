#!/usr/bin/env python3
"""Static gate for the final linked block-order executables."""

from __future__ import annotations

import pathlib
import re
import sys


TAGS = (
    "ref",
    "retained",
    "t4x8_nfast",
    "t4x8_mfast",
    "t8x4_nfast",
    "t8x4_mfast",
    "nmajor",
    "t2x16_nfast_exact",
    "t4x8_nfast_exact",
    "t8x4_nfast_exact",
    "t2x16_direct",
    "identity_direct",
    "identity_coords",
    "t2x16_coords",
    "t2x16_xor_m8",
    "t2x16_serpentine",
    "t2x16_gray",
    "t2x16_xor_macro8",
    "t2x16_insert_p1",
    "t2x16_insert_p2",
    "t2x16_insert_p3",
    "t2x16_n_bitreverse",
    "t2x16_n_rotl1",
    "t2x16_n_rotl2",
    "t2x16_n_rotl3",
)


def instructions(text: str) -> list[str]:
    return [
        line.split("//", 1)[0].strip()
        for line in text.splitlines()
        if re.search(r"// [0-9A-F]{12,}:", line)
    ]


def metadata(text: str, name: str) -> int:
    match = re.search(rf"\.{re.escape(name)}:\s*(\d+)", text)
    if not match:
        raise RuntimeError(f"missing .{name}")
    return int(match.group(1))


def opcode(line: str) -> str:
    return line.split(None, 1)[0] if line else ""


def main() -> None:
    root = pathlib.Path(sys.argv[1])
    for tag in TAGS:
        isa = instructions((root / f"{tag}.isa").read_text(encoding="utf-8"))
        notes = (root / f"{tag}.notes").read_text(encoding="utf-8")
        values = {
            "inst": len(isa),
            "mfma": sum("v_mfma_scale_f32_16x16x128" in x for x in isa),
            "load": sum(opcode(x) == "buffer_load_dwordx4" and " lds" in x for x in isa),
            "store": sum(opcode(x) == "buffer_store_dwordx4" for x in isa),
            "wait": sum(opcode(x) == "s_waitcnt" for x in isa),
            "nop": sum(opcode(x) == "s_nop" for x in isa),
            "barrier": sum(opcode(x) == "s_barrier" for x in isa),
            "setprio": sum(opcode(x) == "s_setprio" for x in isa),
            "vgpr": metadata(notes, "vgpr_count"),
            "sgpr": metadata(notes, "sgpr_count"),
            "vspill": metadata(notes, "vgpr_spill_count"),
            "sspill": metadata(notes, "sgpr_spill_count"),
            "private": metadata(notes, "private_segment_fixed_size"),
            "lds": metadata(notes, "group_segment_fixed_size"),
            "scratch": sum(opcode(x).startswith("scratch_") for x in isa),
        }
        print(tag + ": " + " ".join(f"{key}={value}" for key, value in values.items()))
        expected = {
            "mfma": 192,
            "load": 91,
            "store": 32,
            "wait": 50,
            "barrier": 7,
            "setprio": 0,
            "vspill": 0,
            "sspill": 0,
            "private": 0,
            "lds": 139264,
            "scratch": 0,
        }
        for key, value in expected.items():
            if values[key] != value:
                raise RuntimeError(
                    f"{tag}: expected {key}={value}, got {values[key]}")
        if values["vgpr"] > 256:
            raise RuntimeError(f"{tag}: VGPR overflow {values['vgpr']}")
        if values["sgpr"] > 128:
            raise RuntimeError(f"{tag}: SGPR overflow {values['sgpr']}")

        wait16 = [x for x in isa if re.search(r"\bvmcnt\(16\)", x)]
        if len(wait16) != 1:
            raise RuntimeError(
                f"{tag}: expected one early-C vmcnt(16), got {len(wait16)}")

    print("PASS: linked images retain p18 + early-C + ctrl_fill resource invariants")


if __name__ == "__main__":
    main()
