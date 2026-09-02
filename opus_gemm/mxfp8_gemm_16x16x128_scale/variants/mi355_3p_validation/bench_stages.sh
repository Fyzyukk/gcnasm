#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
GPU=${GPU:-0}
LOCK=${LOCK:-/tmp/mxfp8_gpu${GPU}.lock}
RESULTS_DIR=${RESULTS_DIR:-$HERE/results}
WARMUP=${WARMUP:-200}
ITERS=${ITERS:-100}
ROUNDS=${ROUNDS:-4}

pairs=(
    "00_baseline 01_no_setprio"
    "02_p8_control 03_p18"
    "03_p18 04_ctrl_fill"
    "04_ctrl_fill 05_early_c"
    "05_early_c 06_prera_top"
    "06_prera_top 07_t2x16"
    "07_t2x16 08_agpr"
)

mkdir -p "$RESULTS_DIR"
exec 9>"$LOCK"
flock -x 9

for pair in "${pairs[@]}"; do
    read -r ref candidate <<<"$pair"
    echo "===== $candidate vs $ref ====="
    GPU="$GPU" LOCK_HELD=1 REF="$ref" CANDIDATE="$candidate" \
        WARMUP="$WARMUP" ITERS="$ITERS" ROUNDS="$ROUNDS" \
        RESULTS="$RESULTS_DIR/${candidate}_vs_${ref}_gpu${GPU}_w${WARMUP}_i${ITERS}.tsv" \
        "$HERE/bench.sh"
done

echo "===== 08_agpr vs 00_baseline (direct total) ====="
GPU="$GPU" LOCK_HELD=1 REF=00_baseline CANDIDATE=08_agpr \
    WARMUP="$WARMUP" ITERS="$ITERS" ROUNDS="$ROUNDS" \
    RESULTS="$RESULTS_DIR/08_agpr_vs_00_baseline_gpu${GPU}_w${WARMUP}_i${ITERS}.tsv" \
    "$HERE/bench.sh"
