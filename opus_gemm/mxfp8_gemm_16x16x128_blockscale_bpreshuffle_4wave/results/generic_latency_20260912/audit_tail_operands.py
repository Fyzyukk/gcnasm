#!/usr/bin/env python3
"""Symbolically check current/next-K operands and report linked LDS positions."""
from collections import Counter
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import sys

HERE = Path(__file__).resolve().parent
WORK = Path((HERE / "work_path.txt").read_text().strip())
DEST = HERE / "operand_schedules"

TOKEN = re.compile(
    r"(?P<mma>MXFP8_MMA_(?:ONE|PAIR)\([^;]+?\);)"
    r"|(?P<read>auto\s+\w+\s*=\s*s_[ab]\.template load<16>\(\w+\[\d+\]\);)"
    r"|(?P<load_a>load_a_mrepeat_scale<T,\s*\d+>\(s_a,\s*\w+,\s*v_a\[\d\]\);)"
    r"|(?P<load_b>load_b_range_scale<T,\s*\d+,\s*\d+>\(s_b,\s*\w+,\s*\w+\);)"
    r"|(?P<install>opus::set_slice\((?:v_a\[\d\]|v_b_second),\s*\w+,\s*opus::number<\d+>\{\},\s*opus::number<\d+>\{\}\);)"
    r"|(?P<scale>v_sf[ab]\[\d\]\s*=\s*v_sf[ab]_next\[\d\];)"
    r"|(?P<publish>__builtin_amdgcn_s_barrier\(\);)", re.S)
OFFSETS = {
    "a0_m0_prefetch_offsets": ("a", 0),
    "ra0_next_offsets": ("a", 0), "ra1_next_offsets": ("a", 1),
    "rb0_next_offsets": ("b", 0), "rb1_next_offsets": ("b", 1),
}


def source_bodies(source):
    main, penultimate = source.split("    // Penultimate runtime K128 block:", 1)
    main = main.split("    for (tile = 0; tile + 2 < loops; ++tile)", 1)[1]
    penultimate = penultimate.split("    // Consume the final resident tile", 1)[0]
    return {"main": main, "penultimate": penultimate}


