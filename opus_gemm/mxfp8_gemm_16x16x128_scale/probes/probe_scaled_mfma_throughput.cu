#include <hip/hip_runtime.h>

#include <opus/opus.hpp>

#include <cstdio>
#include <cstdlib>
#include <vector>

#define CHECK_HIP(call)                                                                    \
    do {                                                                                   \
        const hipError_t status_ = (call);                                                 \
        if (status_ != hipSuccess) {                                                       \
            std::fprintf(stderr, "HIP error %s:%d: %s\n", __FILE__, __LINE__,            \
                         hipGetErrorString(status_));                                      \
            std::exit(EXIT_FAILURE);                                                       \
        }                                                                                  \
    } while (false)

namespace {

constexpr int kWaveSize = 64;
constexpr int kMfmasPerLoop = 32;
constexpr double kFlopsPerMfma = 2.0 * 16.0 * 16.0 * 128.0;

template<int Chains, bool FullOperandTopology = false>
__global__ __launch_bounds__(512, 2)
void scaled_mfma_throughput_kernel(float* output, int loops) {
#if defined(__gfx950__)
    using MMA = opus::mfma_f32_16x16x128_fp8_fp8;
    constexpr int a_sets = FullOperandTopology ? 4 : 1;
    constexpr int b_sets = FullOperandTopology ? 6 : 1;

    const int lane = static_cast<int>(threadIdx.x) & (kWaveSize - 1);
    const int wave = static_cast<int>(threadIdx.x) / kWaveSize;

    // Build operands once, before the timed hot loop.  Lane-dependent values
    // keep the matrix instruction live without introducing any loop VMEM.
    typename MMA::vtype_a a[a_sets];
    typename MMA::vtype_b b[b_sets];
#pragma unroll
    for (int set = 0; set < a_sets; ++set) {
#pragma unroll
        for (int i = 0; i < MMA::elem_a; ++i) {
            const unsigned char bits =
                static_cast<unsigned char>(0x20 + ((lane + 3 * i + 5 * set) & 31));
            a[set][i] = __builtin_bit_cast(opus::fp8_t, bits);
        }
    }
#pragma unroll
    for (int set = 0; set < b_sets; ++set) {
#pragma unroll
        for (int i = 0; i < MMA::elem_b; ++i) {
            const unsigned char bits =
                static_cast<unsigned char>(0x20 + ((3 * lane + 5 * i + 7 * set) & 31));
            b[set][i] = __builtin_bit_cast(opus::fp8_t, bits);
        }
    }

    typename MMA::vtype_c accum[Chains];
#pragma unroll
    for (int chain = 0; chain < Chains; ++chain) {
#pragma unroll
        for (int i = 0; i < MMA::elem_c; ++i) {
            // Distinct initial values prevent identical chains from being
            // commoned while remaining small enough for a long accumulation.
            accum[chain][i] = static_cast<float>(1 + lane + 4 * chain + i) * 0x1p-20f;
        }
    }

    constexpr int packed_scale_a = 0x7f7f7f7f;
    constexpr int packed_scale_b[2] = {0x7e7e7e7e, 0x7d7d7d7d};
#pragma unroll 1
    for (int loop = 0; loop < loops; ++loop) {
        opus::static_for<kMfmasPerLoop>([&](auto i) {
            constexpr int instruction = decltype(i)::value;
            constexpr int chain = instruction % Chains;
            constexpr int half = instruction / 16;
            constexpr int a_set = FullOperandTopology ? (instruction % 16) / 4 : 0;
            constexpr int b_in_half = instruction % 4;
            // Match the GEMM's peak live range: the second N half has two new
            // B packs while its other two packs reuse dead B0 registers.
            constexpr int b_set = FullOperandTopology
                                      ? (half == 0 || b_in_half >= 2
                                             ? b_in_half
                                             : 4 + b_in_half)
                                      : 0;
            constexpr int scale_sel_a = instruction & 3;
            constexpr int scale_sel_b = (instruction >> 2) & 3;
            accum[chain] = MMA{}(a[a_set],
                                 b[b_set],
                                 accum[chain],
                                 packed_scale_a,
                                 packed_scale_b[FullOperandTopology ? half : 0],
                                 opus::number<scale_sel_a>{},
                                 opus::number<scale_sel_b>{});
        });
    }

    // One lane per wave sinks every accumulator component.  Stores happen
    // outside the hot loop and are intentionally excluded from the FLOP count.
    if (lane == 0) {
        const std::size_t wave_global =
            static_cast<std::size_t>(blockIdx.x) * (blockDim.x / kWaveSize) + wave;
        float* wave_output = output + wave_global * Chains * MMA::elem_c;
#pragma unroll
        for (int chain = 0; chain < Chains; ++chain) {
#pragma unroll
            for (int i = 0; i < MMA::elem_c; ++i) {
                wave_output[chain * MMA::elem_c + i] = accum[chain][i];
            }
        }
    }
#else
    (void)output;
    (void)loops;
#endif
}

template<int Chains, bool FullOperandTopology = false>
void run_case(float* output,
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
        &active_blocks_per_cu,
        scaled_mfma_throughput_kernel<Chains, FullOperandTopology>,
        threads,
        0));
    const double resident_waves_per_simd =
        static_cast<double>(active_blocks_per_cu * threads / kWaveSize) / 4.0;

    for (int i = 0; i < warmup; ++i) {
        hipLaunchKernelGGL((scaled_mfma_throughput_kernel<Chains, FullOperandTopology>),
                           grid, block, 0, 0, output, loops);
        CHECK_HIP(hipGetLastError());
    }

    hipEvent_t start;
    hipEvent_t stop;
    CHECK_HIP(hipEventCreate(&start));
    CHECK_HIP(hipEventCreate(&stop));
    CHECK_HIP(hipDeviceSynchronize());
    CHECK_HIP(hipEventRecord(start));
    for (int i = 0; i < iterations; ++i) {
        hipLaunchKernelGGL((scaled_mfma_throughput_kernel<Chains, FullOperandTopology>),
                           grid, block, 0, 0, output, loops);
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
    const double effective_issue_interval_ns_per_simd =
        elapsed_ms * 1.0e6 * 256.0 * 4.0 / mfma_count;
    const double nominal_issue_interval_cycles =
        effective_issue_interval_ns_per_simd * nominal_clock_khz / 1.0e6;

    std::printf("topology=%s chains=%2d blocks=%d threads=%d active_blocks/CU=%d "
                "resident_waves/SIMD=%.1f loops=%d iterations=%d "
                "avg=%.4f ms throughput=%.4f PFLOPS "
                "aggregate_mfma=%.3f Ginst/s issue_interval=%.3f ns "
                "nominal_cycles=%.2f\n",
                FullOperandTopology ? "4Ax6B" : "1Ax1B",
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
                effective_issue_interval_ns_per_simd,
                nominal_issue_interval_cycles);
}

} // namespace

