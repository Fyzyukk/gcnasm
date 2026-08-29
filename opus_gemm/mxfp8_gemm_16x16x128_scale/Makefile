# aiter headers live in a different place on each box; take the first that exists.
OPUS_INCLUDE_DIR ?= $(firstword $(wildcard /root/workspace/yanze/aiter/csrc/include \
                                          /root/workspace/aiter/csrc/include))
HIPCC           ?= /opt/rocm/bin/hipcc
ARCH            ?= gfx950

# clang 23 toolchain.  clang 20/21/22 fail to honour the `#pragma unroll 4` on
# the main K loop (they emit `loop not unrolled` and 64 MFMA); clang 23 unrolls
# it 3x to 192 MFMA, which is worth ~+13% (2.45 P -> 2.77 P on gfx950).
# Not available from any apt repo -- build it with tools/build_clang23.sh.
CLANG23_ROOT    ?= /root/workspace/llvm-src/build
CLANG23         ?= $(CLANG23_ROOT)/bin/clang++
# Borrow ROCm's OpenMP headers/runtime: the minimal LLVM build has no openmp.
ROCM_PATH       ?= /opt/rocm
OMP_INC         ?= $(ROCM_PATH)/lib/llvm/include
OMP_LIB         ?= $(ROCM_PATH)/lib/llvm/lib
C23_FLAGS        = -I. -I$(OPUS_INCLUDE_DIR) -std=c++17 -O3 -Wall -ffast-math \
                   --offload-arch=$(ARCH) --rocm-path=$(ROCM_PATH)
C23_LDFLAGS      = -fopenmp -L$(OMP_LIB) -lomp -Wl,-rpath,$(OMP_LIB) \
                   -L$(ROCM_PATH)/lib -lamdhip64 -Wl,-rpath,$(ROCM_PATH)/lib

COMMON_FLAGS = -I. -I$(OPUS_INCLUDE_DIR) -std=c++17 -fopenmp -O3 -Wall --offload-arch=$(ARCH) -ffast-math

BUILD = build

# Original non-scale GEMM.
OUT        = $(BUILD)/gemm_a8w8_mxfp8.exe
KERNEL_OBJ = $(BUILD)/gemm_a8w8_mxfp8_kernel.o
HOST_OBJ   = $(BUILD)/gemm_a8w8_mxfp8_host.o

# The three retained scale pipelines, ordered from baseline to winner.
SCALE_BASELINE_OUT        = $(BUILD)/gemm_a8w8_mxfp8_scale.exe
SCALE_PERSISTENT_OUT      = $(BUILD)/gemm_a8w8_mxfp8_scale_fixed_b_prefetch_4.exe
SCALE_ASYM_B_READ2_OUT    = $(BUILD)/gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2.exe

SCALE_BASELINE_KERNEL_OBJ = $(BUILD)/gemm_a8w8_mxfp8_scale_kernel.o
SCALE_BASELINE_HOST_OBJ   = $(BUILD)/gemm_a8w8_mxfp8_scale_host.o
SCALE_PERSISTENT_KERNEL_OBJ = $(BUILD)/gemm_a8w8_mxfp8_scale_kernel_fixed_b_prefetch_4.o
SCALE_PERSISTENT_HOST_OBJ   = $(BUILD)/gemm_a8w8_mxfp8_scale_host_fixed_b_prefetch_4.o
SCALE_ASYM_B_READ2_KERNEL_OBJ = $(BUILD)/gemm_a8w8_mxfp8_scale_kernel_fixed_b_asym_b_read2.o
SCALE_ASYM_B_READ2_HOST_OBJ   = $(BUILD)/gemm_a8w8_mxfp8_scale_host_fixed_b_asym_b_read2.o

# Same sources, built entirely with clang 23 -- this is the performance build.
C23_OUT        = $(BUILD)/gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_clang23.exe
C23_KERNEL_OBJ = $(BUILD)/c23_kernel_fixed_b_asym_b_read2.o
C23_HOST_OBJ   = $(BUILD)/c23_host_fixed_b_asym_b_read2.o

