#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
TOP=$(cd "$HERE/../.." && pwd)
OUTPUT_VARIANT="$TOP/variants/output_b1_overlap"
TOOLCHAIN=/opt/rocm-llvm23-46fcb339
CLANG23="$TOOLCHAIN/bin/clang++"
ROCM=/opt/rocm
OPUS_INCLUDE_DIR=${OPUS_INCLUDE_DIR:-/root/workspace/aiter/csrc/include}
ARCH=gfx950
BUILD_DIR="$HERE/build"

FLAGS=(
    -I"$BUILD_DIR" -I"$OUTPUT_VARIANT" -I"$TOP" -I"$OPUS_INCLUDE_DIR"
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

# Fresh retained source, including its original uniform s_setprio toggles.
"$CLANG23" -x hip \
    "$TOP/gemm_a8w8_mxfp8_scale_kernel_fixed_b_asym_b_read2_unified_scale.cc" \
    "${FLAGS[@]}" -D__HIPCC_RTC__ -c -o "$BUILD_DIR/retained.o"

# Same retained source with only the six source-level s_setprio calls removed.
sed '/__builtin_amdgcn_s_setprio([01]);/d' \
    "$TOP/gemm_a8w8_mxfp8_scale_kernel_template_fixed_b_asym_b_read2_unified_scale.hpp" \
    > "$BUILD_DIR/tmpl_noprio.hpp"
sed 's#"gemm_a8w8_mxfp8_scale_kernel_template_fixed_b_asym_b_read2_unified_scale.hpp"#"tmpl_noprio.hpp"#' \
    "$TOP/gemm_a8w8_mxfp8_scale_kernel_fixed_b_asym_b_read2_unified_scale.cc" \
    > "$BUILD_DIR/kern_noprio.cc"
"$CLANG23" -x hip "$BUILD_DIR/kern_noprio.cc" \
    "${FLAGS[@]}" -D__HIPCC_RTC__ -c -o "$BUILD_DIR/noprio.o"

# The output-handoff source is already no-setprio.  p8 is its 32/0 control;
# p1 is the selected 18/14 handoff and therefore the combined winner.
for spec in "p8 8" "combined 1"; do
    read -r tag position <<<"$spec"
    "$CLANG23" -x hip "$OUTPUT_VARIANT/kern.cc" \
        "${FLAGS[@]}" -D__HIPCC_RTC__ \
        -DMXFP8_OUTPUT_B1_HANDOFF_PAIRS="$position" \
        -c -o "$BUILD_DIR/$tag.o"
done

for tag in retained noprio p8 combined; do
    "$CLANG23" "$BUILD_DIR/$tag.o" "$BUILD_DIR/host.o" \
        --offload-arch="$ARCH" --rocm-path="$ROCM" "${LDFLAGS[@]}" \
        -o "$BUILD_DIR/$tag.exe"
    "$TOOLCHAIN/bin/llvm-objcopy" \
        --dump-section=.hip_fatbin="$BUILD_DIR/$tag.fatbin" \
        "$BUILD_DIR/$tag.exe"
    "$TOOLCHAIN/bin/clang-offload-bundler" -type=o \
        -targets="hipv4-amdgcn-amd-amdhsa--$ARCH" \
        -input="$BUILD_DIR/$tag.fatbin" -output="$BUILD_DIR/$tag.dev" -unbundle
    "$TOOLCHAIN/bin/llvm-objdump" -d --mcpu="$ARCH" "$BUILD_DIR/$tag.dev" \
        > "$BUILD_DIR/$tag.isa"
    "$TOOLCHAIN/bin/llvm-readelf" --notes "$BUILD_DIR/$tag.dev" \
        > "$BUILD_DIR/$tag.notes"
    rm -f "$BUILD_DIR/$tag.fatbin"
done

python3 - "$BUILD_DIR" <<'PY'
import pathlib
import re
import sys

build = pathlib.Path(sys.argv[1])
expected_prio = {"retained": 22, "noprio": 0, "p8": 0, "combined": 0}

for tag in expected_prio:
    isa = (build / f"{tag}.isa").read_text()
    notes = (build / f"{tag}.notes").read_text()

    def metadata(name):
        match = re.search(rf"\.{re.escape(name)}:\s*(\d+)", notes)
        if not match:
            raise SystemExit(f"FAIL {tag}: missing .{name}")
        return int(match.group(1))

    values = {
        "inst": len(re.findall(r"^\s*\S.*// [0-9A-F]{12,}:", isa, re.MULTILINE)),
        "mfma": isa.count("v_mfma_scale_f32_16x16x128"),
        "setprio": len(re.findall(r"\bs_setprio\b", isa)),
        "wait": len(re.findall(r"\bs_waitcnt\b", isa)),
        "nop": len(re.findall(r"\bs_nop\b", isa)),
        "barrier": len(re.findall(r"\bs_barrier\b", isa)),
        "branch": len(re.findall(r"\bs_cbranch_", isa)),
        "vgpr": metadata("vgpr_count"),
        "sgpr": metadata("sgpr_count"),
        "vspill": metadata("vgpr_spill_count"),
        "sspill": metadata("sgpr_spill_count"),
        "private": metadata("private_segment_fixed_size"),
        "lds": metadata("group_segment_fixed_size"),
        "scratch": len(re.findall(r"^\s*scratch_", isa, re.MULTILINE)),
        "stores": isa.count("buffer_store_dwordx4"),
    }
    print(tag + ": " + " ".join(f"{key}={value}" for key, value in values.items()))
    if values["mfma"] != 192 or values["setprio"] != expected_prio[tag]:
        raise SystemExit(f"FAIL {tag}: MFMA/setprio gate")
    if values["vgpr"] > 256 or values["vspill"] or values["sspill"]:
        raise SystemExit(f"FAIL {tag}: register gate")
    if values["scratch"] or values["private"]:
        raise SystemExit(f"FAIL {tag}: scratch/private gate")
    if values["lds"] != 139264 or values["stores"] != 32 or values["barrier"] != 7:
        raise SystemExit(f"FAIL {tag}: LDS/store/barrier gate")

# The source transformation itself must be exactly the deletion of the six
# uniform priority calls.  LLVM is allowed to regenerate waitcnt scheduling;
# that linked-code effect is one of the things this experiment measures.
top = build.parents[2]
source = (top / "gemm_a8w8_mxfp8_scale_kernel_template_fixed_b_asym_b_read2_unified_scale.hpp").read_text()
generated = (build / "tmpl_noprio.hpp").read_text()
filtered = "\n".join(
    line for line in source.splitlines()
    if "__builtin_amdgcn_s_setprio(" not in line
) + "\n"
if source.count("__builtin_amdgcn_s_setprio(") != 6 or generated != filtered:
    raise SystemExit("FAIL: noprio source transformation is not setprio-only")
print("PASS: noprio source transformation deletes exactly six s_setprio calls")
PY
