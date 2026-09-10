# 8-wave 去掉 host scale 重排：方案总览

截至 2026-09-10。**已按用户最新要求补完现有可测候选并统一收尾，不再运行GPU。**
清理后主源码、保留版与coldburst留在活动目录；旧实验完整压缩归档，最终日志移入results。
[代码与构建入口](README.md)；[删除范围与恢复说明](docs/CLEANUP_20260910.md)。
本文是当前入口。此次仅收尾 postrelease 与 coldburst，不扩展新优化或运行被拒绝的图。

## 1. 当前结论

- **继续保留** [build_side_t2_exact4_nohandoff_noprio/kernel.exe](build_side_t2_exact4_nohandoff_noprio/kernel.exe)。本轮约 **2.60–2.61 PFLOP/s**；最后一场完整 N24 测得 **0.4213221 ms / 2.609670P**，历史独立 N24 为 **0.4226095 ms / 2.601720P**。
- Scale 预取候选 `prototype_scale_f4_qhalf_postrelease_20260910/target` 的 N3 曾有 +0.3784%；现已补两次完整 N24，对同场最快保留版分别 **−0.1013% / +0.1964%**，都未超过同场 A/A 差。**确认未建立优势，不替换保留版**。详见[最终补测记录](FINAL_VALIDATION_20260910.md)。
- `coldburst` 的 target/generic **完整准入、target full hash和3组generic正确性均通过**。两次N24为 **2.610810P / 2.631250P**，同场收益 **+0.2015% / +0.8269%**；后一场超过A/A，但较高峰值未跨会话复现。**已测、保留线索，不晋级**。
- **2.7P 尚未达到。** 相对本次保留版仍需约 3.5% 吞吐提升。不能用不同会话的绝对峰值、unit-scale 消融或不完整复测冒充达标。

保留版 SHA256：

```text
69e9a10aedfea1170e545d273bad99198396bfe2d44b2cef929186677cc72921
```

### 最后几组实验版本，避免选错

下表是清理前的实验记录；活动目录只保留retained和coldburst，其余原型可从历史归档恢复。

| 版本目录 | 实际改动 | 正确性/资源状态 | 性能与处置 |
| --- | --- | --- | --- |
| `build_side_t2_exact4_nohandoff_noprio` | 目前保留的本地 scale 路径，T2/nohandoff/noprio | 已验证；248 VGPR / 97 SGPR；143360B LDS | 约2.60P；当前推荐起点 |
| `prototype_scale_f4_pair32_lanelut_20260909` | F4 pair32 合并请求、12-slot cooked LDS、lane LUT | target/generic、full hash、3 generic cases 均通过；250 VGPR | 该次 N3 2.572110P vs 保留2.599920P，慢1.07% |
| `prototype_scale_f4_pair32_qhalf_alignall_20260910` | Q-half bank 变换及完整 consumer prebase；统一数组对齐 | target完整准入/full hash通过，252 VGPR；generic 1 scalar spill，禁止运行 | 同场2.586230P vs 保留2.590990P；追回旧F4约0.61%，未胜保留版 |
| `prototype_scale_f4_qhalf_postrelease_20260910` | 只把 hot gather 移到前一 tile 的共同 release 之后 | target完整准入/full hash通过，252 VGPR；generic仍1 scalar spill，禁止运行 | 两次完整N24分别−0.1013% / +0.1964%，均未超同场A/A；未晋级 |
| `prototype_scale_f4_qhalf_coldburst_20260910` | 只批量发出四组 cold gather，再共同等待、按原序发布；**不含 postrelease** | 双图254 VGPR、106 SGPR、159744B LDS，零所有spill/scratch/AGPR；完整native、target hash、generic3cases通过 | 两次N24为2.610810P / 2.631250P；第二场正向结果未跨场确认，未晋级 |

以上每行的对照来自各自同场测试，不能把不同会话的数字混成排行榜。
“target通过”也不等于“generic通过”。最近这条 F4 线始终要求零 scalar/vector
spill、零 scratch、零 AGPR；generic 失败没有被豁免。

