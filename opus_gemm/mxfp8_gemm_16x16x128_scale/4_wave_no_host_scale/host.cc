// Standalone host launcher for the logical row-major scale ABI. The kernel
// performs the scale transpose from VGPRs into LDS.

#include <hip/hip_runtime.h>
#include "traits.hpp"

#define MXFP8_SCALE_KERNEL \
    four_wave_c_agpr_single_mfma_coexec_early_c_steady_b1_head_after4_tail8_v1_kernel
#define MXFP8_SCALE_TRAITS \
    four_wave_c_agpr_single_mfma_coexec_early_c_steady_b1_head_after4_tail8_v1_traits
#define MXFP8_SCALE_OUTPUT_TILES_PER_WG 1
#define MXFP8_SCALE_VARIANT_NAME \
    "4W exact-K64 branchless-wrap SFA-K8 raw/K4 queue + SFB-K16 dist22, 256x256x128, unified scale"

#include <hip/hip_fp8.h>
#include <opus/hip_minimal.hpp>
#include <algorithm>
#include <chrono>
#include <cerrno>
#include <climits>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <memory>
#include <omp.h>

#include "gemm_a8w8_mxfp8_scale_common.h"

template<class Traits>
__global__ void MXFP8_SCALE_KERNEL(opus_gemm_scale_kargs kargs);

#define CHECK_HIP(call)                                                                                   \
    do {                                                                                                  \
        hipError_t status_ = call;                                                                        \
        if (status_ != hipSuccess) {                                                                      \
            fprintf(stderr, "HIP error (%s:%d): %s\n", __FILE__, __LINE__, hipGetErrorString(status_));   \
            exit(1);                                                                                      \
        }                                                                                                 \
    } while(0)

#define CHECK_HIP_KERNEL_LAUNCH() CHECK_HIP(hipGetLastError())

using GemmTraits = MXFP8_SCALE_TRAITS;
static constexpr int FIXED_B_PREFETCH_OUTPUT_TILES_PER_WG =
    MXFP8_SCALE_OUTPUT_TILES_PER_WG;
using host_fp8_t = __hip_fp8_e4m3;
using fp32_t = float;
using e8m0_t = uint8_t;

// E8M0: 8-bit exponent-only scale, bias 127. value = 2^(byte - 127); 0x7F = 1.0.
inline fp32_t e8m0_to_f32(e8m0_t e) {
    return std::ldexp(1.0f, static_cast<int>(e) - 127);
}

// Input bytes depend only on the seed, buffer stream and logical element index.
// OpenMP thread count/scheduling cannot change inputs, including batch offsets.
bool env_flag(const char* name) {
    const char* value = std::getenv(name);
    return value != nullptr && std::strcmp(value, "0") != 0;
}

std::uint64_t input_seed() {
    const char* text = std::getenv("MXFP8_RANDOM_SEED");
    if (text == nullptr) return 20260909ull;
    char* end = nullptr;
    errno = 0;
    const unsigned long long seed = std::strtoull(text, &end, 0);
    if (errno != 0 || end == text || *end != '\0' || *text < '0' || *text > '9') {
        std::fprintf(stderr, "Invalid MXFP8_RANDOM_SEED: expected an unsigned integer.\n");
        std::exit(2);
    }
    return static_cast<std::uint64_t>(seed);
}

int integer_argument(const char* text) {
    char* end = nullptr;
    errno = 0;
    const long value = std::strtol(text, &end, 10);
    if (errno != 0 || end == text || *end != '\0' || value < INT_MIN || value > INT_MAX) {
        std::fprintf(stderr, "Invalid integer argument: %s\n", text);
        std::exit(2);
    }
    return static_cast<int>(value);
}

std::uint64_t input_word(std::uint64_t seed, std::uint64_t stream, std::size_t index) {
    std::uint64_t value = seed ^ (stream * 0xd2b74407b1ce6e93ull)
                              ^ static_cast<std::uint64_t>(index);
    value += 0x9e3779b97f4a7c15ull;
    value = (value ^ (value >> 30)) * 0xbf58476d1ce4e5b9ull;
    value = (value ^ (value >> 27)) * 0x94d049bb133111ebull;
    return value ^ (value >> 31);
}

