#include <opus/hip_minimal.hpp>

#include "gemm_a8w8_mxfp8_scale_common.h"

using GemmTraits = gemm_a8w8_mxfp8_scale_traits<>;

#ifndef __HIP_DEVICE_COMPILE__
template<typename Traits>
__global__ void
gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernel(
    opus_gemm_scale_kargs kargs) {}

template __global__ void
gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernel<GemmTraits>(
    opus_gemm_scale_kargs);
#else
#include <opus/opus.hpp>

#ifndef MXFP8_BLOCK_ORDER
#error "MXFP8_BLOCK_ORDER must select one block-order experiment"
#endif

// Return the logical row-major workgroup id consumed by the retained
// template.  Only the physical-id-to-logical-id permutation changes.
__device__ __forceinline__ int mxfp8_ordered_block_id(
    int physical_id,
    int num_tiles_m,
    int num_tiles_n,
    int output_tiles_per_wg) {
    const int num_mgroups =
        ceil_div_scale(num_tiles_m, output_tiles_per_wg);

#if MXFP8_BLOCK_ORDER == 1
    // One 32-WG chunk covers [4 M-groups][8 N tiles], N fastest inside it.
    if (num_mgroups % 4 != 0 || num_tiles_n % 8 != 0) {
        return physical_id;
    }
    const int macro_n_count = num_tiles_n / 8;
    const int macro_id = physical_id / 32;
    const int local_id = physical_id % 32;
    const int block_mgroup = (macro_id / macro_n_count) * 4 + local_id / 8;
    const int block_n = (macro_id % macro_n_count) * 8 + local_id % 8;
#elif MXFP8_BLOCK_ORDER == 2
    // Same [4][8] rectangle, with M-groups fastest inside the 32-WG chunk.
    if (num_mgroups % 4 != 0 || num_tiles_n % 8 != 0) {
        return physical_id;
    }
    const int macro_n_count = num_tiles_n / 8;
    const int macro_id = physical_id / 32;
    const int local_id = physical_id % 32;
    const int block_mgroup = (macro_id / macro_n_count) * 4 + local_id % 4;
    const int block_n = (macro_id % macro_n_count) * 8 + local_id / 4;
#elif MXFP8_BLOCK_ORDER == 3
    // One 32-WG chunk covers [8 M-groups][4 N tiles], N fastest inside it.
    if (num_mgroups % 8 != 0 || num_tiles_n % 4 != 0) {
        return physical_id;
    }
    const int macro_n_count = num_tiles_n / 4;
    const int macro_id = physical_id / 32;
    const int local_id = physical_id % 32;
    const int block_mgroup = (macro_id / macro_n_count) * 8 + local_id / 4;
    const int block_n = (macro_id % macro_n_count) * 4 + local_id % 4;
#elif MXFP8_BLOCK_ORDER == 4
    // Same [8][4] rectangle, with M-groups fastest inside the 32-WG chunk.
    if (num_mgroups % 8 != 0 || num_tiles_n % 4 != 0) {
        return physical_id;
    }
    const int macro_n_count = num_tiles_n / 4;
    const int macro_id = physical_id / 32;
    const int local_id = physical_id % 32;
    const int block_mgroup = (macro_id / macro_n_count) * 8 + local_id % 8;
    const int block_n = (macro_id % macro_n_count) * 4 + local_id / 8;
#elif MXFP8_BLOCK_ORDER == 5
    // Pure N-major traversal: all M-groups for N=0, then all for N=1, ...
    const int block_mgroup = physical_id % num_mgroups;
    const int block_n = physical_id / num_mgroups;
#elif MXFP8_BLOCK_ORDER == 6
    // Exact 8192^2 fast path: [2 M-groups][16 N tiles], N fastest.
    // Other shapes retain the original mapping verbatim.
    if (num_mgroups != 8 || num_tiles_n != 32) {
        return physical_id;
    }
    const int macro_id = physical_id >> 5;
    const int local_id = physical_id & 31;
    const int block_mgroup = (macro_id >> 1) * 2 + (local_id >> 4);
    const int block_n = (macro_id & 1) * 16 + (local_id & 15);
#elif MXFP8_BLOCK_ORDER == 7
    // Exact 8192^2 fast path for [4 M-groups][8 N tiles], N fastest.
    if (num_mgroups != 8 || num_tiles_n != 32) {
        return physical_id;
    }
    const int macro_id = physical_id >> 5;
    const int local_id = physical_id & 31;
    const int block_mgroup = (macro_id >> 2) * 4 + (local_id >> 3);
    const int block_n = (macro_id & 3) * 8 + (local_id & 7);
#elif MXFP8_BLOCK_ORDER == 8
    // Exact 8192^2 fast path for [8 M-groups][4 N tiles], N fastest.
    if (num_mgroups != 8 || num_tiles_n != 32) {
        return physical_id;
    }
    const int macro_id = physical_id >> 5;
    const int local_id = physical_id & 31;
    const int block_mgroup = local_id >> 2;
    const int block_n = macro_id * 4 + (local_id & 3);
#elif MXFP8_BLOCK_ORDER >= 11 && MXFP8_BLOCK_ORDER <= 14
    // Exact 8192^2 2x16 permutations.  Every physical 32-WG chunk still
    // covers the same rectangle; only the order of its sixteen N values moves.
    if (num_mgroups != 8 || num_tiles_n != 32) {
        return physical_id;
    }
    const int macro_id = physical_id >> 5;
    const int local_id = physical_id & 31;
    const int local_m = local_id >> 4;
    const int raw_n = local_id & 15;
    const int block_mgroup = (macro_id >> 1) * 2 + local_m;
#if MXFP8_BLOCK_ORDER == 11
    const int permuted_n = raw_n ^ (local_m << 3);
#elif MXFP8_BLOCK_ORDER == 12
    const int permuted_n = raw_n ^ (local_m * 15);
#elif MXFP8_BLOCK_ORDER == 13
    const int permuted_n = raw_n ^ (raw_n >> 1);
#else
    const int permuted_n = raw_n ^ (((macro_id >> 1) & 1) << 3);
#endif
    const int block_n = (macro_id & 1) * 16 + permuted_n;
#elif MXFP8_BLOCK_ORDER >= 15 && MXFP8_BLOCK_ORDER <= 21
    // Exact 8192^2 2x16 permutations.  Orders 15--17 insert the single
    // local-M bit at positions 1--3 of the physical 5-bit local id.  Orders
    // 18--21 keep M at bit 4 and permute the four local-N bits only.
    if (num_mgroups != 8 || num_tiles_n != 32) {
        return physical_id;
    }
    const int macro_id = physical_id >> 5;
    const int local_id = physical_id & 31;
#if MXFP8_BLOCK_ORDER == 15
    const int local_m = (local_id >> 1) & 1;
    const int raw_n = (local_id & 1) | ((local_id >> 2) << 1);
#elif MXFP8_BLOCK_ORDER == 16
    const int local_m = (local_id >> 2) & 1;
    const int raw_n = (local_id & 3) | ((local_id >> 3) << 2);
#elif MXFP8_BLOCK_ORDER == 17
    const int local_m = (local_id >> 3) & 1;
    const int raw_n = (local_id & 7) | ((local_id >> 4) << 3);
#else
    const int local_m = local_id >> 4;
    const int raw_n = local_id & 15;
#endif
    const int block_mgroup = (macro_id >> 1) * 2 + local_m;
#if MXFP8_BLOCK_ORDER == 18
    const int permuted_n = ((raw_n & 1) << 3) |
                           ((raw_n & 2) << 1) |
                           ((raw_n & 4) >> 1) |
                           ((raw_n & 8) >> 3);
#elif MXFP8_BLOCK_ORDER == 19
    const int permuted_n = ((raw_n << 1) | (raw_n >> 3)) & 15;
#elif MXFP8_BLOCK_ORDER == 20
    const int permuted_n = ((raw_n << 2) | (raw_n >> 2)) & 15;
#elif MXFP8_BLOCK_ORDER == 21
    const int permuted_n = ((raw_n << 3) | (raw_n >> 1)) & 15;
#else
    const int permuted_n = raw_n;
#endif
    const int block_n = (macro_id & 1) * 16 + permuted_n;
#elif MXFP8_BLOCK_ORDER == 9 || MXFP8_BLOCK_ORDER == 10
    return physical_id;
#else
#error "unknown MXFP8_BLOCK_ORDER"
#endif

#if MXFP8_BLOCK_ORDER != 9 && MXFP8_BLOCK_ORDER != 10
    return block_mgroup * num_tiles_n + block_n;
#endif
}

