// Standalone host launcher for the logical row-major scale ABI.  The 8-wave
// kernel performs the scale transpose from VGPRs into LDS.

#include "gemm_a8w8_mxfp8_scale_common.h"

#ifndef MXFP8_PACK_READY_COUNT
#define MXFP8_PACK_READY_COUNT 256
#endif

#define MXFP8_SCALE_KERNEL \
    gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernel
#define MXFP8_SCALE_TRAITS \
    gemm_a8w8_mxfp8_scale_traits<>
#ifndef MXFP8_SCALE_OUTPUT_TILES_PER_WG
#define MXFP8_SCALE_OUTPUT_TILES_PER_WG 1
#endif
#if defined(MXFP8_GPU_SCALE_PACK)
#define MXFP8_SCALE_VARIANT_NAME \
    "8W packed240 with timed GPU row-major scale pack, 256x256x128"
#else
#define MXFP8_SCALE_VARIANT_NAME \
    "8W local raw-scale direct, 256x256x128, unified scale"
#endif

#include <hip/hip_fp8.h>
#include <opus/hip_minimal.hpp>
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <memory>
#include <random>
#include <omp.h>

#include "gemm_a8w8_mxfp8_scale_common.h"

#ifndef MXFP8_SCALE_KERNEL
#define MXFP8_SCALE_KERNEL gemm_a8w8_mxfp8_scale_kernel
#endif

#ifndef MXFP8_SCALE_TRAITS
#define MXFP8_SCALE_TRAITS gemm_a8w8_mxfp8_scale_traits<>
#endif

#ifndef MXFP8_SCALE_VARIANT_NAME
#define MXFP8_SCALE_VARIANT_NAME "8W local raw-scale direct, 256x256x128"
#endif

template<class Traits>
__global__ void MXFP8_SCALE_KERNEL(opus_gemm_scale_kargs kargs);

#if defined(MXFP8_FUSED_VALIDATE_REFERENCE)
template<class Traits>
__global__ void MXFP8_SCALE_REFERENCE_KERNEL(opus_gemm_scale_kargs kargs);

__global__ void mxfp8_compare_f32_bits(
    const std::uint32_t* lhs,
    const std::uint32_t* rhs,
    std::size_t count,
    unsigned long long* mismatches) {
    const std::size_t first =
        static_cast<std::size_t>(__builtin_amdgcn_workgroup_id_x()) * 256
        + __builtin_amdgcn_workitem_id_x();
    const std::size_t stride =
        static_cast<std::size_t>(256) * 256;
    unsigned long long local = 0;
    for (std::size_t i = first; i < count; i += stride) {
        local += lhs[i] != rhs[i];
    }
    if (local != 0) {
        __atomic_fetch_add(mismatches, local, __ATOMIC_RELAXED);
    }
}
#endif

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
#ifndef MXFP8_SCALE_OUTPUT_TILES_PER_WG
#define MXFP8_SCALE_OUTPUT_TILES_PER_WG 1
#endif
static constexpr int FIXED_B_PREFETCH_OUTPUT_TILES_PER_WG =
    MXFP8_SCALE_OUTPUT_TILES_PER_WG;
using host_fp8_t = __hip_fp8_e4m3;
using fp32_t = float;
using e8m0_t = uint8_t;

#if defined(MXFP8_GPU_SCALE_PACK)
#if defined(MXFP8_GPU_SCALE_PACK_COALESCED64)
#ifndef MXFP8_GPU_SCALE_PACK_WAVES_PER_BLOCK
#define MXFP8_GPU_SCALE_PACK_WAVES_PER_BLOCK 4
#endif
// Four adjacent lanes load one complete 64-byte row segment.  Each wave owns
// 16 packed destination slots and already holds all four source rows needed
// for those slots, so the byte transpose can stay entirely in VGPRs.  This
// preserves coalesced input reads without paying for LDS or a workgroup
// barrier.
__device__ inline uint4 transpose_scale_4x4x4(
    const uint4& row0,
    const uint4& row1,
    const uint4& row2,
    const uint4& row3,
    int tile_in_vector) {
    const uint32_t r0 = reinterpret_cast<const uint32_t*>(&row0)[tile_in_vector];
    const uint32_t r1 = reinterpret_cast<const uint32_t*>(&row1)[tile_in_vector];
    const uint32_t r2 = reinterpret_cast<const uint32_t*>(&row2)[tile_in_vector];
    const uint32_t r3 = reinterpret_cast<const uint32_t*>(&row3)[tile_in_vector];
    uint4 out;
    uint32_t* words = reinterpret_cast<uint32_t*>(&out);
#if defined(MXFP8_GPU_SCALE_PACK_PERM8)
    const uint32_t t0 = __builtin_amdgcn_perm(r1, r0, 0x05010400u);
    const uint32_t t1 = __builtin_amdgcn_perm(r1, r0, 0x07030602u);
    const uint32_t t2 = __builtin_amdgcn_perm(r3, r2, 0x05010400u);
    const uint32_t t3 = __builtin_amdgcn_perm(r3, r2, 0x07030602u);
    words[0] = __builtin_amdgcn_perm(t2, t0, 0x05040100u);
    words[1] = __builtin_amdgcn_perm(t2, t0, 0x07060302u);
    words[2] = __builtin_amdgcn_perm(t3, t1, 0x05040100u);
    words[3] = __builtin_amdgcn_perm(t3, t1, 0x07060302u);
#else
    words[0] = (r0 & 0x000000ffu) |
               ((r1 & 0x000000ffu) << 8) |
               ((r2 & 0x000000ffu) << 16) |
               ((r3 & 0x000000ffu) << 24);
    words[1] = ((r0 >> 8) & 0x000000ffu) |
               (r1 & 0x0000ff00u) |
               ((r2 & 0x0000ff00u) << 8) |
               ((r3 & 0x0000ff00u) << 16);
    words[2] = ((r0 >> 16) & 0x000000ffu) |
               ((r1 >> 8) & 0x0000ff00u) |
               (r2 & 0x00ff0000u) |
               ((r3 & 0x00ff0000u) << 8);
    words[3] = ((r0 >> 24) & 0x000000ffu) |
               ((r1 >> 16) & 0x0000ff00u) |
               ((r2 >> 8) & 0x00ff0000u) |
               (r3 & 0xff000000u);
#endif
    return out;
}

__global__ __launch_bounds__(256)
void pack_row_major_scales_gpu(
    const e8m0_t* raw_sfa,
    const e8m0_t* raw_sfb,
    e8m0_t* packed_sfa,
    e8m0_t* packed_sfb,
    int,
    int,
    int,
    int) {
    constexpr int groups_k = 256;
    constexpr int packed_tile_bytes = 1024;
    constexpr int k_chunks = 4;
    constexpr int tiles_per_vector = 4;
    constexpr int tiles_per_chunk = 16;
    constexpr int tiles_mn = 32;
    constexpr int waves_per_block = MXFP8_GPU_SCALE_PACK_WAVES_PER_BLOCK;
    constexpr int wave_groups = 4 / waves_per_block;
    constexpr int sfa_blocks = tiles_mn * k_chunks * wave_groups;
    static_assert(
        waves_per_block == 1 || waves_per_block == 2 || waves_per_block == 4,
        "coalesced64 pack supports 1, 2, or 4 waves per block");

    const int bid = static_cast<int>(__builtin_amdgcn_workgroup_id_x());
    const int tid = static_cast<int>(__builtin_amdgcn_workitem_id_x());
    const bool is_sfb = bid >= sfa_blocks;
    const int local_bid = is_sfb ? bid - sfa_blocks : bid;
    const int wave_group = local_bid & (wave_groups - 1);
    const int tile_chunk = local_bid / wave_groups;
    const int k_chunk = tile_chunk & (k_chunks - 1);
    const int tile_mn = tile_chunk >> 2;
    const int wave = wave_group * waves_per_block + (tid >> 6);
    const int lane = tid & 63;
    const int local_row = lane >> 2;
    const int vector_in_row = lane & 3;
    const int slot = (wave << 4) + local_row;
    const int row0 = is_sfb
        ? ((wave >> 1) << 7) + ((wave & 1) << 4) + local_row
        : (wave << 4) + local_row;
    const int row_step = is_sfb ? 32 : 64;
    const int source_col = (k_chunk << 6) + (vector_in_row << 4);
    const e8m0_t* src = is_sfb ? raw_sfb : raw_sfa;
    e8m0_t* dst = is_sfb ? packed_sfb : packed_sfa;
    const auto* src0 = reinterpret_cast<const uint4*>(
        src + static_cast<std::size_t>((tile_mn << 8) + row0) * groups_k +
        source_col);
    const auto* src1 = reinterpret_cast<const uint4*>(
        src + static_cast<std::size_t>((tile_mn << 8) + row0 + row_step) *
                  groups_k +
        source_col);
    const auto* src2 = reinterpret_cast<const uint4*>(
        src + static_cast<std::size_t>((tile_mn << 8) + row0 + 2 * row_step) *
                  groups_k +
        source_col);
    const auto* src3 = reinterpret_cast<const uint4*>(
        src + static_cast<std::size_t>((tile_mn << 8) + row0 + 3 * row_step) *
                  groups_k +
        source_col);
    const uint4 v0 = *src0;
    const uint4 v1 = *src1;
    const uint4 v2 = *src2;
    const uint4 v3 = *src3;

#pragma unroll
    for (int tile_in_vector = 0; tile_in_vector < tiles_per_vector;
         ++tile_in_vector) {
        const int tile_k = k_chunk * tiles_per_chunk +
                           vector_in_row * tiles_per_vector + tile_in_vector;
        const std::size_t packed_tile =
            (static_cast<std::size_t>(tile_mn) * 64 + tile_k) *
            packed_tile_bytes;
        *reinterpret_cast<uint4*>(
            dst + packed_tile + slot * sizeof(uint4)) =
            transpose_scale_4x4x4(v0, v1, v2, v3, tile_in_vector);
    }
}
#elif defined(MXFP8_GPU_SCALE_PACK_TILED64) || \
    defined(MXFP8_GPU_SCALE_PACK_TILED32)
