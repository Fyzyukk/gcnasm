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

using opus::operator""_I;

// Source-only isolation modes used by variants/source_baseline_isolated.
// Mode 0 is byte-for-byte the retained control flow after preprocessing.
// Each non-zero mode enables exactly one source-level experiment.
#ifndef MXFP8_ISOLATED_SOURCE_CHANGE
#define MXFP8_ISOLATED_SOURCE_CHANGE 0
#endif

#if MXFP8_ISOLATED_SOURCE_CHANGE < 0 || MXFP8_ISOLATED_SOURCE_CHANGE > 4
#error "unknown MXFP8_ISOLATED_SOURCE_CHANGE"
#endif

// The retained/default path consumes host-packed scale tiles directly through
// DTLDS.  The experimental path keeps the public row-major scale ABI and
// performs a two-phase 4x4 transpose in VGPRs before publishing to a four-stage
// LDS ring.  Keeping this behind a compile-time switch leaves the packed
// baseline instruction-identical.
#ifndef MXFP8_ROW_MAJOR_SCALE
#define MXFP8_ROW_MAJOR_SCALE 0
#endif

#ifndef MXFP8_ROW_SCALE_PAIR_POSITION
#define MXFP8_ROW_SCALE_PAIR_POSITION 1
#endif

// Split the six-instruction pair transpose across the MFMA window.  The
// prepare position performs permlane16 plus the two byte permutes and retains
// their two dwords; the ordinary pair position finishes with permlane32, two
// byte permutes, and the LDS write.  Zero keeps the original atomic
// publication.  This is intentionally restricted to the plain double queue,
// whose retained finish point is position 10.
#ifndef MXFP8_ROW_SCALE_PAIR_PREPARE_POSITION
#define MXFP8_ROW_SCALE_PAIR_PREPARE_POSITION 0
#endif

#ifndef MXFP8_ROW_SCALE_SPLIT_QUEUE
#define MXFP8_ROW_SCALE_SPLIT_QUEUE 0
#endif

#ifndef MXFP8_ROW_SCALE_DOUBLE_QUEUE
#define MXFP8_ROW_SCALE_DOUBLE_QUEUE 0
#endif

// Transpose and publish all four resident scale tiles together.  The cooked
// LDS image interleaves the low stage/q bits so one ds_write_b128 replaces
// the two pairwise ds_write2_b32 publications.  Consumer loads remain one
// SFA read plus one SFB read2 per tile.
#ifndef MXFP8_ROW_SCALE_GROUP4_PUBLICATION
#define MXFP8_ROW_SCALE_GROUP4_PUBLICATION 0
#endif

// Schedule the ordinary row-major scale VMEM refill independently from the
// six lane-permute publication instructions.  The numeric positions match
// the MFMA cadence used by MXFP8_ROW_SCALE_PAIR_POSITION: 0 is immediately
// before the first repeat_n2, 1..4 follow the first four repeat_n2 calls, and
// 8 is immediately before loading/consuming B half 1.  Position 1 preserves
// the retained double-queue instruction schedule.
#ifndef MXFP8_ROW_SCALE_PREFETCH_POSITION
#define MXFP8_ROW_SCALE_PREFETCH_POSITION 1
#endif

#ifndef MXFP8_ROW_SCALE_QUEUE8
#define MXFP8_ROW_SCALE_QUEUE8 0
#endif

// Keep the four-stage publication schedule, but fetch adjacent groups in
// eight-tile pairs.  This preserves the double-queue register footprint while
// recovering the row-major cache-sector locality observed with QUEUE8.
#ifndef MXFP8_ROW_SCALE_PAIRED_REFILL
#define MXFP8_ROW_SCALE_PAIRED_REFILL 0
#endif

// Six-register wide fetch: keep one four-tile group and the first pair of the
// next group in VGPRs, while the final adjacent pair is loaded directly into a
// wave-private LDS slot.  The three requests cover one contiguous 32-byte
// row-major scale span without the eight live queue VGPRs of QUEUE8.
#ifndef MXFP8_ROW_SCALE_QUEUE6_RAWTAIL
#define MXFP8_ROW_SCALE_QUEUE6_RAWTAIL 0
#endif

#ifndef MXFP8_ROW_SCALE_PHASE_UNROLL
#define MXFP8_ROW_SCALE_PHASE_UNROLL 0
#endif

// Experimental gfx950 two-pass LDS transpose.  A single DTLDS b128 writes
// four row-major K tiles to a wave-private raw slot.  The first TR_B8 read
// turns rows into 8-byte columns; the consumer's second TR_B8 read turns the
// four M/N calls into the packed scale dwords required by scaled MFMA.
#ifndef MXFP8_ROW_SCALE_TR_READ
#define MXFP8_ROW_SCALE_TR_READ 0
#endif

// Load one row-major scale dword per producer lane directly into a four-stage
// raw LDS ring.  The lane-to-row mapping makes each 256-byte producer slab a
// set of four 4x16 byte matrices.  Consumers use one TR_B8 for SFA and one
// TR_B8 for both SFB halves, followed by lane routing with ds_bpermute.  This
// removes the VGPR scale queue and all cooked-scale LDS publications.
#ifndef MXFP8_ROW_SCALE_RAW_TR_BPERMUTE
#define MXFP8_ROW_SCALE_RAW_TR_BPERMUTE 0
#endif

#ifndef MXFP8_ROW_SCALE_TR_EARLY_STORE
#define MXFP8_ROW_SCALE_TR_EARLY_STORE 0
#endif

// Mode 2 keeps the correct early-store lifetime (the first transpose is
// consumed in the same tile) but separates its read and write across scaled
// MFMAs.  This avoids putting read-tr/wait/write serially at the loop head.
#ifndef MXFP8_ROW_SCALE_TR_ISSUE_POSITION
#define MXFP8_ROW_SCALE_TR_ISSUE_POSITION 1
#endif

#ifndef MXFP8_ROW_SCALE_TR_STORE_POSITION
#define MXFP8_ROW_SCALE_TR_STORE_POSITION 4
#endif

#ifndef MXFP8_ROW_SCALE_TR_INTERLEAVE_WAIT
#define MXFP8_ROW_SCALE_TR_INTERLEAVE_WAIT 15
#endif

#ifndef MXFP8_ROW_SCALE_LOAD_AUX
#define MXFP8_ROW_SCALE_LOAD_AUX 0
#endif

// Reuse the cooked scale dword in the producer wave instead of reading the
// same value back from LDS.  Pair publication needs two additional lane-swap
// instructions to put both K tiles in the consumer lane layout.
#ifndef MXFP8_ROW_SCALE_LOCAL_REUSE
#define MXFP8_ROW_SCALE_LOCAL_REUSE 0
#endif

#ifndef MXFP8_ROW_SCALE_LOCAL_DEBUG
#define MXFP8_ROW_SCALE_LOCAL_DEBUG 0
#endif

// Read cooked scale values for two adjacent K tiles together.  Mode 1 caches
// only SFA.  Mode 2 also moves both conventional SFB reads to the even tile.
// Mode 3 stores tile parity as the innermost LDS dimension, allowing one B64
// read for SFA and one read2-B64 for both SFB halves per tile pair.  Mode 4
// uses the same LDS image but reads one tile at a time as a correctness and
// scheduling control experiment.  Mode 5 reloads the interleaved pair on
// every tile to isolate cross-iteration register-lifetime effects.
#ifndef MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE
#define MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE 0
#endif

#ifndef MXFP8_ROW_SCALE_PAIR_DEBUG
#define MXFP8_ROW_SCALE_PAIR_DEBUG 0
#endif

#if MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE < 0 || \
    MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE > 5
#error "unknown consumer scale pair-cache mode"
#endif

#ifndef MXFP8_BLOCK_ORDER_EXPERIMENT
#define MXFP8_BLOCK_ORDER_EXPERIMENT 0
#endif

// Keep the complete 128-dword C tile in the native accumulator register
// file.  The custom clang23 hard-pin pass turns the connected scaled-MFMA
// chains into tied AGPR destination/SrcC operations and permits direct AGPR
// output stores.
#ifndef MXFP8_ROW_C_AGPR
#define MXFP8_ROW_C_AGPR 0
#endif

// The compute loop historically used a four-way unroll.  Keep the retained
// value as the default, but allow compact-loop experiments that reduce
// duplicated phase dispatch and I-cache pressure without changing the scale
// data path.  This applies to every row-major queue mode, not only QUEUE8.
#ifndef MXFP8_ROW_SCALE_LOOP_UNROLL
#define MXFP8_ROW_SCALE_LOOP_UNROLL 4
#endif

// Split QUEUE8's two adjacent 16-byte refills across the current MFMA tile.
// The first group is fetched at the publication point and the second after
// the final accumulator use, reducing simultaneous RFIFO pressure.
#ifndef MXFP8_ROW_SCALE_QUEUE8_STAGGER
#define MXFP8_ROW_SCALE_QUEUE8_STAGGER 0
#endif

// Target-only specialization bits for the 8192^3, batch-1 performance point.
// The generic build remains the default.  Keeping shape, matrix strides,
// scale strides, and launch bounds independently selectable lets experiments
// retain only assumptions that improve code generation without increasing
// register pressure.
//   bit 0: exact M/N/K/batch
//   bit 1: exact A/B/C strides
//   bit 2: exact row-major scale strides
//   bit 3: exact grid.x/grid.z bounds
//   bit 4: exact K only (kept separate to avoid specializing the output loop)
//   bit 5: exact M/N only
//   bit 6: exact batch only
#ifndef MXFP8_EXACT_8192
#define MXFP8_EXACT_8192 0
#endif

#if MXFP8_ROW_SCALE_LOOP_UNROLL != 1 && \
    MXFP8_ROW_SCALE_LOOP_UNROLL != 2 && \
    MXFP8_ROW_SCALE_LOOP_UNROLL != 4
#error "row-scale loop unroll must be 1, 2, or 4"
#endif

#if MXFP8_ROW_SCALE_PREFETCH_POSITION != 0 && \
    MXFP8_ROW_SCALE_PREFETCH_POSITION != 1 && \
    MXFP8_ROW_SCALE_PREFETCH_POSITION != 2 && \
    MXFP8_ROW_SCALE_PREFETCH_POSITION != 3 && \
    MXFP8_ROW_SCALE_PREFETCH_POSITION != 4 && \
    MXFP8_ROW_SCALE_PREFETCH_POSITION != 8
#error "row-scale prefetch position must be 0, 1, 2, 3, 4, or 8"
#endif

#if MXFP8_ROW_SCALE_PAIR_PREPARE_POSITION != 0 && \
    MXFP8_ROW_SCALE_PAIR_PREPARE_POSITION != 1 && \
    MXFP8_ROW_SCALE_PAIR_PREPARE_POSITION != 2 && \
    MXFP8_ROW_SCALE_PAIR_PREPARE_POSITION != 4 && \
    MXFP8_ROW_SCALE_PAIR_PREPARE_POSITION != 8
#error "row-scale pair prepare position must be 0, 1, 2, 4, or 8"
#endif

#if MXFP8_ROW_SCALE_LOCAL_REUSE < 0 || MXFP8_ROW_SCALE_LOCAL_REUSE > 6
#error "unknown local cooked-scale reuse mode"
#endif

#if MXFP8_ROW_SCALE_TR_READ < 0 || MXFP8_ROW_SCALE_TR_READ > 2
#error "unknown TR-read scale mode"
#endif

#if MXFP8_ROW_SCALE_RAW_TR_BPERMUTE < 0 || \
    MXFP8_ROW_SCALE_RAW_TR_BPERMUTE > 1
#error "unknown raw TR+bpermute scale mode"
#endif

#if MXFP8_ROW_SCALE_TR_EARLY_STORE < 0 || \
    MXFP8_ROW_SCALE_TR_EARLY_STORE > 3
#error "unknown TR-read early-store mode"
#endif


#if MXFP8_ROW_SCALE_TR_INTERLEAVE_WAIT < 0 || \
    MXFP8_ROW_SCALE_TR_INTERLEAVE_WAIT > 15
#error "TR interleave lgkm wait must be in [0, 15]"
#endif

#if MXFP8_ROW_SCALE_TR_EARLY_STORE == 2 && \
    (MXFP8_ROW_SCALE_TR_ISSUE_POSITION < 1 || \
     MXFP8_ROW_SCALE_TR_ISSUE_POSITION > 10 || \
     MXFP8_ROW_SCALE_TR_STORE_POSITION < 1 || \
     MXFP8_ROW_SCALE_TR_STORE_POSITION > 10 || \
     MXFP8_ROW_SCALE_TR_ISSUE_POSITION >= \
         MXFP8_ROW_SCALE_TR_STORE_POSITION)
#error "deferred TR publication requires 1 <= issue < store <= 10"
#endif

#if (MXFP8_ROW_SCALE_SPLIT_QUEUE + MXFP8_ROW_SCALE_DOUBLE_QUEUE + \
     MXFP8_ROW_SCALE_QUEUE8 + MXFP8_ROW_SCALE_QUEUE6_RAWTAIL) > 1
#error "row-scale queue modes are mutually exclusive"
#endif

#if MXFP8_ROW_SCALE_PAIRED_REFILL && \
    (!MXFP8_ROW_SCALE_DOUBLE_QUEUE || MXFP8_ROW_SCALE_QUEUE8 || \
     MXFP8_ROW_SCALE_PHASE_UNROLL || MXFP8_ROW_SCALE_TR_READ || \
     MXFP8_ROW_SCALE_LOCAL_REUSE)
#error "paired refill requires the plain double queue path"
#endif

#if MXFP8_ROW_SCALE_GROUP4_PUBLICATION && \
    (!MXFP8_ROW_SCALE_DOUBLE_QUEUE || MXFP8_ROW_SCALE_SPLIT_QUEUE || \
     MXFP8_ROW_SCALE_QUEUE8 || MXFP8_ROW_SCALE_PAIRED_REFILL || \
     MXFP8_ROW_SCALE_QUEUE6_RAWTAIL || MXFP8_ROW_SCALE_PHASE_UNROLL || \
     MXFP8_ROW_SCALE_TR_READ || MXFP8_ROW_SCALE_LOCAL_REUSE || \
     MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE)
#error "group4 publication requires the plain double queue path"
#endif

#if MXFP8_ROW_SCALE_LOCAL_REUSE && \
    (!MXFP8_ROW_SCALE_DOUBLE_QUEUE || MXFP8_ROW_SCALE_TR_READ)
#error "local cooked-scale reuse currently requires the double queue path"
#endif

#if MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE && \
    (!MXFP8_ROW_SCALE_DOUBLE_QUEUE || MXFP8_ROW_SCALE_TR_READ || \
     MXFP8_ROW_SCALE_LOCAL_REUSE || MXFP8_ROW_SCALE_PHASE_UNROLL)
#error "consumer pair cache requires the plain dynamic double queue path"
#endif

