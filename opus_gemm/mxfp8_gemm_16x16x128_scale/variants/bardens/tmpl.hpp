#pragma once

// Dedicated final pipeline:
//   8-wave persistent fixed-B prefetch x4
//   + one B producer wave per resident SIMD pair
//   + paired SFB LDS reads
//
// Keep these choices local to this template so the persistent reference and
// the final winner are separate source files and can be compared directly.

// Dedicated unified-scale producer variant. Wave 0/1 share one 16-byte
// producer path, and the selected descriptor remains live across all
// persistent M tiles handled by the workgroup.

// 8-wave persistent fixed-B prefetch x4 variant.
//
// One workgroup computes up to four adjacent M tiles while keeping the B/SFB
// tile fixed. The next output tile's K=0 A/B/scale data is prefetched while
// the current output tile finishes.
//
// Required host launch:
//   grid.x = ceil_div(num_tiles_m, 4) * num_tiles_n
// The baseline host launches one workgroup per output tile and is intentionally
// kept unchanged; select this template together with the grid rule above.

#include <opus/hip_minimal.hpp>
#include <opus/opus.hpp>

#include "gemm_a8w8_mxfp8_scale_common.h"

// ---- barrier-density probe (variants/bardens) -------------------------
// Inserts N extra *unconditional* s_barrier into the main loop, evenly
// spread across the 16 MFMA groups.  Every wave executes every one, so
// arrival counts stay matched and results stay exact.  This measures the
// raw price of barrier density -- nothing else changes.
#ifndef MXFP8_EXTRA_BARS
#define MXFP8_EXTRA_BARS 0
#endif
#if MXFP8_EXTRA_BARS == 0
#define MXFP8_BAR_SLOT(i) do {} while (0)
#else
#define MXFP8_BAR_PERIOD (16 / (MXFP8_EXTRA_BARS))
#define MXFP8_BAR_SLOT(i)                                                  \
    do {                                                                   \
        if constexpr (((i) % MXFP8_BAR_PERIOD) == MXFP8_BAR_PERIOD - 1)    \
            __builtin_amdgcn_s_barrier();                                  \
    } while (0)
#endif


using opus::operator""_I;

template<class Traits>
struct fixed_b_prefetch_4_traits : Traits {
    static constexpr int OUTPUT_TILES_PER_WG = 4;
};

template<class T, int Begin, int End, class Mem, class Offsets, class V>
__device__ inline void load_b_range_scale(
    Mem& mem, const Offsets& offsets, V& dst) {
    opus::static_for<End - Begin>([&](auto j) {
        constexpr int i = Begin + decltype(j)::value;
        auto value = mem.template load<T::VEC_B>(offsets[i]);
        opus::set_slice(
            dst,
            value,
            opus::number<i * T::VEC_B>{},
            opus::number<(i + 1) * T::VEC_B>{});
    });
}

__device__ inline void sched_barrier_pairs_scale() {
    __builtin_amdgcn_sched_group_barrier(0x08, 1, 0);
    __builtin_amdgcn_sched_group_barrier(0x02, 2, 0);
    __builtin_amdgcn_sched_group_barrier(0x08, 1, 0);
    __builtin_amdgcn_sched_group_barrier(0x02, 2, 0);
}


template<class T, int HALF_TILE_M, int M_REPEAT, int N_GROUP, class MMA,
         class VC, class SFB>
__device__ inline void mma_scale_repeat_n2(
    MMA& mma,
    const typename opus::remove_cvref_t<MMA>::vtype_a& v_a,
    const typename opus::remove_cvref_t<MMA>::vtype_b& v_b,
    VC& v_c,
    unsigned int v_sfa,
    const SFB& v_sfb) {
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
        constexpr int scale_pack_b = NR / 4;
        constexpr int scale_op_sel_b = NR % 4;
        const unsigned int packed_sfb = [&]() {
            if constexpr (T::SCALE_N_CALLS <= 4)
                return static_cast<unsigned int>(v_sfb);
            else
                return static_cast<unsigned int>(v_sfb[scale_pack_b]);
        }();

        auto s_a = opus::slice(v_a, opus::number<a_offset>{}, opus::number<a_offset + a_len>{});
        auto s_b = opus::slice(v_b, opus::number<b_offset>{}, opus::number<b_offset + b_len>{});
        auto s_c = opus::slice(v_c, opus::number<c_offset>{}, opus::number<c_offset + c_len>{});
        s_c = base_mma{}(
            s_a,
            s_b,
            s_c,
            static_cast<int>(v_sfa),
            static_cast<int>(packed_sfb),
            opus::number<scale_op_sel_a>{},
            opus::number<scale_op_sel_b>{});
        opus::set_slice(v_c, s_c, opus::number<c_offset>{}, opus::number<c_offset + c_len>{});
    });
}

