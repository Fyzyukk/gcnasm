#include <opus/hip_minimal.hpp>
using I8 = int __attribute__((ext_vector_type(8)));
using F4 = float __attribute__((ext_vector_type(4)));

// Compile only. Establish whether a zero SrcC avoids AGPR initialization when
// the result is pinned; no probe kernel is executed or used for performance.
extern "C" __global__ void zero_acc_probe(const I8* a, const I8* b, F4* output) {
    const int tid = __builtin_amdgcn_workitem_id_x();
    __attribute__((amdgpu_pin_agpr(0))) F4 c;
    c = __builtin_amdgcn_mfma_scale_f32_16x16x128_f8f6f4(
        a[tid], b[tid], F4{}, 0, 0, 0, 127, 0, 127);
    output[tid] = c;
}