// Exact-8192 packer that amortizes each row transaction across adjacent
// K-group bytes.  Neighboring lanes load one complete row segment
// segment, then a padded LDS tile changes the ownership to the packed
// consumer order.  The extra dword in the LDS pitch avoids the severe bank
// conflict a natural power-of-two row pitch creates during column-wise reads.
__device__ inline uint4 transpose_scale_4x4_words(
    uint32_t r0,
    uint32_t r1,
    uint32_t r2,
    uint32_t r3) {
    uint4 out;
    uint32_t* words = reinterpret_cast<uint32_t*>(&out);
    words[0] = (r0 & 0x000000ffu) |
               ((r1 & 0x000000ffu) << 8) |
               ((r2 & 0x000000ffu) << 16) |
               ((r3 & 0x000000ffu) << 24);
    words[1] = ((r0 >> 8) & 0x000000ffu) |
               (r1 & 0x0000ff00u) |
               ((r2 & 0x0000ff00u) << 8) |
               ((r3 & 0x0000ff00u) << 16);
    words[2] = ((r0 >> 16) & 0x000000ffu) |
               ((r1 >> 8) & 0x0000ff00u) |
               (r2 & 0x00ff0000u) |
               ((r3 & 0x00ff0000u) << 8);
    words[3] = ((r0 >> 24) & 0x000000ffu) |
               ((r1 >> 16) & 0x0000ff00u) |
               ((r2 >> 8) & 0x00ff0000u) |
               (r3 & 0xff000000u);
    return out;
}

__global__ __launch_bounds__(256)
void pack_row_major_scales_gpu(
    const e8m0_t* raw_sfa,
    const e8m0_t* raw_sfb,
    e8m0_t* packed_sfa,
    e8m0_t* packed_sfb,
    int,
    int,
    int,
    int) {
    constexpr int groups_k = 256;
    constexpr int packed_tile_bytes = 1024;
#if defined(MXFP8_GPU_SCALE_PACK_TILED32)
    constexpr int chunk_bytes = 32;
    constexpr int k_chunks = 8;
    constexpr int vectors_per_row = 2;
    constexpr int tiles_per_chunk = 8;
    constexpr int block_threads = 128;
#else
    constexpr int chunk_bytes = 64;
    constexpr int k_chunks = 4;
    constexpr int vectors_per_row = 4;
    constexpr int tiles_per_chunk = 16;
    constexpr int block_threads = 256;
#endif
    constexpr int tiles_mn = 32;
    constexpr int sfa_blocks = tiles_mn * k_chunks;
    constexpr int lds_pitch_words = chunk_bytes / sizeof(uint32_t) + 1;

    __shared__ uint32_t lds_words[256][lds_pitch_words];

    const int bid = static_cast<int>(__builtin_amdgcn_workgroup_id_x());
    const int tid = static_cast<int>(__builtin_amdgcn_workitem_id_x());
    const bool is_sfb = bid >= sfa_blocks;
    const int local_bid = is_sfb ? bid - sfa_blocks : bid;
    const int k_chunk = local_bid & (k_chunks - 1);
    const int tile_mn = local_bid / k_chunks;
    const e8m0_t* src = is_sfb ? raw_sfb : raw_sfa;
    e8m0_t* dst = is_sfb ? packed_sfb : packed_sfa;

    // Neighboring lanes jointly cover all useful bytes in one row. Repeating
    // over four row bands fills the full 256x64 tile with coalesced loads.
    const int local_row = tid / vectors_per_row;
    const int vec_col = tid & (vectors_per_row - 1);
    const int source_col = k_chunk * chunk_bytes + (vec_col << 4);
#pragma unroll
    for (int row_band = 0; row_band < 4; ++row_band) {
        const int row = local_row + (row_band << 6);
        const int global_row = (tile_mn << 8) + row;
        const uint4 value = *reinterpret_cast<const uint4*>(
            src + static_cast<std::size_t>(global_row) * groups_k + source_col);
        const uint32_t* value_words = reinterpret_cast<const uint32_t*>(&value);
#pragma unroll
        for (int word = 0; word < 4; ++word) {
            lds_words[row][(vec_col << 2) + word] = value_words[word];
        }
    }
    __syncthreads();

    // Each iteration assigns a contiguous 1-KiB packed tile to one wave, so
    // destination stores remain fully coalesced.
#pragma unroll
    for (int output_group = 0; output_group < 4; ++output_group) {
        const int output_linear = tid + output_group * block_threads;
        const int tile_in_chunk = output_linear >> 6;
        const int slot = output_linear & 63;
        int row0;
        if (!is_sfb) {
            row0 = slot;
        } else {
            const int half_n = slot >> 5;
            const int wave_n = (slot >> 4) & 1;
            const int r = slot & 15;
            row0 = (half_n << 7) + (wave_n << 4) + r;
        }
        const int row_step = is_sfb ? 32 : 64;
        const uint32_t r0 = lds_words[row0][tile_in_chunk];
        const uint32_t r1 = lds_words[row0 + row_step][tile_in_chunk];
        const uint32_t r2 = lds_words[row0 + 2 * row_step][tile_in_chunk];
        const uint32_t r3 = lds_words[row0 + 3 * row_step][tile_in_chunk];
        const uint4 value = transpose_scale_4x4_words(r0, r1, r2, r3);
        const int tile_k = k_chunk * tiles_per_chunk + tile_in_chunk;
        const std::size_t packed_tile =
            (static_cast<std::size_t>(tile_mn) * 64 + tile_k) *
            packed_tile_bytes;
        *reinterpret_cast<uint4*>(
            dst + packed_tile + slot * sizeof(uint4)) = value;
    }
}
#else
// Convert four adjacent K128 tiles at once.  One 64-thread block owns four
// 1-KiB packed tiles; each lane owns one 16-byte destination row.  The four
// source rows are separated in M/N but each source access is a naturally
// aligned b128 covering four adjacent tile groups.  The timed benchmark calls
// this kernel before every GEMM launch, so the reported throughput is honest
// row-major-to-output end-to-end throughput rather than a cached prepack.
__device__ inline uint4 transpose_scale_4x4x4(
    const uint4& row0,
    const uint4& row1,
    const uint4& row2,
    const uint4& row3,
    int tile_in_group) {
    const uint32_t r0 = reinterpret_cast<const uint32_t*>(&row0)[tile_in_group];
    const uint32_t r1 = reinterpret_cast<const uint32_t*>(&row1)[tile_in_group];
    const uint32_t r2 = reinterpret_cast<const uint32_t*>(&row2)[tile_in_group];
    const uint32_t r3 = reinterpret_cast<const uint32_t*>(&row3)[tile_in_group];
    uint4 out;
    uint32_t* words = reinterpret_cast<uint32_t*>(&out);
    words[0] = (r0 & 0x000000ffu) |
               ((r1 & 0x000000ffu) << 8) |
               ((r2 & 0x000000ffu) << 16) |
               ((r3 & 0x000000ffu) << 24);
    words[1] = ((r0 >> 8) & 0x000000ffu) |
               (r1 & 0x0000ff00u) |
               ((r2 & 0x0000ff00u) << 8) |
               ((r3 & 0x0000ff00u) << 16);
    words[2] = ((r0 >> 16) & 0x000000ffu) |
               ((r1 >> 8) & 0x0000ff00u) |
               (r2 & 0x00ff0000u) |
               ((r3 & 0x00ff0000u) << 8);
    words[3] = ((r0 >> 24) & 0x000000ffu) |
               ((r1 >> 16) & 0x0000ff00u) |
               ((r2 >> 8) & 0x00ff0000u) |
               (r3 & 0xff000000u);
    return out;
}