#if MXFP8_BLOCK_ORDER == 9 || MXFP8_BLOCK_ORDER == 10
struct mxfp8_direct_block_coords {
    int physical_id;
    int m;
    int n;
};

__device__ __forceinline__ int operator%(
    mxfp8_direct_block_coords coords, int divisor) {
    if (coords.m != 8192 || coords.n != 8192) {
        return coords.physical_id % divisor;
    }
#if MXFP8_BLOCK_ORDER == 9
    const int macro_id = coords.physical_id >> 5;
    const int local_id = coords.physical_id & 31;
    return (macro_id & 1) * 16 + (local_id & 15);
#else
    return coords.physical_id & 31;
#endif
}

__device__ __forceinline__ int operator/(
    mxfp8_direct_block_coords coords, int divisor) {
    if (coords.m != 8192 || coords.n != 8192) {
        return coords.physical_id / divisor;
    }
#if MXFP8_BLOCK_ORDER == 9
    const int macro_id = coords.physical_id >> 5;
    const int local_id = coords.physical_id & 31;
    return (macro_id >> 1) * 2 + (local_id >> 4);
#else
    return coords.physical_id >> 5;
#endif
}
#endif

// The retained template calls opus::block_id_x() only at the two lines that
// derive block_n and first_block_m.  Pre-including opus.hpp keeps its function
// definition outside this narrow macro substitution.
#if MXFP8_BLOCK_ORDER == 9 || MXFP8_BLOCK_ORDER == 10
#define block_id_x()                                                        \
    mxfp8_direct_block_coords{                                              \
        static_cast<int>(__builtin_amdgcn_workgroup_id_x()), kargs.m, kargs.n}
#else
#define block_id_x()                                                        \
    mxfp8_ordered_block_id(                                                 \
        static_cast<int>(__builtin_amdgcn_workgroup_id_x()),                \
        num_tiles_m, num_tiles_n, T::OUTPUT_TILES_PER_WG)
#endif
#define gemm_a8w8_mxfp8_scale_kernel \
    gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernel
#include "../early_c_store_full_stack/tmpl.hpp"
#undef gemm_a8w8_mxfp8_scale_kernel
#undef block_id_x

template __global__ void
gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernel<GemmTraits>(
    opus_gemm_scale_kargs);
#endif
