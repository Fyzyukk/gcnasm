# 最终通用4wave / tile1：2026-09-12

这是提交 `f0b117c` 的历史检查点。当前版本和最新测量见 [后续通用优化记录](CONTINUATION_20260912_GENERIC35.md)。

当前正式版本为 **generic_tile1_final_20260912**，从通用候选 `stream64_batch_output_burst` 清理而来。唯一kernel实现是顶层 `tmpl_generic.hpp`，生产构建只实例化BF16/FP32两种输出。旧 `tmpl.hpp`、`WholeKScaleTraits` 及过时traits别名已从当前构建删除，历史源码和实验继续保留在 `results/`。

用户最新要求是在本次候选比较后，测8192、1024、2048、4096，整理最终代码，然后commit和push。本轮按此收尾；后续继续优化仍以这份通用kernel为基础，长期目标3.5P尚未达到。

## 最终结果

GPU2 / HIP2 / PCI `0000:65:00.0`，M=N=K，batch1，warmup200 / iterations100，CLI seed1，每种输出五轮中位数。性能只计GEMM，不计输入预处理。

| M=N=K | BF16 ms | BF16 P | FP32 ms | FP32 P |
| ---: | ---: | ---: | ---: | ---: |
| 8192 | 0.342066650 | **3.214320** | 0.362748337 | **3.031059** |
| 1024 | 0.014202470 | 0.151205 | 0.018589730 | 0.115520 |
| 2048 | 0.022676940 | 0.757592 | 0.026594579 | 0.645991 |
| 4096 | 0.049726748 | 2.763884 | 0.056115160 | 2.449230 |

原始记录在 `results/final_generic_20260912/final_shapes_gpu2/`。这是清理后正式构建的性能。不能用复现工具smoke测试中的单次3.239P替代上述五轮中位数。

候选确认窗口 `results/generic_migration_20260911/measurements/combo_confirm_20260912_gpu2/` 在同一GPU交替测量：原通用BF16 2.887246P，迁移检查点3.183753P，最终候选3.213513P，保留专用控制3.214235P。最终候选BF16五轮均超过3.2P；FP32为3.029430P。分散写回版3.205744P，选定集中写回版。

## 实现与验证

每WG计算一个完整256×256输出块，4 Wave64。原接口支持M/N正256倍数、K正128倍数；运行时K控制全部矩阵地址和循环。64组scale是可复用缓存容量，超过容量继续加载下一面板，尾面板仅访问有效输入。K128跳过K1预取和倒数第二块。8192也执行同一通用路径。

迁入的优化包括：统一A/B矩阵producer和K1预取；A0/B0分散读取与A1/B1寄存器滚动；MFMA5发布/释放；unroll8；倒数第二块停止无用预取；A1最后一个M repeat提前读取；BF16复用退役矩阵LDS并合并写回。

本次继续优化采用两项：先集中发出四组scale读取、再转置发布，使启动B矩阵请求与scale打包重叠；最后一轮MFMA36后发布前128列输出，集中发出合并写回，与剩余计算重叠。FP32保持直接输出。

资源：FP32普通VGPR252+AGPR256，BF16普通VGPR256+AGPR256，combined508/512；SGPR76，LDS152064B，零spill/scratch。`results/final_generic_20260912/cleanup_equivalence.json`证明清理前后两种通用kernel的全部有效指令编码一致。

- K128、256、384、896、1152、3968、4096、4224、4352、8064、8192、8320、8448、16384、16512、32896，含非方阵和batch2，全部精确匹配独立参考。
- 两种输出在完整8192²的67,108,864个元素上，均精确匹配独立反量化FP32 bmm和CLI seed1基线。
- 最终两种kernel已重新静态检查；`tools/compare_versions.py --rounds 1 --validate`复现流程通过。
- Python适配器、AITER真实shuffle、两种E8M0布局、`out=`、非默认stream检查通过。

## 记录与后续思路

`results/generic_migration_20260911/selected/`保存最终源码、配置、资源审查和选择依据；`migration_checkpoint/`保留3.1855P迁移里程碑。`candidate_index.json`与`screening_summary.json`记录23个候选的全部窗口，`patch_reconstruction.json`证明相对冻结原通用基线的补丁全部匹配哈希。

未采用方向及原因均保留：32组半面板异步预取虽正确但BF16无收益；最终barrier不等待独立C写回与父版几乎相同；提前/分散scale读取收益有限；把面板刷新移到嵌套循环，以及固定VGPR位置，触发编译器hard-pin冲突，没有运行失败版本。

原专用3.214P与更高性能思路位于 `results/tile1_target32_round2_20260911/` 和 `CONTINUATION_20260911_TARGET35.md`。零SrcC初始化和首K剥离曾失败；没有当作已工作优化。后续可继续分析启动、输出和主循环等待，但不要再以只能跑K8192的专用实现作为主体，也不要跨卡外推性能。

```bash
make -j3 all inspect
python3 tools/benchmark_shapes.py --gpu 2 --sizes 8192 1024 2048 4096 --rounds 5 --tag another_run
```
