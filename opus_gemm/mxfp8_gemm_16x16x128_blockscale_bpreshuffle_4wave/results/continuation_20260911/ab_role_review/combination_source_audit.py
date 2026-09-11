#!/usr/bin/env python3
"""Read-only source-composition and lifetime review of AB combinations."""
from pathlib import Path
import difflib
import hashlib
import json
import re

review = Path(__file__).resolve().parent
work = Path('/tmp/mxfp8_fourwave_e8_continue_20260910')
base = Path('/root/workspace/gcnasm_new/gcnasm-mxfp8-final-pipeline-source-20260910/opus_gemm/mxfp8_gemm_16x16x128_blockscale_bpreshuffle_4wave')
paths = {'base': base, 'ab': work / 'ab_role_split_safe_b',
         'vec8': work / 'audit_candidates/store_bf16_vec8',
         'a0': work / 'audit_candidates/roll_a0_mrepeat',
         'ab_store8': work / 'ab_store8', 'ab_store8_a0_mrepeat': work / 'ab_store8_a0_mrepeat'}
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
expected = {'ab': '0dbee7b1831cc5a24c70822de167a22c2a8a42f6bc7776caf4d2ec645e7f91c0',
            'vec8': 'a2f01bbf218cd204e4f72f818b8fbcf56baf95ffc8785dd339cb5d89a7774385',
            'a0': '18ed04381a46b04fb73f893485d8688613132e65d3d33fee3124995aa86e8790',
            'ab_store8': '2c74677dbc95c6d481893d08657afa73945a8492bc55db8fd0945fc2eb1a0559',
            'ab_store8_a0_mrepeat': '3d1cf12e635664b02da7f210e30a8e16bc1b097bfd5933af5fea979350db8d45'}
texts = {name: (path / 'tmpl.hpp').read_text() for name, path in paths.items()}
for name, value in expected.items():
    assert sha(paths[name] / 'tmpl.hpp') == value

def edits(old, new):
    old, new = old.splitlines(True), new.splitlines(True)
    result = []
    for op, a, b, c, d in difflib.SequenceMatcher(a=old, b=new, autojunk=False).get_opcodes():
        if op != 'equal':
            result.append({'old': ''.join(old[a:b]), 'new': ''.join(new[c:d])})
    return result

# Exact changed-line equality binds the combinations to the already audited
# candidates, while the cutpoint checks below independently verify placement.
vec8_edits = edits(texts['base'], texts['vec8'])
a0_edits = edits(texts['base'], texts['a0'])
assert edits(texts['ab'], texts['ab_store8']) == vec8_edits
assert edits(texts['ab_store8'], texts['ab_store8_a0_mrepeat']) == a0_edits
for name in ('ab_store8', 'ab_store8_a0_mrepeat'):
    for filename in ('traits.hpp', 'tmpl_generic.hpp', 'kernel_dispatch.hpp',
                     'gemm_a8w8_mxfp8_scale_common.h', 'gemm_a8w8_blockscale_bpreshuffle_launch.cc',
                     'gemm_a8w8_mxfp8_scale_kernel.cc', 'gemm_a8w8_mxfp8_scale_host.cc', 'Makefile'):
        assert (paths[name] / filename).read_bytes() == (paths['ab'] / filename).read_bytes()
    calls = lambda text: [re.sub(r'\s+', '', x) for x in re.findall(r'MXFP8_MMA_(?:ONE|PAIR)\((.*?)\);', text, re.S)]
    assert calls(texts[name]) == calls(texts['ab'])
    for operation in ('s_waitcnt_vmcnt(0_I)', 's_waitcnt_lgkmcnt(0_I)', '__builtin_amdgcn_s_barrier()'):
        assert texts[name].count(operation) == texts['ab'].count(operation)

tail_marker = '// Consume the final resident tile;'
assert texts['ab_store8_a0_mrepeat'][texts['ab_store8_a0_mrepeat'].index(tail_marker):] == \
       texts['ab_store8'][texts['ab_store8'].index(tail_marker):]

source = texts['ab_store8_a0_mrepeat']
hot_start = source.index('    for (tile = 0;')
hot = source[hot_start:source.index(tail_marker)]
tokens = re.compile(r'MXFP8_MMA_(ONE|PAIR)\((.*?)\);|load_a_mrepeat_scale<T, (\d)>|'
                    r'__builtin_amdgcn_s_barrier\(\)|v_sfa\[0\] = load_sfa_dword\(tile \+ 1, 0\)', re.S)
