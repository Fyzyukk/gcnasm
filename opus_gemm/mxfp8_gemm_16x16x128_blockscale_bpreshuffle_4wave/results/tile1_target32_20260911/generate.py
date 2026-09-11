#!/usr/bin/env python3
"""Screen K-loop scheduling changes on the current 4-wave/tile1 baseline."""
from collections import defaultdict
import difflib
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

here = Path(__file__).resolve().parent
root = here.parents[1]
expected = "1b1c87b28c1ae645cd8986e00aae0f870f089044c8a8eac4d761e396deafe53a"
original = (root / "tmpl.hpp").read_text()
assert hashlib.sha256(original.encode()).hexdigest() == expected
work = Path(tempfile.mkdtemp(prefix="mxfp8_tile1_target32_20260911_"))
files = ["Makefile", "tmpl.hpp", "tmpl_generic.hpp", "traits.hpp", "kernel_dispatch.hpp",
         "gemm_a8w8_mxfp8_scale_common.h", "gemm_a8w8_mxfp8_scale_host.cc",
         "gemm_a8w8_mxfp8_scale_kernel.cc", "gemm_a8w8_blockscale_bpreshuffle_launch.cc",
         "blockscale_bpreshuffle.py"]
base = work / "baseline"
base.mkdir()
for file in files:
    shutil.copy2(root / file, base / file)
shutil.copytree(root / "build", base / "build")
(here / "work_path.txt").write_text(str(work) + "\n")

begin = original.index("#pragma unroll 4")
end = original.index("    // Consume the final resident tile with")
loop = original[begin:end]
issue_pattern = re.compile(
    r"\n        prefetch_matrix_issue\(opus::number<\d+>\{\}, stage, future_tile\);\n"
    r"        __builtin_amdgcn_sched_group_barrier\(0x20, 1, 0\);\n"
    r"        __builtin_amdgcn_sched_barrier\(0\);\n"
)
loop, count = issue_pattern.subn("\n", loop)
assert count == 16
publication_pattern = re.compile(
    r"\n        // MFMA8: finish the previous iteration's operand reads,\n"
    r"        // publish t\+1, and release the old stage for the t\+2 producers\.\n"
    r"        __builtin_amdgcn_s_setprio\(0\);\n"
    r"        s_waitcnt_vmcnt\(0_I\);\n"
    r"        s_waitcnt_lgkmcnt\(0_I\);\n"
    r"        __builtin_amdgcn_s_barrier\(\);\n"
    r"        __builtin_amdgcn_sched_barrier\(0\);\n"
    r"        __builtin_amdgcn_s_setprio\(1\);\n"
)
loop, count = publication_pattern.subn("\n", loop)
assert count == 1
pattern = re.compile(r"        MXFP8_MMA_(PAIR|ONE)\(.*?\);\n        (?:sched_barrier_pairs_scale|__builtin_amdgcn_sched_barrier)\([^;]*\);", re.S)
positions = {}
count = 0
for match in pattern.finditer(loop):
    if not count:
        positions[0] = match.start()
    count += 2 if match[1] == "PAIR" else 1
    positions[count] = match.end()
assert count == 64

configs = {
    "release0_pairs": dict(release=0, sites=list(range(0, 31, 2))),
    "release12_pairs": dict(release=12, sites=list(range(12, 43, 2))),
    "release8_dense2": dict(release=8, sites=[s for s in range(8, 23, 2) for _ in range(2)]),
    "release0_dense2": dict(release=0, sites=[s for s in range(0, 15, 2) for _ in range(2)]),
    "release8_groups4": dict(release=8, sites=[s for s in [8, 16, 24, 32] for _ in range(4)]),
    "release8_burst16": dict(release=8, sites=[8] * 16),
    "unroll1": dict(unroll=1),
    "unroll2": dict(unroll=2),
}
records = []
for name, config in configs.items():
    if "unroll" in config:
        candidate = original.replace("#pragma unroll 4", f"#pragma unroll {config['unroll']}", 1)
    else:
        release = config["release"]
        assert len(config["sites"]) == 16 and min(config["sites"]) >= release
        edits = defaultdict(str)
        edits[release] = f"""

        // MFMA{release}: complete prior operand reads and publish t+1.
        // Release the old LDS stage before its t+2 matrix requests.
        __builtin_amdgcn_s_setprio(0);
        s_waitcnt_vmcnt(0_I);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);
        __builtin_amdgcn_s_setprio(1);
"""
        groups = defaultdict(list)
        for issue, site in enumerate(config["sites"]):
            groups[site].append(issue)
        for site, issues in groups.items():
            edits[site] += "\n" + "".join(f"        prefetch_matrix_issue(opus::number<{i}>{{}}, stage, future_tile);\n" for i in issues)
            edits[site] += f"        __builtin_amdgcn_sched_group_barrier(0x20, {len(issues)}, 0);\n        __builtin_amdgcn_sched_barrier(0);\n"
        candidate_loop = loop
        for site, text in sorted(edits.items(), key=lambda item: positions[item[0]], reverse=True):
            pos = positions[site]
            candidate_loop = candidate_loop[:pos] + text + candidate_loop[pos:]
        candidate_loop = candidate_loop.replace("old stage was released at MFMA8", f"old stage was released at MFMA{release}")
        candidate = original[:begin] + candidate_loop + original[end:]
        assert candidate.count("__builtin_amdgcn_s_barrier();") == original.count("__builtin_amdgcn_s_barrier();")
    directory = work / name
    directory.mkdir()
    for file in files:
        shutil.copy2(base / file, directory / file)
    (directory / "tmpl.hpp").write_text(candidate)
    patch_dir = here / "candidate_patches" / name
    patch_dir.mkdir(parents=True, exist_ok=True)
    (patch_dir / "tmpl.patch").write_text("".join(difflib.unified_diff(
        original.splitlines(True), candidate.splitlines(True), fromfile="a/tmpl.hpp", tofile="b/tmpl.hpp")))
    record = dict(name=name, config=config, source_sha256=hashlib.sha256(candidate.encode()).hexdigest(),
                  output_tiles_per_wg=1, num_waves=4, source_mfma_order_unchanged=True)
    (patch_dir / "candidate.json").write_text(json.dumps(record, indent=2) + "\n")
    records.append(record)
manifest = dict(baseline="current regroll_release8 tile1", baseline_tmpl_sha256=expected,
                base_commit=subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip(),
                target_bf16_pflops=3.2, shape=[8192, 8192, 8192], work_directory=str(work), candidates=records)
(here / "candidate_index.json").write_text(json.dumps(manifest, indent=2) + "\n")
print(work)
for record in records:
    print(record["name"], record["config"])