__global__ __launch_bounds__(64)
void pack_row_major_scales_gpu(
    const e8m0_t* raw_sfa,
    const e8m0_t* raw_sfb,
    e8m0_t* packed_sfa,
    e8m0_t* packed_sfb,
    int m,
    int n,
    int k,
    int batch) {
    constexpr int block_mn = 256;
    constexpr int block_k = 128;
    constexpr int group_k = 32;
    constexpr int packed_tile_bytes = 1024;
    constexpr int k_tiles_per_block = 4;

    const int groups_k = k / group_k;
    const int tiles_k = k / block_k;
    const int tile_groups_k = tiles_k / k_tiles_per_block;
    const int tiles_m = m / block_mn;
    const int tiles_n = n / block_mn;
    const int bid = static_cast<int>(__builtin_amdgcn_workgroup_id_x());
    const int slot = static_cast<int>(__builtin_amdgcn_workitem_id_x());

    const e8m0_t* src;
    e8m0_t* dst;
    int tile_mn;
    int kt_group;
    int batch_id;
    int row0;
    int row1;
    int row2;
    int row3;
    int tile_count;

#if defined(MXFP8_GPU_SCALE_PACK_EXACT_8192)
    constexpr int exact_groups_k = 256;
    constexpr int exact_tiles_k = 64;
    constexpr int exact_tile_groups_k = 16;
    constexpr int exact_tiles_mn = 32;
    constexpr int exact_sfa_blocks = exact_tiles_mn * exact_tile_groups_k;
    if (bid < exact_sfa_blocks) {
        kt_group = bid & (exact_tile_groups_k - 1);
        tile_mn = bid >> 4;
        batch_id = 0;
        tile_count = exact_tiles_mn;
        const int row_base = (tile_mn << 8) + slot;
        row0 = row_base;
        row1 = row_base + 64;
        row2 = row_base + 128;
        row3 = row_base + 192;
        src = raw_sfa;
        dst = packed_sfa;
    } else {
        const int local = bid - exact_sfa_blocks;
        kt_group = local & (exact_tile_groups_k - 1);
        tile_mn = local >> 4;
        batch_id = 0;
        tile_count = exact_tiles_mn;
        const int half_n = slot >> 5;
        const int wave_n = (slot >> 4) & 1;
        const int r = slot & 15;
        const int row_base = (tile_mn << 8) + (half_n << 7) +
                             (wave_n << 4) + r;
        row0 = row_base;
        row1 = row_base + 32;
        row2 = row_base + 64;
        row3 = row_base + 96;
        src = raw_sfb;
        dst = packed_sfb;
    }
    const int source_col = kt_group << 4;
    const auto* src0 = reinterpret_cast<const uint4*>(
        src + (row0 << 8) + source_col);
    const auto* src1 = reinterpret_cast<const uint4*>(
        src + (row1 << 8) + source_col);
    const auto* src2 = reinterpret_cast<const uint4*>(
        src + (row2 << 8) + source_col);
    const auto* src3 = reinterpret_cast<const uint4*>(
        src + (row3 << 8) + source_col);
#else
    const int sfa_blocks = batch * tiles_m * tile_groups_k;
    if (bid < sfa_blocks) {
        const int local = bid;
        kt_group = local % tile_groups_k;
        const int tile_linear = local / tile_groups_k;
        tile_mn = tile_linear % tiles_m;
        batch_id = tile_linear / tiles_m;
        tile_count = tiles_m;
        const int row_base = tile_mn * block_mn + slot;
        row0 = row_base;
        row1 = row_base + 64;
        row2 = row_base + 128;
        row3 = row_base + 192;
        src = raw_sfa;
        dst = packed_sfa;
    } else {
        const int local = bid - sfa_blocks;
        kt_group = local % tile_groups_k;
        const int tile_linear = local / tile_groups_k;
        tile_mn = tile_linear % tiles_n;
        batch_id = tile_linear / tiles_n;
        tile_count = tiles_n;
        const int half_n = slot >> 5;
        const int wave_n = (slot >> 4) & 1;
        const int r = slot & 15;
        const int row_base = tile_mn * block_mn + half_n * 128 +
                             wave_n * 16 + r;
        row0 = row_base;
        row1 = row_base + 32;
        row2 = row_base + 64;
        row3 = row_base + 96;
        src = raw_sfb;
        dst = packed_sfb;
    }

    const int source_col = kt_group * k_tiles_per_block * 4;
    const std::size_t source_batch =
        static_cast<std::size_t>(batch_id) * tile_count * block_mn * groups_k;
    const auto* src0 = reinterpret_cast<const uint4*>(
        src + source_batch + static_cast<std::size_t>(row0) * groups_k +
        source_col);
    const auto* src1 = reinterpret_cast<const uint4*>(
        src + source_batch + static_cast<std::size_t>(row1) * groups_k +
        source_col);
    const auto* src2 = reinterpret_cast<const uint4*>(
        src + source_batch + static_cast<std::size_t>(row2) * groups_k +
        source_col);
    const auto* src3 = reinterpret_cast<const uint4*>(
        src + source_batch + static_cast<std::size_t>(row3) * groups_k +
        source_col);
#endif
    const uint4 v0 = *src0;
    const uint4 v1 = *src1;
    const uint4 v2 = *src2;
    const uint4 v3 = *src3;

#pragma unroll
    for (int tile = 0; tile < k_tiles_per_block; ++tile) {
        const std::size_t packed_tile =
#if defined(MXFP8_GPU_SCALE_PACK_EXACT_8192)
            (static_cast<std::size_t>(tile_mn) * exact_tiles_k +
             (kt_group << 2) + tile) * packed_tile_bytes;
#else
            (static_cast<std::size_t>(batch_id) * tile_count * tiles_k +
             static_cast<std::size_t>(tile_mn) * tiles_k +
             kt_group * k_tiles_per_block + tile) * packed_tile_bytes;
#endif
        auto* out = reinterpret_cast<uint4*>(
            dst + packed_tile + slot * sizeof(uint4));
        *out = transpose_scale_4x4x4(v0, v1, v2, v3, tile);
    }
}
#endif
#endif

// E8M0: 8-bit exponent-only scale, bias 127. value = 2^(byte - 127); 0x7F = 1.0.
inline fp32_t e8m0_to_f32(e8m0_t e) {
    return std::ldexp(1.0f, static_cast<int>(e) - 127);
}

inline e8m0_t f32_to_e8m0(fp32_t v) {
    if (v <= 0.0f) return 0;
    int exp;
    std::frexp(v, &exp);      // v in [0.5, 1) * 2^exp -> nearest power-of-two exponent
    int biased = (exp - 1) + 127;
    if (biased < 0) biased = 0;
    if (biased > 255) biased = 255;
    return static_cast<e8m0_t>(biased);
}

