#include <opus/hip_minimal.hpp>

#include "gemm_a8w8_mxfp8_scale_common.h"

using GemmTraits = gemm_a8w8_mxfp8_scale_traits<>;

#ifndef __HIP_DEVICE_COMPILE__
template<typename Traits>
__global__ void gemm_a8w8_mxfp8_scale_kernel(opus_gemm_scale_kargs kargs) {}

template __global__ void gemm_a8w8_mxfp8_scale_kernel<GemmTraits>(opus_gemm_scale_kargs);
#else
#include "gemm_a8w8_mxfp8_scale_kernel_template.hpp"

template __global__ void gemm_a8w8_mxfp8_scale_kernel<GemmTraits>(opus_gemm_scale_kargs);
#endif
