#!/usr/bin/env python3
"""Distribute the original asymmetric requests across individual MFMA windows."""
from pathlib import Path
import hashlib
import json
import re
import shutil

root = Path(__file__).resolve().parent
work = Path((root / "work_path.txt").read_text().strip())
baseline = work / "baseline"
original = (baseline / "tmpl.hpp").read_text()
branch_re = re.compile(r"        if \(wave_id_n == ([01])\) \{\n.*?        \}\n        __builtin_amdgcn_sched_barrier\(0\);", re.S)
call_re = re.compile(r"            async_load_issue(?:_b_contiguous)?_scale<[^>]+>\(.*?\);", re.S)
pair_re = re.compile(r"        MXFP8_MMA_PAIR\(\s*(.*?)\);\n        sched_barrier_pairs_scale\(\);", re.S)
branches = list(branch_re.finditer(original))
assert [match[1] for match in branches] == ["0", "1"]
requests = {match[1]: call_re.findall(match[0]) for match in branches}
assert all(len(calls) == 16 for calls in requests.values())

configs = {
    "asym_single16": {"0": [(i, 1) for i in range(1, 17)], "1": [(i, 1) for i in range(37, 53)]},
    "asym_pairs8": {"0": [(i, 2) for i in range(2, 17, 2)], "1": [(i, 2) for i in range(38, 53, 2)]},
    "asym_a_pairs_b_single": {"0": [(i, 2) for i in range(2, 17, 2)], "1": [(i, 1) for i in range(37, 53)]},
}

for name, sites in configs.items():
    source = branch_re.sub("", original)
    start = source.index("#pragma unroll 4")
    end = source.index("    // Consume the final resident tile;")
    loop = source[start:end]
    odd_sites = {site for groups in sites.values() for site, _ in groups if site % 2}
    pairs = list(pair_re.finditer(loop))
    assert len(pairs) == 32
    edits = []
    for index, match in enumerate(pairs):
        if index * 2 + 1 not in odd_sites:
            continue
        fields = [value.strip() for value in match[1].split(",")]
        assert len(fields) == 9
        hm, mr, ng, a, b, c0, c1, sa, sb = fields
        text = ""
        for part, c in enumerate([c0, c1]):
            text += f"        MXFP8_MMA_ONE(\n            {hm}, {mr}, {int(ng) * 2 + part}, {a}, {b}, {c}, {sa}, {sb});\n"
            text += "        __builtin_amdgcn_sched_group_barrier(0x08, 1, 0);\n"
            text += "        __builtin_amdgcn_sched_group_barrier(0x02, 2, 0);\n"
        edits.append((match.start(), match.end(), text.rstrip()))
    for begin, finish, text in reversed(edits):
        loop = loop[:begin] + text + loop[finish:]

    instruction_re = re.compile(r"        MXFP8_MMA_(PAIR|ONE)\(.*?\);\n(?:        (?:sched_barrier_pairs_scale|__builtin_amdgcn_sched_group_barrier)\([^;]*\);\n?)+", re.S)
    positions = {}
    ordinal = 0
    for match in instruction_re.finditer(loop):
        ordinal += 2 if match[1] == "PAIR" else 1
        positions[ordinal] = match.end()
    assert ordinal == 64
    edits = []
    for role, groups in sites.items():
        consumed = 0
        for after, count in groups:
            text = f"\n        // {'A' if role == '0' else 'B'}: {count} request(s) after MFMA{after}.\n"
            text += f"        if (wave_id_n == {role}) {{\n"
            text += "\n".join(requests[role][consumed:consumed + count]) + "\n"
            text += f"            __builtin_amdgcn_sched_group_barrier(0x20, {count}, 0);\n"
            text += "        }\n        __builtin_amdgcn_sched_barrier(0);\n"
            consumed += count
            edits.append((positions[after], text))
        assert consumed == 16
    for position, text in sorted(edits, reverse=True):
        loop = loop[:position] + text + loop[position:]
    candidate = source[:start] + loop + source[end:]
    assert call_re.findall(candidate) == call_re.findall(original)
    assert candidate.count("__builtin_amdgcn_s_barrier();") == original.count("__builtin_amdgcn_s_barrier();")
    dest = work / name
    dest.mkdir(exist_ok=False)
    for path in baseline.iterdir():
        if path.is_file() and (path.suffix in [".h", ".hpp", ".cc"] or path.name == "Makefile"):
            shutil.copy2(path, dest / path.name)
    (dest / "tmpl.hpp").write_text(candidate)
    (dest / "candidate.json").write_text(json.dumps(dict(name=name, baseline_sha256=hashlib.sha256(original.encode()).hexdigest(), source_sha256=hashlib.sha256(candidate.encode()).hexdigest(), issue_sites=sites, source_request_order_identical=True, publication_after_mfma=36, a_last_issue_after_mfma=16, b_first_issue_after_mfma=37 if odd_sites else 38, matrix_addresses_and_data_unchanged=True, not_a_full_gemm=False, performance_status="pending original GPU2 availability"), indent=2) + "\n")
    print(name)
