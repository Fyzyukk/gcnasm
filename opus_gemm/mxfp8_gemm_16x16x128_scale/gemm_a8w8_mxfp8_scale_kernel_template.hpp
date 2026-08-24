#pragma once

#include <opus/hip_minimal.hpp>
#include <opus/opus.hpp>

#include "gemm_a8w8_mxfp8_scale_common.h"

using opus::operator""_I;

template<int Pairs, int VALU_CNT, int Group>
__device__ inline void sched_barrier_pairs_scale() {
    __builtin_amdgcn_sched_group_barrier(0x08, 1, Group);
    __builtin_amdgcn_sched_group_barrier(0x02, VALU_CNT, Group);
    if constexpr (Pairs > 1) {
        sched_barrier_pairs_scale<Pairs - 1, VALU_CNT, Group>();
    }
}

template<class T, int HALF_TILE_M, int M_REPEAT, int N_GROUP, class MMA>
__device__ inline void mma_scale_repeat_n2(
    MMA& mma,
    const typename opus::remove_cvref_t<MMA>::vtype_a& v_a,
    const typename opus::remove_cvref_t<MMA>::vtype_b& v_b,
    typename opus::remove_cvref_t<MMA>::vtype_c& v_c,
    unsigned int v_sfa,
    unsigned int v_sfb) {
    (void)mma;

    using tiled_mma = opus::remove_cvref_t<MMA>;
    using base_mma = typename tiled_mma::MMA;

    constexpr int a_len = tiled_mma::mma_a_len;
    constexpr int b_len = tiled_mma::mma_b_len;
    constexpr int c_len = tiled_mma::mma_c_len;
    opus::static_for<T::E_N / 2>([&](auto n_repeat) {
        constexpr int NR = N_GROUP * (T::E_N / 2) + decltype(n_repeat)::value; // 0 / 1   2 / 3
        constexpr int a_offset = M_REPEAT * a_len;
        constexpr int b_offset = NR * b_len;
        constexpr int c_offset = (M_REPEAT * T::E_N + NR) * c_len;
        constexpr int scale_op_sel_a = HALF_TILE_M * T::E_M + M_REPEAT; // 0
        constexpr int scale_op_sel_b = NR; // 0 / 1   2 / 3

        auto s_a = opus::slice(v_a, opus::number<a_offset>{}, opus::number<a_offset + a_len>{});
        auto s_b = opus::slice(v_b, opus::number<b_offset>{}, opus::number<b_offset + b_len>{});
        auto s_c = opus::slice(v_c, opus::number<c_offset>{}, opus::number<c_offset + c_len>{});
        s_c = base_mma{}(
            s_a,
            s_b,
            s_c,
            static_cast<int>(v_sfa),
            static_cast<int>(v_sfb),
            opus::number<scale_op_sel_a>{},
            opus::number<scale_op_sel_b>{});
        opus::set_slice(v_c, s_c, opus::number<c_offset>{}, opus::number<c_offset + c_len>{});
    });
}

// Cooperative SFA loader: the four wave_n==0 waves each copy one contiguous
// 256-byte consumer-wave slice.  Each lane transfers four m_call bytes.
template<class T>
__device__ inline auto make_layout_lsfa_scale(int lane_id, int wave_id_m) {
    constexpr int scale_count = T::SCALE_KGROUPS_PER_MFMA;
    constexpr int m_calls = T::SCALE_M_CALLS;

    constexpr auto block_shape = opus::make_tuple(
        opus::number<T::T_M>{},
        opus::number<T::W_M>{},
        opus::number<scale_count>{},
        opus::number<m_calls>{});
    constexpr auto block_dim = opus::make_tuple(
        opus::make_tuple(opus::p_dim{}, opus::p_dim{}),
        opus::make_tuple(opus::p_dim{}),
        opus::make_tuple(opus::y_dim{}));

    return opus::make_layout<m_calls>(
        block_shape,
        opus::unfold_x_stride(
            block_dim,
            block_shape,
            opus::tuple{opus::number<scale_count * m_calls>{},
                        opus::number<m_calls>{},
                        1_I}),
        opus::unfold_p_coord(
            block_dim,
            opus::tuple{wave_id_m, lane_id / scale_count, lane_id % scale_count}));
}

// Cooperative SFB loader: the four wave_n==1 waves map to
// (half_n, consumer_wave_n), again moving one packed dword per lane.
template<class T>
__device__ inline auto make_layout_lsfb_scale(int lane_id, int wave_id_m) {
    constexpr int scale_count = T::SCALE_KGROUPS_PER_MFMA;
    constexpr int n_calls = T::SCALE_N_CALLS;

    constexpr auto block_shape = opus::make_tuple(
        opus::number<T::SCALE_N_HALVES>{},
        opus::number<T::T_N>{},
        opus::number<T::W_N>{},
        opus::number<scale_count>{},
        opus::number<n_calls>{});
    constexpr auto block_dim = opus::make_tuple(
        opus::make_tuple(opus::p_dim{}),
        opus::make_tuple(opus::p_dim{}, opus::p_dim{}),
        opus::make_tuple(opus::p_dim{}),
        opus::make_tuple(opus::y_dim{}));

    return opus::make_layout<n_calls>(
        block_shape,
        opus::unfold_x_stride(
            block_dim,
            block_shape,
            opus::tuple{opus::number<T::T_N * T::W_N * scale_count * n_calls>{},
                        opus::number<scale_count * n_calls>{},
                        opus::number<n_calls>{},
                        1_I}),
        opus::unfold_p_coord(
            block_dim,
            opus::tuple{wave_id_m / T::T_N,
                        wave_id_m % T::T_N,
                        lane_id / scale_count,
                        lane_id % scale_count}));
}

