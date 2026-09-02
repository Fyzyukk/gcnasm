#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
GPU=${GPU:-0}
REBUILD=${REBUILD:-1}
QUICK=${QUICK:-0}
RESULTS_DIR=${RESULTS_DIR:-$HERE/results}
WARMUP=${WARMUP:-200}
ITERS=${ITERS:-100}
ROUNDS=${ROUNDS:-4}

if [[ "$REBUILD" == 1 ]]; then
    "$HERE/build.sh"
elif [[ "$REBUILD" != 0 ]]; then
    echo "REBUILD must be 0 or 1" >&2
    exit 1
fi

GPU="$GPU" RESULTS="$RESULTS_DIR/correctness_gpu${GPU}.log" \
    "$HERE/correctness.sh"

if [[ "$QUICK" == 0 ]]; then
    GPU="$GPU" RESULTS_DIR="$RESULTS_DIR" WARMUP="$WARMUP" \
        ITERS="$ITERS" ROUNDS="$ROUNDS" "$HERE/bench_stages.sh"
elif [[ "$QUICK" == 1 ]]; then
    GPU="$GPU" REF=00_baseline CANDIDATE=08_agpr \
        WARMUP="$WARMUP" ITERS="$ITERS" ROUNDS="$ROUNDS" \
        RESULTS="$RESULTS_DIR/08_agpr_vs_00_baseline_gpu${GPU}_w${WARMUP}_i${ITERS}.tsv" \
        "$HERE/bench.sh"
else
    echo "QUICK must be 0 or 1" >&2
    exit 1
fi

echo "MI355X validation complete; results are under $RESULTS_DIR"