#if MXFP8_ROW_SCALE_TR_READ && \
    (MXFP8_ROW_SCALE_SPLIT_QUEUE || MXFP8_ROW_SCALE_DOUBLE_QUEUE || \
     MXFP8_ROW_SCALE_QUEUE8 || MXFP8_ROW_SCALE_QUEUE6_RAWTAIL || \
     MXFP8_ROW_SCALE_PHASE_UNROLL)
#error "TR-read scale path has its own queue and phase schedule"
#endif

#if MXFP8_ROW_SCALE_RAW_TR_BPERMUTE && \
    (MXFP8_ROW_SCALE_TR_READ || MXFP8_ROW_SCALE_SPLIT_QUEUE || \
     MXFP8_ROW_SCALE_DOUBLE_QUEUE || MXFP8_ROW_SCALE_QUEUE8 || \
     MXFP8_ROW_SCALE_PAIRED_REFILL || MXFP8_ROW_SCALE_QUEUE6_RAWTAIL || \
     MXFP8_ROW_SCALE_PHASE_UNROLL || MXFP8_ROW_SCALE_GROUP4_PUBLICATION || \
     MXFP8_ROW_SCALE_LOCAL_REUSE || MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE || \
     MXFP8_ROW_SCALE_PAIR_PREPARE_POSITION)
#error "raw TR+bpermute scale path is an isolated scale data path"
#endif

#if MXFP8_ROW_SCALE_PAIR_PREPARE_POSITION && \
    (!MXFP8_ROW_SCALE_DOUBLE_QUEUE || MXFP8_ROW_SCALE_PAIR_POSITION != 10 || \
     MXFP8_ROW_SCALE_SPLIT_QUEUE || MXFP8_ROW_SCALE_QUEUE8 || \
     MXFP8_ROW_SCALE_PAIRED_REFILL || MXFP8_ROW_SCALE_QUEUE6_RAWTAIL || \
     MXFP8_ROW_SCALE_PHASE_UNROLL || MXFP8_ROW_SCALE_TR_READ || \
     MXFP8_ROW_SCALE_GROUP4_PUBLICATION || MXFP8_ROW_SCALE_LOCAL_REUSE || \
     MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE)
#error "split pair prepare requires the plain double queue at pair position 10"
#endif

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


__device__ inline void sched_barrier_pairs_scale() {
    __builtin_amdgcn_sched_group_barrier(0x08, 1, 0);
    __builtin_amdgcn_sched_group_barrier(0x02, 2, 0);
    __builtin_amdgcn_sched_group_barrier(0x08, 1, 0);
    __builtin_amdgcn_sched_group_barrier(0x02, 2, 0);
}

#if MXFP8_ROW_MAJOR_SCALE
// Lanes r, r+16, r+32, and r+48 hold four row-major scale rows.  A pair of
// adjacent K128 phases is transposed together below, sharing the lane
// exchanges and one LDS write instruction.
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

#if MXFP8_EXACT_8192 & 1
    __builtin_assume(kargs.m == 8192);
    __builtin_assume(kargs.n == 8192);
    __builtin_assume(kargs.k == 8192);
    __builtin_assume(kargs.batch == 1);
#endif
#if MXFP8_EXACT_8192 & 16
    __builtin_assume(kargs.k == 8192);
#endif
#if MXFP8_EXACT_8192 & 32
    __builtin_assume(kargs.m == 8192);
    __builtin_assume(kargs.n == 8192);
#endif
#if MXFP8_EXACT_8192 & 64
    __builtin_assume(kargs.batch == 1);
#endif
#if MXFP8_EXACT_8192 & 2
    __builtin_assume(kargs.stride_a == 8192);
    __builtin_assume(kargs.stride_b == 8192);
    __builtin_assume(kargs.stride_c == 8192);
    __builtin_assume(kargs.stride_a_batch == 8192 * 8192);
    __builtin_assume(kargs.stride_b_batch == 8192 * 8192);
    __builtin_assume(kargs.stride_c_batch == 8192 * 8192);
#endif
#if MXFP8_EXACT_8192 & 4
    __builtin_assume(kargs.stride_sfa == 8192 / T::GROUP_K);
    __builtin_assume(kargs.stride_sfb == 8192 / T::GROUP_K);
    __builtin_assume(kargs.stride_sfa_batch ==
                     8192 * (8192 / T::GROUP_K));
    __builtin_assume(kargs.stride_sfb_batch ==
                     8192 * (8192 / T::GROUP_K));
#endif

    const int num_tiles_m = ceil_div_scale(kargs.m, T::B_M);
    const int num_tiles_n = ceil_div_scale(kargs.n, T::B_N);
    const int num_tiles_k = ceil_div_scale(kargs.k, T::B_K);
    const int physical_block_id = block_id_x();
#if MXFP8_EXACT_8192 & 8
    __builtin_assume(physical_block_id < 256);
#endif
    int logical_block_id = physical_block_id;
#if MXFP8_BLOCK_ORDER_EXPERIMENT >= 6 && \
    MXFP8_BLOCK_ORDER_EXPERIMENT <= 8
    if (num_tiles_m == 32 && num_tiles_n == 32) {
        const int macro_id = physical_block_id >> 5;
        const int local_id = physical_block_id & 31;
#if MXFP8_BLOCK_ORDER_EXPERIMENT == 6
        const int block_mgroup =
            (macro_id >> 1) * 2 + (local_id >> 4);
        const int ordered_n =
            (macro_id & 1) * 16 + (local_id & 15);
#elif MXFP8_BLOCK_ORDER_EXPERIMENT == 7
        const int block_mgroup =
            (macro_id >> 2) * 4 + (local_id >> 3);
        const int ordered_n =
            (macro_id & 3) * 8 + (local_id & 7);
#else
        const int block_mgroup = local_id >> 2;
        const int ordered_n = macro_id * 4 + (local_id & 3);
#endif
        logical_block_id = block_mgroup * num_tiles_n + ordered_n;
    }
#elif MXFP8_BLOCK_ORDER_EXPERIMENT != 0
#error "unknown block-order experiment"
#endif
    const int block_n = logical_block_id % num_tiles_n;
    const int first_block_m =
        (logical_block_id / num_tiles_n) * T::OUTPUT_TILES_PER_WG;
    const int col = block_n * T::B_N;
    int first_stage = 0;
    const int batch_id = block_id_z();
#if MXFP8_EXACT_8192 & 8
    __builtin_assume(batch_id == 0);
#endif
    const int wave_id =
        __builtin_amdgcn_readfirstlane(thread_id_x() / T::WARP_SIZE);
    const int lane_id = thread_id_x() % T::WARP_SIZE;
#if MXFP8_ROW_MAJOR_SCALE
    const int wave_id_m = wave_id % T::T_M;
    const int wave_id_n = wave_id / T::T_M;
#if MXFP8_ROW_SCALE_LOCAL_REUSE >= 2 && \
    MXFP8_ROW_SCALE_LOCAL_REUSE <= 5
    // Give every wave exactly one producer role that it also consumes.  The
    // four SFB roles are placed so the other SFB half has the same row index
    // as SFA; because the SFB array follows the four-stage SFA array in LDS,
    // one ds_read2st64_b32(offset1:16) fetches both remaining dwords.
    const bool scale_producer_is_sfa =
        ((wave_id_m ^ wave_id_n) & 1) != 0;
    const int scale_producer_role = scale_producer_is_sfa
        ? wave_id_m
        : ((1 - (wave_id_m >> 1)) * T::T_N + wave_id_n);
#else
    const bool scale_producer_is_sfa = wave_id_n == 0;
    const int scale_producer_role = wave_id_m;
#endif
    const auto* g_sf_base = scale_producer_is_sfa
        ? reinterpret_cast<const D_SF*>(kargs.ptr_sfa) +
              batch_id * kargs.stride_sfa_batch +
              first_block_m * T::B_M * kargs.stride_sfa
        : reinterpret_cast<const D_SF*>(kargs.ptr_sfb) +
              batch_id * kargs.stride_sfb_batch +
              block_n * T::B_N * kargs.stride_sfb;
    auto g_sf = make_gmem(g_sf_base);
#if MXFP8_ROW_SCALE_RAW_TR_BPERMUTE
#elif MXFP8_ROW_SCALE_TR_READ == 1
#elif MXFP8_ROW_SCALE_TR_READ == 2
    opus::u32x4_t v_scale_tr_queue;
#elif MXFP8_ROW_SCALE_SPLIT_QUEUE
    D_SF_PACK v_scale_queue0;
    D_SF_PACK v_scale_queue1;
    D_SF_PACK v_scale_queue2;
    D_SF_PACK v_scale_queue3;
#elif MXFP8_ROW_SCALE_QUEUE6_RAWTAIL
    opus::u32x4_t v_scale_queue;
    opus::u32x2_t v_scale_prefetch_pair;
#else
    opus::u32x4_t v_scale_queue;
#if MXFP8_ROW_SCALE_DOUBLE_QUEUE || MXFP8_ROW_SCALE_QUEUE8
    opus::u32x4_t v_scale_prefetch;
#endif
#endif
#else
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
#endif

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

#if !MXFP8_ROW_MAJOR_SCALE
    const int wave_id_m = wave_id % T::T_M;
    const int wave_id_n = wave_id / T::T_M;
#endif

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

#if !MXFP8_ROW_MAJOR_SCALE
    const auto u_gsfa = make_layout_gsfa_scale<T>(lane_id);
    const auto u_ssfa = make_layout_ssfa_scale<T>();
#endif
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
#if MXFP8_ROW_MAJOR_SCALE
    constexpr int scale_stage_count = 4;
#else
    constexpr int scale_stage_count = 2;
#endif
    __shared__ char smem_sfa[
        smem_sfa_elem * scale_stage_count * sizeof(D_SF)];
    __shared__ char smem_sfb[
        smem_sfb_elem * scale_stage_count * sizeof(D_SF)];
    auto s_sfa = make_smem(reinterpret_cast<D_SF*>(smem_sfa));
    auto s_sfb = make_smem(reinterpret_cast<D_SF*>(smem_sfb));
    static_assert(T::packed_sfa_tile_elem == T::packed_sfb_tile_elem);
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_QUEUE6_RAWTAIL
    constexpr int scale_tail_lane_elem = 8;
    constexpr int scale_tail_wave_elem =
        T::WARP_SIZE * scale_tail_lane_elem;
    __shared__ __align__(256) char smem_sf_queue6_tail[
        T::NUM_WAVES * scale_tail_wave_elem * sizeof(D_SF)];
    auto s_sf_queue6_tail =
        make_smem(reinterpret_cast<D_SF*>(smem_sf_queue6_tail));
#endif
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_TR_READ == 1
    constexpr int raw_scale_lane_elem = 16;
    constexpr int raw_scale_wave_elem =
        T::WARP_SIZE * raw_scale_lane_elem;
    __shared__ __align__(256) char smem_sf_raw[
        T::NUM_WAVES * raw_scale_wave_elem * sizeof(D_SF)];
    auto s_sf_raw = make_smem(reinterpret_cast<D_SF*>(smem_sf_raw));
#endif
#if !MXFP8_ROW_MAJOR_SCALE
    auto* s_sf_ptr = scale_producer_is_sfa ? s_sfa.ptr : s_sfb.ptr;
#endif

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
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_RAW_TR_BPERMUTE
    opus::u32x2_t v_raw_sfa_next;
    opus::u32x2_t v_raw_sfb_next;
    D_SF_PACK v_sfa_next;
    D_SF_PACK v_sfb_next[T::SCALE_N_HALVES];
#endif
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_PAIR_PREPARE_POSITION
    opus::u32x2_t v_scale_pair_prepared;
#endif
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_TR_READ
    opus::u32x2_t v_sfa_tr_pair;
    opus::u32x2_t v_sfb_tr_pair0;
    opus::u32x2_t v_sfb_tr_pair1;
#if MXFP8_ROW_SCALE_TR_READ == 1 && \
    MXFP8_ROW_SCALE_TR_EARLY_STORE != 1
    opus::u32x2_t v_scale_first_transpose;
#endif
#endif
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_LOCAL_REUSE >= 1 && \
    MXFP8_ROW_SCALE_LOCAL_REUSE <= 5
    D_SF_PACK v_scale_local_even;
    D_SF_PACK v_scale_local_odd;
#endif
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE
    opus::u32x2_t v_sfa_consumer_pair;
#if MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE >= 2
    opus::u32x2_t v_sfb_consumer_even;
    opus::u32x2_t v_sfb_consumer_odd;
#endif
#endif
    auto ga_offset = [&](int half_tile_m, int tile_k) { return half_tile_m * T::HALF_B_M * kargs.stride_a + tile_k * T::B_K; };
    auto gb_offset = [&](int half_tile_n, int tile_k) { return half_tile_n * T::HALF_B_N * kargs.stride_b + tile_k * T::B_K; };
    auto sa_offset = [&](int stage, int half_tile_m) { return (stage * 2 + half_tile_m) * smem_a_elem; };
    auto sb_offset = [&](int stage, int half_tile_n) { return (stage * 2 + half_tile_n) * smem_b_elem; };
#if !MXFP8_ROW_MAJOR_SCALE
    auto gsf_offset = [&](int output_delta, int tile_k) {
        return (output_tile + output_delta) * output_stride_sf +
               tile_k * stride_sf;
    };
#endif
    auto ssfa_offset = [&](int stage) { return stage * smem_sfa_elem; };
    auto ssfb_offset = [&](int stage) { return stage * smem_sfb_elem; };
#if !MXFP8_ROW_MAJOR_SCALE || !MXFP8_ROW_SCALE_TR_READ
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_GROUP4_PUBLICATION
    auto group4_scale_offset = [&](int producer_role, int read_stage) {
        const int scale_r = lane_id & 15;
        const int kgroup = lane_id >> 4;
        const int kgroup_low = kgroup & 1;
        const int kgroup_high = kgroup >> 1;
        const int stage_low = read_stage & 1;
        const int stage_high = read_stage >> 1;
        const int dword_offset =
            ((((producer_role * T::W_M + scale_r) * 2 + kgroup_low) *
                   2 +
               stage_low) *
                  4 +
              kgroup_high + 2 * stage_high);
        return dword_offset * sizeof(D_SF_PACK);
    };

    auto load_group4_sfa = [&](int read_stage) {
        const opus::u32_t addr = static_cast<opus::u32_t>(
            reinterpret_cast<__UINTPTR_TYPE__>(
                s_sfa.ptr + group4_scale_offset(wave_id_m, read_stage)));
        D_SF_PACK value;
        asm volatile(
            "ds_read_b32 %0, %1\n"
            : "=v"(value)
            : "v"(addr)
            : "memory");
        return value;
    };

    auto load_sfb_pair = [&](int read_stage) {
        const opus::u32_t addr = static_cast<opus::u32_t>(
            reinterpret_cast<__UINTPTR_TYPE__>(
                s_sfb.ptr + group4_scale_offset(wave_id_n, read_stage)));
        opus::u32x2_t pair;
        // The two N-half producer roles are two 1024-byte role slabs apart.
        // ST64 offsets use 256-byte units, hence offset1=8.
        asm volatile(
            "ds_read2st64_b32 %0, %1 offset0:0 offset1:8\n"
            : "=v"(pair)
            : "v"(addr)
            : "memory");
        return pair;
    };
