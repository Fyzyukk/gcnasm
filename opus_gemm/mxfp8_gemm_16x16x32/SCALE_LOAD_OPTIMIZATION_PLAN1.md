# MXFP8 Scaled-MFMA Scale Load Optimization Plan

本文档记录 `gemm_a8w8_mxfp8_scale_kernel_template.hpp` 的 scale load 相关优化、已验证实验、当前保留状态和后续路线。整体 kernel pipeline 说明放在 `GEMM_A8W8_MXFP8_SCALE_PIPELINE_FLOW.md`。

## 当前结论

当前保留版本：

```text
block shape: 256x256x128
smem_padding: 32
launch_bounds: __launch_bounds__(Traits::BLOCK_SIZE, 2)
barrier structure: 默认 block-level barrier 结构
sched_barrier_pairs_scale: <8, 2, 0>
scale load: packed uint32
```

当前 `4096x4096x4096, batch=1` 性能：

```text
约 1172-1179 TFLOPS
约 1.17-1.18 PFLOPS
```

性能演进：

```text
最初 spill 版本:     251-257 TFLOPS
方案 1 后:           816-818 TFLOPS
方案 C 后:           819-821 TFLOPS
方案 D 后:           1172-1179 TFLOPS
```

当前资源：

```text
TotalSGPRs: 65
VGPRs: 233
AGPRs: 0
ScratchSize: 0 bytes/lane
SGPR Spill: 0
VGPR Spill: 0
Occupancy: 2 waves/SIMD
LDS Size: 135168 bytes/block
```

## 背景

当前 kernel 使用硬件 scaled MFMA：

```text
V_MFMA_SCALE_F32_16X16X128_F8F6F4
```

默认参数：

```text
B_M x B_N x B_K = 256 x 256 x 128
GROUP_K = 32
W_M x W_N x W_K = 16 x 16 x 128
E_M x E_N x E_K = 2 x 4 x 1
SCALE_KGROUPS_PER_MFMA = W_K / GROUP_K = 4
```

一个 scaled MFMA 的 K 宽度是 128，而 MXFP8 scale 的 group K 是 32，所以每个 MFMA 覆盖 4 个 K-group scale：

```text
K[0:32)    -> scale group 0
K[32:64)   -> scale group 1
K[64:96)   -> scale group 2
K[96:128)  -> scale group 3
```

硬件 scaled MFMA 中，不同 lane group 使用不同 K-group scale：

```cpp
scale_group_a = lane_id / T::W_M;  // 0..3
scale_group_b = lane_id / T::W_N;  // 0..3
```

因此从语义上，每个 lane 对每个 `MR/NR` repeat 实际只需要 1 个 E8M0 scale byte。

## 实验总表

| 方向 | 实验配置 | Correctness | 4096 性能 | 结论 |
|---|---|---:|---:|---|
| 初始版本 | 每 lane 加载 4 个 K-group byte，寄存器保存全部 scale | VALID | `251-257 TFLOPS` | spill 严重，不保留 |
| 方案 1: lane-local byte scale | 每 lane 只加载实际使用的 1 个 K-group byte | VALID | `816-818 TFLOPS` | 保留过，后续被方案 D 替代 |
| smem padding | `smem_padding=0` | 未发现 correctness 问题 | `754-759 TFLOPS` | 不保留 |
| smem padding | `smem_padding=16` | 未发现 correctness 问题 | 约 `700 TFLOPS` | 不保留 |
| smem padding | `smem_padding=32` | VALID | 约 `817 TFLOPS` | 保留 |
| launch bounds | min blocks per CU `2 -> 1` | VALID | 无稳定收益 | 不保留 |
| block shape | `256x128x128` | VALID | `656.41 / 657.14 TFLOPS` | 不保留 |
| block shape | `128x256x128` | VALID | `548.13 / 550.44 TFLOPS` | 不保留 |
| barrier 删除 | 删除 post-MFMA `s_barrier` | VALID | `649.27 / 623.99 TFLOPS` | 不保留 |
| barrier 下沉 | post-MFMA barrier 下沉到下一次 LDS load 前 | VALID | `536.95 / 530.32 TFLOPS` | 不保留 |
| 方案 A | scaled MFMA 写临时 `v_mma` 后再加到 `v_c` | VALID | `455-535 TFLOPS` | 不保留 |
| 方案 B | ISA 对比普通 FP8、block_scale、当前 scaled-MFMA | N/A | 见分析 | 已完成 |
| 方案 C | `sched_barrier_pairs_scale<8,4,0> -> <8,2,0>` | VALID | `819-821 TFLOPS` | 保留 |
| 方案 D | packed `uint32` scale load | VALID | `1172-1179 TFLOPS` | 保留 |

