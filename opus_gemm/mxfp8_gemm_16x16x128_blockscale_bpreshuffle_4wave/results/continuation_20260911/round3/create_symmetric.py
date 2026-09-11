#!/usr/bin/env python3
"""Build candidates with uniform, two-tile-ahead A/B producer issue sites."""
from pathlib import Path
import hashlib
import json
import re
import shutil

root = Path(__file__).resolve().parent
work = Path((root / "work_path.txt").read_text().strip())
baseline = work / "baseline"
original = (baseline / "tmpl.hpp").read_text()
branch_re = re.compile(r"        if \(wave_id_n == [01]\) \{\n.*?        \}\n        __builtin_amdgcn_sched_barrier\(0\);", re.S)
assert len(branch_re.findall(original)) == 2
source = branch_re.sub("", original)

declaration = "    auto s_b = make_smem(reinterpret_cast<D_B*>(smem_b));"
assert source.count(declaration) == 1
source = source.replace(declaration, declaration + """

    // Each wave computes C and produces one matrix. The selected resource,
    // global offsets, and LDS row stride are wave-uniform outside the loop.
    // A producers cover alternating padded rows; B producers each cover
    // one N128 half. All four waves execute the same steady issue sites.
    const bool produces_a = wave_id_n == 0;
    auto g_matrix = produces_a ? g_a : g_b;
    const int matrix_vector_offset = produces_a
        ? ((lane_id / 8) * 2 + wave_id_m) * kargs.stride_a + (lane_id % 8) * 16
        : wave_id_m * T::HALF_B_N * kargs.stride_b + lane_id * 16;
    const int matrix_pair_stride = produces_a ? 32 * kargs.stride_a : 16 * kargs.stride_b;
    const int matrix_odd_stride = produces_a ? 16 * kargs.stride_a : 1024;
    const int matrix_k_stride = produces_a ? T::B_K : T::B_K * 16;
    const int matrix_lds_row_stride = produces_a
        ? 2 * (T::smem_linear_wave + T::smem_padding)
        : T::smem_linear_wave + T::smem_padding;
    auto* matrix_lds_base = produces_a
        ? s_a.ptr + wave_id_m * (T::smem_linear_wave + T::smem_padding)
        : s_b.ptr + wave_id_m * smem_b_elem;
    static_assert(smem_a_elem == smem_b_elem);
    auto prefetch_matrix_issue = [&](auto issue_i, int matrix_stage, int k_tile) {
        constexpr int issue = decltype(issue_i)::value;
        auto* dst = matrix_lds_base + matrix_stage * 2 * smem_a_elem
            + issue * matrix_lds_row_stride;
        g_matrix.template async_load<16>(
            reinterpret_cast<void*>(reinterpret_cast<__UINTPTR_TYPE__>(dst)),
            matrix_vector_offset,
            k_tile * matrix_k_stride + (issue / 2) * matrix_pair_stride
                + (issue % 2) * matrix_odd_stride,
            opus::number<0>{}, opus::number<0>{});
    };
""")

seed = "    // K=8192 always has a second tile. Its B data is ready by the first"
assert source.count(seed) == 1
source = source.replace(seed, """    // Both matrices preload tile one. After each publication, all waves
    // refill their released matrix stage with t+2, wrapped to valid tile zero.
    async_load<T::VEC_A>(g_a, s_a.ptr, u_ga, u_sa + sa_offset(1, 0), ga_offset(0, 1));
    async_load<T::VEC_A>(g_a, s_a.ptr, u_ga, u_sa + sa_offset(1, 1), ga_offset(1, 1));

""" + seed)

# Expand only the first pair after publication for one-request issue sites.
pair = """        MXFP8_MMA_PAIR(
            0, 1, 0, v_a[0], v_b_n1, c01_4, c01_5, v_sfa, v_sfb[1]);
        sched_barrier_pairs_scale();"""
assert source.count(pair) == 1
expanded = """        MXFP8_MMA_ONE(
            0, 1, 0, v_a[0], v_b_n1, c01_4, v_sfa, v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);
        MXFP8_MMA_ONE(
            0, 1, 1, v_a[0], v_b_n1, c01_5, v_sfa, v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);"""