#else
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
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE
    auto load_sfa_stage_pair = [&](int even_read_stage) {
        const auto offsets = opus::layout_to_offsets<4>(
            u_rsfa + ssfa_offset(even_read_stage));
#if MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE == 3 || \
    MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE == 5
        const int pair_slot = even_read_stage >> 1;
        const opus::u32_t addr = static_cast<opus::u32_t>(
            reinterpret_cast<__UINTPTR_TYPE__>(
                s_sfa.ptr + pair_slot * 2 * smem_sfa_elem +
                offsets[0] * 2 - ssfa_offset(even_read_stage) * 2));
        opus::u32x2_t pair;
        asm volatile(
            "ds_read_b64 %0, %1\n"
            : "=v"(pair)
            : "v"(addr)
            : "memory");
#else
        const opus::u32_t addr = static_cast<opus::u32_t>(
            reinterpret_cast<__UINTPTR_TYPE__>(s_sfa.ptr + offsets[0]));
        opus::u32x2_t pair;
        // Adjacent scale stages are 1024 bytes apart.  ST64 offsets are in
        // units of 64 dwords (256 bytes), hence offset1=4.
        asm volatile(
            "ds_read2st64_b32 %0, %1 offset0:0 offset1:4\n"
            : "=v"(pair)
            : "v"(addr)
            : "memory");
#endif
        return pair;
    };
#if MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE == 3 || \
    MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE == 5
    auto load_sfb_interleaved_pair = [&](int even_read_stage) {
        const auto offsets = opus::layout_to_offsets<4>(u_rsfb_0);
        const int pair_slot = even_read_stage >> 1;
        const opus::u32_t addr = static_cast<opus::u32_t>(
            reinterpret_cast<__UINTPTR_TYPE__>(
                s_sfb.ptr + pair_slot * 2 * smem_sfb_elem +
                offsets[0] * 2));
        opus::u32x4_t both_halves;
        // Each B64 is [even tile, odd tile].  The two SFB half roles are
        // 1024 bytes apart in the parity-interleaved representation.  Use
        // the ordinary read2-B64 encoding, whose offsets are in 8-byte
        // units, so the exact second address is offset1=128.
        asm volatile(
            "ds_read2_b64 %0, %1 offset0:0 offset1:128\n"
            : "=v"(both_halves)
            : "v"(addr)
            : "memory");
        return both_halves;
    };
#endif
#if MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE == 4
    auto load_sfa_interleaved_stage = [&](int read_stage) {
        const auto offsets = opus::layout_to_offsets<4>(u_rsfa);
        const int pair_slot = read_stage >> 1;
        const int tile_parity = read_stage & 1;
        const opus::u32_t addr = static_cast<opus::u32_t>(
            reinterpret_cast<__UINTPTR_TYPE__>(
                s_sfa.ptr + pair_slot * 2 * smem_sfa_elem +
                offsets[0] * 2 + tile_parity * sizeof(D_SF_PACK)));
        D_SF_PACK value;
        asm volatile(
            "ds_read_b32 %0, %1\n"
            : "=v"(value)
            : "v"(addr)
            : "memory");
        return value;
    };
    auto load_sfb_interleaved_stage = [&](int read_stage) {
        const auto offsets = opus::layout_to_offsets<4>(u_rsfb_0);
        const int pair_slot = read_stage >> 1;
        const int tile_parity = read_stage & 1;
        const opus::u32_t addr = static_cast<opus::u32_t>(
            reinterpret_cast<__UINTPTR_TYPE__>(
                s_sfb.ptr + pair_slot * 2 * smem_sfb_elem +
                offsets[0] * 2 + tile_parity * sizeof(D_SF_PACK)));
        opus::u32x2_t pair;
        asm volatile(
            "ds_read2st64_b32 %0, %1 offset0:0 offset1:4\n"
            : "=v"(pair)
            : "v"(addr)
            : "memory");
        return pair;
    };
#endif
#endif
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_LOCAL_REUSE == 2
    auto load_sfa_remote_sfb_pair = [&](int read_stage) {
        const auto offsets = opus::layout_to_offsets<4>(
            u_rsfa + ssfa_offset(read_stage));
        const opus::u32_t addr = static_cast<opus::u32_t>(
            reinterpret_cast<__UINTPTR_TYPE__>(s_sfa.ptr + offsets[0]));
        opus::u32x2_t pair;
        // The role permutation makes the non-local SFB half use the same row
        // as SFA.  The four-stage SFB array starts 4096 bytes after SFA.
        asm volatile(
            "ds_read2st64_b32 %0, %1 offset0:0 offset1:16\n"
            : "=v"(pair)
            : "v"(addr)
            : "memory");
        return pair;
    };
#endif
#endif

#if MXFP8_ROW_MAJOR_SCALE
    static_assert(T::NUM_KGROUPS == 4);
    static_assert(T::W_M == 16 && T::W_N == 16);
    static_assert(T::T_M == 4 && T::T_N == 2);
    static_assert(T::SCALE_M_CALLS == 4 && T::SCALE_N_CALLS == 4);

#if MXFP8_ROW_SCALE_RAW_TR_BPERMUTE
    auto async_load_raw_tr_scale = [&](int output_tile_index,
                                        int scale_tile) {
        // DTLDS uses a wave-uniform LDS base and places one dword from each
        // lane consecutively.  Decode the producer lane so the resulting
        // 256-byte slab is [row_block][call][row_in_block][kgroup].
        const int raw_row_block = lane_id >> 4;
        const int raw_call = (lane_id & 15) >> 2;
        const int raw_row = raw_row_block * 4 + (lane_id & 3);
        int scale_voffset;
        int scale_soffset;
        decltype(s_sfa.ptr) raw_dest;
        const int write_stage = scale_tile & 3;
        if (scale_producer_is_sfa) {
            const int lane_row =
                raw_call * (T::T_M * T::W_M) + raw_row;
            scale_voffset = lane_row * kargs.stride_sfa;
            scale_soffset =
                (output_tile_index * T::B_M +
                 scale_producer_role * T::W_M) *
                    kargs.stride_sfa +
                scale_tile * T::NUM_KGROUPS;
            raw_dest =
                s_sfa.ptr + write_stage * smem_sfa_elem +
                scale_producer_role * T::WARP_SIZE * sizeof(D_SF_PACK);
        } else {
            const int lane_row =
                raw_call * (T::T_N * T::W_N) + raw_row;
            scale_voffset = lane_row * kargs.stride_sfb;
            scale_soffset =
                ((scale_producer_role >> 1) * T::HALF_B_N +
                 (scale_producer_role & 1) * T::W_N) *
                    kargs.stride_sfb +
                scale_tile * T::NUM_KGROUPS;
            const int consumer_wave_n = scale_producer_role & 1;
            const int half_tile_n = scale_producer_role >> 1;
            raw_dest =
                s_sfb.ptr + write_stage * smem_sfb_elem +
                consumer_wave_n * 2 * T::WARP_SIZE * sizeof(D_SF_PACK) +
                half_tile_n * T::WARP_SIZE * sizeof(D_SF_PACK);
        }
        async_load<4>(
            g_sf, reinterpret_cast<void*>(
                      reinterpret_cast<__UINTPTR_TYPE__>(raw_dest)),
            scale_voffset, scale_soffset, 0_I,
            opus::number<MXFP8_ROW_SCALE_LOAD_AUX>{});
    };

    auto issue_raw_tr_scale = [&](int read_stage,
                                   opus::u32x2_t& raw_sfa,
                                   opus::u32x2_t& raw_sfb) {
        const int tr_lane = lane_id & 15;
        const int row_block = lane_id >> 4;
        const int tr_call = (tr_lane & 7) >> 1;
        const int column_half = tr_lane & 1;
        const int common_offset =
            row_block * 64 + tr_call * 16 + column_half * 8;
        const int sfa_offset =
            read_stage * smem_sfa_elem +
            wave_id_m * T::WARP_SIZE * sizeof(D_SF_PACK) +
            common_offset;
        const int half_tile_n = tr_lane >> 3;
        const int sfb_offset =
            read_stage * smem_sfb_elem +
            wave_id_n * 2 * T::WARP_SIZE * sizeof(D_SF_PACK) +
            half_tile_n * T::WARP_SIZE * sizeof(D_SF_PACK) +
            common_offset;
        const opus::u32_t sfa_addr = static_cast<opus::u32_t>(
            reinterpret_cast<__UINTPTR_TYPE__>(s_sfa.ptr + sfa_offset));
        const opus::u32_t sfb_addr = static_cast<opus::u32_t>(
            reinterpret_cast<__UINTPTR_TYPE__>(s_sfb.ptr + sfb_offset));
        asm volatile(
            "ds_read_b64_tr_b8 %0, %2\n"
            "ds_read_b64_tr_b8 %1, %3\n"
            : "=v"(raw_sfa), "=v"(raw_sfb)
            : "v"(sfa_addr), "v"(sfb_addr)
            : "memory");
    };

    auto route_raw_tr_scale = [&](opus::u32x2_t& raw_sfa,
                                   opus::u32x2_t& raw_sfb,
                                   D_SF_PACK& out_sfa,
                                   D_SF_PACK& out_sfb0,
                                   D_SF_PACK& out_sfb1) {
        asm volatile(
            "s_waitcnt lgkmcnt(0)\n"
            : "+v"(raw_sfa), "+v"(raw_sfb)
            :
            : "memory");
        const int source_lane = ((lane_id << 2) | (lane_id >> 4)) & 63;
        const int route_addr = source_lane << 2;
        out_sfa = static_cast<D_SF_PACK>(__builtin_amdgcn_ds_bpermute(
            route_addr, static_cast<int>(raw_sfa[0])));
        out_sfb0 = static_cast<D_SF_PACK>(__builtin_amdgcn_ds_bpermute(
            route_addr, static_cast<int>(raw_sfb[0])));
        out_sfb1 = static_cast<D_SF_PACK>(__builtin_amdgcn_ds_bpermute(
            route_addr, static_cast<int>(raw_sfb[1])));
    };

    auto wait_raw_tr_scale = [&](D_SF_PACK& out_sfa,
                                  D_SF_PACK& out_sfb0,
                                  D_SF_PACK& out_sfb1) {
        asm volatile(
            "s_waitcnt lgkmcnt(0)\n"
            : "+v"(out_sfa), "+v"(out_sfb0), "+v"(out_sfb1)
            :
            : "memory");
    };

    auto load_raw_tr_scale = [&](int read_stage,
                                  D_SF_PACK& out_sfa,
                                  D_SF_PACK& out_sfb0,
                                  D_SF_PACK& out_sfb1) {
        opus::u32x2_t raw_sfa;
        opus::u32x2_t raw_sfb;
        issue_raw_tr_scale(read_stage, raw_sfa, raw_sfb);
        route_raw_tr_scale(
            raw_sfa, raw_sfb, out_sfa, out_sfb0, out_sfb1);
        wait_raw_tr_scale(out_sfa, out_sfb0, out_sfb1);
    };

#elif MXFP8_ROW_SCALE_TR_READ == 1
    auto async_load_raw_scale_group = [&](int output_tile_index,
                                          int group_base_tile) {
        // TR_B8 emits lanes in [even rows][odd rows] order.  Loading rows in
        // the inverse order makes the second transpose land directly in the
        // physical MFMA scale lane, with no VALU lane permutation.
        const int scale_r = lane_id & 15;
        const int permuted_r = (scale_r >> 1) + ((scale_r & 1) << 3);
        int scale_voffset;
        int scale_soffset;
        if (scale_producer_is_sfa) {
            const int lane_row =
                (lane_id >> 4) * (T::T_M * T::W_M) + permuted_r;
            scale_voffset = lane_row * kargs.stride_sfa;
            scale_soffset =
                (output_tile_index * T::B_M +
                 scale_producer_role * T::W_M) *
                    kargs.stride_sfa +
                group_base_tile * T::NUM_KGROUPS;
        } else {
            const int lane_row =
                (lane_id >> 4) * (T::T_N * T::W_N) + permuted_r;
            scale_voffset = lane_row * kargs.stride_sfb;
            scale_soffset =
                ((scale_producer_role >> 1) * T::HALF_B_N +
                 (scale_producer_role & 1) * T::W_N) *
                    kargs.stride_sfb +
                group_base_tile * T::NUM_KGROUPS;
        }
        async_load<16>(
            g_sf,
            reinterpret_cast<void*>(reinterpret_cast<__UINTPTR_TYPE__>(
                s_sf_raw.ptr + wave_id * raw_scale_wave_elem +
                lane_id * raw_scale_lane_elem)),
            scale_voffset, scale_soffset);
    };

    auto read_raw_scale_pair = [&](int pair_slot) {
        const opus::u32_t raw_addr = static_cast<opus::u32_t>(
            reinterpret_cast<__UINTPTR_TYPE__>(
                s_sf_raw.ptr + wave_id * raw_scale_wave_elem +
                lane_id * raw_scale_lane_elem + pair_slot * 8));
        opus::u32x2_t first_transpose;
        asm volatile(
            "ds_read_b64_tr_b8 %0, %1\n"
            : "=v"(first_transpose)
            : "v"(raw_addr)
            : "memory");
        return first_transpose;
    };

    auto store_first_transposed_scale_pair = [&](int pair_slot,
                                                  opus::u32x2_t first_transpose) {
        // After the first transpose, each lane owns one (tile, K-group)
        // column and eight even/odd rows.  Store that vector as a source row
        // for the consumer's second transpose.
        const int call = lane_id >> 4;
        const int parity = (lane_id & 15) >> 3;
        const int column = lane_id & 7;
        const int tile_in_pair = column >> 2;
        const int kgroup = column & 3;
        const int packed_call = tile_in_pair * 4 + call;
        const int second_source_lane = 2 * packed_call + parity;
        auto* store_ptr = scale_producer_is_sfa ? s_sfa.ptr : s_sfb.ptr;
        const int store_offset =
            pair_slot * (T::NUM_WAVES / T::T_N) * 512 +
            wave_id_m * 512 + kgroup * 128 + second_source_lane * 8;
        const opus::u32_t store_addr = static_cast<opus::u32_t>(
            reinterpret_cast<__UINTPTR_TYPE__>(store_ptr + store_offset));
        asm volatile(
            "ds_write_b64 %0, %1\n"
            :: "v"(store_addr), "v"(first_transpose)
            : "memory");
    };

    auto publish_raw_scale_pair = [&](int pair_slot) {
        s_waitcnt_vmcnt(0_I);
        const auto first_transpose = read_raw_scale_pair(pair_slot);
        s_waitcnt_lgkmcnt(0_I);
        store_first_transposed_scale_pair(pair_slot, first_transpose);
    };

