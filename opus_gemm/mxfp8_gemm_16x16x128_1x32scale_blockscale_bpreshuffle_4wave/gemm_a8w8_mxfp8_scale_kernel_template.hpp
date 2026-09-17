#pragma once

#include <opus/hip_minimal.hpp>
#include <opus/opus.hpp>

#include "gemm_a8w8_mxfp8_scale_common.h"

namespace blockscale_generic {

using opus::operator""_I;

__device__ inline void sched_barrier_pairs_scale() {
    __builtin_amdgcn_sched_group_barrier(0x08, 1, 0);
    __builtin_amdgcn_sched_group_barrier(0x02, 2, 0);
    __builtin_amdgcn_sched_group_barrier(0x08, 1, 0);
    __builtin_amdgcn_sched_group_barrier(0x02, 2, 0);
}

template<class T, int HALF_TILE_M, int M_REPEAT, int N_REPEAT, class MMA>
__device__ inline auto mma_scale_one(
    MMA& mma,
    const typename opus::remove_cvref_t<MMA>::vtype_a& v_a,
    const typename opus::remove_cvref_t<MMA>::vtype_b& v_b,
    typename opus::remove_cvref_t<MMA>::MMA::vtype_c v_c,
    unsigned int v_sfa,
    unsigned int v_sfb)
    -> typename opus::remove_cvref_t<MMA>::MMA::vtype_c {
    (void)mma;

    using tiled_mma = opus::remove_cvref_t<MMA>;
    using base_mma = typename tiled_mma::MMA;

    constexpr int a_len = tiled_mma::mma_a_len;
    constexpr int b_len = tiled_mma::mma_b_len;
    constexpr int a_offset = M_REPEAT * a_len;
    constexpr int b_offset = N_REPEAT * b_len;
    constexpr int scale_op_sel_a = M_REPEAT;
    constexpr int scale_op_sel_b = N_REPEAT;

    auto s_a = opus::slice(v_a, opus::number<a_offset>{}, opus::number<a_offset + a_len>{});
    auto s_b = opus::slice(v_b, opus::number<b_offset>{}, opus::number<b_offset + b_len>{});
    return base_mma{}(s_a, s_b, v_c, static_cast<int>(v_sfa), static_cast<int>(v_sfb), opus::number<scale_op_sel_a>{}, opus::number<scale_op_sel_b>{});
}

template<class T>
__device__ inline auto make_layout_ga_scale(int lane_id, int wave_id_m, int wave_id_n, int stride_a) {
    constexpr int threads_k = T::B_K / T::VEC_A;
    constexpr int threads_m_per_block = T::BLOCK_SIZE / threads_k;
    constexpr int threads_m_per_wave = T::WARP_SIZE / threads_k;

    constexpr auto ga_block_shape = opus::make_tuple(
        opus::number<T::HALF_B_M / threads_m_per_block>{},
        opus::number<T::T_N>{},
        opus::number<threads_m_per_wave>{},
        opus::number<T::T_M>{},
        opus::number<threads_k>{},
        opus::number<T::VEC_A>{});

    constexpr auto ga_block_dim = opus::make_tuple(
        opus::make_tuple(opus::y_dim{}, opus::p_dim{}, opus::p_dim{}, opus::p_dim{}),
        opus::make_tuple(opus::p_dim{}, opus::y_dim{}));

    return opus::make_layout<T::VEC_A>(
        ga_block_shape,
        opus::unfold_x_stride(ga_block_dim, ga_block_shape, opus::tuple{stride_a, 1_I}),
        opus::unfold_p_coord(ga_block_dim, opus::tuple{wave_id_n, lane_id / threads_k, wave_id_m,lane_id % threads_k}));
}

template<class T>
__device__ inline auto make_layout_sa_scale(int wave_id_m, int wave_id_n) {
    constexpr int num_waves = T::BLOCK_SIZE / T::WARP_SIZE;

    constexpr auto sa_block_shape = opus::make_tuple(
        opus::number<T::smem_m_rep / num_waves>{},
        opus::number<T::T_N>{},
        opus::number<T::T_M>{},
        opus::number<T::VEC_A>{});

    constexpr auto sa_block_dim = opus::make_tuple(
        opus::make_tuple(opus::y_dim{}, opus::p_dim{}, opus::p_dim{}),
        opus::make_tuple(opus::y_dim{}));

    return opus::make_layout(
        sa_block_shape,
        opus::unfold_x_stride(sa_block_dim, sa_block_shape, opus::tuple{opus::number<T::smem_linear_wave + T::smem_padding>{}, 1_I}),
        opus::unfold_p_coord(sa_block_dim, opus::tuple{wave_id_n, wave_id_m}));
}

template<class T>
__device__ inline constexpr auto make_layout_gb_scale(int lane_id, int wave_id_m, int wave_id_n, int stride_b) {
    constexpr int lanes_n = T::W_N; // 16: lane_id % 16 selects N within an N16 group.
    constexpr int lanes_k = T::WARP_SIZE / lanes_n; // 4: lane_id / 16 selects a K16 slice.
    constexpr int k_per_wave_load = lanes_k * T::VEC_B; // 4 * 16 = 64 K elements per N row.
    constexpr int n_repeats = T::HALF_B_N / (T::NUM_WAVES * lanes_n); // 128 / (4 * 16) = 2.
    constexpr int k_repeats = T::B_K / k_per_wave_load; // 128 / 64 = 2 wave loads per N16 group.

    constexpr auto gb_block_shape = opus::make_tuple(
        opus::number<T::T_N>{},
        opus::number<T::T_M>{},
        opus::number<n_repeats>{},
        opus::number<k_repeats>{},
        opus::number<T::WARP_SIZE>{},
        opus::number<T::VEC_B>{});

    constexpr auto gb_block_dim = opus::make_tuple(
        opus::make_tuple(opus::p_dim{}, opus::p_dim{}, opus::y_dim{}),
        opus::make_tuple(opus::y_dim{}, opus::p_dim{}, opus::y_dim{}));

    return opus::make_layout<T::VEC_B>(
        gb_block_shape,
        opus::unfold_x_stride(gb_block_dim, gb_block_shape, opus::tuple{T::W_N * stride_b, 1_I}),
        opus::unfold_p_coord(gb_block_dim, opus::tuple{wave_id_n, wave_id_m, lane_id}));
}

template<class T>
__device__ inline constexpr auto make_layout_sb_scale(int wave_id_m, int wave_id_n) {
    constexpr int n_repeats = T::HALF_B_N / (T::NUM_WAVES * T::W_N);
    constexpr int k_per_wave_load = (T::WARP_SIZE / T::W_N) * T::VEC_B;
    constexpr int k_repeats = T::B_K / k_per_wave_load;

    constexpr auto sb_block_shape = opus::make_tuple(
        opus::number<T::T_N>{},
        opus::number<T::T_M>{},
        opus::number<n_repeats>{},
        opus::number<k_repeats>{},
        opus::number<T::VEC_B>{});
    constexpr auto sb_block_dim = opus::make_tuple(
        opus::make_tuple(opus::p_dim{}, opus::p_dim{}, opus::y_dim{}, opus::y_dim{}),
        opus::make_tuple(opus::y_dim{}));

    return opus::make_layout(
        sb_block_shape,
        opus::unfold_x_stride(sb_block_dim, sb_block_shape, opus::tuple{opus::number<T::smem_linear_wave + T::smem_padding>{}, 1_I}),
        opus::unfold_p_coord(sb_block_dim, opus::tuple{wave_id_n, wave_id_m}));
}

template<class T>
__device__ inline constexpr auto make_layout_ra_scale(int lane_id, int wave_id_m) {

    constexpr auto ra_block_shape = opus::make_tuple(
        opus::number<T::E_M>{},
        opus::number<T::T_M>{},
        opus::number<T::T_M>{},
        opus::number<T::W_M / T::T_M>{},
        opus::number<T::E_K>{},
        opus::number<T::W_M * T::W_K / T::WARP_SIZE / T::VEC_A>{},
        opus::number<T::WARP_SIZE / T::W_M>{},
        opus::number<T::VEC_A>{});

    constexpr auto ra_block_dim = opus::make_tuple(
        opus::make_tuple(opus::y_dim{}, opus::p_dim{}, opus::p_dim{}),
        opus::make_tuple(opus::p_dim{}, opus::y_dim{}, opus::y_dim{}, opus::p_dim{}, opus::y_dim{}));

    const int lane_id_m = lane_id % T::W_M;
    return opus::make_layout<T::VEC_A>(
        ra_block_shape,
        opus::unfold_x_stride(ra_block_dim, ra_block_shape, opus::tuple{opus::number<T::smem_linear_wave + T::smem_padding>{}, 1_I}),
        opus::unfold_p_coord(ra_block_dim, opus::tuple{wave_id_m, lane_id_m % T::T_M, lane_id_m / T::T_M, lane_id / T::W_M}));
}

template<class T>
__device__ inline constexpr auto make_layout_rb_scale(int lane_id, int wave_id_n) {
    constexpr int k_vectors = T::W_N * T::W_K / (T::WARP_SIZE * T::VEC_B);

    constexpr auto rb_block_shape = opus::make_tuple(
        opus::number<T::E_N>{},
        opus::number<T::T_N>{},
        opus::number<T::E_K>{},
        opus::number<k_vectors>{},
        opus::number<T::WARP_SIZE>{},
        opus::number<T::VEC_B>{});

    constexpr auto rb_block_dim = opus::make_tuple(
        opus::make_tuple(opus::y_dim{}, opus::p_dim{}, opus::y_dim{}, opus::y_dim{}),
        opus::make_tuple(opus::p_dim{}, opus::y_dim{}));

    return opus::make_layout<T::VEC_B>(
        rb_block_shape,
        opus::unfold_x_stride(rb_block_dim, rb_block_shape, opus::tuple{opus::number<T::smem_linear_wave + T::smem_padding>{}, 1_I}),
        opus::unfold_p_coord(rb_block_dim, opus::tuple{wave_id_n, lane_id}));
}

// Shape [K/128, 256], example K = 8192, shape = [64, 256]
template<class T>
__device__ inline constexpr auto make_layout_gsfa_scale(int lane_id, int wave_id_m, int wave_id_n, int stride_sfa) {
    constexpr auto block_shape = opus::make_tuple(
        opus::number<T::SFA_PASSES_PER_CACHE_PANEL>{}, // 4 cache-fill passes
        opus::number<T::T_N>{}, // 2
        opus::number<T::T_M>{}, // 2
        opus::number<T::SFA_K_COLUMNS_PER_WAVE>{}, // 4
        opus::number<T::B_M / T::VEC_SCALE_A>{}, // 16 lanes per K column
        opus::number<T::VEC_SCALE_A>{}); // 16 contiguous M elements per lane

    constexpr auto block_dim = opus::make_tuple(
        opus::make_tuple(opus::y_dim{}, opus::p_dim{}, opus::p_dim{}, opus::p_dim{}),
        opus::make_tuple(opus::p_dim{}, opus::y_dim{}));

    // M-vector order for quad packing: 0,2,4,6,1,3,5,7,8,10,12,14,9,11,13,15.
    const int lane_id_m = (lane_id & 8) | ((lane_id & 3) << 1) | ((lane_id & 4) >> 2);
    return opus::make_layout<T::VEC_SCALE_A>(
        block_shape,
        opus::unfold_x_stride(block_dim, block_shape, opus::tuple{stride_sfa, 1_I}),
        opus::unfold_p_coord(block_dim, opus::tuple{wave_id_n, wave_id_m, lane_id / T::W_M, lane_id_m}));
}

template<class T>
__device__ inline constexpr auto make_layout_ssfa_scale(int lane_id, int wave_id_m, int wave_id_n) {
    constexpr auto block_shape = opus::make_tuple(
        opus::number<T::SFA_PASSES_PER_CACHE_PANEL>{}, // 4 cache-fill passes
        opus::number<T::T_N>{}, // 2
        opus::number<T::T_M>{}, // 2
        opus::number<T::SFA_K_COLUMNS_PER_WAVE>{}, // 4
        opus::number<T::B_M / T::VEC_SF>{}, // 64 packed M dwords per K column
        opus::number<T::VEC_SF>{}); // 4 M-repeat scale bytes per dword

    constexpr auto block_dim = opus::make_tuple(
        opus::make_tuple(opus::y_dim{}, opus::p_dim{}, opus::p_dim{}, opus::p_dim{}),
        opus::make_tuple(opus::p_dim{}, opus::y_dim{}));

    // First packed dword for this lane; successive transposed words are 8 dwords apart.
    const int lane_id_m = ((lane_id & 4) << 3) | ((lane_id & 3) << 1) | ((lane_id & 8) >> 3);
    return opus::make_layout<T::VEC_SF>(
        block_shape,
        opus::unfold_x_stride(block_dim, block_shape, opus::tuple{opus::number<T::SFA_PANEL_PITCH>{}, 1_I}),
        opus::unfold_p_coord(block_dim, opus::tuple{wave_id_n, wave_id_m, lane_id / T::W_M, lane_id_m}));
}

template<class T, int Vec = T::VEC_SCALE_SF>
__device__ inline constexpr auto make_layout_rsfa_scale(int lane_id, int wave_id_m) {
    static_assert(Vec == T::VEC_SCALE_SF || Vec == T::VEC_SCALE_SF_PAIR);

    constexpr auto block_shape = opus::make_tuple(
        opus::number<T::T_M>{}, // 2 wave_m
        opus::number<T::W_M>{}, // 16 M lanes
        opus::number<Vec>{});

    constexpr auto block_dim = opus::make_tuple(
        opus::make_tuple(opus::p_dim{}, opus::p_dim{}),
        opus::make_tuple(opus::y_dim{}));

    return opus::make_layout<Vec>(
        block_shape,
        opus::unfold_x_stride(block_dim, block_shape, opus::tuple{opus::number<T::VEC_SCALE_SF_PAIR>{}, 1_I}),
        opus::unfold_p_coord(block_dim, opus::tuple{wave_id_m, lane_id % T::W_M}));
}

// Shape [2, K/128], example K = 8192, shape = [2,64]
template<class T>
__device__ inline constexpr auto make_layout_gsfb_scale(int lane_id, int wave_id) {
    constexpr auto block_shape = opus::make_tuple(
        opus::number<T::SCALE_N_HALVES>{}, // 2 producer waves / N128 halves
        opus::number<T::SCALE_PANEL_K_CAPACITY>{}, // 64 K128 slots
        opus::number<1>{}); // one compact E8M0 byte

    constexpr auto block_dim = opus::make_tuple(
        opus::make_tuple(opus::p_dim{}),
        opus::make_tuple(opus::p_dim{}, opus::y_dim{}));

    return opus::make_layout<1>(
        block_shape,
        opus::unfold_x_stride(block_dim, block_shape, opus::tuple{0_I, 1_I}),
        opus::unfold_p_coord(block_dim, opus::tuple{wave_id, lane_id}));
}

// N dim repeat 4, shape [2, 64, 4]
template<class T>
__device__ inline constexpr auto make_layout_ssfb_scale(int lane_id, int wave_id) {
    constexpr auto block_shape = opus::make_tuple(
        opus::number<T::SCALE_N_HALVES>{}, // 2 N128 halves
        opus::number<T::SCALE_PANEL_K_CAPACITY>{}, // 64 K128 slots
        opus::number<T::VEC_SF>{}); // 4 replicated op_sel bytes

    constexpr auto block_dim = opus::make_tuple(
        opus::make_tuple(opus::p_dim{}),
        opus::make_tuple(opus::p_dim{}),
        opus::make_tuple(opus::y_dim{}));

    return opus::make_layout<T::VEC_SF>(
        block_shape,
        opus::unfold_x_stride(block_dim, block_shape, opus::tuple{opus::number<T::VEC_SF>{}, opus::number<T::SCALE_N_HALVES * T::VEC_SF>{}, 1_I}),
        opus::unfold_p_coord(block_dim, opus::tuple{wave_id, lane_id}));
}

template<class T, int Vec = T::VEC_SCALE_SF>
__device__ inline constexpr auto make_layout_rsfb_scale() {
    static_assert(Vec == T::VEC_SCALE_SF || Vec == T::VEC_SCALE_SF_PAIR);

    constexpr auto block_shape = opus::make_tuple(opus::number<Vec>{});
    constexpr auto block_dim = opus::make_tuple(
        opus::make_tuple(opus::y_dim{}));

    return opus::make_layout<Vec>(
        block_shape,
        opus::unfold_x_stride(block_dim, block_shape, opus::tuple{1_I}),
        opus::unfold_p_coord(block_dim, opus::tuple{}));
}

template<class Traits>
__global__ __launch_bounds__(Traits::BLOCK_SIZE, Traits::MIN_WGS_PER_CU) void gemm_a8w8_mxfp8_scale_kernel(opus_gemm_scale_kargs kargs) {
    using namespace opus;

    using T = opus::remove_cvref_t<Traits>;
    using D_A = opus::fp8_t;
    using D_B = opus::fp8_t;
    using D_C = std::conditional_t<T::OUTPUT_BF16, opus::bf16_t, opus::fp32_t>;
    using D_ACC = opus::fp32_t;
    using D_SF = unsigned char;
    using D_SF_PACK = unsigned int;

    // Tile and thread coordinates.
    int block_m = block_id_y();
    int block_n = block_id_x();
    if (((kargs.m | kargs.n) & 511) == 0) {
        const int old_m = block_m;
        block_m = (block_m & ~1) | (block_n & 1);
        block_n = (block_n & ~1) | (old_m & 1);
    }
    const int row = block_m * T::B_M;
    const int col = block_n * T::B_N;

    const int batch_id = block_id_z();
    const int wave_id = __builtin_amdgcn_readfirstlane(thread_id_x() / T::WARP_SIZE);
    const int lane_id = thread_id_x() % T::WARP_SIZE;

    // Matrix global-memory views.
    auto g_a = make_gmem(reinterpret_cast<const D_A*>(kargs.ptr_a) + batch_id * kargs.stride_a_batch + row * kargs.stride_a);
    auto g_b = make_gmem(reinterpret_cast<const D_B*>(kargs.ptr_b) + batch_id * kargs.stride_b_batch + col * kargs.stride_b);
    auto g_c = make_gmem(reinterpret_cast<D_C*>(kargs.ptr_c) + batch_id * kargs.stride_c_batch + row * kargs.stride_c + col);
    auto g_sfa = make_gmem(reinterpret_cast<const D_SF*>(kargs.ptr_sfa) + batch_id * kargs.stride_sfa_batch + row, static_cast<unsigned int>(kargs.stride_sfa_batch - row));
    auto g_sfb = make_gmem(reinterpret_cast<const D_SF*>(kargs.ptr_sfb) + batch_id * kargs.stride_sfb_batch + (col / T::GROUP_N + wave_id % T::SCALE_N_HALVES) * kargs.stride_sfb, static_cast<unsigned int>(kargs.stride_sfb));

    const int wave_id_m = wave_id % T::T_M;
    const int wave_id_n = wave_id / T::T_M;

    // Matrix layouts: global -> LDS -> registers.
    const auto u_ga = make_layout_ga_scale<T>(lane_id, wave_id_m, wave_id_n, kargs.stride_a);
    const auto u_sa = make_layout_sa_scale<T>(wave_id_m, wave_id_n);
    const auto u_ra = make_layout_ra_scale<T>(lane_id, wave_id_m);
    const auto u_gb = make_layout_gb_scale<T>(lane_id, wave_id_m, wave_id_n, kargs.stride_b);
    const auto u_sb = make_layout_sb_scale<T>(wave_id_m, wave_id_n);
    const auto u_rb = make_layout_rb_scale<T>(lane_id, wave_id_n);
    const auto u_gsfa = make_layout_gsfa_scale<T>(lane_id, wave_id_m, wave_id_n, kargs.stride_sfa);
    const auto u_ssfa = make_layout_ssfa_scale<T>(lane_id, wave_id_m, wave_id_n);
    const auto u_rsfa = make_layout_rsfa_scale<T>(lane_id, wave_id_m);
    const auto u_rsfa_pair = make_layout_rsfa_scale<T, T::VEC_SCALE_SF_PAIR>(lane_id, wave_id_m);
    const auto u_gsfb = make_layout_gsfb_scale<T>(lane_id, wave_id);
    const auto u_ssfb = make_layout_ssfb_scale<T>(lane_id, wave_id);
    const auto u_rsfb = make_layout_rsfb_scale<T>();
    const auto u_rsfb_pair = make_layout_rsfb_scale<T, T::VEC_SCALE_SF_PAIR>();

    // Matrix LDS; the same allocation is reused for the C epilogue.
    constexpr int smem_a_elem = T::smem_m_rep * (T::smem_linear_wave + T::smem_padding);
    constexpr int smem_b_elem = T::smem_n_rep * (T::smem_linear_wave + T::smem_padding);
    constexpr int matrix_lds_bytes = smem_a_elem * 4 * sizeof(D_A) + smem_b_elem * 4 * sizeof(D_B);
    alignas(16) __shared__ char smem_matrix[matrix_lds_bytes];
    auto s_a = make_smem(reinterpret_cast<D_A*>(smem_matrix));
    auto s_b = make_smem(reinterpret_cast<D_B*>(smem_matrix + smem_a_elem * 4 * sizeof(D_A)));
    auto s_c = make_smem(reinterpret_cast<D_C*>(smem_matrix));
    alignas(8) __shared__ char smem_sfa[T::SFA_PANEL_BYTES];
    alignas(8) __shared__ char smem_sfb[T::SFB_PANEL_BYTES];
    auto s_sfa = make_smem(reinterpret_cast<D_SF*>(smem_sfa));
    auto s_sfb = make_smem(reinterpret_cast<D_SF*>(smem_sfb));

    // MMA and register fragments.
    auto mma = make_tiled_mma<D_A, D_B, D_ACC>(
        seq<T::E_M, T::E_N, T::E_K>{},
        seq<T::T_M, T::T_N, T::T_K>{},
        seq<T::W_M, T::W_N, T::W_K>{},
        mfma_adaptor_swap_ab{});
    typename decltype(mma)::vtype_a v_a[2];
    typename decltype(mma)::vtype_b v_b;
    typename decltype(mma)::vtype_b v_b_second;
    using AccFragment = typename decltype(mma)::MMA::vtype_c;
    // Pinned C accumulators.
    __attribute__((amdgpu_pin_agpr(0))) AccFragment c00_0 = {};
    __attribute__((amdgpu_pin_agpr(4))) AccFragment c00_1 = {};
    __attribute__((amdgpu_pin_agpr(8))) AccFragment c00_2 = {};
    __attribute__((amdgpu_pin_agpr(12))) AccFragment c00_3 = {};
    __attribute__((amdgpu_pin_agpr(16))) AccFragment c00_4 = {};
    __attribute__((amdgpu_pin_agpr(20))) AccFragment c00_5 = {};
    __attribute__((amdgpu_pin_agpr(24))) AccFragment c00_6 = {};
    __attribute__((amdgpu_pin_agpr(28))) AccFragment c00_7 = {};
    __attribute__((amdgpu_pin_agpr(32))) AccFragment c00_8 = {};
    __attribute__((amdgpu_pin_agpr(36))) AccFragment c00_9 = {};
    __attribute__((amdgpu_pin_agpr(40))) AccFragment c00_10 = {};
    __attribute__((amdgpu_pin_agpr(44))) AccFragment c00_11 = {};
    __attribute__((amdgpu_pin_agpr(48))) AccFragment c00_12 = {};
    __attribute__((amdgpu_pin_agpr(52))) AccFragment c00_13 = {};
    __attribute__((amdgpu_pin_agpr(56))) AccFragment c00_14 = {};
    __attribute__((amdgpu_pin_agpr(60))) AccFragment c00_15 = {};
    __attribute__((amdgpu_pin_agpr(64))) AccFragment c01_0 = {};
    __attribute__((amdgpu_pin_agpr(68))) AccFragment c01_1 = {};
    __attribute__((amdgpu_pin_agpr(72))) AccFragment c01_2 = {};
    __attribute__((amdgpu_pin_agpr(76))) AccFragment c01_3 = {};
    __attribute__((amdgpu_pin_agpr(80))) AccFragment c01_4 = {};
    __attribute__((amdgpu_pin_agpr(84))) AccFragment c01_5 = {};
    __attribute__((amdgpu_pin_agpr(88))) AccFragment c01_6 = {};
    __attribute__((amdgpu_pin_agpr(92))) AccFragment c01_7 = {};
    __attribute__((amdgpu_pin_agpr(96))) AccFragment c01_8 = {};
    __attribute__((amdgpu_pin_agpr(100))) AccFragment c01_9 = {};
    __attribute__((amdgpu_pin_agpr(104))) AccFragment c01_10 = {};
    __attribute__((amdgpu_pin_agpr(108))) AccFragment c01_11 = {};
    __attribute__((amdgpu_pin_agpr(112))) AccFragment c01_12 = {};
    __attribute__((amdgpu_pin_agpr(116))) AccFragment c01_13 = {};
    __attribute__((amdgpu_pin_agpr(120))) AccFragment c01_14 = {};
    __attribute__((amdgpu_pin_agpr(124))) AccFragment c01_15 = {};
    __attribute__((amdgpu_pin_agpr(128))) AccFragment c10_0 = {};
    __attribute__((amdgpu_pin_agpr(132))) AccFragment c10_1 = {};
    __attribute__((amdgpu_pin_agpr(136))) AccFragment c10_2 = {};
    __attribute__((amdgpu_pin_agpr(140))) AccFragment c10_3 = {};
    __attribute__((amdgpu_pin_agpr(144))) AccFragment c10_4 = {};
    __attribute__((amdgpu_pin_agpr(148))) AccFragment c10_5 = {};
    __attribute__((amdgpu_pin_agpr(152))) AccFragment c10_6 = {};
    __attribute__((amdgpu_pin_agpr(156))) AccFragment c10_7 = {};
    __attribute__((amdgpu_pin_agpr(160))) AccFragment c10_8 = {};
    __attribute__((amdgpu_pin_agpr(164))) AccFragment c10_9 = {};
    __attribute__((amdgpu_pin_agpr(168))) AccFragment c10_10 = {};
    __attribute__((amdgpu_pin_agpr(172))) AccFragment c10_11 = {};
    __attribute__((amdgpu_pin_agpr(176))) AccFragment c10_12 = {};
    __attribute__((amdgpu_pin_agpr(180))) AccFragment c10_13 = {};
    __attribute__((amdgpu_pin_agpr(184))) AccFragment c10_14 = {};
    __attribute__((amdgpu_pin_agpr(188))) AccFragment c10_15 = {};
    __attribute__((amdgpu_pin_agpr(192))) AccFragment c11_0 = {};
    __attribute__((amdgpu_pin_agpr(196))) AccFragment c11_1 = {};
    __attribute__((amdgpu_pin_agpr(200))) AccFragment c11_2 = {};
    __attribute__((amdgpu_pin_agpr(204))) AccFragment c11_3 = {};
    __attribute__((amdgpu_pin_agpr(208))) AccFragment c11_4 = {};
    __attribute__((amdgpu_pin_agpr(212))) AccFragment c11_5 = {};
    __attribute__((amdgpu_pin_agpr(216))) AccFragment c11_6 = {};
    __attribute__((amdgpu_pin_agpr(220))) AccFragment c11_7 = {};
    __attribute__((amdgpu_pin_agpr(224))) AccFragment c11_8 = {};
    __attribute__((amdgpu_pin_agpr(228))) AccFragment c11_9 = {};
    __attribute__((amdgpu_pin_agpr(232))) AccFragment c11_10 = {};
    __attribute__((amdgpu_pin_agpr(236))) AccFragment c11_11 = {};
    __attribute__((amdgpu_pin_agpr(240))) AccFragment c11_12 = {};
    __attribute__((amdgpu_pin_agpr(244))) AccFragment c11_13 = {};
    __attribute__((amdgpu_pin_agpr(248))) AccFragment c11_14 = {};
    __attribute__((amdgpu_pin_agpr(252))) AccFragment c11_15 = {};
    // C row stride in D_C elements while staging BF16 output in LDS.
    constexpr int c_lds_row_stride_elems = T::B_N + 8;

    D_SF_PACK v_sfa[2];
    D_SF_PACK v_sfb[T::SCALE_N_HALVES];
    opus::vector_t<D_SF_PACK, 2> v_sfb_next;
    opus::vector_t<D_SF_PACK, 2> v_sfa_next;

    constexpr int scale_panel_mask = T::SCALE_PANEL_K_CAPACITY - 1;
    auto ga_offset = [&](int half_tile_m, int tile_k) { return half_tile_m * T::HALF_B_M * kargs.stride_a + tile_k * T::B_K; };
    auto gb_offset = [&](int half_tile_n, int tile_k) { return half_tile_n * T::HALF_B_N * kargs.stride_b + tile_k * T::B_K * 16; };
    auto sa_offset = [&](int stage, int half_tile_m) { return (stage * 2 + half_tile_m) * smem_a_elem; };
    auto sb_offset = [&](int stage, int half_tile_n) { return (stage * 2 + half_tile_n) * smem_b_elem; };
    auto gsfa_offset = [&](int panel_k_begin) { return panel_k_begin * kargs.stride_sfa; };
    auto gsfb_offset = [&](int panel_k_begin) { return panel_k_begin; };
    auto ssfa_offset = [&](int k_tile, int half_tile_m) { return (k_tile & scale_panel_mask) * T::SFA_PANEL_PITCH + half_tile_m * T::VEC_SCALE_SF; };
    auto ssfb_offset = [&](int k_tile, int half_tile_n) { return (k_tile & scale_panel_mask) * T::SCALE_N_HALVES * T::VEC_SCALE_SF + half_tile_n * T::VEC_SCALE_SF; };

    // A/B K tile buffer_load from global to lds
    const bool prefetches_a = wave_id_n == 0;
    auto g_matrix_prefetch = prefetches_a ? g_a : g_b; // g_a: wave_id 0/1  g_b: wave_id 2/3
    constexpr int a_k_lanes = T::B_K / T::VEC_A; // 128 / 16 = 8
    constexpr int matrix_lds_pitch = T::smem_linear_wave + T::smem_padding; // 1024 + 32
    const int matrix_lane_offset = prefetches_a ? (wave_id_m * T::HALF_B_M + (lane_id / a_k_lanes) * 2) * kargs.stride_a + (lane_id % a_k_lanes) * T::VEC_A : wave_id_m * T::HALF_B_N * kargs.stride_b + lane_id * T::VEC_B;
    const int matrix_pair_stride = 16 * kargs.stride_a;
    const int matrix_odd_stride = prefetches_a ? kargs.stride_a : T::WARP_SIZE * T::VEC_B;
    const int matrix_tile_stride = prefetches_a ? T::B_K : T::B_K * T::VEC_B; // A: 128 / B: 128 * 16
    auto* matrix_lds_base = (prefetches_a ? s_a.ptr : s_b.ptr) + wave_id_m * smem_a_elem; // A or B and half

    // 128 x 128, every wave need 16 buffer_load_dwordx4, divided 4 group, every group divided 4 local, each local's 8 rows are staggered between odd and even, mimicking 4-wave load
    opus::vector_t<int, 4> matrix_voffsets;
    opus::static_for<4>([&](auto local_i) { // 0/1/2/3
        constexpr int local = decltype(local_i)::value;
        constexpr int immediate = local * matrix_lds_pitch; // 0/1/2/3 * (1024 + 32)
        int voffset = matrix_lane_offset + (local / 2) * matrix_pair_stride + (local % 2) * matrix_odd_stride - immediate;
        asm volatile("" : "+v"(voffset));
        matrix_voffsets[local] = voffset;
    });

    // Issue one of the 16 producer-wave requests that copy a K128 matrix half tile directly from global memory to an LDS ping-pong slot.
    // issue_i: buffer_load request index [0, 15], group=issue/4 and local=issue%4. Four requests form one group.
    // matrix_stage: 0 or 1
    // tile_offset: global K tile offset
    auto issue_matrix_prefetch = [&](auto issue_i, int matrix_stage, int tile_offset) {
        constexpr int issue = decltype(issue_i)::value;
        constexpr int local = issue % 4;
        constexpr int group = issue / 4;
        constexpr int immediate = local * matrix_lds_pitch;
        auto* dst = matrix_lds_base + matrix_stage * 2 * smem_a_elem + group * 4 * matrix_lds_pitch;
        async_load<16>(
            g_matrix_prefetch,
            reinterpret_cast<void*>(reinterpret_cast<__UINTPTR_TYPE__>(dst)),
            static_cast<int>(matrix_voffsets[local]),
            __builtin_amdgcn_readfirstlane(tile_offset + group * 2 * matrix_pair_stride),
            opus::number<immediate>{},
            opus::number<0>{});
    };

    // Load Scale_A
    const int scale_k_groups = static_cast<unsigned int>(kargs.k) / T::GROUP_K;
    constexpr int sfa_lds_word_stride = T::VEC_SF * (T::B_M / T::HALF_B_M) * T::E_M; // 4 * （256 / 128）* 4 = 32
    const auto sfa_gmem_offsets = opus::layout_to_offsets<T::VEC_SCALE_A>(u_gsfa);
    const auto sfa_smem_offsets = opus::layout_to_offsets<T::VEC_SF>(u_ssfa);
    opus::vector_t<D_SF, T::VEC_SCALE_A> sfa_panel_raw[T::SFA_PASSES_PER_CACHE_PANEL];

    // Scale_A Global to VGPR
    auto load_sfa_panel = [&](int panel_k_begin) { // K<= 8192 panel_k_begin = 0
        opus::static_for<T::SFA_PASSES_PER_CACHE_PANEL>([&](auto pass_i) { // 0/1/2/3
            constexpr int pass = decltype(pass_i)::value;
            const int first_k_group = panel_k_begin + pass * T::SFA_K_COLUMNS_PER_PASS + wave_id * T::SFA_K_COLUMNS_PER_WAVE;
            // 0 + 0/1/2/3 * 16 + 0/1/2/3 * 4 
            // 8192/128 = 64 K groups, divided into 4 passes, with 16 K groups per pass. Each pass has 4 waves, and each wave consecutively loads 4 groups.
            if (first_k_group < scale_k_groups) {
                sfa_panel_raw[pass] = load<T::VEC_SCALE_A>(g_sfa, sfa_gmem_offsets[pass] + gsfa_offset(panel_k_begin));
            }
        });
        __builtin_amdgcn_sched_barrier(0);
    };

    // Scale_A VGPR transpose and to lds
    auto publish_sfa_panel = [&](int panel_k_begin) { // K<= 8192 panel_k_begin = 0
        const int lane_in_quad = lane_id % 4; // lane in quad 
        // quad 0: lane 0~3
        // quad 1: lane 4~7
        // ....
        /// quad 15: lane 60~63
        const unsigned int pair_byte_select = (lane_in_quad % 2) ? 0x03070105u : 0x06020400u;
        const unsigned int quad_byte_select = (lane_in_quad / 2) ? 0x03020706u : 0x05040100u;

        auto transpose_sfa_word_4x4 = [&](D_SF_PACK lane_word) {
            const D_SF_PACK adjacent_lane = opus::mov_dpp(lane_word, opus::number<0xb1>{});
            const D_SF_PACK paired_bytes = __builtin_amdgcn_perm(adjacent_lane, lane_word, pair_byte_select);
            const D_SF_PACK opposite_pair = opus::mov_dpp(paired_bytes, opus::number<0x4e>{});
            return __builtin_amdgcn_perm(opposite_pair, paired_bytes, quad_byte_select);
        };
        // Example 
        //                byte0   byte1   byte2   byte3 
        // lane 0         M0      M1      M2      M3                lane 0：[M0, M32, M64, M96]
        // lane 1         M32     M33     M34     M35      ---->    lane 1：[M1, M33, M65, M97]
        // lane 2         M64     M65     M66     M67               lane 2：[M2, M34, M66, M98]
        // lane 3         M96     M97     M98     M99               lane 3：[M3, M35, M67, M99]

        opus::static_for<T::SFA_PASSES_PER_CACHE_PANEL>([&](auto pass_i) { // 0/1/2/3
            constexpr int pass = decltype(pass_i)::value;
            const int first_k_group = panel_k_begin + pass * T::SFA_K_COLUMNS_PER_PASS + wave_id * T::SFA_K_COLUMNS_PER_WAVE;
            // 0 + 0/1/2/3 * 16 + 0/1/2/3 * 4 
            if (first_k_group < scale_k_groups) {
                const auto raw_words = __builtin_bit_cast(opus::vector_t<D_SF_PACK, 4>, sfa_panel_raw[pass]); // 16 = 4 x 4
                opus::static_for<4>([&](auto word_i) {
                    constexpr int word = decltype(word_i)::value;
                    // The 4x4 byte transpose happens here, entirely in VGPRs.
                    const D_SF_PACK packed_scales = transpose_sfa_word_4x4(raw_words[word]);
                    store<T::VEC_SF>(s_sfa, __builtin_bit_cast(opus::vector_t<D_SF, T::VEC_SF>, packed_scales), sfa_smem_offsets[pass] + word * sfa_lds_word_stride);
                });
            }
        });
    };

    // Refill the 64-K128 SFA and SFB LDS panels together at each panel boundary, sharing one synchronized LDS handoff.
    auto refill_scale_panel = [&](int next_tile) {
        if ((next_tile & scale_panel_mask) == 0) {
            __builtin_amdgcn_s_setprio(0);
            s_waitcnt_vmcnt(0_I);
            s_waitcnt_lgkmcnt(0_I);
            __builtin_amdgcn_s_barrier();
            __builtin_amdgcn_sched_barrier(0);
            load_sfa_panel(next_tile);
            D_SF_PACK raw_b = 0;
            if (wave_id < T::SCALE_N_HALVES) {
                const auto raw = load<1>(g_sfb, u_gsfb + gsfb_offset(next_tile));
                raw_b = static_cast<D_SF_PACK>(raw[0]);
            }
            s_waitcnt_vmcnt(0_I);
            publish_sfa_panel(next_tile);
            if (wave_id < T::SCALE_N_HALVES) {
                const D_SF_PACK packed = raw_b * 0x01010101u;
                store<T::VEC_SF>(s_sfb, __builtin_bit_cast(opus::vector_t<D_SF, T::VEC_SF>, packed), u_ssfb);
            }
            s_waitcnt_lgkmcnt(0_I);
            __builtin_amdgcn_s_barrier();
            __builtin_amdgcn_sched_barrier(0);
            __builtin_amdgcn_s_setprio(1);
        }
    };

    int stage = 0;
    int tile = 0;
    const int loops = static_cast<unsigned int>(kargs.k) / T::B_K;

    // ===== Prologue =====
    async_load<T::VEC_A>(g_a, s_a.ptr, u_ga, u_sa + sa_offset(0, 0), ga_offset(0, 0));
    async_load<T::VEC_A>(g_a, s_a.ptr, u_ga, u_sa + sa_offset(0, 1), ga_offset(1, 0));
    __builtin_amdgcn_sched_barrier(0);

    load_sfa_panel(0);
    asm volatile("" : : "a"(c00_0));
    asm volatile("" : : "a"(c00_1));
    asm volatile("" : : "a"(c00_2));
    asm volatile("" : : "a"(c00_3));
    asm volatile("" : : "a"(c00_4));
    asm volatile("" : : "a"(c00_5));
    asm volatile("" : : "a"(c00_6));
    asm volatile("" : : "a"(c00_7));
    asm volatile("" : : "a"(c00_8));
    asm volatile("" : : "a"(c00_9));
    asm volatile("" : : "a"(c00_10));
    asm volatile("" : : "a"(c00_11));
    asm volatile("" : : "a"(c00_12));
    asm volatile("" : : "a"(c00_13));
    asm volatile("" : : "a"(c00_14));
    asm volatile("" : : "a"(c00_15));
    asm volatile("" : : "a"(c01_0));
    asm volatile("" : : "a"(c01_1));
    asm volatile("" : : "a"(c01_2));
    asm volatile("" : : "a"(c01_3));
    asm volatile("" : : "a"(c01_4));
    asm volatile("" : : "a"(c01_5));
    asm volatile("" : : "a"(c01_6));
    asm volatile("" : : "a"(c01_7));
    asm volatile("" : : "a"(c01_8));
    asm volatile("" : : "a"(c01_9));
    asm volatile("" : : "a"(c01_10));
    asm volatile("" : : "a"(c01_11));
    asm volatile("" : : "a"(c01_12));
    asm volatile("" : : "a"(c01_13));
    asm volatile("" : : "a"(c01_14));
    asm volatile("" : : "a"(c01_15));

    D_SF_PACK panel_sfb_raw = 0;
    if (wave_id < T::SCALE_N_HALVES) {
        const auto raw = load<1>(g_sfb, u_gsfb + gsfb_offset(0));
        panel_sfb_raw = static_cast<D_SF_PACK>(raw[0]);
    }
    async_load<T::VEC_B>(g_b, s_b.ptr, u_gb, u_sb + sb_offset(0, 0), gb_offset(0, 0));
    async_load<T::VEC_B>(g_b, s_b.ptr, u_gb, u_sb + sb_offset(0, 1), gb_offset(1, 0));

    asm volatile("" : : "a"(c10_0));
    asm volatile("" : : "a"(c10_1));
    asm volatile("" : : "a"(c10_2));
    asm volatile("" : : "a"(c10_3));
    asm volatile("" : : "a"(c10_4));
    asm volatile("" : : "a"(c10_5));
    asm volatile("" : : "a"(c10_6));
    asm volatile("" : : "a"(c10_7));
    asm volatile("" : : "a"(c10_8));
    asm volatile("" : : "a"(c10_9));
    asm volatile("" : : "a"(c10_10));
    asm volatile("" : : "a"(c10_11));
    asm volatile("" : : "a"(c10_12));
    asm volatile("" : : "a"(c10_13));
    asm volatile("" : : "a"(c10_14));
    asm volatile("" : : "a"(c10_15));
    asm volatile("" : : "a"(c11_0));
    asm volatile("" : : "a"(c11_1));
    asm volatile("" : : "a"(c11_2));
    asm volatile("" : : "a"(c11_3));
    asm volatile("" : : "a"(c11_4));
    asm volatile("" : : "a"(c11_5));
    asm volatile("" : : "a"(c11_6));
    asm volatile("" : : "a"(c11_7));
    asm volatile("" : : "a"(c11_8));
    asm volatile("" : : "a"(c11_9));
    asm volatile("" : : "a"(c11_10));
    asm volatile("" : : "a"(c11_11));
    asm volatile("" : : "a"(c11_12));
    asm volatile("" : : "a"(c11_13));
    asm volatile("" : : "a"(c11_14));
    asm volatile("" : : "a"(c11_15));

    publish_sfa_panel(0);
    s_waitcnt_vmcnt(0_I);

    if (wave_id < T::SCALE_N_HALVES) {
        const D_SF_PACK packed = panel_sfb_raw * 0x01010101u;
        store<T::VEC_SF>(s_sfb, __builtin_bit_cast(opus::vector_t<D_SF, T::VEC_SF>, packed), u_ssfb);
    }

    s_waitcnt_lgkmcnt(0_I);
    __builtin_amdgcn_s_barrier();
    __builtin_amdgcn_sched_barrier(0);

    // Interleave K1 requests with independent K0 LDS reads.
    if (loops > 1) {
        opus::static_for<8>([&](auto initial_issue) {
            issue_matrix_prefetch(initial_issue, 1, matrix_tile_stride);
        });
        __builtin_amdgcn_sched_barrier(0);
    }

    v_sfa[0] = __builtin_bit_cast(D_SF_PACK, load<T::VEC_SCALE_SF>(s_sfa, u_rsfa + ssfa_offset(0, 0)));
    v_sfa[1] = __builtin_bit_cast(D_SF_PACK, load<T::VEC_SCALE_SF>(s_sfa, u_rsfa + ssfa_offset(0, 1)));
    v_sfb[0] = __builtin_bit_cast(D_SF_PACK, load<T::VEC_SCALE_SF>(s_sfb, u_rsfb + ssfb_offset(0, 0)));
    v_sfb[1] = __builtin_bit_cast(D_SF_PACK, load<T::VEC_SCALE_SF>(s_sfb, u_rsfb + ssfb_offset(0, 1)));
    v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 0));
    v_a[0] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 0));

    if (loops > 1) {
        opus::static_for<8>([&](auto initial_issue) {
            using Issue = opus::number<decltype(initial_issue)::value + 8>;
            issue_matrix_prefetch(Issue{}, 1, matrix_tile_stride);
        });
        __builtin_amdgcn_sched_barrier(0);
    }

    v_a[1] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 1));
    v_b_second = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 1));
    __builtin_amdgcn_sched_barrier(0);
    __builtin_amdgcn_s_setprio(1);

    // ===== Main loop =====
