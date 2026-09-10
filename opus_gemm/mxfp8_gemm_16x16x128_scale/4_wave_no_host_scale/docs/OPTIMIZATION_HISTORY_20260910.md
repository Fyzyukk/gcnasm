# 4-wave 无 host scale 重排 GEMM：优化记录（2026-09-10）

本次七候选补测及独立选择确认已完成，最终选中 **`b_contig_common_vaddr_v1`**：保留 `prepared_scale_c11_after4` 的 scale 流水线，采用 B producer 连续 LDS 行与共用 vaddr 的地址生成改进。相对 after4 的两轮候选 min-of-N24 收益为 **+1.8421%、+2.0702%**。最终打包版已重建并通过正确性、单 kernel 合同验证及独立完整 N24 复验：8192³ 的 min 为 **0.451738954 ms / 2.433953543 PFlop/s**。全部完整性能批次合计 **528 个样本**；打包复验确认同一 native kernel 的性能，没有新增优化收益声明。实际清理状态以 [CLEANUP_20260910.md](CLEANUP_20260910.md) 为准。

本文以 after4 为历史机制基线，第 6.3 节说明最终 common-vaddr 增量。**第 6.2、7 节性能表是历史 ABBA 测量；第 8、9 节记录 2026-09-10 本次完整 N24 结果、正确性与收尾状态，两类性能数据不混用。** 源码入口使用本目录的 [tmpl.hpp](../tmpl.hpp)、[traits.hpp](../traits.hpp)、[host.cc](../host.cc)、[kern.cc](../kern.cc) 和 [gemm_a8w8_mxfp8_scale_common.h](../gemm_a8w8_mxfp8_scale_common.h)，不依赖旧长目录路径才能理解实现。

## 1. 合同、几何与来源

目标是 gfx950 上的标准 row-major SFA/SFB GEMM：

- 256 个线程，即 4 个 Wave64；wave 拓扑为 `T_M=2, T_N=2, T_K=1`。
- WG 输出 tile 为 `256×256`，K tile 为 128；scaled MFMA 为 `16×16×128`。
- 每 32 个 K 元素共享一个 E8M0 scale，因此一个 K128 tile 对应每行 4 个 scale 字节。
- 本主线是 **exact K=8192**，即 64 个 K128 tile；M、N 是正的 **256 整数倍**，支持 batch。不能把 exact-wrap 直接用于其他 K。
- A 为 `[batch,M,K]`、B 为 `[batch,N,K]` 的原始 FP8 E4M3，计算 `A·Bᵀ`，输出 FP32。SFA/SFB 为原始 E8M0 row-major `[batch,M或N,K/32]`。
- Host 不做 scale packing、不做 B preshuffle；**每个 GEMM 只有 1 次 kernel dispatch、0 字节额外 global workspace**，没有额外转换 kernel。A/B/C/SFA/SFB 自身的 allocation 不属于额外 workspace。
- 本地 common header 保留 96 字节 kernel 参数 ABI；kernel 内部使用 LDS 做必要的 scale 转换，不改变外部布局合同。

旧来源目录名仅用于历史归属：

```text
scale_sfb_k16_carried_raw_coexec_dist22_sfa_k8_raw_k4_queue_exact_k64_wrap_prepared_scale_c11_after4_v1
```

after4 原始 `tmpl.hpp` SHA256：

```text
c44276cd5df57755e05a26433452a990f9c13da43afedf4e78eb7d02886a0669
```

其原始与 recovery 构建的 normalized linked ISA 均为：

```text
f77e1b4bad73e582b4916a9c03b0cc7f161366420ee06f38cd85c28934f78bb6
```

这些 after4 哈希是历史基准身份，不是当前选中源码的哈希。最终身份见 [已验证构建的 manifest 快照](provenance/final_common_packaged_build_manifest.json) 和 [最终验证报告](../FINAL_VALIDATION_20260910.md)；归档状态见 [清理报告](CLEANUP_20260910.md)。最初筛选时同名 `build/` 仍是 after4，不能以当前位置替代历史 manifest 的 SHA256 判断镜像身份。仓库不上传任何 `build*` 目录，历史二进制路径仅作为原机器上的验证记录。

## 2. scale 主线：raw slab、短队列与局部转置

### 2.1 SFA K8 与 SFB K16 raw slab

