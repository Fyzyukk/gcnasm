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

## 为什么不work —— 前提就是错的

统计基线 ISA 稳态循环体（barrier 到 barrier）的指令分布：

```
seg1  lines=433  mfma=32  ds_read=26  buffer_load=18   s_setprio 1
seg2  lines=  5  mfma= 0  ds_read= 0  buffer_load= 0   s_setprio 0
```

编译器把整个循环体调度成了**一个混合段**：32 个 MFMA、26 个 ds_read、
18 个 buffer_load 全部交织在同一 433 行里，`s_setprio 0` 落在段末只剩 5 行。
源码层面"段 1 = 计算 / 段 2 = 内存"的边界，在 ISA 层根本不存在。

**每个 wave 自己内部已经是计算盖读取了。** 内存指令早已被调度器均匀铺进 MFMA
流中。所以给 wave 分配"计算角色"和"读取角色"只会造成伤害：被压低的那个 wave，
它被推迟的不是内存指令，而是交织在它内存指令之间的自己的 MFMA。

换句话说，这个 kernel 的 overlap 不是缺在 wave 之间，而是已经做在 wave 内部
了。要再提升 MFU，瓶颈不在"谁在等谁"。

## 复现

```sh
./build.sh                    # off.exe / on.exe，只差一个 -D
GPU=7 ROUNDS=8 ./bench.sh
```

自定义优先级对：
```sh
hipcc ... -DMXFP8_WAVE_PINGPONG=1 -DMXFP8_PP_HI=2 -DMXFP8_PP_LO=1
```
