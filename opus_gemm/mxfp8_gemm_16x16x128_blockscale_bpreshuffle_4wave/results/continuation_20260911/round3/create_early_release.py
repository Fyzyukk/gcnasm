#!/usr/bin/env python3
"""Release a fully read matrix stage earlier in the symmetric pipeline.

All current A/B LDS reads issue by MFMA20. The existing full VMEM/LGKM
publication barrier can therefore move before c01 without changing operands.
Both matrices are already prefetched two tiles ahead in the parent.
"""
from pathlib import Path
import hashlib
import json
import re
import shutil
import sys

root = Path(__file__).resolve().parent
work = Path((root / "work_path.txt").read_text().strip())
baseline = work / "baseline"
parent = work / "symmetric_pairs8"
original = (parent / "tmpl.hpp").read_text()
issue_re = re.compile(
    r"\n        // Refill the released matrix stage after MFMA\d+\.\n"
    r"(?:        prefetch_matrix_issue\(.*?\);\n)+"
    r"        __builtin_amdgcn_sched_group_barrier\(0x20, \d+, 0\);\n"
    r"        __builtin_amdgcn_sched_barrier\(0\);"
)
source, count = issue_re.subn("", original)
assert count == 8
old_publication = """        // All operands for tile t are now resident in VGPRs. Complete tile
        // t+1 data and release tile t's LDS stage with the barrier, then start
        // the cold B path for tile t+2 while the final 28 MFMAs of tile t run.
        __builtin_amdgcn_s_setprio(0);
        s_waitcnt_vmcnt(0_I);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);
"""
assert source.count(old_publication) == 1
source = source.replace(old_publication, "")
source = source.replace("existing 36-MFMA\n        // barrier", "earlier publication\n        // barrier")
source = source.replace("// branch after MFMA38. The old stage was released at MFMA36.",
                        "// branch; all waves now share the symmetric issue sites.")
configs = {
    "sym_release24_spread": (24, [24, 26, 28, 30, 32, 34, 36, 38, 40, 42, 44, 46, 50, 54, 58, 62]),
    "sym_release24_dense": (24, list(range(24, 55, 2))),
    "sym_release28_dense": (28, list(range(28, 59, 2))),
}
requested = set(sys.argv[1:]) or set(configs)
assert requested <= set(configs)
for name, (release, sites) in configs.items():
    if name not in requested:
        continue
    assert len(sites) == 16 and min(sites) >= release
    begin = source.index("#pragma unroll 4")
    end = source.index("    // Consume the final resident tile;")
    loop = source[begin:end]
    pairs = list(re.finditer(r"        MXFP8_MMA_PAIR\(.*?\);\n        sched_barrier_pairs_scale\(\);", loop, re.S))
    assert len(pairs) == 32
    edits = {}
    edits[release] = f"""

        // MFMA{release}: A1 and all B1 pieces have issued from LDS by MFMA20.
        // Drain their reads, publish t+1, and release stage t for t+2.
        __builtin_amdgcn_s_setprio(0);
        s_waitcnt_vmcnt(0_I);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);
        __builtin_amdgcn_s_setprio(1);
"""
    for issue, site in enumerate(sites):
        edits[site] = edits.get(site, "") + f"""
        // One wave-uniform producer request after MFMA{site}.
        prefetch_matrix_issue(opus::number<{issue}>{{}}, stage, future_tile);
        __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);
        __builtin_amdgcn_sched_barrier(0);
"""
    for site, text in sorted(edits.items(), reverse=True):
        pos = pairs[site // 2 - 1].end()
        loop = loop[:pos] + text + loop[pos:]
    candidate = source[:begin] + loop + source[end:]
    assert candidate.count("s_waitcnt_vmcnt(0_I)") == original.count("s_waitcnt_vmcnt(0_I)")
    assert candidate.count("__builtin_amdgcn_s_barrier();") == original.count("__builtin_amdgcn_s_barrier();")
    dest = work / name
    dest.mkdir(exist_ok=False)
    for path in baseline.iterdir():
        if path.is_file() and (path.suffix in [".hpp", ".h", ".cc"] or path.name == "Makefile"):
            shutil.copy2(path, dest / path.name)
    (dest / "tmpl.hpp").write_text(candidate)
    (dest / "candidate.json").write_text(json.dumps(dict(
        name=name, parent=parent.name,
        parent_sha256=hashlib.sha256(original.encode()).hexdigest(),
        source_sha256=hashlib.sha256(candidate.encode()).hexdigest(),
        release_after_mfma=release, producer_sites=sites,
        lifecycle="Current matrix reads issue by MFMA20; full LGKM drain completes them before stage reuse. Full VMEM drain publishes both t+1 matrices. All new stores are t+2 after the barrier.",
        matrix_mapping="Identical to independently enumerated symmetric_pairs8 mapping",
        mfma_sequence_unchanged=True, not_a_full_gemm=False,
    ), indent=2) + "\n")
    print(name)
