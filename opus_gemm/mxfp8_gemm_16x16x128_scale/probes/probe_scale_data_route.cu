// Map each physical 16-byte half of one src-A lane to the scale-A lane that
// controls it for gfx950 v_mfma_scale_f32_16x16x128_f8f6f4.
#include "opus/opus.hpp"
#ifndef __HIP_DEVICE_COMPILE__
#include "opus/hip_minimal.hpp"
#include <cstdio>
#include <vector>
#include <cmath>
#endif

using namespace opus;

__global__ void probe_scale_data_route(int data_lane,
                                       int data_half,
                                       int hot_scale_lane,
                                       fp32_t* __restrict__ raw_c)
{
#if defined(__gfx950__)
    const int lane = static_cast<int>(__builtin_amdgcn_workitem_id_x());
    const fp8_t zero = __builtin_bit_cast(fp8_t, static_cast<unsigned char>(0x00));
    const fp8_t one  = __builtin_bit_cast(fp8_t, static_cast<unsigned char>(0x38));

    fp8x32_t a;
    fp8x32_t b;
#pragma unroll
    for(int i = 0; i < 32; ++i)
    {
        a[i] = zero;
        b[i] = one;
    }

    if(lane == data_lane)
    {
#pragma unroll
        for(int i = 0; i < 16; ++i)
            a[data_half * 16 + i] = one;
    }

    // Byte 0 is selected. 127 is x1 and 128 is x2.
    volatile int va = lane == hot_scale_lane ? 128 : 127;
    volatile int vb = 127;
    const int scale_a = va;
    const int scale_b = vb;

    fp32x4_t c{0};
    c = __builtin_amdgcn_mfma_scale_f32_16x16x128_f8f6f4(
        __builtin_bit_cast(i32x8_t, a),
        __builtin_bit_cast(i32x8_t, b),
        c, 0, 0, 0, scale_a, 0, scale_b);

#pragma unroll
    for(int i = 0; i < 4; ++i)
        raw_c[lane * 4 + i] = c[i];
#endif
}

#ifndef __HIP_DEVICE_COMPILE__
static double run(int data_lane,
                  int data_half,
                  int hot_scale_lane,
                  fp32_t* device_c,
                  std::vector<float>& host_c)
{
    hipLaunchKernelGGL(probe_scale_data_route,
                       dim3(1), dim3(64), 0, 0,
                       data_lane, data_half, hot_scale_lane, device_c);
    hipDeviceSynchronize();
    hipMemcpy(host_c.data(), device_c, host_c.size() * sizeof(float), hipMemcpyDeviceToHost);
    double sum = 0.0;
    for(float x : host_c)
        sum += x;
    return sum;
}

int main()
{
    fp32_t* device_c = nullptr;
    hipMalloc(&device_c, 64 * 4 * sizeof(fp32_t));
    std::vector<float> host_c(64 * 4);

    for(int data_lane : {0, 16, 32, 48})
    {
        for(int half = 0; half < 2; ++half)
        {
            // -1 means no hot lane: every scale is identity.
            const double baseline = run(data_lane, half, -1, device_c, host_c);
            std::printf("data_lane=%2d half=%d baseline_sum=%g  reacts:",
                        data_lane, half, baseline);
            for(int scale_lane = 0; scale_lane < 64; ++scale_lane)
            {
                const double value = run(data_lane, half, scale_lane, device_c, host_c);
                const double delta = value - baseline;
                if(std::fabs(delta) > 0.25)
                    std::printf(" scale_lane=%d(delta=%g)", scale_lane, delta);
            }
            std::printf("\n");
        }
    }

    hipFree(device_c);
    return 0;
}
#endif
