# MXFP8 GEMM 优化记录：1.878 P 到 2.6528 P，以及 3 P / 32x32x64 探索

本文记录 `8192 x 8192 x 8192, batch=1` 下，从用户标记的 **1.878 P scale 去重版本**
到 **host consumer-major prepack + cooperative global-to-LDS** 的 2.15 P 冻结点，以及之后
8-wave 主线推进到正常 MI350X 上 2.6528 P 的实验、收益来源和剩余瓶颈。文档中约
2.30 P 的数据来自 MI355X 节点；该机器当前的验收目标是稳定超过 2.3 P，不能用健康
MI350X 的 2.6528 P 作为它的本机门槛。2026-08-28 新保留的 asymmetric-B 候选在
MI355X 上达到中位 `0.4758 ms / 2.3109 P`。

当前 2.15 P 源码已经冻结：

```text
commit: 201ffc0d0d89938eb0d00d9195fd3cacbb6fa563
tag:    perf-2p15-consumer-major-coop-lds-20260824
```

在该冻结基线上继续比较过 LDS-head split、B1 lookahead、two-tile-ahead 和
grouped-M。最终只保留实测最优的 `a0-l1`：原单 tile-ahead pipeline，加固定的
LDS 首段精确 wait split。实验宏和其他实现分支均已从正式源码删除。

上面描述的是第 13 节形成时的冻结状态。之后工作树曾重新加入一组实验宏，并完成
第 14～18 节记录的候选筛选。2026-08-27 收敛后，rolling 获胜配置已经固化；第 19 节
记录的是异常节点上约 2.24 P 的 u4 保存点，第 20 节继续到约 2.30 P。随后 fixed-B
prefetch x4 在健康 MI350X 上达到 2.6528 P，并以独立源码和 target 保留。默认
`make scale` 仍构建 rolling 基线，`make scale_fixed_b_prefetch_4` 构建原 fixed-B
基线；MI355X 上当前最快的独立 target 是 `make scale_fixed_b_asym_b_read2`。
文档中的其他历史 `build_*` 名称只表示实验记录，不能据此判断候选仍可运行。

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

## 11. 2026-08-24：GPU 忙时的离线候选

本节只记录已经完成的代码、编译和正确性检查。采样时机器上其他任务仍在运行，
因此小尺寸命令打印出的吞吐率全部作废，尚未给这些候选下性能结论。
本节中的候选均为历史实验；第 13 节记录最终选择和当前代码状态。

### 11.1 grouped-M grid（已撤销）

曾实验用二维 grid 将相邻 workgroup 改为先遍历短 M strip，以缩短 B/B-scale 的
cache 重用距离。受污染环境下，在相同 `b1+l1` pipeline 上交错三轮，原始一维映射
平均为 `2.1594 P`，group 8 平均仅 `1.9724 P`，退化约 8.7%。该差距远大于当前
测量噪声，因此 grouped-M 实验已淘汰，相关编译选项、host 二维 grid 和 kernel
重映射代码均已删除。所有保留版本固定使用冻结版的一维 row-major 映射：

```text
grid = (num_tiles_m * num_tiles_n, 1, batch)
block_m = block_id_x / num_tiles_n
block_n = block_id_x % num_tiles_n
```

### 11.2 two-tile-ahead rolling pipeline 原型（已删除）

新增 `SCALE_TWO_AHEAD`，默认 0 保持冻结 pipeline：

- `0`：原始单 tile-ahead ping-pong；
- `1`：当前 tile 的全部 A0/A1/B0/B1 读入 VGPR 后立即释放 LDS stage；
- `2`：先等待 A0/B0，执行 8 条 MFMA 隐藏其余 LDS read，再释放 stage。

mode 1/2 的 steady-state 时序为：

```text
LDS 中已有 t，另一个 stage 正在接收 t+1
  -> 当前 t 的全部操作数进入 VGPR
  -> barrier，当前 stage 可复用
  -> t+2 直接 global-to-LDS 写回刚释放的 stage
  -> 计算 t
  -> vmcnt(9)，只等待较老的 t+1，允许 9 条 t+2 VMEM 保持 outstanding
  -> barrier，发布 t+1
```

每个 wave、每个 tile 恰好有 9 条 VMEM（1 条 SFA/SFB + 8 条 A/B），所以
`vmcnt(9)` 的年龄窗口与实际 ISA 一致。mode 2 的主循环进一步确认为：

```text
14 条早期 LDS read
13 条较晚 LDS read
lgkmcnt(13)
8 x MFMA
lgkmcnt(0) + stage-release barrier
9 x t+2 VMEM
24 x MFMA
vmcnt(9) + publish barrier
```

代价是同时保留两个 B half，VGPR 从 214 增至 245；仍未 spill，编译器仍报告
2 waves/SIMD：

| pipeline | VGPR | compiler TotalSGPR | next-free SGPR | LDS | spill |
|---:|---:|---:|---:|---:|---:|
| 0 | 214 | 43 | 96 | 139264 B | 0 |
| 1/2 | 245 | 54 | 96 | 139264 B | 0 |

这个原型的收益条件很明确：额外一次、且到达更整齐的 stage-release barrier，
必须小于它从原约 197-cycle tile-tail VMEM wait 中隐藏掉的时间。mode 2 用前 8 条
MFMA 覆盖后 13 条 LDS read，比 mode 1 更可能满足这个条件。

曾尝试用 split-phase workgroup barrier 把到达等待藏在 MFMA 下，但 ROCm clang
对 gfx950 明确报错：`s_barrier_signal`/`s_barrier_wait` 需要 `gfx12-insts`。
因此没有用裸汇编强行绕过架构限制，该变体已淘汰。

### 11.3 已完成的正确性与构建检查

以下随机 E8M0 scale 用例均为 `ALL BATCHES VALID`：

```text
pipeline=1: M=512, N=512, K=384, batch=2
pipeline=2: M=512, N=512, K=128/256/384, batch=1/2
```

它们覆盖 1/2/3 个 K tile、prologue 分支、steady-state `t+2` 路径、epilogue
和 batch stride。由于 GPU 有其他负载，这些命令附带打印的
小尺寸性能数字不可使用。

历史实验曾用独立构建目录生成候选，避免 make 因编译参数变化而复用旧 object：

```bash
make scale_variant SCALE_TWO_AHEAD=0
make scale_variant SCALE_TWO_AHEAD=1
make scale_variant SCALE_TWO_AHEAD=2
```

产物分别位于 `build/variants/a<ahead>/`。

最终实测后 `a1/a2` 均退化，`scale_variant` target 和 `SCALE_TWO_AHEAD` 开关已从
当前 Makefile/源码删除；以上命令仅保留为实验记录。

### 11.4 GPU 空闲后的测试顺序

在同一张 GPU 上以 ABBA 顺序重复 8192³，保留原始每次输出；只有稳定超过当前
同卡上界约 2.167 P 才接受。分别比较 `a0/a1/a2`；任何候选进入正式保存点前，都应重新跑
`512x512x1024, batch=2, verify=1` 的随机 scale 回归。

## 12. 2026-08-24：partial lookahead 与 LDS head split

本节仍是在 GPU 有其他负载时完成，只记录旧 trace、PMC、静态 ISA 和小尺寸正确性。
没有把本节任何运行打印出的吞吐率当作性能结论。

### 12.1 补读保存版 PMC

保存版的 rocprof 数据库仍在
`/tmp/rocprof_scale_2p15_counters_0824/2af3954f34aa/673548_results.db`，对应
`.rocprofv3/315982-673548-counter_values.dat`。301 次 dispatch 的计数为：

| counter | average | min | max |
|---|---:|---:|---:|
| `MfmaUtil` | 52.7687% | 49.4125% | 56.4529% |
| `VALUUtilization` | 98.6267% | 98.6267% | 98.6267% |
| `OccupancyPercent` | 21.8455% | 21.0958% | 22.6076% |
| `MemUnitStalled` | 0.2145% | 0.1688% | 0.2329% |
| `LdsUtil` | 22.2618% | 20.8459% | 23.8161% |
| `LDSBankConflict` | 1.2368% | 1.1581% | 1.3231% |

这次 profile 本身受机器负载影响，绝对时间不能用来接受候选；但低 LDS conflict、
低 `MemUnitStalled` 与约 53% 的 MFMA 利用率支持原 ATT 的判断：优先处理低 occupancy
下的依赖空洞和 wave 到达错峰，而不是先改 LDS padding。

旧 ATT 的主循环命中数允许把 aggregate stall 换算为每 wave/tile：

```text
head lgkmcnt(0):        167100 / 2016 =  82.89 cycles
B1 progressive waits:   98312 / 2016 =  48.77 cycles
tile-tail vmcnt(0):     396716 / 2016 = 196.78 cycles
barrier residence:     1353264 / 4032 = 335.63 cycles
```

`barrier` 的 hitcount 口径与普通单发指令不同，因此最后一项只用于定位，不与其他
三项直接相加。

### 12.2 B1-only three-slot lookahead（已删除）

新增 `SCALE_B1_LOOKAHEAD=1`。它没有像 `SCALE_TWO_AHEAD` 那样把当前 tile 的全部
A/B 保存在 VGPR，也不增加 stage-release barrier。它只为主循环中最后发射、最容易
拖住 tile-tail wait 的 B1 half 增加第三个 LDS 槽：

```text
prologue:
  tile 0 全部 9 条 VMEM
  tile 1 的 2 条 B1 VMEM
  vmcnt(2) -> barrier 发布 tile 0

steady tile t:
  tile t+1 的 scale/A0/B0/A1，共 7 条 VMEM
  tile t+2 的 B1，共 2 条 VMEM
  compute tile t
  vmcnt(2) -> barrier 发布 tile t+1
```

B1 的三个物理槽按 `slot 1 -> slot 3 -> slot 4` 滚动，B0 仍使用原来的两个槽。
因此每轮开始时，B1(t+1) 已经比其余输入早一个完整 K tile 发射。主循环最后一轮
会把最后一个合法 B1 重复写到不再使用的 spare slot，使 steady loop 始终保留恰好
两条最年轻 VMEM，并去掉热循环里的条件分支。额外流量是每 workgroup 一次 16 KiB
B1 half；在 64 个 K tile 下约占该 workgroup A/B 读取量的 0.4%。

新增 LDS 为一个 padded B half：

```text
16 * (1024 + 32) = 16896 bytes
139264 + 16896    = 156160 bytes
160 KiB - 156160 =   7680 bytes headroom
```

当前 gfx950 ISA 已确认 steady state 的 9 条 VMEM 顺序为 `1 scale + 6 A/B + 2
future-B1`，尾部是单条 `s_waitcnt vmcnt(2) lgkmcnt(0)`。相对冻结版每个热循环只
增加 9 条动态指令，没有额外 barrier。

### 12.3 精确拆分首段 LDS wait

候选名 `a0-l1`。冻结版在每轮开头发射 14 条当前 tile LDS read 后
直接 `lgkmcnt(0)`；生成 ISA 中前两个 MFMA 实际只依赖最老的 10 条 read。新模式
把 SFB1 作为第 15 条 read 提前发射，并生成：