## 方案 1: lane-local byte scale

### 问题

优化前 scale register 类型：

```cpp
using vtype_sfa = vector_t<unsigned char, T::E_M * T::SCALE_KGROUPS_PER_MFMA>;
using vtype_sfb = vector_t<unsigned char, T::E_N * T::SCALE_KGROUPS_PER_MFMA>;
```

默认相当于：

```text
SFA: 2 * 4 = 8 byte elements
SFB: 4 * 4 = 16 byte elements
```

但每个 lane 实际只使用当前 `lane_id / W_M` 或 `lane_id / W_N` 对应的 1 个 K-group byte。旧实现既多读 scale，又显著增加寄存器压力。

优化前资源：

```text
VGPRs: 256
VGPR Spill: 69
ScratchSize: 280 bytes/lane
Occupancy: 2 waves/SIMD
LDS Size: 135168 bytes/block
```

优化前 4096 性能：

```text
0.5470 ms, 251.26 TFLOPS
0.5346 ms, 257.07 TFLOPS
```

### 实现

把 K-group 选择提前到 global scale offset 中，register 只保留 `E_M/E_N` 维度：

```cpp
using vtype_sfa = vector_t<unsigned char, T::E_M>;
using vtype_sfb = vector_t<unsigned char, T::E_N>;
```

offset 从：

```cpp
base + tile_k * T::SCALE_KGROUPS_PER_MFMA
```

变成：

```cpp
base + tile_k * T::SCALE_KGROUPS_PER_MFMA + lane_id / T::W_M
base + tile_k * T::SCALE_KGROUPS_PER_MFMA + lane_id / T::W_N
```

helper 直接取：

```cpp
scale_a = v_sfa[MR];
scale_b = v_sfb[NR];
```

### 结果

Correctness：

```text
unit scale 256x256x256: VALID
random scale 256x256x256: VALID
K-pattern 256x256x256: VALID
K-pattern 512x512x512: VALID
```

资源：

```text
VGPRs: 232
VGPR Spill: 0
ScratchSize: 0 bytes/lane
Occupancy: 2 waves/SIMD
LDS Size: 135168 bytes/block
```

4096 性能：

```text
0.1682 ms, 816.92 TFLOPS
0.1681 ms, 817.74 TFLOPS
0.1685 ms, 815.79 TFLOPS
```

结论：方案 1 是第一次关键优化，核心收益是消除 VGPR spill。

## 其他结构实验

### smem padding

```text
padding 0:  754-759 TFLOPS, LDS 131072 bytes/block
padding 16: 约 700 TFLOPS, LDS 133120 bytes/block
padding 32: 约 817 TFLOPS, LDS 135168 bytes/block
```

结论：保留 `smem_padding=32`。

### launch bounds

实验：

```cpp
__launch_bounds__(Traits::BLOCK_SIZE, 2)
__launch_bounds__(Traits::BLOCK_SIZE, 1)
```

`2 -> 1` 没有稳定收益，保留：

```cpp
__launch_bounds__(Traits::BLOCK_SIZE, 2)
```

### block shape

`256x128x128`：

```text
VGPRs: 140
ScratchSize: 0
LDS Size: 101376 bytes/block
Correctness: VALID
4096: 656.41 / 657.14 TFLOPS
```

`128x256x128`：

```text
VGPRs: 145
ScratchSize: 0
LDS Size: 101376 bytes/block
Correctness: VALID
4096: 548.13 / 550.44 TFLOPS
```

默认 `256x256x128` 明显更快，保留默认 block shape。

### block-level barrier

删除 post-MFMA `s_barrier`：

```text
Correctness: VALID
4096: 649.27 / 623.99 TFLOPS
```

把 post-MFMA `s_barrier` 下沉到下一次 LDS load 前：

```text
Correctness: VALID
4096: 536.95 / 530.32 TFLOPS
```

结论：block-level barrier 不只是 correctness 保护，也影响 wave 间 pipeline 节奏，保留默认 barrier 结构。

## 方案 A: 临时 accumulator / v_mma pipeline

目标是参考 `block_scale_gemm`，让 scaled MFMA 先写临时 `v_mma`，再加回 `v_c`，尝试减少对最终 accumulator 的长依赖：

```text
scaled MFMA -> v_mma
v_c += v_mma
```

结果：

```text
A1: 每个 scaled MFMA 写临时 partial，立即加回对应 v_c slice
  VGPRs: 238
  ScratchSize: 0
  VGPR Spill: 0
  Correctness: VALID
  4096: 500.47 / 523.87 / 507.89 TFLOPS

A2: helper 内先生成完整临时 v_mma tile，再统一加回 v_c
  VGPRs: 238
  ScratchSize: 0
  VGPR Spill: 0
  Correctness: VALID
  4096: 534.61 / 455.13 / 498.64 TFLOPS
```

