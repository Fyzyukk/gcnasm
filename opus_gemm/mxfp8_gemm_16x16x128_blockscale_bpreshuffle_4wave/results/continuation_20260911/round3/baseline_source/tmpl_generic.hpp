#pragma once

#include <opus/hip_minimal.hpp>
#include <opus/opus.hpp>

#include "gemm_a8w8_mxfp8_scale_common.h"

namespace blockscale_generic {

using opus::operator""_I;

__device__ inline unsigned int transpose_scale_dword_4x4(
    unsigned int packed, int scale_call) {
    const auto rows01_or_23 =
        __builtin_amdgcn_permlane16_swap(packed, packed, false, true);
    const unsigned int select_q01 =
        0x06020400u + (scale_call & 1) * 0x01010101u;
    const unsigned int q01_or_q23 = __builtin_amdgcn_perm(
        rows01_or_23[1], rows01_or_23[0], select_q01);

    const auto rows0123 = __builtin_amdgcn_permlane32_swap(
        q01_or_q23, q01_or_q23, false, true);
    const unsigned int select_q =
        0x05040100u + (scale_call >> 1) * 0x02020202u;
    return __builtin_amdgcn_perm(rows0123[1], rows0123[0], select_q);
}


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

// Issue exactly one request from an OPUS layout-to-layout asynchronous copy.
// A/B each have four 16-byte requests per lane in this 4-wave geometry.  The
// stock async_load(layout, layout) helper emits all four together, which gives
// the machine scheduler no source-level cut point at which to place an XDL
// instruction.  Keeping the same layouts and offsets here preserves the copy
// semantics while exposing the four requests as independently placeable
// chunks.
template<int Vec, int Issue, class Mem, class SmemPtr,
         class LayoutG, class LayoutS>
__device__ inline void async_load_issue_scale(
    Mem& mem,
    SmemPtr smem_base,
    const LayoutG& u_gmem,
    const LayoutS& u_smem,
    int s_os) {
    const auto gmem_offsets = opus::layout_to_offsets<Vec>(u_gmem);
    const auto smem_offsets = opus::layout_to_offsets<Vec>(u_smem);
    auto* dst = smem_base + smem_offsets[Issue];
    mem.template async_load<Vec>(
        reinterpret_cast<void*>(reinterpret_cast<__UINTPTR_TYPE__>(dst)),
        gmem_offsets[Issue], s_os, opus::number<0>{}, opus::number<0>{});
}

// Assign one producer wave to four adjacent padded LDS rows.  The four
// request destinations then fit in one gfx950 MUBUF immediate range.  Remove
// that immediate from soffset so the packed B source address is unchanged
// while all four requests share one LDS base/m0 value. Each pair of requests
// covers both K64 halves of an AITER N16 group.
template<class T, int Issue, class Mem, class SmemPtr,
         class LayoutG, class LayoutS>
__device__ inline void async_load_issue_b_contiguous_scale(
    Mem& mem,
    SmemPtr smem_base,
    const LayoutG& u_gmem,
    const LayoutS& u_smem,
    int s_os,
    int source_stride) {
    constexpr int lds_issue_stride =
        T::smem_linear_wave + T::smem_padding;
    constexpr int lds_ioffset = Issue * lds_issue_stride;
    const int source_byte_delta =
        16 * (Issue / 2) * source_stride + 1024 * (Issue % 2);
    static_assert(T::T_M == 2 && T::T_N == 2);
    static_assert(Issue >= 0 && Issue < 4);
    static_assert(lds_ioffset <= 4095);

    const auto gmem_offsets = opus::layout_to_offsets<T::VEC_B>(u_gmem);
    const auto smem_offsets = opus::layout_to_offsets<T::VEC_B>(u_smem);
    auto* dst = smem_base + smem_offsets[0];
    mem.template async_load<T::VEC_B>(
        reinterpret_cast<void*>(reinterpret_cast<__UINTPTR_TYPE__>(dst)),
        gmem_offsets[0],
        s_os + source_byte_delta - lds_ioffset,
        opus::number<lds_ioffset>{}, opus::number<0>{});
}

__device__ inline void sched_barrier_pairs_scale() {
    __builtin_amdgcn_sched_group_barrier(0x08, 1, 0);
    __builtin_amdgcn_sched_group_barrier(0x02, 2, 0);
    __builtin_amdgcn_sched_group_barrier(0x08, 1, 0);
    __builtin_amdgcn_sched_group_barrier(0x02, 2, 0);
}

__device__ inline void sched_barrier_one_scale() {
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
    // A 128-row half has four M repeats.  Each half owns one 4-byte SFA pack,
    // so op_sel remains 0..3 instead of incorrectly trying to address bytes
    // 4..7 in one dword.
    constexpr int scale_op_sel_a = M_REPEAT;
    static_assert(HALF_TILE_M == 0 || HALF_TILE_M == 1);
    static_assert(T::E_M == 4);

    auto s_a = opus::slice(
        v_a, opus::number<a_offset>{}, opus::number<a_offset + a_len>{});
    auto s_b = opus::slice(
        v_b, opus::number<b_offset>{}, opus::number<b_offset + b_len>{});
    return base_mma{}(
        s_a,
        s_b,
        v_c,
        static_cast<int>(v_sfa),
        static_cast<int>(v_sfb),
        opus::number<scale_op_sel_a>{},
        opus::number<N_REPEAT>{});
}

#define MXFP8_MMA_PAIR(HALF_TILE_M, M_REPEAT, N_GROUP, VA, VB, C0, C1, SFA, SFB) \
    do {                                                                          \
        C0 = mma_scale_one<T, HALF_TILE_M, M_REPEAT, (N_GROUP) * 2>(              \
            mma, VA, VB, C0, (SFA)[HALF_TILE_M], SFB);                            \
        C1 = mma_scale_one<T, HALF_TILE_M, M_REPEAT, (N_GROUP) * 2 + 1>(          \
            mma, VA, VB, C1, (SFA)[HALF_TILE_M], SFB);                            \
    } while (false)

#define MXFP8_MMA_ONE(HALF_TILE_M, M_REPEAT, N_REPEAT, VA, VB, C, SFA, SFB) \
    do {                                                                     \
        C = mma_scale_one<T, HALF_TILE_M, M_REPEAT, N_REPEAT>(               \
            mma, VA, VB, C, (SFA)[HALF_TILE_M], SFB);                        \
    } while (false)

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
        opus::unfold_x_stride(
            ga_block_dim, ga_block_shape, opus::tuple{stride_a, 1_I}),
        opus::unfold_p_coord(
            ga_block_dim,
            opus::tuple{wave_id_n, lane_id / threads_k, wave_id_m,
                        lane_id % threads_k}));
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
        opus::unfold_x_stride(
            sa_block_dim, sa_block_shape,
            opus::tuple{opus::number<T::smem_linear_wave + T::smem_padding>{}, 1_I}),
        opus::unfold_p_coord(sa_block_dim,
                             opus::tuple{wave_id_n, wave_id_m}));
}

