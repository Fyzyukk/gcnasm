#include <opus/hip_minimal.hpp>

#include "gemm_a8w8_mxfp8_scale_common.h"
#include "gemm_a8w8_mxfp8_scale_kernel_template.hpp"

using GemmTraits = gemm_a8w8_mxfp8_scale_traits<>;

template __global__ void gemm_a8w8_mxfp8_scale_kernel<GemmTraits>(opus_gemm_scale_kargs);
