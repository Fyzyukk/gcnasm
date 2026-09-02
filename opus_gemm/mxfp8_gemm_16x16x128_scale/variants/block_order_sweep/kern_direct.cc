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
#ifndef MXFP8_DIRECT_ORDER
#error "MXFP8_DIRECT_ORDER must select the direct-coordinate mapping"
#endif

#define gemm_a8w8_mxfp8_scale_kernel \
    gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernel
#include "build/tmpl_direct.hpp"
#undef gemm_a8w8_mxfp8_scale_kernel

template __global__ void
gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernel<GemmTraits>(
    opus_gemm_scale_kargs);
#endif
