#!/usr/bin/env python3
from __future__ import annotations

import collections
import importlib.util
import re
import sys
from pathlib import Path


def load_patcher(path: Path):
    spec = importlib.util.spec_from_file_location("zero_srcc_patch", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def instructions(path: Path) -> list[str]:
    return [
        line.split("//", 1)[0].strip()
        for line in path.read_text(encoding="utf-8").splitlines()
        if re.search(r"// [0-9A-F]{12,}:", line)
    ]


def opcode(line: str) -> str:
    return line.split(None, 1)[0] if line else ""


def mfma_fields(line: str) -> list[str]:
    operands = line.split(None, 1)[1]
    operands = operands.split(" op_sel:", 1)[0].split(" op_sel_hi:", 1)[0]
    return [field.strip() for field in operands.split(",")]


def metadata(path: Path, name: str) -> int:
    match = re.search(rf"\.{re.escape(name)}:\s*(\d+)", path.read_text())
    if match is None:
        raise RuntimeError(f"{path}: missing .{name}")
    return int(match.group(1))


def metrics(build: Path, tag: str) -> dict[str, int]:
    ins = instructions(build / f"{tag}.isa")
    ops = collections.Counter(opcode(line) for line in ins)
    mfma = [line for line in ins if opcode(line).startswith("v_mfma_scale")]
    stores = [line for line in ins if opcode(line) == "buffer_store_dwordx4"]
    return {
        "inst": len(ins),
        "mfma": len(mfma),
        "zero_srcc": sum(mfma_fields(line)[3] == "0" for line in mfma),
        "agpr_srcc": sum(mfma_fields(line)[3].startswith("a[") for line in mfma),
        "acc_write": ops["v_accvgpr_write_b32"],
        "d2l": sum(opcode(line) == "buffer_load_dwordx4" and " lds" in line for line in ins),
        "store": len(stores),
        "store_agpr": sum(line.split(None, 1)[1].startswith("a[") for line in stores),
        "wait": ops["s_waitcnt"],
        "barrier": ops["s_barrier"],
        "nop": ops["s_nop"],
        "vgpr": metadata(build / f"{tag}.notes", "vgpr_count"),
        "agpr": metadata(build / f"{tag}.notes", "agpr_count"),
        "sgpr": metadata(build / f"{tag}.notes", "sgpr_count"),
        "vspill": metadata(build / f"{tag}.notes", "vgpr_spill_count"),
        "sspill": metadata(build / f"{tag}.notes", "sgpr_spill_count"),
        "private": metadata(build / f"{tag}.notes", "private_segment_fixed_size"),
        "lds": metadata(build / f"{tag}.notes", "group_segment_fixed_size"),
    }


def main() -> None:
    build = Path(sys.argv[1]).resolve()
    patcher = load_patcher(Path(__file__).with_name("patch_zero_srcc_first.py"))
    expected = patcher.patch((build / "ref.s").read_text(encoding="utf-8"))
    if (build / "zero_first.s").read_text(encoding="utf-8") != expected:
        raise RuntimeError("candidate source is not a reproducible patch")

    ref = metrics(build, "ref")
    cand = metrics(build, "zero_first")
    print("ref: " + " ".join(f"{key}={value}" for key, value in ref.items()))
    print("zero_first: " + " ".join(f"{key}={value}" for key, value in cand.items()))

    expected_ref = {
        "mfma": 192, "zero_srcc": 0, "agpr_srcc": 192,
        "acc_write": 384, "d2l": 91, "store": 32, "store_agpr": 32,
        "wait": 50, "barrier": 7, "vgpr": 112, "agpr": 128,
        "sgpr": 101, "vspill": 0, "sspill": 0, "private": 0, "lds": 139264,
    }
    for key, wanted in expected_ref.items():
        if ref[key] != wanted:
            raise RuntimeError(f"ref: {key}={ref[key]}, expected {wanted}")
    expected_cand = {
        "mfma": 224, "zero_srcc": 32, "agpr_srcc": 192,
        "acc_write": 256, "store": 32, "store_agpr": 32,
        "vgpr": 112, "agpr": 128, "sgpr": 101,
        "vspill": 0, "sspill": 0, "private": 0, "lds": 139264,
    }
    for key, wanted in expected_cand.items():
        if cand[key] != wanted:
            raise RuntimeError(f"zero_first: {key}={cand[key]}, expected {wanted}")
    print("PASS: one clear block is replaced by a zero-SrcC first-K clone")


if __name__ == "__main__":
    main()
