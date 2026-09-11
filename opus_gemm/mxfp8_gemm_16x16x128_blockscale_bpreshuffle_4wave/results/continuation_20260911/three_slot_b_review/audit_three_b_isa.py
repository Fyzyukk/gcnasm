#!/usr/bin/env python3
"""Read-only predicate, VMEM-ticket and LDS-wait audit for three-B candidates."""
from collections import Counter, deque
from functools import lru_cache
from pathlib import Path
import argparse
import ast
import hashlib
import json
import re
import sys

sys.path.insert(0, '/tmp/mxfp8_fourwave_bpreshuffle_20260910')
from audit_lds_waits import parse, audit, regs

REVIEW = Path(__file__).resolve().parent
BASE = Path('/tmp/mxfp8_fourwave_e8_continue_20260910/ab_store8')
helper_file = REVIEW.parent / 'ab_role_split_safe_b_review/audit_isa_exec_wait.py'
helper_source = helper_file.read_text()
tree = ast.parse(helper_source)
reg_fn = next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == 'register_atoms')
exec(compile(ast.Module(body=[reg_fn], type_ignores=[]), str(helper_file), 'exec'))
role_fn = next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == 'audit_roles')
prefix = ast.get_source_segment(helper_source, role_fn).split('    branches = []')[0]
prefix = prefix.replace('def audit_roles(function):', 'def predicate_helper(function):')
prefix = prefix.replace('        try:\n            return (int(token, 0),) * 4',
                        "        if token == 'exec':\n            return ((1 << 64) - 1,) * 4\n        try:\n            return (int(token, 0),) * 4")
prefix = prefix.replace("            elif op == 's_cmp_eq_u32':\n                result = tuple(x == y for x, y in zip(operand(args[0]), operand(args[1])))",
                        "            elif op in ('s_cmp_eq_u32', 's_cmp_lg_u32'):\n                result = tuple((x == y) if op == 's_cmp_eq_u32' else (x != y) for x, y in zip(operand(args[0]), operand(args[1])))\n            elif op == 's_and_b64':\n                result = tuple(x & y for x, y in zip(operand(args[1]), operand(args[2])))\n            elif op == 's_mov_b64':\n                result = tuple(x & ((1 << 64) - 1) for x in operand(args[1]))")
exec(prefix + '    return value, next_consumer\n')