.PHONY: all clean benchmark scale scale_benchmark \
        scale_baseline scale_baseline_benchmark \
        scale_fixed_b_persistent scale_fixed_b_persistent_benchmark \
        scale_fixed_b_prefetch_4 scale_fixed_b_prefetch_4_benchmark \
        scale_final scale_final_benchmark \
        scale_fixed_b_asym_b_read2 scale_fixed_b_asym_b_read2_benchmark \
        clang23 clang23_benchmark clang23_check

all: $(OUT)
benchmark: $(OUT)
	$(OUT)

scale scale_baseline: $(SCALE_BASELINE_OUT)
scale_benchmark scale_baseline_benchmark: $(SCALE_BASELINE_OUT)
	$(SCALE_BASELINE_OUT)

scale_fixed_b_persistent scale_fixed_b_prefetch_4: $(SCALE_PERSISTENT_OUT)
scale_fixed_b_persistent_benchmark scale_fixed_b_prefetch_4_benchmark: $(SCALE_PERSISTENT_OUT)
	$(SCALE_PERSISTENT_OUT)

scale_final scale_fixed_b_asym_b_read2: $(SCALE_ASYM_B_READ2_OUT)
scale_final_benchmark scale_fixed_b_asym_b_read2_benchmark: $(SCALE_ASYM_B_READ2_OUT)
	$(SCALE_ASYM_B_READ2_OUT)

$(BUILD):
	mkdir -p $(BUILD)

# Device compilation skips the implicit host runtime wrapper to reduce compile
# time. Host launchers are compiled normally for <<< >>> support.
$(KERNEL_OBJ): gemm_a8w8_mxfp8_kernel.cc gemm_a8w8_mxfp8_kernel_template.hpp gemm_a8w8_mxfp8_common.h | $(BUILD)
	$(HIPCC) $< $(COMMON_FLAGS) -D__HIPCC_RTC__ -Rpass-analysis=kernel-resource-usage -save-temps=obj -c -o $@

$(HOST_OBJ): gemm_a8w8_mxfp8_host.cc gemm_a8w8_mxfp8_common.h | $(BUILD)
	$(HIPCC) $< $(COMMON_FLAGS) -c -o $@

$(SCALE_BASELINE_KERNEL_OBJ): gemm_a8w8_mxfp8_scale_kernel.cc gemm_a8w8_mxfp8_scale_kernel_template.hpp gemm_a8w8_mxfp8_scale_common.h | $(BUILD)
	$(HIPCC) $< $(COMMON_FLAGS) -D__HIPCC_RTC__ -Rpass-analysis=kernel-resource-usage -save-temps=obj -c -o $@

$(SCALE_BASELINE_HOST_OBJ): gemm_a8w8_mxfp8_scale_host.cc gemm_a8w8_mxfp8_scale_common.h | $(BUILD)
	$(HIPCC) $< $(COMMON_FLAGS) -c -o $@

$(SCALE_PERSISTENT_KERNEL_OBJ): gemm_a8w8_mxfp8_scale_kernel_fixed_b_prefetch_4.cc gemm_a8w8_mxfp8_scale_kernel_template_fixed_b_prefetch_4.hpp gemm_a8w8_mxfp8_scale_common.h | $(BUILD)
	$(HIPCC) $< $(COMMON_FLAGS) -D__HIPCC_RTC__ -Rpass-analysis=kernel-resource-usage -save-temps=obj -c -o $@

$(SCALE_PERSISTENT_HOST_OBJ): gemm_a8w8_mxfp8_scale_host_fixed_b_prefetch_4.cc gemm_a8w8_mxfp8_scale_common.h | $(BUILD)
	$(HIPCC) $< $(COMMON_FLAGS) -c -o $@

$(SCALE_ASYM_B_READ2_KERNEL_OBJ): gemm_a8w8_mxfp8_scale_kernel_fixed_b_asym_b_read2.cc gemm_a8w8_mxfp8_scale_kernel_template_fixed_b_asym_b_read2.hpp gemm_a8w8_mxfp8_scale_common.h | $(BUILD)
	$(HIPCC) $< $(COMMON_FLAGS) -D__HIPCC_RTC__ -Rpass-analysis=kernel-resource-usage -save-temps=obj -c -o $@