template<typename T>
void rand_vector(T* ptr, std::size_t size, fp32_t min_val, fp32_t max_val,
                 std::uint64_t seed, std::uint64_t stream) {
    #pragma omp parallel for
    for (std::size_t i = 0; i < size; ++i) {
        const fp32_t unit = static_cast<fp32_t>(input_word(seed, stream, i) >> 40)
                           * 0x1p-24f;
        ptr[i] = static_cast<T>(min_val + (max_val - min_val) * unit);
    }
}

void rand_scale_e8m0(e8m0_t* ptr, std::size_t size,
                     std::uint64_t seed, std::uint64_t stream,
                     int lo = 124, int hi = 130) {
    #pragma omp parallel for
    for (std::size_t i = 0; i < size; ++i) {
        ptr[i] = static_cast<e8m0_t>(lo + input_word(seed, stream, i) % (hi - lo + 1));
    }
}

std::uint32_t fp32_bits(fp32_t value) {
    std::uint32_t bits;
    static_assert(sizeof(bits) == sizeof(value));
    std::memcpy(&bits, &value, sizeof(bits));
    return bits;
}

// Integer exponent checks remain valid when this host is built with -ffast-math.
bool finite_fp32(fp32_t value) {
    return (fp32_bits(value) & 0x7f800000u) != 0x7f800000u;
}

bool print_output_hash(const fp32_t* output, std::size_t count) {
    std::uint64_t hash = 1469598103934665603ull;
    std::size_t nonfinite = 0;
    for (std::size_t i = 0; i < count; ++i) {
        const std::uint32_t bits = fp32_bits(output[i]);
        hash ^= bits;
        hash *= 1099511628211ull;
        nonfinite += (bits & 0x7f800000u) == 0x7f800000u;
    }
    std::printf("Output bit hash: %016llx (%zu fp32 values)\n",
                static_cast<unsigned long long>(hash), count);
    std::printf("Output finite check: nonfinite=%zu\n", nonfinite);
    return nonfinite == 0;
}

void print_device_identity() {
    int device = -1;
    CHECK_HIP(hipGetDevice(&device));
    hipDeviceProp_t properties{};
    CHECK_HIP(hipGetDeviceProperties(&properties, device));
    char pci[32]{};
    CHECK_HIP(hipDeviceGetPCIBusId(pci, sizeof(pci), device));
    std::printf("Device identity: hip_device=%d pci=%s arch=%s cu=%d warp=%d name=\"%s\"\n",
                device, pci, properties.gcnArchName, properties.multiProcessorCount,
                properties.warpSize, properties.name);
}

template<typename T>
bool valid_vector(const T* ref, const T* result, const double* mag, int n,
                  fp32_t rel_mag = 5e-5f, fp32_t abs_floor = 1e-4f) {
    int errors = 0;
    int max_idx = -1;
    int max_ratio_idx = -1;
    fp32_t max_diff = 0.0f;
    fp32_t max_tol = 0.0f;
    fp32_t max_ratio = 0.0f;
    for (int i = 0; i < n; ++i) {
        const fp32_t r = static_cast<fp32_t>(ref[i]);
        const fp32_t got = static_cast<fp32_t>(result[i]);
        if (!finite_fp32(r) || !finite_fp32(got)) {
            if (errors < 10) std::printf("Error at %d: non-finite reference/result.\n", i);
            ++errors;
            continue;
        }
        const fp32_t diff = std::abs(r - got);
        const fp32_t tol = abs_floor + rel_mag * static_cast<fp32_t>(mag[i]);
        const fp32_t ratio = diff / tol;
        if (diff > max_diff) {
            max_diff = diff;
            max_tol = tol;
            max_idx = i;
        }
        if (ratio > max_ratio) {
            max_ratio = ratio;
            max_ratio_idx = i;
        }
        if (diff > tol) {
            if (errors < 10) {
                std::printf("Error at %d: ref=%.6f, result=%.6f, diff=%.6f, tol=%.6f (sum_abs_term=%.2f)\n",
                            i, r, got, diff, tol, mag[i]);
            }
            ++errors;
        }
    }
    if (max_idx >= 0) {
        std::printf("Validation stats: rel_mag=%.2e, abs_floor=%.2e, errors=%d/%d, max_diff=%.6f at %d (tol=%.6f, ref=%.6f, result=%.6f), max_ratio=%.3f at %d\n",
                    rel_mag, abs_floor, errors, n, max_diff, max_idx, max_tol,
                    static_cast<fp32_t>(ref[max_idx]), static_cast<fp32_t>(result[max_idx]),
                    max_ratio, max_ratio_idx);
    }
    return errors == 0;
}