`tmpl.hpp` 的 `prefetch_sfa_slab()`、`prefetch_sfb_slab()` 将未来多个 K tile 的**原始 row-major scale 字节**直接载入 LDS。这里的 K8/K16 指 K128 tile 数，不是量化 group size：

| 路径 | 缓存范围 | 每逻辑行字节数 | raw LDS | 生产方式 |
| --- | ---: | ---: | ---: | --- |
| SFA K8 | 8 个 K128 tile，即 1024 个 K 元素 | 32 B | 8 KiB | 相邻 2 lane 各读 16 B，两轮覆盖该 wave 的行 |
| SFB K16 | 16 个 K128 tile，即 2048 个 K 元素 | 64 B | 16 KiB | 相邻 4 lane 各读 16 B，四轮覆盖该 wave 的行 |

这把原先稀疏的逐行 scale 请求组织成一行内连续的 32 B／64 B 分组，并摊薄全局 refill 的频率。slab 仍保持原始字节，不是已经转好的 MFMA consumer 布局；后面的局部转置不能省略。

`traits.hpp` 的 `LDS_BYTES=139264` 表示基础 A/B 与双缓冲 consumer-scale 区域。加上 8 KiB SFA raw slab 和 16 KiB SFB raw slab，实际 kernel LDS 是 **163840 B/WG**。两处数字不是矛盾，资源检查应以 linked metadata 的总量为准。

### 2.2 SFA K4 VGPR queue 与 SFB carried raw dword

`prepare_scale()` 保留短的 SFA 四项队列 `v_gsfa_c0..c3`：

1. 每到 `tile_k % 4 == 0`，从 SFA raw slab 一次读取 16 B，即四个 K tile 的 scale dword。
2. 当前 tile 使用 `c0`，随后将 `c1→c0, c2→c1, c3→c2`。
3. 下一次 K4 边界再整体 refill，不把整块 K8/K16 raw slab 都塞进 VGPR。

SFB 使用 `load_sfb_slab_dword()` 按 tile 从 raw LDS 读取一个 dword，放入 `v_gsfb_carried`，在后续 MFMA 区域才执行转置。这是 raw LDS 长缓存与 VGPR 短生命周期的组合；不能把它误解成两个对称的 8/16 深 VGPR 队列。

### 2.3 4×4 byte transpose 与 consumer-scale 布局

`transpose_scale_dword_4x4()` 在 lane `r, r+16, r+32, r+48` 间，把四个逻辑行各自的四字节 scale dword 转成 MFMA 消费者需要的四字节 pack。实现是两级跨 lane 交换配合 `perm` 字节选择：

```text
permlane16_swap → perm → permlane32_swap → perm
```

`publish_scale()` 再把准备好的 SFA、SFB pack 各以一次 `store<4>` 发布到对应 consumer-scale LDS stage。`make_layout_rsfa_scale()`、`make_layout_rsfb_scale()` 定义消费者读取；`mma_scale_one()` 以 M/N repeat 选择 pack 字节。

SFA 的两个 M half 各有一个 dword，M-repeat 的 `op_sel` 只在 0..3 内选择。不能把两半错误地当成一个 dword 的 byte 0..7；同样，`MXFP8_MMA_PAIR` 的 N-group 展开为 `2*g`、`2*g+1`，不是两个相同的 N-repeat。

## 3. prepare/publish 分离与 c11-after4

关键改进不只是“少做多少指令”，而是把准备、发布和消费放到合适的依赖位置。主循环采用双 stage，围绕当前 tile `t` 组织下一 tile 和未来 tile：

| 时点 | 动作 | 避免的依赖集中 |
| --- | --- | --- |
| Prologue | 为 tile 0 prepare/publish，并预先 prepare tile 1 | 首轮无需在循环头现做完整转置 |
| steady 循环头 | 只将已经准备好的 tile `t+1` pack publish 到 next stage | 缩短循环头 scale 转换链 |
| 当前 tile 的 c01 后段 | 读取 tile `t+2` raw SFB，保存在 carried dword | 将 LDS read 与后续 transpose 分开 |
| c11 前 4 条 MFMA 后 | `prepare_scale(future_tile, v_gsfb_carried)` | raw SFB 多获得一些消费前距离 |
| 剩余 12 条 c11 MFMA | 覆盖独立的 SFA/SFB transpose 与准备工作 | 同一段计算区承接这条准备链 |
| 下一轮循环头 | 发布本轮 prepared 的结果 | 形成稳定滚动 |

