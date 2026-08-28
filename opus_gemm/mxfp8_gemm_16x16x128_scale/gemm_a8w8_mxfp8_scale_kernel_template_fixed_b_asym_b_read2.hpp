#pragma once

// Dedicated final pipeline:
//   8-wave persistent fixed-B prefetch x4
//   + one B producer wave per resident SIMD pair
//   + paired SFB LDS reads
//
// Keep these choices local to this template so the persistent reference and
// the final winner are separate source files and can be compared directly.
#define MXFP8_SFB_READ2ST64 1
#define MXFP8_ASYMMETRIC_B_PRODUCER 1

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

using opus::operator""_I;

#ifndef MXFP8_SCALE_OUTPUT_TILES_PER_WG
#define MXFP8_SCALE_OUTPUT_TILES_PER_WG 4
#endif

template<class Traits>
struct fixed_b_prefetch_4_traits : Traits {
    static constexpr int OUTPUT_TILES_PER_WG =
        MXFP8_SCALE_OUTPUT_TILES_PER_WG;
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

template<class T>
__device__ inline auto make_layout_gsfa_scale(int lane_id) {
#if defined(MXFP8_EXPERIMENTAL_4WAVE_LAYOUTS)
    constexpr int scale_vec =
        T::packed_sfa_tile_elem / T::WARP_SIZE;
    static_assert(scale_vec == 8 || scale_vec == 16);
#else
    constexpr int scale_vec = 16;
#endif

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
#if defined(MXFP8_EXPERIMENTAL_4WAVE_LAYOUTS)
    constexpr int scale_vec =
        T::packed_sfa_tile_elem / T::WARP_SIZE;
    static_assert(scale_vec == 8 || scale_vec == 16);
#else
    constexpr int scale_vec = 16;
#endif

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
#if defined(MXFP8_EXPERIMENTAL_4WAVE_LAYOUTS)
    constexpr int scale_vec =
        T::packed_sfb_tile_elem / T::WARP_SIZE;
    static_assert(scale_vec == 8 || scale_vec == 16);
#else
    constexpr int scale_vec = 16;
#endif

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
#if defined(MXFP8_EXPERIMENTAL_4WAVE_LAYOUTS)
    constexpr int scale_vec =
        T::packed_sfb_tile_elem / T::WARP_SIZE;
    static_assert(scale_vec == 8 || scale_vec == 16);
#else
    constexpr int scale_vec = 16;
#endif

    constexpr auto block_shape =
        opus::make_tuple(opus::number<scale_vec>{});
    constexpr auto block_dim =
        opus::make_tuple(opus::make_tuple(opus::y_dim{}));

    return opus::make_layout<scale_vec>(
        block_shape,
        opus::unfold_x_stride(block_dim, block_shape, opus::tuple{1_I}),
        opus::unfold_p_coord(block_dim, opus::tuple{}));
}

#if defined(MXFP8_EXPERIMENTAL_4WAVE_LAYOUTS)
// A 256-byte linear scale slice, used to split a 512-byte tile into two
// direct-to-LDS operations.  CDNA's raw buffer-to-LDS path has no 8-byte
// operation, and simply changing an 8-byte layout to async_load<4> would make
// adjacent lanes overlap because the implicit LDS lane stride also becomes 4.
template<class T>
__device__ inline auto make_layout_gsf4_scale(int lane_id) {
    constexpr auto block_shape = opus::make_tuple(
        opus::number<T::WARP_SIZE>{}, opus::number<4>{});
    constexpr auto block_dim = opus::make_tuple(
        opus::make_tuple(opus::p_dim{}),
        opus::make_tuple(opus::y_dim{}));
    return opus::make_layout<4>(
        block_shape,
        opus::unfold_x_stride(
            block_dim, block_shape, opus::tuple{opus::number<4>{}, 1_I}),
        opus::unfold_p_coord(block_dim, opus::tuple{lane_id}));
}

template<class T>
__device__ inline auto make_layout_ssf4_scale() {
    constexpr auto block_shape = opus::make_tuple(opus::number<4>{});
    constexpr auto block_dim =
        opus::make_tuple(opus::make_tuple(opus::y_dim{}));
    return opus::make_layout<4>(
        block_shape,
        opus::unfold_x_stride(block_dim, block_shape, opus::tuple{1_I}),
        opus::unfold_p_coord(block_dim, opus::tuple{}));
}
#endif

__device__ inline void sched_barrier_pairs_scale() {
    __builtin_amdgcn_sched_group_barrier(0x08, 1, 0);
    __builtin_amdgcn_sched_group_barrier(0x02, 2, 0);
    __builtin_amdgcn_sched_group_barrier(0x08, 1, 0);
    __builtin_amdgcn_sched_group_barrier(0x02, 2, 0);
}

#if defined(MXFP8_WIDE_AGPR_FRAGMENTS)
template<int SCALE_SEL_A, int SCALE_SEL_B, class VA, class VB, class VC>
__device__ __forceinline__ void mfma_scale_agpr_fragment(
    const VA& logical_a,
    const VB& logical_b,
    VC& accum,
    unsigned int scale_a,
    unsigned int scale_b) {
    const auto a_bits = __builtin_bit_cast(opus::i32x8_t, logical_a);
    const auto b_bits = __builtin_bit_cast(opus::i32x8_t, logical_b);

    // mfma_adaptor_swap_ab swaps both data and scale operands.  Therefore
    // logical B is hardware src0/scale0 and logical A is src1/scale1.
    // The low/high op_sel bits form the two-bit packed-scale selector.
    __asm__ volatile(
        "v_mfma_scale_f32_16x16x128_f8f6f4 "
        "%0, %2, %1, %0, %4, %3 "
        "op_sel:[%5,%6,0] op_sel_hi:[%7,%8,0]\n"
        : "+a"(accum)
        : "v"(a_bits), "v"(b_bits), "v"(scale_a), "v"(scale_b),
          "n"(SCALE_SEL_B & 1), "n"(SCALE_SEL_A & 1),
          "n"((SCALE_SEL_B >> 1) & 1),
          "n"((SCALE_SEL_A >> 1) & 1));
}
#endif

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
        // A wide-N wave owns eight N repeats.  Scaled MFMA can select only
        // one of four bytes from a packed scale dword, so repeats 4..7 use
        // the second dword and wrap the byte selector.
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
#if defined(MXFP8_WIDE_AGPR_FRAGMENTS)
        // Keep each 16x16 output fragment as an independent fp32x4 AGPR
        // chain.  A single 256-dword aggregate is too wide for clang's inline
        // asm constraint classes; sixty-four 128-bit read/write constraints
        // fit the physical 256-entry AGPR file exactly and remain stable over
        // the K loop.
        static_assert(c_len == 4);
        auto& s_c = v_c[c_offset / c_len];
        mfma_scale_agpr_fragment<scale_op_sel_a, scale_op_sel_b>(
            s_a, s_b, s_c, static_cast<unsigned int>(v_sfa), packed_sfb);
#else
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
#endif
    });
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

#if defined(MXFP8_ASYMMETRIC_A_PRODUCER_WAVE_N) || \
    defined(MXFP8_ASYMMETRIC_A_ONE_HALF)
template<class T>
__device__ inline auto make_layout_ga_asymmetric_scale(
    int lane_id, int wave_id_m, int stride_a) {
    constexpr int threads_k = T::B_K / T::VEC_A;
    constexpr int threads_m_per_wave = T::WARP_SIZE / threads_k;
    constexpr int producer_waves = T::T_M;
    constexpr int threads_m_per_block =
        producer_waves * threads_m_per_wave;

    constexpr auto ga_block_shape = opus::make_tuple(
        opus::number<T::HALF_B_M / threads_m_per_block>{},
        opus::number<threads_m_per_wave>{},
        opus::number<producer_waves>{},
        opus::number<threads_k>{},
        opus::number<T::VEC_A>{});
    constexpr auto ga_block_dim = opus::make_tuple(
        opus::make_tuple(opus::y_dim{}, opus::p_dim{}, opus::p_dim{}),
        opus::make_tuple(opus::p_dim{}, opus::y_dim{}));

    return opus::make_layout<T::VEC_A>(
        ga_block_shape,
        opus::unfold_x_stride(
            ga_block_dim, ga_block_shape,
            opus::tuple{stride_a, 1_I}),
        opus::unfold_p_coord(
            ga_block_dim,
            opus::tuple{lane_id / threads_k, wave_id_m,
                        lane_id % threads_k}));
}