template<class T>
__device__ inline auto make_layout_gb_scale(int lane_id, int wave_id_m, int wave_id_n, int stride_b) {
    // AITER (16,16) shuffle: a whole wave copies a contiguous N16 x K64
    // region. Its four requests cover two N16 groups and both K64 halves.
    static_assert(T::T_M == 2 && T::T_N == 2);
    static_assert(T::HALF_B_N == 128 && T::B_K == 128 && T::VEC_B == 16);
    const int producer_rep = wave_id_n * T::T_M + wave_id_m;
    return opus::make_layout<T::VEC_B>(
        opus::make_tuple(2_I, 2_I, opus::number<T::VEC_B>{}),
        opus::make_tuple(16 * stride_b, 1024_I, 1_I),
        opus::make_tuple(opus::underscore{}, opus::underscore{},
                         opus::underscore{})) +
        producer_rep * 32 * stride_b + lane_id * T::VEC_B;
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
        opus::make_tuple(opus::p_dim{}, opus::y_dim{}, opus::y_dim{}),
        opus::make_tuple(opus::y_dim{}));

    const int producer_rep = wave_id_n * T::T_M + wave_id_m;

    return opus::make_layout(
        sb_block_shape,
        opus::unfold_x_stride(
            sb_block_dim, sb_block_shape,
            opus::tuple{opus::number<T::smem_linear_wave + T::smem_padding>{}, 1_I}),
        opus::unfold_p_coord(sb_block_dim, opus::tuple{producer_rep}));
}

template<class T>
__device__ inline auto make_layout_ra_scale(int lane_id, int wave_id_m) {
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
        opus::make_tuple(opus::p_dim{}, opus::y_dim{}, opus::y_dim{},
                         opus::p_dim{}, opus::y_dim{}));

    const int lane_id_m = lane_id % T::W_M;
    return opus::make_layout<T::VEC_A>(
        ra_block_shape,
        opus::unfold_x_stride(
            ra_block_dim, ra_block_shape,
            opus::tuple{opus::number<T::smem_linear_wave + T::smem_padding>{}, 1_I}),
        opus::unfold_p_coord(
            ra_block_dim,
            opus::tuple{wave_id_m, lane_id_m % T::T_M,
                        lane_id_m / T::T_M, lane_id / T::W_M}));
}