#elif MXFP8_ROW_SCALE_TR_READ == 2
    auto load_scale_tr_group = [&](int output_tile_index,
                                   int group_base_tile) {
        // Inverse of TR_B8's [even rows][odd rows] destination ordering.
        const int scale_r = lane_id & 15;
        const int permuted_r = (scale_r >> 1) + ((scale_r & 1) << 3);
        int scale_voffset;
        int scale_soffset;
        if (scale_producer_is_sfa) {
            const int lane_row =
                (lane_id >> 4) * (T::T_M * T::W_M) + permuted_r;
            scale_voffset = lane_row * kargs.stride_sfa;
            scale_soffset =
                (output_tile_index * T::B_M +
                 scale_producer_role * T::W_M) *
                    kargs.stride_sfa +
                group_base_tile * T::NUM_KGROUPS;
        } else {
            const int lane_row =
                (lane_id >> 4) * (T::T_N * T::W_N) + permuted_r;
            scale_voffset = lane_row * kargs.stride_sfb;
            scale_soffset =
                ((scale_producer_role >> 1) * T::HALF_B_N +
                 (scale_producer_role & 1) * T::W_N) *
                    kargs.stride_sfb +
                group_base_tile * T::NUM_KGROUPS;
        }
        return __builtin_bit_cast(
            opus::u32x4_t,
            load<16>(g_sf, scale_voffset, scale_soffset,
                     opus::number<MXFP8_ROW_SCALE_LOAD_AUX>{}));
    };

    auto refill_scale_tr_group = [&](int output_tile_index,
                                     int group_base_tile) {
        v_scale_tr_queue =
            load_scale_tr_group(output_tile_index, group_base_tile);
    };

    auto publish_scale_tr_pair = [&](int pair_slot,
                                     D_SF_PACK raw0,
                                     D_SF_PACK raw1) {
        auto* scale_ptr = scale_producer_is_sfa ? s_sfa.ptr : s_sfb.ptr;
        const int role_base =
            pair_slot * (T::NUM_WAVES / T::T_N) * 512 +
            wave_id_m * 512;
        const opus::u32_t raw_addr = static_cast<opus::u32_t>(
            reinterpret_cast<__UINTPTR_TYPE__>(
                scale_ptr + role_base + lane_id * 8));
        opus::u32x2_t raw_pair;
        raw_pair[0] = raw0;
        raw_pair[1] = raw1;
        s_waitcnt_vmcnt(0_I);
        asm volatile(
            "ds_write_b64 %0, %1\n"
            :: "v"(raw_addr), "v"(raw_pair)
            : "memory");
        s_waitcnt_lgkmcnt(0_I);

        opus::u32x2_t first_transpose;
        asm volatile(
            "ds_read_b64_tr_b8 %0, %1\n"
            : "=v"(first_transpose)
            : "v"(raw_addr)
            : "memory");
        s_waitcnt_lgkmcnt(0_I);

        const int call = lane_id >> 4;
        const int parity = (lane_id & 15) >> 3;
        const int column = lane_id & 7;
        const int tile_in_pair = column >> 2;
        const int kgroup = column & 3;
        const int packed_call = tile_in_pair * 4 + call;
        const int second_source_lane = 2 * packed_call + parity;
        const int store_offset =
            role_base + kgroup * 128 + second_source_lane * 8;
        const opus::u32_t store_addr = static_cast<opus::u32_t>(
            reinterpret_cast<__UINTPTR_TYPE__>(scale_ptr + store_offset));
        asm volatile(
            "ds_write_b64 %0, %1\n"
            :: "v"(store_addr), "v"(first_transpose)
            : "memory");
    };
#endif

#if MXFP8_ROW_SCALE_TR_READ
    auto load_transposed_scale_pair = [&](auto& smem,
                                          int pair_slot,
                                          int producer_role) {
        const int kgroup = lane_id >> 4;
        const int source_lane = lane_id & 15;
        const int load_offset =
            pair_slot * (T::NUM_WAVES / T::T_N) * 512 +
            producer_role * 512 + kgroup * 128 + source_lane * 8;
        const opus::u32_t addr = static_cast<opus::u32_t>(
            reinterpret_cast<__UINTPTR_TYPE__>(smem.ptr + load_offset));
        opus::u32x2_t result;
        asm volatile(
            "ds_read_b64_tr_b8 %0, %1\n"
            : "=v"(result)
            : "v"(addr)
            : "memory");
        return result;
    };
#endif
#if !MXFP8_ROW_SCALE_TR_READ && !MXFP8_ROW_SCALE_RAW_TR_BPERMUTE
    auto load_scale_group = [&](int output_tile_index, int group_base_tile) {
        // Audit marker for the ordinary vector path:
        // load<16>(g_sf, scale_voffset, scale_soffset)
        int scale_voffset;
        int scale_soffset;
        if (scale_producer_is_sfa) {
            const int lane_row =
                (lane_id >> 4) * (T::T_M * T::W_M) + (lane_id & 15);
            scale_voffset = lane_row * kargs.stride_sfa;
            scale_soffset =
                (output_tile_index * T::B_M +
                 scale_producer_role * T::W_M) *
                    kargs.stride_sfa +
                group_base_tile * T::NUM_KGROUPS;
        } else {
            const int lane_row =
                (lane_id >> 4) * (T::T_N * T::W_N) + (lane_id & 15);
            scale_voffset = lane_row * kargs.stride_sfb;
            scale_soffset =
                ((scale_producer_role >> 1) * T::HALF_B_N +
                 (scale_producer_role & 1) * T::W_N) *
                    kargs.stride_sfb +
                group_base_tile * T::NUM_KGROUPS;
        }
        return __builtin_bit_cast(
            opus::u32x4_t,
             load<16>(g_sf, scale_voffset, scale_soffset,
                     opus::number<MXFP8_ROW_SCALE_LOAD_AUX>{}));
    };

#if MXFP8_ROW_SCALE_QUEUE6_RAWTAIL
    auto scale_pair_offsets = [&](int output_tile_index,
                                  int pair_base_tile) {
        opus::i32x2_t offsets;
        if (scale_producer_is_sfa) {
            const int lane_row =
                (lane_id >> 4) * (T::T_M * T::W_M) + (lane_id & 15);
            offsets[0] = lane_row * kargs.stride_sfa;
            offsets[1] =
                (output_tile_index * T::B_M +
                 scale_producer_role * T::W_M) *
                    kargs.stride_sfa +
                pair_base_tile * T::NUM_KGROUPS;
        } else {
            const int lane_row =
                (lane_id >> 4) * (T::T_N * T::W_N) + (lane_id & 15);
            offsets[0] = lane_row * kargs.stride_sfb;
            offsets[1] =
                ((scale_producer_role >> 1) * T::HALF_B_N +
                 (scale_producer_role & 1) * T::W_N) *
                    kargs.stride_sfb +
                pair_base_tile * T::NUM_KGROUPS;
        }
        return offsets;
    };

    auto load_scale_pair = [&](int output_tile_index, int pair_base_tile) {
        const auto offsets =
            scale_pair_offsets(output_tile_index, pair_base_tile);
        return __builtin_bit_cast(
            opus::u32x2_t,
            load<8>(g_sf, offsets[0], offsets[1],
                    opus::number<MXFP8_ROW_SCALE_LOAD_AUX>{}));
    };

    auto async_load_scale_tail = [&](int output_tile_index,
                                     int pair_base_tile) {
        const auto offsets =
            scale_pair_offsets(output_tile_index, pair_base_tile);
        async_load<8>(
            g_sf,
            reinterpret_cast<void*>(reinterpret_cast<__UINTPTR_TYPE__>(
                s_sf_queue6_tail.ptr + wave_id * scale_tail_wave_elem +
                lane_id * scale_tail_lane_elem)),
            offsets[0], offsets[1], 0_I,
            opus::number<MXFP8_ROW_SCALE_LOAD_AUX>{});
    };

    auto load_scale_tail = [&]() {
        return __builtin_bit_cast(
            opus::u32x2_t,
            load<8>(
                s_sf_queue6_tail,
                wave_id * scale_tail_wave_elem +
                    lane_id * scale_tail_lane_elem));
    };
#endif

    auto publish_scale_phase_pair = [&](int first_write_stage,
                                         D_SF_PACK raw0,
                                         D_SF_PACK raw1) {
        const auto rows01 = __builtin_amdgcn_permlane16_swap(
            raw0, raw1, false, true);
        const D_SF_PACK calls_even = __builtin_amdgcn_perm(
            rows01[1], rows01[0], 0x06020400u);
        const D_SF_PACK calls_odd = __builtin_amdgcn_perm(
            rows01[1], rows01[0], 0x07030501u);
        const auto rows0123 = __builtin_amdgcn_permlane32_swap(
            calls_even, calls_odd, false, true);
        const D_SF_PACK calls01 = __builtin_amdgcn_perm(
            rows0123[1], rows0123[0], 0x05040100u);
        const D_SF_PACK calls23 = __builtin_amdgcn_perm(
            rows0123[1], rows0123[0], 0x07060302u);

        const int scale_r = lane_id & 15;
        const int physical_call = lane_id >> 4;
        const int logical_call = physical_call >> 1;
        auto* store_ptr = scale_producer_is_sfa ? s_sfa.ptr : s_sfb.ptr;
#if MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE >= 3
        const int tile_parity = physical_call & 1;
        const int pair_slot = first_write_stage >> 1;
        const int store_base =
            pair_slot * 2 * smem_sfa_elem +
            ((((scale_producer_role * T::W_M + scale_r) *
                   T::SCALE_KGROUPS_PER_MFMA +
               logical_call) *
                  2 +
              tile_parity) *
             sizeof(D_SF_PACK));
        const opus::u32_t addr = static_cast<opus::u32_t>(
            reinterpret_cast<__UINTPTR_TYPE__>(store_ptr + store_base));
        asm volatile(
            "ds_write2_b32 %0, %1, %2 offset0:0 offset1:4\n"
            :: "v"(addr), "v"(calls01), "v"(calls23)
            : "memory");
#else
        const int write_stage = first_write_stage ^ (physical_call & 1);
        const int store_base =
            write_stage * smem_sfa_elem +
            (((scale_producer_role * T::W_M + scale_r) *
                  T::SCALE_KGROUPS_PER_MFMA +
              logical_call) *
             T::SCALE_M_CALLS);
        const opus::u32_t addr = static_cast<opus::u32_t>(
            reinterpret_cast<__UINTPTR_TYPE__>(store_ptr + store_base));
        asm volatile(
            "ds_write2_b32 %0, %1, %2 offset0:0 offset1:2\n"
            :: "v"(addr), "v"(calls01), "v"(calls23)
            : "memory");
#endif
#if MXFP8_ROW_SCALE_LOCAL_REUSE
        // The six-instruction pair transpose is laid out for two LDS write
        // stages.  These two register-only swaps turn it into the ordinary
        // consumer layout: element 0 is the even tile and element 1 is the
        // odd tile, with each lane owning its native K-group dword.
        const auto local_k01_k23 = __builtin_amdgcn_permlane32_swap(
            calls01, calls23, false, true);
        return __builtin_amdgcn_permlane16_swap(
            local_k01_k23[0], local_k01_k23[1], false, true);
#endif
    };

#if MXFP8_ROW_SCALE_PAIR_PREPARE_POSITION
    auto prepare_scale_phase_pair = [&](D_SF_PACK raw0,
                                        D_SF_PACK raw1) {
        const auto rows01 = __builtin_amdgcn_permlane16_swap(
            raw0, raw1, false, true);
        opus::u32x2_t prepared;
        prepared[0] = __builtin_amdgcn_perm(
            rows01[1], rows01[0], 0x06020400u);
        prepared[1] = __builtin_amdgcn_perm(
            rows01[1], rows01[0], 0x07030501u);
        return prepared;
    };

    auto publish_prepared_scale_phase_pair = [&] (
        int first_write_stage, const opus::u32x2_t& prepared) {
        const auto rows0123 = __builtin_amdgcn_permlane32_swap(
            prepared[0], prepared[1], false, true);
        const D_SF_PACK calls01 = __builtin_amdgcn_perm(
            rows0123[1], rows0123[0], 0x05040100u);
        const D_SF_PACK calls23 = __builtin_amdgcn_perm(
            rows0123[1], rows0123[0], 0x07060302u);

        const int scale_r = lane_id & 15;
        const int physical_call = lane_id >> 4;
        const int logical_call = physical_call >> 1;
        const int write_stage = first_write_stage ^ (physical_call & 1);
        const int store_base =
            write_stage * smem_sfa_elem +
            (((scale_producer_role * T::W_M + scale_r) *
                  T::SCALE_KGROUPS_PER_MFMA +
              logical_call) *
             T::SCALE_M_CALLS);
        auto* store_ptr = scale_producer_is_sfa ? s_sfa.ptr : s_sfb.ptr;
        const opus::u32_t addr = static_cast<opus::u32_t>(
            reinterpret_cast<__UINTPTR_TYPE__>(store_ptr + store_base));
        asm volatile(
            "ds_write2_b32 %0, %1, %2 offset0:0 offset1:2\n"
            :: "v"(addr), "v"(calls01), "v"(calls23)
            : "memory");
    };
#endif

#if MXFP8_ROW_SCALE_GROUP4_PUBLICATION
    auto publish_scale_group4 = [&](const opus::u32x4_t& raw) {
        // Run the two independent pair transposes in lockstep.  This gives
        // the scheduler independent work across each lane-permute latency
        // and produces the four dwords needed by one B128 LDS write.
        const auto rows01_lo = __builtin_amdgcn_permlane16_swap(
            raw[0], raw[1], false, true);
        const auto rows01_hi = __builtin_amdgcn_permlane16_swap(
            raw[2], raw[3], false, true);

        const D_SF_PACK even_lo = __builtin_amdgcn_perm(
            rows01_lo[1], rows01_lo[0], 0x06020400u);
        const D_SF_PACK odd_lo = __builtin_amdgcn_perm(
            rows01_lo[1], rows01_lo[0], 0x07030501u);
        const D_SF_PACK even_hi = __builtin_amdgcn_perm(
            rows01_hi[1], rows01_hi[0], 0x06020400u);
        const D_SF_PACK odd_hi = __builtin_amdgcn_perm(
            rows01_hi[1], rows01_hi[0], 0x07030501u);

        const auto rows0123_lo = __builtin_amdgcn_permlane32_swap(
            even_lo, odd_lo, false, true);
        const auto rows0123_hi = __builtin_amdgcn_permlane32_swap(
            even_hi, odd_hi, false, true);

        opus::u32x4_t cooked;
        cooked[0] = __builtin_amdgcn_perm(
            rows0123_lo[1], rows0123_lo[0], 0x05040100u);
        cooked[1] = __builtin_amdgcn_perm(
            rows0123_lo[1], rows0123_lo[0], 0x07060302u);
        cooked[2] = __builtin_amdgcn_perm(
            rows0123_hi[1], rows0123_hi[0], 0x05040100u);
        cooked[3] = __builtin_amdgcn_perm(
            rows0123_hi[1], rows0123_hi[0], 0x07060302u);

        const int scale_r = lane_id & 15;
        const int physical_call = lane_id >> 4;
        const int kgroup_low = physical_call >> 1;
        const int stage_low = physical_call & 1;
        const int dword_base =
            ((((scale_producer_role * T::W_M + scale_r) * 2 +
                kgroup_low) *
                   2 +
               stage_low) *
              4);
        auto* store_ptr = scale_producer_is_sfa ? s_sfa.ptr : s_sfb.ptr;
        const opus::u32_t addr = static_cast<opus::u32_t>(
            reinterpret_cast<__UINTPTR_TYPE__>(
                store_ptr + dword_base * sizeof(D_SF_PACK)));
        asm volatile(
            "ds_write_b128 %0, %1\n"
            :: "v"(addr), "v"(cooked)
            : "memory");
    };
