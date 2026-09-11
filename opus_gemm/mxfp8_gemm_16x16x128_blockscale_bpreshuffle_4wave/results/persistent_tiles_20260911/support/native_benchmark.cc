#include <hip/hip_runtime_api.h>

struct opus_gemm_scale_kargs;
using Launch = hipError_t (*)(const opus_gemm_scale_kargs*, int, int, hipStream_t);

// Each library implements one tile mode: auto selects baseline=1, tile2=2, tile4=4.
// Keep submission in native code and exclude setup from the HIP event interval.
extern "C" int benchmark_mxfp8_launches(
    Launch launch, const opus_gemm_scale_kargs* args, int output_bf16,
    hipStream_t stream, int warmup, int iterations, float* average_ms) {
    if (!launch || !args || !average_ms || warmup < 0 || iterations <= 0)
        return static_cast<int>(hipErrorInvalidValue);
    struct Events {
        hipEvent_t begin = nullptr, end = nullptr;
        ~Events() {
            if (begin) (void)hipEventDestroy(begin);
            if (end) (void)hipEventDestroy(end);
        }
    } events;
    hipError_t status = hipEventCreate(&events.begin);
    if (status != hipSuccess) return static_cast<int>(status);
    status = hipEventCreate(&events.end);
    if (status != hipSuccess) return static_cast<int>(status);
    for (int i = 0; i < warmup; ++i) {
        status = launch(args, output_bf16, 0, stream);
        if (status != hipSuccess) return static_cast<int>(status);
    }
    status = hipEventRecord(events.begin, stream);
    if (status != hipSuccess) return static_cast<int>(status);
    for (int i = 0; i < iterations; ++i) {
        status = launch(args, output_bf16, 0, stream);
        if (status != hipSuccess) return static_cast<int>(status);
    }
    status = hipEventRecord(events.end, stream);
    if (status != hipSuccess) return static_cast<int>(status);
    status = hipEventSynchronize(events.end);
    if (status != hipSuccess) return static_cast<int>(status);
    float elapsed = 0;
    status = hipEventElapsedTime(&elapsed, events.begin, events.end);
    if (status != hipSuccess) return static_cast<int>(status);
    *average_ms = elapsed / iterations;
    return static_cast<int>(hipSuccess);
}
