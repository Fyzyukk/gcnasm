# MXFP8 GEMM 优化记录：1.878 P 到 2.15 P

本文记录 `8192 x 8192 x 8192, batch=1` 下，从用户标记的 **1.878 P scale 去重版本** 到当前 **host consumer-major prepack + cooperative dword global-to-LDS** 版本的实际变化、收益来源和剩余瓶颈。

当前 2.15 P 源码已经冻结：

```text
commit: 201ffc0d0d89938eb0d00d9195fd3cacbb6fa563
tag:    perf-2p15-consumer-major-coop-lds-20260824
```

可以用独立 worktree 恢复，不覆盖当前实验代码：

```bash
git worktree add ../mxfp8_scale_2p15 \
  perf-2p15-consumer-major-coop-lds-20260824
```

## 1. 一句话结论

1.878 P 版本已经做到了 **每个 K tile 的 scale 只从 global 读取一次**。当前版本没有继续减少 scale 字节数；两者每个 `256 x 256 x 128` workgroup K tile 都只读取：

```text
SFA: 256 rows x 4 E8M0 bytes = 1024 bytes
SFB: 256 rows x 4 E8M0 bytes = 1024 bytes
total:                         2048 bytes/tile
```

当前版本新增的核心优化是：

```text
1.878 P:
row-major global scale
  -> buffer_load_dword 到 VGPR
  -> 4 x ds_write_b8 在 GPU 内转置
  -> consumer-major LDS

当前 2.15 P:
host 预排成 consumer-major global scale
  -> cooperative buffer_load_dword ... lds
  -> consumer-major LDS
```

因此收益主要来自：

- 相邻 lane 的 scale dword 地址变为连续地址，global load 更容易合并；
- 删除中间 `v_gscale`；
- 删除每个 loader lane、每个 tile 的 4 条 `ds_write_b8`；
- 删除 global→VGPR→LDS 转发链上的 scale 专用等待和数据依赖；
- 保持 LDS 跨 wave 复用，因此没有退化成每个 consumer wave 重复读取 global scale。

## 2. 哪些东西没有变化

为了正确判断收益，下面这些不能算作当前版本新增的优化：

| 项目 | 1.878 P 版本 | 当前版本 |
|---|---:|---:|
| Block tile | `256 x 256 x 128` | 相同 |
| Workgroup | 8 waves / 512 threads | 相同 |
| Wave grid | `T_M x T_N = 4 x 2` | 相同 |
| Scaled MFMA | `16 x 16 x 128` | 相同 |
| Scale global payload | 2 KB/K tile | 相同 |
| Scale global 唯一加载 | 已实现 | 保持 |
| Scale consumer cache | 双缓冲 LDS | 保持 |
| 计算调度粒度 | 64 x 64 workgroup 子块 | 保持 |
| A/B LDS padding | 32 | 相同 |
| Occupancy | 2 waves/SIMD | 相同 |

也就是说，2.15 P 并不是通过少算、少取 scale 字节或者删除 scale LDS 得到的。

## 3. 1.878 P 版本的数据路径

原始数学布局是：

```text
SFA[batch][M][K / 32]
SFB[batch][N][K / 32]
```

一个 `16x16x128` scaled MFMA 覆盖四个 32-K scale group，因此 loader lane 从某一行读取的 dword 内容是：

```text
[q0, q1, q2, q3]
```

但是 consumer 需要的 LDS 顺序是：

```text
SFA: [consumer_wave_m][r][q][m_call]
SFB: [half_n][consumer_wave_n][r][q][n_call]
```

也就是一个 consumer lane 希望一个 dword 中连续放置四次 MFMA call 的 scale，而不是同一行的四个 `q`。因此旧路径必须在 GPU 内做一个局部 `4 x 4` 转置：

```text
buffer_load_dword -> v_gscale = [q0, q1, q2, q3]

ds_write_b8 offset 0
ds_write_b8 offset 4
ds_write_b8 offset 8
ds_write_b8 offset 12
```

这正是旧 ISA 中看到的四条 byte store。它已经避免了 scale 的重复 global load，但仍有两个问题：

1. 相邻 lane 通常读取不同行，8192³ 时原始 row stride 是 `K / 32 = 256` bytes，lane 间 dword 地址不连续；
2. 每个 dword 必须先占一个 VGPR，再拆成四个 byte 写入 LDS。

## 4. 当前 consumer-major host prepack

### 4.1 SFA

host 把 SFA 每个 tile 排成：

```text
[consumer_wave_m=4][r=16][q=4][m_call=4]
```

原始行号映射为：

```text
m = m_block * 256
  + m_call * (T_M * W_M)
  + consumer_wave_m * W_M
  + r
```

其中：

```text
T_M * W_M = 4 * 16 = 64
m_call = 0..3
```

loader lane 映射为：

```text
r = lane_id / 4
q = lane_id % 4
```

