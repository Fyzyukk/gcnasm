# 最终通用4wave / tile1

正式源为顶层`tmpl_generic.hpp`，名称`generic_tile1_final_20260912`，来自五轮确认的`stream64_batch_output_burst`。M/N正256倍数、K正128倍数均走同一运行时K实现，4 Wave64，每WG一个完整256×256输出块。BF16/FP32输出、原E8M0/AITER布局和零额外workspace保持原契约。

本次按用户要求完成候选比较后停止继续试新优化，补测四个尺寸，整理当前构建并保存历史。3.5P尚未达到。

## 性能

`final_shapes_gpu2/`是清理后正式构建的测量，按8192、1024、2048、4096顺序执行。GPU2 / HIP2 / PCI `0000:65:00.0`，M=N=K，batch1，CLI seed1，warmup200 / iterations100，每种输出五轮中位数，只统计GEMM kernel。

| M=N=K | BF16 ms | BF16 P | FP32 ms | FP32 P |
| ---: | ---: | ---: | ---: | ---: |
| 8192 | 0.342066650 | 3.214320 | 0.362748337 | 3.031059 |
| 1024 | 0.014202470 | 0.151205 | 0.018589730 | 0.115520 |
| 2048 | 0.022676940 | 0.757592 | 0.026594579 | 0.645991 |
| 4096 | 0.049726748 | 2.763884 | 0.056115160 | 2.449230 |

小尺寸工作组较少，固定启动和写回开销占比更高。没有更换GPU、调整频率/功耗，也没有并行运行计时、profiling或遥测。每次命令、原始耗时、GPU绑定及源/二进制哈希均已记录。

父候选的独立五轮交替确认见`../generic_migration_20260911/measurements/combo_confirm_20260912_gpu2/`：原通用2.887246/2.794619P，迁移检查点3.183753/3.005484P，选中候选3.213513/3.029430P（BF16/FP32）。分散写回候选为3.205744/3.031405P，最终采用BF16更快的集中写回版。没有用单次最快值作为正式性能。

## 清理与验证

- `cleanup_equivalence.json`：最终构建的BF16/FP32通用指令编码与实测父版完全一致；只移除了未使用的专用实例。
- 当前只编译两种通用输出kernel；旧`tmpl.hpp`、`WholeKScaleTraits`、冗长旧traits别名和无用scale定义已移除，输出宏和注释已澄清。
- 静态审查检查native MFMA、固定256 AGPR、LDS/VMEM等待和EXEC；FP32/BF16 combined VGPR508/512，SGPR76，LDS152064B，零spill/scratch。
- 父候选在K128至32896、面板边界、非方阵及batch2均精确匹配独立参考；最终代码在8192²的67,108,864个元素上，两种输出均再次精确匹配独立参考及CLI seed1基线。
- `python_integration.log`：Python适配器、AITER真实shuffle、E8M0布局、`out=`及非默认stream检查。
- `reproduction_smoke.log`：`tools/compare_versions.py --rounds 1 --validate`完整运行记录。此单轮用于检查复现工具，不能替代五轮性能结果。

最终源码/配置及选择元数据在`../generic_migration_20260911/selected/`。旧专用版3.214P、未采用候选及继续优化思路保留在历史证据和归档中；不参与正式构建。

临时工作目录共590个文件已逐一校验归档，清除了525个冗余文件（62,521,751字节）。归档位置、SHA256、保留目录和清理清单见`archive_manifest.json`；Git中保留可恢复源码的基线、完整补丁和全部测量证据。

```bash
make -j3 all inspect
python3 tools/benchmark_shapes.py --gpu 2 --sizes 8192 1024 2048 4096 \
  --rounds 5 --tag another_run
```