结论：虽然无 spill，但额外 VALU add 和调度形态使性能明显下降，不保留。

## 方案 B: generated ISA 对比

对比文件：

```text
普通 FP8:
  /root/workspace/gcnasm/opus_gemm/fp8_gemm/gemm_a8w8_8wave-hip-amdgcn-amd-amdhsa-gfx950.s

block_scale:
  /root/workspace/gcnasm/opus_gemm/block_scale_gemm/build/gemm_a8w8_blockscale_kernel-hip-amdgcn-amd-amdhsa-gfx950.s

当前 MXFP8 scaled-MFMA:
  build/gemm_a8w8_mxfp8_scale_kernel-hip-amdgcn-amd-amdhsa-gfx950.s
```

静态指令统计：

```text
普通 FP8:
  total instructions: 1160
  MFMA: 128 ordinary v_mfma
  MFMA density: 11.03%
  waitcnt: 23
  s_barrier: 33

block_scale:
  total instructions: 1413
  MFMA: 128 ordinary v_mfma
  software scale/add: 443 v_fma/v_pk_fma + 35 v_mul
  MFMA density: 9.06%
  waitcnt: 18
  s_barrier: 32

MXFP8 byte-scale version:
  total instructions: 1434
  MFMA: 128 v_mfma_scale
  scale global load: 48 buffer_load_ubyte
  scale byte extract / packing related VALU: 87 bit ops
  MFMA density: 8.93%
  waitcnt: 37
  s_barrier: 32
```

MFMA group 内相邻 MFMA gap：

```text
普通 FP8:
  avg gap: 0.00
  histogram: 0:114

block_scale:
  avg gap: 4.02
  histogram: 0:40, 4:13, 6:23, 7:36, 8:2

MXFP8 byte-scale version:
  avg gap: 0.08
  histogram: 0:108, 1:4, 2:1, 3:1
```

结论：当时的 scaled-MFMA 版本并没有被编译器排得很稀疏，108/114 个 group 内相邻 MFMA 是背靠背。性能瓶颈更像来自 byte scale load / waitcnt / hardware scaled-MFMA 行为，而不是明显的 compiler scheduling 空洞。

## 方案 C: scheduler barrier 参数扫描

默认：

```cpp
sched_barrier_pairs_scale<8, 4, 0>();
```

扫描结果：

```text
<8,4,0>
  VGPRs: 232
  Correctness: VALID
  sweep:   819.62 / 818.26 TFLOPS
  confirm: 816.67 / 818.55 / 817.67 / 816.69 / 815.06 TFLOPS

<8,2,0>
  VGPRs: 232
  Correctness: VALID
  sweep:   819.07 / 821.18 TFLOPS
  confirm: 822.22 / 820.29 / 822.33 / 820.92 TFLOPS
           821.02 / 819.89 / 820.27 / 820.10 / 821.36 / 819.91 TFLOPS
  final source build: 820.22 / 819.01 / 819.32 TFLOPS

<8,3,0>
  VGPRs: 232
  Correctness: VALID
  814.72 / 817.51 TFLOPS

<6,4,0>
  VGPRs: 232
  Correctness: VALID
  777.57 / 820.81 TFLOPS

<4,4,0>
  VGPRs: 245
  Correctness: VALID
  815.59 / 741.73 TFLOPS

<6,3,0>
  VGPRs: 232
  Correctness: VALID
  819.50 / 778.18 TFLOPS
```

结论：`<8,2,0>` 有小幅稳定收益，保留：

```cpp
sched_barrier_pairs_scale<8, 2, 0>();
```

## 方案 D: packed uint32 scale load

### 动机

方案 1/方案 C 每个 lane 只加载自己需要的 1 个 byte scale：

```cpp
using vtype_sfa = vector_t<unsigned char, T::E_M>;
using vtype_sfb = vector_t<unsigned char, T::E_N>;
```

优点是每 lane 只读必要数据，缺点是 generated ISA 中会出现大量 `buffer_load_ubyte`。方案 D 反过来让每个 lane 读取当前 128-K MFMA 覆盖的 4 个 K-group scale，使用更高效的 dword load：

```cpp
using vtype_sfa = vector_t<unsigned int, T::E_M>;
using vtype_sfb = vector_t<unsigned int, T::E_N>;
```

### 实现

host/global scale layout 不变，仍是 byte array：

```text
SFA: [M, num_groups_k]
SFB: [N, num_groups_k]
```