// CPU reference MXFP8 GEMM: fp8 inputs, fp32 output, per-32-K E8M0 scales per row.
// SFA: [M, num_groups_k], SFB: [N, num_groups_k]. Accumulate in double and
// emit sum(abs(term)) per element for a condition-aware fp32 validation bound.
void gemm_ref(const host_fp8_t* a, const host_fp8_t* b, const e8m0_t* sfa, const e8m0_t* sfb, fp32_t* c,
              double* mag, int m, int n, int k, int lda, int ldb, int ldc, int stride_sfa, int stride_sfb,
              int group_k) {
    #pragma omp parallel for collapse(2)
    for (int i = 0; i < m; ++i) {
        for (int j = 0; j < n; ++j) {
            const host_fp8_t* a_row = a + i * lda;
            const host_fp8_t* b_row = b + j * ldb;
            const e8m0_t* sfa_row = sfa + i * stride_sfa;
            const e8m0_t* sfb_row = sfb + j * stride_sfb;
            double sum = 0.0;
            double sum_abs_term = 0.0;
            for (int k_group_idx = 0; k_group_idx < k / group_k; ++k_group_idx) {
                const double scale = static_cast<double>(e8m0_to_f32(sfa_row[k_group_idx]))
                                   * static_cast<double>(e8m0_to_f32(sfb_row[k_group_idx]));
                const int p_begin = k_group_idx * group_k;
                const int p_end = p_begin + group_k;
                for (int p = p_begin; p < p_end; ++p) {
                    const double term = static_cast<double>(static_cast<fp32_t>(a_row[p]))
                                      * static_cast<double>(static_cast<fp32_t>(b_row[p]))
                                      * scale;
                    sum += term;
                    sum_abs_term += std::abs(term);
                }
            }
            c[i * ldc + j] = static_cast<fp32_t>(sum);
            mag[i * ldc + j] = sum_abs_term;
        }
    }
}

template<class Traits>
void benchmark_kernel(
    const opus_gemm_scale_kargs& kargs,
    dim3 grid,
    dim3 block,
    int warmup,
    int iterations) {
    for (int i = 0; i < warmup; ++i) {
        MXFP8_SCALE_KERNEL<Traits><<<grid, block>>>(kargs);
        CHECK_HIP_KERNEL_LAUNCH();
    }

    hipEvent_t start;
    hipEvent_t stop;
    CHECK_HIP(hipEventCreate(&start));
    CHECK_HIP(hipEventCreate(&stop));

    CHECK_HIP(hipDeviceSynchronize());
    CHECK_HIP(hipEventRecord(start));

    for (int i = 0; i < iterations; ++i) {
        MXFP8_SCALE_KERNEL<Traits><<<grid, block>>>(kargs);
        CHECK_HIP_KERNEL_LAUNCH();
    }

    CHECK_HIP(hipEventRecord(stop));
    CHECK_HIP(hipEventSynchronize(stop));

    fp32_t total_time = 0.0f;
    CHECK_HIP(hipEventElapsedTime(&total_time, start, stop));

    CHECK_HIP(hipEventDestroy(start));
    CHECK_HIP(hipEventDestroy(stop));

    const fp32_t avg_time = total_time / iterations;
    const std::size_t flop = static_cast<std::size_t>(2) * kargs.m * kargs.n * kargs.k * kargs.batch;
    const fp32_t tflops = static_cast<fp32_t>(flop) / 1.0e9f / avg_time;

    std::printf("Kernel Performance: avg_time=%.9f ms, %.6f TFlops\n", avg_time, tflops);
}

