#pragma once

// Kernel arguments for MXFP8 scaled-MFMA GEMM.
struct opus_gemm_scale_kargs {
    const void* __restrict__ ptr_a;
    const void* __restrict__ ptr_b;
    void* __restrict__ ptr_c;
    int m;
    int n;
    int k;
    int batch;
    int stride_a;
    int stride_b;
    int stride_c;
    int stride_a_batch;
    int stride_b_batch;
    int stride_c_batch;

    const void* __restrict__ ptr_sfa;
    const void* __restrict__ ptr_sfb;
    // Packed scale strides in E8M0 elements. One stride advances to the next
    // K tile; the batch stride spans all spatial tiles and K tiles.
    int stride_sfa;
    int stride_sfb;
    int stride_sfa_batch;
    int stride_sfb_batch;
};

// Configuration traits for gfx950
// V_MFMA_SCALE_F32_16X16X128_F8F6F4.
template<
    int BLOCK_M_ = 256,
    int BLOCK_N_ = 256,
    int BLOCK_K_ = 128,
    int GROUP_M_ = 1,
    int GROUP_N_ = 1,
    int GROUP_K_ = 32>
struct gemm_a8w8_mxfp8_scale_traits {
    static constexpr int BLOCK_SIZE = 512;
    static constexpr int WARP_SIZE = 64;
    static constexpr int NUM_WAVES = BLOCK_SIZE / WARP_SIZE;

    static constexpr int B_M = BLOCK_M_;
    static constexpr int B_N = BLOCK_N_;
    static constexpr int B_K = BLOCK_K_;

    static constexpr int T_M = 4;
    static constexpr int T_N = 2;
    static constexpr int T_K = 1;

    static constexpr int W_M = 16;
    static constexpr int W_N = 16;
    static constexpr int W_K = 128;

    static constexpr int HALF_B_M = B_M / 2;
    static constexpr int HALF_B_N = B_N / 2;

    static_assert(NUM_WAVES == T_M * T_N * T_K);
    static_assert(T_K == 1);
    static_assert(HALF_B_M % (W_M * T_M) == 0);
    static_assert(HALF_B_N % (W_N * T_N) == 0);
    static_assert(B_K % (W_K * T_K) == 0);

    static constexpr int E_M = HALF_B_M / (W_M * T_M); // 128 / 16 * 4 = 2
    static constexpr int E_N = HALF_B_N / (W_N * T_N);
    static constexpr int E_K = B_K / (W_K * T_K);

    static constexpr int VEC_A = 16;
    static constexpr int VEC_B = 16;
    static constexpr int VEC_C = 4;

    static constexpr int GROUP_M = GROUP_M_;
    static constexpr int GROUP_N = GROUP_N_;
    static constexpr int GROUP_K = GROUP_K_;

    static constexpr int SCALE_KGROUPS_PER_MFMA = W_K / GROUP_K;
    static constexpr int NUM_KGROUPS = B_K / GROUP_K;

    static constexpr int smem_linear_wave = WARP_SIZE * VEC_A; // 1024
    static constexpr int smem_sub = smem_linear_wave / B_K; // 8
    static constexpr int smem_m_rep = HALF_B_M / smem_sub; // 16
    static constexpr int smem_n_rep = HALF_B_N / smem_sub; // 16
    static constexpr int smem_padding = 32;

    // The packed global tile exactly matches the consumer-major LDS image.
    static constexpr int SCALE_M_CALLS = B_M / (T_M * W_M); // 4
    static constexpr int SCALE_N_CALLS = E_N; // 4 per N half-tile
    static constexpr int SCALE_N_HALVES = B_N / HALF_B_N; // 2
    static constexpr int packed_sfa_tile_elem = B_M * NUM_KGROUPS;
    static constexpr int packed_sfb_tile_elem = B_N * NUM_KGROUPS;

    static constexpr int a_buffer_load_insts = HALF_B_M * B_K / (BLOCK_SIZE * VEC_A); // 2
    static constexpr int b_buffer_load_insts = HALF_B_N * B_K / (BLOCK_SIZE * VEC_B); // 2

    static constexpr int a_ds_read_insts = E_M * W_M * W_K / (WARP_SIZE * VEC_A);
    static constexpr int b_ds_read_insts = E_N * W_N * W_K / (WARP_SIZE * VEC_B);
    static constexpr int IDENTITY_E8M0 = 127;
};

