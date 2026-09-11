#!/usr/bin/env python3
"""Independent CPU-only review of paired SFB, early A, merged producers."""
from collections import Counter
from pathlib import Path
import ast
import difflib
import hashlib
import importlib.util
import inspect
import json
import re
import sys

REVIEW = Path(__file__).resolve().parent
ROOT = REVIEW.parent
BASE_PATH_FILE = ROOT.parent / 'baseline_path.txt'
BASE = Path(BASE_PATH_FILE.read_text().strip())
META = json.loads((ROOT / 'candidate.json').read_text())
assert Path(META['parent']) == BASE
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(ROOT / 'tmpl.hpp') == META['source_sha256']
assert sha(BASE / 'tmpl.hpp') == 'e32de77d91f66768b2caeeb6e83682b5bf14e7f576bef6303cd0df825e1de0f3'
FILES = ['tmpl.hpp', 'traits.hpp', 'Makefile', 'tmpl_generic.hpp', 'kernel_dispatch.hpp',
         'gemm_a8w8_mxfp8_scale_kernel.cc', 'gemm_a8w8_mxfp8_scale_common.h',
         'gemm_a8w8_mxfp8_scale_host.cc', 'gemm_a8w8_blockscale_bpreshuffle_launch.cc',
         'blockscale_bpreshuffle.py', 'test_blockscale_bpreshuffle.py',
         'build/device.isa', 'build/device.co', 'build/device.notes',
         'build/gemm_a8w8_blockscale_bpreshuffle.exe', 'build/libblockscale_bpreshuffle.so']
initial_hashes = {n: sha(ROOT / n) for n in FILES}
unchanged = [n for n in FILES[:11] if n != 'tmpl.hpp']
assert all(sha(ROOT / n) == sha(BASE / n) for n in unchanged)
src, old = (ROOT / 'tmpl.hpp').read_text(), (BASE / 'tmpl.hpp').read_text()
(REVIEW / 'source.patch').write_text(''.join(difflib.unified_diff(
    old.splitlines(True), src.splitlines(True), fromfile='baseline/tmpl.hpp', tofile='candidate/tmpl.hpp')))


def mma_calls(source):
    body = source[source.index('// K64 specialization:'):]
    result = []
    for kind, contents in re.findall(r'MXFP8_MMA_(ONE|PAIR)\((.*?)\);', body, re.S):
        a = [re.sub(r'\s+', '', x) for x in contents.split(',')]
        if kind == 'ONE':
            assert len(a) == 8
            result.append(tuple(a))
        else:
            assert len(a) == 9
            for j in range(2):
                result.append(tuple(a[:2] + [str(2 * int(a[2]) + j)] + a[3:5] + [a[5 + j]] + a[7:]))
    return result


assert mma_calls(src) == mma_calls(old) and len(mma_calls(src)) == 128
assert [int(x) for x in re.findall(r'MXFP8_PIN_C\(\w+, (\d+)\);', src)] == list(range(0, 256, 4))
requests = lambda s: Counter(re.sub(r'\s+', '', x) for x in re.findall(
    r'\b(async_load(?:_issue_scale|_issue_b_contiguous_scale)?<.*?\);)', s, re.S))
assert requests(src) == requests(old)
for begin, end in [('    auto prefetch_sfa_panel =', '    auto load_sfa_dword ='),
                   ('    auto load_sfa_dword =', '    auto load_sfb_dword =')]:
    assert src[src.index(begin):src.index(end)] == old[old.index(begin):old.index(end)]
assert 'load<4>(s_sfb, (k_tile * T::SCALE_N_HALVES + half_tile_n) * 4)' in src
assert '(lane_id * T::SCALE_N_HALVES + wave_id) * 4' in src
assert 'load<8>(s_sfb, (tile + 1) * T::SCALE_N_HALVES * 4)' in src
assert 'v_sfb[1] = v_sfb_next[1];' in src
assert src.index('v_sfb[1] = v_sfb_next[1];') > src.index('c11_14, c11_15, v_sfa, v_sfb[1]);')
assert 'const int future_tile = (tile + 2) & 63;' in src