template<class T>
__device__ inline auto make_layout_gsfa_scale(int lane_id) {
    constexpr int scale_vec = 16;

    constexpr auto block_shape = opus::make_tuple(
        opus::number<T::WARP_SIZE>{},
        opus::number<scale_vec>{});
    constexpr auto block_dim = opus::make_tuple(
        opus::make_tuple(opus::p_dim{}),
        opus::make_tuple(opus::y_dim{}));

    return opus::make_layout<scale_vec>(
        block_shape,
        opus::unfold_x_stride(block_dim, block_shape, opus::tuple{opus::number<scale_vec>{}, 1_I}),
        opus::unfold_p_coord(block_dim, opus::tuple{lane_id}));
}

template<class T>
__device__ inline auto make_layout_ssfa_scale() {
    constexpr int scale_vec = 16;

    constexpr auto block_shape =
        opus::make_tuple(opus::number<scale_vec>{});
    constexpr auto block_dim =
        opus::make_tuple(opus::make_tuple(opus::y_dim{}));

    return opus::make_layout<scale_vec>(
        block_shape,
        opus::unfold_x_stride(block_dim, block_shape, opus::tuple{1_I}),
        opus::unfold_p_coord(block_dim, opus::tuple{}));
}

template<class T>
__device__ inline auto make_layout_gsfb_scale(int lane_id) {
    constexpr int scale_vec = 16;

    constexpr auto block_shape = opus::make_tuple(
        opus::number<T::WARP_SIZE>{},
        opus::number<scale_vec>{});
    constexpr auto block_dim = opus::make_tuple(
        opus::make_tuple(opus::p_dim{}),
        opus::make_tuple(opus::y_dim{}));

    return opus::make_layout<scale_vec>(
        block_shape,
        opus::unfold_x_stride(block_dim, block_shape, opus::tuple{opus::number<scale_vec>{}, 1_I}),
        opus::unfold_p_coord(block_dim, opus::tuple{lane_id}));
}