// Experimental gfx950 V_MFMA_SCALE_F32_32X32X64_F8F6F4 pipeline.
//
// Keep the same 256x256x128 workgroup tile and producer-side LDS image as the
// validated 16x16x128 kernel.  A wave covers 32x64 output elements, with two
// K64 phases per K128 tile.  This makes the global/LDS traffic directly
// comparable while halving the number of scaled-MFMA instructions.
template<
    int BLOCK_M_ = 256,
    int BLOCK_N_ = 256,
    int BLOCK_K_ = 128,
    int GROUP_M_ = 1,
    int GROUP_N_ = 1,
    int GROUP_K_ = 32>
struct gemm_a8w8_mxfp8_scale_32x32x64_traits {
    static constexpr int BLOCK_SIZE = 512;
    static constexpr int WARP_SIZE = 64;
    static constexpr int NUM_WAVES = BLOCK_SIZE / WARP_SIZE;

    static constexpr int B_M = BLOCK_M_;
    static constexpr int B_N = BLOCK_N_;
    static constexpr int B_K = BLOCK_K_;

    static constexpr int T_M = 4;
    static constexpr int T_N = 2;
    static constexpr int T_K = 1;

    static constexpr int W_M = 32;
    static constexpr int W_N = 32;
    static constexpr int W_K = 64;

    static constexpr int HALF_B_M = B_M / 2;
    static constexpr int HALF_B_N = B_N / 2;

    static_assert(NUM_WAVES == T_M * T_N * T_K);
    static_assert(T_K == 1);
    static_assert(HALF_B_M % (W_M * T_M) == 0);
    static_assert(HALF_B_N % (W_N * T_N) == 0);
    static_assert(B_K % (W_K * T_K) == 0);

    static constexpr int E_M = HALF_B_M / (W_M * T_M); // 1
    static constexpr int E_N = HALF_B_N / (W_N * T_N); // 2
    static constexpr int E_K = B_K / (W_K * T_K);      // 2

    static constexpr int VEC_A = 16;
    static constexpr int VEC_B = 16;
    static constexpr int VEC_C = 4;

    static constexpr int GROUP_M = GROUP_M_;
    static constexpr int GROUP_N = GROUP_N_;
    static constexpr int GROUP_K = GROUP_K_;

    static constexpr int SCALE_KGROUPS_PER_MFMA = W_K / GROUP_K; // 2
    static constexpr int NUM_KGROUPS = B_K / GROUP_K;             // 4

    static constexpr int smem_linear_wave = WARP_SIZE * VEC_A;
    static constexpr int smem_sub = smem_linear_wave / B_K;
    static constexpr int smem_m_rep = HALF_B_M / smem_sub;
    static constexpr int smem_n_rep = HALF_B_N / smem_sub;
    static constexpr int smem_padding = 32;

    // Each physical scale lane owns one packed dword.  For A, its bytes select
    // [K64 phase][M half].  For B, there are two dwords (one per K64 phase)
    // whose bytes select [N half][N repeat].  Both packed tiles remain 1024 B.
    static constexpr int SCALE_M_CALLS = 2;
    static constexpr int SCALE_N_CALLS = E_N;
    static constexpr int SCALE_N_HALVES = B_N / HALF_B_N;
    static constexpr int packed_sfa_tile_elem = B_M * NUM_KGROUPS;
    static constexpr int packed_sfb_tile_elem = B_N * NUM_KGROUPS;

    static constexpr int a_buffer_load_insts =
        HALF_B_M * B_K / (BLOCK_SIZE * VEC_A);
    static constexpr int b_buffer_load_insts =
        HALF_B_N * B_K / (BLOCK_SIZE * VEC_B);
    static constexpr int a_ds_read_insts =
        E_M * E_K * W_M * W_K / (WARP_SIZE * VEC_A);
    static constexpr int b_ds_read_insts =
        E_N * E_K * W_N * W_K / (WARP_SIZE * VEC_B);
    static constexpr int IDENTITY_E8M0 = 127;
};

__host__ __device__ inline int ceil_div_scale(int a, int b) {
    return (a + b - 1) / b;
}
