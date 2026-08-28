OPUS_INCLUDE_DIR ?= /root/workspace/yanze/aiter/csrc/include
HIPCC           ?= /opt/rocm/bin/hipcc
ARCH            ?= gfx950

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

.PHONY: all clean benchmark scale scale_benchmark \
        scale_baseline scale_baseline_benchmark \
        scale_fixed_b_persistent scale_fixed_b_persistent_benchmark \
        scale_fixed_b_prefetch_4 scale_fixed_b_prefetch_4_benchmark \
        scale_final scale_final_benchmark \
        scale_fixed_b_asym_b_read2 scale_fixed_b_asym_b_read2_benchmark

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

clean:
	rm -rf $(BUILD)
