#!/usr/bin/env python3
from __future__ import annotations

import collections
import pathlib
import re
import sys


def instructions(text: str) -> list[str]:
    result = []
    for line in text.splitlines():
        if re.search(r"// [0-9A-F]{12,}:", line):
            result.append(line.split("//", 1)[0].strip())
    return result


def metadata(notes: str, name: str) -> int:
    match = re.search(rf"\.{re.escape(name)}:\s*(\d+)", notes)
    if not match:
        raise RuntimeError(f"missing .{name}")
    return int(match.group(1))


def op(inst: str) -> str:
    return inst.split(None, 1)[0] if inst else ""


def main() -> int:
    build = pathlib.Path(sys.argv[1])
    parsed: dict[str, list[str]] = {}

    for tag in ("ref", "early"):
        isa_text = (build / f"ctrl_{tag}.isa").read_text()
        notes = (build / f"ctrl_{tag}.notes").read_text()
        ins = instructions(isa_text)
        parsed[tag] = ins
        values = {
            "inst": len(ins),
            "mfma": sum("v_mfma_scale_f32_16x16x128" in x for x in ins),
            "setprio": sum(op(x) == "s_setprio" for x in ins),
            "wait": sum(op(x) == "s_waitcnt" for x in ins),
            "nop": sum(op(x) == "s_nop" for x in ins),
            "barrier": sum(op(x) == "s_barrier" for x in ins),
            "loads": sum(op(x) == "buffer_load_dwordx4" and " lds" in x for x in ins),
            "stores": sum(op(x) == "buffer_store_dwordx4" for x in ins),
            "vgpr": metadata(notes, "vgpr_count"),
            "sgpr": metadata(notes, "sgpr_count"),
            "vspill": metadata(notes, "vgpr_spill_count"),
            "sspill": metadata(notes, "sgpr_spill_count"),
            "private": metadata(notes, "private_segment_fixed_size"),
            "scratch": sum(op(x).startswith("scratch_") for x in ins),
            "lds": metadata(notes, "group_segment_fixed_size"),
        }
        print(tag + ": " + " ".join(f"{key}={value}" for key, value in values.items()))
        expected = {
            "mfma": 192,
            "setprio": 0,
            "barrier": 7,
            "loads": 91,
            "stores": 32,
            "sgpr": 101,
            "vspill": 0,
            "sspill": 0,
            "private": 0,
            "scratch": 0,
            "lds": 139264,
        }
        for key, value in expected.items():
            if values[key] != value:
                raise RuntimeError(f"{tag}: expected {key}={value}, got {values[key]}")
        if values["vgpr"] > 256:
            raise RuntimeError(f"{tag}: VGPR overflow {values['vgpr']}")

    # ctrl_fill is a pure scheduling patch: apart from replacing fourteen NOP
    # slots, the opcode multiset must remain unchanged between source p18 and
    # the patched reference.
    source = instructions((build / "source_ref.isa").read_text())
    source_counts = collections.Counter(map(op, source))
    ctrl_counts = collections.Counter(map(op, parsed["ref"]))
    expected_counts = source_counts.copy()
    expected_counts["s_nop"] -= 14
    if ctrl_counts != expected_counts:
        delta = {
            key: (source_counts[key], ctrl_counts[key])
            for key in sorted(source_counts.keys() | ctrl_counts.keys())
            if source_counts[key] != ctrl_counts[key]
        }
        raise RuntimeError(f"ctrl_fill opcode multiset mismatch: {delta}")

    early = parsed["early"]
    wait16 = [index for index, inst in enumerate(early)
              if re.search(r"\bvmcnt\(16\)", inst)]
    if len(wait16) != 1:
        raise RuntimeError(f"early: expected one vmcnt(16), got {len(wait16)}")
    wait_index = wait16[0]
    following = [op(inst) for inst in early[wait_index + 1:wait_index + 4]]
    if "s_barrier" not in following:
        raise RuntimeError("early: vmcnt(16) is not immediately associated with handoff barrier")

    # In the outlined final-output block, exactly sixteen C stores must be
    # issued after the last direct-LDS prologue load and before the branch that
    # enters the vmcnt(16)/barrier handoff block.  No younger VMEM load may sit
    # between those stores and the wait, otherwise vmcnt(16) would be unsafe.
    preceding_branches = [
        index for index in range(wait_index)
        if op(early[index]).startswith("s_cbranch_")
    ]
    if not preceding_branches:
        raise RuntimeError("early: cannot locate handoff entry branch")
    handoff_branch = preceding_branches[-1]
    previous_branch = max(
        index for index in range(handoff_branch)
        if op(early[index]).startswith("s_cbranch_")
    )
    block = early[previous_branch + 1:handoff_branch]
    stores = [index for index, inst in enumerate(block)
              if op(inst) == "buffer_store_dwordx4"]
    if len(stores) != 16:
        raise RuntimeError(f"early: expected 16 early stores in final block, got {len(stores)}")
    first_store = stores[0]
    if any(op(inst) == "buffer_load_dwordx4" and " lds" in inst
           for inst in block[first_store + 1:]):
        raise RuntimeError("early: found a younger direct-LDS VMEM load after early stores")

    # All 32 store instructions and all 192 MFMAs must be preserved; only their
    # placement and register allocation may differ.
    print("PASS: early queue is [all required LDS loads][16 stores] -> vmcnt(16) -> barrier")

    old_p1 = build.parents[1] / "output_b1_overlap" / "build" / "p1.isa"
    if old_p1.exists() and instructions(old_p1.read_text()) != source:
        raise RuntimeError("source_ref no longer matches the retained p18 linked stream")
    print("PASS: source_ref linked stream matches retained output_b1_overlap p1")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