template<class T>
__device__ inline auto make_layout_rb_scale(int lane_id, int wave_id_n) {
    static_assert(T::E_N == 4 && T::E_K == 1);
    static_assert(T::T_M == 2 && T::T_N == 2 && T::VEC_B == 16);
    constexpr int pitch = T::smem_linear_wave + T::smem_padding;
    // Consumer n=32*repeat+16*wave_n+(lane%16),
    //          k=64*k_piece+16*(lane/16)+byte.
    // Invert the coalesced producer while preserving operand flattening
    // (n_repeat, k_piece, byte) and the original four-adjacent-row SB map.
    return opus::make_layout<T::VEC_B>(
        opus::make_tuple(4_I, 2_I, opus::number<T::VEC_B>{}),
        opus::make_tuple(opus::number<4 * pitch>{},
                         opus::number<pitch>{}, 1_I),
        opus::make_tuple(opus::underscore{}, opus::underscore{},
                         opus::underscore{})) +
        2 * wave_id_n * pitch + lane_id * T::VEC_B;
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

    const int wgid = block_id_x();
    const int num_tiles_n = ceil_div_scale(kargs.n, T::B_N);
    const int block_m = wgid / num_tiles_n;
    const int block_n = wgid % num_tiles_n;
    const int num_tiles_k = ceil_div_scale(kargs.k, T::B_K);
    const int row = block_m * T::B_M;
    const int col = block_n * T::B_N;

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

    // Compact external scales: SFA is physical [K/128,M], and SFB is
    // [N/128,K/128]. All four waves load one A byte and one B byte per lane.
    // The B byte is shared by the producer wave's N128 half.
    auto g_sfa = make_gmem(
        reinterpret_cast<const D_SF*>(kargs.ptr_sfa) +
        batch_id * kargs.stride_sfa_batch + row,
        static_cast<unsigned int>(kargs.stride_sfa_batch - row));
    const int sfb_row_offset = (col / T::GROUP_N) * kargs.stride_sfb;
    auto g_sfb = make_gmem(
        reinterpret_cast<const D_SF*>(kargs.ptr_sfb) +
        batch_id * kargs.stride_sfb_batch + sfb_row_offset,
        static_cast<unsigned int>(kargs.stride_sfb_batch - sfb_row_offset));

    const int wave_id_m = wave_id % T::T_M;
    const int wave_id_n = wave_id / T::T_M;

    auto u_ga = make_layout_ga_scale<T>(lane_id, wave_id_m, wave_id_n, kargs.stride_a);
    auto u_sa = make_layout_sa_scale<T>(wave_id_m, wave_id_n);
    auto u_ra = make_layout_ra_scale<T>(lane_id, wave_id_m);
    auto u_gb = make_layout_gb_scale<T>(lane_id, wave_id_m, wave_id_n, kargs.stride_b);
    auto u_sb = make_layout_sb_scale<T>(wave_id_m, wave_id_n);
    auto u_rb = make_layout_rb_scale<T>(lane_id, wave_id_n);

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
    alignas(8) __shared__ char smem_sfa[smem_sfa_elem * 2 * sizeof(D_SF)];
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
    using AccFragment = typename decltype(mma)::MMA::vtype_c;
    static_assert(decltype(mma)::mma_c_len == 4);

#define MXFP8_PIN_C(NAME, BASE) \
    __attribute__((amdgpu_pin_agpr(BASE))) AccFragment NAME = {}
    MXFP8_PIN_C(c00_0, 0);
    MXFP8_PIN_C(c00_1, 4);
    MXFP8_PIN_C(c00_2, 8);
    MXFP8_PIN_C(c00_3, 12);
    MXFP8_PIN_C(c00_4, 16);
    MXFP8_PIN_C(c00_5, 20);
    MXFP8_PIN_C(c00_6, 24);
    MXFP8_PIN_C(c00_7, 28);
    MXFP8_PIN_C(c00_8, 32);
    MXFP8_PIN_C(c00_9, 36);
    MXFP8_PIN_C(c00_10, 40);
    MXFP8_PIN_C(c00_11, 44);
    MXFP8_PIN_C(c00_12, 48);
    MXFP8_PIN_C(c00_13, 52);
    MXFP8_PIN_C(c00_14, 56);
    MXFP8_PIN_C(c00_15, 60);
    MXFP8_PIN_C(c01_0, 64);
    MXFP8_PIN_C(c01_1, 68);
    MXFP8_PIN_C(c01_2, 72);
    MXFP8_PIN_C(c01_3, 76);
    MXFP8_PIN_C(c01_4, 80);
    MXFP8_PIN_C(c01_5, 84);
    MXFP8_PIN_C(c01_6, 88);
    MXFP8_PIN_C(c01_7, 92);
    MXFP8_PIN_C(c01_8, 96);
    MXFP8_PIN_C(c01_9, 100);
    MXFP8_PIN_C(c01_10, 104);
    MXFP8_PIN_C(c01_11, 108);
    MXFP8_PIN_C(c01_12, 112);
    MXFP8_PIN_C(c01_13, 116);
    MXFP8_PIN_C(c01_14, 120);
    MXFP8_PIN_C(c01_15, 124);
    MXFP8_PIN_C(c10_0, 128);
    MXFP8_PIN_C(c10_1, 132);
    MXFP8_PIN_C(c10_2, 136);
    MXFP8_PIN_C(c10_3, 140);
    MXFP8_PIN_C(c10_4, 144);
    MXFP8_PIN_C(c10_5, 148);
    MXFP8_PIN_C(c10_6, 152);
    MXFP8_PIN_C(c10_7, 156);
    MXFP8_PIN_C(c10_8, 160);
    MXFP8_PIN_C(c10_9, 164);
    MXFP8_PIN_C(c10_10, 168);
    MXFP8_PIN_C(c10_11, 172);
    MXFP8_PIN_C(c10_12, 176);
    MXFP8_PIN_C(c10_13, 180);
    MXFP8_PIN_C(c10_14, 184);
    MXFP8_PIN_C(c10_15, 188);
    MXFP8_PIN_C(c11_0, 192);
    MXFP8_PIN_C(c11_1, 196);
    MXFP8_PIN_C(c11_2, 200);
    MXFP8_PIN_C(c11_3, 204);
    MXFP8_PIN_C(c11_4, 208);
    MXFP8_PIN_C(c11_5, 212);
    MXFP8_PIN_C(c11_6, 216);
    MXFP8_PIN_C(c11_7, 220);
    MXFP8_PIN_C(c11_8, 224);
    MXFP8_PIN_C(c11_9, 228);
    MXFP8_PIN_C(c11_10, 232);
    MXFP8_PIN_C(c11_11, 236);
    MXFP8_PIN_C(c11_12, 240);
    MXFP8_PIN_C(c11_13, 244);
    MXFP8_PIN_C(c11_14, 248);
    MXFP8_PIN_C(c11_15, 252);
#undef MXFP8_PIN_C

    D_SF_PACK v_sfa[2];
    D_SF_PACK v_sfb[T::SCALE_N_HALVES];
    D_SF_PACK v_sfa1_next;
    D_SF_PACK v_scale_sfa_prepared = {};
    D_SF_PACK v_scale_sfb_prepared = {};
    D_SF_PACK v_scale_sfa_raw = {};
    D_SF_PACK v_scale_sfb_raw = {};
    auto ga_offset = [&](int half_tile_m, int tile_k) { return half_tile_m * T::HALF_B_M * kargs.stride_a + tile_k * T::B_K; };
    auto gb_offset = [&](int half_tile_n, int tile_k) { return half_tile_n * T::HALF_B_N * kargs.stride_b + tile_k * T::B_K * 16; };
    auto sa_offset = [&](int stage, int half_tile_m) { return (stage * 2 + half_tile_m) * smem_a_elem; };
    auto sb_offset = [&](int stage, int half_tile_n) { return (stage * 2 + half_tile_n) * smem_b_elem; };
    auto ssfa_offset = [&](int stage) { return stage * smem_sfa_elem; };
    auto ssfb_offset = [&](int stage) { return stage * smem_sfb_elem; };

    const int loops = num_tiles_k;

    auto scale_sfa_row = [&](int owner_lane) {
        const int scale_r = owner_lane % T::W_M;
        const int scale_call = owner_lane / T::W_M;
        const int sfa_m_call = wave_id_n * T::E_M + scale_call;
        return sfa_m_call * T::T_M * T::W_M
            + wave_id_m * T::W_M + scale_r;
    };

    auto load_scale_raw = [&](int tile_k) {
        // Wave-uniform K offsets stay in soffset. A's lane pattern covers
        // four 16-row groups; B's lanes repeat the same N128 block byte.
        const auto raw_a = load<1>(
            g_sfa, scale_sfa_row(lane_id), tile_k * kargs.stride_sfa);
        const auto raw_b = load<1>(
            g_sfb, 0, wave_id_m * kargs.stride_sfb + tile_k);
        v_scale_sfa_raw = static_cast<D_SF_PACK>(raw_a[0]);
        v_scale_sfb_raw = static_cast<D_SF_PACK>(raw_b[0]);
    };

    // The caller has drained VMEM before these values are consumed. Pack
    // A's four M-repeat exponents into a word, broadcasting each K128
    // exponent to all K32 lane groups; B repeats one exponent in four bytes.
    auto prepare_scale = [&]() {
        v_scale_sfa_prepared = transpose_scale_dword_4x4(v_scale_sfa_raw * 0x01010101u, lane_id / T::W_M);
        v_scale_sfb_prepared = v_scale_sfb_raw * 0x01010101u;
    };

    auto load_sfa_dword = [&](int read_stage, int half_tile_m) {
        const int addr = ssfa_offset(read_stage)
            + (wave_id_m * T::W_M + lane_id % T::W_M) * 32
            + (lane_id / T::W_M) * 8 + half_tile_m * 4;
        return __builtin_bit_cast(D_SF_PACK, load<4>(s_sfa, addr));
    };

    auto publish_scale = [&](int load_stage) {
        const int scale_r = lane_id % T::W_M;
        const int scale_call = lane_id / T::W_M;
        const int sfb_half_n = wave_id_m;

        const int sfa_store_addr = ssfa_offset(load_stage)
            + ((wave_id_m * T::W_M + scale_r) * 4 + scale_call) * 8
            + wave_id_n * T::E_M;

        const int sfb_store_base =
            ssfb_offset(load_stage) +
            ((((sfb_half_n * T::T_N + wave_id_n) * T::W_N
                + scale_r)
                   * T::SCALE_KGROUPS_PER_MFMA
               + scale_call)
                  * T::SCALE_N_CALLS);

        store<4>(s_sfa, __builtin_bit_cast(opus::vector_t<D_SF, 4>, v_scale_sfa_prepared), sfa_store_addr);
        store<4>(
            s_sfb,
            __builtin_bit_cast(
                opus::vector_t<D_SF, 4>, v_scale_sfb_prepared),
            sfb_store_base);
    };

    // Prologue
    load_scale_raw(0);
    async_load<T::VEC_A>(g_a, s_a.ptr, u_ga, u_sa + sa_offset(0, 0), ga_offset(0, 0));
    async_load<T::VEC_B>(g_b, s_b.ptr, u_gb, u_sb + sb_offset(0, 0), gb_offset(0, 0));
    async_load<T::VEC_A>(g_a, s_a.ptr, u_ga, u_sa + sa_offset(0, 1), ga_offset(1, 0));
    async_load<T::VEC_B>(g_b, s_b.ptr, u_gb, u_sb + sb_offset(0, 1), gb_offset(1, 0));

    s_waitcnt_vmcnt(0_I);

    prepare_scale();
    publish_scale(0);

    s_waitcnt_lgkmcnt(0_I);
    __builtin_amdgcn_s_barrier();
    __builtin_amdgcn_sched_barrier(0);

    int stage = 0;
    int scale_stage = 0;
    int tile = 0;

    // Seed tile 1 only when it exists. The main-loop header publishes the
    // prepared byte/word after this prologue has uniformly drained VMEM.
    if (loops > 1) {
        load_scale_raw(1);
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb, u_sb + sb_offset(1, 0), gb_offset(0, 1));
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb, u_sb + sb_offset(1, 1), gb_offset(1, 1));
        s_waitcnt_vmcnt(0_I);
        prepare_scale();
        __builtin_amdgcn_sched_barrier(0);
    }

    // Seed the register rolling used by CX1.  B-half0, SFB0, and both SFA
    // dwords for the first K tile are loaded once here.  SFA0 is later reused
    // in place, while SFA1 is carried in a dedicated next-tile VGPR.
    v_sfa[0] = load_sfa_dword(scale_stage, 0);
    v_sfa[1] = load_sfa_dword(scale_stage, 1);
    v_sfb[0] = __builtin_bit_cast(
        D_SF_PACK,
        load<4>(s_sfb, u_rsfb_0 + ssfb_offset(scale_stage)));
    v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 0));
    __builtin_amdgcn_sched_barrier(0);

    // Wrap the sole out-of-range tile+2 producer to the valid tile zero.
    // Its destination stage is dead after the last iteration. This also
    // handles short K128-aligned inputs without an out-of-bounds prefetch.
