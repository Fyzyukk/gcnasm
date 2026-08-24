# GEMM A8W8 MXFP8 Scaled-MFMA Pipeline Flow

> 本文描述的是较早的 global-to-VGPR scale pipeline，不再代表当前
> kernel。当前 host consumer-major prepack + cooperative dword
> global-to-LDS 流程见 `MXFP8_GEMM_OPTIMIZATION_LOG.md`。

本文档整理当前 `gemm_a8w8_mxfp8_scale_kernel_template.hpp` 的实际执行流程。优化实验记录放在 `SCALE_LOAD_OPTIMIZATION_PLAN1.md`。

## 1. Kernel 目标

kernel 计算 batched GEMM：

```text
C[batch, M, N] = A[batch, M, K] * B[batch, N, K]^T
```

数据类型：

| 张量 | kernel 内类型 | 说明 |
|---|---|---|
| A | `opus::fp8_t` | FP8 E4M3 |
| B | `opus::fp8_t` | FP8 E4M3 |
| C / ACC | `opus::fp32_t` | FP32 输出和累加 |
| SFA / SFB global storage | `unsigned char` | host/global 侧 E8M0 byte array |
| SFA / SFB register load | `unsigned int` | kernel 侧 packed 4-byte E8M0 dword |

SFA/SFB 的 host/global memory layout 没有改变：

```text
SFA: [batch, M, K / GROUP_K]
SFB: [batch, N, K / GROUP_K]
```

当前 `GROUP_K=32`，scaled MFMA 的 `W_K=128`，所以每个 scaled MFMA 覆盖 4 个 K-group scale。

## 2. 默认 traits

默认实例：

```cpp
using GemmTraits = gemm_a8w8_mxfp8_scale_traits<>;
```

关键参数：

| 参数 | 值 |
|---|---:|
| `B_M x B_N x B_K` | `256 x 256 x 128` |
| `BLOCK_SIZE` | `512` |
| `WARP_SIZE` | `64` |
| `NUM_WAVES` | `8` |
| `T_M x T_N x T_K` | `4 x 2 x 1` |
| `W_M x W_N x W_K` | `16 x 16 x 128` |
| `HALF_B_M x HALF_B_N` | `128 x 128` |
| `E_M x E_N x E_K` | `2 x 4 x 1` |
| `GROUP_K` | `32` |
| `SCALE_KGROUPS_PER_MFMA` | `4` |
| `VEC_A / VEC_B / VEC_C` | `16 / 16 / 4` |
| `smem_padding` | `32` |

一个 block 负责一个 `256 x 256` C tile，并拆成 4 个 `128 x 128` half-tile：

```text
v_c[0][0] -> M 上半区, N 左半区
v_c[0][1] -> M 上半区, N 右半区
v_c[1][0] -> M 下半区, N 左半区
v_c[1][1] -> M 下半区, N 右半区
```

8 个 wave 按 `T_M=4, T_N=2` 排布：

```cpp
wave_id_m = wave_id % T::T_M;
wave_id_n = wave_id / T::T_M;
```

## 3. Block 和 batch 映射

`grid.x` 展开 M/N tile，`grid.z` 表示 batch：

```cpp
wgid         = block_id_x();
num_tiles_n  = ceil_div_scale(kargs.n, T::B_N);
row          = (wgid / num_tiles_n) * T::B_M;
col          = (wgid % num_tiles_n) * T::B_N;
batch_id     = block_id_z();
```

global base：

```text
A base = ptr_a + batch_id * stride_a_batch + row * stride_a
B base = ptr_b + batch_id * stride_b_batch + col * stride_b
C base = ptr_c + batch_id * stride_c_batch + row * stride_c + col
```

scale base 先按 byte address 计算，再 reinterpret 为 packed `uint32_t*`：

