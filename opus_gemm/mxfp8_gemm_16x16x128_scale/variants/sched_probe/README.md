# sched_probe — 逐个屏障归因

承接 `vmem_interleave` 在 350 上的判零结果（80+80 样本，中位数逐位相同，
CI −0.146%~+0.329%）。那个变体同时做了两件事，无法归因：

1. 在 MFMA 调度组里加 VMEM(0x20)；
2. 一次性放开稳态循环里的全部 sched_barrier(0)。

本变体把两者拆成正交的两个旋钮，并给屏障编号，以便逐个定位。

## 旋钮

```
-DMXFP8_VMEM_GROUP=1        在 sched_barrier_pairs_scale() 里加 0x20
-DMXFP8_SCHED_RELEASE=<掩码> 位 i 置 1 => 移除稳态循环里的 barrier i
```

**更正**：稳态循环里是 **8 个** sched_barrier(0)（编号 0..7），不是我之前说的
9 个 —— 另外两个在 prologue（主循环之前），不参与。所以全放开是 `255`。

## 扫描结果（本机 clang20）

`./scan.sh` 编译全部候选并只报告结构指标，不计时：

```
candidate  VGPR SGPR spill occ  body  dry  verdict
base        236   86     0   2   438   12  control
vmem        236   86     0   2   454   15  reject (dry 12->15)
vmem+b0     236   86     0   2   454   15  reject (dry 12->15)
vmem+b1..b5 236   86     0   2   454   15  reject   (与 vmem 完全相同)
vmem+b6     236   86     0   2   451   15  reject (dry 12->15)
vmem+b7     236   86     0   2   527    1  CANDIDATE (dry 12->1)
vmem+all    236   86     0   2   520    1  CANDIDATE (dry 12->1)
```

**8 个屏障里只有 barrier 7 有效。** b0-b6 单独放开的产物与 `vmem` 逐项相同 ——
它们根本不挡路。`vmem+b7` 单独就拿到了 `vmem+all` 的全部效果。

## 归因：收益全部来自放开 b7，0x20 是有害的

补一个不加 VMEM 编排、只放开 b7 的纯化版本（`MXFP8_SCHED_RELEASE=128`）：

```
base      body= 438 dry= 12  mfma  0  0  0  0  0  0  6 10  8  8
vmem      body= 454 dry= 15  mfma  0  0  0  0  0  0  7  9  8  8
b7only    body= 505 dry=  1  mfma  2 10  0  0  0  0  1 12  9 10
vmem_b7   body= 527 dry=  1  mfma  2 10  0  0  0  0  3 11  8 10
```

- `b7only` 不加任何 group barrier，dry 就从 12 降到 1。**全部收益来自放开 b7。**
- `vmem` 单独使 dry 从 12 涨到 15，**方向是负的** —— 与 350 上 clang22 观察到的
  dry 5→9 方向一致。`0x20` 这一项从头到尾就是设计错误。
- `vmem_b7` 的 dry 同样是 1，但 body 比 `b7only` 多 22 行，是多余的重排。

**所以推荐候选是 `b7only`，单变量，不加 group barrier。**

## barrier 7 是什么

它是钉住 B(t+2) 生产者的那道墙 —— 即 `MXFP8_ASYMMETRIC_B_PRODUCER` 那块的
4 条 `buffer_load` 之后：

```cpp
    async_load<T::VEC_B>(g_b, ... gb_offset(0, tile + 2));
    async_load<T::VEC_B>(g_b, ... gb_offset(1, tile + 2));
    SCHED_BARRIER_N(7);     // <-- 这道墙
}
```

放开它，这 4 条 load 才能下沉进尾部 MFMA 流；其余 7 道墙圈住的都不是热点。

## 本机结果（clang20, GPU6, b=1, M=N=K=8192）

正确性：`errors=0/67108864`，ALL BATCHES VALID。

```
base 0.4486  b7only 0.4517  vmem_b7 0.4512
base 0.4494  b7only 0.4521  vmem_b7 0.4513
base 0.4490  b7only 0.4522  vmem_b7 0.4521
base 0.4484  b7only 0.4520  vmem_b7 0.4526
base 0.4495  b7only 0.4514  vmem_b7 0.4522
base 0.4491  b7only 0.4519  vmem_b7 0.4516
```

b7only −0.65%，6/6 输。与前两个变体一样：本机 read 6119 GB/s 已饱和，结构改善
换不到吞吐。**本机数据对这类改动不构成判决。**

（注：首轮在 GPU7 上测到 1.6-1.7ms，是别的进程占满了卡，已换 GPU6 重测。）

## 350 判决（clang22）：0 个 CANDIDATE，线路关闭

```
candidate   body  dry   判定
base         560    5   control
vmem         576    7   reject
vmem+b0      575    7   reject
vmem+b1..b5  575~576 7  reject
vmem+b6      578    8   reject
vmem+b7      575    7   reject
vmem+all     577    9   reject
b7only       559    6   reject      <- 纯化版，单独补测
```

资源全程无污染（VGPR 235 / SGPR 73 / spill 0 / occupancy 2）。

三条结论：

1. **`0x20` 在两个编译器上都有害**，确认是设计错误，不是编译器差异：
   clang20 dry 12→15，clang22 dry 5→7。
2. **b7 的有效性是 clang20 专有的**。clang20 上它把 dry 从 12 打到 1；clang22
   上纯 b7only 反而 5→6。b0-b6 在两个编译器上都无效。
3. **clang22 基线本来就没有可修空间**：dry 只有 5，MFMA 从 decile 5 就开始，
   不存在 clang20 那种"前 60% 全空"的大块分层。

`scan.sh` 的候选列表**漏了纯 b7only**（只有 `vmem+b7`），是本脚本的缺陷；
判决所依据的那一行是手工补编的（`-DMXFP8_SCHED_RELEASE=128`，不定义
`MXFP8_VMEM_GROUP`）。已在下面的用法里补上。

**指令排布路线到此关闭。** 连同 wave_pingpong（−6.75%）和 vmem_interleave
（判零），三次尝试都没有拿到收益。剩余缺口不在搬运的时机，在搬运的字节量。

## 用法

```sh
./scan.sh                       # 编译全部候选 + 结构筛选，不计时
ONLY="base vmem" ./scan.sh      # 只跑指定候选
ONLY="base b7only" ./scan.sh    # 纯化版：放开 b7，不加 group barrier
```

单独构建 b7only：

```sh
hipcc ...gemm_a8w8_mxfp8_scale_kernel_sched_probe.cc $FLAGS \
      -DMXFP8_SCHED_RELEASE=128 -c -o k.o
```

**先跑 `./scan.sh` 看你 clang22 上的表，再决定拿哪个进 ABBA。** 如果 clang22 上
b7 不是那个有效位（很可能，因为你的 off 基线 dry 只有 5、MFMA 从 decile 5 就
开始），表会直接告诉你是哪一位，或者告诉你八个位置都没有 CANDIDATE ——
那就说明 clang22 的调度本来就没有这个可修的空间，这条线可以关掉。
