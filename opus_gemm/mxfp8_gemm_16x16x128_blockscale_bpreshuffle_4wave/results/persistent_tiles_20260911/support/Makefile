TOOLCHAIN ?= /root/toolchains/rocm-llvm23-46fcb339-build
ROCM_PATH ?= /opt/rocm
CXX = $(TOOLCHAIN)/bin/clang++
CLI_SOURCE = ../../continuation_20260911/round3/support/cli_input_generator.cc

.PHONY: all
all: native_benchmark.so cli_input_generator.so

native_benchmark.so: native_benchmark.cc Makefile
	$(CXX) -std=c++17 -O3 -fPIC -shared -D__HIP_PLATFORM_AMD__ -I$(ROCM_PATH)/include $< -L$(ROCM_PATH)/lib -lamdhip64 -Wl,-rpath,$(ROCM_PATH)/lib -o $@

cli_input_generator.so: $(CLI_SOURCE) Makefile
	$(CXX) -x hip --offload-arch=gfx950 --rocm-path=$(ROCM_PATH) -std=c++17 -O3 -fPIC -shared -D__HIP_PLATFORM_AMD__ -I$(ROCM_PATH)/include -fopenmp -I$(ROCM_PATH)/lib/llvm/include $< -L$(ROCM_PATH)/lib/llvm/lib -lomp -Wl,-rpath,$(ROCM_PATH)/lib/llvm/lib -o $@