template<class T>
__device__ inline auto make_layout_ssfb_scale() {
    constexpr int scale_vec = 16;

    constexpr auto block_shape =
        opus::make_tuple(opus::number<scale_vec>{});
    constexpr auto block_dim =
        opus::make_tuple(opus::make_tuple(opus::y_dim{}));

    return opus::make_layout<scale_vec>(
        block_shape,
        opus::unfold_x_stride(block_dim, block_shape, opus::tuple{1_I}),
        opus::unfold_p_coord(block_dim, opus::tuple{}));
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
__global__ __launch_bounds__(Traits::BLOCK_SIZE, 2)
void gemm_a8w8_mxfp8_scale_kernel(opus_gemm_scale_kargs kargs) {
    using namespace opus;

    using T = fixed_b_prefetch_4_traits<opus::remove_cvref_t<Traits>>;
    using D_A = opus::fp8_t;
    using D_B = opus::fp8_t;
    using D_C = opus::fp32_t;
    using D_ACC = opus::fp32_t;
    using D_SF = unsigned char;
    using D_SF_PACK = unsigned int;

    const int num_tiles_m = ceil_div_scale(kargs.m, T::B_M);
    const int num_tiles_n = ceil_div_scale(kargs.n, T::B_N);
    const int num_tiles_k = ceil_div_scale(kargs.k, T::B_K);
    const int block_n = block_id_x() % num_tiles_n;
    const int first_block_m =
        (block_id_x() / num_tiles_n) * T::OUTPUT_TILES_PER_WG;
    const int col = block_n * T::B_N;
    int first_stage = 0;
    const int batch_id = block_id_z();
    const int wave_id =
        __builtin_amdgcn_readfirstlane(thread_id_x() / T::WARP_SIZE);
    const int lane_id = thread_id_x() % T::WARP_SIZE;
    const bool scale_producer_active = wave_id < 2;
    const bool scale_producer_is_sfa = wave_id == 0;
    const auto* g_sf_base = scale_producer_is_sfa
        ? reinterpret_cast<const D_SF*>(kargs.ptr_sfa) +
              batch_id * kargs.stride_sfa_batch +
              first_block_m * num_tiles_k * kargs.stride_sfa
        : reinterpret_cast<const D_SF*>(kargs.ptr_sfb) +
              batch_id * kargs.stride_sfb_batch +
              block_n * num_tiles_k * kargs.stride_sfb;
    auto g_sf = make_gmem(g_sf_base);
    const int stride_sf =
        scale_producer_is_sfa ? kargs.stride_sfa : kargs.stride_sfb;
    const int output_stride_sf =
        scale_producer_is_sfa ? num_tiles_k * kargs.stride_sfa : 0;

    for (int output_tile = 0; output_tile < T::OUTPUT_TILES_PER_WG;
         ++output_tile) {
    const int block_m = first_block_m + output_tile;
    if (block_m >= num_tiles_m) {
        break;
    }
    const int row = block_m * T::B_M;

    auto g_a = make_gmem(
        reinterpret_cast<const D_A*>(kargs.ptr_a) +
        batch_id * kargs.stride_a_batch + row * kargs.stride_a);
    auto g_b = make_gmem(
        reinterpret_cast<const D_B*>(kargs.ptr_b) +
        batch_id * kargs.stride_b_batch + col * kargs.stride_b);
    auto g_c = make_gmem(
        reinterpret_cast<D_C*>(kargs.ptr_c) +
        batch_id * kargs.stride_c_batch + row * kargs.stride_c + col);

    const int wave_id_m = wave_id % T::T_M;
    const int wave_id_n = wave_id / T::T_M;

    auto u_ga = make_layout_ga_scale<T>(lane_id, wave_id_m, wave_id_n, kargs.stride_a);
    auto u_sa = make_layout_sa_scale<T>(wave_id_m, wave_id_n);
    auto u_ra = make_layout_ra_scale<T>(lane_id, wave_id_m);
    auto u_gb = make_layout_gb_scale<T>(lane_id, wave_id_m, wave_id_n, kargs.stride_b);
    auto u_sb = make_layout_sb_scale<T>(wave_id_m, wave_id_n);
    // A single wave from each resident SIMD pair produces both logical
    // wave-N slices. Its partner can enter the tail MFMA sequence immediately.
    auto u_gb_producer_0 =
        make_layout_gb_scale<T>(lane_id, wave_id_m, 0, kargs.stride_b);
    auto u_sb_producer_0 = make_layout_sb_scale<T>(wave_id_m, 0);
    auto u_gb_producer_1 =
        make_layout_gb_scale<T>(lane_id, wave_id_m, 1, kargs.stride_b);
    auto u_sb_producer_1 = make_layout_sb_scale<T>(wave_id_m, 1);
    auto u_rb = make_layout_rb_scale<T>(lane_id, wave_id_n);

    const auto u_gsfa = make_layout_gsfa_scale<T>(lane_id);
    const auto u_ssfa = make_layout_ssfa_scale<T>();
    auto u_rsfa = make_layout_rsfa_scale<T>(lane_id, wave_id_m);
    auto u_rsfb_0 = make_layout_rsfb_scale<T>(lane_id, wave_id_n, 0);

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
    static_assert(T::packed_sfa_tile_elem == T::packed_sfb_tile_elem);
    auto* s_sf_ptr = scale_producer_is_sfa ? s_sfa.ptr : s_sfb.ptr;

    auto mma = make_tiled_mma<D_A, D_B, D_ACC>(
        seq<T::E_M, T::E_N, T::E_K>{},
        seq<T::T_M, T::T_N, T::T_K>{},
        seq<T::W_M, T::W_N, T::W_K>{},
        mfma_adaptor_swap_ab{});
    typename decltype(mma)::vtype_a v_a[2];
    typename decltype(mma)::vtype_b v_b;
    typename decltype(mma)::vtype_b v_b_second;
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
    auto gsf_offset = [&](int output_delta, int tile_k) {
        return (output_tile + output_delta) * output_stride_sf +
               tile_k * stride_sf;
    };
    auto ssfa_offset = [&](int stage) { return stage * smem_sfa_elem; };
    auto ssfb_offset = [&](int stage) { return stage * smem_sfb_elem; };
    auto load_sfb_pair = [&](int read_stage) {
        const auto offsets = opus::layout_to_offsets<4>(
            u_rsfb_0 + ssfb_offset(read_stage));
        const opus::u32_t addr = static_cast<opus::u32_t>(
            reinterpret_cast<__UINTPTR_TYPE__>(s_sfb.ptr + offsets[0]));
        opus::u32x2_t pair;
        // SFB half 1 is exactly 512 bytes after half 0. ST64 offsets are in
        // units of 64 dwords (256 bytes), hence offset1=2.
        asm volatile(
            "ds_read2st64_b32 %0, %1 offset0:0 offset1:2\n"
            : "=v"(pair)
            : "v"(addr)
            : "memory");
        return pair;
    };

    const int loops = num_tiles_k;
    int stage = first_stage;
    int scale_stage = first_stage;
    int tile = 0;

    if (output_tile == 0) {
        if (scale_producer_active) {
            async_load<16>(g_sf, s_sf_ptr, u_gsfa,
                           u_ssfa + ssfa_offset(stage), gsf_offset(0, 0));
        }
        async_load<T::VEC_A>(g_a, s_a.ptr, u_ga,
                             u_sa + sa_offset(stage, 0), ga_offset(0, 0));
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                             u_sb + sb_offset(stage, 0), gb_offset(0, 0));
        async_load<T::VEC_A>(g_a, s_a.ptr, u_ga,
                             u_sa + sa_offset(stage, 1), ga_offset(1, 0));
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                             u_sb + sb_offset(stage, 1), gb_offset(1, 0));

        s_waitcnt_vmcnt(0_I);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);
    }

    // Seed the rolling pipeline.  The retained path initially launches only
    // cold B.  The experimental tail-producer path launches the complete tile
    // here, then keeps that one-tile lead by distributing all producers across
    // the previous tile's final 12 MFMAs.
    if (loops > 1) {
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                             u_sb + sb_offset(stage ^ 1, 0), gb_offset(0, 1));
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                             u_sb + sb_offset(stage ^ 1, 1), gb_offset(1, 1));
        __builtin_amdgcn_sched_barrier(0);
    }

    // Main Loop
