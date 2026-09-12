# 通用4wave / tile1最新记录：2026-09-12发射调度轮

当前生产版本为 **generic_tile1_issue_20260912**，唯一通用实现为顶层 `tmpl_generic.hpp`，选自 `grid2d_unroll4`。清理前后两种输出的有效机器指令完全一致，正式构建与公开工具的独立重建均按同一编码检查。继续以此通用版本优化，**目标3.5P尚未达到**。

## 执行范围

- tile1表示每WG一个完整256×256输出块，4个Wave64。BF16输出的四个128×128区域不改变tile数量，不重新开启tile2/tile4。
- M/N是正的256倍数，K是正的128倍数，在原有ABI字节数限制内支持连续batch。8192只是性能测试shape；不能恢复只支持8192的主体。
- 保留原生16×16×128 FP8 MFMA、固定256 AGPR、E8M0/AITER输入ABI、零额外device workspace。
- 性能对比固定物理GPU2 = HIP2，PCI `0000:65:00.0`，8192³，同一进程共享所有tensor地址，基线—候选—基线交替。不得用跨卡、跨窗口结果直接计算增益；不改频率/功耗，计时不采telemetry。
- 其他K用于正确性，最终性能按8192、1024、2048、4096顺序记录。提交与push已获用户授权。不要修改或暂存相邻的 `../mxfp8_gemm_16x16x128_blockscale_bpreshuffle_4wave_fp32scale/`。

## 当前性能

本轮比较基线是提交 `9229d1a57f24cdd3da47ba3e03545d08d4f001e1`，冻结源码位于 `results/generic_issue_20260912/baseline_source/`。不要混成上轮的 `f0b117c` 基线。

五轮同地址确认中，BF16从3.258160P到3.286620P，FP32从3.049997P到3.076171P；相邻基线归一化提升中位数为0.862868% / 0.871002%，均5/5轮为正。直接对比unroll4/unroll8，unroll4的配对收益仅0.089204% / 0.158498%，分别4/5、5/5轮为正；这项收益很小。

公开工具独立重建后的五轮复现：BF16基线3.266057P、最终版3.288106P，FP32基线3.056781P、最终版3.080897P；配对提升0.725345% / 0.788958%，均5/5轮为正。该窗口为 `shared_allocations/reproduction_confirm_gpu2/`。

正式构建在GPU2独立五轮中位数：

| M=N=K | BF16 P | FP32 P |
| ---: | ---: | ---: |
| 8192 | **3.286311** | **3.076707** |
| 1024 | 0.162466 | 0.120707 |
| 2048 | 0.794949 | 0.668278 |
| 4096 | 2.811149 | 2.484347 |

记录在 `results/generic_issue_20260912/final_shapes_gpu2/`。不要将短筛选中的单次3.295P作为稳定水平。

## 当前实现

保留上一版SFA-after2/SFB-after20的b64预取、分组AGPR初始化、A0/M0-after30预读并在36后安装、BF16-after20/36/52/64的输出发布以及仅在36处允许独立C stores跨barrier。

本轮新增：

1. 主循环矩阵请求位于MFMA7、9、…、37之后。
2. 每四个请求使用同一个m0基址，immediate为0/1056/2112/3168，VOFFSET减去对应immediate，保持源与LDS坐标一致。
3. 主循环维持priority 1，scale面板重填用0/1切换；倒数第二块保留原来的调度。
4. 二维grid X=N tile、Y=M tile，Z=batch，CLI和C ABI两条launch均更新。已有C字节数限制保证所有合法grid维度有效。
5. unroll4，静态MFMA448条，运行时每K128仍64条。

FP32普通VGPR244、BF16普通VGPR256，另各有256 AGPR，combined500/512；SGPR62，LDS152064B，零spill/scratch。BF16普通VGPR已到256，后续增加预读要检查实际寄存器分配。头文件SHA256为 `69ef190d32fc10127deee1d06286233ecdde498e543a2d6c07d02b11696955be`。

## 验证和避免重复的方向

选定父版在两种输出上通过16组通用K、非方阵、batch2，以及独立完整8192²参考与CLI seed1相等检查。正式版通过LDS/VMEM依赖审查，实际AITER shuffle、两种E8M0 metadata布局、字节B、`out=`、输出分配、非默认stream和完整8192输出均验证。详见 [本轮记录](results/generic_issue_20260912/README.md) 与 `selected/selection.json`。

本轮未采用：release4与最终组合混用、release6/7、wave私有输出、输出LDS基址/VALU分组组合、fragment stream、短B1/A0-M1预读、unroll16。wave私有输出的有效read64/xor版正确但降至约3.07～3.09P；不透明AGPR读取/转换helper有正确性问题，不能重新用于生产。全部候选配置、补丁、验证、失败原因在 `candidate_index.json`、`early_rejections.json` 和 `candidate_patches/`。

ATT用于分析主循环间隙与启动/尾部开销，不能当作性能结果。已有诊断显示组合主循环约2095 cycles/K128，原基线约2123；当前最终unroll4尚无独立ATT。后续如继续分析，可先记录当前版的启动、主循环和输出段，再针对剩余开销提出候选。不要仅因单次计时提升就采用。

## 复现入口

```bash
python3 tools/compare_versions.py --gpu 2 --rounds 5 --validate --tag new_compare
python3 tools/benchmark_shapes.py --gpu 2 --sizes 8192 1024 2048 4096 --rounds 5 --tag new_shapes
```

公开比较工具重建本轮冻结9229d1a基线与当前版本，核对9份源码和两种kernel的有效指令编码；结果保存到 `results/generic_issue_20260912/`。`selected/` 是当前最终源码/配置/ISA快照，`cleanup_equivalence.json` 记录清理等价证明，`patch_reconstruction.json` 验证全部候选可以从冻结基线还原。

临时构建与原始ATT归档位置及逐文件哈希在 `archive_manifest.json`。只清理已验证归档的本轮冗余构建，保留基线、测得的父版、清理版和正式构建审查目录。上一轮3.259P历史见 `CONTINUATION_20260912_GENERIC35.md` 和 `results/generic_opt_20260912/`。
