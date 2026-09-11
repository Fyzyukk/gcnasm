#!/usr/bin/env python3
"""Independent CPU-only producer and stage audit; candidate is read-only."""
from collections import Counter
from pathlib import Path
import hashlib
import json
import re

candidate = Path('/tmp/mxfp8_fourwave_e8_continue_20260910/ab_role_split_safe_b')
base = Path('/root/workspace/gcnasm_new/gcnasm-mxfp8-final-pipeline-source-20260910/opus_gemm/mxfp8_gemm_16x16x128_blockscale_bpreshuffle_4wave')
output = Path(__file__).resolve().parent / 'producer_mapping_audit.json'
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
source = (candidate / 'tmpl.hpp').read_text()
baseline = (base / 'tmpl.hpp').read_text()
expected_source_sha = '0dbee7b1831cc5a24c70822de167a22c2a8a42f6bc7776caf4d2ec645e7f91c0'
assert sha(candidate / 'tmpl.hpp') == expected_source_sha
for name in ('traits.hpp', 'tmpl_generic.hpp', 'kernel_dispatch.hpp',
             'gemm_a8w8_mxfp8_scale_common.h', 'gemm_a8w8_blockscale_bpreshuffle_launch.cc'):
    assert (candidate / name).read_bytes() == (base / name).read_bytes(), name

def body_after(text, marker):
    begin = text.index('{', text.index(marker))
    depth = 1
    end = begin + 1
    while depth:
        depth += (text[end] == '{') - (text[end] == '}')
        end += 1
    return text[begin + 1:end - 1]

for name in ('make_layout_ga_scale', 'make_layout_sa_scale', 'make_layout_gb_scale',
             'make_layout_sb_scale', 'make_layout_ra_scale', 'make_layout_rb_scale'):
    assert body_after(source, name) == body_after(baseline, name), name
for operation in ('s_waitcnt_vmcnt(0_I)', 's_waitcnt_lgkmcnt(0_I)', '__builtin_amdgcn_s_barrier()'):
    assert source.count(operation) == baseline.count(operation)
mma_calls = lambda text: [re.sub(r'\s+', '', x) for x in re.findall(r'MXFP8_MMA_(?:ONE|PAIR)\((.*?)\);', text, re.S)]
assert mma_calls(source) == mma_calls(baseline)
start, end = '// Prologue: preload', '// K64 specialization:'
assert source[source.index(start):source.index(end)] == baseline[baseline.index(start):baseline.index(end)]
tail = '// Consume the final resident tile;'
assert source[source.index(tail):] == baseline[baseline.index(tail):]
assert body_after(source, 'auto prefetch_sfa_panel =') == body_after(baseline, 'auto prefetch_sfa_panel =')

# Bind the role enumeration below to all actual calls, not just the comments.
branches = []
for match in re.finditer(r'if \(wave_id_n == ([01])\) \{', source):
    branch = body_after(source[match.start():], 'if ')
    assert '__builtin_amdgcn_s_barrier' not in branch and 'MXFP8_MMA_' not in branch
    role_wave = int(match[1])
    a_calls = re.findall(r'async_load_issue_scale<T::VEC_A, (\d)>\((.*?)\);', branch, re.S)
    b_calls = re.findall(r'async_load_issue_b_contiguous_scale<T, (\d)>\((.*?)\);', branch, re.S)
    assert bool(a_calls) != bool(b_calls)
    matrix = 'A' if a_calls else 'B'
    assert role_wave == (0 if matrix == 'A' else 1)
    calls = a_calls or b_calls
    assert len(calls) == 8
    tuples = []
    for issue, args in calls:
        args = re.sub(r'\s+', '', args)
        if matrix == 'A':
            parsed = re.fullmatch(r'g_a,s_a\.ptr,u_ga_producer_([01]),u_sa_producer_([01])\+sa_offset\(next_stage,([01])\),ga_offset\(([01]),tile\+1\)', args)
        else:
            parsed = re.fullmatch(r'g_b,s_b\.ptr,u_gb_producer_([01]),u_sb_producer_([01])\+sb_offset\(stage,([01])\),gb_offset\(([01]),future_tile\),kargs\.stride_b', args)
        assert parsed, args
        role, lds_role, half, global_half = map(int, parsed.groups())
        assert role == lds_role and half == global_half
        tuples.append((half, role, int(issue)))
    half = tuples[0][0]
    assert sorted(tuples) == [(half, role, issue) for role in range(2) for issue in range(4)]
    branches.append({'matrix': matrix, 'half': half, 'wave_n': role_wave, 'calls': len(calls)})
