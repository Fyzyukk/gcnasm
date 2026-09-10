#include <opus/hip_minimal.hpp>

#include "gemm_a8w8_mxfp8_scale_common.h"

using GemmTraits = gemm_a8w8_mxfp8_scale_traits<>;

#ifndef __HIP_DEVICE_COMPILE__
template<typename Traits>
__global__ void
gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernel(
    opus_gemm_scale_kargs kargs) {}

template __global__ void
gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernel<GemmTraits>(
    opus_gemm_scale_kargs);
#else
#ifndef MXFP8_ISOLATED_SOURCE_CHANGE
#define MXFP8_ISOLATED_SOURCE_CHANGE 2
#endif
#ifndef MXFP8_ROW_SCALE_PRODUCER_MODE
#define MXFP8_ROW_SCALE_PRODUCER_MODE 1
#endif
#ifndef MXFP8_ROW_SCALE_PAIR_POSITION
#define MXFP8_ROW_SCALE_PAIR_POSITION 10
#endif
#ifndef MXFP8_ROW_SCALE_DOUBLE_QUEUE
#define MXFP8_ROW_SCALE_DOUBLE_QUEUE 1
#endif
#ifndef MXFP8_EXACT_8192
#define MXFP8_EXACT_8192 4
#endif
#define MXFP8_ROW_MAJOR_SCALE 1
#define gemm_a8w8_mxfp8_scale_kernel \
    gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernel
#include "gemm_a8w8_mxfp8_scale_kernel.hpp"
#undef gemm_a8w8_mxfp8_scale_kernel
#undef MXFP8_ROW_MAJOR_SCALE

template __global__ void
gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernel<GemmTraits>(
    opus_gemm_scale_kargs);
#endif