```text
15 LDS reads
lgkmcnt(5)          # 最老 10 条完成，首个 MFMA pair 的输入已就绪
2 MFMA
4 A1 LDS reads
lgkmcnt(5)          # 仅退休旧的 4 条 B0，保留 SFB1 + A1
其余 MFMA 与原 progressive waits
```

为防止寄存器分配变化后 machine scheduler 交换 A0/B0 的 LDS 顺序，该模式在两组
read 之间放了 compile-time scheduling barrier；它不生成硬件指令。独立候选仅比
冻结版多 1 条静态/动态 `s_waitcnt`，VGPR、SGPR、LDS 和 occupancy 完全不变。

### 12.4 静态资源与正确性

| candidate | VGPR | compiler TotalSGPR | next-free SGPR | LDS | spill | occupancy |
|---|---:|---:|---:|---:|---:|---:|
| `a0` frozen | 214 | 43 | 96 | 139264 B | 0 | 2 waves/SIMD |
| `a0-l1` | 214 | 43 | 96 | 139264 B | 0 | 2 waves/SIMD |
| `a0-b1` | 213 | 48 | 96 | 156160 B | 0 | 2 waves/SIMD |
| `a0-b1-l1` | 213 | 48 | 96 | 156160 B | 0 | 2 waves/SIMD |

候选阶段曾用编译宏隔离这些互不兼容的路径。最终选择 `a0-l1` 后，所有实验宏、
`static_assert` 和无效分支均已删除，LDS-head split 已成为唯一正式实现。

随机 E8M0 scale 已验证：

```text
a0-l1:     M=N=256, K=128/256/384/512, batch=2
a0-b1:     M=N=256, K=128/256/384/512, batch=2
a0-b1-l1:  M=N=256, K=128/256/384/512, batch=2
a0:        M=N=512, K=1024, batch=2（撤销 grouped-M 后）
```

全部为 `ALL BATCHES VALID`。

## 13. 2026-08-24：最终收敛为 a0-l1

GPU 空闲后在物理 GPU 6 上统一运行 `8192 x 8192 x 8192, batch=1`。每次包含
200 次 warmup 和 100 次计时，三轮交错结果为：

| candidate | average throughput | average time | relative to a0 |
|---|---:|---:|---:|
| `a0` | 2.1442 P | 0.5128 ms | baseline |
| `a0-l1` | **2.1564 P** | **0.5099 ms** | **+0.57%** |
| `a0-b1` | 2.1394 P | 0.5139 ms | -0.22% |
| `a0-b1-l1` | 2.1493 P | 0.5116 ms | +0.24% |
| `a1` | 2.0570 P | 0.5345 ms | -4.07% |
| `a2` | 2.1109 P | 0.5209 ms | -1.55% |
| historical `g8-a0-b1-l1` | 1.9593 P | 0.5612 ms | -8.62% |

因此正式源码只保留 `a0-l1`。具体收敛内容：

- 保留冻结版的一维 row-major grid 和单 tile-ahead ping-pong pipeline；
- 固定保留两处 `lgkmcnt(5)` 以及保证 LDS read 顺序的零机器码 scheduling barrier；
- 删除 grouped-M、B1 three-slot lookahead 和 two-tile-ahead 的代码与构建开关；
- 恢复单一 `make scale` 构建，不再提供实验 variant target。

收敛后的正式二进制与旧 `a0-l1` gfx950 汇编逐行一致，差异仅为编译器生成的 CUID。
静态资源仍为 214 VGPR、43 SGPR、139264 B LDS、零 spill、2 waves/SIMD。
随机 E8M0 scale 的 `512 x 512 x 1024, batch=2` 回归为
`ALL BATCHES VALID`。正式二进制随后三轮性能为：

```text
2.1487 P / 0.5117 ms
2.1522 P / 0.5109 ms
2.1575 P / 0.5096 ms
```

## 14. 2.15 P 之后的测量规则与 u4 收敛配置

后续实验继续固定以下口径：

```text
GPU:       physical GPU 6（测试前确认无其他 KFD 进程）
problem:   M=N=K=8192, batch=1
timing:    每次进程内 200 warmup + 100 timed iterations
compare:   同卡 ABBA，正反顺序交错
accept:    正确性、零 spill，并且稳定收益至少约 0.2%
```

绝对吞吐会随卡频和时间窗变化，因此候选判断以同一时间窗内的配对差值为主，不能把
不同小时、不同 GPU 或受外部任务污染的绝对 P 数直接相减。曾出现的错误
`split-A1` 约 2.25 P 和 GPU 被占用时的样本均已作废。

筛选阶段最终胜出的组合是：

```text
SCALE_SCALE_LOAD_BYTES=16
SCALE_VMEM_LDS_INTERLEAVE=1
SCALE_PREFETCH_B1_READS=4
SCALE_C_STORE_AUX=2
SCALE_LOOP_UNROLL=4
```

筛选阶段对应的构建名称为：

```text
build_scale16_inter1_b1r4_caux2_u4/
build_repro_current_u4/
```

收敛清理后只保留 `build_repro_current_u4/` 作为参考构建；其余历史实验构建均可由
对应参数重新生成。

重新编译的 `build_repro_current_u4` 与保存的 u4 汇编逐指令一致，差异仅为 CUID。
2026-08-27 完成源码清理后，上述值不再是公开编译开关，而是正式实现本身：
默认 `make scale` 无需任何 `-DSCALE_*` 参数。清理版资源保持 228 VGPR、
compiler TotalSGPR 64、139264 B LDS、零 scratch、2 waves/SIMD。

## 15. 可靠收益链

下面的百分比来自各自的同卡配对窗口，不应机械相乘；表格的用途是说明哪些变化有
独立、可重复的正收益。

| change | paired result | resource/result | decision |
|---|---:|---|---|
| `a0-l1` LDS head split | `+0.57%` | 214 VGPR | 保留 |
| B-first VMEM order | `2.1603 -> 2.1763 P`, `+0.74%` | 资源不变 | 保留 |
| VMEM/LDS interleave | 初筛相对 B-first 约 `+0.68%` | 213 VGPR；ATT 支持 | 保留 |
| B1 pre-read `r4` | 相对 interleave 约 `+0.45%`，5/5 组胜 | 229 VGPR | 保留 |
| C-store `nt` (`aux2`) | `2200.49 -> 2211.25 TFlops`, `+0.489%`, 10/10 胜 | 资源不变 | 保留 |
| scalar scale-LDS dst | raw `+0.335%`，trimmed `+0.286%`, 10/10 胜 | 229 -> 228 VGPR | 被后续 16B loader 覆盖 |
| 16B scale producer | `0.49432 -> 0.49241 ms`, 约 `+0.39%`, 10/10 胜 | 228 VGPR | 保留 |
| K-loop unroll 4 | `0.49510 -> 0.49207 ms`, 约 `+0.61%` | 228 VGPR、零 spill | 保留 |

### 15.1 B-first 与 LDS interleave

原循环先发 scale/A，再发 B。B 的跨 block cache 复用较弱，更容易成为最后完成的
global-to-LDS 请求。把顺序改成：

```text
B0 -> B1 -> 当前 tile 的早期 LDS reads -> scale -> A0 -> A1
```

让冷 B 请求最早开始老化，同时让后续较容易命中 cache 的 scale/A 请求覆盖当前 tile
的 LDS latency。新 ATT 中：

```text
两个 head lgkmcnt(5): 约 82.9 -> 4 cycles/tile
B1 progressive wait: 约 48.8 -> 40.7 cycles/tile
barrier residence:   约 335.6 -> 258.1 cycles/tile
tile-tail VMEM wait: 约 196.8 -> 207.9 cycles/tile
```

尾部 VMEM 略增，但 head wait 和 wave 到达差下降更多，所以净性能提高。

### 15.2 B1 提前读取四条

`SCALE_PREFETCH_B1_READS=2/4/6/8` 相对 interleave 均有正向结果，五组配对约为：

```text
r2: +0.27%
r4: +0.45%
r6: +0.29%
r8: +0.42%
```

`r4` 与 `r8` 的十轮直接对比只差约 0.008%，所以保留 VGPR 更低的 `r4`：229 对
244。对应 ATT 中 B1 progressive wait 已从约 41 cycles/tile 降到约
0.8 cycles/tile，tile-tail VMEM wait 约从 208 降到 153 cycles/tile。

### 15.3 C-store non-temporal

`SCALE_C_STORE_AUX=2` 给最终 C 写回添加 non-temporal hint。严格 ABBA 为 10/10 胜，
平均 `+0.489%`。PMC 同时观察到：

```text
L2 miss:          10.682 M -> 10.503 M  (-1.67%)
MemUnitStalled:     0.2296% -> 0.1952%
MfmaUtil:            55.70% -> 56.72%
```

`sc0+nt` 与单独 `nt` 持平，因此选择语义更简单的 `nt`。A/B/scale 的其他 cache
hint 最多只有约 0.05%～0.13%，没有进入主线。

### 15.4 16B scale producer

4B cooperative 路径由 8 个 wave 各发一条 4B/lane 的 scale VMEM。16B 路径改成：

```text
wave 0: 64 lanes x 16 B = 完整 1 KiB SFA tile
wave 1: 64 lanes x 16 B = 完整 1 KiB SFB tile
```

总 payload 仍是 2 KiB/K tile，consumer-major LDS 图像也不变，但 wave-level scale
VMEM 从 8 条降到 2 条，VGPR 从 229 降到 228。SFB producer wave 1/2/3/4 的差异
都在约 0.1% 噪声内，wave 1 少用一个 SGPR，因而保留 wave 1。

当前实现用四个显式 producer layout 表达这条路径，而不是在 load helper 中手写
`lane_id * 16`：

```text
gsfa / gsfb: [producer_lane=64][16-byte issue], stride = [16, 1]
ssfa / ssfb: [16-byte issue], stage offset 由 layout shift 加入
```

`gsfa/gsfb` 用 lane 作为 global tile 内的行坐标；`ssfa/ssfb` 不再加入 lane 坐标，
因为 gfx950 的 `buffer_load_dwordx4 ... lds` 从 wave-uniform LDS base 开始，硬件会把
各 lane 的 16-byte 返回值依次放入 LDS。四个 layout 在 kernel 的 layout 初始化区一起
创建并由 prologue/steady loop 复用。host consumer-major pack、packed tile stride 和
`rsfa/rsfb` consumer layout 均未改变。

这种统一前置 layout 的源码组织使当前编译结果为 230 VGPR、64 SGPR、0 scratch，
occupancy 仍为 2 waves/SIMD。两次 `8192^3` 实测分别为 2.22848 P 和 2.22964 P。

随机 E8M0 的 `M=N=256, K=128/256/384/512, batch=2` 全部通过。

### 15.5 K-loop unroll 4