$(SCALE_ASYM_B_READ2_HOST_OBJ): gemm_a8w8_mxfp8_scale_host_fixed_b_asym_b_read2.cc gemm_a8w8_mxfp8_scale_common.h | $(BUILD)
	$(HIPCC) $< $(COMMON_FLAGS) -c -o $@

$(OUT): $(KERNEL_OBJ) $(HOST_OBJ)
	$(HIPCC) $^ --offload-arch=$(ARCH) -fopenmp -o $@

$(SCALE_BASELINE_OUT): $(SCALE_BASELINE_KERNEL_OBJ) $(SCALE_BASELINE_HOST_OBJ)
	$(HIPCC) $^ --offload-arch=$(ARCH) -fopenmp -o $@

$(SCALE_PERSISTENT_OUT): $(SCALE_PERSISTENT_KERNEL_OBJ) $(SCALE_PERSISTENT_HOST_OBJ)
	$(HIPCC) $^ --offload-arch=$(ARCH) -fopenmp -o $@

$(SCALE_ASYM_B_READ2_OUT): $(SCALE_ASYM_B_READ2_KERNEL_OBJ) $(SCALE_ASYM_B_READ2_HOST_OBJ)
	$(HIPCC) $^ --offload-arch=$(ARCH) -fopenmp -o $@

# ---- clang 23 build (the +13% unrolled one) -------------------------------
$(C23_KERNEL_OBJ): gemm_a8w8_mxfp8_scale_kernel_fixed_b_asym_b_read2.cc gemm_a8w8_mxfp8_scale_kernel_template_fixed_b_asym_b_read2.hpp gemm_a8w8_mxfp8_scale_common.h | $(BUILD)
	@test -x $(CLANG23) || { echo "clang 23 not found at $(CLANG23) -- run tools/build_clang23.sh"; exit 1; }
	$(CLANG23) -x hip $< $(C23_FLAGS) -D__HIPCC_RTC__ -c -o $@

$(C23_HOST_OBJ): gemm_a8w8_mxfp8_scale_host_fixed_b_asym_b_read2.cc gemm_a8w8_mxfp8_scale_common.h | $(BUILD)
	@test -x $(CLANG23) || { echo "clang 23 not found at $(CLANG23) -- run tools/build_clang23.sh"; exit 1; }
	$(CLANG23) -x hip $< $(C23_FLAGS) -fopenmp -I$(OMP_INC) -c -o $@

$(C23_OUT): $(C23_KERNEL_OBJ) $(C23_HOST_OBJ)
	$(CLANG23) $^ --offload-arch=$(ARCH) --rocm-path=$(ROCM_PATH) $(C23_LDFLAGS) -o $@
	@$(MAKE) --no-print-directory clang23_check

clang23: $(C23_OUT)

# Guard rail: the whole point of this build is the unrolled loop.  If a future
# toolchain silently stops unrolling, fail loudly instead of quietly losing 13%.
clang23_check: $(C23_OUT)
	@$(ROCM_PATH)/llvm/bin/llvm-objcopy --dump-section=.hip_fatbin=$(BUILD)/.c23fb $(C23_OUT) 2>/dev/null; \
	$(ROCM_PATH)/llvm/bin/clang-offload-bundler -type=o \
	   -targets=hipv4-amdgcn-amd-amdhsa--$(ARCH) -input=$(BUILD)/.c23fb \
	   -output=$(BUILD)/.c23dev -unbundle 2>/dev/null; \
	n=$$($(ROCM_PATH)/llvm/bin/llvm-objdump -d $(BUILD)/.c23dev 2>/dev/null | grep -c v_mfma_scale_f32_16x16x128); \
	rm -f $(BUILD)/.c23fb $(BUILD)/.c23dev; \
	if [ "$$n" -ge 192 ]; then echo "clang23_check: OK -- $$n MFMA (loop unrolled)"; \
	else echo "clang23_check: FAIL -- only $$n MFMA (expected >=192); loop was NOT unrolled"; exit 1; fi

clang23_benchmark: $(C23_OUT)
	LD_LIBRARY_PATH=$(OMP_LIB):$$LD_LIBRARY_PATH $(C23_OUT) -m 8192 -n 8192 -k 8192 -b 1 -v 0 -w 200 -i 100

clean:
	rm -rf $(BUILD)
