#include <opus/hip_minimal.hpp>
#include "traits.hpp"

#ifndef __HIP_DEVICE_COMPILE__
namespace blockscale_panel {
template<class Traits>
__global__ void gemm_a8w8_mxfp8_scale_kernel(opus_gemm_scale_kargs) {}
}
namespace blockscale_generic {
template<class Traits>
__global__ void gemm_a8w8_mxfp8_scale_kernel(opus_gemm_scale_kargs) {}
}
#else
#include "tmpl.hpp"
#include "tmpl_generic.hpp"
#endif

template __global__ void blockscale_panel::gemm_a8w8_mxfp8_scale_kernel<WholeKScaleTraits<false>>(opus_gemm_scale_kargs);
template __global__ void blockscale_panel::gemm_a8w8_mxfp8_scale_kernel<WholeKScaleTraits<true>>(opus_gemm_scale_kargs);
template __global__ void blockscale_generic::gemm_a8w8_mxfp8_scale_kernel<FourWaveTraits<false>>(opus_gemm_scale_kargs);
template __global__ void blockscale_generic::gemm_a8w8_mxfp8_scale_kernel<FourWaveTraits<true>>(opus_gemm_scale_kargs);