#endif

    auto refill_scale_queue = [&](int output_tile_index,
                                  int group_base_tile) {
        const auto loaded =
            load_scale_group(output_tile_index, group_base_tile);
#if MXFP8_ROW_SCALE_SPLIT_QUEUE
        v_scale_queue0 = loaded[0];
        v_scale_queue1 = loaded[1];
        v_scale_queue2 = loaded[2];
        v_scale_queue3 = loaded[3];
#else
        v_scale_queue = loaded;
#endif
    };
    auto publish_scale_queue01 = [&](int first_write_stage) {
#if MXFP8_ROW_SCALE_SPLIT_QUEUE
#if MXFP8_ROW_SCALE_LOCAL_REUSE
        const auto local_pair = publish_scale_phase_pair(
            first_write_stage, v_scale_queue0, v_scale_queue1);
        v_scale_local_even = local_pair[0];
        v_scale_local_odd = local_pair[1];
#else
        publish_scale_phase_pair(
            first_write_stage, v_scale_queue0, v_scale_queue1);
#endif
#else
#if MXFP8_ROW_SCALE_LOCAL_REUSE == 6
        const auto local_pair = publish_scale_phase_pair(
            first_write_stage, v_scale_queue[0], v_scale_queue[1]);
        v_scale_prefetch[0] = local_pair[0];
        v_scale_prefetch[1] = local_pair[1];
#elif MXFP8_ROW_SCALE_LOCAL_REUSE
        const auto local_pair = publish_scale_phase_pair(
            first_write_stage, v_scale_queue[0], v_scale_queue[1]);
        v_scale_local_even = local_pair[0];
        v_scale_local_odd = local_pair[1];
#else
        publish_scale_phase_pair(
            first_write_stage, v_scale_queue[0], v_scale_queue[1]);
#endif
#endif
    };
    auto publish_scale_queue23 = [&](int first_write_stage) {
#if MXFP8_ROW_SCALE_SPLIT_QUEUE
#if MXFP8_ROW_SCALE_LOCAL_REUSE
        const auto local_pair = publish_scale_phase_pair(
            first_write_stage, v_scale_queue2, v_scale_queue3);
        v_scale_local_even = local_pair[0];
        v_scale_local_odd = local_pair[1];
#else
        publish_scale_phase_pair(
            first_write_stage, v_scale_queue2, v_scale_queue3);
#endif
#else
#if MXFP8_ROW_SCALE_LOCAL_REUSE == 6
        const auto local_pair = publish_scale_phase_pair(
            first_write_stage, v_scale_queue[2], v_scale_queue[3]);
        v_scale_queue = v_scale_prefetch;
        v_scale_prefetch[0] = local_pair[0];
        v_scale_prefetch[1] = local_pair[1];
#elif MXFP8_ROW_SCALE_LOCAL_REUSE
        const auto local_pair = publish_scale_phase_pair(
            first_write_stage, v_scale_queue[2], v_scale_queue[3]);
        v_scale_local_even = local_pair[0];
        v_scale_local_odd = local_pair[1];
#else
        publish_scale_phase_pair(
            first_write_stage, v_scale_queue[2], v_scale_queue[3]);
#endif
#endif
    };
#endif
#endif

    const int loops = num_tiles_k;
#if MXFP8_ROW_MAJOR_SCALE
    __builtin_assume((loops & 3) == 0);
#endif
    int stage = first_stage;
#if MXFP8_ROW_MAJOR_SCALE
    int scale_stage = 0;
#else
    int scale_stage = first_stage;
#endif
    int tile = 0;

    if (output_tile == 0) {
#if MXFP8_ROW_MAJOR_SCALE
#if MXFP8_ROW_SCALE_RAW_TR_BPERMUTE
        async_load_raw_tr_scale(output_tile, 0);
        if (loops > 1) async_load_raw_tr_scale(output_tile, 1);
        if (loops > 2) async_load_raw_tr_scale(output_tile, 2);
        if (loops > 3) async_load_raw_tr_scale(output_tile, 3);
#elif MXFP8_ROW_SCALE_TR_READ == 1
        async_load_raw_scale_group(output_tile, 0);
#elif MXFP8_ROW_SCALE_TR_READ == 2
        refill_scale_tr_group(output_tile, 0);
#else
        refill_scale_queue(output_tile, 0);
#if MXFP8_ROW_SCALE_QUEUE8 || MXFP8_ROW_SCALE_PAIRED_REFILL
        if (loops > 4) {
            v_scale_prefetch = load_scale_group(output_tile, 4);
        }
#elif MXFP8_ROW_SCALE_QUEUE6_RAWTAIL
        if (loops > 4) {
            v_scale_prefetch_pair = load_scale_pair(output_tile, 4);
            async_load_scale_tail(output_tile, 6);
        }
#endif
#endif
#else
        if (scale_producer_active) {
            async_load<16>(g_sf, s_sf_ptr, u_gsfa,
                           u_ssfa + ssfa_offset(stage), gsf_offset(0, 0));
        }
#endif
        async_load<T::VEC_A>(g_a, s_a.ptr, u_ga,
                             u_sa + sa_offset(stage, 0), ga_offset(0, 0));
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                             u_sb + sb_offset(stage, 0), gb_offset(0, 0));
        async_load<T::VEC_A>(g_a, s_a.ptr, u_ga,
                             u_sa + sa_offset(stage, 1), ga_offset(1, 0));
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                             u_sb + sb_offset(stage, 1), gb_offset(1, 0));

        s_waitcnt_vmcnt(0_I);
#if MXFP8_ROW_MAJOR_SCALE
#if MXFP8_ROW_SCALE_RAW_TR_BPERMUTE
        // Raw scale data is already in its consumer-visible four-stage ring.
#elif MXFP8_ROW_SCALE_TR_READ == 1
        publish_raw_scale_pair(0);
#elif MXFP8_ROW_SCALE_TR_READ == 2
        publish_scale_tr_pair(
            0, v_scale_tr_queue[0], v_scale_tr_queue[1]);
#elif MXFP8_ROW_SCALE_GROUP4_PUBLICATION
        publish_scale_group4(v_scale_queue);
#else
        publish_scale_queue01(0);
#endif
#endif
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);
    }

#if MXFP8_ROW_MAJOR_SCALE && \
    MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE == 3 && \
    MXFP8_ROW_SCALE_PAIR_DEBUG
    {
        const auto debug_sfa = load_sfa_stage_pair(0);
        const auto debug_sfb = load_sfb_interleaved_pair(0);
        s_waitcnt_lgkmcnt(0_I);
        auto* debug = reinterpret_cast<unsigned int*>(kargs.ptr_c);
        const int debug_lane = wave_id * T::WARP_SIZE + lane_id;
        debug[0 * T::BLOCK_SIZE + debug_lane] = debug_sfa[0];
        debug[1 * T::BLOCK_SIZE + debug_lane] = debug_sfa[1];
        debug[2 * T::BLOCK_SIZE + debug_lane] = debug_sfb[0];
        debug[3 * T::BLOCK_SIZE + debug_lane] = debug_sfb[1];
        debug[4 * T::BLOCK_SIZE + debug_lane] = debug_sfb[2];
        debug[5 * T::BLOCK_SIZE + debug_lane] = debug_sfb[3];
        return;
    }
#endif

    // Seed the rolling pipeline.  The retained path initially launches only
    // cold B.  The experimental tail-producer path launches the complete tile
    // here, then keeps that one-tile lead by distributing all producers across
    // the previous tile's final 12 MFMAs.
#if MXFP8_ISOLATED_SOURCE_CHANGE == 2
    if (loops > 1 && output_tile == 0) {
#else
    if (loops > 1) {
#endif
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                             u_sb + sb_offset(stage ^ 1, 0), gb_offset(0, 1));
        async_load<T::VEC_B>(g_b, s_b.ptr, u_gb,
                             u_sb + sb_offset(stage ^ 1, 1), gb_offset(1, 1));
        __builtin_amdgcn_sched_barrier(0);
    }

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_RAW_TR_BPERMUTE
    load_raw_tr_scale(scale_stage, v_sfa, v_sfb[0], v_sfb[1]);