`SCALE_LOOP_UNROLL=4` 将 steady loop 展开为四份，减少循环控制和部分地址归纳开销，
没有增加 VGPR、LDS 或 scratch。严格 10 对 10 的结果为：

```text
u1: 0.49510 ms
u4: 0.49207 ms
gain: 0.61%
```

它覆盖了 1～4 个 K tile 的分支和 epilogue 正确性，是 16B producer 之后唯一明显
超过 0.2% 门槛的新候选。

## 16. 当前吞吐上限与剩余瓶颈

新增的纯 `16x16x128_scale` probe 给出了两个上限：

```text
重复使用一组 A/B 的 opcode 理想上限:       约 4.94 P
模拟正式 A/B/accumulator 拓扑的上限:       约 4.153 P
2026-08-27 u4 同卡复测:                    约 2.247 P
```

因此当前约达到 kernel-like MFMA 上限的 54%，不是 MFMA opcode 本身已经饱和。
3 P 相当于该上限约 72%，从当前约 `0.4893 ms` 到 3 P 的 `0.3665 ms` 仍需缩短约
25%。剩余主要矛盾仍是 2 waves/SIMD 下的 VMEM/LDS 隐藏能力和 8 个 wave 到达
tile barrier 的相位差，而不是 HBM 带宽、scale payload 或 LDS bank conflict。

## 17. 已闭环且不应重复的路线

| candidate | result | reason/decision |
|---|---:|---|
| 16-wave, 256x256, 16x16x128 | 约 `2.085 P`, `-2.9%` | 127 VGPR、4 waves/SIMD，但 LDS 流量和 16-wave barrier 成本抵消收益 |
| two 8-wave WG, 128x128 | 约 `1.705 P`, `-20.6%` | 86 VGPR、69632 B LDS、4 waves/SIMD，但复用下降且同步密度过高 |
| single LDS stage | 约 `2.135 P` | 244 VGPR，LDS 虽减半但 occupancy 仍为 2 |
| B1 inplace | 约 `-1.1%` | 少 16 VGPR但缩短了 B1 隐藏窗口 |
| MFMA zigzag | 约 `-0.6%`～`-0.9%` | 少 6 条静态 nop，但破坏 operand/accumulator 调度局部性 |
| split scale producer 2/4 | 约 `-0.6%`～`-0.8%` | producer 更均衡但 wave-level 指令增多 |
| XCD fixed remap | 约 `-2.3%` | 破坏现有 row-major 跨 XCD cache 行为 |
| XCD chunk 2/4/8 | 严格复测持平 | 早期 2.244 P 样本受外部负载影响，作废 |
| grouped-M 2/4/8/16 | 持平到逐步退化 | A 复用损失大于 B 局部性收益 |
| A1 lookahead / split A1 | `-0.43%` 或持平 | 推迟下一 tile global 发射；错误 2.25 P 样本已作废 |
| m0 槽填充 / zigzag / early wait | 持平或退化 | 静态少 nop 不等于动态关键路径更短 |
| merged producer / scale position / fixed stride / direct stage | 持平或退化 | 控制指令减少未兑现为 kernel 时间 |
| LLVM AMDGPU scheduler 策略 | 无稳定胜者 | 默认 u4 最稳 |

判断这些历史记录时必须以本节结论为准：构建名称只表示候选曾经成功构建过，不表示
该候选正确、性能有效或应该重新合入。

## 18. 2026-08-27：barrier rotation 复测与撤销

候选把每个 tile 尾部的发布 barrier 移到下一迭代入口。barrier 数量、VMEM、LDS
read 和 MFMA 数量均不变；目标是让 loop increment/compare 在 barrier 前完成，使
barrier 释放后更快发射下一轮 VMEM。

静态检查结果：

```text
VGPR:       228
LDS:        139264 B
scratch:    0
occupancy:  2 waves/SIMD
barrier:    数量不变，只改变位置
```

随机 E8M0 的 `M=N=256, K=128/256/384/512, batch=2`，baseline 与 rotation
全部 `ALL BATCHES VALID`。随后在空闲物理 GPU 6 上完成两组独立交错测试，每组
baseline/rotation 各 16 个样本：

| repeat | u4 mean | rotation mean | time gain | paired wins |
|---|---:|---:|---:|---:|
| 1 | 0.489988 ms / 2.243954 P | 0.489094 ms / 2.248075 P | `+0.1827%` | 7/8 |
| 2 | 0.488662 ms / 2.250099 P | 0.488331 ms / 2.251559 P | `+0.0678%` | 7/8 |
| combined | 0.489325 ms / 2.247027 P | 0.488713 ms / 2.249817 P | `+0.1253%` | 14/16 |

方向多数为正，但第二次复测明显缩小，组合收益低于预先规定的 0.2% 门槛。结论是：

- 不把 rotation 作为正式优化；
- 已从源码删除 `SCALE_LOOP_BARRIER_ROTATE` 及其条件分支；
- `build_scale16_u4_barrier_rotate/` 的结果保留在本节，构建目录已在收敛清理中删除；
- 撤销后重编的 u4 与保存版汇编除 CUID 外逐行一致。

## 19. 当前保存点、源码清理与下一步

当前可信实验保存点是 `build_repro_current_u4/`。2026-08-27 两组测试合计 32 个
baseline 样本，均值约为：

```text
0.489325 ms
2.247027 P
```

重新构建后资源和回归为：

```text
228 VGPR
compiler TotalSGPR: 64
next-free SGPR: 96
139264 B LDS
0 scratch / 0 spill
2 waves/SIMD
M=N=512, K=1024, batch=2: ALL BATCHES VALID
```

2026-08-27 的收敛清理结果：

- `gemm_a8w8_mxfp8_scale_kernel_template.hpp` 从 2041 行降到 657 行；
- 删除全部实验配置宏、对应 `static_assert`、失败候选条件分支和未引用 helper；
- host launch 恢复为单一的一维 tile grid；
- 删除 210 个历史实验 `build_*` 目录（约 371 MB），只保留参考构建
  `build_repro_current_u4/` 和当前验证构建 `build_clean_u4/`；
- 不带任何 `-DSCALE_*` 参数构建出的 gfx950 汇编，与
  `build_repro_current_u4` 除 CUID 外逐行一致；
- `M=N=256, K=128/256/384/512, batch=2` 以及
  `M=N=512, K=1024, batch=2` 全部报告 `ALL BATCHES VALID`。

清理后又在物理 GPU 6 上做了三轮 `ref-clean-clean-ref`，每个二进制共六个
8192³ 样本：

```text
reference mean:   0.491317 ms
clean mean:       0.491667 ms
mean delta:         -0.071%
reference median: 0.49105 ms
clean median:     0.49075 ms
```

均值和中位数方向相反且差异都小于 0.1%，结合逐行相同的 ISA，判定清理前后性能
等价。这里的新绝对时间只用于清理回归；长期保存点仍采用上面的 32 样本均值。

下一轮不应重复第 17 节的宏扫描。推荐顺序是：

1. 对当前完整 u4 主线重新采 ATT/PMC；旧 trace 早于 16B producer 和 u4，不能直接
   当作当前关键路径。
2. 对比 u4 四个展开体内部与跨四 tile backedge 的 stall，确认收益来自循环控制、
   地址归纳还是编译器寄存器/指令调度。
3. 只设计能改变当前主导 stall、且预计超过 0.2% 的候选；barrier 位置、cache hint、
   producer split、普通 scheduler 参数和简单 nop 删除均已闭环。
4. 正式源码已无实验开关；若继续试验，应在独立构建路径中引入最小开关，并在候选
   收敛后再次删除试验矩阵，保持默认 `make scale` 始终对应已验证主线。

## 20. 2026-08-27：单 barrier 的 20/12 rolling pipeline

完整 u4 ATT 显示，每个 K128 tile 的两条 resident wave 合计 64 条 scaled MFMA 已经
接近 `2048 ticks` 的硬件计算下限，但相邻 tile barrier 的稳态间隔中位数约为
`2744 ticks`。因此本轮没有改变 K tile、MFMA opcode、scale layout 或 LDS 容量，
只改变唯一 tile barrier 在 32 条 MFMA 中的位置。

保留实现的时序为：

```text
prologue:
  tile 0 scale/A/B -> stage 0
  barrier 发布 tile 0
  提前发射 tile 1 的 B0/B1 -> stage 1

steady tile t:
  从 stage(t) 读出当前 scale、A0/A1、B0 和完整 B1
  tile t+1 的 scale/A0/A1 -> stage(t^1)
  执行当前 tile 前 20 条 MFMA
  vmcnt(0) + lgkmcnt(0) + 唯一 workgroup barrier
  tile t+2 的 B0/B1 -> 刚释放的 stage(t)
  只使用 VGPR 执行当前 tile 剩余 12 条 MFMA
```

barrier 同时承担两个作用：发布已经完成的 `t+1`，以及确认所有 wave 已读完 `t`，
从而允许 B(t+2) 覆盖旧 stage。barrier 前当前 tile 的全部 operand 都已进入 VGPR，
所以后 12 条 MFMA 与 B(t+2) 的 global-to-LDS 搬运没有 LDS 覆盖 hazard。每个 K128
tile 仍只有一个 workgroup barrier，global payload 和 MFMA 数量也都不变。

静态资源：

```text
VGPR:                         230
compiler TotalSGPR:            65
next-free SGPR:                96
LDS:                       139264 B
scratch / spill:                0
occupancy:                2 waves/SIMD
```

GPU 6 上 `8192 x 8192 x 8192, batch=1` 的四组交错样本为：

```text
clean u4 median:          0.4911 ms / 约 2.240 P
rolling 20/12 median:     0.4779 ms / 约 2.301 P
同一时间窗净时间收益:     约 2.7%
```

新 ATT 保存于：

```text
trace_rolling_20_12_8192/
```

相对 `trace_block_scale_16_128tile_64x64_current/`：

| ATT 指标 | clean u4 | rolling 20/12 | 变化 |
|---|---:|---:|---:|
| K128 steady barrier 间隔中位数 | 2744 ticks | 2370 ticks | `-13.6%` |
| `s_barrier` 平均 stall/occurrence | 268.86 ticks | 154.52 ticks | `-42.5%` |
| tile wait `vmcnt(0)+lgkmcnt(0)` 平均 stall | 221.11 ticks | 174.18 ticks | `-21.2%` |

本轮同时闭环了以下相邻候选；它们均未保留：

| candidate | 单次 8192³ 结果 | decision |
|---|---:|---|
| barrier `16/16` | 2.2769 P | barrier 过早，VMEM 未成熟 |
| barrier `18/14` | 2.2992 P | 与 20/12 持平，交错复测略慢 |
| barrier `22/10` | 2.2776 P | B 的隐藏窗口不足 |
| barrier 后提前全部 A/B/scale | 2.1945 P | producer burst 推迟 MFMA 恢复 |
| B1 预读从 r4 增至 r8 | 2.2605 P | 244 VGPR，LDS burst 更集中 |
| A/scale 移到当前 LDS read 前 | 1.3560 P | global-to-LDS 写阻塞当前 LDS read |
| A1 移到首对 MFMA 后发射 | 2.2897 P | 下一 tile 的 A1 完成过晚 |
| scale 与 B 一起提前一轮 | 2.2011 P | producer 分支和 barrier 后 burst 退化 |
| barrier 后 B0/B1 分开发射 | 2.2978 P | 与 20/12 持平但多一个热分支 |
| barrier 后 B 使用高优先级 | 2.2968 P | 未超过 0.2% 接受门槛 |
| loop unroll 3 | 2.2850 P | 234 VGPR，慢于 u4 |
| loop unroll 8 | 2.2153 P | 代码体积代价明显 |

