#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
BUILD_DIR="$HERE/build"
GPU=${GPU:-0}
LOCK=${LOCK:-/tmp/mxfp8_gpu${GPU}.lock}
ROUNDS=${ROUNDS:-4}
WARMUP=${WARMUP:-200}
ITERS=${ITERS:-100}
M=${M:-8192}
N=${N:-8192}
K=${K:-8192}
BATCH=${BATCH:-1}
REF=${REF:-00_baseline}
CANDIDATE=${CANDIDATE:-08_agpr}
RESULTS=${RESULTS:-$HERE/results/${CANDIDATE}_vs_${REF}_gpu${GPU}_w${WARMUP}_i${ITERS}.tsv}
RAW_LOG=${RAW_LOG:-${RESULTS%.tsv}.log}
SUMMARY=${SUMMARY:-${RESULTS%.tsv}.summary.txt}

[[ "$REF" != "$CANDIDATE" ]] || {
    echo "REF and CANDIDATE must differ" >&2
    exit 1
}
[[ -x "$BUILD_DIR/$REF.exe" ]] || {
    echo "missing $BUILD_DIR/$REF.exe; run ./build.sh first" >&2
    exit 1
}
[[ -x "$BUILD_DIR/$CANDIDATE.exe" ]] || {
    echo "missing $BUILD_DIR/$CANDIDATE.exe; run ./build.sh first" >&2
    exit 1
}

mkdir -p "$(dirname "$RESULTS")"
if [[ "${LOCK_HELD:-0}" != 1 ]]; then
    exec 9>"$LOCK"
    flock -x 9
fi
: > "$RESULTS"
: > "$RAW_LOG"
printf 'round\tposition\ttag\tms\ttflops\n' >> "$RESULTS"

run_one() {
    local round=$1 position=$2 tag=$3 output timing tflops
    output=$(env -u MXFP8_UNIT_SCALE HIP_VISIBLE_DEVICES="$GPU" \
        "$BUILD_DIR/$tag.exe" \
        -m "$M" -n "$N" -k "$K" -b "$BATCH" -v 0 \
        -w "$WARMUP" -i "$ITERS")
    {
        printf 'round=%s position=%s tag=%s\n' "$round" "$position" "$tag"
        printf '%s\n' "$output"
    } >> "$RAW_LOG"
    grep -q 'unified scale producer' <<<"$output" || {
        echo "FAIL: unified-scale banner missing for $tag" >&2
        exit 1
    }
    timing=$(sed -n 's/.*avg_time=\([0-9.]*\) ms, [0-9.]* TFlops.*/\1/p' <<<"$output")
    tflops=$(sed -n 's/.*avg_time=[0-9.]* ms, \([0-9.]*\) TFlops.*/\1/p' <<<"$output")
    [[ -n "$timing" && -n "$tflops" ]] || {
        echo "FAIL: could not parse performance output for $tag" >&2
        exit 1
    }
    printf '%s\t%s\t%s\t%s\t%s\n' \
        "$round" "$position" "$tag" "$timing" "$tflops" | tee -a "$RESULTS"
}

for ((round = 1; round <= ROUNDS; ++round)); do
    if ((round % 2)); then
        order=("$REF" "$CANDIDATE" "$CANDIDATE" "$REF")
    else
        order=("$CANDIDATE" "$REF" "$REF" "$CANDIDATE")
    fi
    for position in "${!order[@]}"; do
        run_one "$round" "$((position + 1))" "${order[$position]}"
    done
done

python3 - "$RESULTS" "$REF" "$CANDIDATE" <<'PY' | tee "$SUMMARY"
import csv
import math
import statistics
import sys

path, ref_tag, candidate_tag = sys.argv[1:]
rows = list(csv.DictReader(open(path, encoding="utf-8"), delimiter="\t"))
ratios = []
wins = 0
refs_ms = []
candidates_ms = []
refs_tflops = []
candidates_tflops = []

for round_id in sorted({int(row["round"]) for row in rows}):
    ref_rows = [row for row in rows if int(row["round"]) == round_id and row["tag"] == ref_tag]
    candidate_rows = [row for row in rows if int(row["round"]) == round_id and row["tag"] == candidate_tag]
    ref_ms = statistics.mean(float(row["ms"]) for row in ref_rows)
    candidate_ms = statistics.mean(float(row["ms"]) for row in candidate_rows)
    ratio = ref_ms / candidate_ms
    ratios.append(ratio)
    wins += candidate_ms < ref_ms
    refs_ms.extend(float(row["ms"]) for row in ref_rows)
    candidates_ms.extend(float(row["ms"]) for row in candidate_rows)
    refs_tflops.extend(float(row["tflops"]) for row in ref_rows)
    candidates_tflops.extend(float(row["tflops"]) for row in candidate_rows)
    print(
        f"round {round_id}: {ref_tag}={ref_ms:.6f} ms "
        f"{candidate_tag}={candidate_ms:.6f} ms gain={(ratio - 1) * 100:+.4f}%"
    )

geometric_gain = math.exp(statistics.mean(map(math.log, ratios))) - 1
median_gain = statistics.median(refs_ms) / statistics.median(candidates_ms) - 1
ref_gmean_ms = math.exp(statistics.mean(map(math.log, refs_ms)))
candidate_gmean_ms = math.exp(statistics.mean(map(math.log, candidates_ms)))
ref_gmean_p = math.exp(statistics.mean(math.log(value) for value in refs_tflops)) / 1000
candidate_gmean_p = math.exp(statistics.mean(math.log(value) for value in candidates_tflops)) / 1000

print(
    f"summary: geometric={geometric_gain * 100:+.4f}% "
    f"median={median_gain * 100:+.4f}% wins={wins}/{len(ratios)}"
)
print(f"absolute: {ref_tag}={ref_gmean_ms:.6f} ms = {ref_gmean_p:.5f} P")
print(f"absolute: {candidate_tag}={candidate_gmean_ms:.6f} ms = {candidate_gmean_p:.5f} P")
print("PASS_3P" if candidate_gmean_p >= 3.0 else "BELOW_3P")
PY
