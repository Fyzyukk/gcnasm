#!/usr/bin/env python3
"""Move the complete C tile to AGPRs and recolor the hot-loop VGPRs.

The clang23 reference dedicates v0:v127 to the fp32 C tile while the K loop
uses v128:v239 for ordinary values.  Once C is moved to a0:a127, the latter
range can occupy v0:v111.  The setup's original v0:v8 temporaries are moved to
v112:v120; only the ABI-provided workitem id needs one entry copy from v0 to
v112.  This removes every ordinary reference above v127.
"""

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

PACKED_CLEAR_LABELS = {".LBB0_12", ".LBB0_44", ".LBB0_45"}
ROWMAJOR_CLEAR_LABELS = {".LBB0_11", ".LBB0_14", ".LBB0_37"}
LOOP_FIRST_LABEL = ".LBB0_4"
PACKED_WORKITEM_CAPTURE = "v_readfirstlane_b32 s22, v0"
ROWMAJOR_WORKITEM_CAPTURE = "v_readfirstlane_b32 s28, v0"


def recolor_vgprs(
    line: str,
    remap_setup_low: bool,
    setup_base: int,
    explicit_low_map: dict[int, int] | None = None,
) -> str:
    def replace_range(match: re.Match[str]) -> str:
        lo, hi = int(match.group(1)), int(match.group(2))
        if lo >= 128 and hi >= 128:
            return f"v[{lo - 128}:{hi - 128}]"
        if explicit_low_map is not None and lo < 128 and hi < 128:
            mapped = [explicit_low_map.get(reg, reg) for reg in range(lo, hi + 1)]
            if mapped != list(range(mapped[0], mapped[0] + len(mapped))):
                raise RuntimeError(
                    f"non-contiguous explicit tuple remap: {match.group(0)}")
            return f"v[{mapped[0]}:{mapped[-1]}]"
        if remap_setup_low and 0 <= lo <= hi <= 8:
            return f"v[{lo + setup_base}:{hi + setup_base}]"
        if lo < 128 and hi < 128:
            return match.group(0)
        raise RuntimeError(f"VGPR tuple crosses recolor boundary: {match.group(0)}")

    line = VGPR_RANGE_RE.sub(replace_range, line)

    def replace_single(match: re.Match[str]) -> str:
        reg = int(match.group(1))
        if reg >= 128:
            return f"v{reg - 128}"
        if explicit_low_map is not None and reg in explicit_low_map:
            return f"v{explicit_low_map[reg]}"
        if remap_setup_low and reg <= 8:
            return f"v{reg + setup_base}"
        return match.group(0)

    return VGPR_SINGLE_RE.sub(replace_single, line)


def replace_once(text: str, old: str, new: str) -> str:
    if text.count(old) != 1:
        raise RuntimeError(f"expected one metadata field {old!r}")
    return text.replace(old, new)


