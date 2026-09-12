#pragma once

#include <hip/hip_runtime.h>
#include "traits.hpp"

namespace blockscale_panel {
template<class Traits>
__global__ void gemm_a8w8_mxfp8_scale_kernel(opus_gemm_scale_kargs);
}
namespace blockscale_generic {
template<class Traits>
__global__ void gemm_a8w8_mxfp8_scale_kernel(opus_gemm_scale_kargs);
}

// The CLI and C ABI share this selection; each call launches one GEMM.
template<bool OutputBF16>
inline void launch_blockscale_kernel(const opus_gemm_scale_kargs& args,
                                    dim3 grid, dim3 block,
                                    hipStream_t stream = nullptr) {
    if (false) { // Survey harness: force the unchanged generic kernel.
        blockscale_panel::gemm_a8w8_mxfp8_scale_kernel<WholeKScaleTraits<OutputBF16>>
            <<<grid, block, 0, stream>>>(args);
    } else {
        blockscale_generic::gemm_a8w8_mxfp8_scale_kernel<FourWaveTraits<OutputBF16>>
            <<<grid, block, 0, stream>>>(args);
    }
}