def role_and_wait_audit(function, release_point):
    code = function['code']
    positions = {x['addr']: i for i, x in enumerate(code)}
    value, next_consumer = predicate_helper(function)
    masks = (1 << 64) - 1
    decisions = {}
    barriers = [i for i, x in enumerate(code) if x['asm'] == 's_barrier']
    assert len(barriers) == 11
    previous_mfma = {}
    last = None
    for i, ins in enumerate(code):
        if ins['asm'].startswith('v_mfma'):
            last = i
        previous_mfma[i] = last
        assert not re.match(r'\S+\s+exec(?:_lo|_hi)?(?:\s|,)', ins['asm'])
        assert not ins['asm'].startswith('v_cmpx')
    assert previous_mfma[barriers[0]] is None

    # Prologue B1/B2 must have 16 tickets each on exactly waves2/3.
    seed_branch = next(i for i in range(barriers[0] + 1, barriers[0] + 12)
                       if code[i]['asm'].startswith('s_cbranch_scc1'))
    seed_skip = tuple(bool(x) for x in value('scc', seed_branch))
    assert seed_skip == (True, True, False, False)
    seed_end, seed_loads = next_consumer(seed_branch + 1)
    other_end, other_loads = next_consumer(positions[code[seed_branch]['target']])
    assert seed_end == other_end and len(seed_loads) == 32 and not other_loads
    decisions[seed_branch] = seed_skip
    seed_instructions = [x['asm'] for x in code if x['line'] in seed_loads]
    immediates = [int(m[1]) if (m := re.search(r'offset:(\d+)', x)) else 0 for x in seed_instructions]
    assert immediates == [0, 1024, 2112, 3168] * 8

    producer_branches = []
    for i, ins in enumerate(code):
        if not ins['asm'].startswith('s_cbranch_vccnz') or not code[i - 1]['asm'].startswith('s_and_b64 vcc, exec,'):
            continue
        # Actual producer branches immediately follow a native MFMA. The
        # publication control also uses VCC but has no producer requests.
        if not code[i - 2]['asm'].startswith('v_mfma'):
            continue
        acc = int(re.search(r'a\[(\d+):', code[i - 2]['asm'])[1])
        assert acc in ((release_point * 4), (release_point * 4 + 4), 80, 84)
        is_a = acc not in (80, 84)
        producer_end, loads = next_consumer(i + 1)
        other_end, others = next_consumer(positions[ins['target']])
        assert producer_end == other_end and len(loads) == 8 and not others
        assert code[producer_end]['asm'].startswith('v_mfma_scale')
        skip = tuple(bool(x) for x in value(code[i - 1]['asm'].rsplit(', ', 1)[1], i - 1))
        assert skip == ((False, False, True, True) if is_a else (True, True, False, False))
        decisions[i] = skip
        producer_branches.append({'line': ins['line'], 'operand': 'A' if is_a else 'B',
                                  'after_mfma': acc // 4 + 1 if is_a else (37 if acc == 80 else 38),
                                  'loads_per_selected_wave': 8,
                                  'load_lines': loads, 'common_next_mfma_line': code[producer_end]['line']})
    assert len(producer_branches) == 20
    assert Counter(x['operand'] for x in producer_branches) == {'A': 10, 'B': 10}

    # Execute only each short P36 predicate/wait block, once per physical
    # wave. CFG reaching definitions provide the input masks; local moves
    # and conditional branches are then exact, including first-body syntax.
    publications, releases, allowed_waits = [], [], set()
    for barrier in barriers[1:]:
        last = previous_mfma[barrier]
        acc = int(re.search(r'a\[(\d+):', code[last]['asm'])[1])
        if acc == (release_point - 1) * 4:
            block = code[last + 1:barrier]
            assert not any('vmcnt' in x['asm'] for x in block)
            assert code[barrier - 1]['asm'] == 's_waitcnt lgkmcnt(0)'
            releases.append({'line': code[barrier]['line'], 'after_mfma': release_point,
                             'vmem_drain': False})
            continue
        assert acc == 76
        waits_by_wave = []
        for wave in range(4):
            state, waits = {'exec': masks}, []
            i = last + 1
            visited = set()
            while i != barrier:
                assert i not in visited
                visited.add(i)
                ins = code[i]
                op, _, raw = ins['asm'].partition(' ')
                args = [x.strip() for x in raw.split(',')]
                read = lambda token: state[token] if token in state else value(token, i)[wave]
                if op == 's_mov_b64':
                    state[args[0]] = read(args[1]) & masks
                elif op == 's_and_b64':
                    state[args[0]] = read(args[1]) & read(args[2])
                elif op == 's_andn2_b64':
                    state[args[0]] = read(args[1]) & ~read(args[2]) & masks
                elif op.startswith('s_cbranch_vcc'):
                    taken = bool(state['vcc']) if op.endswith('nz') else not bool(state['vcc'])
                    decisions.setdefault(i, [None] * 4)[wave] = taken
                    if taken:
                        i = positions[ins['target']]
                        continue
                elif op == 's_branch':
                    i = positions[ins['target']]
                    continue
                match = re.search(r'vmcnt\((\d+)\)', ins['asm'])
                if match:
                    waits.append(int(match[1]))
                    allowed_waits.add(i)
                i += 1
            assert waits == ([0] if wave < 2 else [16]), (wave, waits)
            waits_by_wave.append(waits)
        publications.append({'line': code[barrier]['line'], 'after_mfma': 36,
                             'vmcnt_by_wave': waits_by_wave})
    assert len(releases) == len(publications) == 5
    first_store = next(i for i, x in enumerate(code) if x['asm'].startswith('buffer_store'))
    actual_waits = {i for i in range(barriers[0] + 1, first_store) if 'vmcnt(' in code[i]['asm']}
    assert actual_waits == allowed_waits, ('hidden VMEM wait', [code[i] for i in actual_waits ^ allowed_waits])
    assert all(all(x is not None for x in values) for values in decisions.values())
    return decisions, {'prologue_B1_B2_selected_waves': [2, 3],
                       'prologue_B1_B2_tickets_per_selected_wave': [16, 16],
                       'prologue_DTLDS_lines': seed_loads,
                       'role_branches': producer_branches, 'releases': releases,
                       'publications': publications, 'hidden_steady_vmem_waits': 0,
                       'exec_writes': 0}


