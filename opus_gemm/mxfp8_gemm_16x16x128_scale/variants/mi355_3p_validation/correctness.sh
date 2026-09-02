#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
BUILD_DIR="$HERE/build"
GPU=${GPU:-0}
LOCK=${LOCK:-/tmp/mxfp8_gpu${GPU}.lock}
RESULTS=${RESULTS:-$HERE/results/correctness_gpu${GPU}.log}
read -r -a tags <<<"${TAGS:-00_baseline 01_no_setprio 02_p8_control 03_p18 04_ctrl_fill 05_early_c 06_prera_top 07_t2x16 08_agpr}"

shapes=(
    "256 256 128 2"
    "256 512 256 1"
    "512 512 512 1"
    "768 512 1024 1"
    "1024 512 1024 1"
    "1280 768 384 1"
    "8192 512 16384 1"
    "8192 2048 128 1"
)

mkdir -p "$(dirname "$RESULTS")"
exec 9>"$LOCK"
flock -x 9
: > "$RESULTS"

for tag in "${tags[@]}"; do
    binary="$BUILD_DIR/$tag.exe"
    [[ -x "$binary" ]] || {
        echo "missing $binary; run ./build.sh first" >&2
        exit 1
    }
    tag_shapes=("${shapes[@]}")
    if [[ "$tag" == 07_t2x16 || "$tag" == 08_agpr ]]; then
        # Exercise the exact-8192 block-order fast path, not only its fallback.
        tag_shapes+=("8192 8192 128 1")
    fi
    for shape in "${tag_shapes[@]}"; do
        read -r m n k batch <<<"$shape"
        echo "CHECK tag=$tag m=$m n=$n k=$k batch=$batch" | tee -a "$RESULTS"
        output=$(env -u MXFP8_UNIT_SCALE HIP_VISIBLE_DEVICES="$GPU" "$binary" \
            -m "$m" -n "$n" -k "$k" -b "$batch" -v 1 -w 1 -i 1)
        printf '%s\n' "$output" | tee -a "$RESULTS"
        grep -q 'unified scale producer' <<<"$output" || {
            echo "FAIL: unified-scale banner missing for $tag" >&2
            exit 1
        }
        valid=$(grep -c '^\[GEMM batch .*\] VALID$' <<<"$output" || true)
        [[ "$valid" -eq "$batch" ]] || {
            echo "FAIL: correctness tag=$tag shape=$shape" >&2
            exit 1
        }
        ! grep -q ' FAIL$' <<<"$output" || {
            echo "FAIL: correctness tag=$tag shape=$shape" >&2
            exit 1
        }
    done
done

echo "PASS: ${tags[*]} passed all eight shared unified-scale shapes; 07_t2x16 and 08_agpr also passed active 8192x8192x128 on physical GPU $GPU" | tee -a "$RESULTS"
