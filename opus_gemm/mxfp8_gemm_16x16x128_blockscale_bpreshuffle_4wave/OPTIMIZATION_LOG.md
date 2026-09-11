4-wave blockscale bpreshuffle 优化记录 — 2026-09-10
===================================================

**2026-09-11 第三轮最终状态：** 已选入 `regroll_release8`。GPU2同轮五次CLI中位数BF16为 **3.074901P**、FP32为 **2.975244P**，相对第二轮基线约提升0.30%/0.64%；3.5P目标未达到。当前流程和验证见 [第三轮续记](CONTINUATION_20260911_ROUND3.md)。下文保留历史记录；已移出的实验文件见 [归档索引](results/ARCHIVE_20260911.md)。

**2026-09-11 更新：** K8192 正式模板已选入 A/B producer 分工、BF16 vec8 写回及仅 FP32 启用的 A0 按 M repeat 滚动。正式重建后三轮中位数 BF16 **0.359965 ms / 3.054P**、FP32 **0.372731 ms / 2.950P**；同时间段旧正式版分别为 **0.373216 ms / 2.946P**、**0.382766 ms / 2.873P**。全部维持四 Wave64、16×16×128 MFMA、C 固定 a0:a255、E8M0 输入和零额外 device workspace。新增优化、无效尝试、验证与证据索引见 `CONTINUATION_20260911.md`，下面保留上一轮记录。

当前选用 `scale_panel_direct_roll_a0` 的完整K面板路径（K=8192）与 `plain_sfa_lds` 的通用K路径。正式实现位于本目录；实验源代码保存在 `/tmp/mxfp8_fourwave_bpreshuffle_20260910`。原4-wave源目录和之前8-wave分支未修改。

**结论：正式三轮中位数 BF16 0.372994 ms / 2.948P，FP32 0.382540 ms / 2.874P；没有达到3.5P。** FP32吞吐比本机原4-wave复现提高 4.92%；相同外部契约的8-wave仍快约 1.33%（BF16）。原4-wave的scale分组为1×32，新版为紧凑blockscale，这一比较是实现吞吐坐标，不是同一输入的数值等价比较。

性能口径
--------

全部正式性能使用 MI355X/gfx950、256 CU、物理GPU2（`HIP_VISIBLE_DEVICES=2`，PCI `0000:65:00.0`）、8192³、**b=1/w=200/i=100**。每个值是100次kernel的平均耗时；三轮交替测量，第二轮反序，表中报告三轮中位数，不取偶然最小值。计时不包括输入生成、B预排和数据传输。4-wave每WG一个输出tile；8-wave沿用此前最快的自动配置，每WG四个输出tile。

| 版本 | 中位耗时 ms | PFLOP/s | 三轮耗时范围 ms |
| --- | ---: | ---: | ---: |
| 原4-wave / FP32（原1×32 scale输入） | 0.401344 | 2.740 | 0.401246–0.401472 |
| 新4-wave bpreshuffle / FP32 | 0.382540 | 2.874 | 0.382407–0.382640 |
| 新4-wave bpreshuffle / BF16 | 0.372994 | 2.948 | 0.372964–0.373847 |
| 之前8-wave bpreshuffle / FP32 | 0.377400 | 2.913 | 0.377300–0.377500 |
| 之前8-wave bpreshuffle / BF16 | 0.368100 | 2.987 | 0.367900–0.370600 |

原始命令、exe哈希和15份日志位于 `results/final_comparison/`。8192³达到3.5P需要 **0.314146179 ms**，相对当前BF16还需约 **15.8%** 的时间下降。不能把目标当作实测值或按GPU差异外推。

原版复现
--------

原目录 `../mxfp8_gemm_16x16x128_scale/4_wave_no_host_scale` 需要clang23的hard-pin与AGPR-pin两个补丁。本机在独立 `/root/toolchains/rocm-llvm23-46fcb339-build` 构建了相同基线；原 `/root/workspace/llvm-src` 未改动。工具链manifest见 `results/toolchain_manifest.json`。

重建与原选定native ISA一致：1920条指令、384条静态MFMA、176普通VGPR+256AGPR、77SGPR、163840B LDS、零spill/scratch；规范化ISA SHA256为 `590bd0440b757862062a03a1c471c1e5f2d896a0c57f6555976e3017a4b937fa`。首次本机复现为0.400440097ms/2.745758057P。256²×8192 CPU参考通过；8192²共67108864个输出均有限，输出bit hash `d7317b3740f24b47` 与原reference一致。证据位于 `results/baseline_reproduction/`。

