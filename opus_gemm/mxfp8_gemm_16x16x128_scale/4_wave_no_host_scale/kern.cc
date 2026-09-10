#include <opus/hip_minimal.hpp>

#include "traits.hpp"

using GemmTraits =
    four_wave_c_agpr_single_mfma_coexec_early_c_steady_b1_head_after4_tail8_v1_traits;

#ifndef __HIP_DEVICE_COMPILE__
template<typename Traits>
__global__ void
four_wave_c_agpr_single_mfma_coexec_early_c_steady_b1_head_after4_tail8_v1_kernel(
    opus_gemm_scale_kargs kargs) {}

template __global__ void
four_wave_c_agpr_single_mfma_coexec_early_c_steady_b1_head_after4_tail8_v1_kernel<GemmTraits>(
    opus_gemm_scale_kargs);
#else
#define gemm_a8w8_mxfp8_scale_kernel \
    four_wave_c_agpr_single_mfma_coexec_early_c_steady_b1_head_after4_tail8_v1_kernel
#include "tmpl.hpp"
#undef gemm_a8w8_mxfp8_scale_kernel

template __global__ void
four_wave_c_agpr_single_mfma_coexec_early_c_steady_b1_head_after4_tail8_v1_kernel<GemmTraits>(
    opus_gemm_scale_kargs);
#endif