template<class T>
__device__ inline auto make_layout_sa_asymmetric_scale(int wave_id_m) {
    constexpr int producer_waves = T::T_M;
    constexpr auto sa_block_shape = opus::make_tuple(
        opus::number<T::smem_m_rep / producer_waves>{},
        opus::number<producer_waves>{},
        opus::number<T::VEC_A>{});
    constexpr auto sa_block_dim = opus::make_tuple(
        opus::make_tuple(opus::y_dim{}, opus::p_dim{}),
        opus::make_tuple(opus::y_dim{}));

    return opus::make_layout(
        sa_block_shape,
        opus::unfold_x_stride(
            sa_block_dim, sa_block_shape,
            opus::tuple{
                opus::number<T::smem_linear_wave + T::smem_padding>{},
                1_I}),
        opus::unfold_p_coord(sa_block_dim, opus::tuple{wave_id_m}));
}
#endif

template<class T>
__device__ inline auto make_layout_ra_scale(int lane_id, int wave_id_m) {

#if defined(MXFP8_EXPERIMENTAL_4WAVE_LAYOUTS)
    // One producer wave writes smem_sub logical rows per 1 KiB LDS chunk.
    // The original 4x2 topology happened to make this split equal T_N (=2),
    // but it remains 2 for the 4x1 topology.  Derive it from the physical
    // producer image instead of using the logical wave-N count.
    constexpr int m_wave_split =
        T::T_M * T::smem_sub / T::W_M;
    static_assert(m_wave_split > 0);
    static_assert(T::T_M % m_wave_split == 0);

    constexpr auto ra_block_shape = opus::make_tuple(
        opus::number<T::E_M>{},
        opus::number<T::T_M / m_wave_split>{},
        opus::number<T::T_M>{},
        opus::number<m_wave_split>{},
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
        opus::unfold_p_coord(ra_block_dim, opus::tuple{wave_id_m / m_wave_split, lane_id_m % T::T_M, wave_id_m % m_wave_split, lane_id_m / T::T_M, lane_id / T::W_M}));
#else
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
#endif
}

template<class T>
__device__ inline auto make_layout_rb_scale(int lane_id, int wave_id_n) {

#if defined(MXFP8_EXPERIMENTAL_4WAVE_LAYOUTS)
    constexpr int producer_rows_per_repeat = T::T_M * T::smem_sub;
    constexpr int consumer_rows_per_repeat = T::T_N * T::W_N;
    constexpr int n_repeat_split =
        producer_rows_per_repeat / consumer_rows_per_repeat;

    if constexpr (producer_rows_per_repeat > consumer_rows_per_repeat) {
        static_assert(producer_rows_per_repeat % consumer_rows_per_repeat == 0);
        static_assert(T::E_N % n_repeat_split == 0);
        // In the 4x1 topology two adjacent logical N repeats occupy the same
        // producer chunk: the high repeat bit selects the chunk and the low
        // bit selects one of its two four-row groups.
        constexpr auto rb_block_shape = opus::make_tuple(
            opus::number<T::E_N / n_repeat_split>{},
            opus::number<T::T_M>{},
            opus::number<n_repeat_split>{},
            opus::number<T::T_N>{},
            opus::number<T::W_N / T::T_M>{},
            opus::number<T::E_K>{},
            opus::number<T::W_N * T::W_K / T::WARP_SIZE / T::VEC_B>{},
            opus::number<T::WARP_SIZE / T::W_N>{},
            opus::number<T::VEC_B>{});

        constexpr auto rb_block_dim = opus::make_tuple(
            opus::make_tuple(opus::y_dim{}, opus::p_dim{}),
            opus::make_tuple(opus::y_dim{}, opus::p_dim{}, opus::p_dim{},
                             opus::y_dim{}, opus::y_dim{}, opus::p_dim{},
                             opus::y_dim{}));

        const int lane_id_n = lane_id % T::W_N;
        return opus::make_layout<T::VEC_B>(
            rb_block_shape,
            opus::unfold_x_stride(
                rb_block_dim, rb_block_shape,
                opus::tuple{
                    opus::number<T::smem_linear_wave + T::smem_padding>{},
                    1_I}),
            opus::unfold_p_coord(
                rb_block_dim,
                opus::tuple{lane_id_n % T::T_M, wave_id_n,
                            lane_id_n / T::T_M,
                            lane_id / T::W_N}));
    } else if constexpr (producer_rows_per_repeat == consumer_rows_per_repeat) {

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
    } else {
        // In the 2x2 topology one logical N repeat spans two producer row
        // groups.  wave_id_n therefore belongs in the chunk coordinate rather
        // than in the row-within-chunk coordinate.
        static_assert(consumer_rows_per_repeat % producer_rows_per_repeat == 0);
        static_assert(T::W_N == producer_rows_per_repeat);
        constexpr auto rb_block_shape = opus::make_tuple(
            opus::number<T::E_N>{},
            opus::number<T::T_N>{},
            opus::number<T::T_M>{},
            opus::number<T::W_N / T::T_M>{},
            opus::number<T::E_K>{},
            opus::number<T::W_N * T::W_K / T::WARP_SIZE / T::VEC_B>{},
            opus::number<T::WARP_SIZE / T::W_N>{},
            opus::number<T::VEC_B>{});
        constexpr auto rb_block_dim = opus::make_tuple(
            opus::make_tuple(opus::y_dim{}, opus::p_dim{}, opus::p_dim{}),
            opus::make_tuple(opus::p_dim{}, opus::y_dim{}, opus::y_dim{},
                             opus::p_dim{}, opus::y_dim{}));
        const int lane_id_n = lane_id % T::W_N;
        return opus::make_layout<T::VEC_B>(
            rb_block_shape,
            opus::unfold_x_stride(
                rb_block_dim, rb_block_shape,
                opus::tuple{
                    opus::number<T::smem_linear_wave + T::smem_padding>{},
                    1_I}),
            opus::unfold_p_coord(
                rb_block_dim,
                opus::tuple{wave_id_n, lane_id_n % T::T_M,
                            lane_id_n / T::T_M,
                            lane_id / T::W_N}));
    }
#else
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
#endif
}

template<class Traits>
#if defined(MXFP8_WIDE_N_WAVE)
__global__ __launch_bounds__(Traits::BLOCK_SIZE, 1)
#else
__global__ __launch_bounds__(Traits::BLOCK_SIZE, 2)
#endif
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
#if defined(MXFP8_A0_THREE_SLOT)
    // A half 0 is prefetched one complete K tile farther ahead than A half 1.
    // The extra slot lets A0(t+2) remain outstanding across the tile-t publish
    // barrier without overwriting either A0(t) or the resident A0(t+1).
    int a0_current = 0;
    int a0_next = 1;
    int a0_spare = 2;
#endif
#if defined(MXFP8_B0_THREE_SLOT)
    // B half 0 has one extra LDS slot. It is dead after the first 16 MFMAs,
    // so tile t+2 can be launched into the spare slot before the mid-tile
    // barrier while B half 1 continues to use the ordinary two-stage ring.
    int b0_current = 0;
    int b0_next = 1;
    int b0_spare = 2;
