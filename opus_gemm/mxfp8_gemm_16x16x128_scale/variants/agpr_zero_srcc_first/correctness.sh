#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
BUILD_DIR=${BUILD_DIR:-$HERE/build}
GPU=${GPU:-7}
LOCK=${LOCK:-/tmp/mxfp8_gpu${GPU}.lock}
RESULTS=${RESULTS:-$HERE/correctness_gpu${GPU}.log}
read -r -a tags <<<"${TAGS:-ref zero_first}"
shapes=(
    "256 256 128 2"
    "256 512 256 1"
    "512 512 512 1"
    "768 512 1024 1"
    "1024 512 1024 1"
    "1280 768 384 1"
    "8192 512 16384 1"
    "8192 2048 128 1"
    "8192 8192 128 1"
)

exec 9>"$LOCK"
flock -x 9
: > "$RESULTS"
for tag in "${tags[@]}"; do
    binary="$BUILD_DIR/$tag.exe"
    [[ -x "$binary" ]] || { echo "missing $binary; run build.sh" >&2; exit 1; }
    for shape in "${shapes[@]}"; do
        read -r m n k batch <<<"$shape"
        echo "CHECK tag=$tag m=$m n=$n k=$k batch=$batch" | tee -a "$RESULTS"
        output=$(env -u MXFP8_UNIT_SCALE HIP_VISIBLE_DEVICES="$GPU" "$binary" \
            -m "$m" -n "$n" -k "$k" -b "$batch" -v 1 -w 1 -i 1)
        printf '%s\n' "$output" | tee -a "$RESULTS"
        grep -q 'unified scale producer' <<<"$output" || exit 1
        valid=$(grep -c '^\[GEMM batch .*\] VALID$' <<<"$output" || true)
        [[ "$valid" -eq "$batch" ]] || exit 1
        ! grep -q ' FAIL$' <<<"$output" || exit 1
    done
done
echo "PASS: ${tags[*]} passed nine unified-scale shapes on GPU $GPU" | tee -a "$RESULTS"
