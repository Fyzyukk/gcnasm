#!/usr/bin/env python3
"""Read-only CPU ISA audit of the AB producer split and its two combinations."""
from collections import Counter, deque
from functools import lru_cache
from pathlib import Path
import argparse
import hashlib
import json
import re
import sys

sys.path.insert(0, '/tmp/mxfp8_fourwave_bpreshuffle_20260910')
from audit_lds_waits import parse, audit, regs

ROOT = Path('/tmp/mxfp8_fourwave_e8_continue_20260910')
BASE = Path('/root/workspace/gcnasm_new/gcnasm-mxfp8-final-pipeline-source-20260910/opus_gemm/mxfp8_gemm_16x16x128_blockscale_bpreshuffle_4wave')


def audit_vmem(function):
    code = function['code']
    positions = {x['addr']: i for i, x in enumerate(code)}
    events = {}
    for i, ins in enumerate(code):
        asm = ins['asm']
        if asm.startswith(('buffer_load', 'global_load', 'flat_load')):
            events[i] = set() if ' lds' in asm else regs(asm.split(',')[0])
        elif asm.startswith(('buffer_store', 'global_store', 'flat_store')):
            events[i] = set()  # gfx950 stores share the VMEM counter.
    work, seen, hazards, publications = deque([(0, ())]), set(), set(), set()
    while work:
        index, pending = work.popleft()
        if (index, pending) in seen:
            continue
        seen.add((index, pending))
        assert len(seen) < 1000000
        ins = code[index]
        asm = ins['asm']
        wait = re.search(r'\bvmcnt\((\d+)\)', asm)
        if wait:
            count = int(wait[1])
            pending = pending[-count:] if count else ()
        touched = set().union(*(events[e] for e in pending)) if pending else set()
        hazards.update((ins['line'], reg) for reg in regs(asm) & touched)
        if index in events:
            pending += (index,)
        if asm == 's_barrier':
            assert not pending, ('VMEM pending at publication', ins, pending)
            publications.add(ins['line'])
        if asm.startswith('s_endpgm'):
            continue
        successors = [positions[ins['target']]] if 'target' in ins else []
        if not asm.startswith('s_branch ') and index + 1 < len(code):
            successors.append(index + 1)
        work.extend((i, pending) for i in successors)
    assert not hazards, hazards
    return {'cfg_states': len(seen), 'hazards': [],
            'barriers_with_zero_pending_vmem': sorted(publications)}


def register_atoms(token):
    match = re.fullmatch(r'([sv])\[(\d+):(\d+)\]', token)
    if match:
        return {(match[1], n) for n in range(int(match[2]), int(match[3]) + 1)}
    match = re.fullmatch(r'([sv])(\d+)', token)
    return {(match[1], int(match[2]))} if match else {token}


