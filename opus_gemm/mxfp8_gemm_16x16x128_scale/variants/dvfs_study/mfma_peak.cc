// Pure-MFMA peak probe: back-to-back v_mfma_scale_f32_16x16x128_f8f6f4 with no
// LDS and no global traffic.  This is the denominator for the normalized
// efficiency metric eff = (kernel FLOP/cycle) / (pure-MFMA FLOP/cycle).
#include <hip/hip_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <vector>
#include <algorithm>

typedef float  f32x4_t  __attribute__((ext_vector_type(4)));
typedef int    i32x8_t  __attribute__((ext_vector_type(8)));

#define NACC 8
#define UNROLL 16

__global__ __launch_bounds__(512) void mfma_peak_kernel(float* out, int iters) {
    i32x8_t a, b;
    for (int i = 0; i < 8; ++i) { a[i] = threadIdx.x + i; b[i] = threadIdx.x * 3 + i; }
    unsigned sa = 0x7f7f7f7fu, sb = 0x7f7f7f7fu;

    f32x4_t acc[NACC];
    for (int i = 0; i < NACC; ++i) acc[i] = (f32x4_t)(0.f);

    for (int it = 0; it < iters; ++it) {
#pragma unroll
        for (int u = 0; u < UNROLL; ++u) {
#pragma unroll
            for (int k = 0; k < NACC; ++k) {
                __asm__ volatile(
                    "v_mfma_scale_f32_16x16x128_f8f6f4 %0, %2, %1, %0, %4, %3 "
                    "op_sel:[0,0,0] op_sel_hi:[0,0,0]\n"
                    : "+v"(acc[k])
                    : "v"(a), "v"(b), "v"(sa), "v"(sb));
            }
        }
    }
    f32x4_t s = (f32x4_t)(0.f);
    for (int i = 0; i < NACC; ++i) s += acc[i];
    if (out) out[threadIdx.x] = s[0] + s[1] + s[2] + s[3];
}

int main(int argc, char** argv) {
    int iters = (argc > 1) ? atoi(argv[1]) : 2000;
    int reps  = (argc > 2) ? atoi(argv[2]) : 7;

    hipDeviceProp_t prop; hipGetDeviceProperties(&prop, 0);
    int cus = prop.multiProcessorCount;
    // occupancy 2 waves/SIMD => 512-thread blocks, 2 blocks per CU
    int blocks = cus * 2;
    int threads = 512;

    float* d = nullptr; hipMalloc(&d, threads * sizeof(float));

    hipEvent_t e0, e1; hipEventCreate(&e0); hipEventCreate(&e1);
    mfma_peak_kernel<<<blocks, threads>>>(d, 50);
    hipDeviceSynchronize();

    // Each MFMA: 16x16x128 => 2*16*16*128 FLOP per wave-instruction
    const double flop_per_mfma = 2.0 * 16.0 * 16.0 * 128.0;
    const int waves_per_block = threads / 64;
    double total_mfma = (double)blocks * waves_per_block
                      * (double)iters * UNROLL * NACC;
    double total_flop = total_mfma * flop_per_mfma;

    std::vector<double> pf;
    for (int r = 0; r < reps; ++r) {
        hipEventRecord(e0);
        mfma_peak_kernel<<<blocks, threads>>>(d, iters);
        hipEventRecord(e1);
        hipEventSynchronize(e1);
        float ms = 0; hipEventElapsedTime(&ms, e0, e1);
        pf.push_back(total_flop / (ms * 1e-3) / 1e15);
    }
    std::sort(pf.begin(), pf.end());
    double med = pf[pf.size() / 2];
    printf("MFMA peak: blocks=%d threads=%d CU=%d mfma_total=%.3g\n",
           blocks, threads, cus, total_mfma);
    printf("MFMA peak: median=%.4f PFLOPS  min=%.4f max=%.4f\n", med, pf.front(), pf.back());
    // FLOP/cycle at a given clock is derived by the caller from telemetry.
    printf("MFMA_PEAK_PFLOPS=%.4f\n", med);
    hipFree(d);
    return 0;
}