// Four wave_n==0 waves cooperatively load the 256 SFA rows.  Each lane owns
// one row and fetches its four contiguous K-group bytes as one dword.
template<class T>
__device__ inline auto make_layout_gsfa_scale(
    int lane_id, int wave_id_m, int stride_sfa) {
    constexpr int scale_count = T::SCALE_KGROUPS_PER_MFMA;
    constexpr int rows_per_wave = T::B_M / T::T_M;
    static_assert(rows_per_wave == T::WARP_SIZE);

    constexpr auto block_shape = opus::make_tuple(
        opus::number<T::T_M>{},
        opus::number<rows_per_wave>{},
        opus::number<scale_count>{});
    constexpr auto block_dim = opus::make_tuple(
        opus::make_tuple(opus::p_dim{}, opus::p_dim{}),
        opus::make_tuple(opus::y_dim{}));

    return opus::make_layout<scale_count>(
        block_shape,
        opus::unfold_x_stride(
            block_dim, block_shape, opus::tuple{stride_sfa, 1_I}),
        opus::unfold_p_coord(block_dim, opus::tuple{wave_id_m, lane_id}));
}

// Four wave_n==1 waves use the same ownership rule for the 256 SFB rows.
template<class T>
__device__ inline auto make_layout_gsfb_scale(
    int lane_id, int wave_id_m, int stride_sfb) {
    constexpr int scale_count = T::SCALE_KGROUPS_PER_MFMA;
    constexpr int rows_per_wave = T::B_N / T::T_M;
    static_assert(rows_per_wave == T::WARP_SIZE);

    constexpr auto block_shape = opus::make_tuple(
        opus::number<T::T_M>{},
        opus::number<rows_per_wave>{},
        opus::number<scale_count>{});
    constexpr auto block_dim = opus::make_tuple(
        opus::make_tuple(opus::p_dim{}, opus::p_dim{}),
        opus::make_tuple(opus::y_dim{}));

    return opus::make_layout<scale_count>(
        block_shape,
        opus::unfold_x_stride(
            block_dim, block_shape, opus::tuple{stride_sfb, 1_I}),
        opus::unfold_p_coord(block_dim, opus::tuple{wave_id_m, lane_id}));
}

// Scatter the four bytes fetched by one SFA loader lane into the
// consumer-major [wave_m][r][q][m_call] LDS image.
template<class T>
__device__ inline auto make_layout_ssfa_scale(int lane_id, int wave_id_m) {
    constexpr int scale_count = T::SCALE_KGROUPS_PER_MFMA;
    constexpr int m_calls = T::SCALE_M_CALLS;

    constexpr auto block_shape = opus::make_tuple(
        opus::number<T::T_M>{},
        opus::number<T::W_M>{},
        opus::number<scale_count>{},
        opus::number<m_calls>{});
    constexpr auto block_dim = opus::make_tuple(
        opus::make_tuple(opus::p_dim{}, opus::p_dim{}),
        opus::make_tuple(opus::y_dim{}),
        opus::make_tuple(opus::p_dim{}));

    return opus::make_layout(
        block_shape,
        opus::unfold_x_stride(
            block_dim,
            block_shape,
            opus::tuple{opus::number<scale_count * m_calls>{},
                        opus::number<m_calls>{},
                        1_I}),
        opus::unfold_p_coord(
            block_dim,
            opus::tuple{lane_id / T::W_M, lane_id % T::W_M, wave_id_m}));
}

