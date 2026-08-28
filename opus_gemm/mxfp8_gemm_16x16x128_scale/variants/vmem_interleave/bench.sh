#!/bin/sh
# Interleaved paired A/B benchmark.  Alternating off/on rounds so that any
# machine-level interference hits both configurations equally.
#
#   GPU=7 ROUNDS=10 ./bench.sh
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
GPU=${GPU:-7}
ROUNDS=${ROUNDS:-10}
M=${M:-8192}; N=${N:-8192}; K=${K:-8192}

run() {  # $1 = exe
    HIP_VISIBLE_DEVICES=$GPU "$1" -b 1 -m $M -n $N -k $K 2>/dev/null \
        | grep -oE '[0-9]+\.[0-9]+ ms' | head -1 | cut -d' ' -f1
}

echo "GPU=$GPU  b=1  M=N=K=$M  rounds=$ROUNDS"
echo ""
echo "=== correctness ==="
HIP_VISIBLE_DEVICES=$GPU "$HERE/build/on.exe" -b 1 -m $M -n $N -k $K -v 1 2>/dev/null | tail -3
echo ""

WINS=0
printf "%-6s %-12s %-12s %s\n" "round" "off(ms)" "on(ms)" "speedup"
i=1
while [ $i -le $ROUNDS ]; do
    A=$(run "$HERE/build/off.exe")
    B=$(run "$HERE/build/on.exe")
    SP=$(awk -v a="$A" -v b="$B" 'BEGIN{printf "%.3f", a/b}')
    W=$(awk -v a="$A" -v b="$B" 'BEGIN{print (b<a)?1:0}')
    WINS=$((WINS + W))
    printf "%-6s %-12s %-12s %s\n" "$i" "$A" "$B" "$SP"
    echo "$A" >> /tmp/vmem_off.txt
    echo "$B" >> /tmp/vmem_on.txt
    i=$((i + 1))
done

echo ""
echo "on wins $WINS/$ROUNDS rounds"
FLOP=$(awk -v m=$M -v n=$N -v k=$K 'BEGIN{print 2*m*n*k}')
for f in off on; do
    BEST=$(sort -g /tmp/vmem_$f.txt | head -1)
    P=$(awk -v t="$BEST" -v f="$FLOP" 'BEGIN{printf "%.3f", f/(t/1000)/1e15}')
    printf "%-4s best=%s ms  =>  %s P\n" "$f" "$BEST" "$P"
done
rm -f /tmp/vmem_off.txt /tmp/vmem_on.txt
