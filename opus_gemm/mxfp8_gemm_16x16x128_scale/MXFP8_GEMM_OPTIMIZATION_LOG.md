# MXFP8 GEMM 优化记录：1.878 P 到约 2.30 P

本文记录 `8192 x 8192 x 8192, batch=1` 下，从用户标记的 **1.878 P scale 去重版本**
到 **host consumer-major prepack + cooperative global-to-LDS** 的 2.15 P 冻结点，以及之后
8-wave 主线继续推进到约 2.30 P 的实验、收益来源和剩余瓶颈。

当前 2.15 P 源码已经冻结：

```text
commit: 201ffc0d0d89938eb0d00d9195fd3cacbb6fa563
tag:    perf-2p15-consumer-major-coop-lds-20260824
```

在该冻结基线上继续比较过 LDS-head split、B1 lookahead、two-tile-ahead 和
grouped-M。最终只保留实测最优的 `a0-l1`：原单 tile-ahead pipeline，加固定的
LDS 首段精确 wait split。实验宏和其他实现分支均已从正式源码删除。

上面描述的是第 13 节形成时的冻结状态。之后工作树曾重新加入一组实验宏，并完成
第 14～18 节记录的候选筛选。2026-08-27 收敛后，获胜配置已经固化为唯一正式路径，
实验宏、失败分支和无用 helper 均已删除；第 19 节记录的是约 2.24 P 的 u4 保存点，
第 20 节继续收敛到约 2.30 P。现在默认 `make scale` 构建的是第 20 节的最终路径。
文档中的历史 `build_*` 名称只表示实验记录，不能据此判断候选有效性。

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

这次结果说明重排现有指令仍有收益，但也把同一结构的边界暴露得更清楚：稳态间隔
`2370 ticks` 距现有 64 条 resident-wave MFMA 的约 `2048 ticks` 计算下限只剩约
`13.6%`。即使把这部分调度开销全部消掉，也不能可靠地覆盖从约 2.30 P 到 3 P 所需
的约 23% 时间缩减。因此下一步若继续向 3 P 推进，需要改变 occupancy、每个同步区
间承担的工作量或 MFMA/输出 tile 拓扑；继续微调 cache hint、普通 scheduler 参数或
scale loader 不足以达到目标。按当前约束，`32x32x64` 路径暂不进入实现，结构实验
最后再单独进行。