```cpp
using D_SF = unsigned char;
using D_SF_PACK = unsigned int;

g_sfa = make_gmem(reinterpret_cast<const D_SF_PACK*>(
    reinterpret_cast<const D_SF*>(kargs.ptr_sfa)
    + batch_id * kargs.stride_sfa_batch
    + row * kargs.stride_sfa));

g_sfb = make_gmem(reinterpret_cast<const D_SF_PACK*>(
    reinterpret_cast<const D_SF*>(kargs.ptr_sfb)
    + batch_id * kargs.stride_sfb_batch
    + col * kargs.stride_sfb));
```

host 侧要求 `M/N/K` 是 `B_M/B_N/B_K` 的整数倍。当前 pipeline 还会无条件预取前两个 K tile，因此要求：

```text
loops = ceil(k / B_K) >= 2
```

默认 `B_K=128` 时即 `K >= 256`。

## 4. 数据流总览

A/B 走 LDS 双缓冲；SFA/SFB 不进 LDS，直接从 global 读取到 register：

```text
global A/B -> async_load -> LDS smem_a/smem_b -> load -> v_a/v_b -> scaled MFMA
global SFA/SFB ---------> packed uint32 v_sfa/v_sfb --------^
scaled MFMA -> v_c[2][2] -> global C
```

LDS 按 stage 和 half tile 分块：

```cpp
sa_offset(stage, half_tile_m) = (stage * 2 + half_tile_m) * smem_a_elem;
sb_offset(stage, half_tile_n) = (stage * 2 + half_tile_n) * smem_b_elem;
```

stage 对应 K tile parity：

```text
stage 0: tile 0, tile 2, tile 4, ...
stage 1: tile 1, tile 3, tile 5, ...
```

## 5. Layout helper 职责

| helper | 方向 | 作用 |
|---|---|---|
| `make_layout_ga_scale` | global A -> LDS | 每线程按 `VEC_A=16` 载入 A half tile 的 K 切片 |
| `make_layout_sa_scale` | LDS A 写入 | 将 A 写入按 wave/half/stage 排列的 LDS |
| `make_layout_ra_scale` | LDS A -> register | 从 LDS 读 `v_a`，匹配 scaled MFMA A operand |
| `make_layout_gb_scale` | global B -> LDS | 每线程按 `VEC_B=16` 载入 B half tile 的 K 切片 |
| `make_layout_sb_scale` | LDS B 写入 | 将 B 写入按 wave/half/stage 排列的 LDS |
| `make_layout_rb_scale` | LDS B -> register | 从 LDS 读 `v_b`，匹配 scaled MFMA B operand |
| `make_layout_sfa_scale` | global SFA -> register | 读取 packed E8M0 dword，不进 LDS |
| `make_layout_sfb_scale` | global SFB -> register | 读取 packed E8M0 dword，不进 LDS |

packed scale layout 使用 packed stride：

```cpp
u_sfa = make_layout_sfa_scale<T>(
    lane_id, wave_id_m,
    kargs.stride_sfa / T::SCALE_KGROUPS_PER_MFMA);

u_sfb = make_layout_sfb_scale<T>(
    lane_id, wave_id_n,
    kargs.stride_sfb / T::SCALE_KGROUPS_PER_MFMA);
```

packed scale offset：

```cpp
sfa_offset(half_tile_m, tile_k)
  = half_tile_m * HALF_B_M * (stride_sfa / 4)
  + tile_k;

sfb_offset(half_tile_n, tile_k)
  = half_tile_n * HALF_B_N * (stride_sfb / 4)
  + tile_k;
```

这里的 `tile_k` 是 `B_K=128` tile index。因为 `g_sfa/g_sfb` 已经是 `uint32_t*`，所以 `tile_k + 1` 跳过的是 4 个 E8M0 scale byte。

## 6. Scale register 和 byte 选择

当前 scale register：

```cpp
using vtype_sfa = vector_t<unsigned int, T::E_M>;
using vtype_sfb = vector_t<unsigned int, T::E_N>;
```

默认情况下：