int main(int argc, char** argv) {
    int blocks = 1024;
    int threads = 512;
    int loops = 2048;
    int warmup = 5;
    int iterations = 20;
    int only_chains = 0;
    int full_operand_topology = 0;

    if (argc > 1) blocks = std::atoi(argv[1]);
    if (argc > 2) threads = std::atoi(argv[2]);
    if (argc > 3) loops = std::atoi(argv[3]);
    if (argc > 4) iterations = std::atoi(argv[4]);
    if (argc > 5) warmup = std::atoi(argv[5]);
    if (argc > 6) only_chains = std::atoi(argv[6]);
    if (argc > 7) full_operand_topology = std::atoi(argv[7]);
    if (blocks <= 0 || threads <= 0 || threads > 512 || threads % kWaveSize != 0 ||
        loops <= 0 || iterations <= 0 || warmup < 0 ||
        !(only_chains == 0 || only_chains == 1 || only_chains == 2 ||
          only_chains == 4 || only_chains == 8 || only_chains == 16 ||
          only_chains == 32) ||
        !(full_operand_topology == 0 || full_operand_topology == 1) ||
        (full_operand_topology && !(only_chains == 0 || only_chains == 32))) {
        std::fprintf(stderr,
                     "usage: %s [blocks=1024] [threads=512] [loops=2048] "
                     "[iterations=20] [warmup=5] [chains=0|1|2|4|8|16|32] "
                     "[full_operand_topology=0|1]\n",
                     argv[0]);
        return EXIT_FAILURE;
    }

    int device = 0;
    hipDeviceProp_t props{};
    CHECK_HIP(hipGetDevice(&device));
    CHECK_HIP(hipGetDeviceProperties(&props, device));
    std::printf("device=%d name=%s CUs=%d clockRate=%d kHz\n",
                device, props.name, props.multiProcessorCount, props.clockRate);

    constexpr int max_chains = 32;
    constexpr int components_per_accumulator = 4;
    const std::size_t waves =
        static_cast<std::size_t>(blocks) * (threads / kWaveSize);
    const std::size_t output_elements =
        waves * max_chains * components_per_accumulator;
    float* output = nullptr;
    CHECK_HIP(hipMalloc(&output, output_elements * sizeof(float)));

    if (!full_operand_topology && (only_chains == 0 || only_chains == 1))
        run_case<1>(output, blocks, threads, loops, warmup, iterations, props.clockRate);
    if (!full_operand_topology && (only_chains == 0 || only_chains == 2))
        run_case<2>(output, blocks, threads, loops, warmup, iterations, props.clockRate);
    if (!full_operand_topology && (only_chains == 0 || only_chains == 4))
        run_case<4>(output, blocks, threads, loops, warmup, iterations, props.clockRate);
    if (!full_operand_topology && (only_chains == 0 || only_chains == 8))
        run_case<8>(output, blocks, threads, loops, warmup, iterations, props.clockRate);
    if (!full_operand_topology && (only_chains == 0 || only_chains == 16))
        run_case<16>(output, blocks, threads, loops, warmup, iterations, props.clockRate);
    if (!full_operand_topology && (only_chains == 0 || only_chains == 32))
        run_case<32>(output, blocks, threads, loops, warmup, iterations, props.clockRate);
    if (full_operand_topology)
        run_case<32, true>(output, blocks, threads, loops, warmup, iterations,
                           props.clockRate);

    std::vector<float> sink(components_per_accumulator);
    CHECK_HIP(hipMemcpy(sink.data(), output,
                        sink.size() * sizeof(float), hipMemcpyDeviceToHost));
    std::printf("sink: %.6e %.6e %.6e %.6e\n",
                sink[0], sink[1], sink[2], sink[3]);

    CHECK_HIP(hipFree(output));
    return EXIT_SUCCESS;
}