#pragma unroll 2
    for (; tile + 2 < loops; ++tile) {
        const int k_tile = tile;
        refill_scale_panel(k_tile + 1);
        const int next_stage = stage ^ 1;
        const int future_tile = k_tile + 2;
        int future_matrix_offset = future_tile * matrix_tile_stride;
        asm volatile("" : "+s"(future_matrix_offset));
        __builtin_amdgcn_sched_barrier(0);

        c00_0 = mma_scale_one<T, 0, 0, 0>(mma, v_a[0], v_b, c00_0, v_sfa[0], v_sfb[0]);
        c00_1 = mma_scale_one<T, 0, 0, 1>(mma, v_a[0], v_b, c00_1, v_sfa[0], v_sfb[0]);
        sched_barrier_pairs_scale();

        v_sfa_next = __builtin_bit_cast(opus::vector_t<D_SF_PACK, 2>, load<T::VEC_SCALE_SF_PAIR>(s_sfa, u_rsfa_pair + ssfa_offset(k_tile + 1, 0)));
        __builtin_amdgcn_sched_barrier(0);

        c00_2 = mma_scale_one<T, 0, 0, 2>(mma, v_a[0], v_b, c00_2, v_sfa[0], v_sfb[0]);
        c00_3 = mma_scale_one<T, 0, 0, 3>(mma, v_a[0], v_b, c00_3, v_sfa[0], v_sfb[0]);
        sched_barrier_pairs_scale();

        c00_4 = mma_scale_one<T, 0, 1, 0>(mma, v_a[0], v_b, c00_4, v_sfa[0], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);
        s_waitcnt_vmcnt(0_I);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();

        c00_5 = mma_scale_one<T, 0, 1, 1>(mma, v_a[0], v_b, c00_5, v_sfa[0], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        c00_6 = mma_scale_one<T, 0, 1, 2>(mma, v_a[0], v_b, c00_6, v_sfa[0], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        issue_matrix_prefetch(opus::number<0>{}, stage, future_matrix_offset);
        __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);
        __builtin_amdgcn_sched_barrier(0);

        c00_7 = mma_scale_one<T, 0, 1, 3>(mma, v_a[0], v_b, c00_7, v_sfa[0], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        c00_8 = mma_scale_one<T, 0, 2, 0>(mma, v_a[0], v_b, c00_8, v_sfa[0], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        issue_matrix_prefetch(opus::number<1>{}, stage, future_matrix_offset);
        __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);
        __builtin_amdgcn_sched_barrier(0);

        c00_9 = mma_scale_one<T, 0, 2, 1>(mma, v_a[0], v_b, c00_9, v_sfa[0], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        c00_10 = mma_scale_one<T, 0, 2, 2>(mma, v_a[0], v_b, c00_10, v_sfa[0], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);
        
        issue_matrix_prefetch(opus::number<2>{}, stage, future_matrix_offset);
        __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);
        __builtin_amdgcn_sched_barrier(0);

        c00_11 = mma_scale_one<T, 0, 2, 3>(mma, v_a[0], v_b, c00_11, v_sfa[0], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        c00_12 = mma_scale_one<T, 0, 3, 0>(mma, v_a[0], v_b, c00_12, v_sfa[0], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        issue_matrix_prefetch(opus::number<3>{}, stage, future_matrix_offset);
        __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);
        __builtin_amdgcn_sched_barrier(0);

        c00_13 = mma_scale_one<T, 0, 3, 1>(mma, v_a[0], v_b, c00_13, v_sfa[0], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        c00_14 = mma_scale_one<T, 0, 3, 2>(mma, v_a[0], v_b, c00_14, v_sfa[0], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        issue_matrix_prefetch(opus::number<4>{}, stage, future_matrix_offset);
        __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);
        __builtin_amdgcn_sched_barrier(0);

        c00_15 = mma_scale_one<T, 0, 3, 3>(mma, v_a[0], v_b, c00_15, v_sfa[0], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        // A half 1 x B half 0 -> C[1][0] (128x128 wave quadrant).
        c10_0 = mma_scale_one<T, 1, 0, 0>(mma, v_a[1], v_b, c10_0, v_sfa[1], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        issue_matrix_prefetch(opus::number<5>{}, stage, future_matrix_offset);
        __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);
        __builtin_amdgcn_sched_barrier(0);

        c10_1 = mma_scale_one<T, 1, 0, 1>(mma, v_a[1], v_b, c10_1, v_sfa[1], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        c10_2 = mma_scale_one<T, 1, 0, 2>(mma, v_a[1], v_b, c10_2, v_sfa[1], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        issue_matrix_prefetch(opus::number<6>{}, stage, future_matrix_offset);
        __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);
        __builtin_amdgcn_sched_barrier(0);

        c10_3 = mma_scale_one<T, 1, 0, 3>(mma, v_a[1], v_b, c10_3, v_sfa[1], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        v_sfb_next = __builtin_bit_cast(opus::vector_t<D_SF_PACK, 2>, load<T::VEC_SCALE_SF_PAIR>(s_sfb, u_rsfb_pair + ssfb_offset(k_tile + 1, 0)));
        __builtin_amdgcn_sched_barrier(0);

        c10_4 = mma_scale_one<T, 1, 1, 0>(mma, v_a[1], v_b, c10_4, v_sfa[1], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        issue_matrix_prefetch(opus::number<7>{}, stage, future_matrix_offset);
        __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);
        __builtin_amdgcn_sched_barrier(0);

        c10_5 = mma_scale_one<T, 1, 1, 1>(mma, v_a[1], v_b, c10_5, v_sfa[1], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        c10_6 = mma_scale_one<T, 1, 1, 2>(mma, v_a[1], v_b, c10_6, v_sfa[1], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        issue_matrix_prefetch(opus::number<8>{}, stage, future_matrix_offset);
        __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);
        __builtin_amdgcn_sched_barrier(0);

        c10_7 = mma_scale_one<T, 1, 1, 3>(mma, v_a[1], v_b, c10_7, v_sfa[1], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        c10_8 = mma_scale_one<T, 1, 2, 0>(mma, v_a[1], v_b, c10_8, v_sfa[1], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        issue_matrix_prefetch(opus::number<9>{}, stage, future_matrix_offset);
        __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);
        __builtin_amdgcn_sched_barrier(0);

        c10_9 = mma_scale_one<T, 1, 2, 1>(mma, v_a[1], v_b, c10_9, v_sfa[1], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        c10_10 = mma_scale_one<T, 1, 2, 2>(mma, v_a[1], v_b, c10_10, v_sfa[1], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        issue_matrix_prefetch(opus::number<10>{}, stage, future_matrix_offset);
        __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);
        __builtin_amdgcn_sched_barrier(0);

        c10_11 = mma_scale_one<T, 1, 2, 3>(mma, v_a[1], v_b, c10_11, v_sfa[1], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        c10_12 = mma_scale_one<T, 1, 3, 0>(mma, v_a[1], v_b, c10_12, v_sfa[1], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        issue_matrix_prefetch(opus::number<11>{}, stage, future_matrix_offset);
        __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);
        __builtin_amdgcn_sched_barrier(0);

        c10_13 = mma_scale_one<T, 1, 3, 1>(mma, v_a[1], v_b, c10_13, v_sfa[1], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        auto a0_m0_next_0 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 0))[0]);
        auto a0_m0_next_1 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 0))[1]);
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        c10_14 = mma_scale_one<T, 1, 3, 2>(mma, v_a[1], v_b, c10_14, v_sfa[1], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        c10_15 = mma_scale_one<T, 1, 3, 3>(mma, v_a[1], v_b, c10_15, v_sfa[1], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        auto b0_n0_next_0 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 0))[0]);
        auto b0_n0_next_1 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 0))[1]);
        opus::set_slice(v_b, b0_n0_next_0, opus::number<0>{}, opus::number<16>{});
        opus::set_slice(v_b, b0_n0_next_1, opus::number<16>{}, opus::number<32>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);


        // A half 0 x B half 1 -> C[0][1] (128x128 wave quadrant).
        c01_0 = mma_scale_one<T, 0, 0, 0>(mma, v_a[0], v_b_second, c01_0, v_sfa[0], v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);

        issue_matrix_prefetch(opus::number<12>{}, stage, future_matrix_offset);
        __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);
        __builtin_amdgcn_sched_barrier(0);

        c01_1 = mma_scale_one<T, 0, 0, 1>(mma, v_a[0], v_b_second, c01_1, v_sfa[0], v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);

        auto b0_n1_next_0 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 0))[2]);
        auto b0_n1_next_1 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 0))[3]);
        opus::set_slice(v_b, b0_n1_next_0, opus::number<32>{}, opus::number<48>{});
        opus::set_slice(v_b, b0_n1_next_1, opus::number<48>{}, opus::number<64>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        c01_2 = mma_scale_one<T, 0, 0, 2>(mma, v_a[0], v_b_second, c01_2, v_sfa[0], v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);
        c01_3 = mma_scale_one<T, 0, 0, 3>(mma, v_a[0], v_b_second, c01_3, v_sfa[0], v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);

        auto b0_n2_next_0 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 0))[4]);
        auto b0_n2_next_1 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 0))[5]);
        opus::set_slice(v_b, b0_n2_next_0, opus::number<64>{}, opus::number<80>{});
        opus::set_slice(v_b, b0_n2_next_1, opus::number<80>{}, opus::number<96>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        opus::set_slice(v_a[0], a0_m0_next_0, opus::number<0>{}, opus::number<16>{});
        opus::set_slice(v_a[0], a0_m0_next_1, opus::number<16>{}, opus::number<32>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);

        c01_4 = mma_scale_one<T, 0, 1, 0>(mma, v_a[0], v_b_second, c01_4, v_sfa[0], v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);

        issue_matrix_prefetch(opus::number<13>{}, stage, future_matrix_offset);
        __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);
        __builtin_amdgcn_sched_barrier(0);

        c01_5 = mma_scale_one<T, 0, 1, 1>(mma, v_a[0], v_b_second, c01_5, v_sfa[0], v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);

        auto b0_n3_next_0 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 0))[6]);
        auto b0_n3_next_1 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 0))[7]);
        opus::set_slice(v_b, b0_n3_next_0, opus::number<96>{}, opus::number<112>{});
        opus::set_slice(v_b, b0_n3_next_1, opus::number<112>{}, opus::number<128>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        v_sfb[0] = v_sfb_next[0];
        __builtin_amdgcn_sched_barrier(0);

        c01_6 = mma_scale_one<T, 0, 1, 2>(mma, v_a[0], v_b_second, c01_6, v_sfa[0], v_sfb[1]);
        c01_7 = mma_scale_one<T, 0, 1, 3>(mma, v_a[0], v_b_second, c01_7, v_sfa[0], v_sfb[1]);
        sched_barrier_pairs_scale();

        if constexpr (T::OUTPUT_BF16) {
            issue_matrix_prefetch(opus::number<14>{}, stage, future_matrix_offset);
            __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);
            __builtin_amdgcn_sched_barrier(0);
        }

        auto a0_m1_next_0 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 0))[2]);
        auto a0_m1_next_1 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 0))[3]);
        opus::set_slice(v_a[0], a0_m1_next_0, opus::number<32>{}, opus::number<48>{});
        opus::set_slice(v_a[0], a0_m1_next_1, opus::number<48>{}, opus::number<64>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);

        c01_8 = mma_scale_one<T, 0, 2, 0>(mma, v_a[0], v_b_second, c01_8, v_sfa[0], v_sfb[1]);
        c01_9 = mma_scale_one<T, 0, 2, 1>(mma, v_a[0], v_b_second, c01_9, v_sfa[0], v_sfb[1]);
        sched_barrier_pairs_scale();

        if constexpr (!T::OUTPUT_BF16) {
            issue_matrix_prefetch(opus::number<14>{}, stage, future_matrix_offset);
            __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);
            __builtin_amdgcn_sched_barrier(0);
        }

        c01_10 = mma_scale_one<T, 0, 2, 2>(mma, v_a[0], v_b_second, c01_10, v_sfa[0], v_sfb[1]);
        c01_11 = mma_scale_one<T, 0, 2, 3>(mma, v_a[0], v_b_second, c01_11, v_sfa[0], v_sfb[1]);
        sched_barrier_pairs_scale();

        if constexpr (T::OUTPUT_BF16) {
            issue_matrix_prefetch(opus::number<15>{}, stage, future_matrix_offset);
            __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);
            __builtin_amdgcn_sched_barrier(0);
        }

        auto a0_m2_next_0 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 0))[4]);
        auto a0_m2_next_1 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 0))[5]);
        opus::set_slice(v_a[0], a0_m2_next_0, opus::number<64>{}, opus::number<80>{});
        opus::set_slice(v_a[0], a0_m2_next_1, opus::number<80>{}, opus::number<96>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);

        c01_12 = mma_scale_one<T, 0, 3, 0>(mma, v_a[0], v_b_second, c01_12, v_sfa[0], v_sfb[1]);
        c01_13 = mma_scale_one<T, 0, 3, 1>(mma, v_a[0], v_b_second, c01_13, v_sfa[0], v_sfb[1]);
        sched_barrier_pairs_scale();

        if constexpr (!T::OUTPUT_BF16) {
            issue_matrix_prefetch(opus::number<15>{}, stage, future_matrix_offset);
            __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);
            __builtin_amdgcn_sched_barrier(0);
        }

        c01_14 = mma_scale_one<T, 0, 3, 2>(mma, v_a[0], v_b_second, c01_14, v_sfa[0], v_sfb[1]);
        c01_15 = mma_scale_one<T, 0, 3, 3>(mma, v_a[0], v_b_second, c01_15, v_sfa[0], v_sfb[1]);
        sched_barrier_pairs_scale();

        __builtin_amdgcn_sched_barrier(0);
        v_sfa[0] = v_sfa_next[0];
        auto a0_m3_next_0 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 0))[6]);
        auto a0_m3_next_1 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 0))[7]);
        opus::set_slice(v_a[0], a0_m3_next_0, opus::number<96>{}, opus::number<112>{});
        opus::set_slice(v_a[0], a0_m3_next_1, opus::number<112>{}, opus::number<128>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        c11_0 = mma_scale_one<T, 1, 0, 0>(mma, v_a[1], v_b_second, c11_0, v_sfa[1], v_sfb[1]);
        c11_1 = mma_scale_one<T, 1, 0, 1>(mma, v_a[1], v_b_second, c11_1, v_sfa[1], v_sfb[1]);
        sched_barrier_pairs_scale();

        c11_2 = mma_scale_one<T, 1, 0, 2>(mma, v_a[1], v_b_second, c11_2, v_sfa[1], v_sfb[1]);
        c11_3 = mma_scale_one<T, 1, 0, 3>(mma, v_a[1], v_b_second, c11_3, v_sfa[1], v_sfb[1]);
        sched_barrier_pairs_scale();
        __builtin_amdgcn_sched_barrier(0);

        auto a1_m0_next_0 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 1))[0]);
        auto a1_m0_next_1 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 1))[1]);
        opus::set_slice(v_a[1], a1_m0_next_0, opus::number<0>{}, opus::number<16>{});
        opus::set_slice(v_a[1], a1_m0_next_1, opus::number<16>{}, opus::number<32>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        c11_4 = mma_scale_one<T, 1, 1, 0>(mma, v_a[1], v_b_second, c11_4, v_sfa[1], v_sfb[1]);
        c11_5 = mma_scale_one<T, 1, 1, 1>(mma, v_a[1], v_b_second, c11_5, v_sfa[1], v_sfb[1]);
        sched_barrier_pairs_scale();

        auto b1_n3_next_0 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 1))[6]);
        auto b1_n3_next_1 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 1))[7]);
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        c11_6 = mma_scale_one<T, 1, 1, 2>(mma, v_a[1], v_b_second, c11_6, v_sfa[1], v_sfb[1]);
        c11_7 = mma_scale_one<T, 1, 1, 3>(mma, v_a[1], v_b_second, c11_7, v_sfa[1], v_sfb[1]);
        sched_barrier_pairs_scale();

        __builtin_amdgcn_sched_barrier(0);
        auto a1_m1_next_0 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 1))[2]);
        auto a1_m1_next_1 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 1))[3]);
        opus::set_slice(v_a[1], a1_m1_next_0, opus::number<32>{}, opus::number<48>{});
        opus::set_slice(v_a[1], a1_m1_next_1, opus::number<48>{}, opus::number<64>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        auto a1_m3_next_0 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 1))[6]);
        auto a1_m3_next_1 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 1))[7]);
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        c11_8 = mma_scale_one<T, 1, 2, 0>(mma, v_a[1], v_b_second, c11_8, v_sfa[1], v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);

        c11_12 = mma_scale_one<T, 1, 3, 0>(mma, v_a[1], v_b_second, c11_12, v_sfa[1], v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);
        
        auto b1_n0_next_0 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 1))[0]);
        auto b1_n0_next_1 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 1))[1]);
        opus::set_slice(v_b_second, b1_n0_next_0, opus::number<0>{}, opus::number<16>{});
        opus::set_slice(v_b_second, b1_n0_next_1, opus::number<16>{}, opus::number<32>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        c11_9 = mma_scale_one<T, 1, 2, 1>(mma, v_a[1], v_b_second, c11_9, v_sfa[1], v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);

        c11_13 = mma_scale_one<T, 1, 3, 1>(mma, v_a[1], v_b_second, c11_13, v_sfa[1], v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);
        auto b1_n1_next_0 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 1))[2]);
        auto b1_n1_next_1 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 1))[3]);
        opus::set_slice(v_b_second, b1_n1_next_0, opus::number<32>{}, opus::number<48>{});
        opus::set_slice(v_b_second, b1_n1_next_1, opus::number<48>{}, opus::number<64>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        c11_10 = mma_scale_one<T, 1, 2, 2>(mma, v_a[1], v_b_second, c11_10, v_sfa[1], v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);

        c11_14 = mma_scale_one<T, 1, 3, 2>(mma, v_a[1], v_b_second, c11_14, v_sfa[1], v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);
        auto b1_n2_next_0 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 1))[4]);
        auto b1_n2_next_1 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 1))[5]);
        opus::set_slice(v_b_second, b1_n2_next_0, opus::number<64>{}, opus::number<80>{});
        opus::set_slice(v_b_second, b1_n2_next_1, opus::number<80>{}, opus::number<96>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        c11_11 = mma_scale_one<T, 1, 2, 3>(mma, v_a[1], v_b_second, c11_11, v_sfa[1], v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);
        auto a1_m2_next_0 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 1))[4]);
        auto a1_m2_next_1 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 1))[5]);
        opus::set_slice(v_a[1], a1_m2_next_0, opus::number<64>{}, opus::number<80>{});
        opus::set_slice(v_a[1], a1_m2_next_1, opus::number<80>{}, opus::number<96>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        c11_15 = mma_scale_one<T, 1, 3, 3>(mma, v_a[1], v_b_second, c11_15, v_sfa[1], v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);
        opus::set_slice(v_a[1], a1_m3_next_0, opus::number<96>{}, opus::number<112>{});
        opus::set_slice(v_a[1], a1_m3_next_1, opus::number<112>{}, opus::number<128>{});
        opus::set_slice(v_b_second, b1_n3_next_0, opus::number<96>{}, opus::number<112>{});
        opus::set_slice(v_b_second, b1_n3_next_1, opus::number<112>{}, opus::number<128>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 4, 0);
        __builtin_amdgcn_sched_barrier(0);

        v_sfb[1] = v_sfb_next[1];
        v_sfa[1] = v_sfa_next[1];
        stage = next_stage;
    }

    // ===== Epilogue =====
    if (loops > 1) {
        refill_scale_panel(tile + 1);
        const int next_stage = stage ^ 1;
        __builtin_amdgcn_sched_barrier(0);
        __builtin_amdgcn_s_setprio(1);

        // A half 0 x B half 0 -> C[0][0] (128x128 wave quadrant).
        c00_0 = mma_scale_one<T, 0, 0, 0>(mma, v_a[0], v_b, c00_0, v_sfa[0], v_sfb[0]);
        c00_1 = mma_scale_one<T, 0, 0, 1>(mma, v_a[0], v_b, c00_1, v_sfa[0], v_sfb[0]);
        sched_barrier_pairs_scale();

        v_sfa_next = __builtin_bit_cast(opus::vector_t<D_SF_PACK, 2>, load<T::VEC_SCALE_SF_PAIR>(s_sfa, u_rsfa_pair + ssfa_offset(tile + 1, 0)));
        __builtin_amdgcn_sched_barrier(0);

        c00_2 = mma_scale_one<T, 0, 0, 2>(mma, v_a[0], v_b, c00_2, v_sfa[0], v_sfb[0]);
        c00_3 = mma_scale_one<T, 0, 0, 3>(mma, v_a[0], v_b, c00_3, v_sfa[0], v_sfb[0]);
        sched_barrier_pairs_scale();

        c00_4 = mma_scale_one<T, 0, 1, 0>(mma, v_a[0], v_b, c00_4, v_sfa[0], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);
        __builtin_amdgcn_s_setprio(0);
        s_waitcnt_vmcnt(0_I);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_s_setprio(1);

        c00_5 = mma_scale_one<T, 0, 1, 1>(mma, v_a[0], v_b, c00_5, v_sfa[0], v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

        c00_6 = mma_scale_one<T, 0, 1, 2>(mma, v_a[0], v_b, c00_6, v_sfa[0], v_sfb[0]);
        c00_7 = mma_scale_one<T, 0, 1, 3>(mma, v_a[0], v_b, c00_7, v_sfa[0], v_sfb[0]);
        sched_barrier_pairs_scale();

        c00_8 = mma_scale_one<T, 0, 2, 0>(mma, v_a[0], v_b, c00_8, v_sfa[0], v_sfb[0]);
        c00_9 = mma_scale_one<T, 0, 2, 1>(mma, v_a[0], v_b, c00_9, v_sfa[0], v_sfb[0]);
        sched_barrier_pairs_scale();

        c00_10 = mma_scale_one<T, 0, 2, 2>(mma, v_a[0], v_b, c00_10, v_sfa[0], v_sfb[0]);
        c00_11 = mma_scale_one<T, 0, 2, 3>(mma, v_a[0], v_b, c00_11, v_sfa[0], v_sfb[0]);
        sched_barrier_pairs_scale();

        c00_12 = mma_scale_one<T, 0, 3, 0>(mma, v_a[0], v_b, c00_12, v_sfa[0], v_sfb[0]);
        c00_13 = mma_scale_one<T, 0, 3, 1>(mma, v_a[0], v_b, c00_13, v_sfa[0], v_sfb[0]);
        sched_barrier_pairs_scale();

        c00_14 = mma_scale_one<T, 0, 3, 2>(mma, v_a[0], v_b, c00_14, v_sfa[0], v_sfb[0]);
        c00_15 = mma_scale_one<T, 0, 3, 3>(mma, v_a[0], v_b, c00_15, v_sfa[0], v_sfb[0]);
        sched_barrier_pairs_scale();

        // A half 1 x B half 0 -> C[1][0] (128x128 wave quadrant).
        c10_0 = mma_scale_one<T, 1, 0, 0>(mma, v_a[1], v_b, c10_0, v_sfa[1], v_sfb[0]);
        c10_1 = mma_scale_one<T, 1, 0, 1>(mma, v_a[1], v_b, c10_1, v_sfa[1], v_sfb[0]);
        sched_barrier_pairs_scale();

        c10_2 = mma_scale_one<T, 1, 0, 2>(mma, v_a[1], v_b, c10_2, v_sfa[1], v_sfb[0]);
        c10_3 = mma_scale_one<T, 1, 0, 3>(mma, v_a[1], v_b, c10_3, v_sfa[1], v_sfb[0]);
        sched_barrier_pairs_scale();

        v_sfb_next = __builtin_bit_cast(opus::vector_t<D_SF_PACK, 2>, load<T::VEC_SCALE_SF_PAIR>(s_sfb, u_rsfb_pair + ssfb_offset(tile + 1, 0)));
        __builtin_amdgcn_sched_barrier(0);

        c10_4 = mma_scale_one<T, 1, 1, 0>(mma, v_a[1], v_b, c10_4, v_sfa[1], v_sfb[0]);
        c10_5 = mma_scale_one<T, 1, 1, 1>(mma, v_a[1], v_b, c10_5, v_sfa[1], v_sfb[0]);
        sched_barrier_pairs_scale();

        c10_6 = mma_scale_one<T, 1, 1, 2>(mma, v_a[1], v_b, c10_6, v_sfa[1], v_sfb[0]);
        c10_7 = mma_scale_one<T, 1, 1, 3>(mma, v_a[1], v_b, c10_7, v_sfa[1], v_sfb[0]);
        sched_barrier_pairs_scale();

        c10_8 = mma_scale_one<T, 1, 2, 0>(mma, v_a[1], v_b, c10_8, v_sfa[1], v_sfb[0]);
        c10_9 = mma_scale_one<T, 1, 2, 1>(mma, v_a[1], v_b, c10_9, v_sfa[1], v_sfb[0]);
        sched_barrier_pairs_scale();

        c10_10 = mma_scale_one<T, 1, 2, 2>(mma, v_a[1], v_b, c10_10, v_sfa[1], v_sfb[0]);
        c10_11 = mma_scale_one<T, 1, 2, 3>(mma, v_a[1], v_b, c10_11, v_sfa[1], v_sfb[0]);
        sched_barrier_pairs_scale();

        c10_12 = mma_scale_one<T, 1, 3, 0>(mma, v_a[1], v_b, c10_12, v_sfa[1], v_sfb[0]);
        c10_13 = mma_scale_one<T, 1, 3, 1>(mma, v_a[1], v_b, c10_13, v_sfa[1], v_sfb[0]);
        sched_barrier_pairs_scale();

        auto a0_m0_next_0 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 0))[0]);
        auto a0_m0_next_1 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 0))[1]);
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        c10_14 = mma_scale_one<T, 1, 3, 2>(mma, v_a[1], v_b, c10_14, v_sfa[1], v_sfb[0]);
        c10_15 = mma_scale_one<T, 1, 3, 3>(mma, v_a[1], v_b, c10_15, v_sfa[1], v_sfb[0]);
        sched_barrier_pairs_scale();

        auto b0_n0_next_0 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 0))[0]);
        auto b0_n0_next_1 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 0))[1]);
        opus::set_slice(v_b, b0_n0_next_0, opus::number<0>{}, opus::number<16>{});
        opus::set_slice(v_b, b0_n0_next_1, opus::number<16>{}, opus::number<32>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);


        // A half 0 x B half 1 -> C[0][1] (128x128 wave quadrant).
        c01_0 = mma_scale_one<T, 0, 0, 0>(mma, v_a[0], v_b_second, c01_0, v_sfa[0], v_sfb[1]);
        c01_1 = mma_scale_one<T, 0, 0, 1>(mma, v_a[0], v_b_second, c01_1, v_sfa[0], v_sfb[1]);
        sched_barrier_pairs_scale();

        auto b0_n1_next_0 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 0))[2]);
        auto b0_n1_next_1 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 0))[3]);
        opus::set_slice(v_b, b0_n1_next_0, opus::number<32>{}, opus::number<48>{});
        opus::set_slice(v_b, b0_n1_next_1, opus::number<48>{}, opus::number<64>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        c01_2 = mma_scale_one<T, 0, 0, 2>(mma, v_a[0], v_b_second, c01_2, v_sfa[0], v_sfb[1]);
        c01_3 = mma_scale_one<T, 0, 0, 3>(mma, v_a[0], v_b_second, c01_3, v_sfa[0], v_sfb[1]);
        sched_barrier_pairs_scale();

        auto b0_n2_next_0 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 0))[4]);
        auto b0_n2_next_1 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 0))[5]);
        opus::set_slice(v_b, b0_n2_next_0, opus::number<64>{}, opus::number<80>{});
        opus::set_slice(v_b, b0_n2_next_1, opus::number<80>{}, opus::number<96>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        opus::set_slice(v_a[0], a0_m0_next_0, opus::number<0>{}, opus::number<16>{});
        opus::set_slice(v_a[0], a0_m0_next_1, opus::number<16>{}, opus::number<32>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);

        __builtin_amdgcn_s_setprio(1);

        c01_4 = mma_scale_one<T, 0, 1, 0>(mma, v_a[0], v_b_second, c01_4, v_sfa[0], v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);

        c01_5 = mma_scale_one<T, 0, 1, 1>(mma, v_a[0], v_b_second, c01_5, v_sfa[0], v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);

        auto b0_n3_next_0 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 0))[6]);
        auto b0_n3_next_1 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 0))[7]);
        opus::set_slice(v_b, b0_n3_next_0, opus::number<96>{}, opus::number<112>{});
        opus::set_slice(v_b, b0_n3_next_1, opus::number<112>{}, opus::number<128>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        v_sfb[0] = v_sfb_next[0];
        __builtin_amdgcn_sched_barrier(0);

        c01_6 = mma_scale_one<T, 0, 1, 2>(mma, v_a[0], v_b_second, c01_6, v_sfa[0], v_sfb[1]);
        c01_7 = mma_scale_one<T, 0, 1, 3>(mma, v_a[0], v_b_second, c01_7, v_sfa[0], v_sfb[1]);
        sched_barrier_pairs_scale();

        auto a0_m1_next_0 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 0))[2]);
        auto a0_m1_next_1 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 0))[3]);
        opus::set_slice(v_a[0], a0_m1_next_0, opus::number<32>{}, opus::number<48>{});
        opus::set_slice(v_a[0], a0_m1_next_1, opus::number<48>{}, opus::number<64>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);

        c01_8 = mma_scale_one<T, 0, 2, 0>(mma, v_a[0], v_b_second, c01_8, v_sfa[0], v_sfb[1]);
        c01_9 = mma_scale_one<T, 0, 2, 1>(mma, v_a[0], v_b_second, c01_9, v_sfa[0], v_sfb[1]);
        sched_barrier_pairs_scale();

        c01_10 = mma_scale_one<T, 0, 2, 2>(mma, v_a[0], v_b_second, c01_10, v_sfa[0], v_sfb[1]);
        c01_11 = mma_scale_one<T, 0, 2, 3>(mma, v_a[0], v_b_second, c01_11, v_sfa[0], v_sfb[1]);
        sched_barrier_pairs_scale();

        auto a0_m2_next_0 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 0))[4]);
        auto a0_m2_next_1 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 0))[5]);
        opus::set_slice(v_a[0], a0_m2_next_0, opus::number<64>{}, opus::number<80>{});
        opus::set_slice(v_a[0], a0_m2_next_1, opus::number<80>{}, opus::number<96>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);

        c01_12 = mma_scale_one<T, 0, 3, 0>(mma, v_a[0], v_b_second, c01_12, v_sfa[0], v_sfb[1]);
        c01_13 = mma_scale_one<T, 0, 3, 1>(mma, v_a[0], v_b_second, c01_13, v_sfa[0], v_sfb[1]);
        sched_barrier_pairs_scale();

        c01_14 = mma_scale_one<T, 0, 3, 2>(mma, v_a[0], v_b_second, c01_14, v_sfa[0], v_sfb[1]);
        c01_15 = mma_scale_one<T, 0, 3, 3>(mma, v_a[0], v_b_second, c01_15, v_sfa[0], v_sfb[1]);
        sched_barrier_pairs_scale();
        __builtin_amdgcn_sched_barrier(0);

        v_sfa[0] = v_sfa_next[0];
        auto a0_m3_next_0 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 0))[6]);
        auto a0_m3_next_1 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 0))[7]);
        opus::set_slice(v_a[0], a0_m3_next_0, opus::number<96>{}, opus::number<112>{});
        opus::set_slice(v_a[0], a0_m3_next_1, opus::number<112>{}, opus::number<128>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        c11_0 = mma_scale_one<T, 1, 0, 0>(mma, v_a[1], v_b_second, c11_0, v_sfa[1], v_sfb[1]);
        c11_1 = mma_scale_one<T, 1, 0, 1>(mma, v_a[1], v_b_second, c11_1, v_sfa[1], v_sfb[1]);
        sched_barrier_pairs_scale();

        c11_2 = mma_scale_one<T, 1, 0, 2>(mma, v_a[1], v_b_second, c11_2, v_sfa[1], v_sfb[1]);
        c11_3 = mma_scale_one<T, 1, 0, 3>(mma, v_a[1], v_b_second, c11_3, v_sfa[1], v_sfb[1]);
        sched_barrier_pairs_scale();
        __builtin_amdgcn_sched_barrier(0);

        auto a1_m0_next_0 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 1))[0]);
        auto a1_m0_next_1 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 1))[1]);
        opus::set_slice(v_a[1], a1_m0_next_0, opus::number<0>{}, opus::number<16>{});
        opus::set_slice(v_a[1], a1_m0_next_1, opus::number<16>{}, opus::number<32>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        c11_4 = mma_scale_one<T, 1, 1, 0>(mma, v_a[1], v_b_second, c11_4, v_sfa[1], v_sfb[1]);
        c11_5 = mma_scale_one<T, 1, 1, 1>(mma, v_a[1], v_b_second, c11_5, v_sfa[1], v_sfb[1]);
        sched_barrier_pairs_scale();

        auto b1_n3_next_0 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 1))[6]);
        auto b1_n3_next_1 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 1))[7]);
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        c11_6 = mma_scale_one<T, 1, 1, 2>(mma, v_a[1], v_b_second, c11_6, v_sfa[1], v_sfb[1]);
        c11_7 = mma_scale_one<T, 1, 1, 3>(mma, v_a[1], v_b_second, c11_7, v_sfa[1], v_sfb[1]);
        sched_barrier_pairs_scale();
        __builtin_amdgcn_sched_barrier(0);

        auto a1_m1_next_0 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 1))[2]);
        auto a1_m1_next_1 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 1))[3]);
        opus::set_slice(v_a[1], a1_m1_next_0, opus::number<32>{}, opus::number<48>{});
        opus::set_slice(v_a[1], a1_m1_next_1, opus::number<48>{}, opus::number<64>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        auto a1_m3_next_0 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 1))[6]);
        auto a1_m3_next_1 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 1))[7]);
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        c11_8 = mma_scale_one<T, 1, 2, 0>(mma, v_a[1], v_b_second, c11_8, v_sfa[1], v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);

        c11_12 = mma_scale_one<T, 1, 3, 0>(mma, v_a[1], v_b_second, c11_12, v_sfa[1], v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);

        auto b1_n0_next_0 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 1))[0]);
        auto b1_n0_next_1 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 1))[1]);
        opus::set_slice(v_b_second, b1_n0_next_0, opus::number<0>{}, opus::number<16>{});
        opus::set_slice(v_b_second, b1_n0_next_1, opus::number<16>{}, opus::number<32>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        c11_9 = mma_scale_one<T, 1, 2, 1>(mma, v_a[1], v_b_second, c11_9, v_sfa[1], v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);

        c11_13 = mma_scale_one<T, 1, 3, 1>(mma, v_a[1], v_b_second, c11_13, v_sfa[1], v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);

        auto b1_n1_next_0 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 1))[2]);
        auto b1_n1_next_1 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 1))[3]);
        opus::set_slice(v_b_second, b1_n1_next_0, opus::number<32>{}, opus::number<48>{});
        opus::set_slice(v_b_second, b1_n1_next_1, opus::number<48>{}, opus::number<64>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        c11_10 = mma_scale_one<T, 1, 2, 2>(mma, v_a[1], v_b_second, c11_10, v_sfa[1], v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);

        c11_14 = mma_scale_one<T, 1, 3, 2>(mma, v_a[1], v_b_second, c11_14, v_sfa[1], v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);

        auto b1_n2_next_0 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 1))[4]);
        auto b1_n2_next_1 = load<16>(s_b, opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(next_stage, 1))[5]);
        opus::set_slice(v_b_second, b1_n2_next_0, opus::number<64>{}, opus::number<80>{});
        opus::set_slice(v_b_second, b1_n2_next_1, opus::number<80>{}, opus::number<96>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        c11_11 = mma_scale_one<T, 1, 2, 3>(mma, v_a[1], v_b_second, c11_11, v_sfa[1], v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);

        auto a1_m2_next_0 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 1))[4]);
        auto a1_m2_next_1 = load<16>(s_a, opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 1))[5]);
        opus::set_slice(v_a[1], a1_m2_next_0, opus::number<64>{}, opus::number<80>{});
        opus::set_slice(v_a[1], a1_m2_next_1, opus::number<80>{}, opus::number<96>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);

        c11_15 = mma_scale_one<T, 1, 3, 3>(mma, v_a[1], v_b_second, c11_15, v_sfa[1], v_sfb[1]);
        __builtin_amdgcn_sched_barrier(0);

        opus::set_slice(v_a[1], a1_m3_next_0, opus::number<96>{}, opus::number<112>{});
        opus::set_slice(v_a[1], a1_m3_next_1, opus::number<112>{}, opus::number<128>{});
        opus::set_slice(v_b_second, b1_n3_next_0, opus::number<96>{}, opus::number<112>{});
        opus::set_slice(v_b_second, b1_n3_next_1, opus::number<112>{}, opus::number<128>{});
        __builtin_amdgcn_sched_group_barrier(0x100, 4, 0);
        __builtin_amdgcn_sched_barrier(0);

        __builtin_amdgcn_s_setprio(0);
        v_sfb[1] = v_sfb_next[1];
        v_sfa[1] = v_sfa_next[1];
        stage = next_stage;
    }

    // Final K tile
    if constexpr (!T::OUTPUT_BF16) {
        v_a[1] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 1));
    }

    if constexpr (!T::OUTPUT_BF16) s_waitcnt_lgkmcnt(0_I);
    if constexpr (!T::OUTPUT_BF16) {
        v_sfb[1] = __builtin_bit_cast(D_SF_PACK,
            load<T::VEC_SCALE_SF>(s_sfb, u_rsfb + ssfb_offset(loops - 1, 1)));
    }
    __builtin_amdgcn_s_setprio(1);
    c00_0 = mma_scale_one<T, 0, 0, 0>(mma, v_a[0], v_b, c00_0, v_sfa[0], v_sfb[0]);
    c00_1 = mma_scale_one<T, 0, 0, 1>(mma, v_a[0], v_b, c00_1, v_sfa[0], v_sfb[0]);
    sched_barrier_pairs_scale();

    c00_2 = mma_scale_one<T, 0, 0, 2>(mma, v_a[0], v_b, c00_2, v_sfa[0], v_sfb[0]);
    c00_3 = mma_scale_one<T, 0, 0, 3>(mma, v_a[0], v_b, c00_3, v_sfa[0], v_sfb[0]);
    sched_barrier_pairs_scale();

    c00_4 = mma_scale_one<T, 0, 1, 0>(mma, v_a[0], v_b, c00_4, v_sfa[0], v_sfb[0]);
    c00_5 = mma_scale_one<T, 0, 1, 1>(mma, v_a[0], v_b, c00_5, v_sfa[0], v_sfb[0]);
    sched_barrier_pairs_scale();

    c00_6 = mma_scale_one<T, 0, 1, 2>(mma, v_a[0], v_b, c00_6, v_sfa[0], v_sfb[0]);
    c00_7 = mma_scale_one<T, 0, 1, 3>(mma, v_a[0], v_b, c00_7, v_sfa[0], v_sfb[0]);
    sched_barrier_pairs_scale();

    c00_8 = mma_scale_one<T, 0, 2, 0>(mma, v_a[0], v_b, c00_8, v_sfa[0], v_sfb[0]);
    c00_9 = mma_scale_one<T, 0, 2, 1>(mma, v_a[0], v_b, c00_9, v_sfa[0], v_sfb[0]);
    sched_barrier_pairs_scale();

    c00_10 = mma_scale_one<T, 0, 2, 2>(mma, v_a[0], v_b, c00_10, v_sfa[0], v_sfb[0]);
    c00_11 = mma_scale_one<T, 0, 2, 3>(mma, v_a[0], v_b, c00_11, v_sfa[0], v_sfb[0]);
    sched_barrier_pairs_scale();

    c00_12 = mma_scale_one<T, 0, 3, 0>(mma, v_a[0], v_b, c00_12, v_sfa[0], v_sfb[0]);
    c00_13 = mma_scale_one<T, 0, 3, 1>(mma, v_a[0], v_b, c00_13, v_sfa[0], v_sfb[0]);
    sched_barrier_pairs_scale();

    c00_14 = mma_scale_one<T, 0, 3, 2>(mma, v_a[0], v_b, c00_14, v_sfa[0], v_sfb[0]);
    c00_15 = mma_scale_one<T, 0, 3, 3>(mma, v_a[0], v_b, c00_15, v_sfa[0], v_sfb[0]);
    sched_barrier_pairs_scale();

    c10_0 = mma_scale_one<T, 1, 0, 0>(mma, v_a[1], v_b, c10_0, v_sfa[1], v_sfb[0]);
    c10_1 = mma_scale_one<T, 1, 0, 1>(mma, v_a[1], v_b, c10_1, v_sfa[1], v_sfb[0]);
    sched_barrier_pairs_scale();

    c10_2 = mma_scale_one<T, 1, 0, 2>(mma, v_a[1], v_b, c10_2, v_sfa[1], v_sfb[0]);
    c10_3 = mma_scale_one<T, 1, 0, 3>(mma, v_a[1], v_b, c10_3, v_sfa[1], v_sfb[0]);
    sched_barrier_pairs_scale();

    c10_4 = mma_scale_one<T, 1, 1, 0>(mma, v_a[1], v_b, c10_4, v_sfa[1], v_sfb[0]);
    c10_5 = mma_scale_one<T, 1, 1, 1>(mma, v_a[1], v_b, c10_5, v_sfa[1], v_sfb[0]);
    sched_barrier_pairs_scale();

    c10_6 = mma_scale_one<T, 1, 1, 2>(mma, v_a[1], v_b, c10_6, v_sfa[1], v_sfb[0]);
    c10_7 = mma_scale_one<T, 1, 1, 3>(mma, v_a[1], v_b, c10_7, v_sfa[1], v_sfb[0]);
    sched_barrier_pairs_scale();

    c10_8 = mma_scale_one<T, 1, 2, 0>(mma, v_a[1], v_b, c10_8, v_sfa[1], v_sfb[0]);
    c10_9 = mma_scale_one<T, 1, 2, 1>(mma, v_a[1], v_b, c10_9, v_sfa[1], v_sfb[0]);
    sched_barrier_pairs_scale();

    c10_10 = mma_scale_one<T, 1, 2, 2>(mma, v_a[1], v_b, c10_10, v_sfa[1], v_sfb[0]);
    c10_11 = mma_scale_one<T, 1, 2, 3>(mma, v_a[1], v_b, c10_11, v_sfa[1], v_sfb[0]);
    sched_barrier_pairs_scale();

    c10_12 = mma_scale_one<T, 1, 3, 0>(mma, v_a[1], v_b, c10_12, v_sfa[1], v_sfb[0]);
    c10_13 = mma_scale_one<T, 1, 3, 1>(mma, v_a[1], v_b, c10_13, v_sfa[1], v_sfb[0]);
    sched_barrier_pairs_scale();

    c10_14 = mma_scale_one<T, 1, 3, 2>(mma, v_a[1], v_b, c10_14, v_sfa[1], v_sfb[0]);
    c10_15 = mma_scale_one<T, 1, 3, 3>(mma, v_a[1], v_b, c10_15, v_sfa[1], v_sfb[0]);
    sched_barrier_pairs_scale();

    if constexpr (T::OUTPUT_BF16) {
        v_b = v_b_second;
    } else {
        v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 1));
    }

    c01_0 = mma_scale_one<T, 0, 0, 0>(mma, v_a[0], v_b, c01_0, v_sfa[0], v_sfb[1]);
    c01_1 = mma_scale_one<T, 0, 0, 1>(mma, v_a[0], v_b, c01_1, v_sfa[0], v_sfb[1]);
    sched_barrier_pairs_scale();

    c01_2 = mma_scale_one<T, 0, 0, 2>(mma, v_a[0], v_b, c01_2, v_sfa[0], v_sfb[1]);
    c01_3 = mma_scale_one<T, 0, 0, 3>(mma, v_a[0], v_b, c01_3, v_sfa[0], v_sfb[1]);
    sched_barrier_pairs_scale();

    c01_4 = mma_scale_one<T, 0, 1, 0>(mma, v_a[0], v_b, c01_4, v_sfa[0], v_sfb[1]);
    c01_5 = mma_scale_one<T, 0, 1, 1>(mma, v_a[0], v_b, c01_5, v_sfa[0], v_sfb[1]);
    sched_barrier_pairs_scale();

    c01_6 = mma_scale_one<T, 0, 1, 2>(mma, v_a[0], v_b, c01_6, v_sfa[0], v_sfb[1]);
    c01_7 = mma_scale_one<T, 0, 1, 3>(mma, v_a[0], v_b, c01_7, v_sfa[0], v_sfb[1]);
    sched_barrier_pairs_scale();

    c01_8 = mma_scale_one<T, 0, 2, 0>(mma, v_a[0], v_b, c01_8, v_sfa[0], v_sfb[1]);
    c01_9 = mma_scale_one<T, 0, 2, 1>(mma, v_a[0], v_b, c01_9, v_sfa[0], v_sfb[1]);
    sched_barrier_pairs_scale();

    c01_10 = mma_scale_one<T, 0, 2, 2>(mma, v_a[0], v_b, c01_10, v_sfa[0], v_sfb[1]);
    c01_11 = mma_scale_one<T, 0, 2, 3>(mma, v_a[0], v_b, c01_11, v_sfa[0], v_sfb[1]);
    sched_barrier_pairs_scale();

    c01_12 = mma_scale_one<T, 0, 3, 0>(mma, v_a[0], v_b, c01_12, v_sfa[0], v_sfb[1]);
    c01_13 = mma_scale_one<T, 0, 3, 1>(mma, v_a[0], v_b, c01_13, v_sfa[0], v_sfb[1]);
    sched_barrier_pairs_scale();

    c01_14 = mma_scale_one<T, 0, 3, 2>(mma, v_a[0], v_b, c01_14, v_sfa[0], v_sfb[1]);
    c01_15 = mma_scale_one<T, 0, 3, 3>(mma, v_a[0], v_b, c01_15, v_sfa[0], v_sfb[1]);
    sched_barrier_pairs_scale();

    c11_0 = mma_scale_one<T, 1, 0, 0>(mma, v_a[1], v_b, c11_0, v_sfa[1], v_sfb[1]);
    c11_1 = mma_scale_one<T, 1, 0, 1>(mma, v_a[1], v_b, c11_1, v_sfa[1], v_sfb[1]);
    sched_barrier_pairs_scale();

    c11_2 = mma_scale_one<T, 1, 0, 2>(mma, v_a[1], v_b, c11_2, v_sfa[1], v_sfb[1]);
    c11_3 = mma_scale_one<T, 1, 0, 3>(mma, v_a[1], v_b, c11_3, v_sfa[1], v_sfb[1]);
    sched_barrier_pairs_scale();

    c11_4 = mma_scale_one<T, 1, 1, 0>(mma, v_a[1], v_b, c11_4, v_sfa[1], v_sfb[1]);
    c11_5 = mma_scale_one<T, 1, 1, 1>(mma, v_a[1], v_b, c11_5, v_sfa[1], v_sfb[1]);
    sched_barrier_pairs_scale();

    c11_6 = mma_scale_one<T, 1, 1, 2>(mma, v_a[1], v_b, c11_6, v_sfa[1], v_sfb[1]);
    c11_7 = mma_scale_one<T, 1, 1, 3>(mma, v_a[1], v_b, c11_7, v_sfa[1], v_sfb[1]);
    sched_barrier_pairs_scale();

    c11_8 = mma_scale_one<T, 1, 2, 0>(mma, v_a[1], v_b, c11_8, v_sfa[1], v_sfb[1]);
    c11_9 = mma_scale_one<T, 1, 2, 1>(mma, v_a[1], v_b, c11_9, v_sfa[1], v_sfb[1]);
    sched_barrier_pairs_scale();

    c11_10 = mma_scale_one<T, 1, 2, 2>(mma, v_a[1], v_b, c11_10, v_sfa[1], v_sfb[1]);
    c11_11 = mma_scale_one<T, 1, 2, 3>(mma, v_a[1], v_b, c11_11, v_sfa[1], v_sfb[1]);
    sched_barrier_pairs_scale();

    c11_12 = mma_scale_one<T, 1, 3, 0>(mma, v_a[1], v_b, c11_12, v_sfa[1], v_sfb[1]);
    c11_13 = mma_scale_one<T, 1, 3, 1>(mma, v_a[1], v_b, c11_13, v_sfa[1], v_sfb[1]);
    sched_barrier_pairs_scale();

    c11_14 = mma_scale_one<T, 1, 3, 2>(mma, v_a[1], v_b, c11_14, v_sfa[1], v_sfb[1]);
    c11_15 = mma_scale_one<T, 1, 3, 3>(mma, v_a[1], v_b, c11_15, v_sfa[1], v_sfb[1]);
    sched_barrier_pairs_scale();
    __builtin_amdgcn_s_setprio(0);

    // ===== Output writeback =====
    auto p_coord_c = opus::make_tuple(wave_id_m, lane_id % mma.grpn_c, wave_id_n, lane_id / mma.grpn_c);
    auto u_gc = partition_layout_c<T::VEC_C>(mma, opus::make_tuple(T::OUTPUT_BF16 ? c_lds_row_stride_elems : kargs.stride_c, 1_I), p_coord_c);

    auto c_offset = [&](int half_tile_m, int half_tile_n) {
        return half_tile_m * T::HALF_B_M * (T::OUTPUT_BF16 ? c_lds_row_stride_elems : kargs.stride_c) + half_tile_n * T::HALF_B_N;
    };

    // BF16 C store lds to global
    auto copy_output_bf16 = [&](int half_m, int half_n, int copy_index) {
        const int linear = thread_id_x() * 8 + copy_index * T::BLOCK_SIZE * 8;
        const int output_row = linear / T::HALF_B_N + half_m * T::HALF_B_M;
        const int output_col = linear % T::HALF_B_N + half_n * T::HALF_B_N;
        const auto value = load<8>(s_c, output_row * c_lds_row_stride_elems + output_col);
        store<8>(g_c, value, output_row * kargs.stride_c + output_col, 0, opus::number<2>{});
    };

    const auto gc_offsets = opus::layout_to_offsets<T::VEC_C>(u_gc);

    // AGPR -> BF16 -> LDS
    auto stage_output_row = [&](auto index_i, int half_m, int half_n,
                                const AccFragment& c0, const AccFragment& c1,
                                const AccFragment& c2, const AccFragment& c3) {
        if constexpr (T::OUTPUT_BF16) {
            constexpr int index = decltype(index_i)::value;
            constexpr int n_repeat_stride = T::T_N * T::W_N;
            const int row_offset = gc_offsets[index] + c_offset(half_m, half_n);
            store<T::VEC_C>(s_c, cast<D_C>(c0), row_offset);
            store<T::VEC_C>(s_c, cast<D_C>(c1), row_offset + n_repeat_stride);
            store<T::VEC_C>(s_c, cast<D_C>(c2), row_offset + 2 * n_repeat_stride);
            store<T::VEC_C>(s_c, cast<D_C>(c3), row_offset + 3 * n_repeat_stride);
        }
    };

    auto store_output_bf16 = [&](auto half_m_i, auto half_n_i) {
        if constexpr (T::OUTPUT_BF16) {
            constexpr int half_m = decltype(half_m_i)::value;
            constexpr int half_n = decltype(half_n_i)::value;
            __builtin_amdgcn_sched_barrier(0);
            if constexpr (!(half_m == 1 && half_n == 0)) {
                s_waitcnt_vmcnt(0_I);
            }
            s_waitcnt_lgkmcnt(0_I);
            __builtin_amdgcn_s_barrier();
            __builtin_amdgcn_sched_barrier(0);
            opus::static_for<8>([&](auto copy_i) { copy_output_bf16(half_m, half_n, decltype(copy_i)::value); });
        }
    };

    // FP32 C store AGPR to global
    auto store_output_fp32 = [&](int half_m, int half_n, const auto&... fragments) {
        if constexpr (!T::OUTPUT_BF16) {
            const int soff = c_offset(half_m, half_n);
            int index = 0;
            (store<T::VEC_C>(g_c, fragments, gc_offsets[index++], soff, opus::number<2>{}), ...);
        }
    };

    if constexpr (T::OUTPUT_BF16) {
        s_waitcnt_vmcnt(0_I);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);

        stage_output_row(opus::number<0>{}, 0, 0, c00_0, c00_1, c00_2, c00_3);
        stage_output_row(opus::number<4>{}, 0, 0, c00_4, c00_5, c00_6, c00_7);
        stage_output_row(opus::number<8>{}, 0, 0, c00_8, c00_9, c00_10, c00_11);
        stage_output_row(opus::number<12>{}, 0, 0, c00_12, c00_13, c00_14, c00_15);
        store_output_bf16(opus::number<0>{}, opus::number<0>{});

        stage_output_row(opus::number<0>{}, 1, 0, c10_0, c10_1, c10_2, c10_3);
        stage_output_row(opus::number<4>{}, 1, 0, c10_4, c10_5, c10_6, c10_7);
        stage_output_row(opus::number<8>{}, 1, 0, c10_8, c10_9, c10_10, c10_11);
        stage_output_row(opus::number<12>{}, 1, 0, c10_12, c10_13, c10_14, c10_15);
        store_output_bf16(opus::number<1>{}, opus::number<0>{});

        stage_output_row(opus::number<0>{}, 0, 1, c01_0, c01_1, c01_2, c01_3);
        stage_output_row(opus::number<4>{}, 0, 1, c01_4, c01_5, c01_6, c01_7);
        stage_output_row(opus::number<8>{}, 0, 1, c01_8, c01_9, c01_10, c01_11);
        stage_output_row(opus::number<12>{}, 0, 1, c01_12, c01_13, c01_14, c01_15);
        store_output_bf16(opus::number<0>{}, opus::number<1>{});

        stage_output_row(opus::number<0>{}, 1, 1, c11_0, c11_1, c11_2, c11_3);
        stage_output_row(opus::number<4>{}, 1, 1, c11_4, c11_5, c11_6, c11_7);
        stage_output_row(opus::number<8>{}, 1, 1, c11_8, c11_9, c11_10, c11_11);
        stage_output_row(opus::number<12>{}, 1, 1, c11_12, c11_13, c11_14, c11_15);
        store_output_bf16(opus::number<1>{}, opus::number<1>{});
    } else {
        store_output_fp32(0, 0,
            c00_0, c00_1, c00_2, c00_3,
            c00_4, c00_5, c00_6, c00_7,
            c00_8, c00_9, c00_10, c00_11,
            c00_12, c00_13, c00_14, c00_15);
        store_output_fp32(1, 0,
            c10_0, c10_1, c10_2, c10_3,
            c10_4, c10_5, c10_6, c10_7,
            c10_8, c10_9, c10_10, c10_11,
            c10_12, c10_13, c10_14, c10_15);
        store_output_fp32(0, 1,
            c01_0, c01_1, c01_2, c01_3,
            c01_4, c01_5, c01_6, c01_7,
            c01_8, c01_9, c01_10, c01_11,
            c01_12, c01_13, c01_14, c01_15);
        store_output_fp32(1, 1,
            c11_0, c11_1, c11_2, c11_3,
            c11_4, c11_5, c11_6, c11_7,
            c11_8, c11_9, c11_10, c11_11,
            c11_12, c11_13, c11_14, c11_15);
    }
}

}
