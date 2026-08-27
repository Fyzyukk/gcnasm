#include <hip/hip_runtime.h>

#include <opus/opus.hpp>

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>

#define CHECK_HIP(call)                                                                  \
    do {                                                                                 \
        const hipError_t status_ = (call);                                               \
        if (status_ != hipSuccess) {                                                     \
            std::fprintf(stderr, "HIP error %s:%d: %s\n", __FILE__, __LINE__,          \
                         hipGetErrorString(status_));                                    \
            std::exit(EXIT_FAILURE);                                                     \
        }                                                                                \
    } while (false)

namespace {

using MMA32 = opus::mfma_f32_32x32x64_fp8_fp8;

constexpr int kWaveSize = 64;
constexpr int kMfmasPerLoop = 32;
constexpr int kMaxChains = 8;
constexpr double kFlopsPerMfma = 2.0 * 32.0 * 32.0 * 64.0;

// This is intentionally a standalone 32x32x64 scaled-MFMA throughput probe.
// It does not include or modify the production 16x16x128 GEMM kernel.
template<int Chains>
__global__ __launch_bounds__(512, 1)
void throughput_kernel(float* output, int loops) {
#if defined(__gfx950__)
    const int lane = static_cast<int>(threadIdx.x) & (kWaveSize - 1);
    const int wave = static_cast<int>(threadIdx.x) / kWaveSize;

    typename MMA32::vtype_a a;
    typename MMA32::vtype_b b;
#pragma unroll
    for (int i = 0; i < MMA32::elem_a; ++i) {
        const unsigned char bits =
            static_cast<unsigned char>(0x20 + ((lane + 3 * i) & 31));
        a[i] = __builtin_bit_cast(opus::fp8_t, bits);
    }
#pragma unroll
    for (int i = 0; i < MMA32::elem_b; ++i) {
        const unsigned char bits =
            static_cast<unsigned char>(0x20 + ((3 * lane + 5 * i) & 31));
        b[i] = __builtin_bit_cast(opus::fp8_t, bits);
    }

    typename MMA32::vtype_c accum[Chains];
#pragma unroll
    for (int chain = 0; chain < Chains; ++chain) {
#pragma unroll
        for (int i = 0; i < MMA32::elem_c; ++i) {
            accum[chain][i] =
                static_cast<float>(1 + lane + 4 * chain + i) * 0x1p-20f;
        }
    }

    // Four identity E8M0 bytes. Selectors are varied as immediates so the
    // generated stream exercises the same operand form needed by a GEMM.
    constexpr int packed_identity_scale = 0x7f7f7f7f;
#pragma unroll 1
    for (int loop = 0; loop < loops; ++loop) {
        opus::static_for<kMfmasPerLoop>([&](auto i) {
            constexpr int instruction = decltype(i)::value;
            constexpr int chain = instruction % Chains;
            constexpr int scale_sel_a = instruction & 3;
            constexpr int scale_sel_b = (instruction >> 2) & 3;
            accum[chain] = MMA32{}(
                a,
                b,
                accum[chain],
                packed_identity_scale,
                packed_identity_scale,
                opus::number<scale_sel_a>{},
                opus::number<scale_sel_b>{});
        });
    }

    if (lane == 0) {
        const std::size_t wave_global =
            static_cast<std::size_t>(blockIdx.x) * (blockDim.x / kWaveSize) + wave;
        float* wave_output = output + wave_global * Chains * MMA32::elem_c;
#pragma unroll
        for (int chain = 0; chain < Chains; ++chain) {
#pragma unroll
            for (int i = 0; i < MMA32::elem_c; ++i) {
                wave_output[chain * MMA32::elem_c + i] = accum[chain][i];
            }
        }
    }
#else
    (void)output;
    (void)loops;
#endif
}

template<int Chains>
void run_throughput_case(float* output,
                         int blocks,
                         int threads,
                         int loops,
                         int warmup,
                         int iterations,
                         int nominal_clock_khz) {
    const dim3 grid(blocks);
    const dim3 block(threads);
    int active_blocks_per_cu = 0;
    CHECK_HIP(hipOccupancyMaxActiveBlocksPerMultiprocessor(
        &active_blocks_per_cu, throughput_kernel<Chains>, threads, 0));
    const double resident_waves_per_simd =
        static_cast<double>(active_blocks_per_cu * threads / kWaveSize) / 4.0;

    for (int i = 0; i < warmup; ++i) {
        hipLaunchKernelGGL(throughput_kernel<Chains>, grid, block, 0, 0,
                           output, loops);
        CHECK_HIP(hipGetLastError());
    }

    hipEvent_t start;
    hipEvent_t stop;
    CHECK_HIP(hipEventCreate(&start));
    CHECK_HIP(hipEventCreate(&stop));
    CHECK_HIP(hipDeviceSynchronize());
    CHECK_HIP(hipEventRecord(start));
    for (int i = 0; i < iterations; ++i) {
        hipLaunchKernelGGL(throughput_kernel<Chains>, grid, block, 0, 0,
                           output, loops);
        CHECK_HIP(hipGetLastError());
    }
    CHECK_HIP(hipEventRecord(stop));
    CHECK_HIP(hipEventSynchronize(stop));

    float elapsed_ms = 0.0f;
    CHECK_HIP(hipEventElapsedTime(&elapsed_ms, start, stop));
    CHECK_HIP(hipEventDestroy(start));
    CHECK_HIP(hipEventDestroy(stop));

    const double waves_per_block = static_cast<double>(threads / kWaveSize);
    const double mfma_count = static_cast<double>(blocks) * waves_per_block * loops *
                              kMfmasPerLoop * iterations;
    const double petaflops = mfma_count * kFlopsPerMfma / (elapsed_ms * 1.0e12);
    const double issue_interval_ns_per_simd =
        elapsed_ms * 1.0e6 * 256.0 * 4.0 / mfma_count;
    const double nominal_issue_interval_cycles =
        issue_interval_ns_per_simd * nominal_clock_khz / 1.0e6;

    std::printf(
        "opcode=32x32x64_scale chains=%d blocks=%d threads=%d "
        "active_blocks/CU=%d resident_waves/SIMD=%.1f loops=%d iterations=%d "
        "avg=%.4f ms throughput=%.4f PFLOPS aggregate_mfma=%.3f Ginst/s "
        "issue_interval=%.3f ns nominal_cycles=%.2f\n",
        Chains,
        blocks,
        threads,
        active_blocks_per_cu,
        resident_waves_per_simd,
        loops,
        iterations,
        elapsed_ms / iterations,
        petaflops,
        mfma_count / (elapsed_ms * 1.0e6),
        issue_interval_ns_per_simd,
        nominal_issue_interval_cycles);
}

// Probe one 16-byte half of one physical A or B lane. Exactly one physical
// scale lane changes from E8M0 127 (x1) to 128 (x2). Comparing the output sum
// with the identity-scale baseline reveals the 32x32x64 scale-lane routing.
__global__ __launch_bounds__(64, 1)
void scale_route_kernel(int probe_b,
                        int data_lane,
                        int data_half,
                        int hot_scale_lane,
                        float* raw_c) {
#if defined(__gfx950__)
    const int lane = static_cast<int>(threadIdx.x);
    const opus::fp8_t zero =
        __builtin_bit_cast(opus::fp8_t, static_cast<unsigned char>(0x00));
    const opus::fp8_t one =
        __builtin_bit_cast(opus::fp8_t, static_cast<unsigned char>(0x38));

    typename MMA32::vtype_a a;
    typename MMA32::vtype_b b;
#pragma unroll
    for (int i = 0; i < MMA32::elem_a; ++i) {
        a[i] = probe_b ? one : zero;
        b[i] = probe_b ? zero : one;
    }

    if (lane == data_lane) {
        if (data_half == 0) {
#pragma unroll
            for (int i = 0; i < 16; ++i) {
                if (probe_b) b[i] = one;
                else a[i] = one;
            }
        } else {
#pragma unroll
            for (int i = 0; i < 16; ++i) {
                if (probe_b) b[16 + i] = one;
                else a[16 + i] = one;
            }
        }
    }

    volatile int hot = lane == hot_scale_lane ? 128 : 127;
    volatile int identity = 127;
    const int scale_a = probe_b ? identity : hot;
    const int scale_b = probe_b ? hot : identity;

    typename MMA32::vtype_c c{0};
    c = MMA32{}(a, b, c, scale_a, scale_b, opus::number<0>{}, opus::number<0>{});

#pragma unroll
    for (int i = 0; i < MMA32::elem_c; ++i) {
        raw_c[lane * MMA32::elem_c + i] = c[i];
    }
#else
    (void)probe_b;
    (void)data_lane;
    (void)data_half;
    (void)hot_scale_lane;
    (void)raw_c;
#endif
}

double run_route_once(int probe_b,
                      int data_lane,
                      int data_half,
                      int hot_scale_lane,
                      float* device_c,
                      std::vector<float>& host_c) {
    hipLaunchKernelGGL(scale_route_kernel, dim3(1), dim3(kWaveSize), 0, 0,
                       probe_b, data_lane, data_half, hot_scale_lane, device_c);
    CHECK_HIP(hipGetLastError());
    CHECK_HIP(hipDeviceSynchronize());
    CHECK_HIP(hipMemcpy(host_c.data(), device_c,
                        host_c.size() * sizeof(float), hipMemcpyDeviceToHost));
    double sum = 0.0;
    for (float x : host_c) sum += x;
    return sum;
}

int run_route_probe() {
    float* device_c = nullptr;
    constexpr int output_elements = kWaveSize * MMA32::elem_c;
    CHECK_HIP(hipMalloc(&device_c, output_elements * sizeof(float)));
    std::vector<float> host_c(output_elements);

    constexpr int representative_lanes[] = {0, 1, 16, 31, 32, 33, 48, 63};
    for (int probe_b = 0; probe_b <= 1; ++probe_b) {
        std::printf("operand=%c\n", probe_b ? 'B' : 'A');
        for (int data_lane : representative_lanes) {
            for (int half = 0; half < 2; ++half) {
                const double baseline = run_route_once(
                    probe_b, data_lane, half, -1, device_c, host_c);
                std::printf("  data_lane=%2d half=%d baseline_sum=%g reacts:",
                            data_lane, half, baseline);
                for (int scale_lane = 0; scale_lane < kWaveSize; ++scale_lane) {
                    const double value = run_route_once(
                        probe_b, data_lane, half, scale_lane, device_c, host_c);
                    const double delta = value - baseline;
                    if (std::fabs(delta) > 0.25) {
                        std::printf(" scale_lane=%d(delta=%g)", scale_lane, delta);
                    }
                }
                std::printf("\n");
            }
        }
    }

    CHECK_HIP(hipFree(device_c));
    return EXIT_SUCCESS;
}

int run_throughput_probe(int argc, char** argv) {
    int blocks = 1024;
    int threads = 512;
    int loops = 2048;
    int iterations = 20;
    int warmup = 5;
    int only_chains = 0;

    if (argc > 2) blocks = std::atoi(argv[2]);
    if (argc > 3) threads = std::atoi(argv[3]);
    if (argc > 4) loops = std::atoi(argv[4]);
    if (argc > 5) iterations = std::atoi(argv[5]);
    if (argc > 6) warmup = std::atoi(argv[6]);
    if (argc > 7) only_chains = std::atoi(argv[7]);
    if (blocks <= 0 || threads <= 0 || threads > 512 ||
        threads % kWaveSize != 0 || loops <= 0 || iterations <= 0 || warmup < 0 ||
        !(only_chains == 0 || only_chains == 1 || only_chains == 2 ||
          only_chains == 4 || only_chains == 8)) {
        std::fprintf(stderr,
                     "usage: %s throughput [blocks=1024] [threads=512] "
                     "[loops=2048] [iterations=20] [warmup=5] "
                     "[chains=0|1|2|4|8]\n",
                     argv[0]);
        return EXIT_FAILURE;
    }

    int device = 0;
    hipDeviceProp_t props{};
    CHECK_HIP(hipGetDevice(&device));
    CHECK_HIP(hipGetDeviceProperties(&props, device));
    std::printf("device=%d name=%s CUs=%d clockRate=%d kHz\n",
                device, props.name, props.multiProcessorCount, props.clockRate);

    const std::size_t waves =
        static_cast<std::size_t>(blocks) * (threads / kWaveSize);
    const std::size_t output_elements =
        waves * kMaxChains * MMA32::elem_c;
    float* output = nullptr;
    CHECK_HIP(hipMalloc(&output, output_elements * sizeof(float)));

    if (only_chains == 0 || only_chains == 1)
        run_throughput_case<1>(output, blocks, threads, loops, warmup, iterations,
                               props.clockRate);
    if (only_chains == 0 || only_chains == 2)
        run_throughput_case<2>(output, blocks, threads, loops, warmup, iterations,
                               props.clockRate);
    if (only_chains == 0 || only_chains == 4)
        run_throughput_case<4>(output, blocks, threads, loops, warmup, iterations,
                               props.clockRate);
    if (only_chains == 0 || only_chains == 8)
        run_throughput_case<8>(output, blocks, threads, loops, warmup, iterations,
                               props.clockRate);

    std::vector<float> sink(MMA32::elem_c);
    CHECK_HIP(hipMemcpy(sink.data(), output,
                        sink.size() * sizeof(float), hipMemcpyDeviceToHost));
    std::printf("sink:");
    for (float x : sink) std::printf(" %.6e", x);
    std::printf("\n");

    CHECK_HIP(hipFree(output));
    return EXIT_SUCCESS;
}

} // namespace

int main(int argc, char** argv) {
    if (argc < 2 || std::strcmp(argv[1], "throughput") == 0) {
        return run_throughput_probe(argc, argv);
    }
    if (std::strcmp(argv[1], "route") == 0) {
        return run_route_probe();
    }
    std::fprintf(stderr, "usage: %s throughput [...] | route\n", argv[0]);
    return EXIT_FAILURE;
}