保留的优化
----------

1. B producer适配AITER标准`shuffle_weight(...,(16,16))`，保持合并访问；A仍是原始row-major FP8。没有引入新的B私有预排格式。
2. 外部SFA从1×32改为E8M0 1×128、物理`[K/128,M]`；SFB为E8M0 128×128、物理`[N/128,K/128]`。不生成全局扩充scale，不重新量化A/B。
3. 改用最终scale dword的普通LDS读取，消除TR8 intrinsic触发的保守VMEM drain，恢复矩阵预取与MFMA重叠。
4. K8192一次预加载完整紧凑scale面板。A scale在寄存器中通过quad DPP/byte permute直接打包进最终LDS，省去中间LDS转置和第二次发布barrier；B字节通过`*0x01010101`复制。循环内不再做scale全局加载或scale LDS写入。
5. A dword打包四个M repeat的scale，四个K32 lane group读取同一word，`op_sel`选对应repeat；B dword四字节相同。K128 scale因此在内部复用于四个K32子组，外部张量保持紧凑布局。
6. 下一tile的A0在当前c01计算完成后提前读入，用末尾16条c11 MFMA隐藏LDS延迟；保留B0、SFA0/SFA1的滚动预取、4倍K循环展开、分组调度和必要同步。
7. 其他正K128倍数用通用双stage scale路径，保持同一外部接口、FP32/BF16与batch支持。分派每次只启动一个选中的GEMM。

当前完整K路径为4个Wave64、256×256×128，LDS152064B，普通VGPR156/204加AGPR256（FP32/BF16），SGPR60，零spill/scratch。通用路径LDS139264B，普通VGPR152/204加AGPR256，SGPR70。metadata的vgpr_count包含AGPR，不能把412/460再当作普通VGPR。每dtype的384条MFMA为静态展开计数；8192³动态计数为16777216。

Scale回退原因的证据
-------------------

第一版正确移植使用循环内TR8，BF16只有约2.52–2.55P。`wait_consumer` ISA在future-B DTLDS之后、TR8之前插入额外`vmcnt(0)`。当前LLVM的`SIInsertWaitcnts.cpp`对缺少AA metadata的LDS访问采用公共LDS-DMA跟踪槽，这一保守等待排空了本可与后续MFMA重叠的矩阵预取。

内联TR8加显式LGKM完成等待的诊断版保留真实发布同步，移除这五处静态额外VMEM drain，BF16回到2.843P；普通dword读取进一步达到2.886P。这支持排程/等待解释，不能据此声称TR8硬件本身慢。

三次采样的BF16 profiler摘要：

| Counter（百万） | TR8 wait_consumer | 普通dword | 完整K普通dword |
| --- | ---: | ---: | ---: |
| SQ_WAIT_ANY | 75.746 | 26.201 | 27.796 |
| SQ_WAVE_CYCLES | 254.363 | 202.321 | 200.359 |
| SQ_LDS_BANK_CONFLICT | 18.350 | 23.069 | 16.908 |
| SQ_WAIT_INST_LDS | 3.241 | 4.546 | 2.809 |

普通dword的部分LDS counter更高，但总等待和实测时间更低；不能只按bank-conflict数量选方案。原始命令/CSV在`results/profile_selected/`，当前ISA等待审查在`results/scale_wait_analysis.json`。

其他已测方向
------------

以下是单轮探索值，单位ms/PFLOP/s；不足1%的差别没有当作稳定收益。完整41份匹配源码/exe哈希的实验记录及命令在`results/experiments.json`。TR8较慢对照、raw-B诊断或编译失败项均未进入正式选择路径。

| 候选 | FP32 | BF16 |
| --- | ---: | ---: |
| `wait_consumer` | 0.450783 / 2.439 | 0.431197 / 2.550 |
| `plain_sfa_lds` | 0.392836 / 2.799 | 0.381018 / 2.886 |
| `tr8_no_vmem_drain` | 0.397458 / 2.766 | 0.386716 / 2.843 |
| `scale_panel_plain` | 0.387423 / 2.838 | 0.378262 / 2.907 |
| `scale_panel_direct_pack` | 0.386424 / 2.845 | 0.376545 / 2.920 |
| `scale_panel_roll_a0` | 0.384215 / 2.862 | 0.374955 / 2.932 |
| `scale_panel_direct_roll_a0` | 0.382872 / 2.872 | 0.373712 / 2.942 |
| `scale_panel_roll_a01` | 0.387064 / 2.841 | 0.377173 / 2.915 |
| `plain_sfa_direct_b` | 0.403751 / 2.723 | 0.390174 / 2.818 |
| `tile128x256_singlebuf_vgpr_endfence` | 0.439723 / 2.500 | 0.413704 / 2.658 |
| `tile128x256_agpr128_plain_endfence_fp32` | 0.436214 / 2.521 | — |
| `scale_panel_direct_roll_a0_acontig` | 0.382588 / 2.874 | 0.373792 / 2.942 |

