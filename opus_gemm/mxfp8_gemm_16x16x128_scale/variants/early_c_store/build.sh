#!/bin/sh
# MXFP8_EARLY_C_STORE: move half the C stores behind the next tile's prologue
# loads in the unified VMEM queue, then relax the tile-boundary wait from
# vmcnt(0) to vmcnt(16).
#
# See the flag's comment block in the template for the mechanism.  Short form:
# gfx9 has one unified, in-order vmcnt for loads AND stores, so with 32 stores
# queued ahead of the 9 prologue loads, "the loads landed" can only be spelled
# vmcnt(0) -- which drains the stores too.  Section 31's ablation prices that
# exposure at 11.1%.
#
# Builds off and on and reports the disassembly gate for each.  Always reads
# the LINKED exe, never the kernel TU .s (section 29.3).
#
# The flag measured +0.17% and was not retained, so the main template no longer
# carries it -- this directory keeps its own fork, like the other variants.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
TOP=$(cd "$HERE/../.." && pwd)

if [ -z "$OPUS_INCLUDE_DIR" ]; then
    for cand in /root/workspace/yanze/aiter/csrc/include \
                /root/workspace/aiter/csrc/include "$HOME/aiter/csrc/include"; do
        [ -f "$cand/opus/hip_minimal.hpp" ] && OPUS_INCLUDE_DIR=$cand && break
    done
fi
[ -f "$OPUS_INCLUDE_DIR/opus/hip_minimal.hpp" ] || {
    echo "ERROR: set OPUS_INCLUDE_DIR=<aiter>/csrc/include" >&2; exit 1; }

CLANG23=${CLANG23:-${CLANG23_ROOT:-/root/workspace/llvm-src/build}/bin/clang++}
ROCM=${ROCM_PATH:-/opt/rocm}
ARCH=${ARCH:-gfx950}
[ -x "$CLANG23" ] || { echo "ERROR: no clang 23 at $CLANG23" >&2; exit 1; }

FLAGS="-I$HERE -I$TOP -I$OPUS_INCLUDE_DIR -std=c++17 -O3 -ffast-math \
       --offload-arch=$ARCH --rocm-path=$ROCM"
LDFLAGS="-fopenmp -L$ROCM/lib/llvm/lib -lomp -Wl,-rpath,$ROCM/lib/llvm/lib \
         -L$ROCM/lib -lamdhip64 -Wl,-rpath,$ROCM/lib"
B="$HERE/build"; mkdir -p "$B"

[ -f "$B/host.o" ] || $CLANG23 -x hip \
    "$TOP/gemm_a8w8_mxfp8_scale_host_fixed_b_asym_b_read2.cc" \
    $FLAGS -fopenmp -I$ROCM/lib/llvm/include -c -o "$B/host.o"

build_one() {   # $1 = tag, $2 = extra defines
    $CLANG23 -x hip "$HERE/gemm_a8w8_mxfp8_scale_kernel_early_c_store.cc" \
        $FLAGS -D__HIPCC_RTC__ $2 -c -o "$B/k_$1.o" 2>&1 | grep -E "error" && exit 1
    $CLANG23 "$B/k_$1.o" "$B/host.o" --offload-arch=$ARCH --rocm-path=$ROCM \
        $LDFLAGS -o "$B/$1.exe"

    $ROCM/llvm/bin/llvm-objcopy --dump-section=.hip_fatbin="$B/.fb" "$B/$1.exe" 2>/dev/null
    $ROCM/llvm/bin/clang-offload-bundler -type=o \
        -targets=hipv4-amdgcn-amd-amdhsa--$ARCH -input="$B/.fb" \
        -output="$B/dev_$1.elf" -unbundle 2>/dev/null
    rm -f "$B/.fb"
    python3 "$HERE/gate.py" "$B/dev_$1.elf" "$1"
}

echo "=== off (retained behaviour) ==="; build_one off ""
echo "=== on  (MXFP8_EARLY_C_STORE)  ==="; build_one on "-DMXFP8_EARLY_C_STORE"

# The flag off must reproduce the retained kernel exactly.  Compare the
# INSTRUCTION STREAM, not the ELF bytes: the reference was built from the
# vmcnt_relax fork's TU, so its embedded metadata (source paths, symbol
# ordering) differs even when the generated code is identical.
REF="$TOP/variants/vmcnt_relax/build23/dev_off.elf"
if [ -f "$REF" ]; then
    $ROCM/llvm/bin/llvm-objdump -d "$B/dev_off.elf" | grep -P '^\t' > "$B/.off.txt"
    $ROCM/llvm/bin/llvm-objdump -d "$REF"            | grep -P '^\t' > "$B/.ref.txt"
    if cmp -s "$B/.off.txt" "$B/.ref.txt"; then
        echo "identity: OK (flag-off instruction stream matches retained)"
    else
        echo "identity: FAIL -- flag-off code differs from $REF" >&2
        diff "$B/.ref.txt" "$B/.off.txt" | head -20 >&2
        exit 1
    fi
    rm -f "$B/.off.txt" "$B/.ref.txt"
else
    echo "identity: SKIPPED (no $REF)"
fi
