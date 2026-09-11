# 4wave / tile1，短期目标3.2P

正式选择 `peel8_tail_columns`，清理后为 `selected_clean`，源码已放到目录顶层 `tmpl.hpp`。GPU2五轮CLI中位数 **BF16 3.159607P / FP32 3.016930P**；同轮 `regroll_release8` 基线为3.066602P / 2.969736P。3.2P尚未达到。完整结论见 [续记](../../CONTINUATION_20260911_TARGET32.md)。

本目录的 `baseline` 始终指冻结的 `regroll_release8` tile1，SHA256 `1b1c87b28c1ae645cd8986e00aae0f870f089044c8a8eac4d761e396deafe53a`。`baseline_source/`及`baseline_manifest.json`保存完整可重建来源。`selected/selection.json`记录正式选择、目标差距、测量参数和源码身份。

## 证据索引

- `candidate_index.json`、`candidate_patches/`：48个候选及清理版。补丁相对于本目录冻结基线，padding候选同时含`traits.patch`。
- `build_results.json`、`build_logs/`、`audits/`：编译资源与静态审计。combined VGPR已包含256 AGPR。
- `full_validation/`：每个新候选在8192³的dyadic独立参考与CLI seed1全输出比对。输出预填NaN，两种dtype均逐值精确检查。
- `shared_allocations/`：同卡、同数据地址、原生C++ HIP event计时，候选前后各测一次冻结基线。每段w200/i100；关闭并发遥测。
- `measurements/final_selection_gpu2/`：正式选择使用的五轮CLI结果、物理卡/PCI/HIP绑定、命令与哈希。
- `shared_allocations/formal_same_address_gpu2/`：正式版五轮同地址确认，BF16/FP32中位3.154957P / 3.019398P。单轮工具冒烟的3.223786P未持续复现，单独标注测量范围。
- `screening_summary.json`：由`summarize.py`汇总每个候选的全部已完成窗口，不挑选最佳一次。
- `selected/static_audit.json`、`selected/cleanup_equivalence.json`、`selected/formal_build_equivalence.json`、`selected/comment_only_equivalence.json`：选定版审计、清理、正式构建及最终注释修订的等价证据。
- `formal_integration.log`、`formal_batch_validation/`：正式Python接口和batch2检查。
- `profiles_gpu2/`：冻结基线及A0/B0分散版本的ATT命令、16条完整wave的指令间隔和汇总。trace时间仅用于诊断。

`tile1/tile2/tile4`统计每WG处理的完整256×256输出块；本轮所有候选均为tile1。候选名中的`r4`是MFMA4的barrier位置，`unroll8`是K循环展开数量。

## 重建

重新比较冻结基线和正式源码：

```bash
python3 tools/compare_versions.py --gpu 2 --rounds 5 --validate --max-initial-vram-percent 20
```

从项目目录执行。`--gpu`为物理rocm-smi卡号，工具自动解析HIP索引并断言PCI；阈值只放宽空闲显存驻留，计算活动仍必须≤5%。默认比较基线为本目录的`regroll_release8`。

恢复某个候选时，先把`baseline_source/`复制到新的隔离目录，再依次应用该候选的`tmpl.patch`和可选的`traits.patch`，以`candidate.json`中的SHA256核对源码，然后`make -j3 all inspect`。使用现有带hard-pin补丁的clang23。`patch_restore_validation.json`记录全部补丁的恢复校验。

`generate*.py`记录当时的候选构造过程；`run.py`重用已保存的GPU/PCI感知驱动，`audit_unroll.py`按展开、K62处理和C11顺序检查实际结构。直接运行旧实验驱动需要`work_path.txt`中的工作副本，或通过`MXFP8_WORK_DIR`指定已恢复的副本。正式复现工具会自行创建隔离目录。

原始ATT和编译副本的归档位置与哈希见`archive_manifest.json`；它们保存在Git仓库外。Git中保留可重建源码、补丁和判断结果所需的原始测量。

本轮连同持久化tile实验共归档并核对1126个文件，随后删除51个冗余构建或原始profile目录（558文件，89.31MiB）。正式build与tile1基线、选定候选、清理版的build仍保留。归档快照早于最后两行注释修订；当前源码使用已更新的`selected_clean`补丁恢复，构建等价证据见`selected/comment_only_equivalence.json`。