# Enumerate the physical [K,half,byte] SFB image. Each producer wave owns one
# external [N128,K] row; all four packed bytes repeat the same E8M0 exponent.
panel, producers = {}, []
for wave in range(2):
    for lane in range(64):
        start = (lane * 2 + wave) * 4
        producers.append((wave, lane, start))
        for byte in range(4):
            assert start + byte not in panel
            panel[start + byte] = (wave, lane)
assert set(panel) == set(range(512)) and len(producers) == 128
for k in range(64):
    for half in range(2):
        start = (k * 2 + half) * 4
        for selector in range(4):
            assert panel[start + selector] == (half, k)
        for wave in range(4):
            for lane in range(64):
                assert panel[start] == (half, k)

# Follow both scale values through the K loop, including the final resident
# tile and the unused wrapped B matrix prefetch. The current SFB1 remains
# alive through all c01/c11 consumers before committing next[1].
current = [(0, 0), (1, 0)]
pair_ranges = []
matrix_tiles = []
for tile in range(63):
    assert current == [(0, tile), (1, tile)]
    start = (tile + 1) * 8
    assert start % 8 == 0 and 0 <= start <= 504
    pair = [panel[start], panel[start + 4]]
    assert pair == [(0, tile + 1), (1, tile + 1)]
    pair_ranges.append((tile, start, start + 7))
    current[0] = pair[0]  # Current B0 is dead after c10; read begins after MFMA38.
    assert current[1] == (1, tile)  # Required for the remaining c01/c11 calls.
    current[1] = pair[1]  # Committed only after final c11.
    a_next, b_future = tile + 1, (tile + 2) & 63
    assert 1 <= a_next <= 63 and 0 <= b_future <= 63
    matrix_tiles.append((tile, a_next, b_future))
assert current == [(0, 63), (1, 63)]
assert panel[(63 * 2 + 1) * 4] == (1, 63)  # Unchanged final SFB1 reload.
assert pair_ranges[-1] == (62, 504, 511) and matrix_tiles[-1] == (62, 63, 0)
layout = {'status': 'PASS', 'sfb_bytes_covered_once': 512, 'producer_words': 128,
          'logical_scales': 128, 'all_four_selector_bytes_identical': True,
          'paired_reads_dynamic': 63, 'paired_read_bounds': [8, 511],
          'last_pair': pair_ranges[-1], 'tail_resident_k': 63,
          'last_matrix_prefetch': {'a_next': 63, 'b_unused_wrap': 0},
          'sfa_panel_and_consumer_source_unchanged': True,
          'source_native_mfma_calls_in_order': 128, 'a_b_request_expressions_unchanged': True}

sys.path.insert(0, '/tmp/mxfp8_fourwave_bpreshuffle_20260910')
from audit_lds_waits import parse, audit, regs
HELPER = Path('/tmp/mxfp8_fourwave_e8_continue_20260910/audit_candidates/ab_role_split_safe_b_review/audit_isa_exec_wait.py')
spec = importlib.util.spec_from_file_location('ab_audit_helper', HELPER)
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)
prefix = inspect.getsource(helper.audit_roles).split('    branches = []')[0]
prefix = prefix.replace('def audit_roles(function):', 'def predicate_helper(function):')
exec(prefix + '    return value, next_consumer\n', helper.__dict__)


