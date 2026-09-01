#include <opus/hip_minimal.hpp>

#include "gemm_a8w8_mxfp8_scale_common.h"

#ifndef MXFP8_SCALE_TRAITS
#define MXFP8_SCALE_TRAITS gemm_a8w8_mxfp8_scale_traits<>
#endif
using GemmTraits = MXFP8_SCALE_TRAITS;

#ifndef __HIP_DEVICE_COMPILE__
template<typename Traits>
__global__ void
gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernel(
    opus_gemm_scale_kargs kargs) {}

template __global__ void
gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernel<GemmTraits>(
    opus_gemm_scale_kargs);
#else
#define gemm_a8w8_mxfp8_scale_kernel \
    gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernel
#include "tmpl.hpp"
#undef gemm_a8w8_mxfp8_scale_kernel

template __global__ void
gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernel<GemmTraits>(
    opus_gemm_scale_kargs);
#endif