源码最终只保留 20/12 B-only rolling 路径，不含实验宏或失败分支。验证构建为
`build_clean_rolling_20_12/`；它与最初跑出约 2.30 P 并用于 ATT 的获胜构建相比，
gfx950 汇编除 CUID 外逐行一致。最终版本还完成了随机 E8M0 的完整
`M=N=K=8192, batch=1` CPU reference 校验：`0 / 67108864` 个元素错误，报告
`ALL BATCHES VALID`；同一轮性能为 `0.4784 ms / 2.2982 P`。

### 20.1 对 3 P 的约束

> 历史说明：本小节按后来确认的异常 MI355X 节点约 2.30 P 做初步判断。正式的
> 2.6528 P 起点、tick 预算和分阶段方案已经在第 27 节重算；后续决策以第 27 节为准。

这次结果说明重排现有指令仍有收益，但也把同一结构的边界暴露得更清楚：稳态间隔
`2370 ticks` 距现有 64 条 resident-wave MFMA 的约 `2048 ticks` 计算下限只剩约
`13.6%`。即使把这部分调度开销全部消掉，也不能可靠地覆盖从约 2.30 P 到 3 P 所需
的约 23% 时间缩减。因此下一步若继续向 3 P 推进，需要改变 occupancy、每个同步区
间承担的工作量或 MFMA/输出 tile 拓扑；继续微调 cache hint、普通 scheduler 参数或
scale loader 不足以达到目标。按当前约束，`32x32x64` 路径暂不进入实现，结构实验
最后再单独进行。

## 21. 2026-08-27：MI350X 统一复测、fixed-B prefetch x4 胜出与构建收敛

在空闲 MI350X（HIP 7 / card5）上，以 `M=N=K=8192, batch=1, verify=0` 对保留候选
执行 3 组 `REF-CAND-CAND-REF`。中位数结果为：

| candidate | 时间 | 性能 |
|---|---:|---:|
| rolling 20/12 baseline | 0.4194 ms | 2.6211 P |
| persistent fixed-A basic x4 | 0.4627 ms | 2.3760 P |
| persistent fixed-A prefetch x4 | 0.4580 ms | 2.4007 P |
| persistent fixed-B basic x4 | 0.4167 ms | 2.6387 P |
| persistent fixed-B prefetch x4 | 0.4151 ms | 2.6489 P |
| persistent 2x2 prefetch x4 | 0.4292 ms | 2.5621 P |
| 16-wave 4x4 rolling u2 | 0.4587 ms | 2.3971 P |
| 16-wave 8x2 rolling u2 | 0.5335 ms | 2.0618 P |
| 16-wave 4x4 persistent 2x2 x4 | 0.4822 ms | 2.2804 P |

最终胜者 `fixed_b_prefetch_4` 的 10 次直接复测中位数为
`0.4144 ms / 2.6528 P`，最快单次为 `0.4138 ms / 2.6571 P`，完整 8192³
正确性验证为 `ALL BATCHES VALID`。其资源为 242 VGPR、96 SGPR、139264 B LDS、
0 scratch、2 waves/SIMD。该版本让每个 workgroup 固定 B/SFB，沿 M 连续处理最多
4 个输出 tile，并在当前输出尾部预取下一输出的 K0 A/B/scale；host grid 相应从
`num_tiles_m * num_tiles_n` 缩为 `ceil_div(num_tiles_m, 4) * num_tiles_n`。

为保留可复现源码而不污染 rolling 基线，fixed-B prefetch x4 已另存为独立 kernel
模板、kernel 编译入口、host 和 Makefile target。gfx950 离线重编结果与获胜构建的
ISA 除 HIP CUID 外逐字节一致。最终只保留：

```text
build_clean_rolling_20_12
build_persistent_fixed_b_prefetch_4
```

其他 8-wave persistent、16-wave 和 32x32x64 probe 的 build 目录均删除；失败路线、
资源数据和性能结果只在文档中保留。probe 源码仍保留，需要时可按交接文档重新构建。

## 22. 2026-08-27：独立 fixed-B 源码在 MI355X 上的重编回归

使用新增的独立 template、kernel driver、persistent host 和 Makefile target 重编
`fixed_b_prefetch_4`。新编 gfx950 ISA 的资源为 242 VGPR、96 SGPR、139264 B LDS、
0 scratch、2 waves/SIMD；去除每次编译变化的 HIP CUID 后，与保存的
`build_persistent_fixed_b_prefetch_4` ISA 逐字节一致。

在 `M=N=K=8192, batch=1, verify=0` 下，以平衡顺序运行 3 组，每个版本取得 6 个
无监控样本：

| 目标卡 | rolling 20/12 | 保存的 fixed-B prefetch x4 | 重编 fixed-B prefetch x4 |
|---|---:|---:|---:|
| HIP 7 / card5 | 0.4830 ms / 2.2764 P | 0.47835 ms / 2.2987 P | 0.4778 ms / 2.3013 P |
| HIP 4 / card7 | 0.49045 ms / 2.2418 P | 0.4864 ms / 2.2606 P | 0.4864 ms / 2.2606 P |

HIP 7 与 `rocm-smi GPU[7]` 不是同一张物理卡：本机 HIP 7 对应 card5，物理 card7
对应 HIP 4，因此两者均完成复测。card5 上重编版相对 rolling 的中位时间收益约
1.08%，保存版与重编版仅差约 0.11%；card7 上两份 persistent 的中位时间完全相同。
当前 MI355X 仍是约 2.26--2.30 P，没有复现 MI350X 的约 2.65 P。

另用 `M=1024, N=256, K=128, batch=2` 覆盖每个 workgroup 的完整 4-output-tile
persistent 路径，重编版结果为 `0 / 524288` 个元素错误，`ALL BATCHES VALID`。

## 23. 2026-08-27：MI350 侧 fixed-B 源码结构在 MI355X 上复现

额外测试了 MI350 环境提供的 690 行 fixed-B prefetch x4 模板。它复用 rolling 模板
中的 layout/MFMA helper，把固定 B、layout 和 stage 生命周期提到 output loop 外，
并把下一输出的 K0 A/B/scale 预取放在最终 K tile 的 20/12 MFMA 分界处。除适配本机
include 路径、通过派生 traits 提供 `OUTPUT_TILES_PER_WG=4` 外，kernel 主体未改。

当前 ROCm 7.14/gfx950 编译结果：

```text
236 VGPR
92 compiler TotalSGPR / 96 next-free SGPR
139264 B LDS
0 scratch
2 waves/SIMD
```

它与保存版不是同一 ISA，但静态工作量接近：均为 192 条 scaled MFMA、162 条
`ds_read`、7 条 `s_barrier` 和 43 条 `s_waitcnt`；该版本多 1 条静态
`buffer_load_dwordx4` 和 1 条 `s_cbranch`。完整 4-output-tile 小规模验证为
`ALL BATCHES VALID`。

HIP 7/card5 上 3 组平衡顺序、每版 6 个无监控样本：

| version | 中位时间 | 中位性能 |
|---|---:|---:|
| rolling 20/12 | 0.4826 ms | 2.2784 P |
| 保存的 fixed-B prefetch x4 | 0.4781 ms | 2.2998 P |
| MI350 源码结构 | 0.47875 ms | 2.2967 P |

MI350 源码结构比保存版慢约 0.14%，属于小幅退化，仍比 rolling 快约 0.80%；因此
它不能解释 MI350 机器上的 2.65 P。

将该候选改为 500 warmup + 5000 次连续计时后，平均为
`0.4797 ms / 2.2920 P`。负载中遥测为：

```text
GFX activity:                         100%
8 个 XCD gfx clock:          1475--1636 MHz
socket power:                         1351 W
hotspot / HBM:                    60 / 36 C
PPT violation:                 ACTIVE, 47%
thermal / VR / PROCHOT violation:     0%
CU / partition:                256 CU, SPX/NPS1
```

同一保存版在另外两张空闲 MI355X 上的三次中位数分别为：HIP 5/card4
`0.4685 ms / 2.3469 P`，HIP 6/card6 `0.4757 ms / 2.3115 P`；物理 card7 为
`2.2606 P`。卡间存在约 4% 差异，但所有空闲卡都显著低于 MI350X 的约 2.65 P。
在相同 executable、256 CU、SPX/NPS1、无热限频的条件下，当前证据指向 MI355X
平台的 PPT/DPM/固件状态导致较低有效 gfx 时钟。要进一步定因，需要在 MI350X 上
对同一长循环同步采集 `amd-smi metric -u -p -c -t -v`，并比较 VBIOS、固件、驱动和
机箱级功耗策略。

## 24. 2026-08-27：区分 clang unroll 收益与短时 boost

> 状态更新：本节关于跨机器差异主要来自 boost 的判断，已被第 26 节的新平台信息
> 取代。本节数据仍保留，但异常 MI355X 节点不能代表正常 MI355X。

MI350X 侧补充了两种测试长度：

| build / 测法 | 时间 | 性能 |
|---|---:|---:|
| clang 22 当前保留版，200 warmup + 100 次计时 | 0.43235 ms | 2.543 P |
| clang 23 历史最优二进制，同样短测 | 0.4184 ms | 2.628 P |
| clang 22 当前保留版，1000 warmup + 1000 次计时 | 0.4897 ms | 2.245 P |

因此 clang 22 未展开只解释短测中的约 0.085 P；更大的差异来自短时 boost 到持续
功耗稳态的下降。clang 22 的稳态/短测性能比例为约 `2.245/2.543 = 0.883`；若仅作
一阶估算，把该比例应用到 clang 23 的 2.628 P，得到约 2.32 P，与当前 MI355X 上
同一历史二进制的约 2.30 P 接近。该估算不能替代实测，下一项必要对照是让 clang 23
历史最优二进制在 MI350X 上执行相同的长循环。

MI350X 持续负载时同样观察到约 994 W、1.48--1.64 GHz，并且 FCLK 从 1500 MHz
降至 1250 MHz；当前 MI355X 持续负载为约 1351 W、1.48--1.64 GHz、FCLK 1250 MHz，
且 PPT violation active。两台机器的稳态时钟区间已经接近，差别主要在于 MI350X
短测保留了更高的瞬态 boost，而当前 MI355X 在 200 次 warmup 内就进入 PPT 稳态。

