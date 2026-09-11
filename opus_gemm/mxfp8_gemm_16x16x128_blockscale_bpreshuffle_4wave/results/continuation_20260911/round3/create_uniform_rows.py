#!/usr/bin/env python3
"""Use contiguous padded LDS rows for both symmetric producer wave pairs."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import sys

root = Path(__file__).resolve().parent
work = Path((root / 'work_path.txt').read_text().strip())
baseline = work / 'baseline'
configs = {
    'sym_rows': ('symmetric_single16', False, False),
    'sym_rows_quad': ('symmetric_single16', True, False),
    'sym_rows_vaddr': ('symmetric_single16', True, True),
    'sym_rel24_vaddr': ('sym_release24_spread', True, True),
}
requested = set(sys.argv[1:]) or set(configs)
assert requested <= set(configs)

# Compare the new producer mapping against the unchanged consumer LDS image.
for matrix in ['a', 'b']:
    seen = set()
    for half in range(2):
        for issue in range(16):
            for lane in range(64):
                if matrix == 'a':
                    row = half * 128 + (issue // 2) * 16 + (lane // 8) * 2 + issue % 2
                    k = (lane % 8) * 16
                    expected_lds = (row // 16 * 2 + row % 2) * 1056 + (row % 16 // 2) * 128 + k
                else:
                    row = half * 128 + (issue // 2) * 16 + lane % 16
                    k = (issue % 2) * 64 + (lane // 16) * 16
                    expected_lds = (row // 16 * 2 + k // 64) * 1056 + (k % 64 // 16 * 16 + row % 16) * 16
                assert expected_lds == (half * 16 + issue) * 1056 + lane * 16
                ioffset = (issue % 4) * 1056 - (32 if issue % 4 else 0)
                source_offset = (issue // 2) * 16 * 8192 + (issue % 2) * (8192 if matrix == 'a' else 1024)
                assert source_offset - ioffset >= 0
                for byte in range(16):
                    assert (row, k + byte) not in seen
                    seen.add((row, k + byte))
    assert seen == {(row, k) for row in range(256) for k in range(128)}

for name, (parent_name, quad, cached) in configs.items():
    if name not in requested:
        continue
    parent = work / parent_name
    original = (parent / 'tmpl.hpp').read_text()
    begin = original.index('    // Each wave computes C and produces one matrix.')
    end = original.index('\n    };', begin) + len('\n    };')
    prefix = '''    // Both matrix producer pairs now own contiguous padded LDS rows.
    // A wave owns one M128 half and alternates row parity across requests.
    // B wave ownership is unchanged. The consumer LDS image is unchanged.
    const bool produces_a = wave_id_n == 0;
    auto g_matrix = produces_a ? g_a : g_b;
    const int matrix_vector_offset = produces_a
        ? (wave_id_m * T::HALF_B_M + (lane_id / 8) * 2) * kargs.stride_a + (lane_id % 8) * 16
        : wave_id_m * T::HALF_B_N * kargs.stride_b + lane_id * 16;
    // Both public launch paths enforce stride_a == stride_b == k.
    const int matrix_pair_stride = 16 * kargs.stride_a;
    const int matrix_odd_stride = produces_a ? kargs.stride_a : 1024;
    const int matrix_k_stride = produces_a ? T::B_K : T::B_K * 16;
    constexpr int matrix_pitch = T::smem_linear_wave + T::smem_padding;
    auto* matrix_lds_base = (produces_a ? s_a.ptr : s_b.ptr) + wave_id_m * smem_a_elem;
    static_assert(smem_a_elem == smem_b_elem);
'''
    if cached:
        prefix += '''    // Materialize immutable address deltas once in VGPRs, leaving only
    // the shared K offset in the scalar issue path. IOFFSET shifts both ends.
    opus::vector_t<int, 16> matrix_addresses;
    opus::static_for<16>([&](auto issue_i) {
        constexpr int issue = decltype(issue_i)::value;
        constexpr int local = issue % 4;
        constexpr int immediate = local * matrix_pitch - (local ? 32 : 0);
        int address = matrix_vector_offset + (issue / 2) * matrix_pair_stride
            + (issue % 2) * matrix_odd_stride - immediate;
        asm volatile("" : "+v"(address));
        matrix_addresses[issue] = address;
    });
'''
    prefix += '''    auto prefetch_matrix_issue = [&](auto issue_i, int matrix_stage, int k_tile) {
        constexpr int issue = decltype(issue_i)::value;
'''
    if quad:
        prefix += '''        constexpr int local = issue % 4;
        constexpr int immediate = local * matrix_pitch - (local ? 32 : 0);
        auto* dst = matrix_lds_base + matrix_stage * 2 * smem_a_elem
            + (issue / 4) * 4 * matrix_pitch + (local ? 32 : 0);
'''
    else:
        prefix += '''        constexpr int immediate = 0;
        auto* dst = matrix_lds_base + matrix_stage * 2 * smem_a_elem + issue * matrix_pitch;
'''
    prefix += '''        g_matrix.template async_load<16>(
            reinterpret_cast<void*>(reinterpret_cast<__UINTPTR_TYPE__>(dst)),
'''
    if cached:
        prefix += '''            matrix_addresses[issue], k_tile * matrix_k_stride,
'''
    else:
        prefix += '''            matrix_vector_offset,
            k_tile * matrix_k_stride + (issue / 2) * matrix_pair_stride
                + (issue % 2) * matrix_odd_stride - immediate,
'''
    prefix += '''            opus::number<immediate>{}, opus::number<0>{});
    };'''
    candidate = original[:begin] + prefix + original[end:]
    dest = work / name
    dest.mkdir(exist_ok=False)
    for path in baseline.iterdir():
        if path.is_file() and (path.suffix in ['.h', '.hpp', '.cc'] or path.name == 'Makefile'):
            shutil.copy2(path, dest / path.name)
    (dest / 'tmpl.hpp').write_text(candidate)
    (dest / 'candidate.json').write_text(json.dumps(dict(
        name=name, parent=parent_name,
        parent_sha256=hashlib.sha256(original.encode()).hexdigest(),
        source_sha256=hashlib.sha256(candidate.encode()).hexdigest(),
        lds_mapping_audit='PASS: every A/B byte maps to the unchanged consumer layout, once per tile',
        immediate_groups=quad, cached_vgpr_offsets=cached,
        matrix_bytes_per_tile=65536,
        changes=['A producer waves each own one M128 half', 'A and B have equal LDS row stride', 'scalar pair stride shared under enforced contiguous input contract'],
        not_a_full_gemm=False,
    ), indent=2) + '\n')
    print(name)