所以每个 lane 的一个 dword 正好是：

```text
[m_call0, m_call1, m_call2, m_call3]
```

四个 `wave_id_n == 0` 的 wave 分别用 `wave_id_m=0..3` 加载一个 consumer-wave slice。每个 wave：

```text
64 lanes x 4 bytes = 256 bytes
```

四个 wave 合计正好加载 1024-byte SFA tile。

### 4.2 SFB

host 把 SFB 每个 tile 排成：

```text
[half_n=2][consumer_wave_n=2][r=16][q=4][n_call=4]
```

原始行号映射为：

```text
n = n_block * 256
  + half_n * 128
  + n_call * (T_N * W_N)
  + consumer_wave_n * W_N
  + r
```

四个 `wave_id_n == 1` 的 loader wave 使用：

```text
half_n         = wave_id_m / 2
consumer_wave_n = wave_id_m % 2
r              = lane_id / 4
q              = lane_id % 4
```

每个 lane 的 dword 是四个连续 `n_call`，四个 wave 合计加载 1024-byte SFB tile。

### 4.3 为什么相邻 lane 现在可以合并

SFA packed offset 是：

```text
(((consumer_wave_m * 16 + r) * 4 + q) * 4 + m_call)
```

lane 从 `q=0` 走到 `q=1` 时，dword base 正好增加 4 bytes。一个 wave 的 64 个 lane 因而覆盖一个连续的 256-byte 区域，而不是以原始 row stride 跨行读取。

SFB 使用同样的规则，只是在最前面增加 `(half_n, consumer_wave_n)` 两维。

## 5. 当前 cooperative global-to-LDS 路径

### 5.1 Producer 分工

```text
wave_id_n == 0 的 4 个 wave：搬 SFA
wave_id_n == 1 的 4 个 wave：搬 SFB
```

每个线程只执行一个 4-byte scale 搬运：

```cpp
async_load<4>(
    g_sfa, s_sfa.ptr,
    u_lsfa,
    u_lsfa + ssfa_offset(stage),
    gsfa_offset(tile));
```

SFB 同理。生成 ISA 是带 `lds` destination 的：

```text
buffer_load_dword ..., ..., lds
```

数据不再经过一个普通目的 VGPR，也不需要随后四条 `ds_write_b8`。

### 5.2 Consumer 读取

所有 consumer wave 从 LDS 读取：

```cpp
r_sfa   = load<4>(s_sfa, u_rsfa   + ssfa_offset(stage));
r_sfb_0 = load<4>(s_sfb, u_rsfb_0 + ssfb_offset(stage));
r_sfb_1 = load<4>(s_sfb, u_rsfb_1 + ssfb_offset(stage));
```

一个 SFA dword 包含四个 `m_call`，由 `op_sel_a=0..3` 选择；每个 SFB dword 包含四个 `n_call`，由 `op_sel_b=0..3` 选择。

### 5.3 为什么仍然保留 SSFA/SSFB

LDS 在这里不是为了再次转置，而是为了 **跨 wave 共享**：

- SFA 由四个 `wave_id_n==0` wave 各加载一次，但同一个 SFA slice 要给两个 N consumer wave 使用；
- SFB 由四个 `wave_id_n==1` wave 各加载一次，但同一个 SFB slice 要给四个 M consumer wave 使用；
- LDS 加一次 workgroup barrier 后，所有 8 个 consumer wave 都能读取各自需要的 SFA 和 SFB。

如果直接改成 global→VGPR，每个 consumer wave 为了同时得到 A/B scale 会重复 global load，或者需要更复杂的跨 wave 通信；之前的 global→VGPR 实验也没有超过 cooperative LDS 版本。

## 6. Pipeline 调度变化

当前 pipeline 是 tile-level ping-pong：

```text
Prologue:
  tile 0 scale/A/B -> LDS stage 0
  wait VMEM + wait LDS + workgroup barrier

Main tile t:
  尽早发射 tile t+1 scale/A/B -> LDS stage^1
  从 LDS stage 读取 tile t 的 SFA/SFB0/A0/B0
  提前发射 SFB1 LDS read
  以 64x64 子块交错执行前半 N 的 MFMA 和 A1 LDS read
  读取 B1，执行后半 N 的 MFMA
  wait next-tile VMEM/LDS
  一个 workgroup barrier 发布下一 stage

Epilogue:
  只消费最终 resident tile，不再发射下一 tile VMEM
```

当前相对最初 direct-LDS 实现还有一个小调度改进：SFB1 在第一半 N 的 16 条 MFMA 之前读取，让这段计算隐藏其 LDS latency。生成 ISA 中 A1/B1 的等待变成逐步收紧，而不是把所有 LDS read 都集中阻塞。

## 7. ISA 对比