```text
v_sfa: 2 packed dwords
v_sfb: 4 packed dwords
```

每个 packed dword 保存当前 128-K MFMA 覆盖的 4 个 E8M0 scale byte：

```text
byte 0 -> K group 0
byte 1 -> K group 1
byte 2 -> K group 2
byte 3 -> K group 3
```

lane group 决定当前 lane 使用哪个 byte：

```cpp
scale_shift_a = (lane_id / T::W_M) * 8;
scale_shift_b = (lane_id / T::W_N) * 8;

scale_a = (v_sfa[MR] >> scale_shift_a) & 0xffu;
scale_b = (v_sfb[NR] >> scale_shift_b) & 0xffu;
```

注意：host/global scale 数学 layout 没有变；改变的是 kernel 的 load granularity 和 register 类型。

## 7. scaled MFMA helper

关键 helper：

```cpp
mma_scale_repeat_mn<T>(
    mma, v_a, v_b, v_c, v_sfa, v_sfb, lane_id);
```

它手动遍历 `E_M x E_N`，对每个 `MR/NR` 取出 A/B/C slice，然后调用底层 scaled MFMA：

```text
for MR in [0, E_M):
  for NR in [0, E_N):
    s_a = A slice for MR
    s_b = B slice for NR
    s_c = C slice for (MR, NR)
    scale_a = extract byte from v_sfa[MR]
    scale_b = extract byte from v_sfb[NR]
    s_c = base_mma{}(s_a, s_b, s_c, scale_a, scale_b, op_sel_a=0, op_sel_b=0)
```

约束：

```text
T::E_K == 1
```

也就是一个 `B_K=128` tile 正好对应一个 `W_K=128` scaled MFMA 深度。

## 8. Prologue

Prologue 建立主循环 invariant：当前 tile 的 `(half_m=0, half_n=0)` 已经完成。

步骤：

```text
1. load tile0 SFA/SFB half0，async load tile0 A/B half0 到 stage0
2. load tile0 SFA/SFB half1，async load tile0 A/B half1 到 stage0
3. waitcnt + barrier，保证 stage0 可读
4. load tile1 SFA/SFB half0，async load tile1 A/B half0 到 stage1，预取 tile1 A half1
5. 从 stage0 读 A half0 和 B half0 到 v_a[0] / v_b
6. async load tile1 B half1 到 stage1
7. 执行 tile0 的 (half_m=0, half_n=0) scaled MFMA -> v_c[0][0]
```

Prologue 结束后：

```text
当前 tile 的 (0,0) half-pair 已累加完成。
```

## 9. Main loop

主循环：

```cpp
for (int tile = 0; tile < loops - 2; tile += 2)
```

每轮处理两个 K tile，并预取后两个 K tile。

进入一轮时，`tile` 的 `(0,0)` 已经完成。本轮补完：

```text
tile:
  (1,0) -> v_c[1][0]
  (0,1) -> v_c[0][1]
  (1,1) -> v_c[1][1]
```

然后处理 `tile + 1` 的完整 2x2 half-pair：

```text
tile+1:
  (0,0) -> v_c[0][0]
  (1,0) -> v_c[1][0]
  (0,1) -> v_c[0][1]
  (1,1) -> v_c[1][1]
```

轮末提前执行下一轮的第一条：

```text
tile+2:
  (0,0) -> v_c[0][0]
```

这条提前 MFMA 维持下一轮相同 invariant。

## 10. Epilogue

Epilogue 从：

```cpp
const int tile = loops - 2;
```

开始。进入 epilogue 时，`tile` 的 `(0,0)` 已经完成。Epilogue 不再预取新 tile，只 drain 最后两个 K tile：

```text
tile:
  (1,0), (0,1), (1,1)

tile+1:
  (0,0), (1,0), (0,1), (1,1)
```

结束后，`v_c[2][2]` 中保存当前 `256 x 256` C tile 的完整 K 累加结果。

