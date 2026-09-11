#!/usr/bin/env python3
"""Conservative DS wait audit of linked gfx950 ISA; never launches a GPU.

Tracks every DS read/write as one LGKM event, including inline ds_write_b8.
DS read destinations remain pending until an explicit wait guarantees their
completion. Explores both successors of every scalar conditional branch and
the loop backedges, checking VGPR reads and overwrites against pending DS
results. This proves the register wait portion under in-order LDS completion;
the separate uniform VMEM/LGKM/barrier protocol protects shared LDS contents.
"""
import collections
import json
import re
import sys
from pathlib import Path


def regs(text):
    result = set()
    for lo, hi, single in re.findall(r"\bv(?:\[(\d+):(\d+)\]|(\d+))\b", text):
        if single:
            result.add(int(single))
        else:
            result.update(range(int(lo), int(hi) + 1))
    # A bracket is not a word character, so the final word-boundary above
    # cannot match ranges followed by punctuation. Parse ranges explicitly.
    for lo, hi in re.findall(r"\bv\[(\d+):(\d+)\]", text):
        result.update(range(int(lo), int(hi) + 1))
    return result


def parse(path):
    functions = []
    for lineno, line in enumerate(Path(path).read_text().splitlines(), 1):
        symbol = re.match(r"^([0-9a-f]+) <([^>]+)>:", line)
        if symbol:
            functions.append({"name": symbol[2], "base": int(symbol[1], 16), "code": []})
            continue
        match = re.match(r"\s*(.*?)\s*// ([0-9A-Fa-f]+):", line)
        if not match or not functions:
            continue
        asm, address = match[1], int(match[2], 16)
        if not asm:
            continue
        instruction = {"asm": asm, "addr": address, "line": lineno}
        if asm.startswith(("s_branch ", "s_cbranch")):
            target = re.search(r"<[^>]+\+0x([0-9a-fA-F]+)>", line)
            assert target, line
            instruction["target"] = functions[-1]["base"] + int(target[1], 16)
        functions[-1]["code"].append(instruction)
    return functions


def audit(function):
    code = function["code"]
    address_to_index = {ins["addr"]: i for i, ins in enumerate(code)}
    work = collections.deque([(0, ())])
    seen = set()
    hazards = set()
    mfma_seen = set()
    event_regs = {}
    event_kind = {}
    max_pending = 0
    for index, ins in enumerate(code):
        asm = ins["asm"]
        if asm.startswith("ds_read"):
            event_regs[index] = regs(asm.split(",", 1)[0])
            event_kind[index] = "read"
        elif asm.startswith("ds_write"):
            event_regs[index] = set()
            event_kind[index] = "write"
        elif asm.startswith("s_load_"):
            event_regs[index] = set()
            event_kind[index] = "smem"

    while work:
        index, pending = work.popleft()
        state = index, pending
        if state in seen:
            continue
        seen.add(state)
        assert len(seen) < 1000000, "unexpected CFG-state growth"
        ins = code[index]
        asm = ins["asm"]
        max_pending = max(max_pending, len(pending))
        wait = re.search(r"\blgkmcnt\((\d+)\)", asm)
        if wait:
            count = int(wait[1])
            pending = pending[-count:] if count else ()

        pending_registers = set().union(*(event_regs[event] for event in pending)) if pending else set()
        # Reads and writes to a still-pending destination both need a wait.
        # Include all VGPR operands, even load destinations (WAW protection).
        touched = regs(asm)
        if asm.startswith("s_waitcnt"):
            touched = set()
        for register in touched & pending_registers:
            producers = tuple(code[event]["line"] for event in pending if register in event_regs[event])
            hazards.add((ins["line"], asm, register, producers))
        if asm.startswith("v_mfma_scale"):
            mfma_seen.add(index)
        if index in event_regs:
            pending = pending + (index,)

        if asm.startswith("s_endpgm"):
            continue
        successors = []
        if "target" in ins:
            successors.append(address_to_index[ins["target"]])
        if not asm.startswith("s_branch ") and index + 1 < len(code):
            successors.append(index + 1)
        for next_index in successors:
            work.append((next_index, pending))

    return {
        "name": function["name"],
        "cfg_states": len(seen),
        "static_mfma_checked": len(mfma_seen),
        "max_pending_lgkm_events": max_pending,
        "hazards": [{"line": line, "asm": asm, "register": register, "producer_lines": producers}
                    for line, asm, register, producers in sorted(hazards)],
    }


if __name__ == "__main__":
    result = {"isa": str(Path(sys.argv[1]).resolve()), "kernels": [audit(function) for function in parse(sys.argv[1])]}
    print(json.dumps(result, indent=2))
    sys.exit(any(kernel["hazards"] for kernel in result["kernels"]))