下面是保留的 loader-transpose ISA 与当前 ISA 的静态计数。静态计数包括 prologue/main 两份控制流代码，因此 `ds_write_b8=9` 不等于每个 tile 执行九次；旧版本运行时每个 loader lane 对一个 scale dword 执行四次 byte store。

| ISA/资源 | 1.878 P 路径 | 当前路径 | 变化 |
|---|---:|---:|---:|
| `v_mfma_scale` | 64 | 64 | 不变 |
| `buffer_load*` | 18 | 18 | 数量不变，scale destination 改为 LDS |
| scale `buffer_load_dword ... lds` | 0 | 2 | 新增两条静态分支路径 |
| `ds_write_b8*` | 9 | 0 | 完全删除 GPU scale 转置 |
| `ds_read_b32` | 6 | 6 | 不变 |
| `ds_read_b128` | 48 | 48 | 不变 |
| `s_waitcnt` | 17 | 15 | 减少 2 条 |
| `s_nop` | 20 | 18 | 减少 2 条 |
| next-free VGPR | 216 | 214 | 小幅下降 |
| LDS bytes/block | 139264 | 139264 | 不变 |
| scratch spill | 0 | 0 | 不变 |
| occupancy | 2 waves/SIMD | 2 waves/SIMD | 不变 |

这张表也说明：主要收益不是 occupancy 提升，而是 scale global 访问形状和 producer 路径缩短。

## 8. 正确性证据

当前保存点已经通过随机 E8M0 scale：

```bash
HIP_VISIBLE_DEVICES=7 ./build/gemm_a8w8_mxfp8_scale.exe \
  -m 512 -n 512 -k 512 -b 1 -v 1

HIP_VISIBLE_DEVICES=7 ./build/gemm_a8w8_mxfp8_scale.exe \
  -m 512 -n 512 -k 1024 -b 2 -v 1
```

两项均为：

```text
[Overall] ALL BATCHES VALID
```

第二项覆盖了多个 K tile 和多个 batch，可验证 tile/batch packed stride 以及 ping-pong stage 切换。

## 9. 性能结果

统一命令：

```bash
HIP_VISIBLE_DEVICES=<4..7> ./build/gemm_a8w8_mxfp8_scale.exe \
  -m 8192 -n 8192 -k 8192 -b 1 -v 0
```

2026-08-24 后四张空闲 GPU 的当前版本结果：

| GPU | avg_time | Throughput |
|---:|---:|---:|
| 4 | 0.5297 ms | 2.0759 P |
| 5 | 0.5155 ms | 2.1328 P |
| 6 | **0.5085 ms** | **2.1622 P** |
| 7 | 0.5158 ms | 2.1318 P |

相对用户记录的 1.878 P：

```text
best throughput gain = 2.1622 / 1.878 - 1 = 15.1%
```

在 GPU 5 上做过同卡交错对比，避免把卡间差异算成优化收益：

```text
旧 global->VGPR->4xds_write_b8: 1.903-1.959 P
consumer-major direct-to-LDS:    2.143-2.157 P
当前 progressive-wait 版本:      best 2.167 P
```

注意：这里测量的是 200 次 warmup 后、100 次 kernel 的 HIP event 平均时间。host prepack 和 H2D copy 不在 kernel 时间内。如果 scale 每次 GEMM 都变化，端到端评估必须另外计入 prepack；如果 packed weight/scale 能复用，kernel-only 数字就是主要指标。

## 10. 当前尚未解决的瓶颈

最新 ATT 位于：

```text
trace_block_scale_consumer_direct_0824/
```

主要观察：

- 当前 stage 开始的 LDS wait 平均约 83 cycles；
- A1 progressive waits 已经很小；
- B1 progressive waits 合计约 49 cycles；
- tile 尾部 `vmcnt(0)/lgkmcnt(0)` 平均约 197 cycles；
- 最大且波动最明显的空洞是 workgroup barrier 前后 wave 到达不均衡；
- MFMA 区域本身约每 wave 28–32 cycles 稳定发射。

因此 scale 路径已经从主要问题降为次要问题。下一阶段应保持当前 scale 数据路径不动，重点优化：

1. 更早发射下一 K tile 的 A/B VMEM；
2. 将 A/B LDS read 更细粒度地穿插到 64x64 MFMA 组之间；
3. 缩短 tile 尾部 `vmcnt(0)` 暴露延迟；
4. 减少 8 个 wave 到达唯一 tile barrier 的时间差；
5. 每次变体都在 GPU 6 与保存点做交错测试，并重新验证随机 scale。

从当前最好 `0.5085 ms / 2.1622 P` 到 3 P，8192³ 的目标时间是：

```text
2 * 8192^3 / 3e15 = 0.3665 ms
```

仍需把 kernel 时间降低约 28%，所以仅继续微调 scale 指令不足以达到目标，后续优化必须主要作用于 A/B pipeline 和 barrier stall。