def audit_vmem(function, decisions):
    code = function['code']
    positions = {x['addr']: i for i, x in enumerate(code)}
    events = {}
    for i, ins in enumerate(code):
        asm = ins['asm']
        if asm.startswith(('buffer_load', 'global_load', 'flat_load')):
            events[i] = set() if ' lds' in asm else regs(asm.split(',')[0])
        elif asm.startswith(('buffer_store', 'global_store', 'flat_store')):
            events[i] = set()
    wave_reports = []
    for wave in range(4):
        work, seen, hazards = deque([(0, ())]), set(), set()
        pending_at_barriers = {}
        while work:
            i, pending = work.popleft()
            if (i, pending) in seen:
                continue
            seen.add((i, pending))
            assert len(seen) < 1000000
            ins = code[i]
            asm = ins['asm']
            wait = re.search(r'vmcnt\((\d+)\)', asm)
            if wait:
                count = int(wait[1])
                pending = pending[-count:] if count else ()
            pending_regs = set().union(*(events[e] for e in pending)) if pending else set()
            hazards.update((ins['line'], r) for r in regs(asm) & pending_regs)
            if i in events:
                pending += (i,)
            if asm == 's_barrier':
                pending_at_barriers.setdefault(ins['line'], set()).add(len(pending))
            if asm.startswith('s_endpgm'):
                continue
            if i in decisions:
                successors = [positions[ins['target']] if decisions[i][wave] else i + 1]
            else:
                successors = [positions[ins['target']]] if 'target' in ins else []
                if not asm.startswith('s_branch ') and i + 1 < len(code):
                    successors.append(i + 1)
            work.extend((j, pending) for j in successors)
        assert not hazards, hazards
        wave_reports.append({'physical_wave': wave, 'cfg_states': len(seen), 'hazards': [],
                             'pending_vmem_at_barriers': {str(k): sorted(v) for k, v in pending_at_barriers.items()}})
    return wave_reports


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('candidate')
    ap.add_argument('--release-point', type=int, choices=(4, 12), default=4)
    args = ap.parse_args()
    root = Path(args.candidate)
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    tracked = ['tmpl.hpp', 'traits.hpp', 'build/device.isa', 'build/device.co',
               'build/device.notes', 'build/gemm_a8w8_blockscale_bpreshuffle.exe']
    hashes = {n: sha(root / n) for n in tracked}
    functions = parse(root / 'build/device.isa')
    original = {f['name']: f for f in parse(BASE / 'build/device.isa')}
    notes = re.split(r'  - \.agpr_count:', (root / 'build/device.notes').read_text())[1:]
    reports = []
    for f, note in zip(functions, notes):
        code = f['code']
        insts = [x['asm'] for x in code if not x['asm'].startswith('s_code_end')]
        generic = 'generic' in f['name']
        counts = Counter()
        for asm in insts:
            if asm.startswith('v_mfma'):
                assert asm.startswith('v_mfma_scale_f32_16x16x128_f8f6f4')
                fields = [x.strip() for x in asm.split(' ', 1)[1].split(',')]
                assert fields[0] == fields[3]
                lo, hi = map(int, re.fullmatch(r'a\[(\d+):(\d+)\]', fields[0]).groups())
                assert hi == lo + 3 and lo % 4 == 0
                counts[lo] += 1
        assert sorted(counts) == list(range(0, 256, 4)) and set(counts.values()) == {6}
        resources = {key: int(re.search(r'\.' + key + r':\s*(\d+)', note)[1]) for key in
                     ['vgpr_count', 'sgpr_count', 'vgpr_spill_count', 'sgpr_spill_count',
                      'private_segment_fixed_size', 'group_segment_fixed_size', 'wavefront_size', 'max_flat_workgroup_size']}
        resources['agpr_count'] = int(note.splitlines()[0])
        assert resources['agpr_count'] == 256 and resources['wavefront_size'] == 64
        assert resources['max_flat_workgroup_size'] == 256
        assert resources['private_segment_fixed_size'] == resources['vgpr_spill_count'] == resources['sgpr_spill_count'] == 0
        lds = audit(f)
        assert not lds['hazards']
        if generic:
            assert insts == [x['asm'] for x in original[f['name']]['code'] if not x['asm'].startswith('s_code_end')]
            decisions, role_report = {}, None
        else:
            decisions, role_report = role_and_wait_audit(f, args.release_point)
        vmem = audit_vmem(f, decisions)
        if role_report:
            for w in vmem:
                expected_r = [0] if w['physical_wave'] < 2 else [32]
                expected_p = [0] if w['physical_wave'] < 2 else [16]
                for r in role_report['releases']:
                    assert w['pending_vmem_at_barriers'][str(r['line'])] == expected_r
                for p in role_report['publications']:
                    assert w['pending_vmem_at_barriers'][str(p['line'])] == expected_p
        reports.append({'name': f['name'], 'resources': resources, 'native_tied_C256_mfma': 384,
                        'generic_isa_unchanged': generic, 'lds_wait': lds,
                        'role_and_wait_proof': role_report, 'vmem_wait': vmem})
    assert hashes == {n: sha(root / n) for n in tracked}
    result = {'status': 'PASS', 'candidate': str(root), 'release_point': args.release_point,
              'candidate_modified': False, 'gpu_launched': False, 'hashes': hashes, 'kernels': reports}
    out = REVIEW / (root.name + '_isa_audit.json')
    out.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({'status': 'PASS', 'report': str(out), 'hashes': hashes,
                      'kernels': [{'name': r['name'], 'resources': r['resources'],
                                   'lds_cfg_states': r['lds_wait']['cfg_states'],
                                   'vmem_cfg_states_by_wave': [w['cfg_states'] for w in r['vmem_wait']]} for r in reports]}, indent=2))


if __name__ == '__main__':
    main()
