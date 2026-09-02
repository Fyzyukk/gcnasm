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


def mfma_fields(line: str) -> list[str]:
    operands = line.split(None, 1)[1]
    operands = operands.split(" op_sel:", 1)[0].split(" op_sel_hi:", 1)[0]
    return [field.strip() for field in operands.split(",")]


def metrics(build: Path, tag: str) -> tuple[list[str], dict[str, int]]:
    ins = instructions(build / f"{tag}.isa")
    ops = collections.Counter(opcode(line) for line in ins)
    mfma = [line for line in ins if opcode(line).startswith("v_mfma_scale_f32_16x16x128")]
    stores = [line for line in ins if opcode(line) == "buffer_store_dwordx4"]
    result = {
        "inst": len(ins),
        "mfma": len(mfma),
        "mfma_agpr_dst": sum(mfma_fields(line)[0].startswith("a[") for line in mfma),
        "mfma_agpr_srcc": sum(mfma_fields(line)[3].startswith("a[") for line in mfma),
        "load": sum(opcode(line) == "buffer_load_dwordx4" and " lds" in line for line in ins),
        "store": len(stores),
        "store_agpr": sum(line.split(None, 1)[1].startswith("a[") for line in stores),
        "acc_write": ops["v_accvgpr_write_b32"],
        "acc_read": ops["v_accvgpr_read_b32"],
        "wait": ops["s_waitcnt"],
        "barrier": ops["s_barrier"],
        "setprio": ops["s_setprio"],
        "scratch": sum(opcode(line).startswith("scratch_") for line in ins),
        "vgpr": metadata(build / f"{tag}.notes", "vgpr_count"),
        "agpr": metadata(build / f"{tag}.notes", "agpr_count"),
        "sgpr": metadata(build / f"{tag}.notes", "sgpr_count"),
        "vspill": metadata(build / f"{tag}.notes", "vgpr_spill_count"),
        "sspill": metadata(build / f"{tag}.notes", "sgpr_spill_count"),
        "private": metadata(build / f"{tag}.notes", "private_segment_fixed_size"),
        "lds": metadata(build / f"{tag}.notes", "group_segment_fixed_size"),
    }
    return ins, result


def main() -> None:
    build = Path(sys.argv[1]).resolve()
    ref_ins, ref = metrics(build, "ref")
    print("ref: " + " ".join(f"{key}={value}" for key, value in ref.items()))

    expected_ref = {
        "inst": 1595, "mfma": 192, "load": 91, "store": 32,
        "wait": 50, "barrier": 7, "setprio": 0, "vgpr": 240,
        "agpr": 0, "sgpr": 101, "vspill": 0, "sspill": 0,
        "private": 0, "lds": 139264,
    }
    for key, wanted in expected_ref.items():
        if ref[key] != wanted:
            raise RuntimeError(f"ref: {key}={ref[key]}, expected {wanted}")

    expected_candidate = {
        "inst": 1595, "mfma": 192, "mfma_agpr_dst": 192,
        "mfma_agpr_srcc": 192, "load": 91, "store": 32,
        "store_agpr": 32, "acc_write": 384, "acc_read": 0,
        "wait": 50, "barrier": 7, "setprio": 0, "scratch": 0,
        "vgpr": 112, "agpr": 128, "sgpr": 101, "vspill": 0,
        "sspill": 0, "private": 0, "lds": 139264,
    }
    ref_ops = [opcode(line) for line in ref_ins]
    tags = (
        "agpr_recolor", "offset116", "offset120", "offset124", "offset128",
        "rotate4", "rotate8", "rotate16",
    )
    for tag in tags:
        candidate_ins, candidate = metrics(build, tag)
        print(tag + ": " + " ".join(f"{key}={value}" for key, value in candidate.items()))
        for key, wanted in expected_candidate.items():
            if candidate[key] != wanted:
                raise RuntimeError(f"{tag}: {key}={candidate[key]}, expected {wanted}")
        vgprs: list[int] = []
        for line in candidate_ins:
            for match in re.finditer(r"\bv(?:\[(\d+):(\d+)\]|(\d+))", line):
                if match.group(3) is not None:
                    vgprs.append(int(match.group(3)))
                else:
                    vgprs.extend((int(match.group(1)), int(match.group(2))))
        if vgprs and max(vgprs) >= 112:
            raise RuntimeError(f"{tag}: ordinary recoloring incomplete: max v{max(vgprs)}")
        if sum("vmcnt(16)" in line for line in candidate_ins) != 1:
            raise RuntimeError(f"{tag}: lost the single p18 early-C vmcnt(16)")
        candidate_ops = [opcode(line) for line in candidate_ins]
        normalized = [
            "v_mov_b32_e32" if op == "v_accvgpr_write_b32" else op
            for op in candidate_ops
        ]
        if len(normalized) != len(ref_ops):
            raise RuntimeError(f"{tag}: unexpected opcode-stream length")
    half_ins, half = metrics(build, "half_upper")
    print("half_upper: " + " ".join(f"{key}={value}" for key, value in half.items()))
    half_expected = {
        "inst": 1595, "mfma": 192, "mfma_agpr_dst": 96,
        "mfma_agpr_srcc": 96, "load": 91, "store": 32,
        "store_agpr": 16, "acc_write": 192, "acc_read": 0,
        "wait": 50, "barrier": 7, "setprio": 0, "scratch": 0,
        "vgpr": 176, "agpr": 64, "sgpr": 101, "vspill": 0,
        "sspill": 0, "private": 0, "lds": 139264,
    }
    for key, wanted in half_expected.items():
        if half[key] != wanted:
            raise RuntimeError(f"half_upper: {key}={half[key]}, expected {wanted}")
    half_vgprs: list[int] = []
    for line in half_ins:
        for match in re.finditer(r"\bv(?:\[(\d+):(\d+)\]|(\d+))", line):
            half_vgprs.extend(
                [int(match.group(3))]
                if match.group(3) is not None
                else [int(match.group(1)), int(match.group(2))]
            )
    if half_vgprs and max(half_vgprs) >= 176:
        raise RuntimeError(f"half_upper: max ordinary VGPR is v{max(half_vgprs)}")
    print("PASS: linked AGPR images are direct-store, within 240/256 registers, and spill-free")


if __name__ == "__main__":
    main()
