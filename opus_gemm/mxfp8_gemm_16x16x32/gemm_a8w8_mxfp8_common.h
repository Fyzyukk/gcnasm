#pragma once

#ifndef MXFP8_PACK_SCALE
#define MXFP8_PACK_SCALE 1
#endif

#ifndef MXFP8_PIN_ACCUM
#define MXFP8_PIN_ACCUM 1
#endif

#ifndef MXFP8_BLOCK_M
#define MXFP8_BLOCK_M 256
#endif

#ifndef MXFP8_BLOCK_N
#define MXFP8_BLOCK_N 256
#endif

#ifndef MXFP8_BLOCK_K
#define MXFP8_BLOCK_K 128
#endif

#ifndef MXFP8_SCHED_PAIRS
#define MXFP8_SCHED_PAIRS 4
#endif

#ifndef MXFP8_SCHED_VALU_CNT
#define MXFP8_SCHED_VALU_CNT 2
#endif

#ifndef MXFP8_COMBINE_SCALE_EXP
#define MXFP8_COMBINE_SCALE_EXP 0
#endif

#ifndef MXFP8_SMEM_PADDING
#define MXFP8_SMEM_PADDING 32
#endif

#ifndef MXFP8_BLOCK_SIZE
#define MXFP8_BLOCK_SIZE 512
#endif

#ifndef MXFP8_T_M
#define MXFP8_T_M 4
#endif

#ifndef MXFP8_T_N
#define MXFP8_T_N 2
#endif

#ifndef MXFP8_MIN_BLOCKS_PER_CU
#define MXFP8_MIN_BLOCKS_PER_CU 2
#endif

#ifndef MXFP8_VEC_C
#define MXFP8_VEC_C 4
#endif

// Kernel arguments for MXFP8 (fp8 e4m3 x fp8 e4m3 -> fp32) GEMM with OCP
struct opus_gemm_kargs {
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
    int stride_sfa;        
    int stride_sfb;        
    int stride_sfa_batch;  
    int stride_sfb_batch;  
};

// Configuration traits for the fp8 x fp8 -> fp32 MXFP8 GEMM kernel.
template<
    int BLOCK_M_ = MXFP8_BLOCK_M,
    int BLOCK_N_ = MXFP8_BLOCK_N,
    int BLOCK_K_ = MXFP8_BLOCK_K,
    int GROUP_M_ = 1,
    int GROUP_N_ = 1,
    int GROUP_K_ = 32>
struct gemm_a8w8_mxfp8_traits {
    static constexpr int BLOCK_SIZE = MXFP8_BLOCK_SIZE;
    static constexpr int WARP_SIZE = 64;
    static constexpr int NUM_WAVES = BLOCK_SIZE / WARP_SIZE;

    static constexpr int B_M = BLOCK_M_;
    static constexpr int B_N = BLOCK_N_;
    static constexpr int B_K = BLOCK_K_;

    static constexpr int T_M = MXFP8_T_M;
    static constexpr int T_N = MXFP8_T_N;
    static constexpr int T_K = 1;

    static constexpr int W_M = 16;
    static constexpr int W_N = 16;
    static constexpr int W_K = 32;

    static constexpr int HALF_B_M = B_M / 2;
    static constexpr int HALF_B_N = B_N / 2;

    static_assert(NUM_WAVES == T_M * T_N * T_K);
    static_assert(T_M % T_N == 0);
    static_assert(T_K == 1);
    static_assert(HALF_B_M % (W_M * T_M) == 0);
    static_assert(HALF_B_N % (W_N * T_N) == 0);
    static_assert(B_K % (W_K * T_K) == 0);

    static constexpr int E_M = HALF_B_M / (W_M * T_M);
    static constexpr int E_N = HALF_B_N / (W_N * T_N);
    static constexpr int E_K = B_K / (W_K * T_K);

    // C accumulator registers per lane per 16x16 tile (= consecutive columns per lane
    // in C-layout 0). For 16x16x32 this is W_M*W_N/WARP_SIZE = 4 (the "pk" dimension).
    static constexpr int ELEM_C = W_M * W_N / WARP_SIZE;

    static constexpr int VEC_A_GLOBAL = 16;
    static constexpr int VEC_B_GLOBAL = 16;
    static constexpr int VEC_A = 8;
    static constexpr int VEC_B = 8;
    static constexpr int VEC_C = MXFP8_VEC_C;

    static constexpr int GROUP_M = GROUP_M_;
    static constexpr int GROUP_N = GROUP_N_;
    static constexpr int GROUP_K = GROUP_K_;
    
    static_assert(W_K == GROUP_K, "W_K must equal GROUP_K for per-group post-scaling");
    static constexpr int NUM_KGROUPS = B_K / GROUP_K;

    static constexpr int smem_linear_wave = WARP_SIZE * 16;
    static constexpr int smem_sub = smem_linear_wave / B_K;
    static constexpr int smem_m_rep = HALF_B_M / smem_sub;
    static constexpr int smem_n_rep = HALF_B_N / smem_sub;
    static constexpr int smem_padding = MXFP8_SMEM_PADDING;

    static_assert(smem_m_rep % NUM_WAVES == 0);
    static_assert(smem_n_rep % NUM_WAVES == 0);

    static constexpr int a_buffer_load_insts = HALF_B_M * B_K / (BLOCK_SIZE * VEC_A_GLOBAL);
    static constexpr int b_buffer_load_insts = HALF_B_N * B_K / (BLOCK_SIZE * VEC_B_GLOBAL);
    static constexpr int a_ds_read_insts = (E_M * E_K * W_M * W_K) / (WARP_SIZE * VEC_A);
    static constexpr int b_ds_read_insts = (E_N * E_K * W_N * W_K) / (WARP_SIZE * VEC_B);
#if MXFP8_PACK_SCALE
    // One dword packs all NUM_KGROUPS E8M0 bytes for a single output row.
    static constexpr int sfa_buffer_load_insts = E_M;
    // SFB loads one packed dword per (n_rep, pk). Each dword contains all
    // NUM_KGROUPS E8M0 bytes for the C fragment column.
    static constexpr int sfb_buffer_load_insts = E_N * ELEM_C;
#else
    static constexpr int sfa_buffer_load_insts = E_M * NUM_KGROUPS;
    // SFB loads one scale per (n_rep, pk, kg): each C column a lane holds is
    // distinct, so ELEM_C(=pk) times more than sfa. See make_layout_sfb_byte.
    static constexpr int sfb_buffer_load_insts = E_N * ELEM_C * NUM_KGROUPS;
#endif
};

__host__ __device__ inline int ceil_div(int a, int b) {
    return (a + b - 1) / b;
}