// Scatter SFB into [half_n][wave_n][r][q][n_call].
template<class T>
__device__ inline auto make_layout_ssfb_scale(int lane_id, int wave_id_m) {
    constexpr int scale_count = T::SCALE_KGROUPS_PER_MFMA;
    constexpr int n_per_call = T::T_N * T::W_N;

    const int linear_n = wave_id_m * T::WARP_SIZE + lane_id;
    const int half_tile_n = linear_n / T::HALF_B_N;
    const int n_in_half = linear_n % T::HALF_B_N;
    const int n_call = n_in_half / n_per_call;
    const int n_in_call = n_in_half % n_per_call;
    const int consumer_wave_n = n_in_call / T::W_N;
    const int r = n_in_call % T::W_N;

    constexpr auto block_shape = opus::make_tuple(
        opus::number<T::SCALE_N_HALVES>{},
        opus::number<T::T_N>{},
        opus::number<T::W_N>{},
        opus::number<scale_count>{},
        opus::number<T::SCALE_N_CALLS>{});
    constexpr auto block_dim = opus::make_tuple(
        opus::make_tuple(opus::p_dim{}),
        opus::make_tuple(opus::p_dim{}, opus::p_dim{}),
        opus::make_tuple(opus::y_dim{}),
        opus::make_tuple(opus::p_dim{}));

    return opus::make_layout(
        block_shape,
        opus::unfold_x_stride(
            block_dim,
            block_shape,
            opus::tuple{
                opus::number<T::T_N * T::W_N * scale_count * T::SCALE_N_CALLS>{},
                opus::number<scale_count * T::SCALE_N_CALLS>{},
                opus::number<T::SCALE_N_CALLS>{},
                1_I}),
        opus::unfold_p_coord(
            block_dim,
            opus::tuple{half_tile_n, consumer_wave_n, r, n_call}));
}

template<class T>
__device__ inline auto make_layout_rsfa_scale(int lane_id, int wave_id_m) {
    constexpr int scale_count = T::SCALE_KGROUPS_PER_MFMA; // 4
    constexpr int m_calls = T::SCALE_M_CALLS; // 4

    constexpr auto gsfa_block_shape = opus::make_tuple(
        opus::number<T::T_M>{}, // 4
        opus::number<T::W_M>{}, // 16
        opus::number<scale_count>{}, // 4
        opus::number<m_calls>{}); // 4

    constexpr auto gsfa_block_dim = opus::make_tuple(
        opus::make_tuple(opus::p_dim{}, opus::p_dim{}),
        opus::make_tuple(opus::p_dim{}),
        opus::make_tuple(opus::y_dim{}));

    return opus::make_layout<m_calls>(
        gsfa_block_shape,
        opus::unfold_x_stride(gsfa_block_dim, gsfa_block_shape, opus::tuple{opus::number<scale_count * m_calls>{}, opus::number<m_calls>{}, 1_I}),
        opus::unfold_p_coord(gsfa_block_dim, opus::tuple{wave_id_m, lane_id % T::W_M, lane_id / T::W_M}));
}

template<class T>
__device__ inline auto make_layout_rsfb_scale(int lane_id, int wave_id_n, int half_tile_n) {
    constexpr int scale_count = T::SCALE_KGROUPS_PER_MFMA; // 4
    constexpr int half_tiles_n = T::SCALE_N_HALVES; // 2

    constexpr auto gsfb_block_shape = opus::make_tuple(
        opus::number<half_tiles_n>{},
        opus::number<T::T_N>{},
        opus::number<T::W_N>{},
        opus::number<scale_count>{},
        opus::number<T::SCALE_N_CALLS>{});

    constexpr auto gsfb_block_dim = opus::make_tuple(
        opus::make_tuple(opus::p_dim{}),
        opus::make_tuple(opus::p_dim{}, opus::p_dim{}),
        opus::make_tuple(opus::p_dim{}),
        opus::make_tuple(opus::y_dim{}));

    return opus::make_layout<T::SCALE_N_CALLS>(
        gsfb_block_shape,
        opus::unfold_x_stride(gsfb_block_dim, gsfb_block_shape, opus::tuple{opus::number<T::T_N * T::W_N * scale_count * T::SCALE_N_CALLS>{}, opus::number<scale_count * T::SCALE_N_CALLS>{}, opus::number<T::SCALE_N_CALLS>{}, 1_I}),
        opus::unfold_p_coord(gsfb_block_dim, opus::tuple{half_tile_n, wave_id_n, lane_id % T::W_N, lane_id / T::W_N}));
}

