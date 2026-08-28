# MXFP8_WAVE_PINGPONG — inter-wave producer/consumer overlap（负结果）

目标：让同一个 SIMD 上的两个 wave 处于相反相位——一个算的时候另一个读，
交替进行，消除干等 cycle。

## 硬件前提

- gfx950 **没有 named barrier**。`__builtin_amdgcn_s_barrier_signal` /
  `s_barrier_wait` 需要 `gfx12-insts`，编译直接报错。因此 Hopper 式
  warp-specialized ping-pong（只同步一半 wave）在这代硬件上做不出来。
  gfx9 上唯一能制造相位差的手段是 `s_setprio`。
- wave→SIMD 的分配是 `wave_id % 4`，也就是 `wave_id_m`。所以同一个 SIMD 上
  的两个 wave **必然 `wave_id_n` 不同**。`wave_id_n` 正是 ping-pong 需要的
  分组（按 wave_id 奇偶分是错的——那样同 SIMD 的两个 wave 会落进同一组）。

## 改动

稳态 K 循环体里，基线对所有 8 个 wave 一律 `s_setprio(1)`。本变体改为按
`wave_id_n` 给同 SIMD 的两个 wave 相反的优先级斜率，并按 tile 奇偶交替角色：

```cpp
const bool pp_lead = (wave_id_n == (tile & 1));
// 段 1（前 10 个 MFMA）
pp_lead ? s_setprio(MXFP8_PP_HI) : s_setprio(MXFP8_PP_LO);
...
// 段 2（尾部 12 个 MFMA）角色反转
pp_lead ? s_setprio(MXFP8_PP_LO) : s_setprio(MXFP8_PP_HI);
```

`MXFP8_PP_HI` / `MXFP8_PP_LO` 默认 2 / 0，可在命令行覆盖。

资源无变化：VGPR 236、TotalSGPR 86、occupancy 2、zero spill、LDS 139264 —— 与
基线逐项相同。这不是一个花寄存器的改动，纯粹是仲裁策略。

## 结果（gfx950 GPU7, b=1, M=N=K=8192, best-of-3）

正确性：errors=0/67108864，ALL BATCHES VALID。

| HI/LO | best | perf | vs off |
|---|---:|---:|---:|
| off (基线) | 0.4517 ms | 2.434 P | — |
| 1 / 0 | 0.4548 ms | 2.418 P | −0.7% |
| 2 / 1 | 0.4553 ms | 2.415 P | −0.8% |
| 3 / 1 | 0.4556 ms | 2.413 P | −0.9% |
| 3 / 0 | 0.4557 ms | 2.413 P | −0.9% |
| **1 / 1（对照）** | **0.4514 ms** | — | **0.0%** |

一致地慢 0.7–0.9%，8 轮里 7 轮输，方差极小，不是噪声。而且**与优先级差值大小
无关**——(2,1) 和 (3,0) 一样差。

`HI=LO=1` 这个对照很关键：它保留了分支但语义与基线完全相同，跑出
0.4514 vs 0.4514，逐 ms 相同。所以分支本身零成本，负收益确实来自优先级差异
带来的真实调度效果。

## 350 实测（MI350X, ROCm 7.2 / clang 22, ABBA/BAAB, 16 blocks × 32 样本）

| 版本 | 中位时间 | 中位性能 | 配对几何平均 | 胜率 |
|---|---:|---:|---:|---:|
| off | 0.41805 ms | 2.6301 P | — | — |
| on (2/0) | 0.44910 ms | 2.4483 P | **−6.75%** | **0/16** |
| pp_21 | — | 2.4521 P | −6.49% | 0/8 |
| pp_10 | — | 2.4352 P | −6.59% | 0/8 |
| pp_30 | — | 2.4363 P | −6.38% | 0/8 |
| pp_11（对照） | — | 2.6213 P | −0.35%（噪声，CI −0.88%~+0.18%） | 3/8 |

350 上回退 **−6.75%**，比本机的 −0.8% 严重得多，且 0/16 全败。off/on 资源逐项
相同（VGPR 235 / SGPR 73 / 零 spill）。`pp_11` 与 off 的 ISA 指令流完全相同
（仅 CUID 元数据不同），确认分支成本为零。

350 上 clang 22 未自动展开（静态 MFMA 64 条，`#pragma unroll 4` 未生效）。

### 350 侧给出的机制解释（正确的那个）

`s_setprio` 调整的是**整个 wave** 的指令仲裁优先级，无法单独优先 MFMA 或单独
优先 memory。所以：

1. 高优先级 wave 连续发射 MFMA；
2. 低优先级 wave 不仅计算被推迟，**它的 global/LDS load 也无法及时发射**；
3. 到 workgroup barrier 时，计算 wave 仍然必须等低优先级 wave；
4. 净效果是破坏了原本已存在的重叠。

所有非等优先级组合都回退 6.4%~6.8% 且与优先级差值关系很小 —— 不是参数没调好，
是 wave 级调度这个**工具层级**本身不适合这条流水线。正确的层级是指令级
（`sched_group_barrier`），见 `../vmem_interleave/`。

## 为什么不work —— 我最初的解释（部分错误）

统计基线 ISA 稳态循环体（barrier 到 barrier）的指令分布：

```
seg1  lines=433  mfma=32  ds_read=26  buffer_load=18   s_setprio 1
seg2  lines=  5  mfma= 0  ds_read= 0  buffer_load= 0   s_setprio 0
```

编译器把整个循环体调度成了**一个混合段**：32 个 MFMA、26 个 ds_read、
18 个 buffer_load 全部交织在同一 433 行里，`s_setprio 0` 落在段末只剩 5 行。
源码层面"段 1 = 计算 / 段 2 = 内存"的边界，在 ISA 层根本不存在。

我当时据此判断"每个 wave 内部已经充分重叠"。**这个判断是错的。** 按行数看确实
混在一起，但按**位置**看是分层的（见 `../vmem_interleave/README.md`）：前 60%
的循环体几乎没有 MFMA。真正成立的结论只有一条 —— wave 级优先级是错误的工具，
理由见上面 350 侧的机制解释。

## 复现

```sh
./build.sh                    # off.exe / on.exe，只差一个 -D
GPU=7 ROUNDS=8 ./bench.sh
```

自定义优先级对：
```sh
hipcc ... -DMXFP8_WAVE_PINGPONG=1 -DMXFP8_PP_HI=2 -DMXFP8_PP_LO=1
```
