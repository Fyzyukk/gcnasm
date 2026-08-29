#!/bin/sh
# Paired ABBA benchmark of each unroll factor against the retained u4 build.
#
# Every candidate is measured against u4 inside the same round, ABBA-ordered,
# so a drift in machine state hits both halves of the pair.  Section 29.4:
# absolute readings on this box move ~2% with neighbour load, but the paired
# comparison survives it.  Run guard.py first anyway.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
GPU=${GPU:-0}
ROUNDS=${ROUNDS:-5}
M=${M:-8192}; N=${N:-8192}; K=${K:-8192}
CANDS=${CANDS:-"1 2 3 6 8"}
FLOP=$(awk -v m=$M -v n=$N -v k=$K 'BEGIN{print 2*m*n*k}')

run() { HIP_VISIBLE_DEVICES=$GPU "$1" -b 1 -m $M -n $N -k $K -v 0 -w 200 -i 100 \
        2>/dev/null | grep -oE 'avg_time=[0-9.]+' | cut -d= -f2; }
tf() { awk -v t="$1" -v f="$FLOP" 'BEGIN{printf "%.3f", f/(t/1000)/1e15}'; }

echo "GPU=$GPU  b=1  M=N=K=$M  rounds=$ROUNDS  baseline=u4"
echo ""
printf "%-4s %-8s %-10s %-10s %-8s %s\n" "u" "wins" "u4(ms)" "cand(ms)" "cand P" "speedup"
for c in $CANDS; do
    [ -x "$HERE/build/u$c.exe" ] || { echo "u$c: no exe"; continue; }
    W=0; BA=""; BB=""
    i=1
    while [ $i -le $ROUNDS ]; do
        A=$(run "$HERE/build/u4.exe");  B=$(run "$HERE/build/u$c.exe")
        B2=$(run "$HERE/build/u$c.exe"); A2=$(run "$HERE/build/u4.exe")
        A=$(awk -v x="$A" -v y="$A2" 'BEGIN{print (x<y)?x:y}')
        B=$(awk -v x="$B" -v y="$B2" 'BEGIN{print (x<y)?x:y}')
        W=$((W + $(awk -v a="$A" -v b="$B" 'BEGIN{print (b<a)?1:0}')))
        BA=$(awk -v n="$A" -v o="$BA" 'BEGIN{print (o==""||n<o)?n:o}')
        BB=$(awk -v n="$B" -v o="$BB" 'BEGIN{print (o==""||n<o)?n:o}')
        i=$((i + 1))
    done
    SP=$(awk -v a="$BA" -v b="$BB" 'BEGIN{printf "%+.2f%%", (a/b-1)*100}')
    printf "%-4s %-8s %-10s %-10s %-8s %s\n" "$c" "$W/$ROUNDS" "$BA" "$BB" "$(tf $BB)" "$SP"
done
