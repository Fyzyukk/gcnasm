#!/usr/bin/env python3
"""Check shared-VOFFSET MUBUF coordinates and nonnegative uniform offsets."""
import hashlib
import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
WORK = Path((HERE / "work_path.txt").read_text().strip())
DEST = HERE / "matrix_mapping"
DEST.mkdir(exist_ok=True)
MASK = (1 << 32) - 1

for name in sys.argv[1:]:
    source = (WORK / name / "tmpl_generic.hpp").read_text()
    cfg = json.loads((WORK / name / "candidate.json").read_text())["config"]
    group = cfg["matrix_cached_lane_addresses"]
    assert group == cfg["matrix_uniform_row_group_issues"] and group in (4, 8)
    assert f"opus::vector_t<int, {group}> matrix_addresses;" in source
    assert f"matrix_addresses[issue % {group}]" in source
    assert f"(issue / {group}) * {group // 2} * matrix_pair_stride" in source
    assert "__builtin_amdgcn_readfirstlane(k_tile * matrix_k_stride" in source
    # Algebraic equality applies to every K: issue/2 decomposes into complete
    # groups and the cached in-group issue. Enumerations exercise signed
    # intermediate VOFFSETs, K-panel transitions and the largest legal K.
    for issue in range(16):
        assert issue // 2 == (issue // group) * (group // 2) + (issue % group) // 2
        assert issue % 4 == (issue % group) % 4
        assert issue % 2 == (issue % group) % 2
    checks, negative_voffsets = 0, 0
    max_soffset = 0
    kvals = [128, 256, 384, 8192, 8320, 32896, 8388480]
    for k in kvals:
        loops = k // 128
        tiles = sorted({i for i in [0, 1, 2, 63, 64, loops - 1] if 0 <= i < loops})
        for is_a in [True, False]:
            odd_stride = k if is_a else 1024
            k_stride = 128 if is_a else 2048
            for half in range(2):
                for lane in range(64):
                    vector = ((half * 128 + lane // 8 * 2) * k + lane % 8 * 16
                              if is_a else half * 128 * k + lane * 16)
                    for issue in range(16):
                        immediate = issue % 4 * 1056
                        cached = issue % group
                        old_voffset = vector + issue // 2 * 16 * k + issue % 2 * odd_stride - immediate
                        new_voffset = vector + cached // 2 * 16 * k + cached % 2 * odd_stride - immediate
                        for tile in tiles:
                            old_soffset = tile * k_stride
                            new_soffset = old_soffset + issue // group * (group // 2) * 16 * k
                            assert 0 <= new_soffset < (1 << 31)
                            expected = old_voffset + old_soffset + immediate
                            assert new_voffset + new_soffset + immediate == expected
                            assert ((old_voffset & MASK) + old_soffset + immediate) & MASK == expected
                            assert ((new_voffset & MASK) + new_soffset + immediate) & MASK == expected
                            assert 0 <= expected <= 256 * k - 16
                            assert expected % 16 == 0
                            checks += 1
                            negative_voffsets += int(new_voffset < 0)
                            max_soffset = max(max_soffset, new_soffset)
    resident = cfg.get("final_operands_resident", False)
    if resident:
        tail = source.split("    // Consume the final resident tile", 1)[1]
        assert "v_a[1] = load<T::VEC_A>" not in tail
        assert "v_sfb[1] = load_sfb_dword" not in tail
        assert "v_b = load<T::VEC_B>" not in tail
        assert "    v_b = v_b_second;" in tail
        assert "s_waitcnt_lgkmcnt(0_I);" in tail.split("    // Publish each", 1)[0]
    report = dict(name=name, status="PASS", cached_vgpr_addresses=group,
                  request_vectors_enumerated=checks, tested_k=kvals,
                  algebraic_identity_for_all_positive_k=True,
                  nonnegative_soffset=True, maximum_tested_soffset=max_soffset,
                  negative_intermediate_voffsets=negative_voffsets,
                  unchanged_global_and_lds_coordinates=True,
                  final_resident_operands=resident,
                  source_sha256=hashlib.sha256(source.encode()).hexdigest(),
                  scope="MUBUF VOFFSET+SOFFSET+IOFFSET identity, alignment and ABI bounds. LDS destination formula remains unchanged. Linked uniformity/readiness and GPU checks are separate.")
    (DEST / (name + ".json")).write_text(json.dumps(report, indent=2) + "\n")
    print(name, "PASS", checks, "request vectors;", group, "cached lane addresses")