历史 prepared V0 把 `prepare_scale()` 放在 c11 链前；after4 只把它移到前两个 `MXFP8_MMA_PAIR` 之后，即四条 MFMA 之后。这个位置保留十二条 c11 MFMA 作为重叠空间，历史独立对比证实其有效。

`dist22` 描述的历史源码位置是：raw SFB 读取发起时还剩 6 条 c01 与 16 条 c11 MFMA；after4 又延后到 c11 前 4 条之后才准备 scale。**这些是源码／ISA 的指令距离，不是可以直接换算的实际周期或 stall 时间。**

SFA 的消费者还采用生命周期分离：下一 tile 的 SFA1 使用 `v_sfa1_next` 提前读取；SFA0 则等当前 tile 最后一个 c01 消费者结束后复用原寄存器，在 c11 区域下隐藏下一次读取。

## 4. 计算与访存协同：AGPR、co-execution、partial wait、B1 split、早存 C

### 4.1 固定 C/D 在 AGPR

`MXFP8_PIN_C` 把 64 个四元素 accumulator fragment 放在 `a0:a255`；A/B 与 scales 留在普通 VGPR。编译器硬 pin 补丁使 MFMA 使用 native、tied 的 AGPR Dst/SrcC，输出也直接从 AGPR fragment 发出 store，避免额外 VGPR bridge。

这是已经验证的布局约束，不是本轮重新搜索的方向。需要支持 `amdgpu_pin_agpr` 的 patched clang23；不用 soft pin，不做 ISA/CO 后处理。after4 历史资源为 180 普通 VGPR + 256 AGPR、83 SGPR；最终 common-vaddr 为 **176 普通 VGPR + 256 AGPR、77 SGPR**。metadata 中合计 VGPR 数不能当成“普通 VGPR 超过 256”。

### 4.2 将四次 DTLDS 请求暴露给调度器

`async_load_issue_scale()` 把原本一次 layout-to-layout copy 中的四次 16 B 请求拆成源码可调度的四个 issue；最终版的 B producer 改用 `async_load_issue_b_contiguous_scale()`，A 保留原 helper。`sched_barrier_one_scale()`、`sched_barrier_pairs_scale()` 用 MFMA/VALU 分组描述节奏，A/B 请求组则使用 VMEM-read mask。

目的在于让独立 DTLDS 请求的发射与 MFMA 执行重叠。after4 与最终 common-vaddr linked ISA 都保留 **21 个同 SRD 的 MFMA→4×DTLDS 窗口**，按 SRD 分布为 `[1,10,10]`。

`sched_group_barrier` 是编译调度约束，不是运行时同步；Count 是匹配机器指令的容量，不是周期。LLVM 的区域匹配也不保证一个 group 只约束紧挨它的源码 load，不能把它当成“旁边几个调用”的机械计数。

### 4.3 partial wait 必须依赖真实生命周期

循环头的 `lgkmcnt(6)` 允许较年轻、当前首个 MFMA 不依赖的 LDS 操作继续在途。发起 A1 LDS 读取后的 `lgkmcnt(9)` 利用接下来的 MFMA 仍使用 A0 这一事实。

与此同时，实际 stage 交接仍保留 `vmcnt(0)`、`lgkmcnt(0)` 与 workgroup barrier：当前 tile 的操作数都已进入 VGPR，下一 stage 的全局拷贝及 scale 发布完成后，才释放可复用的 LDS stage。调度 fence 不能替代这些真实的完成／可见性条件。

这也是后续调整 wait 或 load 位置必须重新做 source/ISA 与数值验证的原因。原 4-wave 的优先级指令时机也属于其 pipeline，不应套用其他 8-wave 分支的静态指纹规则。

### 4.4 B1 的 4+2+2 分段读取

`load_b_range_scale()` 将 B1 的八次 LDS 读拆为三个源码窗口：

- `[0,4)`：前四条 c00 MFMA 之后发起。
- `[4,6)`：完整 c00 结束之后发起。
- `[6,8)`：前四条 c10 MFMA 之后发起。

提前消费者得到更长的读取距离，较晚消费者则不必过早占用 LDS issue 带宽。源码两次 load 附近的 DS group Count=4 不应单凭表面数量改成 2；历史机器调度审计表明这些 group 还可能约束更早的 A1 reads。