当前 MI355X 软件/固件环境为：gcnasm `8ce1bea6335b0d17598fcdd86562c7fe9e775ad9`，
aiter `c8be843ea45b9ba92d053a5be56b6f8fa2d97f4f`，HIP 7.14 / clang 23，amdgpu
6.14.14，MI355X IFWI `00162246`。MI350X 重编环境的 aiter 为
`6df2316d1dea9b4cbb0200e5e939d41844b2655c`、ROCm 7.2 / clang 22；这些差异会影响重新编译的 ISA，
但不会解释同一个已编译 clang 23 executable 跨机器运行时的差异。

## 25. 2026-08-27：MI355X 零 warmup 时间线

> 状态更新：该时间线来自第 26 节确认的异常/降额 MI355X 节点，只用于诊断该机器，
> 不作为 kernel 的正式性能口径。

`gemm_a8w8_mxfp8_scale_host_fixed_b_prefetch_4.cc` 的普通 benchmark 原先把
`warmup=200, iterations=100` 写成函数默认参数，并且 `main()` 在 benchmark 前还有
一次无条件验证 launch。现在保留普通模式的原始默认口径，同时增加：

- `--warmup/-w` 和 `--iterations/-i` 参数；
- `--timeline`：要求 `-v 0`，取消所有显式和隐式预热，连续执行 1000 发；
- 在第 25、50、100、200、500、1000 发处仅插入 HIP event，不在区间之间同步或打印。

MI355X HIP 7 / amd-smi GPU 5 上，两次测试（第二次先空闲 15 秒）的结果为：

| kernel 区间 | 第一次 | 第二次 |
|---|---:|---:|
| 1--25 | 2.0908 P | 1.8782 P |
| 26--50 | 2.5022 P | 2.4860 P |
| 51--100 | 2.3640 P | 2.3362 P |
| 101--200 | 2.2922 P | 2.2912 P |
| 201--500 | 2.2957 P | 2.2957 P |
| 501--1000 | 2.3013 P | 2.3006 P |

结论比“200 次 warmup 隐藏了 2.6 P”更精确：第 1--25 发受 DPM 升频延迟影响，
第 26--50 发出现约 2.49--2.50 P 的短暂峰值，第 51--100 发已经下降，并在第 101 发
左右进入约 2.29--2.30 P 稳态。当前 MI355X 即使从完全取消 warmup 开始，也没有观测
到 2.6 P。

第一次测试同时以约 1 ms 周期读取 AMD SMI GPU metrics。MI355X 的 FCLK 从测试前
就是固定的 1250 MHz；在 501--1000 稳态区间，8 XCD 平均 gfx clock 的采样中位数约
1501 MHz、socket power 中位数约 1311 W，PPT residency 约 36%。早期区间的固件
activity/clock 遥测存在明显低通延迟，不能逐发对应，但 PPT residency 从早期区间
已经开始增长，且长尾与此前 5000 次持续测试一致。

复现命令：

```bash
HIP_VISIBLE_DEVICES=7 ./build/gemm_a8w8_mxfp8_scale_fixed_b_prefetch_4.exe \
  -m 8192 -n 8192 -k 8192 -b 1 -v 0 --timeline
```

## 26. 2026-08-27：最终平台判定与正式性能口径

使用方进一步确认，当前测试的 MI355X 节点
`smci355-ccs-aus-n12-25.cs-aus.dcgpu` 是已知异常/降额（内部称“缩缸”）机器；其他
人员也无法正常使用该节点。正常情况下 MI355X 应略快于 MI350X，因此不能把该节点
测得的约 2.30 P 当作 MI355X 产品性能或当前 kernel 的性能上限。

同一个 kernel 按项目统一的 `200 warmup + 100 timing` benchmark，在正常 MI350X
上的可信结果为：

```text
fixed-B prefetch x4，10 次直接复测中位数：2.6528 P
fixed-B prefetch x4，最快单次：           2.6571 P
```

因此当前正式性能按约 `2.65 P` 记录。异常 MI355X 上的零 warmup 时间线、约 2.30 P
稳态、约 1.5 GHz gfx clock 和 PPT violation 数据仍有诊断价值：它们说明低性能来自
该节点的运行状态，而不是 kernel 源码恢复或 fixed-B persistent 路径错误；这些数据
不得再用于推断正常 MI355X 的性能。

## 27. 2026-08-27：16x16 到 3 P 的硬预算与完整 32x32x64 pipeline

### 27.1 正式起点与目标

本节以健康 MI350X 上 fixed-B prefetch x4 的正式中位数为起点，不使用异常 MI355X
的绝对性能估算 kernel 上限：

```text
8192^3 GEMM FLOP:             2 * 8192^3 = 1,099,511,627,776
当前 fixed-B winner:          0.4144 ms / 2.6528 P
3.0 P 对应时间:               0.366504 ms
还需减少时间:                 47.896 us / 11.56%
还需提高吞吐:                 13.09%
```

中间目标对应：

| 目标 | 时间 | 相对 2.6528 P 所需吞吐提升 |
|---|---:|---:|
| 2.70 P | 0.40723 ms | 1.78% |
| 2.80 P | 0.39268 ms | 5.55% |
| 3.00 P | 0.36650 ms | 13.09% |

当前 16x16 拓扑每个 wave、每个 K128 执行 32 条 scaled MFMA；每个 SIMD 驻留两条
wave。此前 rolling 20/12 的 ATT 测得稳态 K128 barrier 间隔中位数约 2370 ticks，
两条 resident wave 的 MFMA issue 下限约 2048 ticks，因此只剩 322 ticks 非 MFMA
余量。

把 fixed-B 的 2.6528 P 全部乐观地归入该稳态区间，3 P 要求约 2096 ticks，只能保留
48 ticks，需要消掉 `274/322 = 85.2%` 的余量。若严格使用与该 ATT 对应的健康机
rolling 2.6211 P，则目标约 2071 ticks，只能保留 23 ticks，需要消掉约 92.9%。所以
合理结论是：3 P 要消掉当前拓扑约 **85%--93%** 的非 MFMA 空隙，并且已经逼近该
拓扑约 3.03--3.07 P 的乐观计算上限。普通 cache hint、再减十几个 VGPR 或普通
unroll 扫描不可能单独提供 13.09%。

这里还有一个必须先纠正的 profiler 证据问题：现有
`trace_persistent_prefetch_4_8192` 对应旧 `build_persistent_prefetch_4`，为 248 VGPR、
45 条静态 waitcnt；当前 retained fixed-B winner 为 242 VGPR、43 条 waitcnt、7 条
barrier。旧 trace 只能提供方向，不能用于给当前 winner 定关键路径。

### 27.2 16x16 分阶段方案

按收益、风险和停止条件执行，不再进行无边界的参数穷举。

#### 阶段 A：先建立 exact winner 的证据

在健康 MI350X 上对 retained fixed-B executable 重新采 ATT 和 PMC，并同时记录
GFX clock、FCLK 与 PPT。profile 前必须核对 code object 是 242 VGPR、next-free
SGPR 96（compiler TotalSGPR 101）、43 waitcnt、7 barrier、0 spill 的版本。需要分别测出：

- 四个 u4 展开体各自的 barrier-to-barrier 间隔；
- `vmcnt(0)+lgkmcnt(0)` 与 `s_barrier` 的独立等待；
- 最终 K tile、下一 output K0 prefetch 与首尾 C store 的时间线；
- MfmaUtil、LdsUtil、MeanOccupancy、LDS conflict、MemUnitStalled 和 TCC 命中率。

这是后续所有改动的前置条件。若 exact fixed-B 的稳态间隔已经接近 2048 ticks，而
总时间仍明显高于 0.3665 ms，说明剩余主要是 output transition/epilogue；若间隔仍在
2300 ticks 以上，则必须直接攻击同步路径。

#### 阶段 B：低风险收尾实验

1. **最终 K tile 的 C-store 流水化：已完成并停止。** C00/C10/C01 在后续
   accumulator bank 还在计算时分批写回，生成 ISA 中第一批 store 后仍有 22 条
   MFMA，且静态资源与 winner 相同。但五组 ABBA 的中位性能仍慢 0.27%，
   已按 NO-GO 淘汰，详见第 27.7 节。
2. **barrier 分界窄扫：已完成并停止。** rolling 阶段的 `16/16`、`18/14`、
   `20/12`、`22/10` 已证明 20/12 最稳；用户确认 `19/13`、`21/11` 也已运行且
   性能不好。fixed-B 只改变 output traversal，不构成重复整套分界扫描的充分理由。
3. **8192/full-group 专用显式 x4 output fast path：跳过。** 用户明确决定不做，
   因此没有实现、没有生成候选 build，后续也不应将它列入待测矩阵。

分界扫描和 final-K/C-store 都已闭环。本阶段没有剩余低风险代码候选。

#### 阶段 C：16x16 转置 wave-grid go/no-go（已完成）

当前 `T_M=4,T_N=2` 对应 `E_M=2,E_N=4`。可独立测试 `T_M=2,T_N=4`，对应
`E_M=4,E_N=2`：保持 8 waves、128 accumulator、总 MFMA、总 LDS operand 字节和
barrier 数基本不变，但把每 wave 的 B operand/live-range 压力减半，并转移到更容易
提前读取的 A 路径。它不是减少工作量，只是改变关键路径与 LDS 访问分布。

实际结果为 252 VGPR、0 spill、2 waves/SIMD。候选相对 retained fixed-B 慢 1.51%，
未达到“至少快 1%”的保留门槛，因此已按 NO-GO 停止。完整实现、验证矩阵、
静态 ISA 和五组交叉性能数据见第 27.5 节。

#### 阶段 D：direct-to-VGPR（历史已失败，不重复）

早期有完整数据的 scale global-to-VGPR-to-LDS 路径仅为 `1.903--1.959 P`，
后续 consumer-major direct-to-LDS 为 `2.143--2.157 P`。这一数据只覆盖 scale
传输，不应伪装成 full-A/B direct 的精确测量。

用户已确认 direct-to-VGPR 性能路线也做过且结果不好；当前工作树没有保留
full-A/B direct 版本的独立原始数字，因此只记录它的 NO-GO 结论，不虚构数字。
后续不再实现原计划的 direct-global-to-VGPR/full-topology probe。

历史 16-wave `16x16x128` 虽把 occupancy 提到 4 waves/SIMD，但健康 MI350X 只有
2.3971 P；原因是更高 occupancy 没有抵消 LDS operand 与 16-wave barrier 成本。因此
不能把“减 VGPR/加 occupancy”本身当作 3 P 方案。当前 139264 B LDS 和 242 VGPR 都
把 8-wave workgroup 限制在 2 waves/SIMD；只有同时重做 wave output、寄存器生命期
和同步粒度，occupancy 才会真正改变。

### 27.3 已实现的 8-wave 32x32x64 pipeline

新增独立实现，没有覆盖 rolling 基线或 retained fixed-B 源码：