def role_audit(function):
    code = function['code']
    positions = {x['addr']: i for i, x in enumerate(code)}
    value, next_consumer = helper.predicate_helper(function)
    branches = []
    for i, ins in enumerate(code):
        if not ins['asm'].startswith('s_cbranch_vccnz'):
            continue
        possible = [j for j in range(max(0, i - 3), i)
                    if code[j]['asm'].startswith('s_and_b64 vcc, exec,')]
        if not possible:
            continue  # Prologue SFB publication uses a different predicate.
        pred = possible[-1]
        assert all(x['asm'].startswith('v_mfma') for x in code[pred + 1:i])
        prior = next(j for j in range(i - 1, -1, -1) if code[j]['asm'].startswith('v_mfma'))
        acc = int(re.search(r'a\[(\d+):', code[prior]['asm'])[1])
        assert acc in (4, 84)
        is_a = acc == 4
        producer_join, loads = next_consumer(i + 1)
        other_join, others = next_consumer(positions[ins['target']])
        assert producer_join == other_join and len(loads) == 16 and not others
        assert code[producer_join]['asm'].startswith('v_mfma_scale_f32_16x16x128')
        mask = code[pred]['asm'].rsplit(', ', 1)[1]
        actual = value(mask, pred)
        full = (1 << 64) - 1
        assert actual == ((0, 0, full, full) if is_a else (full, full, 0, 0)), (ins, actual)
        branches.append({'line': ins['line'], 'operand': 'A' if is_a else 'B',
                         'after_mfma': 2 if is_a else 38,
                         'producer_waves': [0, 1] if is_a else [2, 3],
                         'producer_requests': 16, 'nonproducer_requests': 0,
                         'common_next_mfma': code[producer_join]['line'], 'load_lines': loads,
                         'predicate_definition_line': code[pred]['line']})
    assert len(branches) == 10 and Counter(x['operand'] for x in branches) == {'A': 5, 'B': 5}
    return {'status': 'PASS', 'static_merged_role_branches': branches,
            'predicate_proof': 'CFG reaching definitions from v0 thread IDs to uniform wave-N masks'}


def resource_map(path):
    result = {}
    for n in re.split(r'  - \.agpr_count:', path.read_text())[1:]:
        name = re.search(r'\.name:\s*(\S+)', n)[1]
        result[name] = {key: int(re.search(r'\.' + key + r':\s*(\d+)', n)[1]) for key in
                        ['vgpr_count', 'sgpr_count', 'private_segment_fixed_size', 'group_segment_fixed_size',
                         'vgpr_spill_count', 'sgpr_spill_count', 'wavefront_size', 'max_flat_workgroup_size']}
        result[name]['agpr_count'] = int(n.splitlines()[0])
    return result


def publication_projection(function):
    m, result = 0, {'steady_vmem_waits': [], 'barriers': []}
    for i, ins in enumerate(function['code']):
        a = ins['asm']
        m += a.startswith('v_mfma')
        if 'vmcnt(' in a and m:
            result['steady_vmem_waits'].append((m, a))
        if a == 's_barrier':
            assert 'lgkmcnt(0)' in function['code'][i - 1]['asm'], ins
            result['barriers'].append(m)
    return result