恢复实验曾把 A1 集中提前，静态 wait/NOP 数下降，但 LDS FIFO 满与 LDS 等待上升并且性能下降。这说明“更早发起”“静态等待更少”都不是晋升证据。

### 4.5 最后 K tile 的早存 C

最终 resident tile 不再发起未来 global load。计算顺序为 `c00 → c10 → c01 → c11`，当 B-half0 对应的 c00/c10 都完成后，立即执行 `MXFP8_STORE_QUADRANT`，与剩余 B-half1 的 c01/c11 MFMA 区域重叠；末尾再写 c01/c11。

每个 quadrant 通过 `MXFP8_STORE_AGPR_FRAGMENT` 直接写出 16 个 fragment，总计 64 次 dwordx4 store。早存只针对已完成的输出，不能提前覆盖仍参与累加的 fragment。

## 5. exact-K64 wrap 的边界

主循环计算：

```cpp
const int future_tile = (tile + 2) & 63;
```

对 K=8192，唯一越界的未来 tile 是最后一轮稳态中的 64，将它折回 tile 0，可以去掉重复的 future producer guard。此时有用的最终 tile 已驻留，折回 producer 所写的旧 stage 在退出稳态后不再作为有用数据消费；实际完成与 stage 复用同步仍保留。

这不是跳过最后一个 K tile，也不是放宽越界访问。它是依赖 exact 64-tile 长度和 stage 生命周期的等价变换。尾部单独消费最后的 resident tile。推广到其他 K 必须重新设计边界，不能只删掉 host 的 `K != 8192` 检查。

after4 的 **384 条 scaled MFMA 是 linked ISA 静态展开计数**，不是一次 8192 GEMM 的动态 MFMA 总数；它与 163840 B LDS、AGPR 布局、零 spill/private/scratch 和 DTLDS 窗口共同构成历史静态证据。

## 6. 纠正遗漏：b_contig_ioffset 是历史正候选

本次审计发现 `b_contig_ioffset_v1` 虽位于隔离区，却有候选专属的 correctness、r4 和 r8 正结果，不能因目录位置将它当作失败版本。此前仅把 after4 当作最终保留上界的结论不完整。

### 6.1 历史 ioffset 机制：B producer 分工和 DTLDS 地址表达

已核对的变化只涉及 B producer 的 `make_layout_gb_scale()`、`make_layout_sb_scale()` 及新增 `async_load_issue_b_contiguous_scale()`，不改 A/scales/consumer 图像，也不引入 host 重排。

令 wave 编号为 `w`，四次请求编号为 `i`：

- 旧 producer 对应 padded LDS 行 `q=4*i+w`，同一 wave 的请求间距为 4224 B。
- 新 producer 对应 `q=4*w+i`，间距变为 `1024+32=1056 B`。
- 四次请求可共用 LDS base/`m0`，immediate 为 `0,1056,2112,3168`，均在 12-bit 范围内。
- global vaddr 使用 `gmem_offsets[i]-ioffset`；硬件再加 immediate，抵消后仍读取新 producer 分工对应的原始 B 元素，而不是 preshuffled B。
- 对同一物理 LDS 行 q，逻辑行关系仍为
  `n=16*floor(q/2)+2*floor(lane/8)+(q%2)`，因此写入给消费者的 LDS 图像不变。

这是分工与地址生成的等价重写，不是 scale transpose 被删除。旧 linked ISA 对比给出 `m0` 写入 122→92、NOP 100→75、SALU 628→561、总指令 1934→1872；普通 VGPR 180→168、SGPR 83→71，AGPR 与 LDS 不变。静态证据支持的解释是减少 B producer 的地址设置与相关调度开销，不能单凭指令数承诺本轮收益。

### 6.2 历史证据

`correctness_gpu7_b_contig_ioffset.log`：四个 exact-K64 用例均通过。候选专属 `results_vs_after4_gpu7_w200_i100_r4/r8` 的历史比较为：

| 历史比较 | 几何收益 | 胜出轮数 | 历史吞吐 |
| --- | ---: | ---: | --- |
| b_contig_ioffset vs after4，r4 | +2.4436% | 4/4 | 2.36100 → 2.41868 PFlop/s |
| b_contig_ioffset vs after4，r8 | +2.2658% | 8/8 | 2.35330 → 2.40672 PFlop/s |

