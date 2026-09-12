#!/usr/bin/env python3
"""Reuse retired matrix LDS to coalesce BF16 output stores across each wave."""
import difflib
import hashlib
import json
from pathlib import Path
import shutil

here = Path(__file__).resolve().parent
work = Path((here / "work_path.txt").read_text().strip())
base = here / "baseline_source"
original = (base / "tmpl.hpp").read_text()
index = json.loads((here / "candidate_index.json").read_text())


def replace_once(source, old, new):
    assert source.count(old) == 1, old
    return source.replace(old, new)


def candidate(aux):
    source = replace_once(original, """    __shared__ char smem_a[smem_a_elem * 4 * sizeof(D_A)];
    __shared__ char smem_b[smem_b_elem * 4 * sizeof(D_B)];
    auto s_a = make_smem(reinterpret_cast<D_A*>(smem_a));
    auto s_b = make_smem(reinterpret_cast<D_B*>(smem_b));""", """    // One owned allocation lets the final output reuse both retired matrices.
    constexpr int matrix_lds_bytes = smem_a_elem * 4 * sizeof(D_A)
                                   + smem_b_elem * 4 * sizeof(D_B);
    alignas(16) __shared__ char smem_matrix[matrix_lds_bytes];
    auto s_a = make_smem(reinterpret_cast<D_A*>(smem_matrix));
    auto s_b = make_smem(reinterpret_cast<D_B*>(smem_matrix + smem_a_elem * 4 * sizeof(D_A)));
    auto s_c = make_smem(reinterpret_cast<D_C*>(smem_matrix));
    constexpr int c_lds_pitch = T::B_N + 8;
    static_assert(!T::OUTPUT_BF16 || T::B_M * c_lds_pitch * sizeof(D_C) == matrix_lds_bytes);""")
    source = replace_once(source, """    s_waitcnt_lgkmcnt(0_I);
    v_sfb[1] = load_sfb_dword(loops - 1, 1);""", """    s_waitcnt_lgkmcnt(0_I);
    if constexpr (T::OUTPUT_BF16) {
        // Every wave has completed all K63 matrix reads before any output write.
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);
    }
    v_sfb[1] = load_sfb_dword(loops - 1, 1);""")
    source = replace_once(source, """        return half_tile_m * T::HALF_B_M * kargs.stride_c +
               half_tile_n * T::HALF_B_N;""", """        return half_tile_m * T::HALF_B_M * (T::OUTPUT_BF16 ? c_lds_pitch : kargs.stride_c) +
               half_tile_n * T::HALF_B_N;""")
    source = replace_once(source, "const int offset = (wave_id_m * 16 + (lane_id & 15) + ((INDEX) / 4) * 32) * kargs.stride_c", "const int offset = (wave_id_m * 16 + (lane_id & 15) + ((INDEX) / 4) * 32) * c_lds_pitch")
    source = replace_once(source, """        g_c.template store<8>(__builtin_bit_cast(opus::vector_t<D_C, 8>, packed), \\
            offset, soff, opus::number<0>{}); \\""", """        s_c.template store<8>(__builtin_bit_cast(opus::vector_t<D_C, 8>, packed), \\
            offset + soff); \\""")
    source = replace_once(source, "    v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 1));", """    if constexpr (T::OUTPUT_BF16) {
        // K63 B1 was rolled into registers by the peeled K62 segment.
        v_b = v_b_second;
    } else {
        v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 1));
    }""")
    source = replace_once(source, "    MXFP8_STORE_QUADRANT(c11, 1, 1);", f"""    MXFP8_STORE_QUADRANT(c11, 1, 1);

    if constexpr (T::OUTPUT_BF16) {{
        // The padded LDS rows distribute stores from the MFMA lane layout.
        // Publish the complete output, then write contiguous rows per wave.
        __builtin_amdgcn_sched_barrier(0);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);
        opus::static_for<T::B_M * T::B_N / (T::BLOCK_SIZE * 8)>([&](auto copy_i) {{
            const int linear = thread_id_x() * 8 + decltype(copy_i)::value * T::BLOCK_SIZE * 8;
            const int output_row = linear / T::B_N;
            const int output_col = linear % T::B_N;
            const auto value = s_c.template load<8>(output_row * c_lds_pitch + output_col);
            g_c.template store<8>(value, output_row * kargs.stride_c + output_col,
                                  0, opus::number<{aux}>{{}});
        }});
    }}""")
    return source


# Audit full-WG coverage, LDS bounds, and the contiguous copy independently
# of the source macros. Numerical operand mapping is checked on the GPU.
written = set()
for wave in range(4):
    for lane in range(64):
        for hm in range(2):
            for hn in range(2):
                for fragment in range(0, 16, 2):
                    row = (wave % 2) * 16 + lane % 16 + (fragment // 4) * 32 + hm * 128
                    col = (wave // 2) * 16 + ((fragment % 4) // 2) * 64 + ((lane // 16) % 2) * 32 + (lane // 32) * 8 + hn * 128
                    assert col % 8 == 0
                    for element in range(8):
                        coord = (row, col + element)
                        assert coord not in written and max(coord) < 256
                        assert (row * 264 + col + element) * 2 < 135168
                        written.add(coord)
copied = {(linear // 256, linear % 256) for iteration in range(32) for tid in range(256)
          for linear in range(tid*8 + iteration*2048, tid*8 + iteration*2048 + 8)}
assert copied == written and len(written) == 65536
(here / "output_transpose_mapping_audit.json").write_text(json.dumps(dict(status="PASS", output_elements=len(written),
    lds_matrix_allocation_bytes=135168, output_row_pitch_bytes=528, extra_lds_bytes=0,
    boundary_before_first_output_write="lgkmcnt(0) + workgroup barrier; no subsequent matrix LDS read",
    boundary_before_global_copy="lgkmcnt(0) + workgroup barrier", output_tiles_per_wg=1), indent=2)+"\n")

for aux in [0, 2]:
    name = f"bf16_lds_epilogue_aux{aux}"
    source = candidate(aux)
    target = work / name
    shutil.copytree(base, target)
    (target / "tmpl.hpp").write_text(source)
    patches = here / "candidate_patches" / name
    patches.mkdir(parents=True)
    (patches / "tmpl.patch").write_text("".join(difflib.unified_diff(original.splitlines(True), source.splitlines(True), fromfile="a/tmpl.hpp", tofile="b/tmpl.hpp")))
    record = dict(name=name, config=dict(bf16_lds_epilogue=True, bf16_store_aux=aux, c_lds_pitch=264),
                  source_sha256=hashlib.sha256(source.encode()).hexdigest(), num_waves=4,
                  output_tiles_per_wg=1, per_accumulator_k_order_unchanged=True)
    (patches / "candidate.json").write_text(json.dumps(record, indent=2)+"\n")
    (target / "candidate.json").write_text(json.dumps(record, indent=2)+"\n")
    index["candidates"].append(record)
    print(name)
(here / "candidate_index.json").write_text(json.dumps(index, indent=2)+"\n")
