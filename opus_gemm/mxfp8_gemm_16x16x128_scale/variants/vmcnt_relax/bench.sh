#!/bin/sh
# Interleaved paired A/B benchmark, ABBA-ordered within each block.
#   GPU=6 ROUNDS=10 ./bench.sh
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
GPU=${GPU:-6}
ROUNDS=${ROUNDS:-10}
M=${M:-8192}; N=${N:-8192}; K=${K:-8192}
run() { HIP_VISIBLE_DEVICES=$GPU "$1" -b 1 -m $M -n $N -k $K 2>/dev/null \
        | grep -oE '[0-9]+\.[0-9]+ ms' | head -1 | cut -d' ' -f1; }
echo "GPU=$GPU  b=1  M=N=K=$M  rounds=$ROUNDS"
echo ""
echo "=== correctness (on) ==="
HIP_VISIBLE_DEVICES=$GPU "$HERE/build/on.exe" -b 1 -m $M -n $N -k $K -v 1 2>/dev/null | tail -3
echo ""
WINS=0
printf "%-6s %-10s %-10s %s\n" "round" "off(ms)" "on(ms)" "off/on"
i=1
while [ $i -le $ROUNDS ]; do
    A=$(run "$HERE/build/off.exe"); B=$(run "$HERE/build/on.exe")
    B2=$(run "$HERE/build/on.exe"); A2=$(run "$HERE/build/off.exe")
    A=$(awk -v x="$A" -v y="$A2" 'BEGIN{print (x<y)?x:y}')
    B=$(awk -v x="$B" -v y="$B2" 'BEGIN{print (x<y)?x:y}')
    SP=$(awk -v a="$A" -v b="$B" 'BEGIN{printf "%.4f", a/b}')
    WINS=$((WINS + $(awk -v a="$A" -v b="$B" 'BEGIN{print (b<a)?1:0}')))
    printf "%-6s %-10s %-10s %s\n" "$i" "$A" "$B" "$SP"
    echo "$A" >> /tmp/vr_off.txt; echo "$B" >> /tmp/vr_on.txt
    i=$((i + 1))
done
echo ""
echo "on wins $WINS/$ROUNDS"
FLOP=$(awk -v m=$M -v n=$N -v k=$K 'BEGIN{print 2*m*n*k}')
for f in off on; do
    BEST=$(sort -g /tmp/vr_$f.txt | head -1)
    MED=$(sort -g /tmp/vr_$f.txt | awk '{a[NR]=$1} END{print a[int((NR+1)/2)]}')
    P=$(awk -v t="$BEST" -v f="$FLOP" 'BEGIN{printf "%.3f", f/(t/1000)/1e15}')
    printf "%-4s best=%s ms  median=%s ms  =>  %s P\n" "$f" "$BEST" "$MED" "$P"
done
rm -f /tmp/vr_off.txt /tmp/vr_on.txt