#endif

    for (int output_tile = 0; output_tile < T::OUTPUT_TILES_PER_WG;
         ++output_tile) {
    const int block_m = first_block_m + output_tile;
    if (block_m >= num_tiles_m) {
        break;
    }
    const int row = block_m * T::B_M;

    const int batch_id = block_id_z();
    const int wave_id = __builtin_amdgcn_readfirstlane(thread_id_x() / T::WARP_SIZE);
    const int lane_id = thread_id_x() % T::WARP_SIZE;

    auto g_a = make_gmem(
        reinterpret_cast<const D_A*>(kargs.ptr_a) +
        batch_id * kargs.stride_a_batch + row * kargs.stride_a);
    auto g_b = make_gmem(
        reinterpret_cast<const D_B*>(kargs.ptr_b) +
        batch_id * kargs.stride_b_batch + col * kargs.stride_b);
    auto g_c = make_gmem(
        reinterpret_cast<D_C*>(kargs.ptr_c) +
        batch_id * kargs.stride_c_batch + row * kargs.stride_c + col);

    // Scale tiles are prepacked in the exact consumer-major LDS order.
    auto g_sfa = make_gmem(
        reinterpret_cast<const D_SF*>(kargs.ptr_sfa) +
        batch_id * kargs.stride_sfa_batch +
        block_m * num_tiles_k * kargs.stride_sfa);
    auto g_sfb = make_gmem(
        reinterpret_cast<const D_SF*>(kargs.ptr_sfb) +
        batch_id * kargs.stride_sfb_batch +
        block_n * num_tiles_k * kargs.stride_sfb);

    const int wave_id_m = wave_id % T::T_M;
    const int wave_id_n = wave_id / T::T_M;

    auto u_ga = make_layout_ga_scale<T>(lane_id, wave_id_m, wave_id_n, kargs.stride_a);
    auto u_sa = make_layout_sa_scale<T>(wave_id_m, wave_id_n);
    auto u_ra = make_layout_ra_scale<T>(lane_id, wave_id_m);
    auto u_gb = make_layout_gb_scale<T>(lane_id, wave_id_m, wave_id_n, kargs.stride_b);
    auto u_sb = make_layout_sb_scale<T>(wave_id_m, wave_id_n);
#if defined(MXFP8_ASYMMETRIC_B_PRODUCER)
    // A single wave from each resident SIMD pair produces both logical
    // wave-N slices. Its partner can enter the tail MFMA sequence immediately.
    auto u_gb_producer_0 =
        make_layout_gb_scale<T>(lane_id, wave_id_m, 0, kargs.stride_b);
    auto u_sb_producer_0 = make_layout_sb_scale<T>(wave_id_m, 0);
    auto u_gb_producer_1 =
        make_layout_gb_scale<T>(lane_id, wave_id_m, 1, kargs.stride_b);
    auto u_sb_producer_1 = make_layout_sb_scale<T>(wave_id_m, 1);
#endif
#if defined(MXFP8_ASYMMETRIC_A_PRODUCER_WAVE_N) || \
    defined(MXFP8_ASYMMETRIC_A_ONE_HALF)
    auto u_ga_producer =
        make_layout_ga_asymmetric_scale<T>(lane_id, wave_id_m, kargs.stride_a);
    auto u_sa_producer = make_layout_sa_asymmetric_scale<T>(wave_id_m);
#endif
    auto u_rb = make_layout_rb_scale<T>(lane_id, wave_id_n);

    const auto u_gsfa = make_layout_gsfa_scale<T>(lane_id);
    const auto u_ssfa = make_layout_ssfa_scale<T>();
    const auto u_gsfb = make_layout_gsfb_scale<T>(lane_id);
    const auto u_ssfb = make_layout_ssfb_scale<T>();
#if defined(MXFP8_EXPERIMENTAL_4WAVE_LAYOUTS)
    const auto u_gsf4 = make_layout_gsf4_scale<T>(lane_id);
    const auto u_ssf4 = make_layout_ssf4_scale<T>();
#endif
    auto u_rsfa = make_layout_rsfa_scale<T>(lane_id, wave_id_m);
    auto u_rsfb_0 = make_layout_rsfb_scale<T>(lane_id, wave_id_n, 0);
#if !defined(MXFP8_SFB_READ2ST64)
    auto u_rsfb_1 = make_layout_rsfb_scale<T>(lane_id, wave_id_n, 1);
#endif

    constexpr int smem_a_elem = T::smem_m_rep * (T::smem_linear_wave + T::smem_padding);
    constexpr int smem_b_elem = T::smem_n_rep * (T::smem_linear_wave + T::smem_padding);
#if defined(MXFP8_A0_THREE_SLOT)
    // Physical A halves: A0 slots 0/1/2 -> 0/2/4, A1 stages 0/1 -> 1/3.
    __shared__ char smem_a[smem_a_elem * 5 * sizeof(D_A)];
#elif defined(MXFP8_SINGLE_STAGE_A)
    __shared__ char smem_a[smem_a_elem * 2 * sizeof(D_A)];
#else
    __shared__ char smem_a[smem_a_elem * 4 * sizeof(D_A)];
#endif
#if defined(MXFP8_B0_THREE_SLOT)
    // Physical B halves: B0 slots 0/1/2 -> 0/2/4, B1 stages 0/1 -> 1/3.
    __shared__ char smem_b[smem_b_elem * 5 * sizeof(D_B)];
#elif defined(MXFP8_SINGLE_STAGE_B)
    __shared__ char smem_b[smem_b_elem * 2 * sizeof(D_B)];
#else
    __shared__ char smem_b[smem_b_elem * 4 * sizeof(D_B)];
#endif
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
    typename decltype(mma)::vtype_b v_b_second;
#if defined(MXFP8_WIDE_AGPR_FRAGMENTS)
    using AccFragment = vector_t<D_ACC, decltype(mma)::mma_c_len>;
    static_assert(decltype(mma)::mma_c_len == 4);
    static_assert(T::E_M * T::E_N == 16);
    AccFragment v_c[2][2][T::E_M * T::E_N]{};
#else
    typename decltype(mma)::vtype_c v_c[2][2];
    clear(v_c[0][0]);
    clear(v_c[0][1]);
    clear(v_c[1][0]);
    clear(v_c[1][1]);
#endif
    D_SF_PACK v_sfa;
#if defined(MXFP8_WIDE_N_WAVE)
    using D_SFB_PACK = vector_t<D_SF_PACK, T::SCALE_N_CALLS / 4>;
    static_assert(T::SCALE_N_CALLS == 8);
    D_SFB_PACK v_sfb[T::SCALE_N_HALVES];
#else
    D_SF_PACK v_sfb[T::SCALE_N_HALVES];
#endif
    auto ga_offset = [&](int half_tile_m, int tile_k) { return half_tile_m * T::HALF_B_M * kargs.stride_a + tile_k * T::B_K; };
#if defined(MXFP8_PRESHUFFLE_B)
    // B is packed as [batch][K/B_K][N][B_K].  Rows within one K panel
    // remain stride_b (= B_K) apart, while advancing tile_k skips a whole
    // N x B_K panel.  The per-lane B layout and the LDS/MFMA path are
    // otherwise identical to the ordinary row-major-B kernel.
    auto gb_offset = [&](int half_tile_n, int tile_k) {
        return half_tile_n * T::HALF_B_N * kargs.stride_b
             + tile_k * kargs.n * T::B_K;
    };
#else
    auto gb_offset = [&](int half_tile_n, int tile_k) { return half_tile_n * T::HALF_B_N * kargs.stride_b + tile_k * T::B_K; };
#endif
#if defined(MXFP8_A0_THREE_SLOT)
    auto sa0_offset = [&](int slot) { return slot * 2 * smem_a_elem; };
    auto sa1_offset = [&](int a_stage) {
        return (a_stage * 2 + 1) * smem_a_elem;
    };
#elif defined(MXFP8_SINGLE_STAGE_A)
    auto sa_offset = [&](int, int half_tile_m) {
        return half_tile_m * smem_a_elem;
    };
#else
    auto sa_offset = [&](int stage, int half_tile_m) { return (stage * 2 + half_tile_m) * smem_a_elem; };
#endif
#if defined(MXFP8_B0_THREE_SLOT)
    auto sb0_offset = [&](int slot) { return slot * 2 * smem_b_elem; };
    auto sb1_offset = [&](int stage) { return (stage * 2 + 1) * smem_b_elem; };
#elif defined(MXFP8_SINGLE_STAGE_B)
    auto sb_offset = [&](int, int half_tile_n) {
        return half_tile_n * smem_b_elem;
    };
#else
    auto sb_offset = [&](int stage, int half_tile_n) { return (stage * 2 + half_tile_n) * smem_b_elem; };
#endif
    auto gsfa_offset = [&](int tile_k) { return tile_k * kargs.stride_sfa; };
    auto gsfb_offset = [&](int tile_k) { return tile_k * kargs.stride_sfb; };
    auto ssfa_offset = [&](int stage) { return stage * smem_sfa_elem; };
    auto ssfb_offset = [&](int stage) { return stage * smem_sfb_elem; };
#if defined(MXFP8_EXPERIMENTAL_4WAVE_LAYOUTS)
    constexpr int sfa_load_vec =
        T::packed_sfa_tile_elem / T::WARP_SIZE;
    constexpr int sfb_load_vec =
        T::packed_sfb_tile_elem / T::WARP_SIZE;
    static_assert(sfa_load_vec == 8 || sfa_load_vec == 16);
    static_assert(sfb_load_vec == 8 || sfb_load_vec == 16);
    auto async_load_sfa_tile = [&](auto& source, int dst_stage, int src_tile) {
        if constexpr (sfa_load_vec == 8) {
            constexpr int slice_elem = T::WARP_SIZE * 4;
            async_load<4>(source, s_sfa.ptr, u_gsf4,
                          u_ssf4 + ssfa_offset(dst_stage),
                          gsfa_offset(src_tile));
            async_load<4>(source, s_sfa.ptr, u_gsf4,
                          u_ssf4 + ssfa_offset(dst_stage) + slice_elem,
                          gsfa_offset(src_tile) + slice_elem);
        } else {
            async_load<sfa_load_vec>(
                source, s_sfa.ptr, u_gsfa,
                u_ssfa + ssfa_offset(dst_stage), gsfa_offset(src_tile));
        }
    };
    auto async_load_sfb_tile = [&](int dst_stage, int src_tile) {
        if constexpr (sfb_load_vec == 8) {
            constexpr int slice_elem = T::WARP_SIZE * 4;
            async_load<4>(g_sfb, s_sfb.ptr, u_gsf4,
                          u_ssf4 + ssfb_offset(dst_stage),
                          gsfb_offset(src_tile));
            async_load<4>(g_sfb, s_sfb.ptr, u_gsf4,
                          u_ssf4 + ssfb_offset(dst_stage) + slice_elem,
                          gsfb_offset(src_tile) + slice_elem);
        } else {
            async_load<sfb_load_vec>(
                g_sfb, s_sfb.ptr, u_gsfb,
                u_ssfb + ssfb_offset(dst_stage), gsfb_offset(src_tile));
        }
    };
#endif
#if defined(MXFP8_SFB_READ2ST64)
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
#endif

    const int loops = num_tiles_k;
    int stage = first_stage;
    int scale_stage = first_stage;
    int tile = 0;

    if (output_tile == 0) {
#if defined(MXFP8_SCALE_PRODUCER_WAVE_N1)
        if (wave_id == T::T_M) {
#else
        if (wave_id == 0) {
#endif
#if defined(MXFP8_EXPERIMENTAL_4WAVE_LAYOUTS)
            async_load_sfa_tile(g_sfa, stage, 0);
#else
            async_load<16>(g_sfa, s_sfa.ptr, u_gsfa,
                           u_ssfa + ssfa_offset(stage), gsfa_offset(0));
#endif
#if defined(MXFP8_SCALE_PRODUCER_WAVE_N1)
        } else if (wave_id == T::T_M + 1) {
#else
        } else if (wave_id == 1) {
#endif
#if defined(MXFP8_EXPERIMENTAL_4WAVE_LAYOUTS)
            async_load_sfb_tile(stage, 0);
#else
            async_load<16>(g_sfb, s_sfb.ptr, u_gsfb,
                           u_ssfb + ssfb_offset(stage), gsfb_offset(0));
#endif
        }
#if defined(MXFP8_A0_THREE_SLOT)
        async_load<T::VEC_A>(g_a, s_a.ptr, u_ga,
                             u_sa + sa0_offset(a0_current), ga_offset(0, 0));
#else
        async_load<T::VEC_A>(g_a, s_a.ptr, u_ga,
                             u_sa + sa_offset(stage, 0), ga_offset(0, 0));
#endif
#if defined(MXFP8_B0_THREE_SLOT)
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                             u_sb + sb0_offset(b0_current), gb_offset(0, 0));
#else
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                             u_sb + sb_offset(stage, 0), gb_offset(0, 0));
#endif
#if defined(MXFP8_A0_THREE_SLOT)
        async_load<T::VEC_A>(g_a, s_a.ptr, u_ga,
                             u_sa + sa1_offset(stage), ga_offset(1, 0));
#else
        async_load<T::VEC_A>(g_a, s_a.ptr, u_ga,
                             u_sa + sa_offset(stage, 1), ga_offset(1, 0));
#endif
#if defined(MXFP8_B0_THREE_SLOT)
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                             u_sb + sb1_offset(stage), gb_offset(1, 0));
#else
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                             u_sb + sb_offset(stage, 1), gb_offset(1, 0));
#endif

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
#if defined(MXFP8_A0_THREE_SLOT)
        // Seed the long-distance A0 stream. A1(1) is issued in the ordinary
        // next-tile producer block at the beginning of tile 0.
        async_load<T::VEC_A>(g_a, s_a.ptr, u_ga,
                             u_sa + sa0_offset(a0_next), ga_offset(0, 1),
                             0_I, opus::number<0>{});
