#include <opus/hip_minimal.hpp>
#include "gemm_a8w8_mxfp8_scale_common.h"

#ifndef __HIP_DEVICE_COMPILE__
namespace blockscale_generic {
template<class Traits>
__global__ void gemm_a8w8_mxfp8_scale_kernel(opus_gemm_scale_kargs) {}
}
#else
#include "gemm_a8w8_mxfp8_scale_kernel_template.hpp"
#endif

template __global__ void blockscale_generic::gemm_a8w8_mxfp8_scale_kernel<FourWaveTraits<false>>(opus_gemm_scale_kargs);
template __global__ void blockscale_generic::gemm_a8w8_mxfp8_scale_kernel<FourWaveTraits<true>>(opus_gemm_scale_kargs);