## 2. 去掉 host 重排后的基本设计

输入 scale 仍是原始 row-major：`SFA[M,K/32]`、`SFB[N,K/32]`。
每个 workgroup 自己读取所需 scale，完成转置并发布到自己的 LDS。

```text
GPU row-major SFA/SFB
    → wave 合作 gather
    → VGPR 中整理/转置
    → 本 WG 的 cooked-scale LDS
    → SFA/SFB consumer reads
    → scaled MFMA
```

当前约束：512 threads / 8 waves，256×256×128计算 tile；一个 fused GEMM
launch；无 host scale reorder、无 global packed-scale workspace、无跨 WG
ready flag/polling/grid barrier。T2 表示同一 WG 顺序算两个相邻 M 输出 tile，
**不是**16 waves，也不是同时持有两份 accumulator。

8192³下 T1/T2/T4/T8 分别是1024/512/256/128个WG。这里的 T2 已经在保留版
中实现，不能把另一台机器的 T4→T2 当成尚未尝试的新优化。T2 仍会为第二个
输出加载 SFB；它不是把完整64KiB SFB永久留在片上。

历史上与 fused-pack/预打包实现的性能对照用于背景，不是当前“无全局 scale
workspace”约束内可直接替换的版本。

## 3. 已经尝试的方案家族

“结束”指这组已测实现不值得重复扫参，不表示数学上否定所有同类算法。
表内相对性能均对各自同场保留版；N3只用于筛选，微小收益需独立确认。

### A. 早期配置、移植和调度

| 家族 | 做了什么 | 已有结论 |
| --- | --- | --- |
| T1→T2、T4/T8 | 改每WG输出数，host/device实例同步修改 | T2成为保留基线；T4完整N24吞吐低约0.21%；T8仅128个WG、N3吞吐低约33.96%，本机没有隐式fallback；不再重复这一轮扫描 |
| producer-map / local reuse | 重排SFA/SFB生产wave、尝试本wave复用 | map1/pf3 N24仅+0.142%、6/12组胜，未晋级；若干提前发布位置有真实错误，不能用 |
| SFB aligned b64 / byte scatter | SFB两half合成aligned b64；或用byte store去掉转置 | aligned独立N24吞吐低约0.24%；scatter/组合只有负面的N3筛选证据，受污染N24整体排除，不用于排序或收益归因 |
| queue8 / unroll16 / B split | 扩大K窗口、改变B读分割 | queue8/u16 N24约慢0.69%；B split6约慢0.49%；寄存器减少不自动变快 |
| LDS读顺序 / exact-K / explicit phase / balanced B / rolling B1 | 改代码生成、wait位置与矩阵供数 | 31个候选已经筛过；最佳exact22独立N24仅+0.0519%、6/12组胜，未建立超出噪声的优势；exact6也已完成N3、吞吐低约1.87%；历史待测队列已处理完毕 |
| 128×128、仍8-wave | 通过小tile降低每WG资源、缩短转置 | 正确但仅约1.46–1.49P，吞吐低42–44%；最佳组合耗时约为保留版1.74倍。当前实现结束 |

更早的完整/半量SFB register cache、A/B LDS padding cache、group4 publication、
旧local-reuse/block-order扫描均未留下可晋级版本。Queue-fence的+0.1478%低于
同场A/A的0.4193%；细分prefetch与整体barrier/B集群位置扫描也无赢家。

依据：[移植与早期续测（已归档）](docs/CLEANUP_20260910.md)、
[31候选复测结论（已归档）](docs/CLEANUP_20260910.md)。

### B. Scale 结构与供数路径

