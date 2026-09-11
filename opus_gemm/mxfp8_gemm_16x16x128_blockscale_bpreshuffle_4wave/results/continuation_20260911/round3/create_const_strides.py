#!/usr/bin/env python3
"""Use stride identities already enforced by both public launch paths."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import sys

root = Path(__file__).resolve().parent
work = Path((root / "work_path.txt").read_text().strip())
baseline = work / "baseline"
launch = (baseline / "gemm_a8w8_blockscale_bpreshuffle_launch.cc").read_text()
assert "a.stride_a != a.k || a.stride_b != a.k || a.stride_c != a.n" in launch
assert "a.stride_a_batch != a.m * a.k || a.stride_b_batch != a.n * a.k" in launch
assert "a.stride_sfa != a.m" in launch and "a.stride_sfb != a.k / 128" in launch
ab = {"stride_a": "T::REQUIRED_K", "stride_b": "T::REQUIRED_K"}
all_contract = dict(ab, stride_c="kargs.n", stride_sfa="kargs.m", stride_sfb="T::SCALE_PANEL_K_TILES", stride_a_batch="(kargs.m * T::REQUIRED_K)", stride_b_batch="(kargs.n * T::REQUIRED_K)", stride_c_batch="(kargs.m * kargs.n)", stride_sfa_batch="(kargs.m * T::SCALE_PANEL_K_TILES)", stride_sfb_batch="((kargs.n / T::GROUP_N) * T::SCALE_PANEL_K_TILES)")
configs = {
    "stride_ab_const": ("baseline", ab),
    "stride_contract": ("baseline", all_contract),
    "stride_sym_single16": ("symmetric_single16", all_contract),
    "stride_asym_pairs8": ("asym_pairs8", all_contract),
    "stride_sym_bf16": ("symmetric_single16", {field: f"(T::OUTPUT_BF16 ? {expression} : kargs.{field})" for field, expression in all_contract.items()}),
}
requested = set(sys.argv[1:]) or set(configs)
assert requested <= set(configs)
for name, (parent_name, replacements) in configs.items():
    if name not in requested:
        continue
    parent = work / parent_name
    source = (parent / "tmpl.hpp").read_text()
    candidate = source
    for field, expression in replacements.items():
        candidate, count = re.subn(r"\bkargs\." + field + r"\b", expression, candidate)
        assert count > 0, field
    # Retain the runtime loop form required by the existing pin-aware LLVM.
    assert "const int loops = ceil_div_scale(kargs.k, T::B_K);" in candidate
    candidate = candidate.replace("    using T = opus::remove_cvref_t<Traits>;", "    using T = opus::remove_cvref_t<Traits>;\n    // C ABI and CLI enforce contiguous matrix/scale strides. K is 8192\n    // on this path, so use those identities directly in address generation.", 1)
    dest = work / name
    dest.mkdir(exist_ok=False)
    for path in baseline.iterdir():
        if path.is_file() and (path.suffix in [".h", ".hpp", ".cc"] or path.name == "Makefile"):
            shutil.copy2(path, dest / path.name)
    (dest / "tmpl.hpp").write_text(candidate)
    manifest = dict(name=name, parent=parent_name, parent_sha256=hashlib.sha256(source.encode()).hexdigest(), source_sha256=hashlib.sha256(candidate.encode()).hexdigest(), replacements=replacements, contract="Existing public C ABI rejects all incompatible strides; CLI constructs the same contiguous strides.", runtime_k_loop_preserved=True, not_a_full_gemm=False)
    (dest / "candidate.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(name)