#endif
#if defined(MXFP8_INTERLEAVED_TAIL_PRODUCER)
        if (wave_id == 0) {
#if defined(MXFP8_EXPERIMENTAL_4WAVE_LAYOUTS)
            async_load_sfa_tile(g_sfa, stage ^ 1, 1);
#else
            async_load<16>(g_sfa, s_sfa.ptr, u_gsfa,
                           u_ssfa + ssfa_offset(stage ^ 1), gsfa_offset(1));
#endif
        } else if (wave_id == 1) {
#if defined(MXFP8_EXPERIMENTAL_4WAVE_LAYOUTS)
            async_load_sfb_tile(stage ^ 1, 1);
#else
            async_load<16>(g_sfb, s_sfb.ptr, u_gsfb,
                           u_ssfb + ssfb_offset(stage ^ 1), gsfb_offset(1));
#endif
        }
#endif
#if defined(MXFP8_INTERLEAVED_TAIL_PRODUCER) || \
    defined(MXFP8_INTERLEAVED_TAIL_A) || \
    defined(MXFP8_INTERLEAVED_TAIL_A_N0)
#if defined(MXFP8_INTERLEAVED_TAIL_A_N0)
        if (wave_id_n == 0) {
#endif
        async_load<T::VEC_A>(g_a, s_a.ptr, u_ga,
                             u_sa + sa_offset(stage ^ 1, 0), ga_offset(0, 1));
#if defined(MXFP8_INTERLEAVED_TAIL_A_N0)
        }
#endif
#endif
#if !defined(MXFP8_SINGLE_STAGE_B)
#if defined(MXFP8_B0_THREE_SLOT)
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                             u_sb + sb0_offset(b0_next), gb_offset(0, 1));
#else
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                             u_sb + sb_offset(stage ^ 1, 0), gb_offset(0, 1));
#endif
#endif
#if defined(MXFP8_INTERLEAVED_TAIL_PRODUCER) || \
    defined(MXFP8_INTERLEAVED_TAIL_A) || \
    defined(MXFP8_INTERLEAVED_TAIL_A_N0)
#if defined(MXFP8_INTERLEAVED_TAIL_A_N0)
        if (wave_id_n == 0) {
#endif
        async_load<T::VEC_A>(g_a, s_a.ptr, u_ga,
                             u_sa + sa_offset(stage ^ 1, 1), ga_offset(1, 1));
#if defined(MXFP8_INTERLEAVED_TAIL_A_N0)
        }
#endif
#endif
#if !defined(MXFP8_SINGLE_STAGE_B)
#if defined(MXFP8_B0_THREE_SLOT)
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                             u_sb + sb1_offset(stage ^ 1), gb_offset(1, 1));
#else
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                             u_sb + sb_offset(stage ^ 1, 1), gb_offset(1, 1));
#endif
#endif
        __builtin_amdgcn_sched_barrier(0);
    }

    // Main Loop
