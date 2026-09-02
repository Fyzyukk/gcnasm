#!/usr/bin/env python3
"""Replace the main-loop entry clear with a cloned zero-SrcC first K tile."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


LABEL = re.compile(r"^(\.LBB0_\d+):")
CLEAR = re.compile(r"^\s*v_accvgpr_write_b32\s+a(\d+),\s*0\s*$")
MFMA = re.compile(r"^\s*v_mfma_scale_f32_16x16x128_f8f6f4\s+")


def zero_srcc(line: str) -> str:
    fields = line.split(",", 5)
    if len(fields) != 6 or not re.fullmatch(r"\s*a\[\d+:\d+\]", fields[3]):
        raise RuntimeError(f"unexpected MFMA operands: {line}")
    fields[3] = " 0"
    return ",".join(fields)


def patch(source: str) -> str:
    lines = source.splitlines()
    labels = {
        match.group(1): index
        for index, line in enumerate(lines)
        if (match := LABEL.match(line))
    }
    start = labels.get(".LBB0_16")
    end = labels.get(".LBB0_24")
    clear_begin = labels.get(".LBB0_12")
    clear_end = labels.get(".LBB0_14")
    insert_at = labels.get(".LBB0_63")
    if None in (start, end, clear_begin, clear_end, insert_at):
        raise RuntimeError("missing main-loop entry labels")
    assert start is not None and end is not None
    assert clear_begin is not None and clear_end is not None
    assert insert_at is not None
    if not (clear_begin < clear_end < start < end):
        raise RuntimeError("unexpected main-loop entry layout")

    entry_labels = [".LBB0_16", ".LBB0_18", ".LBB0_21", ".LBB0_22"]
    if any(label not in labels or not start <= labels[label] < end for label in entry_labels):
        raise RuntimeError("unexpected labels in first unrolled K tile")
    replacements = {label: label.replace(".LBB0_", ".LZERO0_") for label in entry_labels}

    clone: list[str] = []
    zero_mfmas = 0
    for line in lines[start:end]:
        for old, new in replacements.items():
            line = re.sub(rf"(?<![A-Za-z0-9_]){re.escape(old)}(?![A-Za-z0-9_])", new, line)
        if MFMA.match(line):
            line = zero_srcc(line)
            zero_mfmas += 1
        clone.append(line)
    # The original range falls through directly into .LBB0_24.  The clone is
    # inserted before .LBB0_16, so make that exit explicit rather than falling
    # into the regular first body.
    clone.append("\ts_branch .LBB0_24")
    if zero_mfmas != 32:
        raise RuntimeError(f"expected 32 first-tile MFMAs, found {zero_mfmas}")

    removed: set[int] = set()
    clear_registers: set[int] = set()
    branch_retargets = 0
    output: list[str] = []
    for index, line in enumerate(lines):
        if clear_begin < index < clear_end and (match := CLEAR.match(line)):
            removed.add(index)
            clear_registers.add(int(match.group(1)))
            continue
        if clear_begin < index < clear_end and line.strip() == "s_branch .LBB0_16":
            line = "\ts_branch .LZERO0_16"
            branch_retargets += 1
        if index == insert_at:
            output.extend(clone)
        output.append(line)

    if clear_registers != set(range(128)) or len(removed) != 128:
        raise RuntimeError(
            f"main-loop entry clear mismatch: {len(removed)} writes, "
            f"registers={sorted(clear_registers)}"
        )
    if branch_retargets != 1:
        raise RuntimeError(f"expected one entry branch retarget, got {branch_retargets}")
    return "\n".join(output) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    args.output.write_text(patch(args.source.read_text(encoding="utf-8")), encoding="utf-8")
    print("removed one 128-AGPR clear and cloned 32 first-K MFMAs with SrcC=0")


if __name__ == "__main__":
    main()
