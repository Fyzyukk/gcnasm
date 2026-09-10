#pragma once

#include "gemm_a8w8_mxfp8_scale_common.h"

// 4-wave 256x256 single-MFMA co-execution prototype with final-tile early C
// stores. Keep the validated CX2 rolling pipeline and C-only a0:a255 placement.
struct four_wave_c_agpr_single_mfma_coexec_early_c_steady_b1_head_after4_tail8_v1_traits {
    static constexpr int BLOCK_SIZE = 256;
    static constexpr int WARP_SIZE = 64;
    static constexpr int NUM_WAVES = BLOCK_SIZE / WARP_SIZE;
    static constexpr int MIN_WGS_PER_CU = 1;

    static constexpr int B_M = 256;
    static constexpr int B_N = 256;
    static constexpr int B_K = 128;

    static constexpr int T_M = 2;
    static constexpr int T_N = 2;
    static constexpr int T_K = 1;

    static constexpr int W_M = 16;
    static constexpr int W_N = 16;
    static constexpr int W_K = 128;

    static constexpr int HALF_B_M = B_M / 2;
    static constexpr int HALF_B_N = B_N / 2;

    static_assert(NUM_WAVES == 4);
    static_assert(NUM_WAVES == T_M * T_N * T_K);
    static_assert(HALF_B_M % (W_M * T_M) == 0);
    static_assert(HALF_B_N % (W_N * T_N) == 0);
    static_assert(B_K % (W_K * T_K) == 0);

    static constexpr int E_M = HALF_B_M / (W_M * T_M);
    static constexpr int E_N = HALF_B_N / (W_N * T_N);
    static constexpr int E_K = B_K / (W_K * T_K);

    static constexpr int VEC_A = 16;
    static constexpr int VEC_B = 16;
    static constexpr int VEC_C = 4;

    static constexpr int GROUP_M = 1;
    static constexpr int GROUP_N = 1;
    static constexpr int GROUP_K = 32;

    static constexpr int SCALE_KGROUPS_PER_MFMA = W_K / GROUP_K;
    static constexpr int NUM_KGROUPS = B_K / GROUP_K;

    static constexpr int smem_linear_wave = WARP_SIZE * VEC_A;
    static constexpr int smem_sub = smem_linear_wave / B_K;
    static constexpr int smem_m_rep = HALF_B_M / smem_sub;
    static constexpr int smem_n_rep = HALF_B_N / smem_sub;
    static constexpr int smem_padding = 32;

    static constexpr int SCALE_M_CALLS = B_M / (T_M * W_M);
    static constexpr int SCALE_N_CALLS = E_N;
    static constexpr int SCALE_N_HALVES = B_N / HALF_B_N;
    static constexpr int packed_sfa_tile_elem = B_M * NUM_KGROUPS;
    static constexpr int packed_sfb_tile_elem = B_N * NUM_KGROUPS;

    // Each lane rolls four explicit row-major dwords. Four scale-call lanes
    // transpose the current dword and publish one consumer-major store<4>.
    static constexpr int SCALE_TILE_VEC = NUM_KGROUPS;
    static constexpr int SCALE_CACHE_TILES = 4;
    static constexpr int SCALE_CACHE_VEC = SCALE_TILE_VEC * SCALE_CACHE_TILES;
    static constexpr int SFA_LOAD_VEC = SCALE_TILE_VEC;
    static constexpr int SFB_LOAD_VEC = SCALE_TILE_VEC;
    static constexpr int SFA_PRODUCER_LANES = BLOCK_SIZE;
    static constexpr int SFB_PRODUCER_LANES = BLOCK_SIZE;
    static_assert(SCALE_TILE_VEC == 4);
    static_assert(SCALE_CACHE_VEC == 16);
    static_assert((SCALE_CACHE_TILES & (SCALE_CACHE_TILES - 1)) == 0);
    static_assert(SFA_PRODUCER_LANES * SCALE_TILE_VEC == packed_sfa_tile_elem);
    static_assert(SFB_PRODUCER_LANES * SCALE_TILE_VEC == packed_sfb_tile_elem);

    static constexpr int a_buffer_load_insts =
        HALF_B_M * B_K / (BLOCK_SIZE * VEC_A);
    static constexpr int b_buffer_load_insts =
        HALF_B_N * B_K / (BLOCK_SIZE * VEC_B);
    static constexpr int a_ds_read_insts =
        E_M * W_M * W_K / (WARP_SIZE * VEC_A);
    static constexpr int b_ds_read_insts =
        E_N * W_N * W_K / (WARP_SIZE * VEC_B);

    static constexpr int SMEM_A_ELEMS =
        smem_m_rep * (smem_linear_wave + smem_padding) * 4;
    static constexpr int SMEM_B_ELEMS =
        smem_n_rep * (smem_linear_wave + smem_padding) * 4;
    static constexpr int LDS_BYTES =
        SMEM_A_ELEMS + SMEM_B_ELEMS
        + 2 * packed_sfa_tile_elem + 2 * packed_sfb_tile_elem;

    static_assert(E_M == 4 && E_N == 4 && E_K == 1);
    static_assert(a_ds_read_insts == 8 && b_ds_read_insts == 8);
    static_assert(packed_sfa_tile_elem == 1024);
    static_assert(packed_sfb_tile_elem == 1024);
    static_assert(LDS_BYTES == 139264);

    static constexpr int IDENTITY_E8M0 = 127;
};
