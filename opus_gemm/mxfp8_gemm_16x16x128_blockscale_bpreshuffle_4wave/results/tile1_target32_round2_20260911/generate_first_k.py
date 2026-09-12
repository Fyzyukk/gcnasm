#!/usr/bin/env python3
"""Peel K0 and initialize every accumulator with a native zero-SrcC MFMA."""
from experiment_utils import WORK, record_candidate, replace_once

PARENT = "tail_a3_prefetch56"
parent = (WORK / PARENT / "tmpl.hpp").read_text()
helper = r'''
template<class T, int HALF_TILE_M, int M_REPEAT, int N_REPEAT, class MMA>
__device__ inline auto mma_scale_zero_one(
    MMA& mma,
    const typename opus::remove_cvref_t<MMA>::vtype_a& v_a,
    const typename opus::remove_cvref_t<MMA>::vtype_b& v_b,
    unsigned int v_sfa, unsigned int v_sfb)
    -> typename opus::remove_cvref_t<MMA>::MMA::vtype_c {
    (void)mma;
    using tiled_mma = opus::remove_cvref_t<MMA>;
    using fragment = typename tiled_mma::MMA::vtype_c;
    constexpr int a_begin = M_REPEAT * tiled_mma::mma_a_len;
    constexpr int b_begin = N_REPEAT * tiled_mma::mma_b_len;
    const auto a = opus::slice(v_a, opus::number<a_begin>{},
                              opus::number<a_begin + tiled_mma::mma_a_len>{});
    const auto b = opus::slice(v_b, opus::number<b_begin>{},
                              opus::number<b_begin + tiled_mma::mma_b_len>{});
    fragment result;
    // Match mfma_adaptor_swap_ab: hardware SrcA/scaleA consume logical B.
    // SrcC is the inline positive zero; this is each accumulator's first K.
    asm volatile(
        "v_mfma_scale_f32_16x16x128_f8f6f4 %0, %1, %2, 0, %3, %4 "
        "op_sel:[%5,%6,0] op_sel_hi:[%7,%8,0]"
        : "=a"(result)
        : "v"(b), "v"(a), "v"(v_sfb), "v"(v_sfa),
          "n"(N_REPEAT & 1), "n"(M_REPEAT & 1),
          "n"(N_REPEAT >> 1), "n"(M_REPEAT >> 1));
    return result;
}

#define MXFP8_MMA_ZERO_PAIR(HALF_TILE_M, M_REPEAT, N_GROUP, VA, VB, C0, C1, SFA, SFB) \
    do { \
        C0 = mma_scale_zero_one<T, HALF_TILE_M, M_REPEAT, (N_GROUP) * 2>( \
            mma, VA, VB, (SFA)[HALF_TILE_M], SFB); \
        C1 = mma_scale_zero_one<T, HALF_TILE_M, M_REPEAT, (N_GROUP) * 2 + 1>( \
            mma, VA, VB, (SFA)[HALF_TILE_M], SFB); \
    } while (false)

#define MXFP8_MMA_ZERO_ONE(HALF_TILE_M, M_REPEAT, N_REPEAT, VA, VB, C, SFA, SFB) \
    do { \
        C = mma_scale_zero_one<T, HALF_TILE_M, M_REPEAT, N_REPEAT>( \
            mma, VA, VB, (SFA)[HALF_TILE_M], SFB); \
    } while (false)

'''

loop_marker = "    for (tile = 0; tile + 2 < loops; ++tile) {"
start = parent.index(loop_marker) + len(loop_marker) + 1
end = parent.index("    }\n\n    // Consume K62", start)
body = parent[start:end]
for zero in [False, True]:
    first = body
    source = parent
    if zero:
        first = first.replace("MXFP8_MMA_PAIR(", "MXFP8_MMA_ZERO_PAIR(").replace(
            "MXFP8_MMA_ONE(", "MXFP8_MMA_ZERO_ONE(")
        source = replace_once(source,
            "    __attribute__((amdgpu_pin_agpr(BASE))) AccFragment NAME = {}",
            "    __attribute__((amdgpu_pin_agpr(BASE))) AccFragment NAME")
        marker = "template<class T>\n__device__ inline auto make_layout_ga_scale"
        source = replace_once(source, marker, helper + marker)
        source = replace_once(source, "#undef MXFP8_MMA_PAIR", "#undef MXFP8_MMA_PAIR\n#undef MXFP8_MMA_ZERO_ONE\n#undef MXFP8_MMA_ZERO_PAIR")
    first = "    // K0 starts each accumulator; subsequent tiles retain increasing K order.\n    {\n        const int tile = 0;\n" + first + "    }\n\n"
    source = replace_once(source, "#pragma unroll 8\n" + loop_marker,
                          first + "#pragma unroll 8\n" + loop_marker.replace("tile = 0", "tile = 1"))
    name = "first_k_zero_asm" if zero else "first_k_peeled_control"
    record_candidate(name, source, dict(first_k_peeled=True, zero_src_c_initialization=zero,
                     bf16_lds_epilogue=True, release_mfma=5,
                     tail_prefetch_schedule=[["a", 3, 56]], unified_initial_matrix_stages=[1]), PARENT)