count, publications, cutpoints = 0, [], []
for match in tokens.finditer(hot):
    line = source[:hot_start + match.start()].count('\n') + 1
    if match[1]:
        count += 1 if match[1] == 'ONE' else 2
    elif match[3] is not None:
        mr = int(match[3])
        assert publications and publications[-1]['after_mfma'] == 36
        assert count == 36 + mr * 4
        cutpoints.append({'m_repeat': mr, 'source_line': line, 'after_mfma': count,
                          'byte_range_exclusive': [mr * 32, (mr + 1) * 32]})
    elif match[0].startswith('__builtin'):
        publications.append({'source_line': line, 'after_mfma': count})
    else:
        assert count == 48
        sfa0_line = line
assert len(publications) == 1 and count == 64
assert [item['m_repeat'] for item in cutpoints] == [0, 1, 2, 3]
assert 'v_a[0] = load<T::VEC_A>(s_a, u_ra + sa_offset(next_stage, 0));' not in hot

# Compose the split producer publication with mixed-generation A0 slices.
a_stage, b_stage = [[0, 0], [None, None]], [[0, 0], [1, 1]]
a0, b0, sfa0, sfa1, events = [0] * 4, 0, 0, 0, 0
for tile in range(64):
    stage, nxt = tile % 2, (tile % 2) ^ 1
    assert a_stage[stage] == b_stage[stage] == [tile, tile]
    a1, b1 = tile, tile
    if tile < 63:
        a_stage[nxt] = [tile + 1] * 2
        assert b_stage[nxt] == [tile + 1] * 2
    published = False
    for quadrant in ('c00', 'c10', 'c01', 'c11'):
        for mr in range(4):
            for nr in range(4):
                av = a0[mr] if quadrant in ('c00', 'c01') else a1
                bv = b0 if quadrant in ('c00', 'c10') else b1
                sf = sfa0 if quadrant in ('c00', 'c01') else sfa1
                assert av == bv == sf == tile
                events += 1
            if quadrant == 'c01' and tile < 63:
                if mr == 0:
                    assert a_stage[nxt] == b_stage[nxt] == [tile + 1] * 2
                    published = True
                assert published
                a0[mr] = a_stage[nxt][0]
                if mr == 0:
                    b_stage[stage] = [(tile + 2) & 63] * 2
        if quadrant == 'c01' and tile < 63:
            sfa0 = tile + 1
            b0 = b_stage[nxt][0]
    if tile < 63:
        sfa1 = tile + 1
assert events == 4096 and a0 == [63] * 4 and b0 == sfa0 == sfa1 == 63
assert a_stage[1] == b_stage[1] == [63, 63] and b_stage[0] == [0, 0]

producer_report = json.loads((review / 'producer_mapping_audit.json').read_text())
assert producer_report['status'] == 'PASS' and producer_report['source_sha256'] == expected['ab']
report = {'status': 'PASS', 'scope': 'Independent CPU-only source composition and memory lifecycle review; no candidate mutation, compile or GPU launch',
          'source_sha256': expected,
          'ab_store8': {'changed_line_edits_exactly_match_frozen_vec8': True,
                        'edit_groups': len(vec8_edits), 'producer_source_unchanged': True,
                        'inherits_ab_producer_mapping_and_stage_review': True,
                        'mfma_calls_unchanged': True, 'generic_source_and_abi_unchanged': True},
          'ab_store8_a0_mrepeat': {'changed_line_edits_exactly_match_frozen_a0': True,
                                   'edit_groups': len(a0_edits), 'producer_source_unchanged': True,
                                   'publication': publications[0], 'a0_cutpoints': cutpoints,
                                   'sfa0_update_after_mfma': 48, 'sfa0_update_source_line': sfa0_line,
                                   'original_128byte_a0_reload_removed': True,
                                   'tail_including_vec8_store_macros_identical_to_ab_store8': True,
                                   'mfma_consumption_events_checked': events,
                                   'stale_slice_or_scale_events': 0, 'next_stage_read_before_publication': 0,
                                   'tail_tile': 63, 'tail_stage': 1, 'a_tile64_loads': 0},
          'conclusion': 'Both combinations are exact source compositions of the audited components. The manually inserted M0 read is after the retained 36-MFMA publication barrier; no additional mapping or source lifecycle issue found. ISA and GPU validation are owned by the parent/root.'}
for name, value in expected.items():
    assert sha(paths[name] / 'tmpl.hpp') == value
(review / 'combination_source_audit.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
