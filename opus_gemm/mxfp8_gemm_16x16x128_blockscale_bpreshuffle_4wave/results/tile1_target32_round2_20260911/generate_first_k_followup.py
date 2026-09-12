#!/usr/bin/env python3
"""Keep the first main-loop index runtime-visible for hard-pin allocation."""
import json
from experiment_utils import WORK, record_candidate, replace_once

for parent, name, unroll in [
    ("first_k_peeled_control", "first_k_control_runtime", 8),
    ("first_k_zero_i32", "first_k_zero_runtime", 8),
    ("first_k_zero_i32", "first_k_zero_runtime_u2", 2),
]:
    source = (WORK / parent / "tmpl.hpp").read_text()
    old = "#pragma unroll 8\n    for (tile = 1; tile + 2 < loops; ++tile) {"
    new = ("    int first_compute_tile = 1;\n"
           '    asm volatile("" : "+s"(first_compute_tile));\n'
           f"#pragma unroll {unroll}\n"
           "    for (tile = first_compute_tile; tile + 2 < loops; ++tile) {")
    source = replace_once(source, old, new)
    config = json.loads((WORK / parent / "candidate.json").read_text())["config"]
    config.update(runtime_first_compute_tile=True, unroll=unroll)
    record_candidate(name, source, config, parent)