去掉priority/调度屏障、增大unroll、WG分组重排、NT BF16写回、B绕过LDS直入VGPR、A1分片滚动、A producer连续地址化等没有超过选定方案。128×256 tile确实做到2WG/CU：VGPR版最好的BF16约2.658P；AGPR128+普通VGPR120、plain SFA与endfence的FP32为2.521P，也较慢。说明减少LDS/增加占用率本身不足以提高该流水线吞吐；详细结果在`results/tile128_results.md`。

最后补测了8-wave采用的每WG连续四个M tile方案 `scale_panel_persistent4`，在tile间增加完整drain+barrier，保留AGPR256。FP32/BF16正确性通过，单轮分别为 **0.382595291ms/2.873824256P**、**0.372791672ms/2.949399654P**，与当前单tile方案基本持平，未作为新收益或替换正式路径；它还将SGPR增至96、metadata VGPR增至444/480。证据在`results/persistent4/`。

AGPR128 BF16还暴露实验编译器的hard-pin class传播问题，以及另一变体共享zero seed的coalescing冲突；没有为了这些未见优势的候选修改编译器。诊断产物仍保存在临时实验目录的`agpr128_diagnostic/`和`agpr128_conflict_review/`。

最终验证和文件
--------------

- 正式目录全新重建后的源文件和exe/lib/ISA/metadata哈希与集成快照一致，四个kernel的完整规范化ISA与选定候选一致；CFG/backedge LDS寄存器等待检查零hazard，零spill/scratch。见`results/static_validation.json`。
- 真实AITER `shuffle_weight`、uint8/E8M0两种scale载体、两种A_scale metadata、当前stream、输出复用及错误输入检查通过；五个小形状FP32/BF16逐值精确等于CPU参考。见`results/integration_final.log`。
- 8192³的FP32、BF16各67108864个输出，与独立反量化后FP32 GEMM参考全部精确一致。测试使用可精确累加的随机dyadic输入；另有native随机CPU参考测试。
- batch2在K8192（FP32/BF16）和K384（BF16）通过；见`results/batch_validation.json`及对应日志。
- trace确认一次算法GEMM dispatch、零scratch。CLI输入准备有一个ROCm内部`copyBuffer` dispatch，整段trace为两个dispatch；五次hipMalloc分别属于A/B/C/SFA/SFB。GEMM适配层本身没有额外分配或scale转换kernel。见`results/single_kernel_trace/contract.json`。

`tmpl.hpp`为K8192优化实现，`tmpl_generic.hpp`为通用K；`kernel_dispatch.hpp`统一CLI与C ABI选择。布局、scale逐步流程、编译命令和AITER集成边界见`README.md`。本目录提供独立适配层；没有修改AITER主仓的正式dispatch/build注册，也不接受普通FP32 blockscale输入。


## 2026-09-11 第二轮：B scale pair与producer分支合并

正式 `tmpl.hpp` 已选入 `pair_b_early_a_merge` 的清理版本；B LDS面板改 `[K,half]`，一次b64预取两半scale，提前首批A预取，并合并相邻producer角色判断。4wave、a0:a255、MFMA16×16×128、外部E8M0布局均不变。

GPU2、8192³、b=1/w=200/i=100，正式重建后交替三轮：BF16 **0.359300537ms / 3.060145P**，FP32 **0.371294022ms / 2.961296P**。同期上一版3.052679/2.956034P，提升约0.245%/0.178%。没有达到3.5P。

FP32普通VGPR184→176，BF16192，SGPR92→91，AGPR256，LDS152064B，零spill。独立完整输出验证、同CLI输入精确对比及静态机器指令一致性均有记录。完整流程、未采用的TR8/private LDS/m0/WG/A布局实验和测量边界见 `CONTINUATION_20260911_ROUND2.md`；证据见 `results/continuation_20260911/round2/`。
