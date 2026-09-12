#!/usr/bin/env python3
"""Check source m0 ownership and emitted matrix requests against frozen baseline."""
import hashlib
import json
from pathlib import Path
import re
import sys

HERE = Path(__file__).resolve().parent
WORK = Path((HERE / "work_path.txt").read_text().strip())


def requests(path):
    functions = {}
    current = None
    for line in path.read_text().splitlines():
        symbol = re.fullmatch(r"[0-9A-Fa-f]+ <([^>]+)>:", line)
        if symbol:
            current = symbol[1]
            functions[current] = []
            m0 = None
            definitions = {}
        if current is None or "//" not in line:
            continue
        ins = " ".join(line.split("//", 1)[0].split())
        definition = re.match(r"s_\w+ (s\d+),", ins)
        if definition:
            definitions[definition[1]] = ins
        if re.match(r"\S+ m0,", ins):
            assert ins.startswith(("s_mov_b32 m0,", "s_add_i32 m0,")), ins
            m0 = ins
            copied = re.fullmatch(r"s_mov_b32 m0, (s\d+)", ins)
            if copied:
                expression = definitions.get(copied[1], "")
                add = re.fullmatch(r"s_add_i32 s\d+, (s\d+), (0x[0-9a-f]+|\d+)", expression)
                addk = re.fullmatch(r"s_addk_i32 (s\d+), (0x[0-9a-f]+|\d+)", expression)
                if add or addk:
                    # In the scalar remainder loop LLVM computes the group
                    # address into a temporary before moving it to m0. The
                    # baseline computes that identical base + literal in m0.
                    expr = add or addk
                    m0 = f"s_add_i32 m0, {expr[1]}, {expr[2]}"
        if ins.startswith("buffer_load") and ins.endswith(" lds"):
            assert m0 is not None
            functions[current].append(dict(request=ins, m0_assignment=m0))
        if ins.startswith("s_endpgm"):
            current = None
    assert len(functions) == 2
    return functions


reports = []
for name in sys.argv[1:]:
    directory = WORK / name
    cfg = json.loads((directory / "candidate.json").read_text())["config"]
    parent = "grid_group2" if cfg.get("grid_group") == 2 else "baseline"
    reference = requests(WORK / parent / "build/device.isa")
    source = (directory / "tmpl_generic.hpp").read_text()
    main = source.split("for (tile = 0; tile + 2 < loops; ++tile) {", 1)[1]
    main = main.split("// Penultimate runtime K128 block", 1)[0]
    group = None
    source_issues = []
    for action, value in re.findall(r"(prepare_matrix_group|issue_matrix_prepared)\(opus::number<(\d+)>", main):
        value = int(value)
        if action == "prepare_matrix_group":
            group = value
        else:
            assert group == value // 4, (name, value, group)
            source_issues.append(value)
    assert source_issues == list(range(16)), (name, source_issues)
    actual = requests(directory / "build/device.isa")
    # Address, resource and m0 registers retain their baseline allocation.
    # The explicitly materialized future-K expression changes the SOFFSET
    # register in the last unrolled iteration and the scalar remainder loop.
    # Do not require register-number identity for that ordinary C++ value;
    # record its differences and keep all other request fields exact.
    assert "int future_matrix_offset = future_tile * matrix_k_stride;" in main
    assert main.count("}, future_matrix_offset);") == 16
    scalar_register_changes = []
    for function, expected_requests in reference.items():
        assert len(actual[function]) == len(expected_requests)
        for ordinal, (expected, emitted) in enumerate(zip(expected_requests, actual[function])):
            assert expected["m0_assignment"] == emitted["m0_assignment"], (name, ordinal)
            normalize = lambda text: re.sub(r", s\d+ offen", ", SCALAR_K_OFFSET offen", text)
            assert normalize(expected["request"]) == normalize(emitted["request"]), (name, ordinal)
            if expected["request"] != emitted["request"]:
                scalar_register_changes.append(dict(function=function, ordinal=ordinal,
                                                    baseline=expected["request"], candidate=emitted["request"]))
    report = dict(name=name, status="PASS", comparison_parent=parent, source_group_order=source_issues,
                  matrix_voffset_resource_immediate_and_m0_expressions_match_baseline=True,
                  runtime_k_scalar_register_changes=scalar_register_changes,
                  requests_per_function={key:len(value) for key,value in actual.items()},
                  source_sha256=hashlib.sha256(source.encode()).hexdigest(),
                  isa_sha256=hashlib.sha256((directory / "build/device.isa").read_bytes()).hexdigest(),
                  scope="Matrix request VOFFSET/resource/immediate and m0 ownership equivalence. Runtime-K SOFFSET is compiler-derived C++ arithmetic and covered by generic/full shape checks. CFG VMEM/LGKM readiness is checked by audit.py")
    reports.append(report)
    print(name, "PASS", report["requests_per_function"])
(HERE / "m0_explicit_audit.json").write_text(json.dumps(reports, indent=2) + "\n")