这些是历史 paired-ABBA 结果，不是本次 min-of-N 结果。本次已经补足来源绑定、正确性和独立 N24 比较：ioffset 的收益得到复现，但最终按两次独立 min-of-N H2H 选择略快的 common-vaddr。ioffset 不是错误或明显落后的版本，两者差距只有约 0.12%–0.16%。

### 6.3 最终 common-vaddr：同一 B 图像，共用 vector address

最终 [tmpl.hpp](../tmpl.hpp) 的 `async_load_issue_b_contiguous_scale()` 在第 53 行，B 的 `make_layout_gb_scale()`、`make_layout_sb_scale()` 在第 296、325 行；c01 区域的未来 B0/B1 请求使用这个 helper。它保留上节的 `q=4*w+i` producer 分工和 `0/1056/2112/3168` immediate，但进一步让四次请求共用 `gmem_offsets[0]` 作为 vaddr，把行差与 immediate 补偿放到 scalar offset：

```text
source_row_delta(i) = 16*floor(i/2) + (i mod 2) = {0,1,16,17}
vaddr              = gmem_offsets[0]
soffset            = s_os + source_row_delta(i)*stride_b - ioffset(i)
最终 global 地址    = vaddr + soffset + ioffset(i)
                   = gmem_offsets[0] + s_os + source_row_delta(i)*stride_b
```

因此每次仍读取原始 B 中正确的行/K 位置，写入相同的 consumer LDS 图像；不是改变 B 的外部布局。静态 gate 对 B half 的 16384 字节图像及 393216 个源地址组合完成核对，native ISA 的 10 个 B 请求组使用同一组内的 m0/vaddr。

本次约 2% 的新收益来自 **B producer 地址准备、m0 设置及其调度变化**，不是缩短或删除 scale 转置。对最终源码与 after4 的差异核对显示，`prefetch_sfa_slab()`、`prefetch_sfb_slab()`、`prepare_scale()`、`publish_scale()`、c11-after4 位置和消费者映射均保留。它们目前分别位于 `tmpl.hpp` 第 608、633、673、715 行，`prepare_scale(future_tile, ...)` 位于第 1086 行。

最终 native 资源为 **1920 条指令、384 条 scaled MFMA、176 普通 VGPR + 256 AGPR、77 SGPR、163840 B LDS、零 spill/private/scratch**；m0 写入 92 次、NOP 92 条。common 的总指令与 NOP 比历史 ioffset 的 1872/75 更多，却在本次 min-of-N 指标下略快，再次说明不能按静态指令数单调推断性能。资源口径取自 linked metadata 和静态 gate，不混用 profiler 的寄存器解码字段。

## 7. after4 的历史收益与已经关闭的方向

统一历史条件为 GPU7、8192³、batch 1、warmup 200、iterations 100、paired ABBA；不能与其他机器或本次估计量混合：

| 历史比较 | 几何收益 | 胜出轮数 | 归属 |
| --- | ---: | ---: | --- |
| after4 vs exact-wrap，r4 | +1.4703% | 4/4 | `results_vs_wrap_r4_gpu7.*` |
| after4 vs exact-wrap，r8 | +1.3656% | 8/8 | `results_vs_wrap_r8_gpu7.*` |
| after4 vs prepared V0，独立 r8 | +0.8968% | 8/8 | `results_vs_prepared_v0_r8_gpu7.*` |

这些收益不能相加，也不能将各自参考不同的吞吐数字拼成一个新的测量。after4 目录继承的 `results_vs_exact_k64_wrap_8192_*` 实际属于 prepared V0，不能当成 after4 的证据。

旧 wait6 prepacked 参考可以作为“把 scale 转换成本移到 host 后”的上界，但违反本任务 no-host-repack 合同，不可直接晋升。恢复批次中，A1/B1 group 调整、next-B fence opening、c11 SyncID/count 组合等已经完成负向或低于门槛的独立比较，不因为缺少某个后续轮次就重复已关闭版本。具体关闭名单见 [PENDING_AUDIT_20260910.md](PENDING_AUDIT_20260910.md) 及保存的恢复记录。

## 8. 本次七候选已完成补测

