# MXFP8_VMEM_INTERLEAVE — 打散循环体的计算/访存分层

承接 `wave_pingpong` 的负结果。那次失败教会的是**工具层级选错了**：
`s_setprio` 是 wave 级的，压不住单类指令，只会连带卡住低优先级 wave 的 load
发射，最后大家在 workgroup barrier 一起等。正确的层级是**指令级**。

## 真正的问题：循环体是分层的，不是交织的

按十分位统计基线 ISA 稳态循环体（barrier 到 barrier）：

```
decile       0  1  2  3  4  5  6  7  8  9
mfma         0  0  0  0  0  0  6 10  8  8    <- 全在后 40%
buffer_load  8  0  0  0  0  4  6  0  0  0    <- 全在前 60%
```

**循环体前 60% 几乎没有 MFMA，matrix core 在那段是空转的。** 这才是 49% MFU
的直接来源，也印证了 350 上观察到的 "prio2 段 20 条 MFMA / 0 条 buffer_load"。

（更正：之前我判断为"均匀交织"，是错的。按行数看是混在一起，按位置看是分层。）

## 两处原因，都在源码里

**1. VMEM 从未被编排。** `sched_barrier_pairs_scale()` 在每个 MFMA 组后调用，
但只排 DS(0x08) 和 VALU(0x02)：

```cpp
sched_group_barrier(0x08, 1, 0);   // DS
sched_group_barrier(0x02, 2, 0);   // VALU
sched_group_barrier(0x08, 1, 0);
sched_group_barrier(0x02, 2, 0);
```

VMEM(0x20) 在整个 kernel 的 group barrier 里一次都没出现过，调度器因此可以
自由地把整块 global load 沉到循环体顶部。本变体加入 `0x20` 一项。

**2. 9 个 `sched_barrier(0)` 把循环体切成了 10 个不通透的区。** 这是决定性的
一条：`sched_group_barrier` 只能在编译器已放进**同一调度区**的指令间排序。
单加 `0x20` 完全无效（干区 load 12→12，反而多一个干区），因为那 8 条
buffer_load 被 `sched_barrier(0)` 锁在自己区内，group barrier 跨不过去。
本变体把稳态循环里的 9 个 `sched_barrier(0)` 一并置于宏保护下。

两处必须同时改才有效果。

## 效果：分层确实被打散

```
        decile       0  1  2  3  4  5  6  7  8  9
off     mfma         0  0  0  0  0  0  6 10  8  8
        buffer_load  8  0  0  0  0  4  6  0  0  0    干区 load = 12

on      mfma         3  9  0  0  0  0  3 11  8 10
        buffer_load  8  0  0  0  0  1  9  0  0  0    干区 load =  1
```

**MFMA-free 区里的 load 从 12 条降到 1 条**，且 MFMA 开始出现在 decile 0-1
（基线前 60% 一条都没有）。结构指标是明确改善的。

资源逐项相同：VGPR 236 / TotalSGPR 86 / occupancy 2 / 零 spill / LDS 139264。
正确性 `errors=0/67108864`，ALL BATCHES VALID。

## 本机结果（GPU7, clang20, b=1, M=N=K=8192）

```
off 0.4514  on 0.4526
off 0.4513  on 0.4528
off 0.4517  on 0.4528
off 0.4518  on 0.4531
off 0.4514  on 0.4531
off 0.4519  on 0.4527
```

**−0.3%，6/6 全输。**

但这与 `wave_pingpong` 的 −0.8%（本机）/ −6.75%（350）性质不同：那次结构指标
和性能同向恶化，是机制性错误；这次**结构指标明确改善、性能小幅回退**，符合本机
带宽饱和的特征——本机 read 6119 GB/s 已打满，把 load 提前发射换不到额外吞吐，
只多付了指令重排的开销。

所以本机数据对这个变体**不构成判决**。350 上 read 7782 GB/s 有 25-40% 余量，
提前发射的 load 有机会真正转化为吞吐。判决必须在 350 上做。

## 预期与判读

- 若 350 上为**正**：机制成立，下一步是调 group barrier 的配比（每组 MFMA 之间
  插几条 VMEM）以及有选择地只放开部分 `sched_barrier(0)`，而不是全放开。
- 若为**零或负**：说明放开 `sched_barrier(0)` 让编译器做出的其他重排（本变体
  body 从 438 行涨到 520 行）抵消了收益，应改为只加 `0x20` 编排、逐个放开
  `sched_barrier(0)` 定位是哪一个在挡路。

注意 on 的 body 是 520 行 vs off 438 行 —— 放开调度屏障后编译器做了别的重排，
这是本变体最大的不确定性来源，不是纯粹的"只移动 load"。

## 复现

```sh
./build.sh                    # off.exe / on.exe，只差一个 -D
GPU=7 ROUNDS=8 ./bench.sh     # smoke test only
```

分层指标（判断成败的直接依据，比时间更有信息量）：

```sh
cd build && python3 - <<'EOF'
for cfg in ('off','on'):
    L=open(f'isa_{cfg}.s').read().split('\n')
    bar=[i for i,l in enumerate(L) if 's_barrier' in l]
    a,b=max(zip(bar,bar[1:]), key=lambda p:p[1]-p[0])
    seg=[l.strip() for l in L[a:b]]; n=len(seg)
    def dec(pred):
        h=[0]*10
        for i,l in enumerate(seg):
            if pred(l): h[min(9,i*10//n)]+=1
        return h
    m=dec(lambda l:'mfma' in l); bl=dec(lambda l:'buffer_load' in l)
    print(cfg, "mfma", m, "load", bl,
          "dry-load", sum(bl[i] for i in range(10) if m[i]==0))
EOF
```