#if defined(MXFP8_WIDE_N_WAVE)
#ifndef MXFP8_WIDE_LOOP_UNROLL
#define MXFP8_WIDE_LOOP_UNROLL 1
#endif
#if MXFP8_WIDE_LOOP_UNROLL == 2
#pragma unroll 2
#elif MXFP8_WIDE_LOOP_UNROLL == 4
#pragma unroll 4
#else
#pragma unroll 1
#endif
#else
#pragma unroll 4
#endif
    for (tile = 0; tile + 1 < loops; ++tile) {
        const int next_stage = stage ^ 1;

#if !defined(MXFP8_INTERLEAVED_TAIL_PRODUCER)
        // Keeping the producer branch in a local callable preserves the
        // verified gfx950 control flow and register allocation.
        auto load_next_scale = [&]() {
#if defined(MXFP8_EXPERIMENTAL_4WAVE_LAYOUTS)
            if (wave_id == 0) { async_load_sfa_tile(g_sfa, next_stage, tile + 1);
            } else if (wave_id == 1) {
                async_load_sfb_tile(next_stage, tile + 1);
            }
#elif defined(MXFP8_SCALE_PRODUCER_WAVE_N1)
            if (wave_id == T::T_M) { async_load<16>(g_sfa, s_sfa.ptr, u_gsfa, u_ssfa + ssfa_offset(next_stage), gsfa_offset(tile + 1));
            } else if (wave_id == T::T_M + 1) {
                async_load<16>(g_sfb, s_sfb.ptr, u_gsfb, u_ssfb + ssfb_offset(next_stage), gsfb_offset(tile + 1));
            }
#else
            if (wave_id == 0) { async_load<16>(g_sfa, s_sfa.ptr, u_gsfa, u_ssfa + ssfa_offset(next_stage), gsfa_offset(tile + 1));
            } else if (wave_id == 1) {
                async_load<16>(g_sfb, s_sfb.ptr, u_gsfb, u_ssfb + ssfb_offset(next_stage), gsfb_offset(tile + 1));
            }
#endif
        };
#endif

        v_sfa = __builtin_bit_cast(D_SF_PACK, load<4>(s_sfa, u_rsfa + ssfa_offset(scale_stage)));
#if defined(MXFP8_SFB_READ2ST64)
        const auto v_sfb_pair = load_sfb_pair(scale_stage);
        v_sfb[0] = v_sfb_pair[0];
        v_sfb[1] = v_sfb_pair[1];
#else
#if defined(MXFP8_WIDE_N_WAVE)
        v_sfb[0] = __builtin_bit_cast(
            D_SFB_PACK,
            load<T::SCALE_N_CALLS>(
                s_sfb, u_rsfb_0 + ssfb_offset(scale_stage)));
#else
        v_sfb[0] = __builtin_bit_cast(D_SF_PACK, load<4>(s_sfb, u_rsfb_0 + ssfb_offset(scale_stage)));
#endif
#endif
#if defined(MXFP8_A0_THREE_SLOT)
        v_a[0] = load<T::VEC_A>(s_a, u_ra + sa0_offset(a0_current));
#else
        v_a[0] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 0));
#endif
#if defined(MXFP8_SINGLE_STAGE_A)
        // Read both current A halves before the single physical A stage is
        // released to the next K tile.
        v_a[1] = load<T::VEC_A>(
            s_a, u_ra + sa_offset(stage, 1));
#endif
        __builtin_amdgcn_sched_barrier(0);

#if defined(MXFP8_B0_THREE_SLOT)
        v_b = load<T::VEC_B>(s_b, u_rb + sb0_offset(b0_current));
        auto rb1_offsets_prefetch =
            opus::layout_to_offsets<T::VEC_B>(u_rb + sb1_offset(stage));
#else
        v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 0));
        auto rb1_offsets_prefetch = opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(stage, 1));
#endif
#if defined(MXFP8_SINGLE_STAGE_B)
        // B1 stays in LDS until B0's accumulator quadrants are complete.
#else
        load_b_range_scale<T, 0, T::b_ds_read_insts / 2>(
            s_b, rb1_offsets_prefetch, v_b_second);
#endif
#if !defined(MXFP8_SFB_READ2ST64)
#if defined(MXFP8_WIDE_N_WAVE)
        v_sfb[1] = __builtin_bit_cast(
            D_SFB_PACK,
            load<T::SCALE_N_CALLS>(
                s_sfb, u_rsfb_1 + ssfb_offset(scale_stage)));
#else
        v_sfb[1] = __builtin_bit_cast(D_SF_PACK, load<4>(s_sfb, u_rsfb_1 + ssfb_offset(scale_stage)));
#endif
#endif
        __builtin_amdgcn_sched_barrier(0);

#if !defined(MXFP8_INTERLEAVED_TAIL_PRODUCER)
        load_next_scale();
#if defined(MXFP8_INTERLEAVED_TAIL_A_N0)
        if (wave_id_n == 1) {
            async_load<T::VEC_A>(g_a, s_a.ptr, u_ga,
                                 u_sa + sa_offset(next_stage, 0),
                                 ga_offset(0, tile + 1), 0_I,
                                 opus::number<0>{});
            async_load<T::VEC_A>(g_a, s_a.ptr, u_ga,
                                 u_sa + sa_offset(next_stage, 1),
                                 ga_offset(1, tile + 1), 0_I,
                                 opus::number<0>{});
        }
#elif !defined(MXFP8_INTERLEAVED_TAIL_A) && \
    !defined(MXFP8_SINGLE_STAGE_A)
#if defined(MXFP8_A0_THREE_SLOT)
        // A0(t+1) was launched one iteration earlier. Only A1(t+1) belongs to
        // this iteration's required producer payload.
        async_load<T::VEC_A>(
            g_a, s_a.ptr, u_ga, u_sa + sa1_offset(next_stage),
            ga_offset(1, tile + 1), 0_I, opus::number<0>{});
#elif defined(MXFP8_ASYMMETRIC_A_ONE_HALF)
        // Move exactly one A half from the delayed resident wave onto its
        // early partner.  With asymmetric B on wave-N1 this changes the
        // steady producer issue split from 4:8 to 6:6, without the long burst
        // of the full asymmetric-A experiment.
#if MXFP8_ASYMMETRIC_A_ONE_HALF == 0
        if (wave_id_n == MXFP8_ASYMMETRIC_A_PRODUCER_WAVE_N) {
            async_load<T::VEC_A>(
                g_a, s_a.ptr, u_ga_producer,
                u_sa_producer + sa_offset(next_stage, 0),
                ga_offset(0, tile + 1), 0_I, opus::number<0>{});
        }
        async_load<T::VEC_A>(
            g_a, s_a.ptr, u_ga,
            u_sa + sa_offset(next_stage, 1),
            ga_offset(1, tile + 1), 0_I, opus::number<0>{});
#elif MXFP8_ASYMMETRIC_A_ONE_HALF == 1
        async_load<T::VEC_A>(
            g_a, s_a.ptr, u_ga,
            u_sa + sa_offset(next_stage, 0),
            ga_offset(0, tile + 1), 0_I, opus::number<0>{});
        if (wave_id_n == MXFP8_ASYMMETRIC_A_PRODUCER_WAVE_N) {
            async_load<T::VEC_A>(
                g_a, s_a.ptr, u_ga_producer,
                u_sa_producer + sa_offset(next_stage, 1),
                ga_offset(1, tile + 1), 0_I, opus::number<0>{});
        }
#else
#error "MXFP8_ASYMMETRIC_A_ONE_HALF must be 0 or 1"
#endif
#elif defined(MXFP8_ASYMMETRIC_A_PRODUCER_WAVE_N)
        if (wave_id_n == MXFP8_ASYMMETRIC_A_PRODUCER_WAVE_N) {
            async_load<T::VEC_A>(
                g_a, s_a.ptr, u_ga_producer,
                u_sa_producer + sa_offset(next_stage, 0),
                ga_offset(0, tile + 1), 0_I, opus::number<0>{});
            async_load<T::VEC_A>(
                g_a, s_a.ptr, u_ga_producer,
                u_sa_producer + sa_offset(next_stage, 1),
                ga_offset(1, tile + 1), 0_I, opus::number<0>{});
        }
#else
        async_load<T::VEC_A>(g_a, s_a.ptr, u_ga, u_sa + sa_offset(next_stage, 0), ga_offset(0, tile + 1), 0_I, opus::number<0>{});
        async_load<T::VEC_A>(g_a, s_a.ptr, u_ga, u_sa + sa_offset(next_stage, 1), ga_offset(1, tile + 1), 0_I, opus::number<0>{});
#endif
#endif
        __builtin_amdgcn_sched_barrier(0);
#endif

#if defined(MXFP8_SINGLE_STAGE_A) || defined(MXFP8_SINGLE_STAGE_B)
        s_waitcnt_lgkmcnt(opus::number<0>{});
#elif defined(MXFP8_SFB_READ2ST64)
        s_waitcnt_lgkmcnt(opus::number<8>{});
#else
        s_waitcnt_lgkmcnt(opus::number<9>{});