template<typename T>
void rand_vector(T* ptr, std::size_t size, fp32_t min_val = 0.0f, fp32_t max_val = 1.0f) {
    const char* seed_env = std::getenv("MXFP8_RANDOM_SEED");
    const unsigned int deterministic_seed =
        seed_env ? static_cast<unsigned int>(std::strtoul(seed_env, nullptr, 0)) : 0;
    #pragma omp parallel
    {
        std::random_device rd;
        std::mt19937 gen(seed_env
                            ? deterministic_seed
                                  + 0x9e3779b9u * omp_get_thread_num()
                            : rd() + omp_get_thread_num());
        std::uniform_real_distribution<fp32_t> dis(min_val, max_val);
        #pragma omp for
        for (std::size_t i = 0; i < size; ++i) {
            ptr[i] = static_cast<T>(dis(gen));
        }
    }
}

// Random E8M0 scales drawn as power-of-two exponents around 1.0 (byte in [lo, hi]).
void rand_scale_e8m0(e8m0_t* ptr, std::size_t size, int lo = 124, int hi = 130) {
    const char* seed_env = std::getenv("MXFP8_RANDOM_SEED");
    const unsigned int deterministic_seed =
        seed_env ? static_cast<unsigned int>(std::strtoul(seed_env, nullptr, 0)) : 0;
    #pragma omp parallel
    {
        std::random_device rd;
        std::mt19937 gen(seed_env
                            ? deterministic_seed + 0x85ebca6bu
                                  + 0x9e3779b9u * omp_get_thread_num()
                            : rd() + omp_get_thread_num());
        std::uniform_int_distribution<int> dis(lo, hi);
        #pragma omp for
        for (std::size_t i = 0; i < size; ++i) {
            ptr[i] = static_cast<e8m0_t>(dis(gen));
        }
    }
}

#if defined(MXFP8_PRESHUFFLE_B)
// Pack row-major B[batch][N][K] as B'[batch][K/BLOCK_K][N][BLOCK_K].
// Keeping the original host B allows validation to remain independent of the
// packed layout consumed by the GPU kernel.
void preshuffle_b_k_panels(
    const host_fp8_t* src,
    host_fp8_t* dst,
    int batch,
    int n,
    int k,
    int block_k) {
    const int num_k_tiles = k / block_k;
    #pragma omp parallel for collapse(2)
    for (int b = 0; b < batch; ++b) {
        for (int row = 0; row < n; ++row) {
            const host_fp8_t* src_row =
                src + static_cast<std::size_t>(b) * n * k
                    + static_cast<std::size_t>(row) * k;
            for (int tile_k = 0; tile_k < num_k_tiles; ++tile_k) {
                host_fp8_t* dst_row =
                    dst + static_cast<std::size_t>(b) * n * k
                        + (static_cast<std::size_t>(tile_k) * n + row) * block_k;
                std::copy_n(src_row + static_cast<std::size_t>(tile_k) * block_k,
                            block_k, dst_row);
            }
        }
    }
}
#endif