#pragma unroll 4
    for (tile = 0; tile + 1 < loops; ++tile) {
        const int next_stage = stage ^ 1;
        const int future_tile = tile + 2 < loops ? tile + 2 : 0;

        // The preceding iteration prepared these values after draining
        // their VMEM loads. Retain the original two-store publication point.
        auto publish_next_scale = [&]() {
            publish_scale(next_stage);
        };

        v_a[0] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 0));
        __builtin_amdgcn_sched_barrier(0);

        v_sfb[1] = __builtin_bit_cast(D_SF_PACK, load<4>(s_sfb, u_rsfb_1 + ssfb_offset(scale_stage)));
        __builtin_amdgcn_sched_barrier(0);

        publish_next_scale();
        __builtin_amdgcn_sched_barrier(0);
        // Read t+2 now; the existing 36-MFMA VMEM drain completes these
        // compact loads before c11 prepares them for the next header.
        load_scale_raw(future_tile);
        const auto u_sa_next_0 = u_sa + sa_offset(next_stage, 0);
        const auto u_sa_next_1 = u_sa + sa_offset(next_stage, 1);
        __builtin_amdgcn_sched_barrier(0);

        // All LDS reads here are compiler-visible intrinsics. Let LLVM's
        // waitcnt pass wait at the actual operand consumers; publication
        // still has the explicit vmcnt(0)/lgkmcnt(0)/barrier below.
        __builtin_amdgcn_s_setprio(1);

        // A half 0 x B half 0 -> C[0][0] (128x128 wave quadrant).
        // One scaled MFMA occupies the XDL pipe for roughly 32 cycles on
        // gfx950.  Place the four independent A0(t+1) DTLDS requests directly
        // behind it so their issue work can co-execute with that XDL window.
        MXFP8_MMA_ONE(
            0, 0, 0, v_a[0], v_b, c00_0, v_sfa, v_sfb[0]);
        sched_barrier_one_scale();
        async_load_issue_scale<T::VEC_A, 0>(
            g_a, s_a.ptr, u_ga, u_sa_next_0, ga_offset(0, tile + 1));
        async_load_issue_scale<T::VEC_A, 1>(
            g_a, s_a.ptr, u_ga, u_sa_next_0, ga_offset(0, tile + 1));
        async_load_issue_scale<T::VEC_A, 2>(
            g_a, s_a.ptr, u_ga, u_sa_next_0, ga_offset(0, tile + 1));
        async_load_issue_scale<T::VEC_A, 3>(
            g_a, s_a.ptr, u_ga, u_sa_next_0, ga_offset(0, tile + 1));
        __builtin_amdgcn_sched_group_barrier(0x20, 4, 0);

        MXFP8_MMA_ONE(
            0, 0, 1, v_a[0], v_b, c00_1, v_sfa, v_sfb[0]);
        sched_barrier_one_scale();
        async_load_issue_scale<T::VEC_A, 0>(
            g_a, s_a.ptr, u_ga, u_sa_next_1, ga_offset(1, tile + 1));
        async_load_issue_scale<T::VEC_A, 1>(
            g_a, s_a.ptr, u_ga, u_sa_next_1, ga_offset(1, tile + 1));
        async_load_issue_scale<T::VEC_A, 2>(
            g_a, s_a.ptr, u_ga, u_sa_next_1, ga_offset(1, tile + 1));
        async_load_issue_scale<T::VEC_A, 3>(
            g_a, s_a.ptr, u_ga, u_sa_next_1, ga_offset(1, tile + 1));
        __builtin_amdgcn_sched_group_barrier(0x20, 4, 0);
        __builtin_amdgcn_sched_barrier(0);

        v_a[1] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 1));
        // A1 is independent of c00. Its first c10 consumer determines the
        // required wait, with no eager whole-vector drain here.

        MXFP8_MMA_PAIR(
            0, 0, 1, v_a[0], v_b, c00_2, c00_3, v_sfa, v_sfb[0]);
        sched_barrier_pairs_scale();

        // Issue the count-4 B1 head after four c00 MFMAs. The remaining
        // twelve c00 MFMAs plus c10 cover it; the count-8 tail stays fixed
        // after complete c00.
        auto rb1_offsets_head =
            opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(stage, 1));
        load_b_range_scale<T, 0, 4>(
            s_b, rb1_offsets_head, v_b_second);
        __builtin_amdgcn_sched_group_barrier(0x100, 4, 0);

        MXFP8_MMA_PAIR(
            0, 1, 0, v_a[0], v_b, c00_4, c00_5, v_sfa, v_sfb[0]);
        sched_barrier_pairs_scale();

        MXFP8_MMA_PAIR(
            0, 1, 1, v_a[0], v_b, c00_6, c00_7, v_sfa, v_sfb[0]);
        sched_barrier_pairs_scale();

        MXFP8_MMA_PAIR(
            0, 2, 0, v_a[0], v_b, c00_8, c00_9, v_sfa, v_sfb[0]);
        sched_barrier_pairs_scale();

        MXFP8_MMA_PAIR(
            0, 2, 1, v_a[0], v_b, c00_10, c00_11, v_sfa, v_sfb[0]);
        sched_barrier_pairs_scale();

        MXFP8_MMA_PAIR(
            0, 3, 0, v_a[0], v_b, c00_12, c00_13, v_sfa, v_sfb[0]);
        sched_barrier_pairs_scale();

        MXFP8_MMA_PAIR(
            0, 3, 1, v_a[0], v_b, c00_14, c00_15, v_sfa, v_sfb[0]);
        sched_barrier_pairs_scale();

        // Start the first half of the B1 tail after complete c00.  Its first
        // consumers are earlier in the B1 chain, so keep their full c10
        // latency shadow.
        auto rb1_offsets_tail =
            opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(stage, 1));
        load_b_range_scale<T, 4, 6>(
            s_b, rb1_offsets_tail, v_b_second);
        __builtin_amdgcn_sched_group_barrier(0x100, 4, 0);

        // A half 1 x B half 0 -> C[1][0] (128x128 wave quadrant).
        MXFP8_MMA_PAIR(
            1, 0, 0, v_a[1], v_b, c10_0, c10_1, v_sfa, v_sfb[0]);
        sched_barrier_pairs_scale();

        MXFP8_MMA_PAIR(
            1, 0, 1, v_a[1], v_b, c10_2, c10_3, v_sfa, v_sfb[0]);
        sched_barrier_pairs_scale();

        // The final two B1-tail chunks are consumed later.  Issue them after
        // four c10 MFMAs and cover their latency with the remaining twelve.
        load_b_range_scale<T, 6, 8>(
            s_b, rb1_offsets_tail, v_b_second);
        __builtin_amdgcn_sched_group_barrier(0x100, 4, 0);

        MXFP8_MMA_PAIR(
            1, 1, 0, v_a[1], v_b, c10_4, c10_5, v_sfa, v_sfb[0]);
        sched_barrier_pairs_scale();

        MXFP8_MMA_PAIR(
            1, 1, 1, v_a[1], v_b, c10_6, c10_7, v_sfa, v_sfb[0]);
        sched_barrier_pairs_scale();

        MXFP8_MMA_PAIR(
            1, 2, 0, v_a[1], v_b, c10_8, c10_9, v_sfa, v_sfb[0]);
        sched_barrier_pairs_scale();

        MXFP8_MMA_PAIR(
            1, 2, 1, v_a[1], v_b, c10_10, c10_11, v_sfa, v_sfb[0]);
        sched_barrier_pairs_scale();

        MXFP8_MMA_PAIR(
            1, 3, 0, v_a[1], v_b, c10_12, c10_13, v_sfa, v_sfb[0]);
        sched_barrier_pairs_scale();

        MXFP8_MMA_PAIR(
            1, 3, 1, v_a[1], v_b, c10_14, c10_15, v_sfa, v_sfb[0]);
        sched_barrier_pairs_scale();

        const auto& v_b_n1 = v_b_second;

        // A half 0 x B half 1 -> C[0][1] (128x128 wave quadrant).
        MXFP8_MMA_PAIR(
            0, 0, 0, v_a[0], v_b_n1, c01_0, c01_1, v_sfa, v_sfb[1]);
        sched_barrier_pairs_scale();

        MXFP8_MMA_PAIR(
            0, 0, 1, v_a[0], v_b_n1, c01_2, c01_3, v_sfa, v_sfb[1]);
        sched_barrier_pairs_scale();

        // All operands for tile t are now resident in VGPRs.  Publish tile
        // t+1 and release tile t's LDS stage with the same barrier, then start
        // the cold B path for tile t+2 while the final 28 MFMAs of tile t run.
        __builtin_amdgcn_s_setprio(0);
        s_waitcnt_vmcnt(0_I);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);

        __builtin_amdgcn_s_setprio(1);

        // Split the tile+2 B copies into four requests per half around the
        // original two single-MFMA windows. The old stage is now released.
        MXFP8_MMA_ONE(
            0, 1, 0, v_a[0], v_b_n1, c01_4, v_sfa, v_sfb[1]);
        sched_barrier_one_scale();
        const auto u_sb_future_0 = u_sb + sb_offset(stage, 0);
        async_load_issue_b_contiguous_scale<T, 0>(
            g_b, s_b.ptr, u_gb, u_sb_future_0, gb_offset(0, future_tile),
            kargs.stride_b);
        async_load_issue_b_contiguous_scale<T, 1>(
            g_b, s_b.ptr, u_gb, u_sb_future_0, gb_offset(0, future_tile),
            kargs.stride_b);
        async_load_issue_b_contiguous_scale<T, 2>(
            g_b, s_b.ptr, u_gb, u_sb_future_0, gb_offset(0, future_tile),
            kargs.stride_b);
        async_load_issue_b_contiguous_scale<T, 3>(
            g_b, s_b.ptr, u_gb, u_sb_future_0, gb_offset(0, future_tile),
            kargs.stride_b);
        __builtin_amdgcn_sched_group_barrier(0x20, 4, 0);

        MXFP8_MMA_ONE(
            0, 1, 1, v_a[0], v_b_n1, c01_5, v_sfa, v_sfb[1]);
        sched_barrier_one_scale();
        const auto u_sb_future_1 = u_sb + sb_offset(stage, 1);
        async_load_issue_b_contiguous_scale<T, 0>(
            g_b, s_b.ptr, u_gb, u_sb_future_1, gb_offset(1, future_tile),
            kargs.stride_b);
        async_load_issue_b_contiguous_scale<T, 1>(
            g_b, s_b.ptr, u_gb, u_sb_future_1, gb_offset(1, future_tile),
            kargs.stride_b);
        async_load_issue_b_contiguous_scale<T, 2>(
            g_b, s_b.ptr, u_gb, u_sb_future_1, gb_offset(1, future_tile),
            kargs.stride_b);
        async_load_issue_b_contiguous_scale<T, 3>(
            g_b, s_b.ptr, u_gb, u_sb_future_1, gb_offset(1, future_tile),
            kargs.stride_b);
        __builtin_amdgcn_sched_group_barrier(0x20, 4, 0);
        __builtin_amdgcn_sched_barrier(0);

        // The next scale stage is published and c01_5 has issued.  Start SFA1
        // for tile t+1 in a dedicated VGPR; the remaining ten c01 plus all
        // sixteen c11 MFMAs hide the read without shortening SFA0's lifetime.
        v_sfa1_next = load_sfa_dword(next_stage, 1);

        // The current tile no longer consumes B-half0 or SFB0.  Read those
        // operands for tile t+1 from the newly published next_stage while the
        // remaining twenty-six current-tile MFMAs execute.  The two future-B
        // request groups above are already in flight before these DS reads.
        v_sfb[0] = __builtin_bit_cast(
            D_SF_PACK,
            load<4>(s_sfb, u_rsfb_0 + ssfb_offset(next_stage)));
        v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(next_stage, 0));
        __builtin_amdgcn_sched_barrier(0);

        MXFP8_MMA_PAIR(
            0, 1, 1, v_a[0], v_b_n1, c01_6, c01_7, v_sfa, v_sfb[1]);
        sched_barrier_pairs_scale();

        MXFP8_MMA_PAIR(
            0, 2, 0, v_a[0], v_b_n1, c01_8, c01_9, v_sfa, v_sfb[1]);
        sched_barrier_pairs_scale();

        MXFP8_MMA_PAIR(
            0, 2, 1, v_a[0], v_b_n1, c01_10, c01_11, v_sfa, v_sfb[1]);
        sched_barrier_pairs_scale();

        MXFP8_MMA_PAIR(
            0, 3, 0, v_a[0], v_b_n1, c01_12, c01_13, v_sfa, v_sfb[1]);
        sched_barrier_pairs_scale();

        MXFP8_MMA_PAIR(
            0, 3, 1, v_a[0], v_b_n1, c01_14, c01_15, v_sfa, v_sfb[1]);
        sched_barrier_pairs_scale();

        // SFA0 is dead after the final c01 MFMA.  Reuse the same VGPR for the
        // next tile's SFA0 now, then hide this LDS read under all sixteen c11
        // MFMAs.  The true register anti-dependency prevents the read from
        // moving above the last current-tile SFA0 consumer.
        __builtin_amdgcn_sched_barrier(0);
        v_sfa[0] = load_sfa_dword(next_stage, 0);
        __builtin_amdgcn_sched_barrier(0);

        // A half 1 x B half 1 -> C[1][1] (128x128 wave quadrant).
        MXFP8_MMA_PAIR(
            1, 0, 0, v_a[1], v_b_n1, c11_0, c11_1, v_sfa, v_sfb[1]);
        sched_barrier_pairs_scale();

        MXFP8_MMA_PAIR(
            1, 0, 1, v_a[1], v_b_n1, c11_2, c11_3, v_sfa, v_sfb[1]);
        sched_barrier_pairs_scale();

        // The compact loads were completed by the 36-MFMA VMEM drain.
        // Keep preparation at the original c11-after4 cut point; the next
        // header publishes A's byte and B's four-byte broadcast.
        prepare_scale();

        MXFP8_MMA_PAIR(
            1, 1, 0, v_a[1], v_b_n1, c11_4, c11_5, v_sfa, v_sfb[1]);
        sched_barrier_pairs_scale();

        MXFP8_MMA_PAIR(
            1, 1, 1, v_a[1], v_b_n1, c11_6, c11_7, v_sfa, v_sfb[1]);
        sched_barrier_pairs_scale();

        MXFP8_MMA_PAIR(
            1, 2, 0, v_a[1], v_b_n1, c11_8, c11_9, v_sfa, v_sfb[1]);
        sched_barrier_pairs_scale();

        MXFP8_MMA_PAIR(
            1, 2, 1, v_a[1], v_b_n1, c11_10, c11_11, v_sfa, v_sfb[1]);
        sched_barrier_pairs_scale();

        MXFP8_MMA_PAIR(
            1, 3, 0, v_a[1], v_b_n1, c11_12, c11_13, v_sfa, v_sfb[1]);
        sched_barrier_pairs_scale();

        MXFP8_MMA_PAIR(
            1, 3, 1, v_a[1], v_b_n1, c11_14, c11_15, v_sfa, v_sfb[1]);
        sched_barrier_pairs_scale();
        __builtin_amdgcn_s_setprio(0);
        v_sfa[1] = v_sfa1_next;
        stage = next_stage;
        scale_stage = next_stage;
    }

    // Consume the final resident tile without issuing more global loads.
    v_a[0] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 0));
    v_a[1] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 1));

    s_waitcnt_lgkmcnt(0_I);
    v_sfb[1] = __builtin_bit_cast(D_SF_PACK, load<4>(s_sfb, u_rsfb_1 + ssfb_offset(scale_stage)));

    __builtin_amdgcn_s_setprio(1);
    auto p_coord_c = opus::make_tuple(
        wave_id_m, lane_id % mma.grpn_c,
        wave_id_n, lane_id / mma.grpn_c);
    auto u_gc = partition_layout_c<T::VEC_C>(
        mma, opus::make_tuple(kargs.stride_c, 1_I), p_coord_c);

    auto c_offset = [&](int half_tile_m, int half_tile_n) {
        return half_tile_m * T::HALF_B_M * kargs.stride_c +
               half_tile_n * T::HALF_B_N;
    };

    const auto gc_offsets = opus::layout_to_offsets<T::VEC_C>(u_gc);
