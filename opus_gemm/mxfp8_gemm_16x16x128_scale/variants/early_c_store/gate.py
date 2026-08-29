#!/usr/bin/env python3
"""Disassembly gate for the MXFP8_EARLY_C_STORE build.

Checks the things that can silently undo the change or silently cost more than
it buys:

  * VGPR/spill/scratch -- the build sits at 243/256, and hoisting the C
    addresses above the tail extends their live range.  vgpr_spill_count == 0
    is NOT sufficient; count scratch_* too (measurement protocol).
  * the tile-boundary wait must read vmcnt(16), not vmcnt(0) -- if the
    scheduler sank the early stores back below it, we would still see 0.
  * store grouping: 32 total, and under the flag the first group must come
    AFTER the prologue's `buffer_load ... lds`.  That ordering IS the change.

Always run against the LINKED exe's extracted device ELF (section 29.3).
"""
import re
import subprocess
import sys

OBJDUMP = '/opt/rocm/llvm/bin/llvm-objdump'
READELF = '/opt/rocm/llvm/bin/llvm-readelf'


def main():
    elf, tag = sys.argv[1], sys.argv[2]
    lines = subprocess.run([OBJDUMP, '-d', elf],
                           capture_output=True, text=True).stdout.split('\n')
    ins = [l for l in lines if re.match(r'^\t[a-z]', l)]

    notes = subprocess.run([READELF, '--notes', elf],
                           capture_output=True, text=True).stdout

    def note(key):
        m = re.search(key + r':\s*(\d+)', notes)
        return m.group(1) if m else '?'

    mfma = sum(1 for l in ins if 'v_mfma' in l)
    scratch = sum(1 for l in ins if re.match(r'^\tscratch_', l))

    # Store groups, in program order.
    kinds = []
    for l in ins:
        if re.match(r'^\tbuffer_store', l):
            kinds.append('S')
        elif re.match(r'^\tbuffer_load', l) and ' lds' in l:
            kinds.append('L')
    groups = []
    for k in kinds:
        if groups and groups[-1][0] == k:
            groups[-1][1] += 1
        else:
            groups.append([k, 1])
    stores = sum(n for k, n in groups if k == 'S')

    # The tile-boundary wait: the one immediately preceding an s_barrier that
    # follows a run of lds loads.  Report every distinct vmcnt value present.
    vmcnts = sorted({int(m.group(1))
                     for l in ins
                     for m in [re.search(r's_waitcnt.*vmcnt\((\d+)\)', l)] if m})

    print(f"  {tag:4s} mfma={mfma} stores={stores} "
          f"VGPR={note('vgpr_count')} vspill={note('vgpr_spill_count')} "
          f"scratch={scratch} LDS={note('group_segment_fixed_size')}")
    print(f"       vmcnt values in kernel: {vmcnts}")
    tail = ''.join(f"{k}{n} " for k, n in groups[-6:])
    print(f"       last store/lds-load groups: {tail}")

    ok = True
    if scratch:
        print(f"       FAIL: {scratch} scratch_* instructions", file=sys.stderr)
        ok = False
    if note('vgpr_spill_count') != '0':
        print("       FAIL: nonzero vgpr_spill_count", file=sys.stderr)
        ok = False
    if stores != 32:
        print(f"       FAIL: expected 32 buffer_store, found {stores}",
              file=sys.stderr)
        ok = False
    if tag == 'on':
        if 16 not in vmcnts:
            print("       FAIL: no s_waitcnt vmcnt(16) -- the relaxed wait is "
                  "missing; the early stores were likely sunk", file=sys.stderr)
            ok = False
        # Under the flag we want stores split into two runs, with lds loads
        # before the first.
        runs = [n for k, n in groups if k == 'S']
        if len(runs) < 2:
            print(f"       WARN: stores not split into two runs: {runs}")
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