// Tile-major consumer order matching the LDS image:
// [consumer_wave_m][r][q][m_call]. The packed tile is a byte-for-byte image
// of the consumer-facing LDS tile.
template<class Traits>
void pack_sfa_consumer_major(
    const e8m0_t* src,
    e8m0_t* dst,
    int batch,
    int m,
    int k) {
    constexpr int scale_count = Traits::SCALE_KGROUPS_PER_MFMA;
    constexpr int tile_elems = Traits::packed_sfa_tile_elem;

    const int num_groups_k = k / Traits::GROUP_K;
    const int num_tiles_m = m / Traits::B_M;
    const int num_tiles_k = k / Traits::B_K;

    #pragma omp parallel for collapse(3)
    for (int b = 0; b < batch; ++b) {
        for (int mb = 0; mb < num_tiles_m; ++mb) {
            for (int kt = 0; kt < num_tiles_k; ++kt) {
                const std::size_t dst_tile =
                    (static_cast<std::size_t>(b) * num_tiles_m * num_tiles_k
                     + static_cast<std::size_t>(mb) * num_tiles_k + kt)
                    * tile_elems;
                if constexpr (Traits::W_M == 32 && Traits::W_K == 64) {
                    // One dword per physical scale lane.  q identifies the
                    // low/high physical half-wave, while byte selector
                    // [phase, half_m] supplies the four K32/M-half choices.
                    for (int consumer_wave_m = 0;
                         consumer_wave_m < Traits::T_M;
                         ++consumer_wave_m) {
                        for (int r = 0; r < Traits::W_M; ++r) {
                            for (int q = 0; q < scale_count; ++q) {
                                for (int phase = 0; phase < Traits::E_K; ++phase) {
                                    for (int half_m = 0;
                                         half_m < Traits::B_M / Traits::HALF_B_M;
                                         ++half_m) {
                                        const int selector = 2 * phase + half_m;
                                        const int src_m =
                                            mb * Traits::B_M
                                            + half_m * Traits::HALF_B_M
                                            + consumer_wave_m * Traits::W_M + r;
                                        const int src_q =
                                            kt * Traits::NUM_KGROUPS + 2 * phase + q;
                                        const std::size_t dst_offset =
                                            (((consumer_wave_m * Traits::W_M + r)
                                               * scale_count
                                              + q)
                                             * 4)
                                            + selector;
                                        dst[dst_tile + dst_offset] =
                                            src[(static_cast<std::size_t>(b) * m + src_m)
                                                * num_groups_k + src_q];
                                    }
                                }
                            }
                        }
                    }
                } else {
                    for (int consumer_wave_m = 0; consumer_wave_m < Traits::T_M;
                         ++consumer_wave_m) {
                        for (int r = 0; r < Traits::W_M; ++r) {
                            for (int q = 0; q < scale_count; ++q) {
                                for (int m_call = 0; m_call < Traits::SCALE_M_CALLS;
                                     ++m_call) {
                                    const int src_m =
                                        mb * Traits::B_M
                                        + m_call * Traits::T_M * Traits::W_M
                                        + consumer_wave_m * Traits::W_M + r;
                                    const int src_q = kt * Traits::NUM_KGROUPS + q;
                                    const std::size_t dst_offset =
                                        (((consumer_wave_m * Traits::W_M + r) * scale_count + q)
                                         * Traits::SCALE_M_CALLS)
                                        + m_call;
                                    dst[dst_tile + dst_offset] =
                                        src[(static_cast<std::size_t>(b) * m + src_m)
                                            * num_groups_k + src_q];
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// SFB consumer order is
// [half_n][consumer_wave_n][r][q][n_call]. The packed tile is copied
// linearly to LDS; producer vector width does not change this layout.
template<class Traits>
void pack_sfb_consumer_major(
    const e8m0_t* src,
    e8m0_t* dst,
    int batch,
    int n,
    int k) {
    constexpr int scale_count = Traits::SCALE_KGROUPS_PER_MFMA;
    constexpr int tile_elems = Traits::packed_sfb_tile_elem;

    const int num_groups_k = k / Traits::GROUP_K;
    const int num_tiles_n = n / Traits::B_N;
    const int num_tiles_k = k / Traits::B_K;

    #pragma omp parallel for collapse(3)
    for (int b = 0; b < batch; ++b) {
        for (int nb = 0; nb < num_tiles_n; ++nb) {
            for (int kt = 0; kt < num_tiles_k; ++kt) {
                const std::size_t dst_tile =
                    (static_cast<std::size_t>(b) * num_tiles_n * num_tiles_k
                     + static_cast<std::size_t>(nb) * num_tiles_k + kt)
                    * tile_elems;
                if constexpr (
                    Traits::W_N == 16 && Traits::W_K == 128
                    && Traits::T_M == 2 && Traits::T_N == 4
                    && Traits::E_M == 4 && Traits::E_N == 2) {
                    // Transposed 8-wave 2x4 topology.  One dword per physical
                    // scale lane holds [N half][N repeat], so both 128-column
                    // halves share a single LDS read and op_sel selects 0..3.
                    for (int consumer_wave_n = 0;
                         consumer_wave_n < Traits::T_N;
                         ++consumer_wave_n) {
                        for (int r = 0; r < Traits::W_N; ++r) {
                            for (int q = 0; q < scale_count; ++q) {
                                for (int half_n = 0;
                                     half_n < Traits::SCALE_N_HALVES;
                                     ++half_n) {
                                    for (int n_call = 0;
                                         n_call < Traits::E_N;
                                         ++n_call) {
                                        const int selector =
                                            half_n * Traits::E_N + n_call;
                                        const int src_n =
                                            nb * Traits::B_N
                                            + half_n * Traits::HALF_B_N
                                            + n_call * Traits::T_N * Traits::W_N
                                            + consumer_wave_n * Traits::W_N + r;
                                        const int src_q =
                                            kt * Traits::NUM_KGROUPS + q;
                                        const std::size_t dst_offset =
                                            (((consumer_wave_n * Traits::W_N + r)
                                               * scale_count
                                              + q)
                                             * 4)
                                            + selector;
                                        dst[dst_tile + dst_offset] =
                                            src[(static_cast<std::size_t>(b) * n + src_n)
                                                * num_groups_k + src_q];
                                    }
                                }
                            }
                        }
                    }
                } else if constexpr (
                    Traits::W_N == 32 && Traits::W_K == 64
                    && Traits::T_N == 4 && Traits::E_N == 1) {
                    // 16-wave 4x4 topology: one dword per physical scale
                    // lane.  Its four bytes select [K64 phase][N half].
                    // Keeping phase in the byte selector (rather than in the
                    // dword address) is what keeps the complete tile at 1 KiB.
                    for (int consumer_wave_n = 0;
                         consumer_wave_n < Traits::T_N;
                         ++consumer_wave_n) {
                        for (int r = 0; r < Traits::W_N; ++r) {
                            for (int q = 0; q < scale_count; ++q) {
                                for (int phase = 0; phase < Traits::E_K; ++phase) {
                                    for (int half_n = 0;
                                         half_n < Traits::SCALE_N_HALVES;
                                         ++half_n) {
                                        const int selector = 2 * phase + half_n;
                                        const int src_n =
                                            nb * Traits::B_N
                                            + half_n * Traits::HALF_B_N
                                            + consumer_wave_n * Traits::W_N + r;
                                        const int src_q =
                                            kt * Traits::NUM_KGROUPS + 2 * phase + q;
                                        const std::size_t dst_offset =
                                            ((consumer_wave_n * Traits::W_N + r)
                                                 * scale_count
                                             + q)
                                                * 4
                                            + selector;
                                        dst[dst_tile + dst_offset] =
                                            src[(static_cast<std::size_t>(b) * n + src_n)
                                                * num_groups_k + src_q];
                                    }
                                }
                            }
                        }
                    }
                } else if constexpr (Traits::W_N == 32 && Traits::W_K == 64) {
                    // Two dwords per lane, one for each K64 phase.  Byte
                    // selector [half_n, n_repeat] supplies the four N choices.
                    for (int phase = 0; phase < Traits::E_K; ++phase) {
                        for (int consumer_wave_n = 0;
                             consumer_wave_n < Traits::T_N;
                             ++consumer_wave_n) {
                            for (int r = 0; r < Traits::W_N; ++r) {
                                for (int q = 0; q < scale_count; ++q) {
                                    for (int half_n = 0;
                                         half_n < Traits::SCALE_N_HALVES;
                                         ++half_n) {
                                        for (int n_repeat = 0;
                                             n_repeat < Traits::E_N;
                                             ++n_repeat) {
                                            const int selector = 2 * half_n + n_repeat;
                                            const int src_n =
                                                nb * Traits::B_N
                                                + half_n * Traits::HALF_B_N
                                                + n_repeat * Traits::T_N * Traits::W_N
                                                + consumer_wave_n * Traits::W_N + r;
                                            const int src_q =
                                                kt * Traits::NUM_KGROUPS + 2 * phase + q;
                                            const std::size_t dst_offset =
                                                (((((phase * Traits::T_N
                                                     + consumer_wave_n)
                                                    * Traits::W_N)
                                                   + r)
                                                  * scale_count
                                                  + q)
                                                 * 4)
                                                + selector;
                                            dst[dst_tile + dst_offset] =
                                                src[(static_cast<std::size_t>(b) * n + src_n)
                                                    * num_groups_k + src_q];
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    for (int half_n = 0; half_n < Traits::SCALE_N_HALVES; ++half_n) {
                        for (int consumer_wave_n = 0; consumer_wave_n < Traits::T_N;
                             ++consumer_wave_n) {
                            for (int r = 0; r < Traits::W_N; ++r) {
                                for (int q = 0; q < scale_count; ++q) {
                                    for (int n_call = 0; n_call < Traits::SCALE_N_CALLS;
                                         ++n_call) {
                                        const int src_n =
                                            nb * Traits::B_N + half_n * Traits::HALF_B_N
                                            + n_call * Traits::T_N * Traits::W_N
                                            + consumer_wave_n * Traits::W_N + r;
                                        const int src_q = kt * Traits::NUM_KGROUPS + q;
                                        const std::size_t dst_offset =
                                            (((((half_n * Traits::T_N + consumer_wave_n)
                                                 * Traits::W_N)
                                                + r)
                                               * scale_count
                                               + q)
                                              * Traits::SCALE_N_CALLS)
                                            + n_call;
                                        dst[dst_tile + dst_offset] =
                                            src[(static_cast<std::size_t>(b) * n + src_n)
                                                * num_groups_k + src_q];
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
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
void launch_scale_pipeline(
    const opus_gemm_scale_kargs& kargs,
    dim3 grid,
    dim3 block
#if defined(MXFP8_GPU_SCALE_PACK)
    , const e8m0_t* raw_sfa,
    const e8m0_t* raw_sfb,
    e8m0_t* packed_sfa,
    e8m0_t* packed_sfb
#endif
) {
#if defined(MXFP8_GPU_SCALE_PACK) && !defined(MXFP8_FUSED_COOPERATIVE_PACK)
#if defined(MXFP8_GPU_SCALE_PACK_EXACT_8192)
#if defined(MXFP8_GPU_SCALE_PACK_COALESCED64)
    constexpr int pack_blocks =
        1024 / MXFP8_GPU_SCALE_PACK_WAVES_PER_BLOCK;
#elif defined(MXFP8_GPU_SCALE_PACK_TILED32)
    constexpr int pack_blocks = 512;
#elif defined(MXFP8_GPU_SCALE_PACK_TILED64)
    constexpr int pack_blocks = 256;
#else
    constexpr int pack_blocks = 1024;
#endif
#else
    const int tile_groups_k = (kargs.k / Traits::B_K) / 4;
    const int pack_blocks = kargs.batch *
        ((kargs.m / Traits::B_M) + (kargs.n / Traits::B_N)) *
        tile_groups_k;
#endif
#if defined(MXFP8_GPU_SCALE_PACK_COALESCED64)
    pack_row_major_scales_gpu<<<
        dim3(pack_blocks),
        dim3(64 * MXFP8_GPU_SCALE_PACK_WAVES_PER_BLOCK)>>>(
#elif defined(MXFP8_GPU_SCALE_PACK_TILED32)
    pack_row_major_scales_gpu<<<dim3(pack_blocks), dim3(128)>>>(
#elif defined(MXFP8_GPU_SCALE_PACK_TILED64)
    pack_row_major_scales_gpu<<<dim3(pack_blocks), dim3(256)>>>(
#else
    pack_row_major_scales_gpu<<<dim3(pack_blocks), dim3(64)>>>(
#endif
        raw_sfa, raw_sfb, packed_sfa, packed_sfb,
        kargs.m, kargs.n, kargs.k, kargs.batch);
    CHECK_HIP_KERNEL_LAUNCH();
#endif
#if defined(MXFP8_FUSED_COOPERATIVE_PACK)
    auto launch_kargs = kargs;
    static unsigned int launch_epoch = 0;
    launch_kargs.pack_epoch = ++launch_epoch;
    void* kernel_params[] = {&launch_kargs};
    CHECK_HIP(hipLaunchCooperativeKernel(
        MXFP8_SCALE_KERNEL<Traits>, grid, block, kernel_params, 0, nullptr));
#else
    MXFP8_SCALE_KERNEL<Traits><<<grid, block>>>(kargs);
    CHECK_HIP_KERNEL_LAUNCH();
#endif
}

template<class Traits>
void benchmark_kernel(
    const opus_gemm_scale_kargs& kargs,
    dim3 grid,
    dim3 block,
    int warmup,
    int iterations
#if defined(MXFP8_GPU_SCALE_PACK)
    , const e8m0_t* raw_sfa,
    const e8m0_t* raw_sfb,
    e8m0_t* packed_sfa,
    e8m0_t* packed_sfb
#endif
) {
    for (int i = 0; i < warmup; ++i) {
        launch_scale_pipeline<Traits>(
            kargs, grid, block
#if defined(MXFP8_GPU_SCALE_PACK)
            , raw_sfa, raw_sfb, packed_sfa, packed_sfb
#endif
        );
    }

    hipEvent_t start;
    hipEvent_t stop;
    CHECK_HIP(hipEventCreate(&start));
    CHECK_HIP(hipEventCreate(&stop));

    CHECK_HIP(hipDeviceSynchronize());
    CHECK_HIP(hipEventRecord(start));

    for (int i = 0; i < iterations; ++i) {
        launch_scale_pipeline<Traits>(
            kargs, grid, block
#if defined(MXFP8_GPU_SCALE_PACK)
            , raw_sfa, raw_sfb, packed_sfa, packed_sfb
#endif
        );
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

    std::printf("Kernel Performance: avg_time=%.4f ms, %.2f TFlops\n", avg_time, tflops);
}

template<class Traits>
void benchmark_kernel_timeline(
    const opus_gemm_scale_kargs& kargs,
    dim3 grid,
    dim3 block
#if defined(MXFP8_GPU_SCALE_PACK)
    , const e8m0_t* raw_sfa,
    const e8m0_t* raw_sfb,
    e8m0_t* packed_sfa,
    e8m0_t* packed_sfb
#endif
) {
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
            launch_scale_pipeline<Traits>(
                kargs, grid, block
#if defined(MXFP8_GPU_SCALE_PACK)
                , raw_sfa, raw_sfb, packed_sfa, packed_sfb
#endif
            );
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
    int K = 256;
    int batch = 8;
    int verify = 0;
    int warmup = 200;
    int iterations = 100;
    int timeline = 0;

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
                    if (i + 1 < argc) {
                        target = std::atoi(argv[++i]);
                    }
                } else {
                    target = std::atoi(val);
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
    }

    if (M <= 0 || N <= 0 || K <= 0 || batch <= 0 || warmup < 0 || iterations <= 0) {
        std::cerr << "Invalid arguments: M/N/K/batch/iterations must be positive and warmup must be non-negative.\n";
        return 1;
    }
    if (timeline && verify) {
        std::cerr << "--timeline requires --verify 0 so that no validation launch precedes kernel 1.\n";
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
#if defined(MXFP8_GPU_SCALE_PACK_EXACT_8192)
    if (M != 8192 || N != 8192 || K != 8192 || batch != 1) {
        std::cerr << "exact GPU scale pack requires 8192x8192x8192, batch 1.\n";
        return 1;
    }
#endif
    const int num_groups_k = K / GROUP_K;
    const int num_tiles_m = M / BLOCK_M;
    const int num_tiles_n = N / BLOCK_N;
    const int num_tiles_k = K / BLOCK_K;
    if ((num_tiles_k & 3) != 0) {
        std::cerr
            << "row-major scale VGPR queue4 experiment requires "
               "num_tiles_k % 4 == 0 (K must be a multiple of "
            << (4 * BLOCK_K) << ").\n";
        return 1;
    }

    auto host_a = std::make_unique<host_fp8_t[]>(static_cast<std::size_t>(batch) * M * K);
    auto host_b = std::make_unique<host_fp8_t[]>(static_cast<std::size_t>(batch) * N * K);
#if defined(MXFP8_PRESHUFFLE_B)
    auto host_b_preshuffled =
        std::make_unique<host_fp8_t[]>(static_cast<std::size_t>(batch) * N * K);
#endif
    std::unique_ptr<fp32_t[]> host_c;
    std::unique_ptr<fp32_t[]> host_c_out;
    std::unique_ptr<double[]> host_c_mag;
    if (verify) {
        host_c = std::make_unique<fp32_t[]>(static_cast<std::size_t>(batch) * M * N);
        host_c_out = std::make_unique<fp32_t[]>(static_cast<std::size_t>(batch) * M * N);
        host_c_mag = std::make_unique<double[]>(static_cast<std::size_t>(M) * N);
    }

    const std::size_t sfa_count = static_cast<std::size_t>(batch) * M * num_groups_k;
    const std::size_t sfb_count = static_cast<std::size_t>(batch) * N * num_groups_k;
    auto host_sfa = std::make_unique<e8m0_t[]>(sfa_count);
    auto host_sfb = std::make_unique<e8m0_t[]>(sfb_count);

    rand_vector(host_a.get(), static_cast<std::size_t>(batch) * M * K, 0.0f, 1.0f);
    rand_vector(host_b.get(), static_cast<std::size_t>(batch) * N * K, -0.5f, 0.5f);
    // Debug-only K-window isolation.  With the variables unset this has no
    // effect; when set, both operands are zeroed outside [begin, end), making
    // it possible to identify which pipelined K tiles are corrupted.
    if (const char* begin_env = std::getenv("MXFP8_ACTIVE_K_BEGIN")) {
        const int begin = std::max(0, std::atoi(begin_env));
        const int end = std::min(
            K, std::atoi(std::getenv("MXFP8_ACTIVE_K_END")
                             ? std::getenv("MXFP8_ACTIVE_K_END")
                             : begin_env));
        for (int b = 0; b < batch; ++b) {
            for (int i = 0; i < M; ++i) {
                for (int k = 0; k < K; ++k) {
                    if (k < begin || k >= end) {
                        host_a[(static_cast<std::size_t>(b) * M + i) * K + k] =
                            static_cast<host_fp8_t>(0.0f);
                    }
                }
            }
            for (int j = 0; j < N; ++j) {
                for (int k = 0; k < K; ++k) {
                    if (k < begin || k >= end) {
                        host_b[(static_cast<std::size_t>(b) * N + j) * K + k] =
                            static_cast<host_fp8_t>(0.0f);
                    }
                }
            }
        }
    }
#if defined(MXFP8_PRESHUFFLE_B)
    preshuffle_b_k_panels(
        host_b.get(), host_b_preshuffled.get(), batch, N, K, BLOCK_K);
#endif
    rand_scale_e8m0(host_sfa.get(), sfa_count);
    rand_scale_e8m0(host_sfb.get(), sfb_count);
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
#if defined(MXFP8_GPU_SCALE_PACK)
    void* dev_sfa_packed = nullptr;
    void* dev_sfb_packed = nullptr;
#endif
#if defined(MXFP8_FUSED_COOPERATIVE_PACK)
    void* dev_pack_ready = nullptr;
#endif
#if defined(MXFP8_FUSED_VALIDATE_REFERENCE)
    fp32_t* dev_c_reference = nullptr;
    unsigned long long* dev_mismatches = nullptr;
#endif
    fp32_t* dev_c = nullptr;
    CHECK_HIP(hipMalloc(&dev_a, static_cast<std::size_t>(batch) * M * K * sizeof(host_fp8_t)));
    CHECK_HIP(hipMalloc(&dev_b, static_cast<std::size_t>(batch) * N * K * sizeof(host_fp8_t)));
    CHECK_HIP(hipMalloc(&dev_c, static_cast<std::size_t>(batch) * M * N * sizeof(fp32_t)));
    CHECK_HIP(hipMalloc(&dev_sfa, sfa_count * sizeof(e8m0_t)));
    CHECK_HIP(hipMalloc(&dev_sfb, sfb_count * sizeof(e8m0_t)));
#if defined(MXFP8_GPU_SCALE_PACK)
    CHECK_HIP(hipMalloc(&dev_sfa_packed, sfa_count * sizeof(e8m0_t)));
    CHECK_HIP(hipMalloc(&dev_sfb_packed, sfb_count * sizeof(e8m0_t)));
#endif
#if defined(MXFP8_FUSED_COOPERATIVE_PACK)
    CHECK_HIP(hipMalloc(
        &dev_pack_ready, MXFP8_PACK_READY_COUNT * sizeof(unsigned int)));
    CHECK_HIP(hipMemset(
        dev_pack_ready, 0, MXFP8_PACK_READY_COUNT * sizeof(unsigned int)));
#endif
#if defined(MXFP8_FUSED_VALIDATE_REFERENCE)
    CHECK_HIP(hipMalloc(
        &dev_c_reference,
        static_cast<std::size_t>(batch) * M * N * sizeof(fp32_t)));
    CHECK_HIP(hipMalloc(&dev_mismatches, sizeof(unsigned long long)));
#endif

    CHECK_HIP(hipMemcpy(dev_a, host_a.get(), static_cast<std::size_t>(batch) * M * K * sizeof(host_fp8_t), hipMemcpyHostToDevice));
#if defined(MXFP8_PRESHUFFLE_B)
    CHECK_HIP(hipMemcpy(dev_b, host_b_preshuffled.get(), static_cast<std::size_t>(batch) * N * K * sizeof(host_fp8_t), hipMemcpyHostToDevice));
#else
    CHECK_HIP(hipMemcpy(dev_b, host_b.get(), static_cast<std::size_t>(batch) * N * K * sizeof(host_fp8_t), hipMemcpyHostToDevice));
#endif
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
#if defined(MXFP8_PRESHUFFLE_B)
    kargs.stride_b = BLOCK_K;
#else
    kargs.stride_b = K;
#endif
    kargs.stride_c = N;
    kargs.stride_a_batch = M * K;
    kargs.stride_b_batch = N * K;
    kargs.stride_c_batch = M * N;
#if defined(MXFP8_GPU_SCALE_PACK)
    kargs.ptr_sfa = dev_sfa_packed;
    kargs.ptr_sfb = dev_sfb_packed;
    kargs.stride_sfa = GemmTraits::packed_sfa_tile_elem;
    kargs.stride_sfb = GemmTraits::packed_sfb_tile_elem;
    kargs.stride_sfa_batch =
        num_tiles_m * num_tiles_k * kargs.stride_sfa;
    kargs.stride_sfb_batch =
        num_tiles_n * num_tiles_k * kargs.stride_sfb;
#if defined(MXFP8_FUSED_COOPERATIVE_PACK)
    kargs.ptr_sfa_raw = dev_sfa;
    kargs.ptr_sfb_raw = dev_sfb;
    kargs.ptr_pack_ready = dev_pack_ready;
    kargs.pack_epoch = 0;
#endif
#else
    kargs.ptr_sfa = dev_sfa;
    kargs.ptr_sfb = dev_sfb;
    kargs.stride_sfa = num_groups_k;
    kargs.stride_sfb = num_groups_k;
    kargs.stride_sfa_batch = M * num_groups_k;
    kargs.stride_sfb_batch = N * num_groups_k;
#endif

    const int m_tile_groups =
        ceil_div_scale(num_tiles_m, FIXED_B_PREFETCH_OUTPUT_TILES_PER_WG);
    dim3 grid(m_tile_groups * num_tiles_n, 1, batch);
    dim3 block(BLOCK_SIZE);

#if defined(MXFP8_FUSED_COOPERATIVE_PACK)
    int active_blocks_per_cu = 0;
    int compute_units = 0;
    CHECK_HIP(hipOccupancyMaxActiveBlocksPerMultiprocessor(
        &active_blocks_per_cu, MXFP8_SCALE_KERNEL<GemmTraits>, BLOCK_SIZE, 0));
    CHECK_HIP(hipDeviceGetAttribute(
        &compute_units, hipDeviceAttributeMultiprocessorCount, 0));
    const long long cooperative_capacity =
        static_cast<long long>(active_blocks_per_cu) * compute_units;
    const long long cooperative_grid =
        static_cast<long long>(grid.x) * grid.y * grid.z;
    std::printf(
        "Cooperative residency: active_blocks_per_cu=%d, compute_units=%d, "
        "capacity=%lld, grid_blocks=%lld\n",
        active_blocks_per_cu, compute_units, cooperative_capacity,
        cooperative_grid);
    if (cooperative_grid > cooperative_capacity) {
        std::cerr << "Cooperative grid does not fit concurrently on the GPU.\n";
        return 1;
    }
    if (std::getenv("MXFP8_FUSED_PREPACK_ONCE") != nullptr) {
        pack_row_major_scales_gpu<<<dim3(256), dim3(256)>>>(
            reinterpret_cast<const e8m0_t*>(dev_sfa),
            reinterpret_cast<const e8m0_t*>(dev_sfb),
            reinterpret_cast<e8m0_t*>(dev_sfa_packed),
            reinterpret_cast<e8m0_t*>(dev_sfb_packed),
            M, N, K, batch);
        CHECK_HIP_KERNEL_LAUNCH();
        CHECK_HIP(hipDeviceSynchronize());
    }
#endif

    std::printf("Launching MXFP8 scaled-MFMA GEMM %s: M=%d, N=%d, K=%d, grid=(%u,%u,%u), block=%d, output_tiles_per_wg=%d\n",
                MXFP8_SCALE_VARIANT_NAME, M, N, K, grid.x, grid.y, grid.z, BLOCK_SIZE,
                FIXED_B_PREFETCH_OUTPUT_TILES_PER_WG);

#if defined(MXFP8_FUSED_VALIDATE_REFERENCE)
    if (std::getenv("MXFP8_VALIDATE_FUSED_REFERENCE") != nullptr) {
        CHECK_HIP(hipMemset(dev_c, 0, static_cast<std::size_t>(batch) * M * N * sizeof(fp32_t)));
        CHECK_HIP(hipMemset(dev_c_reference, 0, static_cast<std::size_t>(batch) * M * N * sizeof(fp32_t)));
        CHECK_HIP(hipMemset(dev_mismatches, 0, sizeof(unsigned long long)));
        launch_scale_pipeline<GemmTraits>(
            kargs, grid, block,
            reinterpret_cast<const e8m0_t*>(dev_sfa),
            reinterpret_cast<const e8m0_t*>(dev_sfb),
            reinterpret_cast<e8m0_t*>(dev_sfa_packed),
            reinterpret_cast<e8m0_t*>(dev_sfb_packed));
        auto reference_kargs = kargs;
        reference_kargs.ptr_c = dev_c_reference;
        MXFP8_SCALE_REFERENCE_KERNEL<GemmTraits><<<grid, block>>>(
            reference_kargs);
        CHECK_HIP_KERNEL_LAUNCH();
        const std::size_t output_count =
            static_cast<std::size_t>(batch) * M * N;
        mxfp8_compare_f32_bits<<<dim3(256), dim3(256)>>>(
            reinterpret_cast<const std::uint32_t*>(dev_c),
            reinterpret_cast<const std::uint32_t*>(dev_c_reference),
            output_count, dev_mismatches);
        CHECK_HIP_KERNEL_LAUNCH();
        unsigned long long mismatches = 0;
        CHECK_HIP(hipMemcpy(&mismatches, dev_mismatches,
                            sizeof(mismatches), hipMemcpyDeviceToHost));
        std::printf("Fused-vs-packed bitwise comparison: %llu/%zu mismatches\n",
                    mismatches, output_count);
        std::printf("[Fused GEMM reference] %s\n",
                    mismatches == 0 ? "VALID" : "FAIL");
        return mismatches == 0 ? 0 : 1;
    }
#endif

    if (std::getenv("MXFP8_OUTPUT_HASH") != nullptr) {
        launch_scale_pipeline<GemmTraits>(
            kargs, grid, block
#if defined(MXFP8_GPU_SCALE_PACK)
            , reinterpret_cast<const e8m0_t*>(dev_sfa),
            reinterpret_cast<const e8m0_t*>(dev_sfb),
            reinterpret_cast<e8m0_t*>(dev_sfa_packed),
            reinterpret_cast<e8m0_t*>(dev_sfb_packed)
#endif
        );
        const std::size_t output_count =
            static_cast<std::size_t>(batch) * M * N;
        auto output_bits = std::make_unique<std::uint32_t[]>(output_count);
        CHECK_HIP(hipMemcpy(output_bits.get(), dev_c,
                            output_count * sizeof(std::uint32_t),
                            hipMemcpyDeviceToHost));
        std::uint64_t hash = 1469598103934665603ull;
        for (std::size_t i = 0; i < output_count; ++i) {
            hash ^= output_bits[i];
            hash *= 1099511628211ull;
        }
        std::printf("Output bit hash: %016llx (%zu fp32 values)\n",
                    static_cast<unsigned long long>(hash), output_count);
        return 0;
    }

#if defined(MXFP8_GPU_SCALE_PACK)
    if (std::getenv("MXFP8_BENCH_GPU_PACK_ONLY") != nullptr) {
        auto launch_pack = [&]() {
            pack_row_major_scales_gpu<<<dim3(256), dim3(256)>>>(
                reinterpret_cast<const e8m0_t*>(dev_sfa),
                reinterpret_cast<const e8m0_t*>(dev_sfb),
                reinterpret_cast<e8m0_t*>(dev_sfa_packed),
                reinterpret_cast<e8m0_t*>(dev_sfb_packed),
                M, N, K, batch);
            CHECK_HIP_KERNEL_LAUNCH();
        };
        for (int i = 0; i < warmup; ++i) launch_pack();
        hipEvent_t pack_start;
        hipEvent_t pack_stop;
        CHECK_HIP(hipEventCreate(&pack_start));
        CHECK_HIP(hipEventCreate(&pack_stop));
        CHECK_HIP(hipDeviceSynchronize());
        CHECK_HIP(hipEventRecord(pack_start));
        for (int i = 0; i < iterations; ++i) launch_pack();
        CHECK_HIP(hipEventRecord(pack_stop));
        CHECK_HIP(hipEventSynchronize(pack_stop));
        float pack_total_ms = 0.0f;
        CHECK_HIP(hipEventElapsedTime(&pack_total_ms, pack_start, pack_stop));
        std::printf("GPU scale pack only: avg_time=%.4f ms\n",
                    pack_total_ms / iterations);
        CHECK_HIP(hipEventDestroy(pack_start));
        CHECK_HIP(hipEventDestroy(pack_stop));
        return 0;
    }
    if (std::getenv("MXFP8_VALIDATE_GPU_PACK_ONLY") != nullptr) {
        launch_scale_pipeline<GemmTraits>(
            kargs, grid, block,
            reinterpret_cast<const e8m0_t*>(dev_sfa),
            reinterpret_cast<const e8m0_t*>(dev_sfb),
            reinterpret_cast<e8m0_t*>(dev_sfa_packed),
            reinterpret_cast<e8m0_t*>(dev_sfb_packed));
        auto gpu_sfa_packed = std::make_unique<e8m0_t[]>(sfa_count);
        auto gpu_sfb_packed = std::make_unique<e8m0_t[]>(sfb_count);
        auto ref_sfa_packed = std::make_unique<e8m0_t[]>(sfa_count);
        auto ref_sfb_packed = std::make_unique<e8m0_t[]>(sfb_count);
        CHECK_HIP(hipMemcpy(gpu_sfa_packed.get(), dev_sfa_packed,
                            sfa_count * sizeof(e8m0_t), hipMemcpyDeviceToHost));
        CHECK_HIP(hipMemcpy(gpu_sfb_packed.get(), dev_sfb_packed,
                            sfb_count * sizeof(e8m0_t), hipMemcpyDeviceToHost));
        pack_sfa_consumer_major<GemmTraits>(
            host_sfa.get(), ref_sfa_packed.get(), batch, M, K);
        pack_sfb_consumer_major<GemmTraits>(
            host_sfb.get(), ref_sfb_packed.get(), batch, N, K);
        std::size_t errors = 0;
        auto check_pack = [&](const char* tag, const e8m0_t* gpu,
                              const e8m0_t* ref, std::size_t count) {
            std::size_t local_errors = 0;
            for (std::size_t i = 0; i < count; ++i) {
                if (gpu[i] != ref[i]) {
                    if (local_errors < 8) {
                        std::printf(
                            "%s pack mismatch at %zu: gpu=%u ref=%u\n",
                            tag, i, static_cast<unsigned>(gpu[i]),
                            static_cast<unsigned>(ref[i]));
                    }
                    ++local_errors;
                }
            }
            std::printf("%s packed-scale validation: %zu/%zu mismatches\n",
                        tag, local_errors, count);
            return local_errors;
        };
        errors += check_pack("SFA", gpu_sfa_packed.get(),
                             ref_sfa_packed.get(), sfa_count);
        errors += check_pack("SFB", gpu_sfb_packed.get(),
                             ref_sfb_packed.get(), sfb_count);
        std::printf("[GPU pack only] %s\n", errors == 0 ? "VALID" : "FAIL");
        return errors == 0 ? 0 : 1;
    }
#endif

    if (verify) {
        launch_scale_pipeline<GemmTraits>(
            kargs, grid, block
#if defined(MXFP8_GPU_SCALE_PACK)
            , reinterpret_cast<const e8m0_t*>(dev_sfa),
            reinterpret_cast<const e8m0_t*>(dev_sfb),
            reinterpret_cast<e8m0_t*>(dev_sfa_packed),
            reinterpret_cast<e8m0_t*>(dev_sfb_packed)
#endif
        );
        std::printf("\nValidating GPU results against CPU reference...\n");
        CHECK_HIP(hipMemcpy(host_c_out.get(), dev_c, static_cast<std::size_t>(batch) * M * N * sizeof(fp32_t),
                            hipMemcpyDeviceToHost));

        if (std::getenv("MXFP8_DUMP_PAIR_CACHE") != nullptr) {
            const auto* raw = reinterpret_cast<const std::uint32_t*>(
                host_c_out.get());
            for (int wave = 0; wave < 8; ++wave) {
                for (int lane = 0; lane < 4; ++lane) {
                    const int index = wave * 64 + lane;
                    std::printf(
                        "pair-debug wave=%d lane=%d "
                        "sfa0=%08x sfa1=%08x "
                        "sfb00=%08x sfb01=%08x "
                        "sfb10=%08x sfb11=%08x\n",
                        wave, lane,
                        raw[0 * BLOCK_SIZE + index],
                        raw[1 * BLOCK_SIZE + index],
                        raw[2 * BLOCK_SIZE + index],
                        raw[3 * BLOCK_SIZE + index],
                        raw[4 * BLOCK_SIZE + index],
                        raw[5 * BLOCK_SIZE + index]);
                }
            }
            return 0;
        }

        if (std::getenv("MXFP8_DUMP_SCALE_REUSE") != nullptr) {
            const auto* raw = reinterpret_cast<const std::uint32_t*>(
                host_c_out.get());
            for (int wave = 0; wave < 8; ++wave) {
                int mismatches = 0;
                for (int lane = 0; lane < 64; ++lane) {
                    const int index = wave * 64 + lane;
                    mismatches += raw[index] != raw[512 + index];
                    if (lane < 2) {
                        std::printf(
                            "scale-debug wave=%d lane=%d role=%u "
                            "local=%08x lds=%08x\n",
                            wave, lane, raw[1024 + index], raw[index],
                            raw[512 + index]);
                    }
                }
                std::printf("scale-debug wave=%d mismatches=%d/64\n",
                            wave, mismatches);
            }
            return 0;
        }

        bool all_valid = true;
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

    std::printf("\n");
    if (timeline) {
        benchmark_kernel_timeline<GemmTraits>(
            kargs, grid, block
#if defined(MXFP8_GPU_SCALE_PACK)
            , reinterpret_cast<const e8m0_t*>(dev_sfa),
            reinterpret_cast<const e8m0_t*>(dev_sfb),
            reinterpret_cast<e8m0_t*>(dev_sfa_packed),
            reinterpret_cast<e8m0_t*>(dev_sfb_packed)
#endif
        );
    } else {
        benchmark_kernel<GemmTraits>(
            kargs, grid, block, warmup, iterations
#if defined(MXFP8_GPU_SCALE_PACK)
            , reinterpret_cast<const e8m0_t*>(dev_sfa),
            reinterpret_cast<const e8m0_t*>(dev_sfb),
            reinterpret_cast<e8m0_t*>(dev_sfa_packed),
            reinterpret_cast<e8m0_t*>(dev_sfb_packed)
#endif
        );
    }
    std::printf("\n");

    CHECK_HIP(hipFree(dev_a));
    CHECK_HIP(hipFree(dev_b));
    CHECK_HIP(hipFree(dev_c));
    CHECK_HIP(hipFree(dev_sfa));
    CHECK_HIP(hipFree(dev_sfb));
#if defined(MXFP8_GPU_SCALE_PACK)
    CHECK_HIP(hipFree(dev_sfa_packed));
    CHECK_HIP(hipFree(dev_sfb_packed));
#endif
#if defined(MXFP8_FUSED_COOPERATIVE_PACK)
    CHECK_HIP(hipFree(dev_pack_ready));
#endif
#if defined(MXFP8_FUSED_VALIDATE_REFERENCE)
    CHECK_HIP(hipFree(dev_c_reference));
    CHECK_HIP(hipFree(dev_mismatches));
#endif

    return 0;
}