def audit_roles(function):
    code = function['code']
    positions = {x['addr']: i for i, x in enumerate(code)}
    predecessors = [[] for _ in code]
    for i, ins in enumerate(code):
        if 'target' in ins:
            predecessors[positions[ins['target']]].append(i)
        if not ins['asm'].startswith(('s_branch ', 's_endpgm')) and i + 1 < len(code):
            predecessors[i + 1].append(i)

    def parts(index):
        op, _, args = code[index]['asm'].partition(' ')
        return op, [x.strip() for x in args.split(',')]

    def definitions(index):
        op, args = parts(index)
        result = set()
        no_dest = op.startswith(('s_cmp', 's_cbranch', 's_branch', 's_wait', 's_set',
                                 's_barrier', 's_endpgm', 's_nop', 'ds_write',
                                 'buffer_store', 'global_store', 'flat_store'))
        if op.startswith('buffer_load') and ' lds' in code[index]['asm']:
            no_dest = True
        if not no_dest:
            result |= register_atoms(args[0])
        if op.startswith(('v_mad_u64', 'v_add_co_', 'v_sub_co_', 'v_subrev_co_')):
            result |= register_atoms(args[1])
        if op.startswith(('s_cmp', 's_add', 's_sub', 's_and', 's_or_', 's_xor',
                          's_lshr', 's_lshl', 's_ashr', 's_min', 's_max')):
            result.add('scc')
        return result

    defs = [definitions(i) for i in range(len(code))]

    @lru_cache(None)
    def reaching(token, before):
        wanted = register_atoms(token)
        work, visited, found = list(predecessors[before]), set(), set()
        if before == 0:
            return (-1,)
        while work:
            index = work.pop()
            if index in visited:
                continue
            visited.add(index)
            if wanted & defs[index]:
                found.add(index)
            elif predecessors[index]:
                work.extend(predecessors[index])
            else:
                found.add(-1)
        return tuple(sorted(found))

    @lru_cache(None)
    def value(token, before):
        try:
            return (int(token, 0),) * 4
        except ValueError:
            pass
        possibilities = []
        for definition in reaching(token, before):
            if definition < 0:
                assert token == 'v0', ('unexpected live-in', token, before)
                possibilities.append(tuple(tuple(w * 64 + l for l in range(64)) for w in range(4)))
                continue
            op, args = parts(definition)
            operand = lambda t: value(t, definition)
            if op == 'v_readfirstlane_b32':
                result = tuple(x[0] for x in operand(args[1]))
            elif op == 's_lshr_b32':
                result = tuple((x & 0xffffffff) >> y for x, y in zip(operand(args[1]), operand(args[2])))
            elif op == 's_cmp_eq_u32':
                result = tuple(x == y for x, y in zip(operand(args[0]), operand(args[1])))
            elif op == 's_cselect_b64':
                result = tuple((x if cond else y) & ((1 << 64) - 1)
                               for cond, x, y in zip(operand('scc'), operand(args[1]), operand(args[2])))
            elif op == 'v_cndmask_b32_e64':
                result = tuple(tuple(y if (mask >> lane) & 1 else x for lane in range(64))
                               for x, y, mask in zip(operand(args[1]), operand(args[2]), operand(args[3])))
            elif op == 'v_cmp_ne_u32_e64':
                result = tuple(sum(int(x != y) << lane for lane, y in enumerate(ys))
                               for x, ys in zip(operand(args[1]), operand(args[2])))
            else:
                raise AssertionError(('unexpected predicate definition', token, code[definition]))
            possibilities.append(result)
        assert possibilities and all(x == possibilities[0] for x in possibilities)
        return possibilities[0]

    def next_consumer(index):
        dtlds, seen = [], set()
        while index not in seen:
            seen.add(index)
            ins = code[index]
            asm = ins['asm']
            if asm.startswith(('v_mfma', 's_barrier', 's_cbranch', 's_endpgm')):
                return index, dtlds
            if asm.startswith('buffer_load') and ' lds' in asm:
                dtlds.append(ins['line'])
            index = positions[ins['target']] if asm.startswith('s_branch ') else index + 1
        raise AssertionError('cycle inside producer branch')

    branches = []
    for i, ins in enumerate(code):
        if not ins['asm'].startswith('s_cbranch_vccnz') or not code[i - 1]['asm'].startswith('s_and_b64 vcc, exec,'):
            continue
        producer_join, producer_loads = next_consumer(i + 1)
        other_join, other_loads = next_consumer(positions[ins['target']])
        assert producer_join == other_join and len(producer_loads) == 8 and not other_loads
        assert code[producer_join]['asm'].startswith('v_mfma_scale_f32_16x16x128')
        mask = code[i - 1]['asm'].rsplit(', ', 1)[1]
        skip_masks = value(mask, i - 1)
        prior = code[i - 2]['asm']
        assert prior.startswith('v_mfma_scale')
        acc = int(re.search(r'a\[(\d+):', prior)[1])
        assert acc in (0, 4, 80, 84)
        is_a = acc in (0, 4)
        expected = (0, 0, (1 << 64) - 1, (1 << 64) - 1) if is_a else ((1 << 64) - 1, (1 << 64) - 1, 0, 0)
        assert skip_masks == expected, (ins, skip_masks)
        branches.append({'branch_line': ins['line'], 'operand': 'A' if is_a else 'B',
                         'producer_waves': [0, 1] if is_a else [2, 3],
                         'producer_dtlds': 8, 'other_dtlds': 0,
                         'producer_load_lines': producer_loads,
                         'common_next_mfma_line': code[producer_join]['line'],
                         'predicate_uniform_in_each_wave': True})
    assert len(branches) == 20
    assert Counter(x['operand'] for x in branches) == {'A': 10, 'B': 10}
    return {'role_branches': branches, 'all_role_branches_join_before_mfma': True,
            'predicate_proof': 'CFG reaching definitions from v0 thread IDs, scalar wave-N comparison, and full-lane masks'}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('candidate', choices=['ab_role_split_safe_b', 'ab_store8', 'ab_store8_a0_mrepeat'])
    args = parser.parse_args()
    root = ROOT / args.candidate
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    names = ['tmpl.hpp', 'tmpl_generic.hpp', 'traits.hpp', 'build/device.co',
             'build/device.isa', 'build/device.notes', 'build/gemm_a8w8_blockscale_bpreshuffle.exe',
             'build/libblockscale_bpreshuffle.so']
    hashes = {name: sha(root / name) for name in names}
    source = (root / 'tmpl.hpp').read_text()
    baseline = (BASE / 'tmpl.hpp').read_text()
    calls = lambda s: [re.sub(r'\s+', '', x) for x in re.findall(r'MXFP8_MMA_(?:ONE|PAIR)\((.*?)\);', s, re.S)]
    assert calls(source) == calls(baseline)
    assert [int(x) for x in re.findall(r'MXFP8_PIN_C\(\w+, (\d+)\);', source)] == list(range(0, 256, 4))
    for name in ['tmpl_generic.hpp', 'traits.hpp', 'gemm_a8w8_mxfp8_scale_kernel.cc',
                 'gemm_a8w8_mxfp8_scale_common.h', 'kernel_dispatch.hpp',
                 'gemm_a8w8_blockscale_bpreshuffle_launch.cc']:
        assert sha(root / name) == sha(BASE / name), name
    old = {f['name']: f for f in parse(BASE / 'build/device.isa')}
    ab = {f['name']: f for f in parse(ROOT / 'ab_role_split_safe_b/build/device.isa')}
    notes = re.split(r'  - \.agpr_count:', (root / 'build/device.notes').read_text())[1:]
    functions = parse(root / 'build/device.isa')
    assert len(functions) == len(notes) == 4
    reports = []
    for function, note in zip(functions, notes):
        code = function['code']
        insts = [x['asm'] for x in code if not x['asm'].startswith('s_code_end')]
        resource = {key: int(re.search(r'\.' + key + r':\s*(\d+)', note)[1]) for key in
                    ['vgpr_count', 'sgpr_count', 'group_segment_fixed_size', 'private_segment_fixed_size',
                     'vgpr_spill_count', 'sgpr_spill_count', 'wavefront_size', 'max_flat_workgroup_size']}
        resource['agpr_count'] = int(note.splitlines()[0])
        assert resource['agpr_count'] == 256 and resource['wavefront_size'] == 64
        assert resource['max_flat_workgroup_size'] == 256
        assert resource['private_segment_fixed_size'] == resource['vgpr_spill_count'] == resource['sgpr_spill_count'] == 0
        counts, last_write = Counter(), {}
        for i, ins in enumerate(code):
            asm = ins['asm']
            assert not re.match(r'\S+\s+exec(?:_lo|_hi)?(?:\s|,)', asm) and not asm.startswith('v_cmpx'), ins
            if not asm.startswith('v_mfma'):
                continue
            assert asm.startswith('v_mfma_scale_f32_16x16x128_f8f6f4')
            fields = [x.strip() for x in asm.split(' ', 1)[1].split(',')]
            assert fields[0] == fields[3]
            lo, hi = map(int, re.fullmatch(r'a\[(\d+):(\d+)\]', fields[0]).groups())
            assert lo % 4 == 0 and hi == lo + 3 and hi < 256
            counts[lo] += 1
            for a in range(lo, hi + 1):
                last_write[a] = i
        assert sorted(counts) == list(range(0, 256, 4)) and set(counts.values()) == {6}
        generic = 'blockscale_generic' in function['name']
        is_bf16 = 'Lb1' in function['name']
        if generic:
            assert insts == [x['asm'] for x in old[function['name']]['code'] if not x['asm'].startswith('s_code_end')]
        if args.candidate == 'ab_store8' and not is_bf16:
            assert insts == [x['asm'] for x in ab[function['name']]['code'] if not x['asm'].startswith('s_code_end')]
        lds = audit(function)
        assert not lds['hazards']
        vmem = audit_vmem(function)
        roles = None if generic else audit_roles(function)
        opcodes = Counter(x.split()[0] for x in insts)
        output = {'stores': sum(n for op, n in opcodes.items() if op.startswith('buffer_store'))}
        if not generic and is_bf16 and 'store8' in args.candidate:
            assert opcodes['buffer_store_dwordx4'] == 32
            assert opcodes['v_permlane16_swap_b32_e64'] == 64
            assert opcodes['v_cvt_pk_bf16_f32'] == 128
            reads = []
            for i, ins in enumerate(code):
                if ins['asm'].startswith('v_accvgpr_read_b32'):
                    a = int(re.search(r', a(\d+)', ins['asm'])[1])
                    assert i > last_write[a]
                    reads.append(a)
            assert sorted(reads) == list(range(256))
            assert all(' nt' not in x for x in insts if x.startswith('buffer_store'))
            output.update({'agprs_read_once_after_last_static_write': 256,
                           'packed_bf16_rne_conversions': 128, 'permlane16_swaps': 64,
                           'store_bytes_per_lane': 16, 'cache_policy': 'unchanged default'})
        reports.append({'name': function['name'], 'resources': resource, 'instructions': len(insts),
                        'native_tied_mfma_C256': 384, 'exec_writes': 0,
                        'generic_isa_unchanged': generic, 'lds_wait': lds, 'vmem_wait': vmem,
                        'roles': roles, 'output': output})
    assert hashes == {name: sha(root / name) for name in names}, 'candidate changed during audit'
    result = {'candidate': str(root), 'status': 'PASS', 'gpu_launched': False,
              'candidate_files_modified': False, 'hashes': hashes,
              'source_mfma_call_order_unchanged': True, 'external_abi_files_unchanged': True,
              'kernels': reports}
    output = Path(__file__).resolve().parent / (args.candidate + '_isa_exec_wait_audit.json')
    output.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({'status': 'PASS', 'report': str(output), 'hashes': hashes,
                      'kernels': [{k: v for k, v in x.items() if k in ('name', 'resources', 'output')} for x in reports]}, indent=2))


if __name__ == '__main__':
    main()