七个候选均通过本轮 source/ISA 核对及完整指定数值测试集，没有候选因数值错误被排除。筛选条件是 8192³/batch1、warmup 200、iterations 100；每个样本为 100 次 GEMM 的平均时间，再对交错采集的 24 个样本取最小值。`gain` 使用较快 A/A 基线的 min 除以候选 min 再减一，不是 paired 均值收益。

[candidates_n24 的原始 summary](../results/candidates_n24_20260910/summary.json) 共 9 labels×24=216 样本，quality 标记 `complete=true, valid_for_selection=true`。较快 after4 基线为 0.461238712 ms，A/A spread 为 0.2831%。

| 候选短名 | 改动 | min ms | vs after4 | 本次处置 |
| --- | --- | ---: | ---: | --- |
| `b0_split4_c01_89_v1` | B0 4+4 放到 c01_8/9 | 0.474690855 | −2.8339% | 不保留 |
| `b0_split4_c01_1213_v1` | B0 4+4 放到 c01_12/13 | 0.477380306 | −3.3813% | 不保留 |
| `b0_split4_c01_pair_between_v1` | B0 两组读分列 c01_6/7 pair 两侧 | 0.463743091 | −0.5400% | 不保留 |
| `b0_split4_c01_pair_between_open_v1` | 上项再开放调度 fence/group | 0.467963815 | −1.4371% | 不保留 |
| `transpose_staged_v1` | SFA/SFB 两级 shuffle 交错排列 | 0.461979151 | −0.1603% | 无超噪声收益，不保留 |
| `b_contig_common_vaddr_v1` | 连续 B LDS 行、共用 vaddr | 0.452895761 | +1.8421% | 晋级；独立复核后选中 |
| `b_contig_ioffset_v1` | 连续 B LDS 行、immediate 补偿 | 0.453406185 | +1.7275% | 晋级；与 common 接近，最终未选 |

旧 gate 的父版 wait/指令数指纹误拒绝与真实 NPAIR/NREP 数学错误已区别处理；本轮没有将错误映射探针修成新候选。布局模型和 opcode aggregate 检查也没有代替 GPU 数值验证。来源、完整日志与脚本快照由 [tools/run_suite.py](../tools/run_suite.py)、[tools/static_common.py](../tools/static_common.py) 和结果 manifest 绑定。

## 9. 本次最终选择、规模验证与完整打包复验

### 9.1 独立 N24 确认：按 min-of-N 小胜选 common

后续三组完整比较的 quality 均为 `complete=true, valid_for_selection=true`。与第 8 节初筛合计为 456 个完整性能样本，再加第 9.3 节最终打包复验的 72 个，共 **528 个完整性能样本**。设备一致为 gfx950、256 CU，HIP visibility 7 对应 PCI `0000:98:00.0`、SMI index 5；不把 HIP/SMI 索引当成相同编号。

| 本次完整批次 | 较快 A/A 基线 min ms | common min ms / PFlop/s | common min 收益 | A/A spread |
| --- | ---: | ---: | ---: | ---: |
| [contig_confirm_n24](../results/contig_confirm_n24_20260910/summary.json)，对 after4 | 0.462160945 | 0.452787220 / 2.428319 | +2.0702% | 0.1368% |
| [contig_headtohead_n24](../results/contig_headtohead_n24_20260910/summary.json)，对 ioffset | 0.452667266 | 0.452135444 / 2.431819 | +0.1176% | 0.0678% |
| [contig_headtohead_recheck2_n24](../results/contig_headtohead_recheck2_n24_20260910/summary.json)，独立再对 ioffset | 0.453220189 | 0.452487707 / 2.429926 | +0.1619% | 0.0184% |

ioffset 在对 after4 的独立确认中也达到 0.453066260 ms、+2.0074%，不是失败候选。common 相对 ioffset 的两次独立 min-of-N 小胜都超过对应 A/A spread，因而按既定 min-of-N 标准最终保留 common。

**不夸大这项选择：** 两次 H2H 的 common paired 几何收益实际为 **−0.1117%、−0.0982%**，逐轮分别 12/24、16/24 胜。因此这里证明的是本次 min-of-N24 指标下约 0.12%–0.16% 的微弱优势，不是 common 在均值、paired 统计或每轮都更快。候选选择数据与第 9.3 节最终打包复验分别记录，不与历史 ABBA、其他机器或 prepacked 上界混算。

### 9.2 正确性覆盖与一 kernel／零额外 workspace