def inject(candidate_source, sites):
    begin = candidate_source.index("#pragma unroll 4")
    end = candidate_source.index("    // Consume the final resident tile;")
    loop = candidate_source[begin:end]
    pattern = re.compile(r"        MXFP8_MMA_(PAIR|ONE)\(.*?\);\n        (?:sched_barrier_pairs_scale|__builtin_amdgcn_sched_barrier)\([^;]*\);", re.S)
    mfma_count = 0
    positions = {}
    for match in pattern.finditer(loop):
        mfma_count += 2 if match[1] == "PAIR" else 1
        positions[mfma_count] = match.end()
    assert mfma_count == 64
    # After 36 must follow publication, not just the fourth c01 MFMA.
    publication = "        __builtin_amdgcn_s_barrier();\n        __builtin_amdgcn_sched_barrier(0);"
    assert loop.count(publication) == 1
    positions[36] = loop.index(publication) + len(publication)
    edits = []
    next_issue = 0
    for after, count in sites:
        text = f"\n        // Refill the released matrix stage after MFMA{after}.\n"
        for issue in range(next_issue, next_issue + count):
            text += f"        prefetch_matrix_issue(opus::number<{issue}>{{}}, stage, future_tile);\n"
        text += f"        __builtin_amdgcn_sched_group_barrier(0x20, {count}, 0);\n"
        text += "        __builtin_amdgcn_sched_barrier(0);"
        next_issue += count
        edits.append((positions[after], text))
    assert next_issue == 16
    for position, text in sorted(edits, reverse=True):
        loop = loop[:position] + text + loop[position:]
    return candidate_source[:begin] + loop + candidate_source[end:]

configs = {
    "symmetric_batch16": [(38, 16)],
    "symmetric_pairs8": [(i, 2) for i in [38, 42, 46, 50, 54, 58, 62, 64]],
    "symmetric_single16": [(i, 1) for i in [36, 37] + list(range(38, 65, 2))],
}

# Enumerate all producer bytes against independent matrix coordinates.
pitch = 1056
seen = {"a": set(), "b": set()}
for kind in seen:
    for producer in range(2):
        for issue in range(16):
            for lane in range(64):
                if kind == "a":
                    lds = (2 * issue + producer) * pitch + lane * 16
                    row = issue * 16 + (lane // 8) * 2 + producer
                    k = (lane % 8) * 16
                    assert lds == (row // 16 * 2 + row % 2) * pitch + (row % 16 // 2) * 128 + k
                else:
                    lds = (producer * 16 + issue) * pitch + lane * 16
                    row = producer * 128 + (issue // 2) * 16 + lane % 16
                    k = (issue % 2) * 64 + (lane // 16) * 16
                    assert lds == (row // 16 * 2 + k // 64) * pitch + (k % 64 // 16 * 16 + row % 16) * 16
                for byte in range(16):
                    assert (row, k + byte) not in seen[kind]
                    seen[kind].add((row, k + byte))
    assert seen[kind] == {(row, k) for row in range(256) for k in range(128)}

for name, sites in configs.items():
    dest = work / name
    dest.mkdir(exist_ok=False)
    for path in baseline.iterdir():
        if path.is_file() and (path.suffix in [".hpp", ".h", ".cc"] or path.name == "Makefile"):
            shutil.copy2(path, dest / path.name)
    candidate = inject(source.replace(pair, expanded) if name == "symmetric_single16" else source, sites)
    (dest / "tmpl.hpp").write_text(candidate)
    manifest = dict(name=name, baseline_sha256=hashlib.sha256(original.encode()).hexdigest(), source_sha256=hashlib.sha256(candidate.encode()).hexdigest(), issue_sites=sites, mapping_audit="PASS", bytes_per_matrix_per_tile=len(seen["a"]), two_slot_lifecycle="K0/K1 seeded, publish t+1 and release t after MFMA36, write t+2 to released stage", extra_dead_prefetch="A gains one wrapped K0 prefetch at t=62, matching B's existing valid wrap", not_a_full_gemm=False)
    (dest / "candidate.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(name)
