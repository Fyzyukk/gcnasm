#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
BUILD_DIR=${BUILD_DIR:-$HERE/build}
GPU=${GPU:-7}
ROUNDS=${ROUNDS:-4}
WARMUP=${WARMUP:-200}
ITERS=${ITERS:-100}
LOCK=${LOCK:-/tmp/mxfp8_gpu${GPU}.lock}
RESULTS=${RESULTS:-$HERE/results_w${WARMUP}_i${ITERS}_gpu${GPU}.tsv}

exec 9>"$LOCK"
flock -x 9
: > "$RESULTS"
printf 'round\tposition\ttag\tms\n' >> "$RESULTS"

run_one() {
    local round=$1 position=$2 tag=$3 output timing
    output=$(env -u MXFP8_UNIT_SCALE HIP_VISIBLE_DEVICES="$GPU" \
        "$BUILD_DIR/$tag.exe" -m 8192 -n 8192 -k 8192 -b 1 -v 0 \
        -w "$WARMUP" -i "$ITERS")
    grep -q 'unified scale producer' <<<"$output" || exit 1
    timing=$(sed -n 's/.*avg_time=\([0-9.]*\) ms, [0-9.]* TFlops.*/\1/p' <<<"$output")
    [[ -n "$timing" ]] || exit 1
    printf '%s\t%s\t%s\t%s\n' "$round" "$position" "$tag" "$timing" | tee -a "$RESULTS"
}

for ((round = 1; round <= ROUNDS; ++round)); do
    if ((round % 2)); then order=(ref zero_first zero_first ref)
    else order=(zero_first ref ref zero_first); fi
    for position in "${!order[@]}"; do
        run_one "$round" "$((position + 1))" "${order[$position]}"
    done
done

python3 - "$RESULTS" <<'PY'
import csv, math, statistics, sys
rows = list(csv.DictReader(open(sys.argv[1], encoding="utf-8"), delimiter="\t"))
ratios = []; refs = []; cands = []; wins = 0
for round_id in sorted({int(row["round"]) for row in rows}):
    ref = [float(row["ms"]) for row in rows if int(row["round"]) == round_id and row["tag"] == "ref"]
    cand = [float(row["ms"]) for row in rows if int(row["round"]) == round_id and row["tag"] == "zero_first"]
    rm, cm = statistics.mean(ref), statistics.mean(cand)
    ratios.append(rm / cm); refs += ref; cands += cand; wins += cm < rm
    print(f"round {round_id}: ref={rm:.6f} candidate={cm:.6f} gain={(rm/cm-1)*100:+.4f}%")
geometric = math.exp(statistics.mean(map(math.log, ratios))) - 1
median = statistics.median(refs) / statistics.median(cands) - 1
print(f"summary: geometric={geometric*100:+.4f}% median={median*100:+.4f}% wins={wins}/{len(ratios)}")
PY