```text
gemm_a8w8_mxfp8_scale_kernel_template_32x32x64_fixed_b_prefetch_4.hpp
gemm_a8w8_mxfp8_scale_kernel_32x32x64_fixed_b_prefetch_4.cc
gemm_a8w8_mxfp8_scale_host_32x32x64_fixed_b_prefetch_4.cc
Makefile target: scale_32x32x64
```

构建命令使用 `/tmp`，不新增仓库 build 目录：

```bash
make BUILD=/tmp/mxfp8_32x32x64_pipeline -j4 scale_32x32x64
```

实现拓扑：

```text
WG tile:                 256x256x128
threads / waves:         512 / 8
T_M x T_N x T_K:         4 x 2 x 1
W_M x W_N x W_K:         32 x 32 x 64
E_M x E_N x E_K:         1 x 2 x 2
wave output:              64x128，8 个 32x32 accumulator fragments
K128:                     两个 K64 phase，每 wave 16 条 scaled MFMA
pipeline:                 双缓冲 LDS、每 K128 一个 barrier、steady 10/6 分界
output traversal:         fixed-B persistent x4 + 下一 output K0 prefetch
scale payload:            SFA/SFB 各 1024 B/K128，使用 byte selector 选 phase/half
```

最终默认 u4 资源与静态 ISA：

| 项目 | 16x16 fixed-B | 32x32 fixed-B |
|---|---:|---:|
| VGPR | 242 | 220 |
| next-free SGPR | 96 | 96 |
| LDS | 139264 B | 139264 B |
| scratch/spill | 0 | 0 |
| occupancy | 2 waves/SIMD | 2 waves/SIMD |
| scaled MFMA | 192 | 96 |
| `ds_read` | 162 | 162 |
| `buffer_load` | 68 | 67 |
| `s_waitcnt` | 43 | 25 |
| `s_barrier` | 7 | 7 |
| C store | 32 | 32 |

ISA 只包含 `v_mfma_scale_f32_32x32x64_f8f6f4`，没有混入 16x16 opcode。A/B 静态
映射各覆盖完整 16384 个唯一元素、0 mismatch，最大 LDS offset 为 16863，小于
16896；C 的四个 quadrant 完整覆盖 256x256。随机 E8M0 的 K=128/256/384/512、
batch=2，以及 scale row/K-group 定向模式和 persistent M tail 均为
`ALL BATCHES VALID`。

调优过程表明寄存器不是唯一问题：

| 32x32 版本 | 资源/变化 | 异常 MI355X 探索值 |
|---|---|---:|
| 初版，相邻执行同一 chain 的两个 phase | 256 VGPR，0 spill | 1.757 P |
| 8 chain 跨 phase 交错 | 256 VGPR | 1.910 P |
| base operand 复用 | 220 VGPR，0 spill | 约 1.95--1.96 P |
| 删除 pair scheduler barrier | 226 VGPR | 1.943 P，回退 |
| unroll 1 | 206 VGPR，0 spill | 1.935 P |
| unroll 2 | 256 VGPR，27 spill | 淘汰 |
| unroll 8 | 220 VGPR，0 spill | 1.958 P |
| unroll 4 | 220 VGPR，0 spill | 保留 |

最终在当前已知异常 MI355X 节点、`8192^3`、200 warmup + 100 timing 上完成三组
`16-ref / 32-cand / 32-cand / 16-ref`：

```text
16x16 fixed-B（6 个样本）中位数: 0.4794 ms / 2.2934 P
32x32 fixed-B（6 个样本）中位数: 0.5692 ms / 1.9319 P
32x32 时间增加:                    约 18.7%
32x32 吞吐下降:                    约 15.8%
```

该节点不能提供正常 MI355X 的绝对性能，但同一时间窗的配对差距远大于噪声。若把
同机吞吐比 0.842 仅作一阶外推，健康 MI350X 上约为 2.23 P；这不是实测正式数据，
仍需在健康卡上运行同一 executable 才能确认。

PMC 中位数进一步说明失败原因：

| 指标 | 16x16 | 32x32 |
|---|---:|---:|
| MfmaUtil | 66.1% | 48.5% |
| LdsUtil | 27.9% | 38.3% |
| MeanOccupancyPerActiveCU | 1.99 | 1.97 |
| MemUnitStalled | 0.25% | 0.79% |

32x32 虽把静态 MFMA 数减半，却没有降低 LDS read、barrier、global payload 或 occupancy。
每个 wave 的独立 accumulator chain 从 16x16 的约 32 条降到 8 条，而且每条 chain
要被两个 K64 phase 连续更新，无法隐藏该 opcode 的依赖延迟；同样 162 条 LDS read
也只分摊到一半 MFMA 上。因此当前 8-wave 32x32 pipeline 是完整、正确的负结果，
不能替换 2.6528 P 的 16x16 winner。

### 27.4 16-wave 32x32 go/no-go 已完成并淘汰

为排除“8-wave 只是 occupancy 不足”的可能，又实现了独立 16-wave rolling prototype：

```text
threads:                   1024 / 16 waves
T_M x T_N:                 4 x 4
wave output:               64x64
accumulator:               4 fragments / 64 VGPR
MFMA per wave per K128:     8
实际资源:                  117 VGPR、54 compiler SGPR
LDS:                       139264 B
scratch/spill:             0
occupancy:                 4 waves/SIMD
```

新增文件：

```text
gemm_a8w8_mxfp8_scale_32x32x64_16wave_common.h
gemm_a8w8_mxfp8_scale_kernel_template_32x32x64_16wave_rolling.hpp
gemm_a8w8_mxfp8_scale_kernel_32x32x64_16wave_rolling.cc
gemm_a8w8_mxfp8_scale_host_32x32x64_16wave_rolling.cc
Makefile target: scale_32x32x64_16wave
```

实现复用 generic 1024-thread global-to-LDS producer；每个 half 每线程搬 1x16 B。
A/B base consumer 继续使用同一 padded LDS image，SFA layout 直接复用；SFB 改为
每个 B lane 一个 dword，并用 `2*phase+half_n` 选择 byte。默认 unroll 1，只让
A0/A1/B0/B1 四组 base operand 同时存活。

随机 E8M0 的 K=128/256/384/512、batch=2，M/N 多 tile，以及 SFA/SFB row/K-group
定向模式均为 `ALL BATCHES VALID`。ISA 有 16 条静态
`v_mfma_scale_f32_32x32x64_f8f6f4`、0 条 16x16 opcode。

在异常 MI355X 上完成三组 fixed-B reference 与 16-wave candidate 的交叉复测：

```text
16x16 fixed-B（6 个样本）中位数: 0.4791 ms / 2.2950 P
32x32 16-wave（6 个样本）中位数: 0.5911 ms / 1.8602 P
32x32 16-wave 时间增加:           约 23.4%
32x32 16-wave 吞吐下降:           约 18.9%
```

它也比 8-wave 32x32 的约 1.932 P 低约 3.7%。原因不是寄存器或 spill：每 wave 只有
4 条独立 accumulator chain；每 WG/K128 的 LDS consumer read 约从 216 条增到
288 条；barrier 要同步 16 waves；139264 B LDS 仍只允许一个 WG/CU，所以 occupancy
变成 4 waves/SIMD 并没有带来第二个独立 workgroup。

fixed-B 在成熟 16x16 kernel 上的历史收益约 1.2%，不可能把 1.86 P 推向 3 P。因此
16-wave 版本不再叠 persistent，也不再扫描 unroll/scheduler。结合 8-wave 和 16-wave
两个完整实现，`32x32x64_scale` 的当前 GEMM 路线正式停止；源码作为正确的结构负例
与后续硬件/编译器研究基线保留。

### 27.5 8-wave `T_M=2,T_N=4` 转置 wave-grid：NO-GO

按用户指定，本实验先于其余 16x16 候选完成，并且没有实现 8192 显式 x4
fast path。新增的独立文件为：

```text
gemm_a8w8_mxfp8_scale_tm2_tn4_common.h
gemm_a8w8_mxfp8_scale_kernel_template_tm2_tn4_fixed_b_prefetch_4.hpp
gemm_a8w8_mxfp8_scale_kernel_tm2_tn4_fixed_b_prefetch_4.cc
gemm_a8w8_mxfp8_scale_host_tm2_tn4_fixed_b_prefetch_4.cc
Makefile target: scale_tm2_tn4_fixed_b_prefetch_4
```

构建命令：

```bash
make BUILD=/tmp/mxfp8_tm2_tn4_npair -B -j4 \
  scale_tm2_tn4_fixed_b_prefetch_4
```

候选继续使用 `16x16x128_scale`、`256x256x128` WG tile、512 threads / 8 waves、
fixed-B persistent x4、K128 双缓冲与每 K128 一次 barrier。唯一的拓扑性改动是：

```text
T_M,T_N:             4,2 -> 2,4
E_M,E_N:             2,4 -> 4,2
A LDS reads/half:      4  -> 8
B LDS reads/half:      8  -> 4
SFA dwords/wave:       1  -> 2
SFB dwords/wave:       2  -> 1
```

SFA 两个 dword 分别服务两个 M half，`op_sel_a=M_REPEAT=0..3`。SFB 把两个
N half 放进同一 dword，`op_sel_b=2*half_n+n_repeat`。A/B consumer layout 来自
已验证的 unscaled `T_M=2,T_N=4` 8-wave 路径；不是只替换 traits，因为 retained
template 含有 `T_M=4,T_N=2` 专用 layout、scale 选择和手工 MFMA 调度。

当前源码保留 N-pair 调度，使相邻两条 MFMA 共享 A，与 retained winner 的
scheduler-group 形状一致。另外试过相邻 MFMA 共享 B 的 M-pair 调度；快速交叉对比中
两者中位时间约为 0.49705 ms 和 0.49785 ms，差 0.16%，属于噪声。

最终 N-pair 的静态 ISA：

| 项目 | retained winner | `T_M=2,T_N=4` |
|---|---:|---:|
| VGPR | 242 | 252 |
| next-free SGPR | 96 | 96 |
| compiler TotalSGPR | 101 | 95 |
| LDS | 139264 B | 139264 B |
| scratch/spill | 0 | 0 |
| occupancy | 2 waves/SIMD | 2 waves/SIMD |
| static 16x16x128 scaled MFMA | 192 | 192 |
| static `ds_read` | 162 | 156 |
| static `buffer_load` | 68 | 67 |
| static `s_waitcnt` | 43 | 28 |
| static `s_barrier` | 7 | 7 |

正确性覆盖 K=128/256/384/512、batch=2、N 多 tile、persistent 1/2/3/4 output、
`4+1` output tail，random/unit E8M0 以及 SFA/SFB row/K-group 定向 pattern，全部输出
`ALL BATCHES VALID`。由于性能门槛已失败，没有继续做完整 `8192^3 -v 1`。

性能使用当前已知异常 MI355X 的 GPU 7，所以只用同卡、同时窗的相对结果判定
拓扑。在后续稳定窗口执行 `8192^3`、`w200/i100`、5 组
`REF-CAND-CAND-REF`，原始时间为：

