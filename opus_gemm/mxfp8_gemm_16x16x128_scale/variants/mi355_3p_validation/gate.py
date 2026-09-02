#!/usr/bin/env python3
from __future__ import annotations

import collections
import re
import sys
from pathlib import Path


def instructions(path: Path) -> list[str]:
    return [
        line.split("//", 1)[0].strip()
        for line in path.read_text(encoding="utf-8").splitlines()
        if re.search(r"// [0-9A-F]{12,}:", line)
    ]


def opcode(line: str) -> str:
    return line.split(None, 1)[0] if line else ""


def metadata(path: Path, name: str) -> int:
    match = re.search(rf"\.{re.escape(name)}:\s*(\d+)", path.read_text())
    if match is None:
        raise RuntimeError(f"{path}: missing .{name}")
    return int(match.group(1))


def metrics(build: Path, tag: str) -> dict[str, int]:
    ins = instructions(build / f"{tag}.isa")
    ops = collections.Counter(opcode(line) for line in ins)
    mfma = [line for line in ins if opcode(line).startswith("v_mfma_scale_f32_16x16x128")]
    stores = [line for line in ins if opcode(line) == "buffer_store_dwordx4"]
    return {
        "inst": len(ins),
        "nop": ops["s_nop"],
        "mfma": len(mfma),
        "load_lds": sum(
            opcode(line) == "buffer_load_dwordx4" and " lds" in line
            for line in ins
        ),
        "store": len(stores),
        "store_agpr": sum(line.split(None, 1)[1].startswith("a[") for line in stores),
        "acc_write": ops["v_accvgpr_write_b32"],
        "acc_read": ops["v_accvgpr_read_b32"],
        "wait": ops["s_waitcnt"],
        "barrier": ops["s_barrier"],
        "setprio": ops["s_setprio"],
        "scratch_ops": sum(opcode(line).startswith("scratch_") for line in ins),
        "vgpr": metadata(build / f"{tag}.notes", "vgpr_count"),
        "agpr": metadata(build / f"{tag}.notes", "agpr_count"),
        "sgpr": metadata(build / f"{tag}.notes", "sgpr_count"),
        "vspill": metadata(build / f"{tag}.notes", "vgpr_spill_count"),
        "sspill": metadata(build / f"{tag}.notes", "sgpr_spill_count"),
        "private": metadata(build / f"{tag}.notes", "private_segment_fixed_size"),
        "lds": metadata(build / f"{tag}.notes", "group_segment_fixed_size"),
    }


def check(tag: str, got: dict[str, int], expected: dict[str, int]) -> None:
    print(tag + ": " + " ".join(f"{key}={value}" for key, value in got.items()))
    for key, wanted in expected.items():
        if got[key] != wanted:
            raise RuntimeError(f"{tag}: {key}={got[key]}, expected {wanted}")
    if got["vspill"] or got["sspill"] or got["private"] or got["scratch_ops"]:
        raise RuntimeError(f"{tag}: spill/scratch/private allocation is not zero")


def main() -> None:
    build = Path(sys.argv[1]).resolve()
    common = {
        "mfma": 192,
        "store": 32,
        "barrier": 7,
        "sgpr": 101,
        "vspill": 0,
        "sspill": 0,
        "private": 0,
        "scratch_ops": 0,
        "lds": 139264,
    }
    stages = [
        ("00_baseline", 1599, 110, 87, 45, 22, 240, 0, 0, 0),
        ("01_no_setprio", 1582, 110, 87, 50, 0, 240, 0, 0, 0),
        ("02_p8_control", 1605, 112, 91, 50, 0, 240, 0, 0, 0),
        ("03_p18", 1608, 115, 91, 50, 0, 240, 0, 0, 0),
        ("04_ctrl_fill", 1594, 101, 91, 50, 0, 240, 0, 0, 0),
        ("05_early_c", 1593, 100, 91, 50, 0, 240, 0, 0, 0),
        ("06_prera_top", 1582, 88, 91, 50, 0, 240, 0, 0, 0),
        ("07_t2x16", 1595, 85, 91, 50, 0, 240, 0, 0, 0),
        ("08_agpr", 1595, 84, 91, 50, 0, 112, 128, 384, 32),
    ]
    expected = {}
    for tag, inst, nop, loads, waits, setprio, vgpr, agpr, acc_write, store_agpr in stages:
        expected[tag] = common | {
            "inst": inst,
            "nop": nop,
            "load_lds": loads,
            "wait": waits,
            "setprio": setprio,
            "vgpr": vgpr,
            "agpr": agpr,
            "acc_write": acc_write,
            "acc_read": 0,
            "store_agpr": store_agpr,
        }

    for tag, wanted in expected.items():
        check(tag, metrics(build, tag), wanted)

    print("PASS: all cumulative stages and the p8 isolation control match the expected linked ISA/resources")


if __name__ == "__main__":
    main()