assert [(b['matrix'], b['half']) for b in branches] == [('A', 0), ('A', 1), ('B', 0), ('B', 1)]

K, PITCH, HALF_LDS, MATRIX_LDS = 8192, 1056, 16896, 67584
soffset_ranges = [[2**32, -1] for _ in range(4)]

def producer_map(matrix, stage, tile, split):
    result, owner_counts = {}, Counter()
    for physical_wave in range(4):
        wm, physical_wn = physical_wave % 2, physical_wave // 2
        if split and physical_wn != (0 if matrix == 'A' else 1):
            continue
        roles = range(2) if split else (physical_wn,)
        for role in roles:
            producer = 2 * role + wm
            for half in range(2):
                for issue in range(4):
                    for lane in range(64):
                        if matrix == 'A':
                            m = half * 128 + ((issue * 2 + role) * 8 + lane // 8) * 2 + wm
                            src = m * K + tile * 128 + (lane % 8) * 16
                            dst = (stage * 2 + half) * HALF_LDS + (issue * 4 + 2 * role + wm) * PITCH + lane * 16
                        else:
                            src = (half * 128 + producer * 32 + (issue // 2) * 16) * K + tile * 2048 + (issue % 2) * 1024 + lane * 16
                            dst = (stage * 2 + half) * HALF_LDS + (producer * 4 + issue) * PITCH + lane * 16
                            if split:
                                immediate = 1024 if issue == 1 else issue * PITCH
                                base_delta = issue * PITCH - immediate
                                s_os = half * 128 * K + tile * 2048
                                byte_delta = (issue // 2) * 16 * K + (issue % 2) * 1024
                                soffset = s_os + byte_delta - immediate
                                assert 0 <= soffset <= 0xffffffff
                                assert 0 <= immediate <= 4095
                                soffset_ranges[issue][0] = min(soffset_ranges[issue][0], soffset)
                                soffset_ranges[issue][1] = max(soffset_ranges[issue][1], soffset)
                                # Model the actual MUBUF unsigned scalar operand.
                                actual_global = producer * 32 * K + lane * 16 + (soffset & 0xffffffff) + immediate
                                actual_lds = (stage * 2 + half) * HALF_LDS + producer * 4 * PITCH + base_delta + lane * 16 + immediate
                                assert actual_global == src and actual_lds == dst
                        assert dst not in result
                        assert src % 16 == dst % 16 == 0
                        assert 0 <= src < src + 16 <= 256 * K
                        assert 0 <= dst < dst + 16 <= MATRIX_LDS
                        result[dst] = src
                        owner_counts[physical_wave] += 1
    assert len(result) == len(set(result.values())) == 2048
    # All requests are aligned 16-byte regions, so unique starts also prove
    # byte-disjoint stores and loads, including every 32-byte row padding gap.
    return result, owner_counts

mapping = {}
for matrix in ('A', 'B'):
    compared_requests = 0
    for stage in range(2):
        for tile in range(64):
            original, _ = producer_map(matrix, stage, tile, False)
            replacement, owners = producer_map(matrix, stage, tile, True)
            assert original == replacement
            if matrix == 'A':
                expected = {m * K + tile * 128 + k for m in range(256) for k in range(0, 128, 16)}
            else:
                expected = {ng * 16 * K + tile * 2048 + x for ng in range(16) for x in range(0, 2048, 16)}
            assert set(replacement.values()) == expected
            compared_requests += len(original)
    mapping[matrix] = {'stage_count': 2, 'k_tiles': 64, 'compared_16byte_requests': compared_requests,
                       'compared_bytes': compared_requests * 16,
                       'requests_per_stage_tile': 2048, 'unique_bytes_per_stage_tile': 32768,
                       'requests_per_active_wave_per_lane': 16,
                       'requests_per_wave_per_lane': [owners[w] // 64 for w in range(4)],
                       'missing_duplicate_changed_or_out_of_range_requests': 0}

# Explicitly expose the K0 unsigned-soffset failure avoided by Issue1.
old_k0_scalar = 1024 - 1056
assert old_k0_scalar == -32
assert (old_k0_scalar & 0xffffffff) + 1056 == 2**32 + 1024
assert 0 + 1024 == 1024
assert 32 + 1024 == 1056

# Track data validity separately for A/B because their producers run at
# different points. Register operands survive reuse of the old LDS stage.
a_stage, b_stage = [[0, 0], [None, None]], [[0, 0], [1, 1]]
a0_reg, b0_reg, scale0, scale1, consumption_events = 0, 0, 0, 0, 0
for tile in range(63):
    current, nxt = tile % 2, (tile % 2) ^ 1
    assert a0_reg == b0_reg == tile
    assert a_stage[current] == b_stage[current] == [tile, tile]
    assert b_stage[nxt] == [tile + 1, tile + 1]
    # A(t+1) is copied by waves0/1 after the first two c00 MFMAs.
    a_stage[nxt] = [tile + 1, tile + 1]
    a1_reg, b1_reg = a_stage[current][1], b_stage[current][1]
    for quadrant in ('c00', 'c10'):
        assert (a0_reg if quadrant == 'c00' else a1_reg) == b0_reg == scale0 == tile
        consumption_events += 16
    assert a0_reg == b1_reg == scale0 == tile
    consumption_events += 4
    # The common 36-MFMA publication waits for A(t+1) on waves0/1 and
    # outstanding B(t+1) on waves2/3 (all waves for the first prefetch).
    assert a_stage[nxt] == b_stage[nxt] == [tile + 1, tile + 1]
    b_stage[current] = [(tile + 2) & 63] * 2
    assert a0_reg == b1_reg == tile
    consumption_events += 12
    a0_reg, b0_reg, scale0 = a_stage[nxt][0], b_stage[nxt][0], tile + 1
    assert a1_reg == b1_reg == scale1 == tile
    consumption_events += 16
    scale1 = tile + 1
assert a0_reg == b0_reg == scale0 == scale1 == 63
assert a_stage[1] == b_stage[1] == [63, 63]
assert b_stage[0] == [0, 0]
for quadrant in ('c00', 'c10', 'c01', 'c11'):
    assert a_stage[1] == b_stage[1] == [63, 63]
    consumption_events += 16
assert consumption_events == 4096

report = {'candidate': str(candidate), 'status': 'PASS',
          'source_sha256': expected_source_sha, 'baseline_source_sha256': sha(base / 'tmpl.hpp'),
          'scope': 'CPU source mapping and lifecycle only; candidate and frozen artifacts not modified; no build or GPU launch',
          'source_checks': {'producer_branches': branches, 'mfma_calls_unchanged': True,
                            'consumer_layouts_unchanged': True, 'explicit_waits_and_barriers_unchanged': True,
                            'prologue_and_tail_unchanged': True, 'scales_unchanged': True},
          'logical_role_coverage': {'A': {'physical_wave0': [0, 2], 'physical_wave1': [1, 3]},
                                    'B': {'physical_wave2': [0, 2], 'physical_wave3': [1, 3]}},
          'mapping': mapping,
          'formulas': {'variables': 's=stage, h=half, t=K128 tile, r=logical wave_n role, w=physical_wave%2, i=issue, l=lane; P=2*r+w; K=8192',
                       'A_global': '(128*h + 2*((2*i+r)*8+l//8)+w)*K + 128*t + 16*(l%8) + byte',
                       'A_lds': '(2*s+h)*16896 + (4*i+2*r+w)*1056 + 16*l + byte',
                       'B_global': '(128*h+32*P+16*(i//2))*K + 2048*t + 1024*(i%2) + 16*l + byte',
                       'B_lds': '(2*s+h)*16896 + (4*P+i)*1056 + 16*l + byte'},
          'safe_b_unsigned_soffset': {'immediates': [0, 1024, 2112, 3168],
                                      'lds_base_deltas': [0, 32, 0, 0],
                                      'per_issue_soffset_ranges': soffset_ranges,
                                      'all_soffsets_nonnegative_and_u32': True,
                                      'old_issue1_k0_half0_soffset': -32,
                                      'old_effective_unsigned_delta': 2**32 + 1024,
                                      'new_issue1_k0_half0_soffset': 0,
                                      'new_effective_global_delta': 1024,
                                      'new_effective_lds_delta': 1056},
          'lifecycle': {'loop_iterations': 63, 'publication_after_mfma': 36,
                        'mfma_consumption_events': consumption_events, 'final_tile': 63,
                        'final_stage': 1, 'dead_wrapped_b_prefetch_stage': 0,
                        'a_tile64_loads': 0, 'premature_stage_reuse': 0},
          'conclusion': 'No producer mapping, coverage, unsigned B address, or source stage lifecycle issue found. ISA EXEC/wait/tied-MFMA/resource review is owned by the parent agent.'}
assert sha(candidate / 'tmpl.hpp') == expected_source_sha
output.write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({'status': 'PASS', 'source_sha256': expected_source_sha,
                  'mapping': mapping, 'safe_b_soffset_ranges': soffset_ranges,
                  'mfma_consumption_events': consumption_events, 'report': str(output)}, indent=2))
