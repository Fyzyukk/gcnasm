#!/usr/bin/env python3
"""Move the longest-lived upper half of C to AGPRs and recolor operands."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


MFMA_RE = re.compile(
    r"^(\s*v_mfma_scale_f32_16x16x128_f8f6f4\s+)"
    r"v\[(\d+):(\d+)\](,\s+v\[\d+:\d+\],\s+v\[\d+:\d+\],\s+)"
    r"v\[(\d+):(\d+)\](,.*)$"
)
STORE_RE = re.compile(r"^(\s*buffer_store_dwordx4\s+)v\[(\d+):(\d+)\](,.*)$")
MOV_RE = re.compile(r"^(\s*)v_mov_b32_e32\s+v(\d+),\s+(.+?)\s*$")
LABEL_RE = re.compile(r"^(\.LBB0_\d+):")
VGPR_RANGE_RE = re.compile(r"\bv\[(\d+):(\d+)\]")
VGPR_SINGLE_RE = re.compile(r"\bv(\d+)\b")
CLEAR_LABELS = {".LBB0_12", ".LBB0_44", ".LBB0_45"}


def recolor(line: str) -> str:
    def replace_range(match: re.Match[str]) -> str:
        lo, hi = int(match.group(1)), int(match.group(2))
        if lo >= 128:
            return f"v[{lo - 64}:{hi - 64}]"
        if 64 <= lo <= hi <= 95:
            return f"v[{lo + 64}:{hi + 64}]"
        if hi < 64 or 96 <= lo <= hi < 128:
            return match.group(0)
        raise RuntimeError(f"tuple crosses half-recolor boundary: {match.group(0)}")

    line = VGPR_RANGE_RE.sub(replace_range, line)

    def replace_single(match: re.Match[str]) -> str:
        reg = int(match.group(1))
        if reg >= 128:
            return f"v{reg - 64}"
        if 64 <= reg <= 95:
            return f"v{reg + 64}"
        return match.group(0)

    return VGPR_SINGLE_RE.sub(replace_single, line)


def replace_once(text: str, old: str, new: str) -> str:
    if text.count(old) != 1:
        raise RuntimeError(f"expected one metadata field {old!r}")
    return text.replace(old, new)


def patch(source: str) -> str:
    output: list[str] = []
    label = ""
    mfma_agpr = 0
    store_agpr = 0
    clear_agpr = 0
    clear_vgpr = 0

    for original in source.splitlines():
        line = original
        match = LABEL_RE.match(line)
        if match:
            label = match.group(1)

        match = MFMA_RE.match(line)
        if match:
            d0, d1 = int(match.group(2)), int(match.group(3))
            c0, c1 = int(match.group(5)), int(match.group(6))
            if (d0, d1) != (c0, c1) or not (0 <= d0 <= d1 < 128):
                raise RuntimeError(f"unexpected MFMA accumulator tuple: {line}")
            if d0 >= 64:
                line = (
                    f"{match.group(1)}a[{d0 - 64}:{d1 - 64}]"
                    f"{match.group(4)}a[{c0 - 64}:{c1 - 64}]{match.group(7)}"
                )
                mfma_agpr += 1

        match = STORE_RE.match(line)
        if match:
            d0, d1 = int(match.group(2)), int(match.group(3))
            if not (0 <= d0 <= d1 < 128):
                raise RuntimeError(f"unexpected store payload: {line}")
            if d0 >= 64:
                line = f"{match.group(1)}a[{d0 - 64}:{d1 - 64}]{match.group(4)}"
                store_agpr += 1

        match = MOV_RE.match(line)
        if match and label in CLEAR_LABELS:
            dst = int(match.group(2))
            if dst < 128:
                if dst >= 64:
                    line = f"{match.group(1)}v_accvgpr_write_b32 a{dst - 64}, 0"
                    clear_agpr += 1
                else:
                    line = f"{match.group(1)}v_mov_b32_e32 v{dst}, 0"
                    clear_vgpr += 1

        if line.strip() and not line.lstrip().startswith((".", ";", "#")):
            line = recolor(line)
        output.append(line)

    expected = (96, 16, 192, 192)
    actual = (mfma_agpr, store_agpr, clear_agpr, clear_vgpr)
    if actual != expected:
        raise RuntimeError(f"unexpected half-AGPR counts {actual}, expected {expected}")

    text = "\n".join(output) + "\n"
    for old, new in (
        (".amdhsa_accum_offset 240", ".amdhsa_accum_offset 176"),
        (".num_vgpr, 240", ".num_vgpr, 176"),
        (".num_agpr, 0", ".num_agpr, 64"),
        (".agpr_count:     0", ".agpr_count:     64"),
        (".vgpr_count:     240", ".vgpr_count:     176"),
    ):
        text = replace_once(text, old, new)
    return text


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    args.output.write_text(patch(args.source.read_text(encoding="utf-8")), encoding="utf-8")
    print("patched upper 64 C dwords: 96 MFMAs, 16 stores, 192 clears")


if __name__ == "__main__":
    main()
