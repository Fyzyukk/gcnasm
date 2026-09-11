TOOLCHAIN ?= /root/toolchains/rocm-llvm23-46fcb339-build
CXX = $(TOOLCHAIN)/bin/clang++
ROCM_PATH ?= /opt/rocm
FLAGS = -std=c++17 -O3 -fPIC -shared -D__HIP_PLATFORM_AMD__ -I$(ROCM_PATH)/include

.PHONY: all
all: cli_input_generator.so native_benchmark.so

cli_input_generator.so: cli_input_generator.cc
	$(CXX) -x hip --offload-arch=gfx950 --rocm-path=$(ROCM_PATH) $(FLAGS) -fopenmp -I$(ROCM_PATH)/lib/llvm/include $< \
		-L$(ROCM_PATH)/lib/llvm/lib -lomp -Wl,-rpath,$(ROCM_PATH)/lib/llvm/lib -o $@

native_benchmark.so: native_benchmark.cc
	$(CXX) $(FLAGS) $< -L$(ROCM_PATH)/lib -lamdhip64 -Wl,-rpath,$(ROCM_PATH)/lib -o $@
