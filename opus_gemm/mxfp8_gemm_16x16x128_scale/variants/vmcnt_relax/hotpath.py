#!/usr/bin/env python3
"""Hot-path structure report for the MXFP8 steady K loop.

The metric that matters is NOT the largest s_barrier span -- in this kernel
that span crosses an output-tile boundary and contains the accumulator-clear
code, which runs once every OUTPUT_TILES_PER_WG tiles, not every K tile.

Instead this walks basic blocks and reports each block that contains MFMAs,
plus how many of that block's MFMAs sit *behind* its first vmcnt wait.  Those
are the MFMAs the matrix core cannot start until every outstanding VM request
retires, and they are the direct cost of the hot-path wall.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
BUILD = os.path.join(HERE, "build")


def blocks(path):
    L = open(path).read().split("\n")
    labs = {}
    for i, l in enumerate(L):
        m = re.match(r"\.(LBB0_\d+):", l.strip())
        if m:
            labs[m.group(1)] = i
    keys = sorted(labs, key=lambda k: labs[k])
    out = []
    for i, k in enumerate(keys):
        a = labs[k]
        b = labs[keys[i + 1]] if i + 1 < len(keys) else len(L)
        seg = [x.strip() for x in L[a:b]]
        mf = sum("v_mfma" in x for x in seg)
        if mf == 0:
            continue
        bl = sum(x.startswith("buffer_load") for x in seg)
        ds = sum(x.startswith("ds_read") for x in seg)
        wi = next((j for j, x in enumerate(seg)
                   if "s_waitcnt" in x and "vmcnt" in x), None)
        stranded = sum("v_mfma" in x for x in seg[wi:]) if wi is not None else 0
        waits = [x for x in seg if "s_waitcnt" in x and "vmcnt" in x]
        out.append((k, b - a, mf, bl, ds, stranded, waits))
    return out


for cfg in ("off", "on"):
    p = os.path.join(BUILD, f"isa_{cfg}.s")
    if not os.path.exists(p):
        sys.exit(f"missing {p}; run build.sh")
    print(f"=== {cfg} ===")
    print(f"  {'block':10s} {'len':>4s} {'mfma':>4s} {'bufld':>5s} "
          f"{'ds':>3s} {'stranded':>8s}  vmcnt waits")
    for k, n, mf, bl, ds, st, w in blocks(p):
        print(f"  {k:10s} {n:4d} {mf:4d} {bl:5d} {ds:3d} {st:8d}  {w}")
    print()
print("'stranded' = MFMAs in that block issued after its first vmcnt wait.")
print("Lower is better; the hot block is the one with buffer_load > 0.")