#define MXFP8_STORE_AGPR_FRAGMENT(ACC, INDEX)                                   \
    do {                                                                        \
        if constexpr (T::OUTPUT_BF16) {                                         \
            g_c.template store<T::VEC_C>(cast<D_C>(ACC),                         \
                gc_offsets[INDEX], soff, opus::number<0>{});                     \
        } else {                                                                \
            g_c.template store<T::VEC_C>(ACC, gc_offsets[INDEX], soff,            \
                opus::number<2>{});                                              \
        }                                                                       \
    } while (false)
#define MXFP8_STORE_QUADRANT(PREFIX, HALF_M, HALF_N)                            \
    do {                                                                        \
        const int soff = c_offset(HALF_M, HALF_N);                              \
        MXFP8_STORE_AGPR_FRAGMENT(PREFIX##_0, 0);                               \
        MXFP8_STORE_AGPR_FRAGMENT(PREFIX##_1, 1);                               \
        MXFP8_STORE_AGPR_FRAGMENT(PREFIX##_2, 2);                               \
        MXFP8_STORE_AGPR_FRAGMENT(PREFIX##_3, 3);                               \
        MXFP8_STORE_AGPR_FRAGMENT(PREFIX##_4, 4);                               \
        MXFP8_STORE_AGPR_FRAGMENT(PREFIX##_5, 5);                               \
        MXFP8_STORE_AGPR_FRAGMENT(PREFIX##_6, 6);                               \
        MXFP8_STORE_AGPR_FRAGMENT(PREFIX##_7, 7);                               \
        MXFP8_STORE_AGPR_FRAGMENT(PREFIX##_8, 8);                               \
        MXFP8_STORE_AGPR_FRAGMENT(PREFIX##_9, 9);                               \
        MXFP8_STORE_AGPR_FRAGMENT(PREFIX##_10, 10);                             \
        MXFP8_STORE_AGPR_FRAGMENT(PREFIX##_11, 11);                             \
        MXFP8_STORE_AGPR_FRAGMENT(PREFIX##_12, 12);                             \
        MXFP8_STORE_AGPR_FRAGMENT(PREFIX##_13, 13);                             \
        MXFP8_STORE_AGPR_FRAGMENT(PREFIX##_14, 14);                             \
        MXFP8_STORE_AGPR_FRAGMENT(PREFIX##_15, 15);                             \
    } while (false)

    MXFP8_MMA_PAIR(0, 0, 0, v_a[0], v_b, c00_0, c00_1, v_sfa, v_sfb[0]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(0, 0, 1, v_a[0], v_b, c00_2, c00_3, v_sfa, v_sfb[0]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(0, 1, 0, v_a[0], v_b, c00_4, c00_5, v_sfa, v_sfb[0]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(0, 1, 1, v_a[0], v_b, c00_6, c00_7, v_sfa, v_sfb[0]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(0, 2, 0, v_a[0], v_b, c00_8, c00_9, v_sfa, v_sfb[0]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(0, 2, 1, v_a[0], v_b, c00_10, c00_11, v_sfa, v_sfb[0]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(0, 3, 0, v_a[0], v_b, c00_12, c00_13, v_sfa, v_sfb[0]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(0, 3, 1, v_a[0], v_b, c00_14, c00_15, v_sfa, v_sfb[0]);
    sched_barrier_pairs_scale();


    MXFP8_MMA_PAIR(1, 0, 0, v_a[1], v_b, c10_0, c10_1, v_sfa, v_sfb[0]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(1, 0, 1, v_a[1], v_b, c10_2, c10_3, v_sfa, v_sfb[0]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(1, 1, 0, v_a[1], v_b, c10_4, c10_5, v_sfa, v_sfb[0]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(1, 1, 1, v_a[1], v_b, c10_6, c10_7, v_sfa, v_sfb[0]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(1, 2, 0, v_a[1], v_b, c10_8, c10_9, v_sfa, v_sfb[0]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(1, 2, 1, v_a[1], v_b, c10_10, c10_11, v_sfa, v_sfb[0]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(1, 3, 0, v_a[1], v_b, c10_12, c10_13, v_sfa, v_sfb[0]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(1, 3, 1, v_a[1], v_b, c10_14, c10_15, v_sfa, v_sfb[0]);
    sched_barrier_pairs_scale();

    // B-half0 is dead on the final K tile.  Start the direct AGPR stores for
    // both completed C quadrants before the B-half1 MFMAs occupy the XDL pipe.
    MXFP8_STORE_QUADRANT(c00, 0, 0);
    MXFP8_STORE_QUADRANT(c10, 1, 0);

    v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 1));

    MXFP8_MMA_PAIR(0, 0, 0, v_a[0], v_b, c01_0, c01_1, v_sfa, v_sfb[1]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(0, 0, 1, v_a[0], v_b, c01_2, c01_3, v_sfa, v_sfb[1]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(0, 1, 0, v_a[0], v_b, c01_4, c01_5, v_sfa, v_sfb[1]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(0, 1, 1, v_a[0], v_b, c01_6, c01_7, v_sfa, v_sfb[1]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(0, 2, 0, v_a[0], v_b, c01_8, c01_9, v_sfa, v_sfb[1]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(0, 2, 1, v_a[0], v_b, c01_10, c01_11, v_sfa, v_sfb[1]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(0, 3, 0, v_a[0], v_b, c01_12, c01_13, v_sfa, v_sfb[1]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(0, 3, 1, v_a[0], v_b, c01_14, c01_15, v_sfa, v_sfb[1]);
    sched_barrier_pairs_scale();


    MXFP8_MMA_PAIR(1, 0, 0, v_a[1], v_b, c11_0, c11_1, v_sfa, v_sfb[1]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(1, 0, 1, v_a[1], v_b, c11_2, c11_3, v_sfa, v_sfb[1]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(1, 1, 0, v_a[1], v_b, c11_4, c11_5, v_sfa, v_sfb[1]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(1, 1, 1, v_a[1], v_b, c11_6, c11_7, v_sfa, v_sfb[1]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(1, 2, 0, v_a[1], v_b, c11_8, c11_9, v_sfa, v_sfb[1]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(1, 2, 1, v_a[1], v_b, c11_10, c11_11, v_sfa, v_sfb[1]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(1, 3, 0, v_a[1], v_b, c11_12, c11_13, v_sfa, v_sfb[1]);
    sched_barrier_pairs_scale();

    MXFP8_MMA_PAIR(1, 3, 1, v_a[1], v_b, c11_14, c11_15, v_sfa, v_sfb[1]);
    sched_barrier_pairs_scale();
    __builtin_amdgcn_s_setprio(0);

    MXFP8_STORE_QUADRANT(c01, 0, 1);
    MXFP8_STORE_QUADRANT(c11, 1, 1);
#undef MXFP8_STORE_QUADRANT
#undef MXFP8_STORE_AGPR_FRAGMENT
#undef MXFP8_MMA_ONE
#undef MXFP8_MMA_PAIR
}

} // namespace blockscale_generic