#endif

    // Main Loop
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_PHASE_UNROLL
    auto run_main_tile = [&](auto next_phase_number) {
        constexpr int next_scale_phase =
            opus::remove_cvref_t<decltype(next_phase_number)>::value;
        constexpr int read_scale_stage = (next_scale_phase + 3) & 3;
#else
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_LOOP_UNROLL == 1
#pragma unroll 1
#elif MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_LOOP_UNROLL == 2
#pragma unroll 2
#else
#pragma unroll 4
#endif
    for (tile = 0; tile + 1 < loops; ++tile) {
#endif
        const int next_stage = stage ^ 1;

        // Keeping the producer branch in a local callable preserves the
        // verified gfx950 control flow and register allocation.
        auto load_next_scale = [&]() {
#if MXFP8_ROW_MAJOR_SCALE
            const int next_scale_tile = tile + 1;
#if MXFP8_ROW_SCALE_RAW_TR_BPERMUTE
            (void)next_scale_tile;
#elif MXFP8_ROW_SCALE_TR_READ == 1
            const int phase = next_scale_tile & 3;
#if MXFP8_ROW_SCALE_TR_EARLY_STORE
            if (phase == 2 && next_scale_tile + 2 < loops) {
                async_load_raw_scale_group(
                    output_tile, next_scale_tile + 2);
            }
#else
            if (phase == 0) {
                s_waitcnt_lgkmcnt(0_I);
                asm volatile(
                    "" : "+v"(v_scale_first_transpose) :: "memory");
                store_first_transposed_scale_pair(
                    0, v_scale_first_transpose);
            } else if (phase == 2) {
                s_waitcnt_lgkmcnt(0_I);
                asm volatile(
                    "" : "+v"(v_scale_first_transpose) :: "memory");
                store_first_transposed_scale_pair(
                    1, v_scale_first_transpose);
                if (next_scale_tile + 2 < loops) {
                    async_load_raw_scale_group(
                        output_tile, next_scale_tile + 2);
                }
            }
#endif
#elif MXFP8_ROW_SCALE_TR_READ == 2
            const int phase = next_scale_tile & 3;
            if (phase == 0) {
                publish_scale_tr_pair(
                    0, v_scale_tr_queue[0], v_scale_tr_queue[1]);
            } else if (phase == 2) {
                publish_scale_tr_pair(
                    1, v_scale_tr_queue[2], v_scale_tr_queue[3]);
                if (next_scale_tile + 2 < loops) {
                    refill_scale_tr_group(
                        output_tile, next_scale_tile + 2);
                }
            }
#elif MXFP8_ROW_SCALE_GROUP4_PUBLICATION
            if ((next_scale_tile & 3) == 0) {
                publish_scale_group4(v_scale_prefetch);
            }
#elif MXFP8_ROW_SCALE_QUEUE6_RAWTAIL
#if MXFP8_ROW_SCALE_PHASE_UNROLL
            if constexpr (next_scale_phase == 0) {
                publish_scale_phase_pair(
                    0, v_scale_queue[0], v_scale_queue[1]);
            } else if constexpr (next_scale_phase == 2) {
                publish_scale_phase_pair(
                    2, v_scale_queue[2], v_scale_queue[3]);
            } else if constexpr (next_scale_phase == 4) {
                publish_scale_phase_pair(
                    0, v_scale_prefetch_pair[0],
                    v_scale_prefetch_pair[1]);
                v_scale_prefetch_pair = load_scale_tail();
            } else if constexpr (next_scale_phase == 6) {
                publish_scale_phase_pair(
                    2, v_scale_prefetch_pair[0],
                    v_scale_prefetch_pair[1]);
                if (next_scale_tile + 2 < loops) {
                    v_scale_queue = load_scale_group(
                        output_tile, next_scale_tile + 2);
                    if (next_scale_tile + 6 < loops) {
                        v_scale_prefetch_pair = load_scale_pair(
                            output_tile, next_scale_tile + 6);
                        async_load_scale_tail(
                            output_tile, next_scale_tile + 8);
                    }
                }
            }
#else
            const int phase8 = next_scale_tile & 7;
            if (phase8 == 0) {
                publish_scale_phase_pair(
                    0, v_scale_queue[0], v_scale_queue[1]);
            } else if (phase8 == 2) {
                publish_scale_phase_pair(
                    2, v_scale_queue[2], v_scale_queue[3]);
            } else if (phase8 == 4) {
                publish_scale_phase_pair(
                    0, v_scale_prefetch_pair[0],
                    v_scale_prefetch_pair[1]);
                v_scale_prefetch_pair = load_scale_tail();
            } else if (phase8 == 6) {
                publish_scale_phase_pair(
                    2, v_scale_prefetch_pair[0],
                    v_scale_prefetch_pair[1]);
                if (next_scale_tile + 2 < loops) {
                    v_scale_queue = load_scale_group(
                        output_tile, next_scale_tile + 2);
                    if (next_scale_tile + 6 < loops) {
                        v_scale_prefetch_pair = load_scale_pair(
                            output_tile, next_scale_tile + 6);
                        async_load_scale_tail(
                            output_tile, next_scale_tile + 8);
                    }
                }
            }
#endif
#elif MXFP8_ROW_SCALE_QUEUE8
            const int phase8 = next_scale_tile & 7;
            if (phase8 == 0) {
                publish_scale_phase_pair(
                    0, v_scale_queue[0], v_scale_queue[1]);
            } else if (phase8 == 2) {
                publish_scale_phase_pair(
                    2, v_scale_queue[2], v_scale_queue[3]);
            } else if (phase8 == 4) {
                publish_scale_phase_pair(
                    0, v_scale_prefetch[0], v_scale_prefetch[1]);
            } else if (phase8 == 6) {
                publish_scale_phase_pair(
                    2, v_scale_prefetch[2], v_scale_prefetch[3]);
                if (next_scale_tile + 2 < loops) {
                    asm volatile(
                        "" : "+v"(v_scale_queue),
                             "+v"(v_scale_prefetch) :: "memory");
                    v_scale_queue = load_scale_group(
                        output_tile, next_scale_tile + 2);
#if !MXFP8_ROW_SCALE_QUEUE8_STAGGER
                    if (next_scale_tile + 6 < loops) {
                        v_scale_prefetch = load_scale_group(
                            output_tile, next_scale_tile + 6);
                    }
#endif
                }
            }
#elif MXFP8_ROW_SCALE_PHASE_UNROLL
            if constexpr (next_scale_phase == 0) {
                publish_scale_queue01(0);
            } else if constexpr (next_scale_phase == 2) {
                publish_scale_queue23(2);
                if (next_scale_tile + 2 < loops) {
#if MXFP8_ROW_SCALE_SPLIT_QUEUE
                    asm volatile(
                        "" : "+v"(v_scale_queue0), "+v"(v_scale_queue1),
                             "+v"(v_scale_queue2), "+v"(v_scale_queue3) ::
                             "memory");
#else
                    asm volatile("" : "+v"(v_scale_queue) :: "memory");
#endif
#if MXFP8_ROW_SCALE_DOUBLE_QUEUE
#if MXFP8_ROW_SCALE_LOCAL_REUSE != 6
                    v_scale_queue = v_scale_prefetch;
#endif
#else
                    refill_scale_queue(output_tile, next_scale_tile + 2);
#endif
                }
            }
#else
            const int phase = next_scale_tile & 3;
            if (phase == 0) {
#if MXFP8_ROW_SCALE_PAIR_PREPARE_POSITION
                publish_prepared_scale_phase_pair(
                    0, v_scale_pair_prepared);
#else
                publish_scale_queue01(0);
#endif
            } else if (phase == 2) {
#if MXFP8_ROW_SCALE_PAIR_PREPARE_POSITION
                publish_prepared_scale_phase_pair(
                    2, v_scale_pair_prepared);
#else
                publish_scale_queue23(2);
#endif
                if (next_scale_tile + 2 < loops) {
#if MXFP8_ROW_SCALE_SPLIT_QUEUE
                    asm volatile(
                        "" : "+v"(v_scale_queue0), "+v"(v_scale_queue1),
                             "+v"(v_scale_queue2), "+v"(v_scale_queue3) ::
                             "memory");
#else
                    asm volatile("" : "+v"(v_scale_queue) :: "memory");
#endif
#if MXFP8_ROW_SCALE_DOUBLE_QUEUE
#if MXFP8_ROW_SCALE_LOCAL_REUSE != 6
#if MXFP8_ROW_SCALE_PAIRED_REFILL
                    if ((next_scale_tile & 7) == 2) {
                        v_scale_queue = v_scale_prefetch;
                    }
#else
                    v_scale_queue = v_scale_prefetch;
#endif
#endif
#else
                    refill_scale_queue(output_tile, next_scale_tile + 2);
#endif
                }
            }
#endif
#else
            if (scale_producer_active) {
                async_load<16>(
                    g_sf, s_sf_ptr, u_gsfa,
                    u_ssfa + ssfa_offset(next_stage),
                    gsf_offset(0, tile + 1));
            }
#endif
        };

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_PAIR_PREPARE_POSITION
        auto prepare_next_scale_pair = [&]() {
            const int next_scale_tile = tile + 1;
            const int phase = next_scale_tile & 3;
            if (phase == 0) {
                v_scale_pair_prepared = prepare_scale_phase_pair(
                    v_scale_queue[0], v_scale_queue[1]);
                asm volatile(
                    "" : "+v"(v_scale_pair_prepared) :: "memory");
            } else if (phase == 2) {
                v_scale_pair_prepared = prepare_scale_phase_pair(
                    v_scale_queue[2], v_scale_queue[3]);
                asm volatile(
                    "" : "+v"(v_scale_pair_prepared) :: "memory");
            }
        };
#endif

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_DOUBLE_QUEUE && \
    !MXFP8_ROW_SCALE_TR_READ && !MXFP8_ROW_SCALE_PAIRED_REFILL
        auto prefetch_next_scale_group = [&]() {
            const int next_scale_tile = tile + 1;
#if MXFP8_ROW_SCALE_PHASE_UNROLL
            if constexpr (next_scale_phase == 2) {
                if (next_scale_tile + 2 < loops) {
                    v_scale_prefetch =
                        load_scale_group(output_tile, next_scale_tile + 2);
                }
            }
#else
            if ((next_scale_tile & 3) == 2 &&
                next_scale_tile + 2 < loops) {
                v_scale_prefetch =
                    load_scale_group(output_tile, next_scale_tile + 2);
            }
#endif
        };
#endif

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_RAW_TR_BPERMUTE
        // Current raw scales were routed during the preceding tile.
#elif MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_TR_READ
        if ((scale_stage & 1) == 0) {
            const int read_pair_slot = scale_stage >> 1;
            v_sfa_tr_pair = load_transposed_scale_pair(
                s_sfa, read_pair_slot, wave_id_m);
            v_sfb_tr_pair0 = load_transposed_scale_pair(
                s_sfb, read_pair_slot, wave_id_n);
            v_sfb_tr_pair1 = load_transposed_scale_pair(
                s_sfb, read_pair_slot, wave_id_n + T::T_N);
        }
#if MXFP8_ROW_SCALE_TR_READ == 1
#if MXFP8_ROW_SCALE_TR_EARLY_STORE == 1
        if (scale_stage == 0) {
            const auto first_transpose = read_raw_scale_pair(1);
            s_waitcnt_lgkmcnt(0_I);
            store_first_transposed_scale_pair(1, first_transpose);
        } else if (scale_stage == 2 && tile + 2 < loops) {
            const auto first_transpose = read_raw_scale_pair(0);
            s_waitcnt_lgkmcnt(0_I);
            store_first_transposed_scale_pair(0, first_transpose);
        }
#elif MXFP8_ROW_SCALE_TR_EARLY_STORE == 0 || \
      MXFP8_ROW_SCALE_TR_EARLY_STORE == 3
        if (scale_stage == 0) {
            v_scale_first_transpose = read_raw_scale_pair(1);
        } else if (scale_stage == 2 && tile + 2 < loops) {
            v_scale_first_transpose = read_raw_scale_pair(0);
        }
#if MXFP8_ROW_SCALE_TR_EARLY_STORE == 0
        s_waitcnt_lgkmcnt(0_I);
        asm volatile(
            "" : "+v"(v_scale_first_transpose), "+v"(v_sfa_tr_pair),
                 "+v"(v_sfb_tr_pair0), "+v"(v_sfb_tr_pair1) ::
            "memory");
#endif
#endif
#endif
#elif MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_PHASE_UNROLL
        v_sfa = __builtin_bit_cast(
            D_SF_PACK,
            load<4>(s_sfa, u_rsfa + ssfa_offset(read_scale_stage)));
        const auto v_sfb_pair = load_sfb_pair(read_scale_stage);
#elif MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_GROUP4_PUBLICATION
        v_sfa = load_group4_sfa(scale_stage);
        const auto v_sfb_pair = load_sfb_pair(scale_stage);
#elif MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_LOCAL_REUSE == 6
        if (scale_producer_is_sfa) {
            v_sfa = (scale_stage & 1)
                ? v_scale_prefetch[1]
                : v_scale_prefetch[0];
        } else {
            v_sfa = __builtin_bit_cast(
                D_SF_PACK,
                load<4>(s_sfa, u_rsfa + ssfa_offset(scale_stage)));
        }
        const auto v_sfb_pair = load_sfb_pair(scale_stage);
#elif MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_LOCAL_REUSE == 2
        const D_SF_PACK v_scale_local = (scale_stage & 1)
            ? v_scale_local_odd
            : v_scale_local_even;
        opus::u32x2_t v_scale_remote_pair;
        if (scale_producer_is_sfa) {
            v_scale_remote_pair = load_sfb_pair(scale_stage);
        } else {
            v_scale_remote_pair =
                load_sfa_remote_sfb_pair(scale_stage);
        }
#elif MXFP8_ROW_MAJOR_SCALE && \
      (MXFP8_ROW_SCALE_LOCAL_REUSE == 1 || \
       MXFP8_ROW_SCALE_LOCAL_REUSE == 4)
        if (scale_producer_is_sfa) {
            v_sfa = (scale_stage & 1)
                ? v_scale_local_odd
                : v_scale_local_even;
        } else {
            v_sfa = __builtin_bit_cast(
                D_SF_PACK,
                load<4>(s_sfa, u_rsfa + ssfa_offset(scale_stage)));
        }
        const auto v_sfb_pair = load_sfb_pair(scale_stage);
#elif MXFP8_ROW_MAJOR_SCALE && \
      MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE == 5
        {
            const int tile_parity = scale_stage & 1;
            const auto v_sfa_pair =
                load_sfa_stage_pair(scale_stage & ~1);
            const auto v_sfb_pair =
                load_sfb_interleaved_pair(scale_stage & ~1);
            v_sfa = v_sfa_pair[tile_parity];
            v_sfb[0] = v_sfb_pair[tile_parity];
            v_sfb[1] = v_sfb_pair[2 + tile_parity];
        }
#elif MXFP8_ROW_MAJOR_SCALE && \
      MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE == 4
        v_sfa = load_sfa_interleaved_stage(scale_stage);
        const auto v_sfb_pair =
            load_sfb_interleaved_stage(scale_stage);
        v_sfb[0] = v_sfb_pair[0];
        v_sfb[1] = v_sfb_pair[1];
#elif MXFP8_ROW_MAJOR_SCALE && \
      MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE == 3
        if ((scale_stage & 1) == 0) {
            // Issue the wide pair reads after the A/B LDS reads below.  On
            // gfx950, allowing more LDS reads to pass an outstanding B64
            // pair read can corrupt a component even if a later waitcnt(0)
            // is present.
        } else {
            v_sfa = v_sfa_consumer_pair[1];
            v_sfb[0] = v_sfb_consumer_odd[0];
            v_sfb[1] = v_sfb_consumer_odd[1];
        }
#elif MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE
        if ((scale_stage & 1) == 0) {
            v_sfa_consumer_pair = load_sfa_stage_pair(scale_stage);
#if MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE == 2
            v_sfb_consumer_even = load_sfb_pair(scale_stage);
            v_sfb_consumer_odd = load_sfb_pair(scale_stage ^ 1);
            v_sfb[0] = v_sfb_consumer_even[0];
            v_sfb[1] = v_sfb_consumer_even[1];
#else
            const auto v_sfb_pair = load_sfb_pair(scale_stage);
            v_sfb[0] = v_sfb_pair[0];
            v_sfb[1] = v_sfb_pair[1];
#endif
            v_sfa = v_sfa_consumer_pair[0];
        } else {
            v_sfa = v_sfa_consumer_pair[1];
#if MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE == 2
            v_sfb[0] = v_sfb_consumer_odd[0];
            v_sfb[1] = v_sfb_consumer_odd[1];
#else
            const auto v_sfb_pair = load_sfb_pair(scale_stage);
            v_sfb[0] = v_sfb_pair[0];
            v_sfb[1] = v_sfb_pair[1];
#endif
        }
#else
        v_sfa = __builtin_bit_cast(D_SF_PACK, load<4>(s_sfa, u_rsfa + ssfa_offset(scale_stage)));
        const auto v_sfb_pair = load_sfb_pair(scale_stage);
#endif
#if (!MXFP8_ROW_MAJOR_SCALE || \
     (!MXFP8_ROW_SCALE_TR_READ && !MXFP8_ROW_SCALE_RAW_TR_BPERMUTE)) && \
    MXFP8_ROW_SCALE_LOCAL_REUSE != 2 && \
    !MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE
        v_sfb[0] = v_sfb_pair[0];
        v_sfb[1] = v_sfb_pair[1];
#endif
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_LOCAL_DEBUG
        if (tile + 1 == MXFP8_ROW_SCALE_LOCAL_DEBUG && output_tile == 0 &&
            block_id_x() == 0 &&
            block_id_z() == 0) {
            auto* debug = reinterpret_cast<unsigned int*>(kargs.ptr_c);
            const int debug_lane = wave_id * T::WARP_SIZE + lane_id;
            const D_SF_PACK local = (scale_stage & 1)
                ? v_scale_local_odd
                : v_scale_local_even;
            debug[debug_lane] = local;
            debug[T::BLOCK_SIZE + debug_lane] =
                v_sfb_pair[scale_producer_role >> 1];
            debug[2 * T::BLOCK_SIZE + debug_lane] =
                static_cast<unsigned int>(scale_producer_role);
            return;
        }
#endif
        v_a[0] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 0));
        __builtin_amdgcn_sched_barrier(0);

        v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 0));
        auto rb1_offsets_prefetch = opus::layout_to_offsets<T::VEC_B>(u_rb + sb_offset(stage, 1));
        load_b_range_scale<T, 0, T::b_ds_read_insts / 2>(
            s_b, rb1_offsets_prefetch, v_b_second);
        __builtin_amdgcn_sched_barrier(0);

#if !MXFP8_ROW_MAJOR_SCALE
        load_next_scale();
#endif
        async_load<T::VEC_A>(g_a, s_a.ptr, u_ga, u_sa + sa_offset(next_stage, 0), ga_offset(0, tile + 1), 0_I, opus::number<0>{});
        async_load<T::VEC_A>(g_a, s_a.ptr, u_ga, u_sa + sa_offset(next_stage, 1), ga_offset(1, tile + 1), 0_I, opus::number<0>{});
        __builtin_amdgcn_sched_barrier(0);

#if MXFP8_ROW_MAJOR_SCALE && \
    MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE == 3
        if ((scale_stage & 1) == 0) {
            v_sfa_consumer_pair = load_sfa_stage_pair(scale_stage);
            const auto v_sfb_consumer_pair =
                load_sfb_interleaved_pair(scale_stage);
            v_sfb_consumer_even[0] = v_sfb_consumer_pair[0];
            v_sfb_consumer_odd[0] = v_sfb_consumer_pair[1];
            v_sfb_consumer_even[1] = v_sfb_consumer_pair[2];
            v_sfb_consumer_odd[1] = v_sfb_consumer_pair[3];
            asm volatile(
                "s_waitcnt lgkmcnt(0)\n"
                : "+v"(v_sfa_consumer_pair),
                  "+v"(v_sfb_consumer_even),
                  "+v"(v_sfb_consumer_odd)
                :
                : "memory");
            v_sfa = v_sfa_consumer_pair[0];
            v_sfb[0] = v_sfb_consumer_even[0];
            v_sfb[1] = v_sfb_consumer_even[1];
        }