old_functions = {x['name']: x for x in parse(BASE / 'build/device.isa')}
resources = resource_map(ROOT / 'build/device.notes')
base_resources = resource_map(BASE / 'build/device.notes')
reports = []
for f in parse(ROOT / 'build/device.isa'):
    name, code = f['name'], f['code']
    generic, bf16 = 'blockscale_generic' in name, 'Lb1' in name
    r = resources[name]
    assert r['agpr_count'] == 256 and r['wavefront_size'] == 64 and r['max_flat_workgroup_size'] == 256
    assert r['private_segment_fixed_size'] == r['vgpr_spill_count'] == r['sgpr_spill_count'] == 0
    assert r['group_segment_fixed_size'] == (139264 if generic else 152064)
    canonical = lambda fun: [x['asm'] for x in fun['code'] if not x['asm'].startswith('s_code_end')]
    if generic:
        assert canonical(f) == canonical(old_functions[name]) and r == base_resources[name]
    counts, last_write = Counter(), {}
    for i, ins in enumerate(code):
        a = ins['asm']
        assert not re.match(r'\S+\s+exec(?:_lo|_hi)?(?:\s|,)', a) and not a.startswith('v_cmpx')
        if not a.startswith('v_mfma'):
            continue
        assert a.startswith('v_mfma_scale_f32_16x16x128_f8f6f4')
        args = [x.strip() for x in a.split(' ', 1)[1].split(',')]
        assert args[0] == args[3]
        lo, hi = map(int, re.fullmatch(r'a\[(\d+):(\d+)\]', args[0]).groups())
        assert lo % 4 == 0 and hi == lo + 3 and hi < 256
        counts[lo] += 1
        last_write.update({x: i for x in range(lo, hi + 1)})
    assert sorted(counts) == list(range(0, 256, 4)) and set(counts.values()) == {6}
    lds, vmem = audit(f), helper.audit_vmem(f)
    assert not lds['hazards']
    ops = Counter(x['asm'].split()[0] for x in code)
    roles, prologue = None, None
    if not generic:
        roles = role_audit(f)
        assert publication_projection(f) == publication_projection(old_functions[name])
        bar = next(i for i, x in enumerate(code) if x['asm'] == 's_barrier')
        pre = code[:bar]
        dtlds = [i for i, x in enumerate(pre) if x['asm'].startswith('buffer_load') and ' lds' in x['asm']]
        vectors = [i for i, x in enumerate(pre) if x['asm'].startswith('buffer_load_dwordx4') and ' lds' not in x['asm']]
        assert len(dtlds) == 16 and len(vectors) == 4
        assert max(dtlds[:8]) < min(vectors) and max(vectors) < min(dtlds[8:])
        assert all('s[16:19]' in pre[i]['asm'] for i in dtlds[:8])
        assert all('s[8:11]' in pre[i]['asm'] for i in dtlds[8:])
        assert ops['ds_read_b64'] == 5 and ops['ds_read2_b32'] == 2
        assert ops['buffer_store_dwordx4'] == (32 if bf16 else 64)
        if bf16:
            assert ops['v_permlane16_swap_b32_e64'] == 64 and ops['v_cvt_pk_bf16_f32'] == 128
        assert all(not x['asm'].startswith(('buffer_load', 'global_load', 'flat_load')) or ' lds' in x['asm']
                   for x in code[bar + 1:])
        prologue = {'a_dtlds_before_scale_vectors': [pre[i]['line'] for i in dtlds[:8]],
                    'sfa_global_vector_reads': [pre[i]['line'] for i in vectors],
                    'b_dtlds_after_scale_vectors': [pre[i]['line'] for i in dtlds[8:]],
                    'first_publication_line': code[bar]['line']}
    reports.append({'name': name, 'resources': r, 'baseline_resources': base_resources[name],
                    'generic_isa_identical': generic, 'native_tied_mfma_C256': 384,
                    'exec_writes': 0, 'lds_wait': lds, 'vmem_wait': vmem,
                    'role_audit': roles, 'early_a_prologue': prologue,
                    'publication_and_steady_vmem_waits': None if generic else publication_projection(f),
                    'opcode_counts': dict(ops)})
assert len(reports) == 4
assert initial_hashes == {n: sha(ROOT / n) for n in FILES}, 'Frozen candidate changed during review'
result = {'status': 'CPU audit PASS', 'gpu_launched': False, 'compiler_invoked': False,
          'candidate_files_modified': False, 'candidate': str(ROOT), 'baseline': str(BASE),
          'baseline_path_file': str(BASE_PATH_FILE), 'hashes': initial_hashes,
          'baseline_hashes': {n: sha(BASE / n) for n in FILES},
          'unchanged_source_files': unchanged, 'scale_and_boundary_audit': layout,
          'kernels': reports, 'helper_sha256': sha(HELPER)}
(REVIEW / 'audit_report.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps({'status': result['status'], 'report': str(REVIEW / 'audit_report.json'),
                  'scale_and_boundary_audit': layout,
                  'kernels': [{k: v for k, v in x.items() if k in
                              ['name', 'resources', 'generic_isa_identical', 'native_tied_mfma_C256']} for x in reports]}, indent=2))
