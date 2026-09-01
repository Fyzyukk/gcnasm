#!/bin/sh
# Interleaved paired benchmark.  Each round runs every candidate once, in a
# rotating order, so slow drift and neighbour interference hit all candidates
# equally (the container pollutes ~1 in 10 readings by ~2%; absolute numbers do
# not survive that, paired deltas do).
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
B="$HERE/build"
GPU=${GPU:-0}
ROUNDS=${ROUNDS:-8}
SHAPE=${SHAPE:-"-m 8192 -n 8192 -k 8192"}
TAGS=${TAGS:-"off a b ab"}
ROCM=${ROCM_PATH:-/opt/rocm}

for r in $(seq 1 "$ROUNDS"); do
    # rotate the order each round
    order=$(echo $TAGS | tr ' ' '\n' | awk -v n="$r" '{a[NR]=$0} END{for(i=0;i<NR;i++) print a[(i+n)%NR+1]}')
    for t in $order; do
        ms=$(HIP_VISIBLE_DEVICES=$GPU LD_LIBRARY_PATH=$ROCM/lib/llvm/lib:$LD_LIBRARY_PATH \
             "$B/$t.exe" $SHAPE -b 1 -v 0 -w 200 -i 100 2>&1 \
             | grep -oE 'avg_time=[0-9.]+' | cut -d= -f2)
        echo "$t $ms"
    done
done