#endif
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_TR_READ == 1 && \
    MXFP8_ROW_SCALE_TR_EARLY_STORE == 3
        if (scale_stage == 0) {
            s_waitcnt_lgkmcnt(
                opus::number<MXFP8_ROW_SCALE_TR_INTERLEAVE_WAIT>{});
            store_first_transposed_scale_pair(
                1, v_scale_first_transpose);
        } else if (scale_stage == 2 && tile + 2 < loops) {
            s_waitcnt_lgkmcnt(
                opus::number<MXFP8_ROW_SCALE_TR_INTERLEAVE_WAIT>{});
            store_first_transposed_scale_pair(
                0, v_scale_first_transpose);
        }
#endif
        s_waitcnt_lgkmcnt(opus::number<8>{});
#if MXFP8_ROW_MAJOR_SCALE && \
    MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE == 3 && \
    MXFP8_ROW_SCALE_PAIR_DEBUG
        s_waitcnt_lgkmcnt(0_I);
        if (tile == 0 && output_tile == 0 && block_id_x() == 0 &&
            block_id_z() == 0) {
            auto* debug = reinterpret_cast<unsigned int*>(kargs.ptr_c);
            const int debug_lane = wave_id * T::WARP_SIZE + lane_id;
            debug[debug_lane] = v_sfa;
            debug[T::BLOCK_SIZE + debug_lane] = v_sfb[0];
            debug[2 * T::BLOCK_SIZE + debug_lane] = v_sfb[1];
            return;
        }
#endif
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_LOCAL_REUSE == 2
        if (scale_producer_is_sfa) {
            v_sfa = v_scale_local;
            v_sfb[0] = v_scale_remote_pair[0];
            v_sfb[1] = v_scale_remote_pair[1];
        } else {
            v_sfa = v_scale_remote_pair[0];
            const bool local_is_half1 = (scale_producer_role >> 1) != 0;
            v_sfb[0] = local_is_half1
                ? v_scale_remote_pair[1]
                : v_scale_local;
            v_sfb[1] = local_is_half1
                ? v_scale_local
                : v_scale_remote_pair[1];
        }
#elif MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_LOCAL_REUSE == 5
        if (!scale_producer_is_sfa) {
            const D_SF_PACK v_scale_local = (scale_stage & 1)
                ? v_scale_local_odd
                : v_scale_local_even;
            if ((scale_producer_role >> 1) != 0)
                v_sfb[1] = v_scale_local;
            else
                v_sfb[0] = v_scale_local;
        }
#endif
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_TR_READ
        const int read_tile_in_pair = scale_stage & 1;
        v_sfa = v_sfa_tr_pair[read_tile_in_pair];
        v_sfb[0] = v_sfb_tr_pair0[read_tile_in_pair];
        v_sfb[1] = v_sfb_tr_pair1[read_tile_in_pair];
#endif

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_TR_READ == 1 && \
    MXFP8_ROW_SCALE_TR_EARLY_STORE == 2
        auto issue_deferred_scale_transpose = [&]() {
            if (scale_stage == 0) {
                v_scale_first_transpose = read_raw_scale_pair(1);
            } else if (scale_stage == 2 && tile + 2 < loops) {
                v_scale_first_transpose = read_raw_scale_pair(0);
            }
        };
        auto store_deferred_scale_transpose = [&]() {
            if (scale_stage == 0) {
                s_waitcnt_lgkmcnt(0_I);
                store_first_transposed_scale_pair(
                    1, v_scale_first_transpose);
            } else if (scale_stage == 2 && tile + 2 < loops) {
                s_waitcnt_lgkmcnt(0_I);
                store_first_transposed_scale_pair(
                    0, v_scale_first_transpose);
            }
        };
#endif
#if MXFP8_ISOLATED_SOURCE_CHANGE != 1
        __builtin_amdgcn_s_setprio(1);
#endif

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_PAIR_POSITION == 0
        load_next_scale();
#endif

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_DOUBLE_QUEUE && \
    !MXFP8_ROW_SCALE_TR_READ && !MXFP8_ROW_SCALE_PAIRED_REFILL && \
    MXFP8_ROW_SCALE_PREFETCH_POSITION == 0
        prefetch_next_scale_group();
#endif

        // A half 0 x B half 0 -> C[0][0] (64x64).
        mma_scale_repeat_n2<T, 0, 0, 0>(
            mma, v_a[0], v_b, v_c[0][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][0]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale();

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_TR_READ == 1 && \
    MXFP8_ROW_SCALE_TR_EARLY_STORE == 2 && \
    MXFP8_ROW_SCALE_TR_ISSUE_POSITION == 1
        issue_deferred_scale_transpose();
#endif
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_TR_READ == 1 && \
    MXFP8_ROW_SCALE_TR_EARLY_STORE == 2 && \
    MXFP8_ROW_SCALE_TR_STORE_POSITION == 1
        store_deferred_scale_transpose();
#endif

#if MXFP8_ROW_MAJOR_SCALE && \
    MXFP8_ROW_SCALE_PAIR_PREPARE_POSITION == 1
        prepare_next_scale_pair();
#endif

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_PAIR_POSITION == 1
        // Publish the next pair while the first two scaled MFMAs are in flight.
        load_next_scale();
#endif

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_DOUBLE_QUEUE && \
    !MXFP8_ROW_SCALE_TR_READ && !MXFP8_ROW_SCALE_PAIRED_REFILL && \
    MXFP8_ROW_SCALE_PREFETCH_POSITION == 1
        // Keep the row-major VMEM refill early while leaving the six lane
        // permutes at the independently tuned publication position.
        prefetch_next_scale_group();
#endif


        v_a[1] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 1));
        s_waitcnt_lgkmcnt(opus::number<8>{});

        mma_scale_repeat_n2<T, 0, 0, 1>(
            mma, v_a[0], v_b, v_c[0][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][0]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale();

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_TR_READ == 1 && \
    MXFP8_ROW_SCALE_TR_EARLY_STORE == 2 && \
    MXFP8_ROW_SCALE_TR_ISSUE_POSITION == 2
        issue_deferred_scale_transpose();
#endif
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_TR_READ == 1 && \
    MXFP8_ROW_SCALE_TR_EARLY_STORE == 2 && \
    MXFP8_ROW_SCALE_TR_STORE_POSITION == 2
        store_deferred_scale_transpose();
#endif

#if MXFP8_ROW_MAJOR_SCALE && \
    MXFP8_ROW_SCALE_PAIR_PREPARE_POSITION == 2
        prepare_next_scale_pair();
#endif

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_PAIR_POSITION == 2
        load_next_scale();
#endif

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_DOUBLE_QUEUE && \
    !MXFP8_ROW_SCALE_TR_READ && !MXFP8_ROW_SCALE_PAIRED_REFILL && \
    MXFP8_ROW_SCALE_PREFETCH_POSITION == 2
        prefetch_next_scale_group();
#endif

        mma_scale_repeat_n2<T, 0, 1, 0>(
            mma, v_a[0], v_b, v_c[0][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][0]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale();

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_TR_READ == 1 && \
    MXFP8_ROW_SCALE_TR_EARLY_STORE == 2 && \
    MXFP8_ROW_SCALE_TR_ISSUE_POSITION == 3
        issue_deferred_scale_transpose();
#endif
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_TR_READ == 1 && \
    MXFP8_ROW_SCALE_TR_EARLY_STORE == 2 && \
    MXFP8_ROW_SCALE_TR_STORE_POSITION == 3
        store_deferred_scale_transpose();
#endif

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_PAIR_POSITION == 3
        load_next_scale();
#endif

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_DOUBLE_QUEUE && \
    !MXFP8_ROW_SCALE_TR_READ && !MXFP8_ROW_SCALE_PAIRED_REFILL && \
    MXFP8_ROW_SCALE_PREFETCH_POSITION == 3
        prefetch_next_scale_group();
#endif

        mma_scale_repeat_n2<T, 0, 1, 1>(
            mma, v_a[0], v_b, v_c[0][0], v_sfa, v_sfb[0]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][0]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale();

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_TR_READ == 1 && \
    MXFP8_ROW_SCALE_TR_EARLY_STORE == 2 && \
    MXFP8_ROW_SCALE_TR_ISSUE_POSITION == 4
        issue_deferred_scale_transpose();
#endif
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_TR_READ == 1 && \
    MXFP8_ROW_SCALE_TR_EARLY_STORE == 2 && \
    MXFP8_ROW_SCALE_TR_STORE_POSITION == 4
        store_deferred_scale_transpose();
#endif

#if MXFP8_ROW_MAJOR_SCALE && \
    MXFP8_ROW_SCALE_PAIR_PREPARE_POSITION == 4
        prepare_next_scale_pair();
#endif

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_PAIR_POSITION == 4
        load_next_scale();
#endif

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_DOUBLE_QUEUE && \
    !MXFP8_ROW_SCALE_TR_READ && !MXFP8_ROW_SCALE_PAIRED_REFILL && \
    MXFP8_ROW_SCALE_PREFETCH_POSITION == 4
        prefetch_next_scale_group();
#endif

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

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_TR_READ == 1 && \
    MXFP8_ROW_SCALE_TR_EARLY_STORE == 2 && \
    MXFP8_ROW_SCALE_TR_ISSUE_POSITION == 8
        issue_deferred_scale_transpose();
#endif
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_TR_READ == 1 && \
    MXFP8_ROW_SCALE_TR_EARLY_STORE == 2 && \
    MXFP8_ROW_SCALE_TR_STORE_POSITION == 8
        store_deferred_scale_transpose();
#endif

#if MXFP8_ROW_MAJOR_SCALE && \
    MXFP8_ROW_SCALE_PAIR_PREPARE_POSITION == 8
        prepare_next_scale_pair();
#endif

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_PAIR_POSITION == 8
        load_next_scale();
#endif

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_DOUBLE_QUEUE && \
    !MXFP8_ROW_SCALE_TR_READ && !MXFP8_ROW_SCALE_PAIRED_REFILL && \
    MXFP8_ROW_SCALE_PREFETCH_POSITION == 8
        prefetch_next_scale_group();
#endif

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

        mma_scale_repeat_n2<T, 0, 0, 1>(
            mma, v_a[0], v_b_n1, v_c[0][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale();

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_TR_READ == 1 && \
    MXFP8_ROW_SCALE_TR_EARLY_STORE == 2 && \
    MXFP8_ROW_SCALE_TR_ISSUE_POSITION == 10
        issue_deferred_scale_transpose();
#endif
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_TR_READ == 1 && \
    MXFP8_ROW_SCALE_TR_EARLY_STORE == 2 && \
    MXFP8_ROW_SCALE_TR_STORE_POSITION == 10
        store_deferred_scale_transpose();
#endif

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_PAIR_POSITION == 10
        load_next_scale();
#endif


        // All operands for tile t are now resident in VGPRs.  Publish tile
        // t+1 and release tile t's LDS stage with the same barrier, then start
        // the cold B path for tile t+2 while the final 12 MFMAs of tile t run.
#if MXFP8_ISOLATED_SOURCE_CHANGE != 1
        __builtin_amdgcn_s_setprio(0);
#endif
        s_waitcnt_vmcnt(0_I);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_RAW_TR_BPERMUTE
        // Every consumer has finished reading this raw stage.  Refill the
        // freed slot four tiles ahead while the final twelve MFMAs execute.
        if (tile + 4 < loops) {
            async_load_raw_tr_scale(output_tile, tile + 4);
            __builtin_amdgcn_sched_barrier(0);
        }
#endif

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
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_RAW_TR_BPERMUTE
        issue_raw_tr_scale(
            (scale_stage + 1) & 3, v_raw_sfa_next, v_raw_sfb_next);
#endif
#if MXFP8_ISOLATED_SOURCE_CHANGE != 1
        __builtin_amdgcn_s_setprio(1);
#endif

        mma_scale_repeat_n2<T, 0, 1, 0>(
            mma, v_a[0], v_b_n1, v_c[0][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale();


        mma_scale_repeat_n2<T, 0, 1, 1>(
            mma, v_a[0], v_b_n1, v_c[0][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
            asm volatile("" : "+v"(v_c_pin[1]) ::);
        }
        sched_barrier_pairs_scale();

#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_RAW_TR_BPERMUTE
        route_raw_tr_scale(
            v_raw_sfa_next, v_raw_sfb_next,
            v_sfa_next, v_sfb_next[0], v_sfb_next[1]);
#endif

        // A half 1 x B half 1 -> C[1][1] (64x64).
        mma_scale_repeat_n2<T, 1, 0, 0>(
            mma, v_a[1], v_b_n1, v_c[1][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale();


        mma_scale_repeat_n2<T, 1, 0, 1>(
            mma, v_a[1], v_b_n1, v_c[1][1], v_sfa, v_sfb[1]);
        {
            auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[1][1]);
            asm volatile("" : "+v"(v_c_pin[0]) ::);
        }
        sched_barrier_pairs_scale();


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
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_RAW_TR_BPERMUTE
        wait_raw_tr_scale(v_sfa_next, v_sfb_next[0], v_sfb_next[1]);
        v_sfa = v_sfa_next;
        v_sfb[0] = v_sfb_next[0];
        v_sfb[1] = v_sfb_next[1];
#endif
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_QUEUE8 && \
    MXFP8_ROW_SCALE_QUEUE8_STAGGER
        // The old prefetch group is dead after phase-6 publication.  Delay
        // the adjacent second refill until the current tile's MFMAs finish.
        const int stagger_next_scale_tile = tile + 1;
        if ((stagger_next_scale_tile & 7) == 6 &&
            stagger_next_scale_tile + 6 < loops) {
            v_scale_prefetch = load_scale_group(
                output_tile, stagger_next_scale_tile + 6);
        }
#endif
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_PAIRED_REFILL
        // At phase 6 the current four-dword group has just been fully
        // published.  Refill both adjacent groups after the final operand use
        // of this tile, keeping the load result out of the peak MFMA live set.
        const int paired_next_scale_tile = tile + 1;
        if ((paired_next_scale_tile & 7) == 6 &&
            paired_next_scale_tile + 2 < loops) {
            v_scale_queue = load_scale_group(
                output_tile, paired_next_scale_tile + 2);
            if (paired_next_scale_tile + 6 < loops) {
                v_scale_prefetch = load_scale_group(
                    output_tile, paired_next_scale_tile + 6);
            }
        }
#endif
#if MXFP8_ISOLATED_SOURCE_CHANGE != 1
        __builtin_amdgcn_s_setprio(0);
#endif
        stage = next_stage;
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_PHASE_UNROLL
        ++tile;
#elif MXFP8_ROW_MAJOR_SCALE
        scale_stage = (scale_stage + 1) & 3;
#else
        scale_stage = next_stage;
#endif
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_PHASE_UNROLL
    };

#if MXFP8_ROW_SCALE_QUEUE6_RAWTAIL
    for (; tile + 8 < loops;) {
        run_main_tile(opus::number<1>{});
        run_main_tile(opus::number<2>{});
        run_main_tile(opus::number<3>{});
        run_main_tile(opus::number<4>{});
        run_main_tile(opus::number<5>{});
        run_main_tile(opus::number<6>{});
        run_main_tile(opus::number<7>{});
        run_main_tile(opus::number<0>{});
    }
    if (tile + 1 < loops) run_main_tile(opus::number<1>{});
    if (tile + 1 < loops) run_main_tile(opus::number<2>{});
    if (tile + 1 < loops) run_main_tile(opus::number<3>{});
    if (tile + 1 < loops) run_main_tile(opus::number<4>{});
    if (tile + 1 < loops) run_main_tile(opus::number<5>{});
    if (tile + 1 < loops) run_main_tile(opus::number<6>{});
    if (tile + 1 < loops) run_main_tile(opus::number<7>{});
#else
    for (; tile + 4 < loops;) {
        run_main_tile(opus::number<1>{});
        run_main_tile(opus::number<2>{});
        run_main_tile(opus::number<3>{});
        run_main_tile(opus::number<0>{});
    }
    if (tile + 1 < loops) run_main_tile(opus::number<1>{});
    if (tile + 1 < loops) run_main_tile(opus::number<2>{});
    if (tile + 1 < loops) run_main_tile(opus::number<3>{});
#endif
#else
    }
#endif

    // Consume the final resident tile without issuing more global loads.
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_RAW_TR_BPERMUTE
    // The main loop routed the final tile's scales into these registers.
#elif MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_TR_READ
    v_sfa = v_sfa_tr_pair[1];
    v_sfb[0] = v_sfb_tr_pair0[1];
    v_sfb[1] = v_sfb_tr_pair1[1];
#elif MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_PHASE_UNROLL
    v_sfa = __builtin_bit_cast(
        D_SF_PACK, load<4>(s_sfa, u_rsfa + ssfa_offset(3)));
    const auto v_sfb_pair = load_sfb_pair(3);
#elif MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_GROUP4_PUBLICATION
    v_sfa = load_group4_sfa(scale_stage);
    const auto v_sfb_pair = load_sfb_pair(scale_stage);
#elif MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_LOCAL_REUSE == 6
    if (scale_producer_is_sfa) {
        v_sfa = (scale_stage & 1)
            ? v_scale_prefetch[1]
            : v_scale_prefetch[0];
    } else {
        v_sfa = __builtin_bit_cast(
            D_SF_PACK,
            load<4>(s_sfa, u_rsfa + ssfa_offset(scale_stage)));
    }
    const auto v_sfb_pair = load_sfb_pair(scale_stage);
#elif MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_LOCAL_REUSE == 2
    const D_SF_PACK v_scale_local = (scale_stage & 1)
        ? v_scale_local_odd
        : v_scale_local_even;
    opus::u32x2_t v_scale_remote_pair;
    if (scale_producer_is_sfa) {
        v_scale_remote_pair = load_sfb_pair(scale_stage);
    } else {
        v_scale_remote_pair = load_sfa_remote_sfb_pair(scale_stage);
    }
#elif MXFP8_ROW_MAJOR_SCALE && \
      (MXFP8_ROW_SCALE_LOCAL_REUSE == 1 || \
       MXFP8_ROW_SCALE_LOCAL_REUSE == 4)
    if (scale_producer_is_sfa) {
        v_sfa = (scale_stage & 1)
            ? v_scale_local_odd
            : v_scale_local_even;
    } else {
        v_sfa = __builtin_bit_cast(
            D_SF_PACK,
            load<4>(s_sfa, u_rsfa + ssfa_offset(scale_stage)));
        }
        const auto v_sfb_pair = load_sfb_pair(scale_stage);
#elif MXFP8_ROW_MAJOR_SCALE && \
      MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE == 5
    {
        const int tile_parity = scale_stage & 1;
        const auto v_sfa_pair =
            load_sfa_stage_pair(scale_stage & ~1);
            const auto v_sfb_pair =
                load_sfb_interleaved_pair(scale_stage & ~1);
            s_waitcnt_lgkmcnt(0_I);
            v_sfa = v_sfa_pair[tile_parity];
        v_sfb[0] = v_sfb_pair[tile_parity];
        v_sfb[1] = v_sfb_pair[2 + tile_parity];
    }
#elif MXFP8_ROW_MAJOR_SCALE && \
      MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE == 4
    v_sfa = load_sfa_interleaved_stage(scale_stage);
    const auto v_sfb_pair = load_sfb_interleaved_stage(scale_stage);
    v_sfb[0] = v_sfb_pair[0];
    v_sfb[1] = v_sfb_pair[1];
#elif MXFP8_ROW_MAJOR_SCALE && \
      MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE == 3
    v_sfa = v_sfa_consumer_pair[1];
    v_sfb[0] = v_sfb_consumer_odd[0];
    v_sfb[1] = v_sfb_consumer_odd[1];
#elif MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE
    v_sfa = v_sfa_consumer_pair[1];
#if MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE == 2
    v_sfb[0] = v_sfb_consumer_odd[0];
    v_sfb[1] = v_sfb_consumer_odd[1];
#else
    const auto v_sfb_pair = load_sfb_pair(scale_stage);
    v_sfb[0] = v_sfb_pair[0];
    v_sfb[1] = v_sfb_pair[1];
#endif
#else
    v_sfa = __builtin_bit_cast(D_SF_PACK, load<4>(s_sfa, u_rsfa + ssfa_offset(scale_stage)));
    const auto v_sfb_pair = load_sfb_pair(scale_stage);
#endif
#if (!MXFP8_ROW_MAJOR_SCALE || \
     (!MXFP8_ROW_SCALE_TR_READ && !MXFP8_ROW_SCALE_RAW_TR_BPERMUTE)) && \
    MXFP8_ROW_SCALE_LOCAL_REUSE != 2 && \
    !MXFP8_ROW_SCALE_CONSUMER_PAIR_CACHE
    v_sfb[0] = v_sfb_pair[0];
    v_sfb[1] = v_sfb_pair[1];
#endif
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_LOCAL_DEBUG == 4
    if (output_tile == 0 && block_id_x() == 0 && block_id_z() == 0) {
        auto* debug = reinterpret_cast<unsigned int*>(kargs.ptr_c);
        const int debug_lane = wave_id * T::WARP_SIZE + lane_id;
        const D_SF_PACK local = (scale_stage & 1)
            ? v_scale_local_odd
            : v_scale_local_even;
        debug[debug_lane] = local;
        debug[T::BLOCK_SIZE + debug_lane] =
            v_sfb_pair[scale_producer_role >> 1];
        debug[2 * T::BLOCK_SIZE + debug_lane] =
            static_cast<unsigned int>(scale_producer_role);
        return;
    }
#endif
    v_a[0] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 0));
    v_a[1] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 1));
    v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 0));
    s_waitcnt_lgkmcnt(0_I);
