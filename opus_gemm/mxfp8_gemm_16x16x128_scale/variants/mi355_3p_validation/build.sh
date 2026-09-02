#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
VARIANTS=$(cd "$HERE/.." && pwd)
REPO=$(git -C "$HERE" rev-parse --show-toplevel)
BASELINE_DIR="$VARIANTS/combined_winner_validate"
CTRL_DIR="$VARIANTS/isa_schedule_search"
EARLY_DIR="$VARIANTS/early_c_store_full_stack"
PRERA_DIR="$VARIANTS/full_stack_sched_flags"
ORDER_DIR="$VARIANTS/block_order_sweep"
FINAL_DIR="$VARIANTS/agpr_isa_recolor"
BUILD_DIR="$HERE/build"
TOOLCHAIN=/opt/rocm-llvm23-46fcb339
CLANG23="$TOOLCHAIN/bin/clang++"
OPUS_INCLUDE_DIR=${OPUS_INCLUDE_DIR:-/root/workspace/aiter/csrc/include}

[[ -x "$CLANG23" ]] || {
    echo "missing required compiler: $CLANG23" >&2
    exit 1
}
[[ -f "$OPUS_INCLUDE_DIR/opus/hip_minimal.hpp" && \
   -f "$OPUS_INCLUDE_DIR/opus/opus.hpp" ]] || {
    echo "missing required OPUS headers under: $OPUS_INCLUDE_DIR" >&2
    exit 1
}

mkdir -p "$BUILD_DIR"
for legacy in baseline full_stack final_agpr \
    02_p18 03_ctrl_fill 04_early_c 05_prera_top 06_t2x16 07_agpr; do
    for suffix in exe isa notes dev; do
        path="$BUILD_DIR/$legacy.$suffix"
        [[ ! -e "$path" ]] || unlink "$path"
    done
done

# Both owning builders use the same clang23 toolchain and perform their own
# linked-image resource gates.  Neither builder launches a GPU workload.
(cd "$BASELINE_DIR" && OPUS_INCLUDE_DIR="$OPUS_INCLUDE_DIR" ./build.sh)
(cd "$CTRL_DIR" && \
    TOOLCHAIN="$TOOLCHAIN" CLANG23="$CLANG23" ROCM_PATH=/opt/rocm \
    OPUS_INCLUDE_DIR="$OPUS_INCLUDE_DIR" ARCH=gfx950 \
    MODES=ctrl_fill ./build.sh)
(cd "$EARLY_DIR" && OPUS_INCLUDE_DIR="$OPUS_INCLUDE_DIR" ./build.sh)
(cd "$PRERA_DIR" && OPUS_INCLUDE_DIR="$OPUS_INCLUDE_DIR" ./build.sh)
(cd "$ORDER_DIR" && OPUS_INCLUDE_DIR="$OPUS_INCLUDE_DIR" ./build.sh)
(cd "$FINAL_DIR" && OPUS_INCLUDE_DIR="$OPUS_INCLUDE_DIR" ./build.sh)

copy_set() {
    local tag=$1
    local exe=$2
    local isa=$3
    local notes=$4
    local dev=$5
    cp "$exe" "$BUILD_DIR/$tag.exe"
    cp "$isa" "$BUILD_DIR/$tag.isa"
    cp "$notes" "$BUILD_DIR/$tag.notes"
    cp "$dev" "$BUILD_DIR/$tag.dev"
    chmod +x "$BUILD_DIR/$tag.exe"
}

copy_set 00_baseline \
    "$BASELINE_DIR/build/retained.exe" \
    "$BASELINE_DIR/build/retained.isa" \
    "$BASELINE_DIR/build/retained.notes" \
    "$BASELINE_DIR/build/retained.dev"
copy_set 01_no_setprio \
    "$BASELINE_DIR/build/noprio.exe" \
    "$BASELINE_DIR/build/noprio.isa" \
    "$BASELINE_DIR/build/noprio.notes" \
    "$BASELINE_DIR/build/noprio.dev"
copy_set 02_p8_control \
    "$BASELINE_DIR/build/p8.exe" \
    "$BASELINE_DIR/build/p8.isa" \
    "$BASELINE_DIR/build/p8.notes" \
    "$BASELINE_DIR/build/p8.dev"
copy_set 03_p18 \
    "$BASELINE_DIR/build/combined.exe" \
    "$BASELINE_DIR/build/combined.isa" \
    "$BASELINE_DIR/build/combined.notes" \
    "$BASELINE_DIR/build/combined.dev"
copy_set 04_ctrl_fill \
    "$CTRL_DIR/build/ctrl_fill.exe" \
    "$CTRL_DIR/build/ctrl_fill.isa" \
    "$CTRL_DIR/build/ctrl_fill.notes" \
    "$CTRL_DIR/build/ctrl_fill.co"
copy_set 05_early_c \
    "$EARLY_DIR/build/ctrl_early.exe" \
    "$EARLY_DIR/build/ctrl_early.isa" \
    "$EARLY_DIR/build/ctrl_early.notes" \
    "$EARLY_DIR/build/ctrl_early.co"
copy_set 06_prera_top \
    "$PRERA_DIR/build/prera_top.exe" \
    "$PRERA_DIR/build/prera_top.isa" \
    "$PRERA_DIR/build/prera_top.notes" \
    "$PRERA_DIR/build/prera_top.co"
copy_set 07_t2x16 \
    "$ORDER_DIR/build/t2x16_nfast_exact.exe" \
    "$ORDER_DIR/build/t2x16_nfast_exact.isa" \
    "$ORDER_DIR/build/t2x16_nfast_exact.notes" \
    "$ORDER_DIR/build/t2x16_nfast_exact.co"
copy_set 08_agpr \
    "$FINAL_DIR/build/agpr_recolor.exe" \
    "$FINAL_DIR/build/agpr_recolor.isa" \
    "$FINAL_DIR/build/agpr_recolor.notes" \
    "$FINAL_DIR/build/agpr_recolor_linked.dev"

python3 "$HERE/gate.py" "$BUILD_DIR"

{
    printf 'git_commit=%s\n' "$(git -C "$REPO" rev-parse HEAD)"
    printf 'compiler=%s\n' "$CLANG23"
    "$CLANG23" --version | sed -n '1,2p'
    printf 'arch=gfx950\n'
    printf 'mode=unified-scale\n'
    printf 'opus_include_dir=%s\n' "$OPUS_INCLUDE_DIR"
    printf 'aiter_commit=%s\n' \
        "$(git -C "$OPUS_INCLUDE_DIR" rev-parse HEAD 2>/dev/null || printf unavailable)"
    sha256sum \
        "$OPUS_INCLUDE_DIR/opus/hip_minimal.hpp" \
        "$OPUS_INCLUDE_DIR/opus/opus.hpp"
    sha256sum \
        "$BUILD_DIR"/{00_baseline,01_no_setprio,02_p8_control,03_p18,04_ctrl_fill,05_early_c,06_prera_top,07_t2x16,08_agpr}.exe
} > "$BUILD_DIR/manifest.txt"

cat "$BUILD_DIR/manifest.txt"