#pragma unroll 4
    for (tile = 0; tile + 1 < loops; ++tile) {
        const int next_stage = stage ^ 1;

        // Keeping the producer branch in a local callable preserves the
        // verified gfx950 control flow and register allocation.
        auto load_next_scale = [&]() {
            if (scale_producer_active) {
                async_load<16>(
                    g_sf, s_sf_ptr, u_gsfa,
                    u_ssfa + ssfa_offset(next_stage),
                    gsf_offset(0, tile + 1));
            }
        };

        v_sfa = __builtin_bit_cast(D_SF_PACK, load<4>(s_sfa, u_rsfa + ssfa_offset(scale_stage)));
        const auto v_sfb_pair = load_sfb_pair(scale_stage);
        v_sfb[0] = v_sfb_pair[0];
        v_sfb[1] = v_sfb_pair[1];
        v_a[0] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 0));
        __builtin_amdgcn_sched_barrier(0);

        v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 0));
        auto rb1_offsets_prefetch = opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(stage, 1));
        load_b_range_scale<T, 0, T::b_ds_read_insts / 2>(
            s_b, rb1_offsets_prefetch, v_b_second);
        __builtin_amdgcn_sched_barrier(0);

        load_next_scale();
        async_load<T::VEC_A>(g_a, s_a.ptr, u_ga, u_sa + sa_offset(next_stage, 0), ga_offset(0, tile + 1), 0_I, opus::number<0>{});
        async_load<T::VEC_A>(g_a, s_a.ptr, u_ga, u_sa + sa_offset(next_stage, 1), ga_offset(1, tile + 1), 0_I, opus::number<0>{});
        __builtin_amdgcn_sched_barrier(0);

        s_waitcnt_lgkmcnt(opus::number<8>{});
        __builtin_amdgcn_s_setprio(1);

        // A half 0 x B half 0 -> C[0][0] (64x64).
        mma_scale_repeat_n2<T, 0, 0, 0>(
            mma, v_a[0], v_b, v_c[0][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][0]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale();
        MXFP8_BAR_SLOT(0);


        v_a[1] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 1));
        s_waitcnt_lgkmcnt(opus::number<8>{});

        mma_scale_repeat_n2<T, 0, 0, 1>(
            mma, v_a[0], v_b, v_c[0][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][0]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale();
        MXFP8_BAR_SLOT(1);

        mma_scale_repeat_n2<T, 0, 1, 0>(
            mma, v_a[0], v_b, v_c[0][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][0]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale();
        MXFP8_BAR_SLOT(2);

        mma_scale_repeat_n2<T, 0, 1, 1>(
            mma, v_a[0], v_b, v_c[0][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][0]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale();
        MXFP8_BAR_SLOT(3);

        // A half 1 x B half 0 -> C[1][0] (64x64).
        mma_scale_repeat_n2<T, 1, 0, 0>(
            mma, v_a[1], v_b, v_c[1][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][0]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale();
        MXFP8_BAR_SLOT(4);

        mma_scale_repeat_n2<T, 1, 0, 1>(
            mma, v_a[1], v_b, v_c[1][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][0]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale();
        MXFP8_BAR_SLOT(5);

        mma_scale_repeat_n2<T, 1, 1, 0>(
            mma, v_a[1], v_b, v_c[1][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][0]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale();
        MXFP8_BAR_SLOT(6);

        mma_scale_repeat_n2<T, 1, 1, 1>(
            mma, v_a[1], v_b, v_c[1][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][0]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale();
        MXFP8_BAR_SLOT(7);

        auto rb1_offsets_tail = opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(stage, 1));
        load_b_range_scale<T, T::b_ds_read_insts / 2,
                           T::b_ds_read_insts>(
            s_b, rb1_offsets_tail, v_b_second);
        const auto& v_b_n1 = v_b_second;

        // A half 0 x B half 1 -> C[0][1] (64x64).
        mma_scale_repeat_n2<T, 0, 0, 0>(
            mma, v_a[0], v_b_n1, v_c[0][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale();
        MXFP8_BAR_SLOT(8);

        mma_scale_repeat_n2<T, 0, 0, 1>(
            mma, v_a[0], v_b_n1, v_c[0][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale();
        MXFP8_BAR_SLOT(9);


        // All operands for tile t are now resident in VGPRs.  Publish tile
        // t+1 and release tile t's LDS stage with the same barrier, then start
        // the cold B path for tile t+2 while the final 12 MFMAs of tile t run.
        __builtin_amdgcn_s_setprio(0);
        s_waitcnt_vmcnt(0_I);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);

        if (tile + 2 < loops) {
            constexpr int b_producer_wave_n =
                1;
            if (wave_id_n == b_producer_wave_n) {
                async_load<T::VEC_B>(g_b, s_b.ptr, u_gb_producer_0,
                                     u_sb_producer_0 + sb_offset(stage, 0),
                                     gb_offset(0, tile + 2));
                async_load<T::VEC_B>(g_b, s_b.ptr, u_gb_producer_1,
                                     u_sb_producer_1 + sb_offset(stage, 0),
                                     gb_offset(0, tile + 2));
                async_load<T::VEC_B>(g_b, s_b.ptr, u_gb_producer_0,
                                     u_sb_producer_0 + sb_offset(stage, 1),
                                     gb_offset(1, tile + 2));
                async_load<T::VEC_B>(g_b, s_b.ptr, u_gb_producer_1,
                                     u_sb_producer_1 + sb_offset(stage, 1),
                                     gb_offset(1, tile + 2));
            }
            __builtin_amdgcn_sched_barrier(0);
        }
        __builtin_amdgcn_s_setprio(1);

        mma_scale_repeat_n2<T, 0, 1, 0>(
            mma, v_a[0], v_b_n1, v_c[0][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale();
        MXFP8_BAR_SLOT(10);


        mma_scale_repeat_n2<T, 0, 1, 1>(
            mma, v_a[0], v_b_n1, v_c[0][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale();
        MXFP8_BAR_SLOT(11);


        // A half 1 x B half 1 -> C[1][1] (64x64).
        mma_scale_repeat_n2<T, 1, 0, 0>(
            mma, v_a[1], v_b_n1, v_c[1][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale();
        MXFP8_BAR_SLOT(12);


        mma_scale_repeat_n2<T, 1, 0, 1>(
            mma, v_a[1], v_b_n1, v_c[1][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale();
        MXFP8_BAR_SLOT(13);


        mma_scale_repeat_n2<T, 1, 1, 0>(
            mma, v_a[1], v_b_n1, v_c[1][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale();
        MXFP8_BAR_SLOT(14);

        mma_scale_repeat_n2<T, 1, 1, 1>(
            mma, v_a[1], v_b_n1, v_c[1][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale();
        MXFP8_BAR_SLOT(15);
        __builtin_amdgcn_s_setprio(0);
        stage = next_stage;
        scale_stage = next_stage;
    }

    // Consume the final resident tile without issuing more global loads.
    v_sfa = __builtin_bit_cast(D_SF_PACK, load<4>(s_sfa, u_rsfa + ssfa_offset(scale_stage)));
    const auto v_sfb_pair = load_sfb_pair(scale_stage);
    v_sfb[0] = v_sfb_pair[0];
    v_sfb[1] = v_sfb_pair[1];
    v_a[0] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 0));
    v_a[1] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 1));
    v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 0));
    s_waitcnt_lgkmcnt(0_I);

    const bool has_next_output =
        output_tile + 1 < T::OUTPUT_TILES_PER_WG &&
        block_m + 1 < num_tiles_m;
    const int next_output_stage = stage ^ 1;
    if (has_next_output) {
        const int next_block_m = block_m + 1;
        const int next_row = next_block_m * T::B_M;
        auto g_a_next = make_gmem(
            reinterpret_cast<const D_A*>(kargs.ptr_a) +
            batch_id * kargs.stride_a_batch + next_row * kargs.stride_a);
        if (scale_producer_active) {
            async_load<16>(
                g_sf, s_sf_ptr, u_gsfa,
                u_ssfa + ssfa_offset(next_output_stage), gsf_offset(1, 0));
        }
        async_load<T::VEC_A>(g_a_next, s_a.ptr, u_ga,
                             u_sa + sa_offset(next_output_stage, 0), ga_offset(0, 0));
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                             u_sb + sb_offset(next_output_stage, 0), gb_offset(0, 0));
        async_load<T::VEC_A>(g_a_next, s_a.ptr, u_ga,
                             u_sa + sa_offset(next_output_stage, 1), ga_offset(1, 0));
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                             u_sb + sb_offset(next_output_stage, 1), gb_offset(1, 0));
        __builtin_amdgcn_sched_barrier(0);
    }

    __builtin_amdgcn_s_setprio(1);
    mma_scale_repeat_n2<T, 0, 0, 0>(mma, v_a[0], v_b, v_c[0][0], v_sfa, v_sfb[0]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][0]);
        asm volatile("" : "+v"(v_c_pin[0]) ::);
    }
    sched_barrier_pairs_scale();

    mma_scale_repeat_n2<T, 0, 0, 1>(mma, v_a[0], v_b, v_c[0][0], v_sfa, v_sfb[0]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][0]);
        asm volatile("" : "+v"(v_c_pin[0]) ::);
    }
    sched_barrier_pairs_scale();

    mma_scale_repeat_n2<T, 0, 1, 0>(mma, v_a[0], v_b, v_c[0][0], v_sfa, v_sfb[0]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][0]);
        asm volatile("" : "+v"(v_c_pin[1]) ::);
    }
    sched_barrier_pairs_scale();

    mma_scale_repeat_n2<T, 0, 1, 1>(mma, v_a[0], v_b, v_c[0][0], v_sfa, v_sfb[0]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][0]);
        asm volatile("" : "+v"(v_c_pin[1]) ::);
    }
    sched_barrier_pairs_scale();


    mma_scale_repeat_n2<T, 1, 0, 0>(mma, v_a[1], v_b, v_c[1][0], v_sfa, v_sfb[0]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][0]);
        asm volatile("" : "+v"(v_c_pin[0]) ::);
    }
    sched_barrier_pairs_scale();

    mma_scale_repeat_n2<T, 1, 0, 1>(mma, v_a[1], v_b, v_c[1][0], v_sfa, v_sfb[0]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][0]);
        asm volatile("" : "+v"(v_c_pin[0]) ::);
    }
    sched_barrier_pairs_scale();

    mma_scale_repeat_n2<T, 1, 1, 0>(mma, v_a[1], v_b, v_c[1][0], v_sfa, v_sfb[0]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][0]);
        asm volatile("" : "+v"(v_c_pin[1]) ::);
    }
    sched_barrier_pairs_scale();

    mma_scale_repeat_n2<T, 1, 1, 1>(mma, v_a[1], v_b, v_c[1][0], v_sfa, v_sfb[0]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][0]);
        asm volatile("" : "+v"(v_c_pin[1]) ::);
    }
    sched_barrier_pairs_scale();


    v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 1));

    mma_scale_repeat_n2<T, 0, 0, 0>(mma, v_a[0], v_b, v_c[0][1], v_sfa, v_sfb[1]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
        asm volatile("" : "+v"(v_c_pin[0]) ::);
    }
    sched_barrier_pairs_scale();

    mma_scale_repeat_n2<T, 0, 0, 1>(mma, v_a[0], v_b, v_c[0][1], v_sfa, v_sfb[1]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
        asm volatile("" : "+v"(v_c_pin[0]) ::);
    }
    sched_barrier_pairs_scale();

    mma_scale_repeat_n2<T, 0, 1, 0>(mma, v_a[0], v_b, v_c[0][1], v_sfa, v_sfb[1]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
        asm volatile("" : "+v"(v_c_pin[1]) ::);
    }
    sched_barrier_pairs_scale();

    mma_scale_repeat_n2<T, 0, 1, 1>(mma, v_a[0], v_b, v_c[0][1], v_sfa, v_sfb[1]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
        asm volatile("" : "+v"(v_c_pin[1]) ::);
    }
    sched_barrier_pairs_scale();


    mma_scale_repeat_n2<T, 1, 0, 0>(mma, v_a[1], v_b, v_c[1][1], v_sfa, v_sfb[1]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
        asm volatile("" : "+v"(v_c_pin[0]) ::);
    }
    sched_barrier_pairs_scale();

    mma_scale_repeat_n2<T, 1, 0, 1>(mma, v_a[1], v_b, v_c[1][1], v_sfa, v_sfb[1]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
        asm volatile("" : "+v"(v_c_pin[0]) ::);
    }
    sched_barrier_pairs_scale();

    mma_scale_repeat_n2<T, 1, 1, 0>(mma, v_a[1], v_b, v_c[1][1], v_sfa, v_sfb[1]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
        asm volatile("" : "+v"(v_c_pin[1]) ::);
    }
    sched_barrier_pairs_scale();

    mma_scale_repeat_n2<T, 1, 1, 1>(mma, v_a[1], v_b, v_c[1][1], v_sfa, v_sfb[1]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
        asm volatile("" : "+v"(v_c_pin[1]) ::);
    }
    sched_barrier_pairs_scale();
    __builtin_amdgcn_s_setprio(0);

    if (has_next_output) {
        s_waitcnt_vmcnt(0_I);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);
        first_stage = next_output_stage;
    }

    auto p_coord_c = opus::make_tuple(wave_id_m, lane_id % mma.grpn_c, wave_id_n, lane_id / mma.grpn_c);
    auto u_gc = partition_layout_c<T::VEC_C>(mma, opus::make_tuple(kargs.stride_c, 1_I), p_coord_c);

    auto c_offset = [&](int half_tile_m, int half_tile_n) {
        return half_tile_m * T::HALF_B_M * kargs.stride_c + half_tile_n * T::HALF_B_N;
    };

    store<T::VEC_C>(g_c, v_c[0][0], u_gc, c_offset(0, 0), opus::number<2>{});
    store<T::VEC_C>(g_c, v_c[0][1], u_gc, c_offset(0, 1), opus::number<2>{});
    store<T::VEC_C>(g_c, v_c[1][0], u_gc, c_offset(1, 0), opus::number<2>{});
    store<T::VEC_C>(g_c, v_c[1][1], u_gc, c_offset(1, 1), opus::number<2>{});
    }
}