| 家族 | 核心思路 | 实测/拒绝原因与处置 |
| --- | --- | --- |
| Fullprepare | 提前完成六步转置，发布位置不变 | source版独立N24只+0.0288%；保留248寄存器的ISA版+0.1609%低于同场A/A0.322%。未晋级 |
| Paired refill | 相邻两组连续gather，仍用原raw队列 | N24仅+0.0821%、8/24轮胜；B-split2后续慢3.46%。未确认收益 |
| Consumer record | 合并SFA/SFB到一个b128 record，少一条consumer LDS读 | LDS指令和FIFO下降属实，但N3慢1.16%；额外复制/字节量与调度有成本 |
| Prefetch epoch / consumer ahead | 提前raw定义或提前consumer读 | wave-N分时初始微利未在独立N24复现；consumer ahead慢1.38%。不是最新postrelease方案 |
| F2 raw slab | 32行×32B合取，经额外16KiB raw LDS再读回 | TCC少10%，但增加LDS read/FIFO压力；plain/XOR慢0.71/0.83%，DQ/PF1慢3.00%。结束这组实现 |
| F2 register-only | lane/lane+32合取，用swap恢复队列，不加raw LDS | TCP前端access未下降；初版scratch拒绝，两个target修复慢7.50/2.92%。未有合格generic |
| Adjacent F2 direct | 真正相邻lane合取，直接生成cooked数据，masked b128发布 | 多个版本被private storage/spill拦下；可运行cold-remat target慢1.50%，尽管TCP/bank计数下降。generic拒绝 |
| Aligned F2 cooked | 单raw4，两个cohort直接发布cooked环 | 初版慢6.59%；mod4/captured stride去掉hot SMEM后仍慢1.35%；两种consumer-prebase后续因unroll/立即数折叠未达标而拒绝 |
| F4 diagonal/power2 | 单raw4，cohort环深1/2/4/4，保留六步转置 | TCC少13.125%，初版慢0.72%；hot full-EXEC改进未证明超过保留版，cold mask仍必须保留 |
| F4 pair32 + lane LUT | 四lane对齐32B窗口对；period8、每kind12个cooked slots | TCC少13.75%，但bank冲突多72.92%、N3慢1.07%。引出Q-half改进 |
| Q-half + prebase/alignall | 只翻转slot内role bit6，分散producer bank；consumer逆变换 | bank问题明显缓解，吞吐追回约0.61%；仍未超过保留版。是后续时序实验的共同基底 |
| Q-half postrelease | hot gather移至前一phase1共同release后；读取数不变 | target两次N24分别−0.1013% / +0.1964%，未超同场A/A；generic仍拒绝。已完成复核，未晋级 |
| Q-half coldburst | 四cold gather批量发出，原序发布；hot单raw4不变 | 双图完整准入及GPU正确性通过；N24收益+0.2015% / +0.8269%，后一场超A/A但未跨场确认，已测未晋级 |

各实验精确目录、资源、原始结果见
[scale_candidates_20260909.json（已归档）](docs/CLEANUP_20260910.md) 和
[scale深挖总账（已归档）](docs/CLEANUP_20260910.md)。

## 4. Scale 路径目前真正证实了什么

### 请求合并有收益空间，但不能只看字节数

受控 **unit-scale-only** 地址消融保留原指令/寄存器/发布/同步，只将gather地址
合并：N24约少3.435%时间，TCC请求下降；它不是任意scale正确的GEMM候选，
不能用它的绝对性能宣称2.7P。删除工作可能改变调度，所以普通删代码消融
也不是严格的计时下界。

### Q-half 确实修复了新增的bank成本，但FIFO仍在

下面是同一三图profile中、每个dispatch均一致的计数；profile时间不用于选优。

| 计数器 | 保留版 | Pair32 lane-LUT | Q-half alignall |
| --- | ---: | ---: | ---: |
| TCP_TCC_READ_REQ |41943040|36175872|36175872|
| SQ_INSTS_LDS |13893632|13926400|13926400|
| SQ_LDS_BANK_CONFLICT |6291456|10878976|6684672|