```text
reference: 0.4876, 0.4881, 0.4888, 0.4892, 0.4897,
           0.4906, 0.4882, 0.4889, 0.4869, 0.4893 ms
candidate: 0.4969, 0.4926, 0.4963, 0.4989, 0.4962,
           0.4986, 0.4955, 0.4947, 0.4943, 0.4974 ms

reference median: 0.48885 ms / 2.249 P
candidate median: 0.49625 ms / 2.216 P
candidate time:   +1.51%
candidate perf:   -1.49%
```

10/10 个 candidate 样本都慢于 reference 的最慢稳定样本。按同机比例机械外推，
健康 MI350X 上只约为 `2.6528 * 0.985 = 2.61 P`，而 `+1%` 的保留门槛是
`2.6796 P`。因此该候选正式判定为 **NO-GO**。

失败原因也与数据一致：B LDS read 和 B live range 虽然减半，但 A LDS read 加倍、
VGPR 增加 10；总 LDS operand 字节、MFMA、barrier 和 occupancy 均没下降。M-pair/N-pair
都不改善性能，说明该转置只把压力从 B 搬到 A，没有缩短真实关键路径。

### 27.6 已完成路线去重与剩余边界

本节修正第 27.2 节最初方案中两个重复项。

barrier 分界早已在第 20 节闭环：

| 分界 | 历史性能 | 结论 |
|---|---:|---|
| 16/16 | 2.2769 P | barrier 过早，VMEM 未成熟 |
| 18/14 | 2.2992 P | 与 20/12 持平，交错复测略慢 |
| 20/12 | 约 2.301 P | 当轮保留点 |
| 22/10 | 2.2776 P | B 隐藏窗口不足 |

`19/13` 和 `21/11` 也已实测性能不好，但它们的独立原始数字没有保留在
当前工作树。结论是 20/12 为已有扫描的收敛点，不再用相邻整数分界重新穷举。

direct-to-VGPR 也已被用户确认为历史 NO-GO。已存档的 scale-only 对照是
`1.903--1.959 P` 对 `2.143--2.157 P`；full-A/B direct 的精确原始数字不在当前
文档或 build 中，所以不补写虚假数字，但也不再将它当成待做方案。

在明确跳过显式 x4，且 16-wave、32x32、2x4 wave-grid、barrier 分界和
direct-to-VGPR 都已淘汰后，final-K/C-store overlap 也已实现并慢 0.27%。
因此健康 MI350X 的 `2.6528 P` 是当前实现的收敛点。

### 27.7 final-K/C-store overlap：NO-GO

为避免覆盖 retained winner，新增了独立候选：

```text
gemm_a8w8_mxfp8_scale_kernel_template_fixed_b_prefetch_4_cstore_overlap.hpp
gemm_a8w8_mxfp8_scale_kernel_fixed_b_prefetch_4_cstore_overlap.cc
gemm_a8w8_mxfp8_scale_host_fixed_b_prefetch_4_cstore_overlap.cc
Makefile target: scale_fixed_b_prefetch_4_cstore_overlap
```

```bash
make BUILD=/tmp/mxfp8_cstore_overlap -B -j4 \
  scale_fixed_b_prefetch_4_cstore_overlap
```

实现保持 next-output K0 prefetch 位于所有 C store 之前，不改变 continuation 的
`vmcnt(0) + lgkmcnt(0) + s_barrier`。final-K 仍按 C00、C10、C01、C11 的 bank
顺序计算，但在后一 bank 发射至少一对独立 MFMA 后，立即写回前一个已完成
bank。最终 ISA 在第一批 C store 后还有 22 条 scaled MFMA，因此实际生成的
确是 store/MFMA overlap，不是源码层的假重排。

候选与当地重编 reference 的静态资源/指令数完全相同：

```text
VGPR:                    242
compiler TotalSGPR:      101
next-free SGPR:           96
LDS:                  139264 B
scratch/spill:              0
occupancy:          2 waves/SIMD
scaled MFMA:              192
ds_read:                  162
buffer_load/store:      68/32
s_waitcnt/barrier:       43/7
```

正确性矩阵覆盖 K=128/256/384/512、batch=2、N 多 tile、persistent 1/2/3/4 output、
`4+1` output tail，random/unit E8M0 和 SFA/SFB row/K-group 定向 pattern，全部为
`ALL BATCHES VALID`。

在异常 MI355X 上仅使用同卡相对比较判定候选：GPU 7、`8192^3`、
`w200/i100`、5 组 `REF-CAND-CAND-REF`。

```text
reference: 0.4811, 0.4808, 0.4811, 0.4796, 0.4809,
           0.4805, 0.4801, 0.4802, 0.4804, 0.4805 ms
candidate: 0.4819, 0.4826, 0.4817, 0.4810, 0.4816,
           0.4814, 0.4857, 0.4820, 0.4826, 0.4817 ms

reference median: 0.48050 ms / 2.2883 P
candidate median: 0.48180 ms / 2.2821 P
candidate time:   +0.2706%
candidate perf:   -0.2698%
```

5/5 个 group 的 candidate 均值都慢于对应 reference 均值，不仅没有超过
`+0.2%` 门槛，连方向都是负的。因此正式判定 **NO-GO**，不再测 age-aware
waitcnt 或更细的 store 插入位置。当前 winner 仍是 fixed-B prefetch x4，健康
MI350X 正式性能仍为 `0.4144 ms / 2.6528 P`。

### 27.8 resident-wave 严格 producer/consumer 错相：NO-GO

本轮验证以下假设：同一 SIMD 上两条 resident wave 保持一个 phase 的进度差，令一条
wave 计算当前 K128，另一条 wave 把下一 K128 搬入 LDS，然后交换角色。

当前 rolling ATT 的 occupancy 记录确认 512-thread workgroup 的 resident pair 为：

```text
(wave 0, wave 4)
(wave 1, wave 5)
(wave 2, wave 6)
(wave 3, wave 7)
```

现有映射 `wave_id_m = wave_id % 4`、`wave_id_n = wave_id / 4` 因而使每对 wave
共享 M 坐标、使用不同 N 坐标。条件 `s_barrier` 可以让两组 wave 在相邻 lexical
barrier 上完成同一个 hardware barrier epoch，从机制上能建立要求的错相；但它不是
半个 workgroup 独立同步。

本轮只新增独立 probe，没有修改 retained fixed-B winner：

```text
probes/probe_wave_phase_pipeline.cu
probes/probe_wave_phase_consumer_only.cu
probes/probe_wave_phase_consumer_segmented.cu
probes/probe_wave_shared_pipeline.cu
probes/probe_wave_shared_asymmetric.cu
```

#### 27.8.1 搬运确实能隐藏，但单 compute-wave 成为新瓶颈

第一组 probe 固定为 512 threads、139264 B LDS、2 waves/SIMD；每 wave、每 K128
动态执行 8 条 16-B global-to-LDS、24 条 `ds_read_b128` 和 32 条 scaled MFMA。
严格错相没有死锁，输出 bit-exact。修正 accumulator 初始化被编译器移入计时区后，
三组 `256 blocks x 256 loops` 的 block 内计时为：

```text
full payload, aligned:       3805.8--3957.8 cycles/K128
full payload, strict stagger:2934.2--2943.0 cycles/K128
```

这个 aligned 版本有意先等待全部搬运再计算，只用于证明错相机制，不代表 winner。

随后把两套 LDS stage 在计时前填好，计时循环完全删除 global-to-LDS，只保留相同的
24 条 LDS read、32 条 MFMA 和两个 barrier epoch。三组 ABBA 完全稳定：

```text
all-loads-first consumer:
  aligned two-compute-wave:  2556.68--2556.89 cycles/K128
  strict one-compute-wave:   2953.33--2953.52 cycles/K128
  strict time penalty:       about 15.5%
```

full-payload strict 与 consumer-only strict 相差不到 1%，说明 8 条 global-to-LDS
确实几乎全部被另一条 wave 的计算隐藏。失败点不是 producer，而是同一 SIMD 同时只
剩一条 compute wave，无法再用第二条 resident compute wave 遮盖 LDS/MFMA issue
空隙。

为排除 all-loads-first 人为放大该损失，又实现了贴近 winner 的 segmented consumer：

```text
A0 + B0 + B1-head
lgkmcnt(9)
第一对 MFMA
提前发 A1，lgkmcnt(9)
完成前 16 条 MFMA
发 B1-tail
完成后 16 条 MFMA
每两条 MFMA 使用 winner 同型 sched-group barrier
```

该 probe 的两种 schedule 均为 248 VGPR、139264 B LDS、0 spill、2 waves/SIMD，
每轮仍严格是 24 条 `ds_read_b128` 和 32 条 scaled MFMA，且计时区没有 G2L。在
GPU 7 短暂回到 0% busy 后，以 `warmup=5, iterations=3` 重跑三组 ABBA，结果为：

```text
segmented aligned:           2391.4--2393.7 cycles/K128
segmented strict stagger:    2545.2--2546.3 cycles/K128
strict time penalty:         about 6.4%
all outputs:                 bit-exact
```

因此细粒度 LDS/MFMA 调度可以缩小损失，却不能反转结论。`2545` 还是一个完全删除
计时区 G2L 的理想上界；它已比既有 rolling ATT 的约 `2370 ticks` 慢约 7.4%，比
3 P 的约 `2096 ticks` 预算慢约 21.4%。按健康 MI350X winner 比例折算，其乐观上限
只有约 `2.47 P`，加入真实 producer 不可能把它推到 3 P。

#### 27.8.2 真实 shared-LDS 生命周期与 12/4 producer

不能把当前 8-wave producer layout 直接限制到任意四条 wave。每个 group 对每个
16-KiB A/B half 只覆盖 8 KiB；必须让四条 active producer wave 遍历两个虚拟
`producer_n` 才能填满整个 half。正确 remap 后：

```text
G0 (wave 0--3): A0 + A1 + B0 = 12 direct-LDS loads/wave
G1 (wave 4--7): B1           =  4 direct-LDS loads/wave
总 payload:                       64 KiB/K128
```

安全的两个 barrier epoch 为：

```text
G1: load B1(next) + wait -> H1
G0: consume(current)     -> H1

G0: load A0/A1/B0(next) + wait -> H2
G1: consume(current)            -> H2

H2 后才交换 current/next stage
```

两个 stage 足够：两个 producer 写 next 的不重叠区域，两组 consumer 只读 current；
H2 同时保证 next 完整发布和 current 的最后一个 reader 已退出。严格执行中点换班最少
需要两个 barrier epoch/K128，不能保持 winner 的一个 barrier/K128。

`probe_wave_shared_asymmetric.cu` 按此实现了 G0 12-copy/G1 4-copy、双 64-KiB
shared stage、每 tile/每 1-KiB chunk 不同的有限 FP8 输入，并保存所有 lane 的
accumulator 做逐 bit 对比。资源与结果：

```text
rolling probe:     238 VGPR / 34 SGPR / 139264 B LDS / 0 spill / occ 2
asymmetric probe:  248 VGPR / 41 SGPR / 139264 B LDS / 0 spill / occ 2
correctness:       all comparisons bit-exact
```