kernel 里从 byte base pointer 转成 `uint32_t*`：

```cpp
using D_SF = unsigned char;
using D_SF_PACK = unsigned int;

auto g_sfa = make_gmem(reinterpret_cast<const D_SF_PACK*>(
    reinterpret_cast<const D_SF*>(kargs.ptr_sfa)
    + batch_id * kargs.stride_sfa_batch
    + row * kargs.stride_sfa));
```

因为 host 侧 `K` 必须是 `B_K=128` 的整数倍，`stride_sfa/stride_sfb = K / GROUP_K` 一定是 4 的整数倍，row base 可以按 packed dword 访问。

layout 使用 packed stride：

```cpp
auto u_sfa = make_layout_sfa_scale<T>(
    lane_id, wave_id_m,
    kargs.stride_sfa / T::SCALE_KGROUPS_PER_MFMA);

auto u_sfb = make_layout_sfb_scale<T>(
    lane_id, wave_id_n,
    kargs.stride_sfb / T::SCALE_KGROUPS_PER_MFMA);
```

offset 从 byte 版：

```cpp
base + tile_k * 4 + lane_group
```

变成 packed 版：

```cpp
base_packed + tile_k
```

helper 内按 lane group 抽取当前 byte：

```cpp
const int scale_shift_a = (lane_id / T::W_M) * 8;
const int scale_shift_b = (lane_id / T::W_N) * 8;

const int scale_a = static_cast<int>((v_sfa[MR] >> scale_shift_a) & 0xffu);
const int scale_b = static_cast<int>((v_sfb[NR] >> scale_shift_b) & 0xffu);
```

### 结果

资源：

```text
TotalSGPRs: 65
VGPRs: 233
AGPRs: 0
ScratchSize: 0
SGPR Spill: 0
VGPR Spill: 0
Occupancy: 2 waves/SIMD
LDS Size: 135168 bytes/block
```

Correctness：

```text
unit scale 256x256x256:
  errors=0/65536
  max_diff=0.000095
  [Overall] ALL BATCHES VALID

random scale 256x256x256:
  errors=0/65536
  max_diff=0.003906
  [Overall] ALL BATCHES VALID

K-pattern 512x512x512:
  errors=0/262144
  max_diff=0.006836
  [Overall] ALL BATCHES VALID
```

4096 性能：

```text
0.1171 ms, 1173.50 TFLOPS
0.1172 ms, 1172.34 TFLOPS
0.1166 ms, 1178.87 TFLOPS
0.1170 ms, 1174.51 TFLOPS
0.1171 ms, 1174.03 TFLOPS

final source build:
0.1173 ms, 1172.10 TFLOPS
0.1167 ms, 1177.69 TFLOPS
```

结论：方案 D 是明确正收益。虽然每 lane 读取的 scale byte 数从 6 bytes 增加到 24 bytes，但 global load 形态从 byte load 变成 dword load 后，性能从方案 C 的约 `819-821 TFLOPS` 提升到约 `1172-1179 TFLOPS`，保留。

## 当前参考差距

参考 kernel：

```text
/root/workspace/gcnasm/opus_gemm/fp8_gemm:
  普通 FP8 GEMM，约 1.6-1.85 PFLOPS

/root/workspace/gcnasm/opus_gemm/block_scale_gemm:
  FP8 + fp32 block scale GEMM，约 1.84-1.89 PFLOPS

当前 MXFP8 E8M0 scaled-MFMA:
  约 1.17-1.18 PFLOPS
```

当前差距从方案 1 后的约 `2x` 缩小到约 `1.4-1.6x`。

## 后续路线

剩余主要方向是普通 MFMA + 软件 E8M0 scale。

当前硬件 scaled-MFMA 一次处理：

```text
16 x 16 x 128
```

MXFP8 `GROUP_K=32`，所以不能直接用普通 `K=128` FP8 MFMA 后乘一个 scale。可行软件路线是把 K=128 拆成 4 个 K=32 partial：

```text
for kg in 0..3:
  ordinary FP8 MFMA over K-group kg
  partial *= scale_a[kg] * scale_b[kg]
  acc += partial
```

风险：

```text
1. 需要可用且高效的 K=32 普通 FP8 MFMA 路径。
2. pipeline 和 layout 需要较大改动。
3. scale/add VALU 会增加指令量。
4. correctness 要重新覆盖 unit/random/K-pattern/multi-K cases。
```

这个方向潜在收益大，但实现风险也最高。除非继续追到 FP8/block_scale 参考 kernel 的 1.6-1.9 PFLOPS 区间，否则当前 packed uint32 scaled-MFMA 路线已经是稳定可用版本。