def simulate(body, config):
    # A/B operands contain four repeats, each with two distinct K64 pieces.
    operands = {(matrix, half, piece): "current"
                for matrix in "ab" for half in range(2) for piece in range(8)}
    scales = {(matrix, half): "current" for matrix in "ab" for half in range(2)}
    temps, loads, installs, consumers = {}, [], [], {}
    published, mfmas = False, 0
    destinations = []
    for token in TOKEN.finditer(body):
        kind, text = token.lastgroup, token.group()
        if kind == "publish":
            assert mfmas == 5 and not published
            published = True
        elif kind == "mma":
            macro, arguments = re.fullmatch(r"MXFP8_MMA_(ONE|PAIR)\((.*)\);", text, re.S).groups()
            args = [arg.strip() for arg in arguments.split(",")]
            half, m, n = map(int, args[:3])
            assert args[3] == f"v_a[{half}]" and args[4] in ("v_b", "v_b_n1")
            b_half = int(args[4] == "v_b_n1")
            assert args[-2:] == ["v_sfa", f"v_sfb[{b_half}]"]
            ns = [n] if macro == "ONE" else [2 * n, 2 * n + 1]
            for column, dest in zip(ns, args[5:-2]):
                assert dest == f"c{half}{b_half}_{m * 4 + column}", (mfmas, text)
                assert all(operands[("a", half, m * 2 + p)] == "current" for p in range(2)), (mfmas, text, "early A overwrite")
                assert all(operands[("b", b_half, column * 2 + p)] == "current" for p in range(2)), (mfmas, text, "early B overwrite")
                assert scales[("a", half)] == scales[("b", b_half)] == "current"
                mfmas += 1
                destinations.append(dest)
                consumers[("a", half, m)] = mfmas
                consumers[("b", b_half, column)] = mfmas
        elif kind == "read":
            name, matrix, offset, piece = re.fullmatch(
                r"auto\s+(\w+)\s*=\s*s_([ab])\.template load<16>\((\w+)\[(\d+)\]\);", text).groups()
            assert published, (mfmas, "next stage has not been published")
            assert OFFSETS[offset][0] == matrix and name not in temps
            value = (*OFFSETS[offset], int(piece))
            temps[name] = value
            loads.append(dict(name=name, value=list(value), after_mfma=mfmas))
        elif kind == "install":
            dst, temp, begin, end = re.fullmatch(
                r"opus::set_slice\((v_a\[\d\]|v_b_second),\s*(\w+),\s*opus::number<(\d+)>\{\},\s*opus::number<(\d+)>\{\}\);", text).groups()
            begin, end = int(begin), int(end)
            assert end == begin + 16 and begin % 16 == 0
            value = ("a", int(dst[4]), begin // 16) if dst.startswith("v_a") else ("b", 1, begin // 16)
            assert temps[temp] == value, (dst, temp, temps[temp], value)
            operands[value] = "next"
            installs.append(dict(name=temp, value=list(value), after_mfma=mfmas))
        elif kind == "load_a":
            repeat, offset, half = re.fullmatch(
                r"load_a_mrepeat_scale<T,\s*(\d+)>\(s_a,\s*(\w+),\s*v_a\[(\d)\]\);", text).groups()
            half, repeat = int(half), int(repeat)
            assert published and OFFSETS[offset] == ("a", half)
            for piece in range(2 * repeat, 2 * repeat + 2):
                operands[("a", half, piece)] = "next"
        elif kind == "load_b":
            begin, end, offset, dst = re.fullmatch(
                r"load_b_range_scale<T,\s*(\d+),\s*(\d+)>\(s_b,\s*(\w+),\s*(\w+)\);", text).groups()
            assert dst in ("v_b", "v_b_second")
            half = int(dst == "v_b_second")
            assert published and OFFSETS[offset] == ("b", half)
            for piece in range(int(begin), int(end)):
                operands[("b", half, piece)] = "next"
        elif kind == "scale":
            dst_matrix, dst_half, src_matrix, src_half = re.fullmatch(
                r"v_sf([ab])\[(\d)\]\s*=\s*v_sf([ab])_next\[(\d)\];", text).groups()
            assert (dst_matrix, dst_half) == (src_matrix, src_half)
            scales[(dst_matrix, int(dst_half))] = "next"
    assert mfmas == 64 and len(set(destinations)) == 64
    assert set(operands.values()) == set(scales.values()) == {"next"}
    assert Counter(row["name"] for row in loads) == Counter(row["name"] for row in installs)
    for operand, after in config["tail_operand_prefetch"].items():
        matrix, half, repeat = operand[0], int(operand[1]), int(operand[-1])
        for piece in range(2):
            name = f"{operand}_early_{piece}"
            load = next(row for row in loads if row["name"] == name)
            install = next(row for row in installs if row["name"] == name)
            assert load["after_mfma"] == after == 54
            assert install["after_mfma"] == config["tail_operand_install"][operand]
            assert install["after_mfma"] == consumers[(matrix, half, repeat)]
            assert load["after_mfma"] > 5
    return dict(mfmas=mfmas, unique_accumulator_fragments=len(set(destinations)),
                next_stage_published_after=5, current_operands_preserved=True,
                next_operands_complete=True, scale_lifetimes_preserved=True,
                independent_prefetches=loads, installs=installs)


def linked_reads(path):
    spec = importlib.util.spec_from_file_location(
        "lds_parser", HERE.parent / "continuation_20260911/round3/support/audit_lds_waits.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    reports = []
    for function in module.parse(path):
        blocks, active, count = [], None, 0
        for instruction in function["code"]:
            asm = instruction["asm"]
            if asm.startswith("v_mfma"):
                if " a[0:3]," in asm:
                    if active is not None:
                        assert count == 64
                        blocks.append(active)
                    active, count = {"lds_reads_after_mfma": {}, "matrix_prefetches": 0}, 0
                assert active is not None
                count += 1
            elif active is not None and asm.startswith("ds_read"):
                active["lds_reads_after_mfma"].setdefault(str(count), []).append(dict(line=instruction["line"], asm=asm))
            elif active is not None and asm.startswith("buffer_load") and " lds" in asm:
                active["matrix_prefetches"] += 1
        assert active is not None and count == 64
        blocks.append(active)
        reports.append(dict(function=function["name"], blocks=blocks))
    return reports


def main():
    DEST.mkdir(exist_ok=True)
    for name in sys.argv[1:]:
        directory = WORK / name
        source = (directory / "tmpl_generic.hpp").read_text()
        config = json.loads((directory / "candidate.json").read_text())["config"]
        bodies = source_bodies(source)
        simulations = {label: simulate(body, config) for label, body in bodies.items()}
        linked = linked_reads(directory / "build/device.isa")
        linked_parent = linked_reads(WORK / config["operand_schedule_parent"] / "build/device.isa")
        # Identify complete t+2-producing bodies from the linked instructions,
        # not from source comments or assumed textual block numbering.
        for function, parent in zip(linked, linked_parent):
            assert function["function"] == parent["function"]
            main_blocks = [b for b in function["blocks"] if b["matrix_prefetches"] == 16]
            parent_blocks = [b for b in parent["blocks"] if b["matrix_prefetches"] == 16]
            assert len(main_blocks) == len(parent_blocks) >= 1
            for block, old in zip(main_blocks, parent_blocks):
                counts = Counter({int(k): len(v) for k, v in block["lds_reads_after_mfma"].items()})
                expected = Counter({int(k): len(v) for k, v in old["lds_reads_after_mfma"].items()})
                for operand in config["tail_operand_prefetch"]:
                    expected[54] += 2
                    expected[63 if operand == "a1_m2" else 64] -= 2
                assert all(v >= 0 for v in expected.values())
                assert counts == expected, (function["function"], counts, expected)
        # A deliberately early overwrite must fail the symbolic consumer check.
        operand = next(iter(config["tail_operand_prefetch"]))
        dst, first = ("v_a[1]", 64) if operand == "a1_m2" else ("v_b_second", 96)
        early_install = f"opus::set_slice({dst}, {operand}_early_0, opus::number<{first}>{{}}, opus::number<{first + 16}>{{}});"
        read = re.search(rf"auto {operand}_early_1 = [^;]+;", bodies["main"])
        assert read
        broken = bodies["main"][:read.end()] + "\n" + early_install + bodies["main"][read.end():]
        try:
            simulate(broken, config)
        except AssertionError:
            pass
        else:
            raise AssertionError("Early-overwrite counterexample was accepted")
        report = dict(name=name, status="PASS", source_sha256=hashlib.sha256(source.encode()).hexdigest(),
                      isa_sha256=hashlib.sha256((directory / "build/device.isa").read_bytes()).hexdigest(),
                      parent_isa_sha256=hashlib.sha256((WORK / config["operand_schedule_parent"] / "build/device.isa").read_bytes()).hexdigest(),
                      simulations=simulations, early_overwrite_counterexample_rejected=True,
                      linked_prefetch_placement_matches=True, linked_lds_reads=linked,
                      scope="Symbolic source operands for main and penultimate K blocks; exact linked LDS issue counts vs parent for every t+2-producing body. Register readiness and runtime correctness are separate checks.")
        (DEST / (name + ".json")).write_text(json.dumps(report, indent=2) + "\n")
        print(name, "PASS: both K bodies preserve every current operand, scale and accumulator; all next operands installed")


if __name__ == "__main__":
    main()
