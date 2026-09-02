#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
TOP=$(cd "$HERE/../.." && pwd)
TOOLCHAIN=${TOOLCHAIN:-/opt/rocm-llvm23-46fcb339}
CLANG23=${CLANG23:-$TOOLCHAIN/bin/clang++}
ROCM=${ROCM_PATH:-/opt/rocm}
OPUS_INCLUDE_DIR=${OPUS_INCLUDE_DIR:-/root/workspace/aiter/csrc/include}
ARCH=${ARCH:-gfx950}
BUILD_DIR=${BUILD_DIR:-$HERE/build}
SOURCE_DIR="$TOP/variants/output_b1_overlap"
MODES=${MODES:-"ctrl_fill setup_resource setup_m0 setup_resource+ctrl_fill"}

FLAGS=(
    -I"$SOURCE_DIR" -I"$TOP" -I"$OPUS_INCLUDE_DIR"
    -std=c++17 -O3 -ffast-math
    --offload-arch="$ARCH" --rocm-path="$ROCM"
)
LDFLAGS=(
    -fopenmp -L"$ROCM/lib/llvm/lib" -lomp
    -Wl,-rpath,"$ROCM/lib/llvm/lib"
    -L"$ROCM/lib" -lamdhip64 -Wl,-rpath,"$ROCM/lib"
)

[[ -x "$CLANG23" ]] || { echo "missing clang23: $CLANG23" >&2; exit 1; }
[[ -f "$OPUS_INCLUDE_DIR/opus/hip_minimal.hpp" ]] || {
    echo "missing OPUS headers: $OPUS_INCLUDE_DIR" >&2
    exit 1
}

mkdir -p "$BUILD_DIR"
"$CLANG23" -x hip \
    "$TOP/gemm_a8w8_mxfp8_scale_host_fixed_b_asym_b_read2_unified_scale.cc" \
    "${FLAGS[@]}" -fopenmp -I"$ROCM/lib/llvm/include" \
    -c -o "$BUILD_DIR/host.o"
"$CLANG23" -x hip "$SOURCE_DIR/kern.cc" "${FLAGS[@]}" -D__HIPCC_RTC__ \
    -DMXFP8_OUTPUT_B1_HANDOFF_PAIRS=1 \
    -c -o "$BUILD_DIR/kernel_ref.o"
"$CLANG23" "$BUILD_DIR/kernel_ref.o" "$BUILD_DIR/host.o" \
    --offload-arch="$ARCH" --rocm-path="$ROCM" "${LDFLAGS[@]}" \
    -o "$BUILD_DIR/ref.exe"
"$CLANG23" -x hip "$SOURCE_DIR/kern.cc" "${FLAGS[@]}" -D__HIPCC_RTC__ \
    -DMXFP8_OUTPUT_B1_HANDOFF_PAIRS=1 --cuda-device-only -S \
    -o "$BUILD_DIR/ref.s"

"$TOOLCHAIN/bin/llvm-objcopy" \
    --dump-section=.hip_fatbin="$BUILD_DIR/ref.fb" "$BUILD_DIR/ref.exe"
"$TOOLCHAIN/bin/clang-offload-bundler" -type=o \
    -targets=host-x86_64-unknown-linux-gnu- \
    -input="$BUILD_DIR/ref.fb" -output="$BUILD_DIR/host.empty" -unbundle

for mode in $MODES; do
    tag=${mode//+/_}
    python3 "$HERE/patch_schedule.py" "$mode" \
        "$BUILD_DIR/ref.s" "$BUILD_DIR/$tag.s"
    "$CLANG23" -x assembler -target amdgcn-amd-amdhsa -mcpu="$ARCH" \
        "$BUILD_DIR/$tag.s" -o "$BUILD_DIR/$tag.co"
    "$TOOLCHAIN/bin/clang-offload-bundler" -type=o \
        -targets=host-x86_64-unknown-linux-gnu-,hipv4-amdgcn-amd-amdhsa--"$ARCH" \
        -input="$BUILD_DIR/host.empty" -input="$BUILD_DIR/$tag.co" \
        -output="$BUILD_DIR/$tag.fb"
    "$TOOLCHAIN/bin/llvm-objcopy" \
        --update-section=.hip_fatbin="$BUILD_DIR/$tag.fb" \
        "$BUILD_DIR/ref.exe" "$BUILD_DIR/$tag.exe"
    chmod +x "$BUILD_DIR/$tag.exe"
    "$TOOLCHAIN/bin/llvm-objdump" -d --mcpu="$ARCH" \
        "$BUILD_DIR/$tag.co" > "$BUILD_DIR/$tag.isa"
    "$TOOLCHAIN/bin/llvm-readelf" --notes "$BUILD_DIR/$tag.co" \
        > "$BUILD_DIR/$tag.notes"
done

python3 - "$BUILD_DIR" <<'PY'
import re
import sys
from pathlib import Path

build = Path(sys.argv[1])
for path in sorted(build.glob("*.isa")):
    text = path.read_text(encoding="utf-8")
    notes = path.with_suffix(".notes").read_text(encoding="utf-8")
    def meta(name):
        match = re.search(rf"\.{name}:\s*(\d+)", notes)
        if not match:
            raise SystemExit(f"{path.stem}: missing {name}")
        return int(match.group(1))
    values = dict(
        mfma=text.count("v_mfma_scale_f32_16x16x128"),
        vgpr=meta("vgpr_count"),
        sgpr=meta("sgpr_count"),
        vspill=meta("vgpr_spill_count"),
        sspill=meta("sgpr_spill_count"),
        private=meta("private_segment_fixed_size"),
        lds=meta("group_segment_fixed_size"),
        barriers=len(re.findall(r"^\s*s_barrier\b", text, re.MULTILINE)),
        loads=len(re.findall(r"^\s*buffer_load_dwordx4\b[^\n]*\blds\b", text, re.MULTILINE)),
        stores=text.count("buffer_store_dwordx4"),
    )
    print(path.stem, " ".join(f"{k}={v}" for k, v in values.items()))
    if values != {
        "mfma": 192, "vgpr": 240, "sgpr": 101,
        "vspill": 0, "sspill": 0, "private": 0,
        "lds": 139264, "barriers": 7, "loads": 91, "stores": 32,
    }:
        raise SystemExit(f"gate failed for {path.stem}: {values}")
PY