template<class T>
__device__ inline auto make_layout_ga_scale(int lane_id, int wave_id_m, int wave_id_n, int stride_a) {
    constexpr int threads_k = T::B_K / T::VEC_A; // 8
    constexpr int threads_m_per_block = T::BLOCK_SIZE / threads_k; // 64
    constexpr int threads_m_per_wave = T::WARP_SIZE / threads_k; // 8

    constexpr auto ga_block_shape = opus::make_tuple(
        opus::number<T::HALF_B_M / threads_m_per_block>{}, // 2 64
        opus::number<T::T_N>{}, // 2 32
        opus::number<threads_m_per_wave>{}, // 8 4
        opus::number<T::T_M>{}, // 4 1
        opus::number<threads_k>{}, //8 16
        opus::number<T::VEC_A>{}); //16  1

    constexpr auto ga_block_dim = opus::make_tuple(
        opus::make_tuple(opus::y_dim{}, opus::p_dim{}, opus::p_dim{}, opus::p_dim{}),
        opus::make_tuple(opus::p_dim{}, opus::y_dim{}));

    return opus::make_layout<T::VEC_A>(
        ga_block_shape,
        opus::unfold_x_stride(ga_block_dim, ga_block_shape, opus::tuple{stride_a, 1_I}),
        opus::unfold_p_coord(ga_block_dim, opus::tuple{wave_id_n, lane_id / threads_k, wave_id_m, lane_id % threads_k}));
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
__device__ inline auto make_layout_gb_scale(int lane_id, int wave_id_m, int wave_id_n, int stride_b) {
    constexpr int threads_k = T::B_K / T::VEC_B;
    constexpr int threads_n_per_block = T::BLOCK_SIZE / threads_k;
    constexpr int threads_n_per_wave = T::WARP_SIZE / threads_k;

    constexpr auto gb_block_shape = opus::make_tuple(
        opus::number<T::HALF_B_N / threads_n_per_block>{},
        opus::number<T::T_N>{},
        opus::number<threads_n_per_wave>{},
        opus::number<T::T_M>{},
        opus::number<threads_k>{},
        opus::number<T::VEC_B>{});

    constexpr auto gb_block_dim = opus::make_tuple(
        opus::make_tuple(opus::y_dim{}, opus::p_dim{}, opus::p_dim{}, opus::p_dim{}),
        opus::make_tuple(opus::p_dim{}, opus::y_dim{}));

    return opus::make_layout<T::VEC_B>(
        gb_block_shape,
        opus::unfold_x_stride(gb_block_dim, gb_block_shape, opus::tuple{stride_b, 1_I}),
        opus::unfold_p_coord(gb_block_dim, opus::tuple{wave_id_n, lane_id / threads_k, wave_id_m, lane_id % threads_k}));
}

template<class T>
__device__ inline auto make_layout_sb_scale(int wave_id_m, int wave_id_n) {
    constexpr int num_waves = T::BLOCK_SIZE / T::WARP_SIZE;

    constexpr auto sb_block_shape = opus::make_tuple(
        opus::number<T::smem_n_rep / num_waves>{},
        opus::number<T::T_N>{},
        opus::number<T::T_M>{},
        opus::number<T::VEC_B>{});

    constexpr auto sb_block_dim = opus::make_tuple(
        opus::make_tuple(opus::y_dim{}, opus::p_dim{}, opus::p_dim{}),
        opus::make_tuple(opus::y_dim{}));

    return opus::make_layout(
        sb_block_shape,
        opus::unfold_x_stride(sb_block_dim, sb_block_shape, opus::tuple{opus::number<T::smem_linear_wave + T::smem_padding>{}, 1_I}),
        opus::unfold_p_coord(sb_block_dim, opus::tuple{wave_id_n, wave_id_m}));
}

template<class T>
__device__ inline auto make_layout_ra_scale(int lane_id, int wave_id_m) {

    constexpr auto ra_block_shape = opus::make_tuple(
        opus::number<T::E_M>{},
        opus::number<T::T_M / T::T_N>{},
        opus::number<T::T_M>{},
        opus::number<T::T_N>{},
        opus::number<T::W_M / T::T_M>{},
        opus::number<T::E_K>{},
        opus::number<T::W_M * T::W_K / T::WARP_SIZE / T::VEC_A>{},
        opus::number<T::WARP_SIZE / T::W_M>{},
        opus::number<T::VEC_A>{});

    constexpr auto ra_block_dim = opus::make_tuple(
        opus::make_tuple(opus::y_dim{}, opus::p_dim{}, opus::p_dim{}),
        opus::make_tuple(opus::p_dim{}, opus::p_dim{}, opus::y_dim{}, opus::y_dim{}, opus::p_dim{}, opus::y_dim{}));

    const int lane_id_m = lane_id % T::W_M;

    return opus::make_layout<T::VEC_A>(
        ra_block_shape,
        opus::unfold_x_stride(ra_block_dim, ra_block_shape, opus::tuple{opus::number<T::smem_linear_wave + T::smem_padding>{}, 1_I}),
        opus::unfold_p_coord(ra_block_dim, opus::tuple{wave_id_m / T::T_N, lane_id_m % T::T_M, wave_id_m % T::T_N, lane_id_m / T::T_M, lane_id / T::W_M}));
}

template<class T>
__device__ inline auto make_layout_rb_scale(int lane_id, int wave_id_n) {

    constexpr auto rb_block_shape = opus::make_tuple(
        opus::number<T::E_N>{},
        opus::number<T::T_M>{},
        opus::number<T::T_N>{},
        opus::number<T::W_N / T::T_M>{},
        opus::number<T::E_K>{},
        opus::number<T::W_N * T::W_K / T::WARP_SIZE / T::VEC_B>{},
        opus::number<T::WARP_SIZE / T::W_N>{},
        opus::number<T::VEC_B>{});

    constexpr auto rb_block_dim = opus::make_tuple(
        opus::make_tuple(opus::y_dim{}, opus::p_dim{}),
        opus::make_tuple(opus::p_dim{}, opus::p_dim{}, opus::y_dim{}, opus::y_dim{}, opus::p_dim{}, opus::y_dim{}));

    const int lane_id_n = lane_id % T::W_N;
    
    return opus::make_layout<T::VEC_B>(
        rb_block_shape,
        opus::unfold_x_stride(rb_block_dim, rb_block_shape, opus::tuple{opus::number<T::smem_linear_wave + T::smem_padding>{}, 1_I}),
        opus::unfold_p_coord(rb_block_dim, opus::tuple{lane_id_n % T::T_M, wave_id_n, lane_id_n / T::T_M, lane_id / T::W_N}));
}

template<class Traits>
__global__ __launch_bounds__(Traits::BLOCK_SIZE, 2) void gemm_a8w8_mxfp8_scale_kernel(opus_gemm_scale_kargs kargs) {
    using namespace opus;

    using T = opus::remove_cvref_t<Traits>;
    using D_A = opus::fp8_t;
    using D_B = opus::fp8_t;
    using D_C = opus::fp32_t;
    using D_ACC = opus::fp32_t;
    using D_SF = unsigned char;
    using D_SF_PACK = unsigned int;

    const int wgid = block_id_x();
    const int num_tiles_n = ceil_div_scale(kargs.n, T::B_N);
    const int num_tiles_k = ceil_div_scale(kargs.k, T::B_K);
    const int block_m = wgid / num_tiles_n;
    const int block_n = wgid % num_tiles_n;
    const int row = block_m * T::B_M;
    const int col = block_n * T::B_N;

    const int batch_id = block_id_z();
    const int wave_id = __builtin_amdgcn_readfirstlane(thread_id_x() / T::WARP_SIZE);
    const int lane_id = thread_id_x() % T::WARP_SIZE;

    auto g_a = make_gmem(reinterpret_cast<const D_A*>(kargs.ptr_a) + batch_id * kargs.stride_a_batch + row * kargs.stride_a);
    auto g_b = make_gmem(reinterpret_cast<const D_B*>(kargs.ptr_b) + batch_id * kargs.stride_b_batch + col * kargs.stride_b);
    auto g_c = make_gmem(reinterpret_cast<D_C*>(kargs.ptr_c) + batch_id * kargs.stride_c_batch + row * kargs.stride_c + col);

    // Scale is prepacked tile-major in the exact consumer-major LDS order.
    // Four waves cooperatively copy aligned, adjacent dwords directly from
    // global memory into LDS; no VGPR forwarding or LDS transpose is needed.
    auto g_sfa = make_gmem(reinterpret_cast<const D_SF*>(
        reinterpret_cast<const D_SF*>(kargs.ptr_sfa) + batch_id * kargs.stride_sfa_batch
        + block_m * num_tiles_k * kargs.stride_sfa));
    auto g_sfb = make_gmem(reinterpret_cast<const D_SF*>(
        reinterpret_cast<const D_SF*>(kargs.ptr_sfb) + batch_id * kargs.stride_sfb_batch
        + block_n * num_tiles_k * kargs.stride_sfb));

    const int wave_id_m = wave_id % T::T_M;
    const int wave_id_n = wave_id / T::T_M;

    auto u_ga = make_layout_ga_scale<T>(lane_id, wave_id_m, wave_id_n, kargs.stride_a);
    auto u_sa = make_layout_sa_scale<T>(wave_id_m, wave_id_n);
    auto u_ra = make_layout_ra_scale<T>(lane_id, wave_id_m);
    auto u_gb = make_layout_gb_scale<T>(lane_id, wave_id_m, wave_id_n, kargs.stride_b);
    auto u_sb = make_layout_sb_scale<T>(wave_id_m, wave_id_n);
    auto u_rb = make_layout_rb_scale<T>(lane_id, wave_id_n);

    auto u_lsfa = make_layout_lsfa_scale<T>(lane_id, wave_id_m);
    auto u_lsfb = make_layout_lsfb_scale<T>(lane_id, wave_id_m);
    auto u_rsfa = make_layout_rsfa_scale<T>(lane_id, wave_id_m);
    auto u_rsfb_0 = make_layout_rsfb_scale<T>(lane_id, wave_id_n, 0);
    auto u_rsfb_1 = make_layout_rsfb_scale<T>(lane_id, wave_id_n, 1);

    constexpr int smem_a_elem = T::smem_m_rep * (T::smem_linear_wave + T::smem_padding);
    constexpr int smem_b_elem = T::smem_n_rep * (T::smem_linear_wave + T::smem_padding);
    __shared__ char smem_a[smem_a_elem * 4 * sizeof(D_A)];
    __shared__ char smem_b[smem_b_elem * 4 * sizeof(D_B)];
    auto s_a = make_smem(reinterpret_cast<D_A*>(smem_a));
    auto s_b = make_smem(reinterpret_cast<D_B*>(smem_b));

    constexpr int smem_sfa_elem = T::packed_sfa_tile_elem;
    constexpr int smem_sfb_elem = T::packed_sfb_tile_elem;
    __shared__ char smem_sfa[smem_sfa_elem * 2 * sizeof(D_SF)];
    __shared__ char smem_sfb[smem_sfb_elem * 2 * sizeof(D_SF)];
    auto s_sfa = make_smem(reinterpret_cast<D_SF*>(smem_sfa));
    auto s_sfb = make_smem(reinterpret_cast<D_SF*>(smem_sfb));

    auto mma = make_tiled_mma<D_A, D_B, D_ACC>(
        seq<T::E_M, T::E_N, T::E_K>{},
        seq<T::T_M, T::T_N, T::T_K>{},
        seq<T::W_M, T::W_N, T::W_K>{},
        mfma_adaptor_swap_ab{});
    typename decltype(mma)::vtype_a v_a[2];
    typename decltype(mma)::vtype_b v_b;
    typename decltype(mma)::vtype_c v_c[2][2];
    clear(v_c[0][0]);
    clear(v_c[0][1]);
    clear(v_c[1][0]);
    clear(v_c[1][1]);

    D_SF_PACK v_sfa;
    D_SF_PACK v_sfb[T::SCALE_N_HALVES];
    auto ga_offset = [&](int half_tile_m, int tile_k) { return half_tile_m * T::HALF_B_M * kargs.stride_a + tile_k * T::B_K; };
    auto gb_offset = [&](int half_tile_n, int tile_k) { return half_tile_n * T::HALF_B_N * kargs.stride_b + tile_k * T::B_K; };
    auto sa_offset = [&](int stage, int half_tile_m) { return (stage * 2 + half_tile_m) * smem_a_elem; };
    auto sb_offset = [&](int stage, int half_tile_n) { return (stage * 2 + half_tile_n) * smem_b_elem; };
    auto gsfa_offset = [&](int tile_k) { return tile_k * kargs.stride_sfa; };
    auto gsfb_offset = [&](int tile_k) { return tile_k * kargs.stride_sfb; };
    auto ssfa_offset = [&](int stage) { return stage * smem_sfa_elem; };
    auto ssfb_offset = [&](int stage) { return stage * smem_sfb_elem; };

    const int loops = num_tiles_k;

    // Prologue
    if (wave_id_n == 0) {
        async_load<4>(
            g_sfa, s_sfa.ptr, u_lsfa, u_lsfa + ssfa_offset(0), gsfa_offset(0));
    } else {
        async_load<4>(
            g_sfb, s_sfb.ptr, u_lsfb, u_lsfb + ssfb_offset(0), gsfb_offset(0));
    }
    async_load<T::VEC_A>(g_a, s_a.ptr, u_ga, u_sa + sa_offset(0, 0), ga_offset(0, 0));
    async_load<T::VEC_B>(g_b, s_b.ptr, u_gb, u_sb + sb_offset(0, 0), gb_offset(0, 0));
    async_load<T::VEC_A>(g_a, s_a.ptr, u_ga, u_sa + sa_offset(0, 1), ga_offset(1, 0));
    async_load<T::VEC_B>(g_b, s_b.ptr, u_gb, u_sb + sb_offset(0, 1), gb_offset(1, 0));

    s_waitcnt_vmcnt(0_I);
    s_waitcnt_lgkmcnt(0_I);
    __builtin_amdgcn_s_barrier();
    __builtin_amdgcn_sched_barrier(0);

    int stage = 0;
    int tile = 0;

    // Main Loop
    for (tile = 0; tile + 1 < loops; ++tile) {
        const int next_stage = stage ^ 1;

        // Four waves fetch SFA and four fetch SFB.  Host prepacking makes the
        // dword layout identical to the consumer-major LDS layout.
        if (wave_id_n == 0) {
            async_load<4>(
                g_sfa,
                s_sfa.ptr,
                u_lsfa,
                u_lsfa + ssfa_offset(next_stage),
                gsfa_offset(tile + 1));
        } else {
            async_load<4>(
                g_sfb,
                s_sfb.ptr,
                u_lsfb,
                u_lsfb + ssfb_offset(next_stage),
                gsfb_offset(tile + 1));
        }

        async_load<T::VEC_A>(
            g_a, s_a.ptr, u_ga, u_sa + sa_offset(next_stage, 0), ga_offset(0, tile + 1));
        async_load<T::VEC_B>(
            g_b, s_b.ptr, u_gb, u_sb + sb_offset(next_stage, 0), gb_offset(0, tile + 1));
        async_load<T::VEC_A>(
            g_a, s_a.ptr, u_ga, u_sa + sa_offset(next_stage, 1), ga_offset(1, tile + 1));
        async_load<T::VEC_B>(
            g_b, s_b.ptr, u_gb, u_sb + sb_offset(next_stage, 1), gb_offset(1, tile + 1));

        auto r_sfa = load<4>(s_sfa, u_rsfa + ssfa_offset(stage));
        auto r_sfb_0 = load<4>(s_sfb, u_rsfb_0 + ssfb_offset(stage));
        v_a[0] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 0));
        v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 0));

        s_waitcnt_lgkmcnt(0_I);
        v_sfa = __builtin_bit_cast(D_SF_PACK, r_sfa);
        v_sfb[0] = __builtin_bit_cast(D_SF_PACK, r_sfb_0);

        // Fetch the second N-half scale before the first half computes.  It is
        // only one dword, and the following 16 MFMAs hide its LDS latency.
        auto r_sfb_1 = load<4>(s_sfb, u_rsfb_1 + ssfb_offset(stage));

        __builtin_amdgcn_s_setprio(1);
        mma_scale_repeat_n2<T, 0, 0, 0>(
            mma, v_a[0], v_b, v_c[0][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][0]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale<2, 2, 0>();

        v_a[1] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 1));

        mma_scale_repeat_n2<T, 0, 0, 1>(
            mma, v_a[0], v_b, v_c[0][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][0]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale<2, 2, 0>();

        mma_scale_repeat_n2<T, 0, 1, 0>(
            mma, v_a[0], v_b, v_c[0][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][0]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale<2, 2, 0>();

        mma_scale_repeat_n2<T, 0, 1, 1>(
            mma, v_a[0], v_b, v_c[0][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][0]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale<2, 2, 0>();

        mma_scale_repeat_n2<T, 1, 0, 0>(
            mma, v_a[1], v_b, v_c[1][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][0]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale<2, 2, 0>();

        mma_scale_repeat_n2<T, 1, 0, 1>(
            mma, v_a[1], v_b, v_c[1][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][0]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale<2, 2, 0>();

        mma_scale_repeat_n2<T, 1, 1, 0>(
            mma, v_a[1], v_b, v_c[1][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][0]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale<2, 2, 0>();

        mma_scale_repeat_n2<T, 1, 1, 1>(
            mma, v_a[1], v_b, v_c[1][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][0]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale<2, 2, 0>();

        v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 1));
        v_sfb[1] = __builtin_bit_cast(D_SF_PACK, r_sfb_1);

        mma_scale_repeat_n2<T, 0, 0, 0>(
            mma, v_a[0], v_b, v_c[0][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale<2, 2, 0>();

        mma_scale_repeat_n2<T, 0, 0, 1>(
            mma, v_a[0], v_b, v_c[0][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale<2, 2, 0>();

        mma_scale_repeat_n2<T, 0, 1, 0>(
            mma, v_a[0], v_b, v_c[0][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale<2, 2, 0>();

        mma_scale_repeat_n2<T, 0, 1, 1>(
            mma, v_a[0], v_b, v_c[0][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale<2, 2, 0>();

        mma_scale_repeat_n2<T, 1, 0, 0>(
            mma, v_a[1], v_b, v_c[1][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale<2, 2, 0>();

        mma_scale_repeat_n2<T, 1, 0, 1>(
            mma, v_a[1], v_b, v_c[1][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale<2, 2, 0>();

        mma_scale_repeat_n2<T, 1, 1, 0>(
            mma, v_a[1], v_b, v_c[1][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale<2, 2, 0>();

        mma_scale_repeat_n2<T, 1, 1, 1>(
            mma, v_a[1], v_b, v_c[1][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale<2, 2, 0>();
        __builtin_amdgcn_s_setprio(0);

        s_waitcnt_vmcnt(0_I);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);
        stage = next_stage;
    }

    // ---------------------------------------------------------------------
    // Epilogue: consume the final resident tile; issue no next-tile VMEM.
    // ---------------------------------------------------------------------
    auto r_sfa = load<4>(s_sfa, u_rsfa + ssfa_offset(stage));
    auto r_sfb_0 = load<4>(s_sfb, u_rsfb_0 + ssfb_offset(stage));
    v_a[0] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 0));
    v_a[1] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 1));
    v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 0));

    s_waitcnt_lgkmcnt(0_I);
    v_sfa = __builtin_bit_cast(D_SF_PACK, r_sfa);
    v_sfb[0] = __builtin_bit_cast(D_SF_PACK, r_sfb_0);
    auto r_sfb_1 = load<4>(s_sfb, u_rsfb_1 + ssfb_offset(stage));

    __builtin_amdgcn_s_setprio(1);
    mma_scale_repeat_n2<T, 0, 0, 0>(
        mma, v_a[0], v_b, v_c[0][0], v_sfa, v_sfb[0]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][0]);
        asm volatile("" : "+v"(v_c_pin[0]) ::);
    }
    sched_barrier_pairs_scale<2, 2, 0>();

    mma_scale_repeat_n2<T, 0, 0, 1>(
        mma, v_a[0], v_b, v_c[0][0], v_sfa, v_sfb[0]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][0]);
        asm volatile("" : "+v"(v_c_pin[0]) ::);
    }
    sched_barrier_pairs_scale<2, 2, 0>();

    mma_scale_repeat_n2<T, 0, 1, 0>(
        mma, v_a[0], v_b, v_c[0][0], v_sfa, v_sfb[0]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][0]);
        asm volatile("" : "+v"(v_c_pin[1]) ::);
    }
    sched_barrier_pairs_scale<2, 2, 0>();

    mma_scale_repeat_n2<T, 0, 1, 1>(
        mma, v_a[0], v_b, v_c[0][0], v_sfa, v_sfb[0]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][0]);
        asm volatile("" : "+v"(v_c_pin[1]) ::);
    }
    sched_barrier_pairs_scale<2, 2, 0>();

    mma_scale_repeat_n2<T, 1, 0, 0>(
        mma, v_a[1], v_b, v_c[1][0], v_sfa, v_sfb[0]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][0]);
        asm volatile("" : "+v"(v_c_pin[0]) ::);
    }
    sched_barrier_pairs_scale<2, 2, 0>();

    mma_scale_repeat_n2<T, 1, 0, 1>(
        mma, v_a[1], v_b, v_c[1][0], v_sfa, v_sfb[0]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][0]);
        asm volatile("" : "+v"(v_c_pin[0]) ::);
    }
    sched_barrier_pairs_scale<2, 2, 0>();

    mma_scale_repeat_n2<T, 1, 1, 0>(
        mma, v_a[1], v_b, v_c[1][0], v_sfa, v_sfb[0]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][0]);
        asm volatile("" : "+v"(v_c_pin[1]) ::);
    }
    sched_barrier_pairs_scale<2, 2, 0>();

    mma_scale_repeat_n2<T, 1, 1, 1>(
        mma, v_a[1], v_b, v_c[1][0], v_sfa, v_sfb[0]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][0]);
        asm volatile("" : "+v"(v_c_pin[1]) ::);
    }
    sched_barrier_pairs_scale<2, 2, 0>();

    v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 1));
    v_sfb[1] = __builtin_bit_cast(D_SF_PACK, r_sfb_1);

    mma_scale_repeat_n2<T, 0, 0, 0>(
        mma, v_a[0], v_b, v_c[0][1], v_sfa, v_sfb[1]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
        asm volatile("" : "+v"(v_c_pin[0]) ::);
    }
    sched_barrier_pairs_scale<2, 2, 0>();

    mma_scale_repeat_n2<T, 0, 0, 1>(
        mma, v_a[0], v_b, v_c[0][1], v_sfa, v_sfb[1]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
        asm volatile("" : "+v"(v_c_pin[0]) ::);
    }
    sched_barrier_pairs_scale<2, 2, 0>();

    mma_scale_repeat_n2<T, 0, 1, 0>(
        mma, v_a[0], v_b, v_c[0][1], v_sfa, v_sfb[1]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
        asm volatile("" : "+v"(v_c_pin[1]) ::);
    }
    sched_barrier_pairs_scale<2, 2, 0>();

    mma_scale_repeat_n2<T, 0, 1, 1>(
        mma, v_a[0], v_b, v_c[0][1], v_sfa, v_sfb[1]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
        asm volatile("" : "+v"(v_c_pin[1]) ::);
    }
    sched_barrier_pairs_scale<2, 2, 0>();

    mma_scale_repeat_n2<T, 1, 0, 0>(
        mma, v_a[1], v_b, v_c[1][1], v_sfa, v_sfb[1]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
        asm volatile("" : "+v"(v_c_pin[0]) ::);
    }
    sched_barrier_pairs_scale<2, 2, 0>();

    mma_scale_repeat_n2<T, 1, 0, 1>(
        mma, v_a[1], v_b, v_c[1][1], v_sfa, v_sfb[1]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
        asm volatile("" : "+v"(v_c_pin[0]) ::);
    }
    sched_barrier_pairs_scale<2, 2, 0>();

    mma_scale_repeat_n2<T, 1, 1, 0>(
        mma, v_a[1], v_b, v_c[1][1], v_sfa, v_sfb[1]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
        asm volatile("" : "+v"(v_c_pin[1]) ::);
    }
    sched_barrier_pairs_scale<2, 2, 0>();

    mma_scale_repeat_n2<T, 1, 1, 1>(
        mma, v_a[1], v_b, v_c[1][1], v_sfa, v_sfb[1]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
        asm volatile("" : "+v"(v_c_pin[1]) ::);
    }
    sched_barrier_pairs_scale<2, 2, 0>();
    __builtin_amdgcn_s_setprio(0);

    auto p_coord_c = opus::make_tuple(wave_id_m, lane_id % mma.grpn_c, wave_id_n, lane_id / mma.grpn_c);
    auto u_gc = partition_layout_c<T::VEC_C>(mma, opus::make_tuple(kargs.stride_c, 1_I), p_coord_c);

    auto c_offset = [&](int half_tile_m, int half_tile_n) {
        return half_tile_m * T::HALF_B_M * kargs.stride_c + half_tile_n * T::HALF_B_N;
    };

    store<T::VEC_C>(g_c, v_c[0][0], u_gc, c_offset(0, 0));
    store<T::VEC_C>(g_c, v_c[0][1], u_gc, c_offset(0, 1));
    store<T::VEC_C>(g_c, v_c[1][0], u_gc, c_offset(1, 0));
    store<T::VEC_C>(g_c, v_c[1][1], u_gc, c_offset(1, 1));
}