当前节点 8 张 MI355X 均为 100% busy、约 92% VRAM，因此 host event 时间无效，只看
block 内 device-cycle。一个连续稳定窗口的 9 组 ABBA 为：

```text
rolling reference: 3670.55--3676.17 cycles/K128
12/4 asymmetric:   3873.11--3875.95 cycles/K128
candidate time:    about +5.1%--+5.5%
```

这再次证明 shared-LDS 生命周期和错相机制在功能上可行，但正确实现后性能方向仍为负。

#### 27.8.3 历史核对和最终决策

提交 `5bfe154` 的早期 kernel 已使用相同的 `wave_id_n` barrier-epoch 错相，但它是
约 8 barriers/K128 的细粒度 quadrant pipeline；唯一可核对性能是 4096 方阵约
`1.172--1.179 P`，不能与当前 8192 winner 直接比较，也不存在单独开关条件 barrier
的 ABBA。`201ffc0` 的约 2.15 P consumer-major 版本已经取消该错相，`8ce1bea` 的
约 2.30 P rolling 版本进一步收敛为一个 barrier/K128。历史上没有“高性能错相版本”
可直接恢复。

最终判定：**严格的一条 wave 计算、另一条 wave 搬运、再交换角色路线 NO-GO**。
它成功隐藏了搬运，却以更大的 compute issue 损失和第二个 barrier 为代价，因此不接入
正式 GEMM，retained winner 保持不变。若继续冲 3 P，只考虑让两条 resident wave
大部分时间都参与计算、在各自 wave 内细分 LDS/MFMA 并提前发 VMEM 的路线；不再做
exclusive producer/consumer wave 分工。

### 27.9 尾部 operand carry 与完整 producer 前移：NO-GO

在不减少两条 resident wave 的 MFMA 工作量、仍保持一个 workgroup barrier/K128 的
前提下，`probe_wave_operand_carry.cu` 测试了把 next tile 的 LDS operand read 放到
当前 tile 最后 12 条 MFMA 之间。两种顺序分别按 operand 的线性死亡顺序和 B-group
顺序发射，输出均与 reference bit-exact。GPU 7 上重跑 `256 blocks x 256 loops` 的
ABCCBA device-cycle 结果为：

```text
baseline:       2105.94 cycles/K128
carry-linear:   2202.53 cycles/K128，吞吐 -4.39%
carry-b-group:  2206.54 cycles/K128，吞吐 -4.56%
```

真实 kernel 中另有两个独立 target，把下一 tile 的 producer 分散到尾部 MFMA：

```text
scale_fixed_b_tail_producer  # A/B/scale 全部前移
scale_fixed_b_tail_a         # 只前移 A0/A1
```

在当前 MI355X、GPU 7、`8192^3`、`w500/i500` 的三组
`REF-FULL-AONLY-REF` 中：

```text
reference median:       0.48365 ms
full producer median:   0.50550 ms，时间 +4.52%，吞吐 -4.32%
A-only median:          0.49950 ms，时间 +3.28%，吞吐 -3.17%
```

这两个结果与 carry probe 一致：把 LDS read 或完整 producer 塞入最后 12 条 MFMA
会破坏已经收敛的 MFMA/LDS issue 节奏，不能作为下一轮 pipeline 的起点。

### 27.10 B0 三槽 lookahead：NO-GO

`scale_fixed_b_b0_three_slot` 给 B half 0 增加第三个物理 LDS slot。B0 在前 16 条
MFMA 后已经死亡，候选在 `vmcnt(0) + lgkmcnt(0)` 后、mid-tile barrier 前发射
`B0(t+2)`，希望跨 barrier 保留 outstanding VMEM，同时 B1 继续使用双缓冲。

原始 5 组测试的中位为 reference `0.48535 ms`、candidate `0.48650 ms`，candidate
慢约 0.24%。本轮在 GPU 7 用 `w500/i500` 重跑三组得到：

```text
reference median: 0.48270 ms
candidate median: 0.48425 ms
candidate time:   +0.32%
candidate perf:   -0.32%
```

把等待放宽成 `vmcnt(2)`、试图只等待较老请求的版本还慢约 1.02%。三槽增加 LDS
生命周期但没有改善关键路径，正式判定 **NO-GO**。

### 27.11 SFB 两个 half 合并读取：小幅正收益

`scale_fixed_b_sfb_read2st64` 把相距 512 bytes 的 SFB half 0/1 两条
`ds_read_b32` 合成一条 `ds_read2st64_b32 offset0:0 offset1:2`。展开后的静态
`ds_read` 总数从 162 降到 156，VGPR 从 242 降到 238；LDS、scratch 和
2 waves/SIMD occupancy 不变。

GPU 7、`8192^3`、`w500/i500`、5 组 `REF-CAND-CAND-REF` 的原始时间为：

```text
reference: 0.4835, 0.4832, 0.4834, 0.4833, 0.4822,
           0.4821, 0.4820, 0.4819, 0.4815, 0.4816 ms
read2:     0.4827, 0.4824, 0.4825, 0.4824, 0.4821,
           0.4816, 0.4813, 0.4818, 0.4811, 0.4811 ms

reference median/mean: 0.48215 / 0.48247 ms
read2 median/mean:     0.48195 / 0.48190 ms
median throughput:     +0.04%
mean throughput:       +0.12%
```

绝对收益很小，但 5/5 个交叉 group 的均值方向都为正，并且减少 4 VGPR；因此把它
作为后续 asymmetric-B winner 的组成部分保留，不单独宣称大幅提速。

### 27.12 asymmetric B producer：MI355X 上的新 winner

resident pair 是 `(wave 0,4)`、`(1,5)`、`(2,6)`、`(3,7)`。新路径保持两条 wave
都执行全部 MFMA，只在 mid-tile barrier 后的 next-B producer 段分工：

```text
wave_id_n == 0: 立即进入最后 12 条 MFMA
wave_id_n == 1: 用两个显式 logical wave-N layout 填满 B0/B1，再进入相同 MFMA
```

这与第 27.8 节的 exclusive producer/consumer 不同：producer wave 只短暂落后，
并未放弃计算。最终 target 为 `scale_fixed_b_asym_b_read2`，同时包含第 27.11 节的
SFB read2。静态资源为：

```text
VGPR:                    243
compiler TotalSGPR:      106
next-free SGPR:          100
compiler SGPR spill:       5（spill 到保留 VGPR lane，scratch 仍为 0）
LDS:                  139264 B
occupancy:          2 waves/SIMD
```

正确性覆盖 K=128/256/384/512/1024、batch=2、N 多 tile、persistent 1/2/3/4
output、`4+1` tail、random/unit E8M0，以及 SFA/SFB row/K-group 定向 pattern，
全部为 `ALL BATCHES VALID`。

在当前 MI355X、GPU 7、`8192^3`、`w500/i500` 上，持久构建执行 5 组
`REF-CAND-CAND-REF`：

```text
reference: 0.4836, 0.4838, 0.4830, 0.4830, 0.4830,
           0.4829, 0.4824, 0.4825, 0.4823, 0.4816 ms
candidate: 0.4767, 0.4765, 0.4764, 0.4764, 0.4758,
           0.4758, 0.4758, 0.4757, 0.4752, 0.4755 ms

reference median: 0.48295 ms / 2.2767 P
candidate median: 0.47580 ms / 2.3109 P
candidate time:   -1.480%
candidate perf:   +1.503%
```

5/5 个交叉 group 的 candidate 均值都更快，10/10 个 candidate 样本都超过
2.3 P。本机目标因此已经稳定达到。健康 MI350X 的 `0.4144 ms / 2.6528 P` 仅保留
为历史 reference，不再错误地当作当前 MI355X 的验收数字。

曾把两个显式 logical wave-N layout 合成一个四-wave producer layout。它通过
K=384/1024 正确性，资源和指令总数不变；5 组对照中显式版中位 `0.47640 ms`，
紧凑版 `0.47645 ms`，约 0.01% 差异，属于完全打平。为保留已完成全矩阵验证的版本，
最终源码恢复显式映射；重编 ISA 与保存的已验证 winner 除 HIP CUID 外逐指令一致。

另外两个简化尝试不保留：固定正/负 offset 的版本一个虽正确但约 `0.4955 ms`，另一个
在 K>=384 时错误，其约 2.45 P 的数字无效；让 B0/B1 分给 resident pair 的不同 wave
约 `0.481 ms`，比同一 wave 完成两 half 的约 `0.476 ms` 慢约 1%。

持久构建位置：

```text
build_fixed_b_asym_b_read2/
  gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2.exe
```

### 27.13 asymmetric A producer：NO-GO

在 asymmetric-B winner 上继续让四条 wave 覆盖完整 A0/A1 producer payload，另四条
wave 提前进入 MFMA。映射正确，K=384、batch=2 验证通过，但 VGPR 增到 247；
opposite-role 版本报告 15 个 SGPR spill，same-role 版本报告 12 个，均无 scratch，
occupancy 仍为 2 waves/SIMD。

GPU 7、`8192^3`、`w500/i500` 的交叉结果为：

```text
A 与 B 使用相反 producer wave:
  reference median 0.47660 ms
  candidate median 0.48960 ms，吞吐 -2.66%

A 与 B 使用同一 producer wave:
  reference median 0.47650 ms
  candidate median 0.48270 ms，吞吐 -1.28%
```

同一 producer wave 确实比相反角色少损失，但仍显著慢于 asymmetric-B-only winner。
主循环前半段不足以隐藏单 wave 双倍 A 搬运，且额外寄存器压力抵消了 compute wave 的
领先优势，因此 asymmetric A 判定 **NO-GO**。

### 27.14 B 的 K128 panel 预排布：NO-GO

`scale_fixed_b_asym_b_bpreshuffle_read2` 保持 27.12 的 asymmetric-B 计算和 producer
映射不变，只把 B 从 `[batch][N][K]` 预排为 `[batch][K/128][N][128]`。这样同一
K128 panel 内相邻 N 行在显存中连续，排除原始 8192-byte 行距造成 cache-line 利用率
不足的可能。原始 B 仍用于 CPU reference，GPU 只上传预排后的副本。

资源为 `243 VGPR / 106 SGPR / 15 SGPR spills / 0 scratch / 139264 B LDS`，occupancy
仍为 2 waves/SIMD；K=128/384/512、batch=2 与多 N tile 正确性均通过。GPU 7、
`8192^3`、`w200/i100` 的 ABBA 结果为：

```text
reference A1:   0.4794 ms / 2.2935 P
preshuffle B1:  0.4792 ms / 2.2946 P
preshuffle B2:  0.4782 ms / 2.2994 P
reference A2:   0.4781 ms / 2.2998 P
```

差异完全落在同轮漂移内，且候选多出 10 个 SGPR spill，因此正式判定 **NO-GO**。
这说明原始 B 的大行距不是当前距 2.6 P 约 13% 缺口的主因；retained winner 继续为
`scale_fixed_b_asym_b_read2`。