template<class Traits>
void benchmark_kernel_timeline(
    const opus_gemm_scale_kargs& kargs,
    dim3 grid,
    dim3 block) {
    // Record all boundaries in one uninterrupted stream. There is deliberately
    // no warmup and no host-side synchronization between ranges.
    constexpr int range_ends[] = {25, 50, 100, 200, 500, 1000};
    constexpr int num_ranges = sizeof(range_ends) / sizeof(range_ends[0]);
    hipEvent_t marks[num_ranges + 1];
    for (int i = 0; i <= num_ranges; ++i) {
        CHECK_HIP(hipEventCreate(&marks[i]));
    }

    CHECK_HIP(hipDeviceSynchronize());
    const auto host_start = std::chrono::steady_clock::now();
    CHECK_HIP(hipEventRecord(marks[0]));

    int launched = 0;
    for (int range = 0; range < num_ranges; ++range) {
        while (launched < range_ends[range]) {
            MXFP8_SCALE_KERNEL<Traits><<<grid, block>>>(kargs);
            CHECK_HIP_KERNEL_LAUNCH();
            ++launched;
        }
        CHECK_HIP(hipEventRecord(marks[range + 1]));
    }

    CHECK_HIP(hipEventSynchronize(marks[num_ranges]));
    const auto host_end = std::chrono::steady_clock::now();
    const auto host_start_ns = std::chrono::duration_cast<std::chrono::nanoseconds>(
        host_start.time_since_epoch()).count();
    const auto host_end_ns = std::chrono::duration_cast<std::chrono::nanoseconds>(
        host_end.time_since_epoch()).count();

    const std::size_t flop =
        static_cast<std::size_t>(2) * kargs.m * kargs.n * kargs.k * kargs.batch;
    int range_begin = 1;
    fp32_t cumulative_time = 0.0f;
    std::printf("Timeline: warmup=0, consecutive_kernels=%d, host_start_ns=%lld, host_end_ns=%lld\n",
                range_ends[num_ranges - 1],
                static_cast<long long>(host_start_ns),
                static_cast<long long>(host_end_ns));
    for (int range = 0; range < num_ranges; ++range) {
        fp32_t range_time = 0.0f;
        CHECK_HIP(hipEventElapsedTime(&range_time, marks[range], marks[range + 1]));
        const int range_iterations = range_ends[range] - range_begin + 1;
        const fp32_t avg_time = range_time / range_iterations;
        const fp32_t tflops = static_cast<fp32_t>(flop) / 1.0e9f / avg_time;
        cumulative_time += range_time;
        std::printf(
            "Timeline kernels %d-%d: total=%.4f ms, avg=%.4f ms, %.2f TFlops (%.4f PFlop/s), cumulative=%.4f ms\n",
            range_begin,
            range_ends[range],
            range_time,
            avg_time,
            tflops,
            tflops / 1000.0f,
            cumulative_time);
        range_begin = range_ends[range] + 1;
    }

    for (int i = 0; i <= num_ranges; ++i) {
        CHECK_HIP(hipEventDestroy(marks[i]));
    }
}