#endif
#if defined(MXFP8_SINGLE_STAGE_B)
        // The B image is shared by all waves.  A per-wave lgkm wait is not
        // enough to let one wave overwrite data another wave may still read.
        __builtin_amdgcn_s_barrier();
#endif
        __builtin_amdgcn_s_setprio(1);

        // A half 0 x B half 0 -> C[0][0] (64x64).
        mma_scale_repeat_n2<T, 0, 0, 0>(
            mma, v_a[0], v_b, v_c[0][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][0]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale();

#if defined(MXFP8_SINGLE_STAGE_B)
        // B0 is fully resident in VGPRs.  Refill its disjoint physical half
        // immediately; B1 remains untouched in LDS until B0 computation ends.
        async_load<T::VEC_B>(
            g_b, s_b.ptr, u_gb, u_sb + sb_offset(next_stage, 0),
            gb_offset(0, tile + 1), 0_I, opus::number<0>{});
        __builtin_amdgcn_sched_barrier(0);
#endif

#if defined(MXFP8_SINGLE_STAGE_A)
        // All A reads for tile t are complete.  Reuse that single LDS image
        // for A(t+1) while the remaining thirty MFMAs execute.
        async_load<T::VEC_A>(
            g_a, s_a.ptr, u_ga, u_sa + sa_offset(next_stage, 0),
            ga_offset(0, tile + 1), 0_I, opus::number<0>{});
        async_load<T::VEC_A>(
            g_a, s_a.ptr, u_ga, u_sa + sa_offset(next_stage, 1),
            ga_offset(1, tile + 1), 0_I, opus::number<0>{});
        __builtin_amdgcn_sched_barrier(0);
#else
#if defined(MXFP8_A0_THREE_SLOT)
        v_a[1] = load<T::VEC_A>(s_a, u_ra + sa1_offset(stage));
#else
        v_a[1] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 1));
#endif
#if defined(MXFP8_SFB_READ2ST64)
        s_waitcnt_lgkmcnt(opus::number<8>{});
#else
        s_waitcnt_lgkmcnt(opus::number<9>{});
