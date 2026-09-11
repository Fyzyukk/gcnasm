#!/usr/bin/env python3
"""Carry all four matrix halves across K iterations using dead operand slices.

Prefetch global data during the first half of a K iteration. Load next A1
and B1 into dead register slices near its end, allowing early stage release
in the following iteration. Matrix LDS images and MFMA order do not change.
"""
from pathlib import Path
import hashlib
import json
import re
import shutil
import sys

root = Path(__file__).resolve().parent
work = Path((root / 'work_path.txt').read_text().strip())
baseline = work / 'baseline'
parent = work / 'sym_rows_vaddr'
original = (parent / 'tmpl.hpp').read_text()
begin = original.index('#pragma unroll 4')
end = original.index('    // Consume the final resident tile;')
loop = original[begin:end]
issue_re = re.compile(
    r'\n        // Refill the released matrix stage after MFMA\d+\.\n'
    r'(?:        prefetch_matrix_issue\(.*?\);\n)+'
    r'        __builtin_amdgcn_sched_group_barrier\(0x20, \d+, 0\);\n'
    r'        __builtin_amdgcn_sched_barrier\(0\);'
)
loop, count = issue_re.subn('', loop)
assert count == 16
load_a = '''        v_a[1] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 1));
        // A1 is independent of c00. Its first c10 consumer determines the
        // required wait, with no eager whole-vector drain here.
'''
assert loop.count(load_a) == 1
loop = loop.replace(load_a, '')
for start, stop in [
    ('        // Issue the count-4 B1 head', '        MXFP8_MMA_PAIR('),
    ('        // Start the first half of the B1 tail', '        // A half 1 x B half 0'),
    ('        // The final two B1-tail chunks', '        MXFP8_MMA_PAIR('),
]:
    a = loop.index(start)
    b = loop.index(stop, a)
    loop = loop[:a] + loop[b:]
assert 'rb1_offsets_head' not in loop and 'rb1_offsets_tail' not in loop
publication = '''        // All operands for tile t are now resident in VGPRs. Complete tile
        // t+1 data and release tile t's LDS stage with the barrier, then start
        // the cold B path for tile t+2 while the final 28 MFMAs of tile t run.
        __builtin_amdgcn_s_setprio(0);
        s_waitcnt_vmcnt(0_I);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);
'''
assert loop.count(publication) == 1
loop = loop.replace(publication, '')
loop = loop.replace('existing 36-MFMA\n        // barrier', 'early publication\n        // barrier')
offsets = '''        const auto ra0_next_offsets =
            opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 0));'''
assert loop.count(offsets) == 1
loop = loop.replace(offsets, offsets + '''
        const auto ra1_next_offsets =
            opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 1));
        const auto rb1_next_offsets =
            opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 1));''')

prefix = original[:begin]
seed = '    v_a[0] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 0));'
assert prefix.count(seed) == 1
prefix = prefix.replace(seed, seed + '''
    // Seed every current-tile matrix half. Subsequent A1/B1 values roll
    // into dead operand slices near the end of the previous K iteration.
    v_a[1] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 1));
    v_b_second = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 1));''')
configs = {
    'regroll_release4': (4, list(range(4, 35, 2))),
    'regroll_release8': (8, list(range(8, 39, 2))),
}
requested = set(sys.argv[1:]) or set(configs)
assert requested <= set(configs)
for name, (release, sites) in configs.items():
    if name not in requested:
        continue
    candidate_loop = loop
    pattern = re.compile(r'        MXFP8_MMA_(PAIR|ONE)\(.*?\);\n        (?:sched_barrier_pairs_scale|__builtin_amdgcn_sched_barrier)\([^;]*\);', re.S)
    count = 0
    positions = {}
    for match in pattern.finditer(candidate_loop):
        count += 2 if match[1] == 'PAIR' else 1
        positions[count] = match.end()
    assert count == 64 and len(sites) == 16
    edits = {release: f'''

        // MFMA{release}: finish the previous iteration's operand reads,
        // publish t+1, and release the old stage for the t+2 producers.
        __builtin_amdgcn_s_setprio(0);
        s_waitcnt_vmcnt(0_I);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);
        __builtin_amdgcn_s_setprio(1);
'''}
    for issue, site in enumerate(sites):
        edits[site] = edits.get(site, '') + f'''
        prefetch_matrix_issue(opus::number<{issue}>{{}}, stage, future_tile);
        __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);
        __builtin_amdgcn_sched_barrier(0);
'''
    for repeat, site in enumerate([52, 56, 60, 64]):
        edits[site] = edits.get(site, '') + f'''
        // A1 M-repeat {repeat} has no further current-tile consumers.
        __builtin_amdgcn_sched_barrier(0);
        load_a_mrepeat_scale<T, {repeat}>(s_a, ra1_next_offsets, v_a[1]);
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);
'''
    for lo, hi, site in [(0, 4, 62), (4, 8, 64)]:
        edits[site] = edits.get(site, '') + f'''
        // B1 N-repeats {lo // 2} and {hi // 2 - 1} are dead after MFMA{site}.
        __builtin_amdgcn_sched_barrier(0);
        load_b_range_scale<T, {lo}, {hi}>(s_b, rb1_next_offsets, v_b_second);
        __builtin_amdgcn_sched_group_barrier(0x100, {hi - lo}, 0);
        __builtin_amdgcn_sched_barrier(0);
'''
    for site, text in sorted(edits.items(), reverse=True):
        pos = positions[site]
        candidate_loop = candidate_loop[:pos] + text + candidate_loop[pos:]
    candidate = prefix + candidate_loop + original[end:]
    assert candidate.count('__builtin_amdgcn_s_barrier();') == original.count('__builtin_amdgcn_s_barrier();')
    dest = work / name
    dest.mkdir(exist_ok=False)
    for path in baseline.iterdir():
        if path.is_file() and (path.suffix in ['.h', '.hpp', '.cc'] or path.name == 'Makefile'):
            shutil.copy2(path, dest / path.name)
    (dest / 'tmpl.hpp').write_text(candidate)
    (dest / 'candidate.json').write_text(json.dumps(dict(
        name=name, parent=parent.name,
        parent_sha256=hashlib.sha256(original.encode()).hexdigest(),
        source_sha256=hashlib.sha256(candidate.encode()).hexdigest(),
        release_after_mfma=release, global_issue_sites=sites,
        a1_next_read_sites=[52, 56, 60, 64], b1_next_read_sites=[62, 64],
        lifecycle='Current matrix halves are seeded in prologue and carried in VGPRs. Full LGKM/VMEM publication follows all previous reads. Refill the released old stage with t+2, then roll t+1 from the other published stage only after each current operand slice is dead.',
        same_matrix_lds_mapping=True, same_mfma_sequence=True,
        extra_final_tile_reads='Conservative original epilogue reloads retained',
        not_a_full_gemm=False,
    ), indent=2) + '\n')
    print(name)