[correctness_complete](../results/correctness_complete_20260910/summary.json) 的 reference、after4 和七候选全部 eligible、`excluded={}`；[final_correctness](../results/final_correctness_20260910/summary.json) 又独立验证 reference、已选 common 镜像和新打包 final 镜像，三者全部通过。两批 quality 均 complete/valid。

每个镜像都完成 8 个 CPU 参考用例（K 全为 8192）：unit 256×256/b1、random 256×512/b1、SFA-K 512×256/b1、SFB-K 256×512/b1、第二 seed random 512²/b1、random 256²/b3、SFA-row 768×256/b2、SFB-row 256×768/b2。两批合计 **96 个 CPU 参考检查**。

每个镜像另外完成以下 3 项全输出回归，两批共 **36 项**：

| 大规模用例 | 输出元素数 | 参考与所有候选一致的 64-bit bit hash |
| --- | ---: | --- |
| 8192³/b1，seed 20260909 | 67108864 | `d7317b3740f24b47` |
| 8192³/b1，seed 20260910 | 67108864 | `712d4716c77aae2e` |
| 1024×512×8192/b3，seed 20260909 | 1572864 | `ddb29e2ff28ae34f` |

大规模结果是对 reference 的全输出 bit hash 回归与有限值检查，**不是**大规模 CPU 逐元素 GEMM 参考；小规模才使用 CPU 数值参考。最终 host 的 14 项非法输入／模式冲突测试也全部在 launch 前正确拒绝，详见最终验证报告。

[single_kernel_trace 的 contract](../results/single_kernel_trace_20260910/contract.json) 绑定最终 executable SHA256，在 8192³/b1、w0/i1 下记录 **1 次 kernel dispatch、1 次 HIP launch、5 次显式 hipMalloc**。五份分别是 A、B、C、原始 row-major SFA、原始 row-major SFB；算法额外 global workspace 为 **0 字节**，不将 runtime/profiler 内部分配混称为算法 workspace。Profiler 时间不用于性能选择。

### 9.3 最终源码身份与已完成的 N24 打包复验

当前最终 `tmpl.hpp` SHA256 为 `06702267a0f0c32c1d8e1b9ff77f60e1264bf1d23b78c1e8b5ee09cdf371b624`；`build/kernel.exe` 为 `6c5a9b271f589b905a3e34469b6f6e284c32c9ac5f3a9989d77eb8752b12c9a9`。最终打包与已测候选的 normalized native ISA 都是 `590bd0440b757862062a03a1c471c1e5f2d896a0c57f6555976e3017a4b937fa`。完整 source/host/compiler/CO 绑定见 build manifest；在身份与正确性检查之外，现已完成实际的最终打包性能复验。

[final_release_retry4_n24](../results/final_release_retry4_n24_20260910/summary.json) 的三个 label 各完成 24 个样本，共 72 个；[quality](../results/final_release_retry4_n24_20260910/quality.json) 为 `complete=true, valid_for_selection=true`。selected 与 selected A/A 使用相同原候选 executable，A/A spread 为 **0.0371064%**。

| 打包复验 label | min ms | PFlop/s |
| --- | ---: | ---: |
| selected | 0.452264607 | 2.431124635 |
| selected A/A | 0.452096850 | 2.432026739 |
| final | **0.451738954** | **2.433953543** |

摘要中的 final 相对较快 selected A/A 的 min 差为 +0.0792263%，但两者 **native ISA 完全一致**；这是独立打包后的性能复验，不把这点差异记作新的 kernel 优化或叠加到相对 after4 的约 2% 收益中。

此前中断的 release 批次全部仍为 invalid，未拼接、未纳入完整样本数。特别是 retry2 在 `r22_p1` 检测到外部 PID 1825077，retry3 在 `r06_p1` 检测到 PID 1841067；即使 retry2 已完成 21 轮，也没有降格采用。完整打包复验只采用本次独立完成的 retry4。早先在开始前中断的 H2H retry 也没有计入上述两次有效 H2H。

完整验证结果与可复现命令见 [FINAL_VALIDATION_20260910.md](../FINAL_VALIDATION_20260910.md)。**实际清理状态、归档位置与恢复映射以 [CLEANUP_20260910.md](CLEANUP_20260910.md) 为准**；本文不把中断数据当作性能证据，也不以清理计划代替清理执行记录。
