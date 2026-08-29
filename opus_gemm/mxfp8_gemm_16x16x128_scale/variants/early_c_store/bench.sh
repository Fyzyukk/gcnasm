#!/bin/sh
# ABBA paired benchmark: MXFP8_EARLY_C_STORE off vs on.
#
# Paired and alternating because the container is shared -- roughly 1 reading
# in 10 is polluted by a neighbour, typically by ~2%.  A median delta under 1%
# without a near-sweep win count is not a result.
#
# Run variants/dvfs_study/guard.py first; it must say CLEAN.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
B="$HERE/build"
M=${M:-8192}; N=${N:-8192}; K=${K:-8192}
W=${W:-200}; I=${I:-100}; ROUNDS=${ROUNDS:-10}

[ -x "$B/off.exe" ] && [ -x "$B/on.exe" ] || { echo "build first" >&2; exit 1; }

run() { "$B/$1.exe" -m $M -n $N -k $K -b 1 -v 0 -w $W -i $I 2>&1 \
        | grep -oP 'avg_time=\K[0-9.]+'; }

echo "ABBA ${M}x${N}x${K} -b 1 -w $W -i $I, $ROUNDS rounds"
for r in $(seq 1 $ROUNDS); do
    a=$(run off); b=$(run on); c=$(run on); d=$(run off)
    echo "$r $a $b $c $d"
done | tee "$B/abba.txt"

python3 - "$B/abba.txt" <<'PY'
import sys, statistics as st
offs, ons, wins, n = [], [], 0, 0
for line in open(sys.argv[1]):
    p = line.split()
    if len(p) != 5: continue
    _, a, b, c, d = p
    o = (float(a) + float(d)) / 2      # off, bracketing
    e = (float(b) + float(c)) / 2      # on, bracketed
    offs.append(o); ons.append(e); n += 1
    if e < o: wins += 1
mo, me = st.median(offs), st.median(ons)
flops = 2 * 8192**3
print(f"\nrounds={n} on-wins={wins}/{n}")
print(f"off median {mo:.4f} ms  ({flops/(mo*1e-3)/1e15:.4f} P)")
print(f"on  median {me:.4f} ms  ({flops/(me*1e-3)/1e15:.4f} P)")
print(f"delta {(mo-me)/mo*100:+.3f}%")
PY
