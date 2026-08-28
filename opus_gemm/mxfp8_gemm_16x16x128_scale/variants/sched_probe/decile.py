#!/usr/bin/env python3
"""Structure screen for the sched_probe candidates.

Reports, per candidate, the position of MFMA vs buffer_load inside the steady
K-loop body (the largest span between two s_barrier).  "dry" counts loads that
land in a decile containing no MFMA -- those are the cycles where the matrix
core has nothing to do.  A candidate is only worth an ABBA block if dry drops
and no resource metric regresses.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
BUILD = os.path.join(HERE, "build")


def body_metrics(path):
    lines = open(path).read().split("\n")
    bar = [i for i, l in enumerate(lines) if "s_barrier" in l]
    if len(bar) < 2:
        return None
    a, b = max(zip(bar, bar[1:]), key=lambda p: p[1] - p[0])
    seg = [l.strip() for l in lines[a:b]]
    n = len(seg)

    def dec(pred):
        h = [0] * 10
        for i, l in enumerate(seg):
            if pred(l):
                h[min(9, i * 10 // n)] += 1
        return h

    m = dec(lambda l: "mfma" in l)
    bl = dec(lambda l: "buffer_load" in l)
    dry = sum(bl[i] for i in range(10) if m[i] == 0)
    return n, m, bl, dry


rows = []
res = os.path.join(BUILD, ".res.txt")
if not os.path.exists(res):
    sys.exit("no build results; run scan.sh")

for line in open(res):
    name, tag, v, sg, sp, ss, oc = line.strip().split("|")
    met = body_metrics(os.path.join(BUILD, f"isa_{tag}.s"))
    if met is None:
        continue
    n, m, bl, dry = met
    rows.append((name, int(v), int(sg), int(sp), int(ss), int(oc), n, m, bl, dry))

base = rows[0] if rows else None
print()
print(f"{'candidate':<10} {'VGPR':>4} {'SGPR':>4} {'spill':>5} {'occ':>3} "
      f"{'body':>5} {'dry':>4}  verdict")
print("-" * 78)
for r in rows:
    name, v, sg, sp, ss, oc, n, m, bl, dry = r
    if name == base[0]:
        verdict = "control"
    else:
        bad = (v > base[1] or sp > base[3] or ss > base[4] or oc < base[5])
        if bad:
            verdict = "REJECT (resource)"
        elif dry < base[9]:
            verdict = f"CANDIDATE (dry {base[9]}->{dry})"
        else:
            verdict = f"reject (dry {base[9]}->{dry})"
    print(f"{name:<10} {v:>4} {sg:>4} {sp:>5} {oc:>3} {n:>5} {dry:>4}  {verdict}")

print()
print("decile detail (mfma / buffer_load):")
for r in rows:
    name, _, _, _, _, _, n, m, bl, dry = r
    print(f"  {name:<10} mfma {' '.join(f'{x:2d}' for x in m)}")
    print(f"  {'':<10} load {' '.join(f'{x:2d}' for x in bl)}")
print()
print("Only feed CANDIDATE rows into ABBA.  Binaries: build/<tag>.exe")