int main(int argc, char** argv) {
    constexpr int BLOCK_M = GemmTraits::B_M;
    constexpr int BLOCK_N = GemmTraits::B_N;
    constexpr int BLOCK_K = GemmTraits::B_K;
    constexpr int BLOCK_SIZE = GemmTraits::BLOCK_SIZE;

    int M = 256;
    int N = 512;
    int K = 8192;
    int batch = 1;
    int verify = 0;
    int warmup = 200;
    int iterations = 100;
    int timeline = 0;
    bool device_info_only = false;
    const bool output_hash = env_flag("MXFP8_OUTPUT_HASH");

    auto parse_val = [](const char* arg, const char* flag) -> const char* {
        const std::size_t len = std::strlen(flag);
        if (std::strncmp(arg, flag, len) == 0) {
            if (arg[len] == '=') {
                return arg + len + 1;
            }
            if (arg[len] == '\0') {
                return reinterpret_cast<const char*>(1);
            }
        }
        return nullptr;
    };
    for (int i = 1; i < argc; ++i) {
        const char* arg = argv[i];
        const char* val = nullptr;
        auto try_parse = [&](int& target, const char* short_flag, const char* long_flag) {
            if ((val = parse_val(arg, short_flag)) || (long_flag && (val = parse_val(arg, long_flag)))) {
                if (val == reinterpret_cast<const char*>(1)) {
                    if (i + 1 >= argc) {
                        std::fprintf(stderr, "Missing value for %s\n", arg);
                        std::exit(2);
                    }
                    target = integer_argument(argv[++i]);
                } else {
                    target = integer_argument(val);
                }
                return true;
            }
            return false;
        };
        if (try_parse(M, "-m", "--m")) continue;
        if (try_parse(N, "-n", "--n")) continue;
        if (try_parse(K, "-k", "--k")) continue;
        if (try_parse(batch, "-b", "--b")) continue;
        if (try_parse(verify, "-v", "--verify")) continue;
        if (try_parse(warmup, "-w", "--warmup")) continue;
        if (try_parse(iterations, "-i", "--iterations")) continue;
        if (std::strcmp(arg, "--timeline") == 0) {
            timeline = 1;
            continue;
        }
        if (std::strcmp(arg, "--device-info") == 0) {
            device_info_only = true;
            continue;
        }
        std::fprintf(stderr, "Unknown argument: %s\n", arg);
        return 2;
    }
    if (device_info_only) {
        // Identity-only probe: no allocation, kernel launch or benchmark.
        print_device_identity();
        return 0;
    }

    if (M <= 0 || N <= 0 || K <= 0 || batch <= 0 || warmup < 0 || iterations <= 0) {
        std::cerr << "Invalid arguments: M/N/K/batch/iterations must be positive and warmup must be non-negative.\n";
        return 1;
    }
    if (timeline && (verify || output_hash)) {
        std::cerr << "--timeline requires --verify 0 and no MXFP8_OUTPUT_HASH.\n";
        return 1;
    }

    constexpr int GROUP_K = GemmTraits::GROUP_K;
    if (M % BLOCK_M != 0 || N % BLOCK_N != 0 || K % BLOCK_K != 0) {
        std::cerr << "M/N/K must be multiples of BLOCK_M/BLOCK_N/BLOCK_K ("
                  << BLOCK_M << "," << BLOCK_N << "," << BLOCK_K << ").\n";
        return 1;
    }
    if (K % GROUP_K != 0) {
        std::cerr << "K must be a multiple of GROUP_K (" << GROUP_K << ").\n";
        return 1;
    }
    if (K != 8192) {
        std::cerr << "This exact-K64 kernel requires K=8192.\n";
        return 1;
    }

    if (verify != 0 && verify != 1) {
        std::fprintf(stderr, "--verify must be 0 or 1.\n");
        return 2;
    }
    const std::uint64_t seed = input_seed();
    print_device_identity();
    std::printf("Input generator: splitmix64-index-v1 seed=%llu\n",
                static_cast<unsigned long long>(seed));

    const int num_groups_k = K / GROUP_K;
    const int num_tiles_m = M / BLOCK_M;
    const int num_tiles_n = N / BLOCK_N;

    auto host_a = std::make_unique<host_fp8_t[]>(static_cast<std::size_t>(batch) * M * K);
    auto host_b = std::make_unique<host_fp8_t[]>(static_cast<std::size_t>(batch) * N * K);
    std::unique_ptr<fp32_t[]> host_c;
    std::unique_ptr<fp32_t[]> host_c_out;
    std::unique_ptr<double[]> host_c_mag;
    if (verify) {
        host_c = std::make_unique<fp32_t[]>(static_cast<std::size_t>(batch) * M * N);
        host_c_mag = std::make_unique<double[]>(static_cast<std::size_t>(M) * N);
    }
    const std::size_t output_count = static_cast<std::size_t>(batch) * M * N;
    if (verify || output_hash) {
        host_c_out = std::make_unique<fp32_t[]>(output_count);
    }

    const std::size_t sfa_count = static_cast<std::size_t>(batch) * M * num_groups_k;
    const std::size_t sfb_count = static_cast<std::size_t>(batch) * N * num_groups_k;
    auto host_sfa = std::make_unique<e8m0_t[]>(sfa_count);
    auto host_sfb = std::make_unique<e8m0_t[]>(sfb_count);

    rand_vector(host_a.get(), static_cast<std::size_t>(batch) * M * K, 0.0f, 1.0f, seed, 1);
    rand_vector(host_b.get(), static_cast<std::size_t>(batch) * N * K, -0.5f, 0.5f, seed, 2);
    rand_scale_e8m0(host_sfa.get(), sfa_count, seed, 3);
    rand_scale_e8m0(host_sfb.get(), sfb_count, seed, 4);
    if (const char* u = std::getenv("MXFP8_UNIT_SCALE")) {
        if (std::atoi(u)) {
            std::fill_n(host_sfa.get(), sfa_count, static_cast<e8m0_t>(127));
            std::fill_n(host_sfb.get(), sfb_count, static_cast<e8m0_t>(127));
        }
    }
    if (const char* sfa_value = std::getenv("MXFP8_SFA_VALUE")) {
        std::fill_n(host_sfa.get(), sfa_count, static_cast<e8m0_t>(std::atoi(sfa_value)));
    }
    if (const char* sfb_value = std::getenv("MXFP8_SFB_VALUE")) {
        std::fill_n(host_sfb.get(), sfb_count, static_cast<e8m0_t>(std::atoi(sfb_value)));
    }
    if (std::getenv("MXFP8_SFA_ROW_PATTERN")) {
        for (int b = 0; b < batch; ++b) {
            for (int i = 0; i < M; ++i) {
                const e8m0_t value = static_cast<e8m0_t>(124 + (i % 7));
                std::fill_n(host_sfa.get() + static_cast<std::size_t>(b) * M * num_groups_k + i * num_groups_k,
                            num_groups_k, value);
            }
        }
    }
    if (std::getenv("MXFP8_SFA_K_PATTERN")) {
        for (int b = 0; b < batch; ++b) {
            for (int i = 0; i < M; ++i) {
                for (int g = 0; g < num_groups_k; ++g) {
                    host_sfa[static_cast<std::size_t>(b) * M * num_groups_k + i * num_groups_k + g] =
                        static_cast<e8m0_t>(124 + (g % 7));
                }
            }
        }
    }
    if (std::getenv("MXFP8_SFB_ROW_PATTERN")) {
        for (int b = 0; b < batch; ++b) {
            for (int j = 0; j < N; ++j) {
                const e8m0_t value = static_cast<e8m0_t>(124 + (j % 7));
                std::fill_n(host_sfb.get() + static_cast<std::size_t>(b) * N * num_groups_k + j * num_groups_k,
                            num_groups_k, value);
            }
        }
    }
    if (std::getenv("MXFP8_SFB_K_PATTERN")) {
        for (int b = 0; b < batch; ++b) {
            for (int j = 0; j < N; ++j) {
                for (int g = 0; g < num_groups_k; ++g) {
                    host_sfb[static_cast<std::size_t>(b) * N * num_groups_k + j * num_groups_k + g] =
                        static_cast<e8m0_t>(124 + (g % 7));
                }
            }
        }
    }

    void* dev_a = nullptr;
    void* dev_b = nullptr;
    void* dev_sfa = nullptr;
    void* dev_sfb = nullptr;
    fp32_t* dev_c = nullptr;
    CHECK_HIP(hipMalloc(&dev_a, static_cast<std::size_t>(batch) * M * K * sizeof(host_fp8_t)));
    CHECK_HIP(hipMalloc(&dev_b, static_cast<std::size_t>(batch) * N * K * sizeof(host_fp8_t)));
    CHECK_HIP(hipMalloc(&dev_c, static_cast<std::size_t>(batch) * M * N * sizeof(fp32_t)));
    CHECK_HIP(hipMalloc(&dev_sfa, sfa_count * sizeof(e8m0_t)));
    CHECK_HIP(hipMalloc(&dev_sfb, sfb_count * sizeof(e8m0_t)));

    CHECK_HIP(hipMemcpy(dev_a, host_a.get(), static_cast<std::size_t>(batch) * M * K * sizeof(host_fp8_t), hipMemcpyHostToDevice));
    CHECK_HIP(hipMemcpy(dev_b, host_b.get(), static_cast<std::size_t>(batch) * N * K * sizeof(host_fp8_t), hipMemcpyHostToDevice));
    CHECK_HIP(hipMemcpy(dev_sfa, host_sfa.get(), sfa_count * sizeof(e8m0_t), hipMemcpyHostToDevice));
    CHECK_HIP(hipMemcpy(dev_sfb, host_sfb.get(), sfb_count * sizeof(e8m0_t), hipMemcpyHostToDevice));

    opus_gemm_scale_kargs kargs{};
    kargs.ptr_a = dev_a;
    kargs.ptr_b = dev_b;
    kargs.ptr_c = dev_c;
    kargs.m = M;
    kargs.n = N;
    kargs.k = K;
    kargs.batch = batch;
    kargs.stride_a = K;
    kargs.stride_b = K;
    kargs.stride_c = N;
    kargs.stride_a_batch = M * K;
    kargs.stride_b_batch = N * K;
    kargs.stride_c_batch = M * N;
    kargs.ptr_sfa = dev_sfa;
    kargs.ptr_sfb = dev_sfb;
    kargs.stride_sfa = num_groups_k;
    kargs.stride_sfb = num_groups_k;
    kargs.stride_sfa_batch = M * num_groups_k;
    kargs.stride_sfb_batch = N * num_groups_k;

    const int m_tile_groups =
        ceil_div_scale(num_tiles_m, FIXED_B_PREFETCH_OUTPUT_TILES_PER_WG);
    dim3 grid(m_tile_groups * num_tiles_n, 1, batch);
    dim3 block(BLOCK_SIZE);

    std::printf("Launching MXFP8 scaled-MFMA GEMM %s: M=%d, N=%d, K=%d, grid=(%u,%u,%u), block=%d, output_tiles_per_wg=%d\n",
                MXFP8_SCALE_VARIANT_NAME, M, N, K, grid.x, grid.y, grid.z, BLOCK_SIZE,
                FIXED_B_PREFETCH_OUTPUT_TILES_PER_WG);

    bool all_valid = true;
    if (verify || output_hash) {
        // Correctness-only launch; the default timed path never enters here.
        // Hash mode covers every output on the CPU and skips all timed launches.
        MXFP8_SCALE_KERNEL<GemmTraits><<<grid, block>>>(kargs);
        CHECK_HIP_KERNEL_LAUNCH();
        CHECK_HIP(hipMemcpy(host_c_out.get(), dev_c, output_count * sizeof(fp32_t),
                            hipMemcpyDeviceToHost));
        if (output_hash) all_valid = print_output_hash(host_c_out.get(), output_count);
    }
    if (verify) {
        std::printf("\nValidating GPU results against CPU reference...\n");
        for (int b = 0; b < batch; ++b) {
            gemm_ref(host_a.get() + static_cast<std::size_t>(b) * M * K,
                     host_b.get() + static_cast<std::size_t>(b) * N * K,
                     host_sfa.get() + static_cast<std::size_t>(b) * M * num_groups_k,
                     host_sfb.get() + static_cast<std::size_t>(b) * N * num_groups_k,
                     host_c.get() + static_cast<std::size_t>(b) * M * N,
                     host_c_mag.get(),
                     M, N, K, K, K, N, num_groups_k, num_groups_k, GROUP_K);
            const bool valid = valid_vector(host_c.get() + static_cast<std::size_t>(b) * M * N,
                                            host_c_out.get() + static_cast<std::size_t>(b) * M * N,
                                            host_c_mag.get(), M * N);
            std::printf("[GEMM batch %d/%d: %dx%dx%d, block_%dx%dx%d] %s\n",
                        b + 1, batch, M, N, K, BLOCK_M, BLOCK_N, BLOCK_K, valid ? "VALID" : "FAIL");
            all_valid = all_valid && valid;
        }

        std::printf("\n[Overall] %s\n", all_valid ? "ALL BATCHES VALID" : "SOME BATCHES FAILED");
    }

    if (all_valid && !output_hash) {
        std::printf("\n");
        if (timeline) {
            benchmark_kernel_timeline<GemmTraits>(kargs, grid, block);
        } else {
            benchmark_kernel<GemmTraits>(kargs, grid, block, warmup, iterations);
        }
        std::printf("\n");
    }

    CHECK_HIP(hipFree(dev_a));
    CHECK_HIP(hipFree(dev_b));
    CHECK_HIP(hipFree(dev_c));
    CHECK_HIP(hipFree(dev_sfa));
    CHECK_HIP(hipFree(dev_sfb));

    return all_valid ? 0 : 1;
}