def patch(
    source: str,
    accum_offset: int,
    setup_base: int,
    agpr_rotate: int,
    rowmajor: bool,
    fused: bool,
) -> str:
    if rowmajor or fused:
        label = ""
        clear_counts: dict[str, int] = {}
        transpose_labels: set[str] = set()
        outer_loop_labels: list[str] = []
        for source_line in source.splitlines():
            label_match = LABEL_RE.match(source_line)
            if label_match:
                label = label_match.group(1)
                if "=>This Loop Header: Depth=1" in source_line:
                    outer_loop_labels.append(label)
            move_match = MOV_RE.match(source_line)
            if move_match and int(move_match.group(2)) < 128:
                clear_counts[label] = clear_counts.get(label, 0) + 1
            if "v_permlane16_swap_b32_e64 v0, v1" in source_line:
                transpose_labels.add(label)
        clear_labels = {
            block for block, count in clear_counts.items() if count == 128
        }
        if len(clear_labels) != 3:
            raise RuntimeError(
                f"expected three row-major clear blocks, found {clear_labels}")
        if rowmajor and not transpose_labels:
            raise RuntimeError("failed to locate row-major transpose temporary block")
        if len(outer_loop_labels) != 1:
            raise RuntimeError(
                "expected one row-major outer loop header, found "
                f"{outer_loop_labels}")
        loop_first_label = outer_loop_labels[0]
    else:
        clear_labels = PACKED_CLEAR_LABELS
        transpose_labels = set()
        loop_first_label = LOOP_FIRST_LABEL
    if rowmajor or fused:
        captures = [
            line.strip() for line in source.splitlines()
            if re.fullmatch(r"\s*v_readfirstlane_b32\s+s\d+,\s+v0\s*", line)
        ]
        if not captures:
            raise RuntimeError("failed to locate workitem-id capture")
        workitem_capture = captures[0]
        vgpr_match = re.search(r"\.num_vgpr,\s*(\d+)", source)
        accum_match = re.search(r"\.amdhsa_accum_offset\s+(\d+)", source)
        if vgpr_match is None or accum_match is None:
            raise RuntimeError("failed to infer row-major register metadata")
        source_vgprs = int(vgpr_match.group(1))
        source_accum_offset = int(accum_match.group(1))
    else:
        workitem_capture = PACKED_WORKITEM_CAPTURE
        source_vgprs = 240
        source_accum_offset = 240
    compact_vgprs = source_vgprs - 128
    ordinary_vgprs = accum_offset if (rowmajor or fused) else source_vgprs - 128
    output: list[str] = []
    current_label = ""
    in_setup = True
    workitem_captured = False
    mfma_count = 0
    store_count = 0
    clear_count = 0
    preheader_count = 0

    for original in source.splitlines():
        line = original
        label_match = LABEL_RE.match(line)
        if label_match:
            current_label = label_match.group(1)
            if current_label == loop_first_label:
                in_setup = False

        mfma_match = MFMA_RE.match(line)
        if mfma_match:
            d0, d1 = int(mfma_match.group(2)), int(mfma_match.group(3))
            c0, c1 = int(mfma_match.group(5)), int(mfma_match.group(6))
            if not (0 <= d0 <= d1 < 128 and (d0, d1) == (c0, c1)):
                raise RuntimeError(f"unexpected MFMA accumulator tuple: {line}")
            ad0 = (d0 + agpr_rotate) % 128
            ac0 = (c0 + agpr_rotate) % 128
            line = (
                f"{mfma_match.group(1)}a[{ad0}:{ad0 + d1 - d0}]"
                f"{mfma_match.group(4)}a[{ac0}:{ac0 + c1 - c0}]"
                f"{mfma_match.group(7)}"
            )
            mfma_count += 1

        store_match = STORE_RE.match(line)
        if store_match:
            d0, d1 = int(store_match.group(2)), int(store_match.group(3))
            if not (0 <= d0 <= d1 < 128):
                raise RuntimeError(f"unexpected C-store tuple: {line}")
            ad0 = (d0 + agpr_rotate) % 128
            line = (
                f"{store_match.group(1)}a[{ad0}:{ad0 + d1 - d0}]"
                f"{store_match.group(4)}"
            )
            store_count += 1

        move_match = MOV_RE.match(line)
        if move_match and current_label in clear_labels:
            dst = int(move_match.group(2))
            if dst < 128:
                line = (
                    f"{move_match.group(1)}v_accvgpr_write_b32 "
                    f"a{(dst + agpr_rotate) % 128}, 0"
                )
                clear_count += 1

        if line.strip() and not line.lstrip().startswith((".", ";", "#")):
            remap_low = in_setup and workitem_captured
            low_base = setup_base
            explicit_low_map = None
            if rowmajor and current_label in transpose_labels:
                # The row-major transpose uses v0:v2 after the ordinary
                # high range has been compacted.  Use spare registers below
                # a0; QUEUE8 has only two consecutive spares, so borrow the
                # compacted top register for the third short-lived value.
                if compact_vgprs <= 125:
                    explicit_low_map = {
                        0: compact_vgprs,
                        1: compact_vgprs + 1,
                        2: compact_vgprs + 2,
                    }
                else:
                    explicit_low_map = {0: 126, 1: 127, 2: 125}
            line = recolor_vgprs(
                line, remap_low, low_base, explicit_low_map)

        output.append(line)
        if original.strip() == workitem_capture:
            output.append(f"\tv_mov_b32_e32 v{setup_base}, v0")
            workitem_captured = True
            preheader_count += 1

    if mfma_count != 192:
        raise RuntimeError(f"expected 192 MFMAs, patched {mfma_count}")
    if store_count != 32:
        raise RuntimeError(f"expected 32 stores, patched {store_count}")
    if clear_count != 384:
        raise RuntimeError(f"expected 384 C clears, patched {clear_count}")
    if preheader_count != 1:
        raise RuntimeError(f"expected one workitem-id capture, found {preheader_count}")

    text = "\n".join(output) + "\n"
    replacements = (
        (
            f".amdhsa_next_free_vgpr {source_vgprs}",
            f".amdhsa_next_free_vgpr {accum_offset + 128}",
        ),
        (
            f".amdhsa_accum_offset {source_accum_offset}",
            f".amdhsa_accum_offset {accum_offset}",
        ),
        (f".num_vgpr, {source_vgprs}", f".num_vgpr, {ordinary_vgprs}"),
        (".num_agpr, 0", ".num_agpr, 128"),
        (".agpr_count:     0", ".agpr_count:     128"),
        (
            f".vgpr_count:     {source_vgprs}",
            f".vgpr_count:     {ordinary_vgprs}",
        ),
    )
    for old, new in replacements:
        text = replace_once(text, old, new)
    return text


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument(
        "--accum-offset", type=int, choices=(112, 116, 120, 124, 128), default=112
    )
    parser.add_argument("--setup-base", type=int, default=24)
    parser.add_argument("--agpr-rotate", type=int, choices=(0, 4, 8, 16), default=0)
    parser.add_argument(
        "--rowmajor",
        action="store_true",
        help="patch the 252-VGPR row-major double-queue assembly profile",
    )
    parser.add_argument(
        "--fused",
        action="store_true",
        help="patch a fused-pack packed-kernel profile with dynamic labels",
    )
    args = parser.parse_args()
    if (args.rowmajor or args.fused) and args.accum_offset != 128:
        raise SystemExit("row-major/fused recoloring requires accum offset 128")
    if args.rowmajor and args.fused:
        raise SystemExit("--rowmajor and --fused are mutually exclusive")
    if args.setup_base < 23 or args.setup_base % 2 or args.setup_base + 8 >= args.accum_offset:
        raise SystemExit(
            "setup range must fit above v22/below accum offset and preserve pair alignment"
        )
    args.output.write_text(
        patch(
            args.source.read_text(encoding="utf-8"),
            args.accum_offset,
            args.setup_base,
            args.agpr_rotate,
            args.rowmajor,
            args.fused,
        ),
        encoding="utf-8",
    )
    print(
        "patched 192 MFMAs, 32 direct AGPR stores, 384 AGPR clears, "
        f"one entry workitem-id copy, offset={args.accum_offset}, "
        f"rotate={args.agpr_rotate}, rowmajor={args.rowmajor}"
    )


if __name__ == "__main__":
    main()