#endif
#endif

        mma_scale_repeat_n2<T, 0, 0, 1>(
            mma, v_a[0], v_b, v_c[0][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][0]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale();

        mma_scale_repeat_n2<T, 0, 1, 0>(
            mma, v_a[0], v_b, v_c[0][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][0]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale();

        mma_scale_repeat_n2<T, 0, 1, 1>(
            mma, v_a[0], v_b, v_c[0][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][0]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale();

        // A half 1 x B half 0 -> C[1][0] (64x64).
        mma_scale_repeat_n2<T, 1, 0, 0>(
            mma, v_a[1], v_b, v_c[1][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][0]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale();

        mma_scale_repeat_n2<T, 1, 0, 1>(
            mma, v_a[1], v_b, v_c[1][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][0]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale();

        mma_scale_repeat_n2<T, 1, 1, 0>(
            mma, v_a[1], v_b, v_c[1][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][0]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale();

        mma_scale_repeat_n2<T, 1, 1, 1>(
            mma, v_a[1], v_b, v_c[1][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][0]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale();

#if defined(MXFP8_SINGLE_STAGE_B)
        // B0 is dead now, so its registers can be reused for the complete B1
        // operand.  Only after the LDS read completes may B1(t+1) overwrite
        // the same physical half.
        v_b_second = load<T::VEC_B>(
            s_b, u_rb + sb_offset(stage, 1));
        s_waitcnt_lgkmcnt(opus::number<0>{});
        __builtin_amdgcn_s_barrier();
        async_load<T::VEC_B>(
            g_b, s_b.ptr, u_gb, u_sb + sb_offset(next_stage, 1),
            gb_offset(1, tile + 1), 0_I, opus::number<0>{});
        __builtin_amdgcn_sched_barrier(0);
#elif defined(MXFP8_B0_THREE_SLOT)
        auto rb1_offsets_tail =
            opus::layout_to_offsets<T::VEC_B>(u_rb + sb1_offset(stage));
#else
        auto rb1_offsets_tail = opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(stage, 1));
#endif
#if !defined(MXFP8_SINGLE_STAGE_B)
        load_b_range_scale<T, T::b_ds_read_insts / 2,
                           T::b_ds_read_insts>(
            s_b, rb1_offsets_tail, v_b_second);
#endif
        const auto& v_b_n1 = v_b_second;

        // A half 0 x B half 1 -> C[0][1] (64x64).
        mma_scale_repeat_n2<T, 0, 0, 0>(
            mma, v_a[0], v_b_n1, v_c[0][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale();

        mma_scale_repeat_n2<T, 0, 0, 1>(
            mma, v_a[0], v_b_n1, v_c[0][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale();

#if defined(MXFP8_STAGGERED_TAIL_MFMA)
        // The asymmetric B producer reaches this point roughly twelve MFMA
        // issue slots behind its resident partner.  Let the non-producer
        // consume its final twelve independent MFMAs before joining the
        // publish barrier.  After release, the producer writes B(t+2) and
        // consumes the same tail while its partner starts tile t+1.
        // Use two runtime phases so the compiler emits this large MFMA body
        // only once.  Phase 0 falls through to the barrier block; phase 1
        // skips it and exits the loop.
#pragma unroll 1
        for (int stagger_phase = 0; stagger_phase < 2; ++stagger_phase) {
            if (stagger_phase == wave_id_n) {
                __builtin_amdgcn_s_setprio(1);
            mma_scale_repeat_n2<T, 0, 1, 0>(
                mma, v_a[0], v_b_n1, v_c[0][1], v_sfa, v_sfb[1]);
            {
                auto* v_c_pin =
                    reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
                asm volatile("" : "+v"(v_c_pin[1]) ::);
            }
            sched_barrier_pairs_scale();

            mma_scale_repeat_n2<T, 0, 1, 1>(
                mma, v_a[0], v_b_n1, v_c[0][1], v_sfa, v_sfb[1]);
            {
                auto* v_c_pin =
                    reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
                asm volatile("" : "+v"(v_c_pin[1]) ::);
            }
            sched_barrier_pairs_scale();

            mma_scale_repeat_n2<T, 1, 0, 0>(
                mma, v_a[1], v_b_n1, v_c[1][1], v_sfa, v_sfb[1]);
            {
                auto* v_c_pin =
                    reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
                asm volatile("" : "+v"(v_c_pin[0]) ::);
            }
            sched_barrier_pairs_scale();

            mma_scale_repeat_n2<T, 1, 0, 1>(
                mma, v_a[1], v_b_n1, v_c[1][1], v_sfa, v_sfb[1]);
            {
                auto* v_c_pin =
                    reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
                asm volatile("" : "+v"(v_c_pin[0]) ::);
            }
            sched_barrier_pairs_scale();

            mma_scale_repeat_n2<T, 1, 1, 0>(
                mma, v_a[1], v_b_n1, v_c[1][1], v_sfa, v_sfb[1]);
            {
                auto* v_c_pin =
                    reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
                asm volatile("" : "+v"(v_c_pin[1]) ::);
            }
            sched_barrier_pairs_scale();

            mma_scale_repeat_n2<T, 1, 1, 1>(
                mma, v_a[1], v_b_n1, v_c[1][1], v_sfa, v_sfb[1]);
            {
                auto* v_c_pin =
                    reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
                asm volatile("" : "+v"(v_c_pin[1]) ::);
            }
            sched_barrier_pairs_scale();
            }
            if (stagger_phase != 0) {
                continue;
            }
#endif

        // All operands for tile t are now resident in VGPRs.  Publish tile
        // t+1 and release tile t's LDS stage with the same barrier, then start
        // the cold B path for tile t+2 while the final 12 MFMAs of tile t run.
        __builtin_amdgcn_s_setprio(0);
#if defined(MXFP8_A0_THREE_SLOT)
        if (tile + 2 < loops) {
            // Keep these two per-wave direct-to-LDS requests newest in the VM
            // queue. vmcnt(2) retires the required A0/A1/scale payload for
            // tile t+1 while allowing A0(t+2) to overlap the barrier and tail.
            async_load<T::VEC_A>(
                g_a, s_a.ptr, u_ga, u_sa + sa0_offset(a0_spare),
                ga_offset(0, tile + 2), 0_I, opus::number<0>{});
            s_waitcnt_vmcnt(opus::number<2>{});
        } else {
            // There is no harmless future request to occupy the final two VM
            // slots, so all data for the final resident tile must retire.
            s_waitcnt_vmcnt(0_I);
        }
#else
        s_waitcnt_vmcnt(0_I);
#endif
        s_waitcnt_lgkmcnt(0_I);
#if defined(MXFP8_B0_THREE_SLOT)
        // The tile-t+1 producer payload is complete before this point. Launch
        // B0(t+2) after the wait so it may remain outstanding across this
        // barrier; the next iteration's wait publishes it before consumption.
        if (tile + 2 < loops) {
            async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                                 u_sb + sb0_offset(b0_spare),
                                 gb_offset(0, tile + 2));
        }
#endif
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);

#if defined(MXFP8_INTERLEAVED_TAIL_PRODUCER) || \
    defined(MXFP8_INTERLEAVED_TAIL_A) || \
    defined(MXFP8_INTERLEAVED_TAIL_A_N0)
        // Always use a valid producer tile.  The final main-loop iteration
        // redundantly reloads the resident last tile into the released stage;
        // this removes a hot conditional around the interleaved producer and
        // costs only one producer payload per complete K loop.
        const int producer_tile = min(tile + 2, loops - 1);
#endif
#if defined(MXFP8_INTERLEAVED_TAIL_PRODUCER)
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                             u_sb + sb_offset(stage, 0), gb_offset(0, producer_tile));
#else
        if (tile + 2 < loops) {
#if defined(MXFP8_ASYMMETRIC_B_PRODUCER)
#if defined(MXFP8_ASYMMETRIC_B_SPLIT_3_1)
            // Keep the producer/consumer skew that makes asymmetric-B useful,
            // but move one of the four logical B slices onto the early wave.
            // ATT shows wave-N0 reaching the publish barrier well before N1;
            // a 1:3 split tests whether part of that slack can retire useful
            // VMEM without destroying the resident-wave overlap.
            if (wave_id_n == 0) {
                async_load<T::VEC_B>(g_b, s_b.ptr, u_gb_producer_1,
                                     u_sb_producer_1 + sb_offset(stage, 1),
                                     gb_offset(1, tile + 2));
            } else {
                async_load<T::VEC_B>(g_b, s_b.ptr, u_gb_producer_0,
                                     u_sb_producer_0 + sb_offset(stage, 0),
                                     gb_offset(0, tile + 2));
                async_load<T::VEC_B>(g_b, s_b.ptr, u_gb_producer_1,
                                     u_sb_producer_1 + sb_offset(stage, 0),
                                     gb_offset(0, tile + 2));
                async_load<T::VEC_B>(g_b, s_b.ptr, u_gb_producer_0,
                                     u_sb_producer_0 + sb_offset(stage, 1),
                                     gb_offset(1, tile + 2));
            }
#else
#if defined(MXFP8_ASYMMETRIC_B_ALTERNATE)
            const int b_producer_wave_n =
                MXFP8_ASYMMETRIC_B_PRODUCER ^ (tile & 1);
#else
            constexpr int b_producer_wave_n =
                MXFP8_ASYMMETRIC_B_PRODUCER;
#endif
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
#if defined(MXFP8_ASYMMETRIC_B_TAIL_PRIORITY)
                // Let the delayed producer catch the low-priority partner
                // once its B payload has been issued.
                __builtin_amdgcn_s_setprio(1);
#endif
            }
#endif
#else
#if !defined(MXFP8_B0_THREE_SLOT) && !defined(MXFP8_SINGLE_STAGE_B)
            async_load<T::VEC_B>(g_b, s_b.ptr, u_gb, u_sb + sb_offset(stage, 0), gb_offset(0, tile + 2));
#endif
#if defined(MXFP8_B0_THREE_SLOT)
            async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                                 u_sb + sb1_offset(stage),
                                 gb_offset(1, tile + 2));
#elif !defined(MXFP8_SINGLE_STAGE_B)
            async_load<T::VEC_B>(g_b, s_b.ptr, u_gb, u_sb + sb_offset(stage, 1), gb_offset(1, tile + 2));
#endif
#endif
            __builtin_amdgcn_sched_barrier(0);
        }
#endif
#if defined(MXFP8_STAGGERED_TAIL_MFMA)
        }
#else
#if !defined(MXFP8_ASYMMETRIC_B_TAIL_PRIORITY)
        __builtin_amdgcn_s_setprio(1);
#endif

        mma_scale_repeat_n2<T, 0, 1, 0>(
            mma, v_a[0], v_b_n1, v_c[0][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale();

#if defined(MXFP8_INTERLEAVED_TAIL_PRODUCER)
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                             u_sb + sb_offset(stage, 1), gb_offset(1, producer_tile));
#endif

        mma_scale_repeat_n2<T, 0, 1, 1>(
            mma, v_a[0], v_b_n1, v_c[0][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale();

#if defined(MXFP8_INTERLEAVED_TAIL_PRODUCER) || \
    defined(MXFP8_INTERLEAVED_TAIL_A) || \
    defined(MXFP8_INTERLEAVED_TAIL_A_N0)
#if defined(MXFP8_INTERLEAVED_TAIL_A_N0)
        if (wave_id_n == 0) {
#endif
        async_load<T::VEC_A>(g_a, s_a.ptr, u_ga,
                             u_sa + sa_offset(stage, 0), ga_offset(0, producer_tile),
                             0_I, opus::number<0>{});
#if defined(MXFP8_INTERLEAVED_TAIL_A_N0)
        }
#endif
#endif

        // A half 1 x B half 1 -> C[1][1] (64x64).
        mma_scale_repeat_n2<T, 1, 0, 0>(
            mma, v_a[1], v_b_n1, v_c[1][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale();

#if defined(MXFP8_INTERLEAVED_TAIL_PRODUCER) || \
    defined(MXFP8_INTERLEAVED_TAIL_A) || \
    defined(MXFP8_INTERLEAVED_TAIL_A_N0)
#if defined(MXFP8_INTERLEAVED_TAIL_A_N0)
        if (wave_id_n == 0) {
#endif
        async_load<T::VEC_A>(g_a, s_a.ptr, u_ga,
                             u_sa + sa_offset(stage, 1), ga_offset(1, producer_tile),
                             0_I, opus::number<0>{});
#if defined(MXFP8_INTERLEAVED_TAIL_A_N0)
        }
#endif
#endif

        mma_scale_repeat_n2<T, 1, 0, 1>(
            mma, v_a[1], v_b_n1, v_c[1][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale();

#if defined(MXFP8_INTERLEAVED_TAIL_PRODUCER)
        if (wave_id == 0) {
#if defined(MXFP8_EXPERIMENTAL_4WAVE_LAYOUTS)
            async_load_sfa_tile(g_sfa, stage, producer_tile);
#else
            async_load<16>(g_sfa, s_sfa.ptr, u_gsfa,
                           u_ssfa + ssfa_offset(stage),
                           gsfa_offset(producer_tile));
#endif
        } else if (wave_id == 1) {
#if defined(MXFP8_EXPERIMENTAL_4WAVE_LAYOUTS)
            async_load_sfb_tile(stage, producer_tile);
#else
            async_load<16>(g_sfb, s_sfb.ptr, u_gsfb,
                           u_ssfb + ssfb_offset(stage),
                           gsfb_offset(producer_tile));
#endif
        }
#endif

        mma_scale_repeat_n2<T, 1, 1, 0>(
            mma, v_a[1], v_b_n1, v_c[1][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale();

        mma_scale_repeat_n2<T, 1, 1, 1>(
            mma, v_a[1], v_b_n1, v_c[1][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale();
#endif
        __builtin_amdgcn_s_setprio(0);
#if defined(MXFP8_B0_THREE_SLOT)
        const int old_b0_current = b0_current;
        b0_current = b0_next;
        b0_next = b0_spare;
        b0_spare = old_b0_current;
#endif
#if defined(MXFP8_A0_THREE_SLOT)
        const int old_a0_current = a0_current;
        a0_current = a0_next;
        a0_next = a0_spare;
        a0_spare = old_a0_current;
#endif
        stage = next_stage;
        scale_stage = next_stage;
    }

    // Consume the final resident tile without issuing more global loads.
    v_sfa = __builtin_bit_cast(D_SF_PACK, load<4>(s_sfa, u_rsfa + ssfa_offset(scale_stage)));
#if defined(MXFP8_SFB_READ2ST64)
    const auto v_sfb_pair = load_sfb_pair(scale_stage);
    v_sfb[0] = v_sfb_pair[0];
    v_sfb[1] = v_sfb_pair[1];
#else
#if defined(MXFP8_WIDE_N_WAVE)
    v_sfb[0] = __builtin_bit_cast(
        D_SFB_PACK,
        load<T::SCALE_N_CALLS>(
            s_sfb, u_rsfb_0 + ssfb_offset(scale_stage)));
#else
    v_sfb[0] = __builtin_bit_cast(D_SF_PACK, load<4>(s_sfb, u_rsfb_0 + ssfb_offset(scale_stage)));
#endif
#endif
#if defined(MXFP8_A0_THREE_SLOT)
    v_a[0] = load<T::VEC_A>(s_a, u_ra + sa0_offset(a0_current));
    v_a[1] = load<T::VEC_A>(s_a, u_ra + sa1_offset(stage));
#else
    v_a[0] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 0));
    v_a[1] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 1));
#endif
#if defined(MXFP8_B0_THREE_SLOT)
    v_b = load<T::VEC_B>(s_b, u_rb + sb0_offset(b0_current));
#else
    v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 0));
#endif
    s_waitcnt_lgkmcnt(0_I);
#if !defined(MXFP8_SFB_READ2ST64)
#if defined(MXFP8_WIDE_N_WAVE)
    v_sfb[1] = __builtin_bit_cast(
        D_SFB_PACK,
        load<T::SCALE_N_CALLS>(
            s_sfb, u_rsfb_1 + ssfb_offset(scale_stage)));
#else
    v_sfb[1] = __builtin_bit_cast(D_SF_PACK, load<4>(s_sfb, u_rsfb_1 + ssfb_offset(scale_stage)));
#endif
#endif

    const bool has_next_output =
        output_tile + 1 < T::OUTPUT_TILES_PER_WG &&
        block_m + 1 < num_tiles_m;
    const int next_output_stage = stage ^ 1;
    if (has_next_output) {
#if defined(MXFP8_SINGLE_STAGE_B)
        __builtin_amdgcn_s_barrier();
#endif
        const int next_block_m = block_m + 1;
        const int next_row = next_block_m * T::B_M;
        auto g_a_next = make_gmem(
            reinterpret_cast<const D_A*>(kargs.ptr_a) +
            batch_id * kargs.stride_a_batch + next_row * kargs.stride_a);
        auto g_sfa_next = make_gmem(
            reinterpret_cast<const D_SF*>(kargs.ptr_sfa) +
            batch_id * kargs.stride_sfa_batch +
            next_block_m * num_tiles_k * kargs.stride_sfa);

#if defined(MXFP8_SCALE_PRODUCER_WAVE_N1)
        if (wave_id == T::T_M) {
#else
        if (wave_id == 0) {
#endif
#if defined(MXFP8_EXPERIMENTAL_4WAVE_LAYOUTS)
            async_load_sfa_tile(g_sfa_next, next_output_stage, 0);
#else
            async_load<16>(g_sfa_next, s_sfa.ptr, u_gsfa,
                           u_ssfa + ssfa_offset(next_output_stage), gsfa_offset(0));
#endif
#if defined(MXFP8_SCALE_PRODUCER_WAVE_N1)
        } else if (wave_id == T::T_M + 1) {
#else
        } else if (wave_id == 1) {
#endif
#if defined(MXFP8_EXPERIMENTAL_4WAVE_LAYOUTS)
            async_load_sfb_tile(next_output_stage, 0);
#else
            async_load<16>(g_sfb, s_sfb.ptr, u_gsfb,
                           u_ssfb + ssfb_offset(next_output_stage), gsfb_offset(0));
#endif
        }
#if defined(MXFP8_A0_THREE_SLOT)
        async_load<T::VEC_A>(g_a_next, s_a.ptr, u_ga,
                             u_sa + sa0_offset(a0_next), ga_offset(0, 0));
#else
        async_load<T::VEC_A>(g_a_next, s_a.ptr, u_ga,
                             u_sa + sa_offset(next_output_stage, 0), ga_offset(0, 0));
#endif
#if defined(MXFP8_B0_THREE_SLOT)
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                             u_sb + sb0_offset(b0_next), gb_offset(0, 0));
#else
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                             u_sb + sb_offset(next_output_stage, 0), gb_offset(0, 0));
#endif
#if defined(MXFP8_A0_THREE_SLOT)
        async_load<T::VEC_A>(g_a_next, s_a.ptr, u_ga,
                             u_sa + sa1_offset(next_output_stage), ga_offset(1, 0));
#else
        async_load<T::VEC_A>(g_a_next, s_a.ptr, u_ga,
                             u_sa + sa_offset(next_output_stage, 1), ga_offset(1, 0));
#endif
#if defined(MXFP8_B0_THREE_SLOT)
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                             u_sb + sb1_offset(next_output_stage), gb_offset(1, 0));
#elif !defined(MXFP8_SINGLE_STAGE_B)
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                             u_sb + sb_offset(next_output_stage, 1), gb_offset(1, 0));
#endif
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


#if defined(MXFP8_SINGLE_STAGE_B)
    v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 1));
    s_waitcnt_lgkmcnt(opus::number<0>{});
    if (has_next_output) {
        __builtin_amdgcn_s_barrier();
        async_load<T::VEC_B>(
            g_b, s_b.ptr, u_gb,
            u_sb + sb_offset(next_output_stage, 1), gb_offset(1, 0));
        __builtin_amdgcn_sched_barrier(0);
    }
#elif defined(MXFP8_B0_THREE_SLOT)
    v_b = load<T::VEC_B>(s_b, u_rb + sb1_offset(stage));
#else
    v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 1));
#endif

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
#if defined(MXFP8_A0_THREE_SLOT)
        const int old_a0_current = a0_current;
        a0_current = a0_next;
        a0_next = a0_spare;
        a0_spare = old_a0_current;
#endif
#if defined(MXFP8_B0_THREE_SLOT)
        const int old_b0_current = b0_current;
        b0_current = b0_next;
        b0_next = b0_spare;
        b0_spare = old_b0_current;
#endif
    }

    auto p_coord_c = opus::make_tuple(wave_id_m, lane_id % mma.grpn_c, wave_id_n, lane_id / mma.grpn_c);
    auto u_gc = partition_layout_c<T::VEC_C>(mma, opus::make_tuple(kargs.stride_c, 1_I), p_coord_c);

    auto c_offset = [&](int half_tile_m, int half_tile_n) {
        return half_tile_m * T::HALF_B_M * kargs.stride_c + half_tile_n * T::HALF_B_N;
    };

#if defined(MXFP8_WIDE_AGPR_FRAGMENTS)
    // Materialize one 64-dword quadrant at a time for the existing vectorized
    // output layout.  This costs one AGPR->VGPR read per result only at the
    // epilogue, while avoiding a second 256-VGPR live aggregate.
    opus::static_for<4>([&](auto quadrant) {
        constexpr int Q = decltype(quadrant)::value;
        constexpr int HM = Q / 2;
        constexpr int HN = Q % 2;
        typename decltype(mma)::vtype_c v_c_store;
        opus::static_for<T::E_M * T::E_N>([&](auto fragment) {
            constexpr int F = decltype(fragment)::value;
            constexpr int begin = F * decltype(mma)::mma_c_len;
            opus::set_slice(
                v_c_store, v_c[HM][HN][F], opus::number<begin>{},
                opus::number<begin + decltype(mma)::mma_c_len>{});
        });
        store<T::VEC_C>(g_c, v_c_store, u_gc, c_offset(HM, HN),
                        opus::number<2>{});
    });
#else
    store<T::VEC_C>(g_c, v_c[0][0], u_gc, c_offset(0, 0), opus::number<2>{});
    store<T::VEC_C>(g_c, v_c[0][1], u_gc, c_offset(0, 1), opus::number<2>{});
    store<T::VEC_C>(g_c, v_c[1][0], u_gc, c_offset(1, 0), opus::number<2>{});
    store<T::VEC_C>(g_c, v_c[1][1], u_gc, c_offset(1, 1), opus::number<2>{});
#endif
    }
}