Q-half保持请求少13.75%，bank冲突较旧pair32少38.55%，只比保留版多6.25%；
但FIFO-full均值仍约高15.11%。因此下一步的主要线索是 **供数时机、发布与
等待重叠、冷启动串行化以及地址/控制开销**，不是再次增加raw LDS搬运。
这些是聚合计数，不能直接相加成耗时，也不能当成精确逐指令归因。

### 两个最新时序方案必须分开看

- **Postrelease**：`gather(j)`从`tile=4j-6 / MFMA2`移到`tile=4j-7 / MFMA20 release之后`。同tile先完成旧pair2，再发新gather；tile1也必须独立发j2。下一phase2 VM0完成raw，之后phase3才消费。native确认deadline前有32条MFMA，而旧路径18条；不是性能百分比承诺。
- **Coldburst**：只合并冷启动的四组gather。cold逻辑raw由4增到16，hot仍4；gather/转置/发布次数不减。编译器实际使用partial VM6/VM7和共同VM0，不能把删掉三个source VM0解释成native少三条wait。它还牺牲了部分原cold发布与后续VMEM的交叠；补测结果已记录，不能仅从source wait减少推断收益。

## 5. 代码生成与验证中不能忘的坑

| 问题 | 已发生的具体结果 | 后续约束 |
| --- | --- | --- |
| 寄存器/私有对象 | F2多版scratch拒绝；F4 explicit3次scalar spill，Q-half2次，consumer-prebase1次 | `.vgpr_count`已包含AGPR，按8向上取整；当前F4严格零所有spill，不要改gate迁就失败图 |
| LDS对齐改变数组顺序 | 只给scale加256对齐将其移到LDS前端，矩阵base常量变多；所有数组同对齐后恢复原顺序 | source对齐只保证alignment，不保证顺序；看实际native base及总159744B |
| constexpr不等于立即数折叠 | F2 switch版unroll失败；typed loads版仍逐tile做地址运算 | 检查MFMA展开数、literal DS offsets、hot SMEM及实际动态路径 |
| 转置/EXEC | cross-lane swaps和swap32输入必须full EXEC；末两条纯lane-local perm可被cold mask包住 | 不要把“最后两条可交换”扩展为整条网络都可mask；cold有效Q mask不可删 |
| tr_b8指令语义 | 另一机器uniform-address probe显示每16lane只有首lane提供地址 | 不能按任意per-lane地址CPU模型假设它能做跨行scale gather；本机也无获胜替代方案 |
| v_perm literal | 本机gfx950工具链拒绝四个真实mask literal，SGPR/VGPR形式可编码 | “把一个常驻SGPR改成单条literal v_perm”这条捷径已关闭 |
| 机器状态/双峰计时 | 多次A/A差大于候选收益，另有污染或GPU占用中断 | 使用同场最小值、A/A及独立复测；不能用median、目录名clean或很小方差证明有效 |

旧rawslab/adjacent记录曾有明确限定的scalar-lane admission；它们是历史例外，
**不能继承为当前F4零spill要求的豁免**。

## 6. 中断历史、最终补测与收尾范围

Postrelease的N3已完整结束，4个标签均通过full hash：
[screen summary](results/results_scale_f4_qhalf_postrelease_screen3_20260910/summary.json)。

较早两次N24曾中断，记录如下；用户后来明确恢复后，已另建两次完整N24会话：

| 目录 | 实际留下的数据 | 状态 |
| --- | --- | --- |
| `results_scale_f4_qhalf_postrelease_confirm24_20260910` | 2轮、6条观测 | 第3轮前GPU7出现其他进程，guard停止；quality明确不用于选优 |
| `results_scale_f4_qhalf_postrelease_confirm24_retry1_20260910` | 15完整轮、45条观测 | 用户要求停止，root中断；不是N24、没有最终after-run检查，不能确认收益 |

不把N3、被占用中断和用户中断的样本拼成N24；原始记录保留。后来的两次完整
N24分别为−0.1013% / +0.1964%，未建立超出A/A的优势，详见
[最终补测记录](FINAL_VALIDATION_20260910.md)。没有为postrelease采集新profile。
暂停阶段仅整理文档；随后按用户明确指令恢复了现有候选的补测。

