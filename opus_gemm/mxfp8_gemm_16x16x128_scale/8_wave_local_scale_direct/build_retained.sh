#!/usr/bin/env bash
# Build the retained T2/exact4/src1/nohandoff configuration without inherited experiments.
set -euo pipefail

task_root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
task_output="$task_root/build_retained_rebuild"
if (( $# > 1 )); then
    printf 'Usage: bash %s [NEW_BUILD_DIR | --print-config]\n' "$0" >&2
    exit 2
fi
if [[ ${1:-} == --help ]]; then
    printf 'Usage: bash %s [NEW_BUILD_DIR | --print-config]\n' "$0"
    printf 'Builds only; does not run GPU tests. The frozen retained binary is not overwritten.\n'
    exit 0
fi
if [[ $# == 1 && $1 != --print-config ]]; then
    task_output=$1
fi

# Pin every experiment selector consumed by build.sh. External toolchain/include
# locations may still be supplied through TOOLCHAIN, ROCM_PATH and OPUS_INCLUDE_DIR.
task_config=(
    ARCH=gfx950
    OUTPUT_TILES_PER_WG=2 EXACT_MASK=4 SOURCE_CHANGE=1 OUTPUT_HANDOFF=0
    PAIR_POSITION=10 PREFETCH_POSITION=1 LOOP_UNROLL=4 DOUBLE_QUEUE=1
    OPAQUE_K_BOUND=0 PHASE_UNROLL=0 BLOCK_ORDER=0
    SFB_LDS_CACHE_STAGES=0 SFB_REG_CACHE=0 SFB_PAD_CACHE=0
    C_AGPR=0 B_SECOND_AGPR=0 B_MAIN_AGPR=0 A_AGPR=0 SCALE_PREFETCH_AGPR=0
    SFB_CACHE_DEBUG_STAGE=-1 SFB_CACHE_REUSE=1 SFB_CACHE_SKIP_PRODUCER=1
    SFB_CACHE_FULL_GROUPS=0 CONSUMER_PAIR_CACHE=0 GROUP4_PUBLICATION=0
    LOCAL_REUSE=0 PRODUCER_MAP=0 SFB_ALIGNED_PAIR=0 BYTE_SCATTER=0
    B_PREFETCH_SPLIT=4 B_HEAD_LDS_GROUP=0 A1_LDS_ORDER=0 A1_WAIT_COUNT=8
    B_PREFETCH_MID_COUNT=0 B_PREFETCH_MID_POSITION=7
    B_PREFETCH_ROLLING=0 B_PREFETCH_ROLLING_FENCE=0
    PIPELINE_ADVANCE_POSITION=10 B_BALANCED_PRODUCER=0
    DEFER_QUEUE_COPY=0 QUEUE_FENCE=0 QUEUE8=0 PAIRED_REFILL=0
)

if [[ ${1:-} == --print-config ]]; then
    printf '%s\n' "${task_config[@]}" "BUILD_DIR=$task_output"
    exit 0
fi

exec env "${task_config[@]}" "BUILD_DIR=$task_output" bash "$task_root/build.sh"
