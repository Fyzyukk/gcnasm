#!/usr/bin/env python3
"""Apply zero-instruction-count scheduling experiments to clang23 gfx950 ISA."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


MFMA = "\tv_mfma_scale_f32_16x16x128_f8f6f4 "


def opcode(line: str) -> str | None:
    stripped = line.strip()
    if not stripped or stripped.startswith((";", "#", ".")):
        return None
    return stripped.split(None, 1)[0]


def previous_instructions(lines: list[str], start: int, count: int) -> list[int]:
    found: list[int] = []
    for index in range(start - 1, -1, -1):
        if opcode(lines[index]) is not None:
            found.append(index)
            if len(found) == count:
                break
    return list(reversed(found))


def next_instructions(lines: list[str], start: int, count: int) -> list[int]:
    found: list[int] = []
    for index in range(start, len(lines)):
        if opcode(lines[index]) is not None:
            found.append(index)
            if len(found) == count:
                break
    return found


def find_b1_tail_regions(lines: list[str]) -> list[tuple[list[int], list[int], list[int]]]:
    regions: list[tuple[list[int], list[int], list[int]]] = []
    for index in range(len(lines) - 3):
        reads = list(range(index, index + 4))
        if not all(opcode(lines[pos]) == "ds_read_b128" for pos in reads):
            continue
        before = previous_instructions(lines, index, 2)
        after = next_instructions(lines, index + 4, 3)
        if len(before) != 2 or len(after) != 3:
            continue
        if not all(MFMA in lines[pos] for pos in before):
            continue
        if not all(MFMA in lines[pos] for pos in after[:2]):
            continue
        if opcode(lines[after[2]]) != "s_waitcnt" or "lgkmcnt(2)" not in lines[after[2]]:
            continue
        regions.append((before, reads, after[:2]))
    if len(regions) != 5:
        raise RuntimeError(f"expected five steady B1 tail regions, found {len(regions)}")
    return regions


def patch_b1(lines: list[str], mode: str) -> int:
    regions = find_b1_tail_regions(lines)
    patched = 0
    for before, reads, after in reversed(regions):
        if mode in {"b1_swap", "b1_war3"}:
            if mode == "b1_war3":
                latest_sources = set()
                operands = re.findall(r"v\[(\d+):(\d+)\]|\bv(\d+)\b", lines[before[1]])
                for lo, hi, scalar in operands[1:3]:
                    if scalar:
                        latest_sources.add(int(scalar))
                    else:
                        latest_sources.update(range(int(lo), int(hi) + 1))
                first_dest_match = re.search(r"v\[(\d+):(\d+)\]|\bv(\d+)\b", lines[reads[0]])
                if first_dest_match is None:
                    raise RuntimeError("B1 read has no VGPR destination")
                if first_dest_match.group(3):
                    first_dest = {int(first_dest_match.group(3))}
                else:
                    first_dest = set(range(
                        int(first_dest_match.group(1)), int(first_dest_match.group(2)) + 1
                    ))
                if not latest_sources & first_dest:
                    continue
            lines[before[0]], lines[before[1]] = lines[before[1]], lines[before[0]]
            patched += 1
            continue

        if mode == "b1_front1":
            moving = lines.pop(after[0])
            lines.insert(reads[0], moving)
            patched += 1
            continue

        if mode == "b1_split2":
            # MFMA2 shadows the first two reads; MFMA3 shadows the last two.
            first = lines.pop(after[0])
            lines.insert(reads[0], first)
            second_index = next(
                pos for pos in range(reads[0] + 1, reads[0] + 12)
                if MFMA in lines[pos]
            )
            second = lines.pop(second_index)
            ds_seen = 0
            insert_at = None
            for pos in range(reads[0] + 1, reads[0] + 12):
                if opcode(lines[pos]) == "ds_read_b128":
                    ds_seen += 1
                    if ds_seen == 2:
                        insert_at = pos + 1
                        break
            if insert_at is None:
                raise RuntimeError("could not place split MFMA")
            lines.insert(insert_at, second)
            patched += 1
            continue

        raise ValueError(mode)
    if mode == "b1_war3" and patched != 3:
        raise RuntimeError(f"expected three immediate B1 WAR sites, patched {patched}")
    return patched


def find_control_regions(lines: list[str]) -> list[tuple[int, list[int]]]:
    regions: list[tuple[int, list[int]]] = []
    for barrier, line in enumerate(lines):
        if opcode(line) != "s_barrier":
            continue
        following = next_instructions(lines, barrier + 1, 5)
        ops = [opcode(lines[pos]) for pos in following]
        if ops[:5] == [
            "s_add_i32", "s_cmp_ge_i32", "s_cbranch_scc1",
            "s_andn2_b64", "s_cbranch_vccnz",
        ]:
            regions.append((barrier, following[:5]))
        elif ops[:4] == [
            "s_cmp_ge_i32", "s_cbranch_scc1",
            "s_andn2_b64", "s_cbranch_vccnz",
        ]:
            regions.append((barrier, following[:4]))
    if len(regions) != 5:
        raise RuntimeError(f"expected five producer-control regions, found {len(regions)}")
    return regions


def patch_control_fill(lines: list[str]) -> int:
    regions = find_control_regions(lines)
    previous_barrier = -1
    with_windows: list[tuple[int, list[int], list[int]]] = []
    for barrier, controls in regions:
        nops = [
            pos for pos in range(previous_barrier + 1, barrier)
            if opcode(lines[pos]) == "s_nop"
        ]
        needed = 3 if opcode(lines[controls[0]]) == "s_add_i32" else 2
        if len(nops) < needed:
            raise RuntimeError(f"barrier line {barrier + 1}: need {needed} NOP slots")
        with_windows.append((barrier, controls, nops[-needed:]))
        previous_barrier = barrier

    for _barrier, controls, slots in reversed(with_windows):
        if len(controls) == 5:
            add, compare, _branch_scc, andn2, _branch_vcc = controls
            moving = [lines[andn2], lines[add], lines[compare]]
            remove = [andn2, compare, add]
        else:
            compare, _branch_scc, andn2, _branch_vcc = controls
            moving = [lines[andn2], lines[compare]]
            remove = [andn2, compare]

        for slot, instruction in zip(slots, moving):
            lines[slot] = instruction
        for pos in sorted(remove, reverse=True):
            del lines[pos]
    lines[:] = "".join(lines).splitlines(keepends=True)
    return len(regions)


def patch_vadd_gap(lines: list[str]) -> int:
    matches = []
    for index, line in enumerate(lines):
        if not re.match(r"\s*v_add_u32_e32 v158, s2, v139\s*$", line):
            continue
        previous = previous_instructions(lines, index, 1)
        following = next_instructions(lines, index + 1, 2)
        if (
            len(previous) == 1
            and MFMA in lines[previous[0]]
            and "v[158:165]" in lines[previous[0]]
            and len(following) == 2
            and opcode(lines[following[0]]) == "s_nop"
            and MFMA in lines[following[1]]
            and "v[158:165]" not in lines[following[1]]
        ):
            matches.append((index, following[1]))
    if len(matches) != 1:
        raise RuntimeError(f"expected one v158 anti-dependency site, found {len(matches)}")

    source, target = matches[0]
    moving = lines.pop(source)
    if source < target:
        target -= 1
    lines.insert(target + 1, moving)
    return 1


def add_buffer_offset(line: str, old_soffset: str, new_soffset: str, offset: int) -> str:
    needle = f", {old_soffset} offen lds"
    replacement = f", {new_soffset} offen offset:{offset} lds"
    if needle not in line:
        raise RuntimeError(f"unexpected buffer-load spelling: {line.strip()}")
    return line.replace(needle, replacement)


def patch_vmem_imm_offset(lines: list[str]) -> int:
    regions = find_control_regions(lines)
    patches: list[tuple[int, int, list[int], list[int], str, int]] = []
    for _barrier, controls in regions:
        branch_vcc = controls[-1]
        window = next_instructions(lines, branch_vcc + 1, 40)
        initial = None
        for pos in window:
            match = re.match(
                r"\s*s_add_i32 (s[67]), s93, (0x[0-9a-f]+)\s*$", lines[pos]
            )
            if match:
                initial = (pos, match.group(1), int(match.group(2), 16))
                break
            if opcode(lines[pos]) == "s_barrier":
                break
        if initial is None:
            continue
        initial_pos, soffset, immediate = initial
        loads: list[int] = []
        middle = None
        for pos in window:
            if pos <= initial_pos:
                continue
            if opcode(lines[pos]) == "buffer_load_dwordx4" and f", {soffset} offen lds" in lines[pos]:
                loads.append(pos)
            if re.match(
                rf"\s*s_add_i32 {soffset}, {soffset}, s45\s*$", lines[pos]
            ):
                middle = pos
            if len(loads) == 8:
                break
        if len(loads) != 8 or middle is None:
            raise RuntimeError(
                f"line {initial_pos + 1}: expected eight loads and middle offset add"
            )
        if not all(pos < middle for pos in loads[:4]) or not all(pos > middle for pos in loads[4:]):
            raise RuntimeError(f"line {initial_pos + 1}: malformed 4+4 load split")
        patches.append((initial_pos, middle, loads[:4], loads[4:], soffset, immediate))

    if len(patches) != 4:
        raise RuntimeError(f"expected four compact 8-VMEM regions, found {len(patches)}")

    for initial, middle, first, second, soffset, immediate in reversed(patches):
        for pos in first:
            lines[pos] = add_buffer_offset(lines[pos], soffset, "s93", immediate)
        for pos in second:
            lines[pos] = add_buffer_offset(lines[pos], soffset, soffset, immediate)
        lines[middle] = re.sub(
            rf"s_add_i32 {soffset}, {soffset}, s45",
            f"s_add_i32 {soffset}, s93, s45",
            lines[middle],
        )
        del lines[initial]
    return len(patches)


def patch_setup_resource(lines: list[str]) -> int:
    regions = find_control_regions(lines)
    patches: list[tuple[list[int], list[int]]] = []
    prior_barrier = -1
    for barrier, controls in regions:
        # The large backedge still needs the old s18 to form its loop index.
        if "s18, 2" in lines[controls[0]]:
            prior_barrier = barrier
            continue
        branch_vcc = controls[-1]
        following = next_instructions(lines, branch_vcc + 1, 10)
        resource = [
            pos for pos in following
            if re.match(r"\s*s_mov_b32 s1[89], s1[45]\s*$", lines[pos])
        ]
        if len(resource) != 2 or "s18, s14" not in lines[resource[0]] or "s19, s15" not in lines[resource[1]]:
            raise RuntimeError(f"barrier line {barrier + 1}: missing resource restore pair")

        load_nops = []
        for pos in range(prior_barrier + 1, barrier):
            if opcode(lines[pos]) != "s_nop":
                continue
            following_one = next_instructions(lines, pos + 1, 1)
            if following_one and opcode(lines[following_one[0]]) == "buffer_load_dwordx4":
                load_nops.append(pos)
        if len(load_nops) < 2:
            raise RuntimeError(f"barrier line {barrier + 1}: missing VMEM latency slots")
        patches.append((resource, load_nops[-2:]))
        prior_barrier = barrier

    if len(patches) != 4:
        raise RuntimeError(f"expected four compact resource pairs, found {len(patches)}")
    for resource, slots in reversed(patches):
        moving = [lines[pos] for pos in resource]
        for slot, instruction in zip(slots, moving):
            lines[slot] = instruction
        for pos in sorted(resource, reverse=True):
            del lines[pos]
    return len(patches)


def patch_setup_m0(lines: list[str]) -> int:
    regions = find_control_regions(lines)
    patches: list[tuple[int, int]] = []
    prior_barrier = -1
    for barrier, controls in regions:
        if "s18, 2" in lines[controls[0]]:
            prior_barrier = barrier
            continue
        branch_vcc = controls[-1]
        following = next_instructions(lines, branch_vcc + 1, 4)
        m0 = next(
            (pos for pos in following if re.match(r"\s*s_mov_b32 m0, s\d+\s*$", lines[pos])),
            None,
        )
        if m0 is None:
            raise RuntimeError(f"barrier line {barrier + 1}: missing initial m0 setup")
        compute_nops = [
            pos for pos in range(prior_barrier + 1, barrier)
            if opcode(lines[pos]) == "s_nop"
            and next_instructions(lines, pos + 1, 1)
            and opcode(lines[next_instructions(lines, pos + 1, 1)[0]]) != "buffer_load_dwordx4"
        ]
        if not compute_nops:
            raise RuntimeError(f"barrier line {barrier + 1}: missing compute NOP slot")
        patches.append((m0, compute_nops[-1]))
        prior_barrier = barrier

    if len(patches) != 4:
        raise RuntimeError(f"expected four compact m0 setups, found {len(patches)}")
    for source, slot in reversed(patches):
        lines[slot] = lines[source]
        del lines[source]
    return len(patches)


def patch_ctrl_full_setup(lines: list[str]) -> int:
    regions = find_control_regions(lines)
    plans = []
    prior_barrier = -1
    for region_number, (barrier, controls) in enumerate(regions):
        if region_number == 4:
            nops = [
                pos for pos in range(prior_barrier + 1, barrier)
                if opcode(lines[pos]) == "s_nop"
            ]
            add, compare, _branch_scc, andn2, _branch_vcc = controls
            plans.append(("tail", [andn2, add, compare], nops[-3:]))
            prior_barrier = barrier
            continue

        branch_vcc = controls[-1]
        following = next_instructions(lines, branch_vcc + 1, 10)
        m0 = next(
            (pos for pos in following if re.match(r"\s*s_mov_b32 m0, s\d+\s*$", lines[pos])),
            None,
        )
        resource = [
            pos for pos in following
            if re.match(r"\s*s_mov_b32 s1[89], s1[45]\s*$", lines[pos])
        ]
        if m0 is None or len(resource) != 2:
            raise RuntimeError(f"barrier line {barrier + 1}: missing compact setup")

        load_nops = []
        for pos in range(prior_barrier + 1, barrier):
            if opcode(lines[pos]) != "s_nop":
                continue
            next_one = next_instructions(lines, pos + 1, 1)
            if next_one and opcode(lines[next_one[0]]) == "buffer_load_dwordx4":
                load_nops.append(pos)
        if len(load_nops) < 2:
            raise RuntimeError(f"barrier line {barrier + 1}: missing resource slots")

        last_load = max(
            pos for pos in range(prior_barrier + 1, barrier)
            if opcode(lines[pos]) == "buffer_load_dwordx4"
        )
        first_mfma = next(
            pos for pos in range(last_load + 1, barrier) if MFMA in lines[pos]
        )
        vcc_writes = [
            pos for pos in range(first_mfma, barrier)
            if "vcc" in lines[pos] and opcode(lines[pos]) not in {None, "s_waitcnt"}
        ]
        if vcc_writes:
            raise RuntimeError(f"barrier line {barrier + 1}: VCC clobber after hoist")

        compute_nops = [
            pos for pos in range(first_mfma, barrier) if opcode(lines[pos]) == "s_nop"
        ]
        if len(controls) == 5:
            add, compare, _branch_scc, andn2, _branch_vcc = controls
            if len(compute_nops) < 3:
                raise RuntimeError(f"barrier line {barrier + 1}: missing three compute slots")
            setup_lines = [lines[add], lines[compare], lines[m0]]
            remove = [add, compare, andn2, m0, *resource]
            setup_slots = compute_nops[-3:]
        else:
            compare, _branch_scc, andn2, _branch_vcc = controls
            if len(compute_nops) < 2:
                raise RuntimeError(f"barrier line {barrier + 1}: missing two compute slots")
            setup_lines = [lines[compare], lines[m0]]
            remove = [compare, andn2, m0, *resource]
            setup_slots = compute_nops[-2:]

        plans.append((
            "compact", first_mfma, lines[andn2], setup_slots, setup_lines,
            load_nops[-2:], [lines[pos] for pos in resource], remove,
        ))
        prior_barrier = barrier

    for plan in reversed(plans):
        if plan[0] == "tail":
            _kind, remove, slots = plan
            moving = [lines[pos] for pos in remove]
            for slot, instruction in zip(slots, moving):
                lines[slot] = instruction
            for pos in sorted(remove, reverse=True):
                del lines[pos]
            continue

        (
            _kind, first_mfma, andn2_line, setup_slots, setup_lines,
            resource_slots, resource_lines, remove,
        ) = plan
        lines[first_mfma] = andn2_line + lines[first_mfma]
        for slot, instruction in zip(setup_slots, setup_lines):
            lines[slot] = instruction
        for slot, instruction in zip(resource_slots, resource_lines):
            lines[slot] = instruction
        for pos in sorted(remove, reverse=True):
            del lines[pos]
    lines[:] = "".join(lines).splitlines(keepends=True)
    return len(regions)


def patch_setup_m0_p4(lines: list[str]) -> int:
    regions = find_control_regions(lines)
    barrier, controls = regions[3]
    branch_vcc = controls[-1]
    following = next_instructions(lines, branch_vcc + 1, 4)
    m0 = next(
        (pos for pos in following if re.match(r"\s*s_mov_b32 m0, s\d+\s*$", lines[pos])),
        None,
    )
    if m0 is None:
        raise RuntimeError("fourth compact region has no initial m0 setup")
    previous_barrier = max(
        pos for pos in range(barrier) if opcode(lines[pos]) == "s_barrier"
    )
    nops = [
        pos for pos in range(previous_barrier + 1, barrier)
        if opcode(lines[pos]) == "s_nop"
    ]
    if len(nops) < 3:
        raise RuntimeError(f"expected fourth-region compute NOPs, found {len(nops)}")
    lines[nops[-3]] = lines[m0]
    del lines[m0]
    return 1


def instruction_multiset(lines: list[str]) -> dict[str, int]:
    counts: dict[str, int] = {}
    for line in lines:
        op = opcode(line)
        if op is not None:
            counts[op] = counts.get(op, 0) + 1
    return counts


def patch(lines: list[str], mode: str) -> tuple[list[str], list[str]]:
    original = instruction_multiset(lines)
    applied: list[str] = []

    parts = mode.split("+")
    for part in parts:
        if part == "ctrl_fill":
            applied.append(f"ctrl_fill={patch_control_fill(lines)}")
        elif part in {"b1_swap", "b1_war3", "b1_front1", "b1_split2"}:
            applied.append(f"{part}={patch_b1(lines, part)}")
        elif part == "vadd_gap":
            applied.append(f"vadd_gap={patch_vadd_gap(lines)}")
        elif part == "vmem_imm_offset":
            applied.append(f"vmem_imm_offset={patch_vmem_imm_offset(lines)}")
        elif part == "setup_resource":
            applied.append(f"setup_resource={patch_setup_resource(lines)}")
        elif part == "setup_m0":
            applied.append(f"setup_m0={patch_setup_m0(lines)}")
        elif part == "ctrl_full_setup":
            applied.append(f"ctrl_full_setup={patch_ctrl_full_setup(lines)}")
        elif part == "setup_m0_p4":
            applied.append(f"setup_m0_p4={patch_setup_m0_p4(lines)}")
        else:
            raise ValueError(f"unknown mode: {part}")

    final = instruction_multiset(lines)
    expected = dict(original)
    if "ctrl_fill" in parts:
        # Four add/cmp/andn2 regions consume three NOPs; the fifth consumes two.
        expected["s_nop"] -= 14
    if "vmem_imm_offset" in parts:
        expected["s_add_i32"] -= 4
    if "setup_resource" in parts:
        expected["s_nop"] -= 8
    if "setup_m0" in parts:
        expected["s_nop"] -= 4
    if "ctrl_full_setup" in parts:
        expected["s_nop"] -= 22
    if "setup_m0_p4" in parts:
        expected["s_nop"] -= 1
    if final != expected:
        changed = sorted(set(original) | set(final))
        delta = {key: (original.get(key, 0), final.get(key, 0)) for key in changed
                 if original.get(key, 0) != final.get(key, 0)}
        raise RuntimeError(f"unexpected instruction-count change: {delta}")
    return lines, applied


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("mode")
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    lines = args.source.read_text(encoding="utf-8").splitlines(keepends=True)
    lines, applied = patch(lines, args.mode)
    args.output.write_text("".join(lines), encoding="utf-8")
    print(args.mode, " ".join(applied))


if __name__ == "__main__":
    main()