### 本次收尾范围与未实施提案

1. **Postrelease**：完整N24 + A/A及独立N24复核均已结束，不晋级。generic仍不得运行。
2. **Coldburst**：完整source/native/sync准入、generic3cases、target full hash、N3与两次完整N24均结束。第二场2.631250P峰值保留，不剔除，但没有跨场确认，不晋级。
3. **Producer complete-base缓存**：只完成CPU提案，尚无源码/二进制，不在此次补测范围。pair0算一次完整地址，pair2用write2 `(128,130)` dword立即数复用；需要一个跨tile逻辑32-bit缓存。Q-half旧图可望删去每有效j的1 SALU+9 VALU，但新图资源/收益未知，且提案仍需绑定alignall源码。
4. 当前 **没有postrelease/coldburst组合版**；此次收尾不构建新组合。

无需重复：已结束的producer-map/散写/queue widening/B split/128tile扫描，或仅
因几条指令变少就重跑整族。2.7P尚未实现，本次收尾不包含继续拓展寻优。

清理前清单核对已闭合：32个scale候选、53个镜像路径全部有状态，其中23个已验证
未晋级、7个资源拒绝、2个codegen拒绝；没有合格但遗漏未测的镜像。被拒绝图未运行。

## 7. 复现信息与文档入口

固定性能合同：`8192³, batch1, warmup200, iterations100, GPU7,
MXFP8_RANDOM_SEED=20260909, OMP_TOOL=disabled`；full output hash
`bb8d97357b61bd71`。短`w0/i1`只用于正确性。每条正式观测本身是100次launch平均，
N24取24条正式观测中的最小值，不是单次launch最小值。

工具链：`/root/toolchains/rocm-llvm23-46fcb339-build`；ROCm `/opt/rocm`；
OPUS include `/root/workspace/aiter/csrc/include`。新实验fresh目录、target/generic
各单次构建；不要覆盖保留版、冻结源码或失败镜像。

| 要找什么 | 入口 |
| --- | --- |
| 本次整理与最终状态 | 本文 |
| 恢复后的最终补测证据 | [FINAL_VALIDATION_20260910.md](FINAL_VALIDATION_20260910.md) |
| Scale全量实验及测量证据 | [OPTIMIZATION_SCALE_PATH_20260909.md（已归档）](docs/CLEANUP_20260910.md) |
| Scale候选机器可读清单 | [scale_candidates_20260909.json（已归档）](docs/CLEANUP_20260910.md) |
| 早期移植实验 | [OPTIMIZATION_RESULTS_20260909_CONTINUED.md（已归档）](docs/CLEANUP_20260910.md) |
| 31个早期候选的最终验证 | [OPTIMIZATION_RESUMED_GPU_20260909.md（已归档）](docs/CLEANUP_20260910.md) |
| 早期候选清单 | [offline_candidates_20260909.json（已归档）](docs/CLEANUP_20260910.md) |
| 最新预取源码/资源/状态 | [postrelease README（已归档）](docs/CLEANUP_20260910.md) |
| 冷启动候选、完整准入与GPU结果 | [coldburst README](prototype_scale_f4_qhalf_coldburst_20260910/README.md) |
| 未实现的地址缓存提案 | [F4_QHALF_PRODUCER_PREBASE_CPU_PROPOSAL.md（已归档）](docs/CLEANUP_20260910.md) |

性能记录中的P均指PFLOP/s。另一机器日志的0.374ms/2.934P预打包参考以及该次
无效timing不能直接搬来排列本目录版本；本机结果以固定合同和同场对照为准。
外机0.374ms不是本机的绝对有效性门槛；本机保留版历史正常区间约0.42–0.43ms。
删代码消融变慢本身不足以证明机器状态失效，须结合同场A/A、基线轨迹与进程记录。
