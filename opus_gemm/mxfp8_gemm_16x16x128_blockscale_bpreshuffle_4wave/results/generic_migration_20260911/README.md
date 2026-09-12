# 通用4wave / tile1迁移与后续优化

目标是保持运行时K通用，在8192³ compute-bound测试点向3.5P提升。M/N正256倍数、K正128倍数、batch、FP32/BF16输出与外部AITER/E8M0接口保持原有支持范围；每WG计算一个完整256×256输出块，4 Wave64，无额外workspace。其他K只做正确性检查。

迁移检查点为`stream64_rows4`，后续选定`stream64_batch_output_burst`，整理成唯一正式实现`generic_tile1_final_20260912`。`tmpl_generic.hpp`由运行时K控制，64组scale缓存循环复用；8192也直接选择通用kernel。冻结的专用3.214P版本仅作历史控制。最终四尺寸测量见[最终记录](../final_generic_20260912/README.md)，最新决策见[通用续记](../../CONTINUATION_20260911_GENERIC35.md)。

GPU2 / HIP2 / PCI `0000:65:00.0`，8192³、batch1、warmup200/iterations100、CLI seed1、五轮交替中位数（`measurements/migration_confirm_gpu2/`）：

| 版本 | BF16 P | FP32 P |
| --- | ---: | ---: |
| 原通用基线 | 2.887404 | 2.792190 |
| 通用迁移检查点 | 3.185528 | 3.007706 |
| 冻结专用控制 | 3.214499 | 3.043128 |

后续输出重叠、启动scale读取和主循环调度候选均以通用源为父版。三轮筛选用于挑选候选；正式采用前另做确认，不按跨窗口最快值排名。GPU通过PCI核对，计时、profiling及遥测不并行，没有修改频率或功耗设置。

## 证据

- `manifest.json`与`candidate_index.json`：目标、物理卡、源版本和每个候选的配置/哈希。
- `baseline_source/`：冻结原通用源，测试副本强制generic。`migration_checkpoint/`保存迁移里程碑，`selected/`保存正式选择。
- `candidate_patches/NAME/`：相对冻结原通用源的完整补丁，无需逐层应用父版；包含失败和未采用候选。
- `patch_reconstruction.json`：23个候选的全部补丁恢复后匹配记录源码哈希。`screening_summary.json`汇总全部完成窗口。
- `build_results.json`、`build_logs/`：构建结果，包括编译器hard-pin失败。
- `audits/`：native MFMA、固定256 AGPR、EXEC、零spill/scratch和链接后ISA的LDS/VMEM等待检查。
- `shape_validation/`：K128至32896、32/64组面板边界、非方阵及batch2的独立参考；仅验证正确性。
- `full_validation/`：8192²完整输出对独立反量化FP32 bmm及CLI seed1冻结基线的精确比较。
- `shared_allocations/`：同地址、参照包围的三轮筛选；`measurements/`为CLI交替确认。
- `profiles_gpu2/`：ATT指令诊断摘要，不能用instrumented耗时作为性能结论。

## 复现

从`baseline_source/`复制到隔离目录，应用某候选的`tmpl_generic.hpp.patch`和`traits.hpp.patch`，核对`candidate.json`哈希，再`make -j3 all inspect`。所有候选保留同一专用源码，静态审查要求其ISA不变。

`work_path.txt`记录临时构建目录。`generate_*.py`创建独立候选；`build.py NAME...`编译；`screen.py NAME... --tag UNIQUE --reference PARENT --gpu 2`串行进行静态审查、通用正确性、完整8192正确性和同地址计时。`capture_att.py NAME...`、`analyze_trace.py NAME...`用于独立的指令诊断。

`tools/compare_versions.py`用于冻结原通用与当前正式通用的重建对照。原专用实验和更高性能思路另保留在`../tile1_target32_round2_20260911/`，不作为后续优化主体。

临时构建和ATT原始数据已归档并逐文件校验，位置与清理清单见`archive_manifest.json`。仅保留原通用基线、历史专用控制和最终选中候选的临时构建；其他候选可从完整补丁或校验过的归档恢复。当前生产源码只包含最终通用实现。
