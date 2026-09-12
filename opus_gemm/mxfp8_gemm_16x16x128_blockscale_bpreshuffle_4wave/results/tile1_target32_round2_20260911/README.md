# 4wave / tile1：aabad81到3.214P

本轮冻结基线是 `aabad812aca199d3b91bbb567f176f26f92cf6e0 / peel8_tail_columns`，源码在 `baseline_source/`。当前正式源码为 `selected/tmpl.hpp` 的 `selected_32_clean`，与实测 `tail_a3_prefetch56` 的二进制完全一致。最新流程和下一步说明在 [续记](../../CONTINUATION_20260911_TARGET35.md)。

## 正式测量

`measurements/tail_prefetch_confirm_gpu2/`：GPU2 / HIP2 / PCI `0000:65:00.0`，M=N=K8192、batch1、w200/i100、CLI seed1、五轮交替。只统计GEMM kernel。

| 版本 | BF16 ms / P | FP32 ms / P |
| --- | ---: | ---: |
| 冻结aabad81基线 | 0.347929268 / 3.160158 | 0.364843369 / 3.013654 |
| `tail_a3_prefetch56` | **0.342103310 / 3.213975** | **0.361416779 / 3.042226** |

BF16五轮均超过3.2P，3.5P目标尚未达到。全部原始耗时、命令、源及exe哈希和GPU状态保留在各测量目录。初始空闲显存阈值1%，无并行GPU计时、profiler或遥测，没有更改频率或功耗设置。

## 证据索引

- `selected/selection.json`：最终版本、基线commit、测量窗口和目标状态。
- `selected/static_audit.json`：native MFMA、固定256 AGPR、LDS/VMEM等待审查及资源，BF16/FP32均combined VGPR480、SGPR48、LDS152064B、零spill/scratch。
- `selected/cleanup_equivalence.json`、`formal_build_equivalence.json`：注释清理版、正式重建与实测候选的ISA/metadata/exe/lib逐字节一致。
- `full_validation/`：进入性能筛选候选的独立完整输出参考及CLI seed1精确对照；没有省略错误后继续计时。
- `candidate_index.json`、`candidate_patches/`：54个候选及相对aabad81完整补丁。包含未采用和编译失败版本。
- `patch_reconstruction.json`：54个补丁在干净基线恢复后均匹配记录的SHA256。
- `build_results.json`、`build_logs/`：成功或失败的编译记录；K0零初始化相关失败未进入性能测试。
- `screening_summary.json`：全部已完成同地址/CLI窗口，由 `summarize.py` 汇总；没有挑选最快重复。
- `profiles_gpu2/`：ATT分析及命令摘要；trace仅用于诊断排程。
- `../generic_k_survey_20260911/`：用户要求的专用/通用两条路径均跑8192的独立比较，实际使用GPU6。

`lds_rows4_vec4`是后续可用候选，五轮确认BF16 3.216377P、同期父版本3.213319P，差异仅约0.095%，没有代替当前正式选择。不能将不同窗口最快值直接排序作为稳定提升。

## 重现与归档

从 `baseline_source/` 创建隔离副本，应用对应 `candidate_patches/NAME/tmpl.patch`，即可恢复候选；补丁不需要逐层应用父候选。`candidate.json`记录源哈希和配置。顶层 `tools/compare_versions.py --gpu 2 --rounds 5 --validate` 自动重建本轮基线和当前源码，在PCI核对后用同一组地址比较。

`work_path.txt`记录原始临时工作目录。原始构建和trace另存Git仓库外，路径、归档哈希、逐文件校验及清理清单见 `archive_manifest.json`。保留基线、选中版本和可继续实验的候选构建；其余已归档的重复build和原始profile可以恢复到隔离目录，使用 `MXFP8_WORK_DIR` 指向恢复位置。

用户的tile定义保持不变：tile1是每WG一个完整256×256输出块；本轮没有重新测tile2/tile4。