## 11. 同步和调度

同步控制：

| 控制 | 作用 |
|---|---|
| `s_waitcnt_vmcnt(...)` | 等待 global buffer load / async load 进度 |
| `s_waitcnt_lgkmcnt(...)` | 等待 LDS read |
| `__builtin_amdgcn_s_barrier()` | 保证 LDS stage 跨 wave 可见，并保护 stage 复用 |
| `__builtin_amdgcn_sched_barrier(0)` | 给 compiler scheduler 设置边界 |

每段 scaled MFMA 使用：

```cpp
__builtin_amdgcn_s_setprio(1);
mma_scale_repeat_mn(...);
asm volatile("" : "+v"(v_c_pin[0]), "+v"(v_c_pin[1]) ::);
sched_barrier_pairs_scale<8, 2, 0>();
__builtin_amdgcn_s_setprio(0);
```

含义：

```text
s_setprio(1/0): 临时提高 MFMA 段优先级，再恢复
inline asm pin: 约束 compiler 不要过早移动 v_c 读写
sched_barrier_pairs_scale<8,2,0>: 当前保留的 scheduler group barrier 参数
```

实验结论：

```text
删除 block-level post-MFMA s_barrier: 624-649 TFLOPS，不保留
下沉 post-MFMA s_barrier:            530-537 TFLOPS，不保留
sched_barrier_pairs_scale<8,2,0>:    819-821 TFLOPS，作为方案 C 保留
```

## 12. Store

构造 C 的 per-lane store layout：

```cpp
p_coord_c = make_tuple(
    wave_id_m,
    lane_id % mma.grpn_c,
    wave_id_n,
    lane_id / mma.grpn_c);

u_gc = partition_layout_c<T::VEC_C>(
    mma, make_tuple(kargs.stride_c, 1_I), p_coord_c);
```

4 个 half-tile 写回：

```cpp
c_offset(half_tile_m, half_tile_n)
  = half_tile_m * T::HALF_B_M * kargs.stride_c
  + half_tile_n * T::HALF_B_N;

store(g_c, v_c[0][0], u_gc, c_offset(0, 0));
store(g_c, v_c[0][1], u_gc, c_offset(0, 1));
store(g_c, v_c[1][0], u_gc, c_offset(1, 0));
store(g_c, v_c[1][1], u_gc, c_offset(1, 1));
```

## 13. 当前性能和资源

当前 packed uint32 scale load 版本资源：

```text
TotalSGPRs: 65
VGPRs: 233
ScratchSize: 0
VGPR Spill: 0
Occupancy: 2 waves/SIMD
LDS Size: 135168 bytes/block
```

当前 correctness：

```text
unit scale 256x256x256: VALID
random scale 256x256x256: VALID
K-pattern 512x512x512: VALID
```

当前 4096 性能：

```text
1172-1179 TFLOPS
1.17-1.18 PFLOPS
```

## 14. 当前实现注意点

- 当前是硬件 `v_mfma_scale` 路线，不是普通 MFMA + software post-scale。
- host/global SFA/SFB layout 仍是 byte layout；kernel 只是按 packed `uint32_t` 加载。
- `stride_sfa/stride_sfb` 是 byte scale stride，kernel 内 packed layout 使用 `stride / SCALE_KGROUPS_PER_MFMA`。
- 默认 `K` 是 `B_K=128` 的整数倍，因此 `K / GROUP_K` 是 4 的整数倍，packed dword row base 对齐成立。
- `T::E_K` 固定要求为 1；如果未来修改 `B_K/W_K` 导致 `E_K > 1`，`mma_scale_repeat_mn` 和 scale offset 都需要重新设计。
- 当前代码没有处理 `loops < 2` 的路径；默认形状下需要 `K >= 256`。
- SFA/SFB 不经过 LDS，也没有 cross-lane remap；每个 lane 自己加载 packed dword 并抽取自己的 lane-group byte。
