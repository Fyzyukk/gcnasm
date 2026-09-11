#include <hip/hip_runtime_api.h>

struct opus_gemm_scale_kargs;
using Launch = hipError_t (*)(const opus_gemm_scale_kargs*, int, int, hipStream_t);

// Host-only benchmark helper. Each function call still launches exactly one
// unchanged GEMM through its public C ABI. Keeping the repeat loop in native
// code prevents Python thread scheduling from creating holes in the queue.
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
        status = launch(args, output_bf16, 1, stream);
        if (status != hipSuccess) return static_cast<int>(status);
    }
    status = hipEventRecord(events.begin, stream);
    if (status != hipSuccess) return static_cast<int>(status);
    for (int i = 0; i < iterations; ++i) {
        status = launch(args, output_bf16, 1, stream);
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