#if MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_LOCAL_REUSE == 2
    if (scale_producer_is_sfa) {
        v_sfa = v_scale_local;
        v_sfb[0] = v_scale_remote_pair[0];
        v_sfb[1] = v_scale_remote_pair[1];
    } else {
        v_sfa = v_scale_remote_pair[0];
        const bool local_is_half1 = (scale_producer_role >> 1) != 0;
        v_sfb[0] = local_is_half1
            ? v_scale_remote_pair[1]
            : v_scale_local;
        v_sfb[1] = local_is_half1
            ? v_scale_local
            : v_scale_remote_pair[1];
    }
#elif MXFP8_ROW_MAJOR_SCALE && MXFP8_ROW_SCALE_LOCAL_REUSE == 5
    if (!scale_producer_is_sfa) {
        const D_SF_PACK v_scale_local = (scale_stage & 1)
            ? v_scale_local_odd
            : v_scale_local_even;
        if ((scale_producer_role >> 1) != 0)
            v_sfb[1] = v_scale_local;
        else
            v_sfb[0] = v_scale_local;
    }
#endif

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
#if MXFP8_ROW_MAJOR_SCALE
#if MXFP8_ROW_SCALE_RAW_TR_BPERMUTE
        async_load_raw_tr_scale(output_tile + 1, 0);
        if (loops > 1) async_load_raw_tr_scale(output_tile + 1, 1);
        if (loops > 2) async_load_raw_tr_scale(output_tile + 1, 2);
        if (loops > 3) async_load_raw_tr_scale(output_tile + 1, 3);
#elif MXFP8_ROW_SCALE_TR_READ == 1
        async_load_raw_scale_group(output_tile + 1, 0);
#elif MXFP8_ROW_SCALE_TR_READ == 2
        refill_scale_tr_group(output_tile + 1, 0);
#else
        refill_scale_queue(output_tile + 1, 0);
#if MXFP8_ROW_SCALE_QUEUE8 || MXFP8_ROW_SCALE_PAIRED_REFILL
        if (loops > 4) {
            v_scale_prefetch = load_scale_group(output_tile + 1, 4);
        }
#elif MXFP8_ROW_SCALE_QUEUE6_RAWTAIL
        if (loops > 4) {
            v_scale_prefetch_pair = load_scale_pair(output_tile + 1, 4);
            async_load_scale_tail(output_tile + 1, 6);
        }
#endif
#endif
#else
        if (scale_producer_active) {
            async_load<16>(
                g_sf, s_sf_ptr, u_gsfa,
                u_ssfa + ssfa_offset(next_output_stage), gsf_offset(1, 0));
        }
#endif
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

#if MXFP8_ISOLATED_SOURCE_CHANGE == 2
    auto output_b1_handoff = [&]() {
        if (has_next_output) {
            s_waitcnt_vmcnt(0_I);
#if MXFP8_ROW_MAJOR_SCALE
#if MXFP8_ROW_SCALE_RAW_TR_BPERMUTE
            // The four raw stages were filled above; the barrier publishes them.
#elif MXFP8_ROW_SCALE_TR_READ == 1
            publish_raw_scale_pair(0);
#elif MXFP8_ROW_SCALE_TR_READ == 2
            publish_scale_tr_pair(
                0, v_scale_tr_queue[0], v_scale_tr_queue[1]);
#elif MXFP8_ROW_SCALE_GROUP4_PUBLICATION
            publish_scale_group4(v_scale_queue);
#else
            publish_scale_queue01(0);
#endif
#endif
            s_waitcnt_lgkmcnt(0_I);
            __builtin_amdgcn_s_barrier();
            __builtin_amdgcn_sched_barrier(0);
            if (loops > 1) {
                async_load<T::VEC_B>(
                    g_b, s_b.ptr, u_gb,
                    u_sb + sb_offset(stage, 0), gb_offset(0, 1));
                async_load<T::VEC_B>(
                    g_b, s_b.ptr, u_gb,
                    u_sb + sb_offset(stage, 1), gb_offset(1, 1));
                __builtin_amdgcn_sched_barrier(0);
            }
            first_stage = next_output_stage;
        }
    };
#endif

#if MXFP8_ISOLATED_SOURCE_CHANGE == 3
    auto p_coord_c = opus::make_tuple(
        wave_id_m, lane_id % mma.grpn_c, wave_id_n,
        lane_id / mma.grpn_c);
    auto u_gc = partition_layout_c<T::VEC_C>(
        mma, opus::make_tuple(kargs.stride_c, 1_I), p_coord_c);
    auto c_offset = [&](int half_tile_m, int half_tile_n) {
        return half_tile_m * T::HALF_B_M * kargs.stride_c +
               half_tile_n * T::HALF_B_N;
    };
#endif

#if MXFP8_ISOLATED_SOURCE_CHANGE != 1
    __builtin_amdgcn_s_setprio(1);
#endif
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

#if MXFP8_ISOLATED_SOURCE_CHANGE == 3
    store<T::VEC_C>(g_c, v_c[0][0], u_gc, c_offset(0, 0), opus::number<2>{});
    store<T::VEC_C>(g_c, v_c[1][0], u_gc, c_offset(1, 0), opus::number<2>{});
    __builtin_amdgcn_sched_barrier(0);
#endif

    v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 1));

    mma_scale_repeat_n2<T, 0, 0, 0>(mma, v_a[0], v_b, v_c[0][1], v_sfa, v_sfb[1]);
    {
        auto* v_c_pin = reinterpret_cast<vector_t<D_ACC, 16>*>(&v_c[0][1]);
        asm volatile("" : "+v"(v_c_pin[0]) ::);
    }
    sched_barrier_pairs_scale();

#if MXFP8_ISOLATED_SOURCE_CHANGE == 2
    output_b1_handoff();
#endif

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
#if MXFP8_ISOLATED_SOURCE_CHANGE != 1
    __builtin_amdgcn_s_setprio(0);
#endif

#if MXFP8_ISOLATED_SOURCE_CHANGE != 2
    if (has_next_output) {
#if MXFP8_ISOLATED_SOURCE_CHANGE == 3 && !MXFP8_ROW_MAJOR_SCALE
        s_waitcnt_vmcnt(opus::number<16>{});
#else
        s_waitcnt_vmcnt(0_I);
#endif
#if MXFP8_ROW_MAJOR_SCALE
#if MXFP8_ROW_SCALE_RAW_TR_BPERMUTE
        // The four raw stages were filled above; the barrier publishes them.
#elif MXFP8_ROW_SCALE_TR_READ == 1
        publish_raw_scale_pair(0);
#elif MXFP8_ROW_SCALE_TR_READ == 2
        publish_scale_tr_pair(
            0, v_scale_tr_queue[0], v_scale_tr_queue[1]);
#elif MXFP8_ROW_SCALE_GROUP4_PUBLICATION
        publish_scale_group4(v_scale_queue);
#else
        publish_scale_queue01(0);
#endif
#endif
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);
        first_stage = next_output_stage;
    }
#endif

#if MXFP8_ISOLATED_SOURCE_CHANGE != 3
    auto p_coord_c = opus::make_tuple(wave_id_m, lane_id % mma.grpn_c, wave_id_n, lane_id / mma.grpn_c);
    auto u_gc = partition_layout_c<T::VEC_C>(mma, opus::make_tuple(kargs.stride_c, 1_I), p_coord_c);

    auto c_offset = [&](int half_tile_m, int half_tile_n) {
        return half_tile_m * T::HALF_B_M * kargs.stride_c + half_tile_n * T::HALF_B_N;
    };
#endif

#if MXFP8_ISOLATED_SOURCE_CHANGE == 3
    store<T::VEC_C>(g_c, v_c[0][1], u_gc, c_offset(0, 1), opus::number<2>{});
    store<T::VEC_C>(g_c, v_c[1][1], u_gc, c_offset(1, 1), opus::number<2>{});
#else
    store<T::VEC_C>(g_c, v_c[0][0], u_gc, c_offset(0, 0), opus::number<2>{});
    store<T::VEC_C>(g_c, v_c[0][1], u_gc, c_offset(0, 1), opus::number<2>{});
    store<T::VEC_C>(g_c, v_c[1][0], u_gc, c_offset(1, 0), opus::number<2>{});
    store<T::VEC_C>(g_c, v_c[1][1], u_gc, c_offset(1, 1), opus::number<2>{});
#endif
    }
}
