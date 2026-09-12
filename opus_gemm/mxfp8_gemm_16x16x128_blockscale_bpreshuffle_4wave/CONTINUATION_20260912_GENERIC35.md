# 最新通用4wave / tile1优化记录：2026-09-12

当前版本 **generic_tile1_opt_20260912**，唯一kernel头文件为顶层 `tmpl_generic.hpp`。本轮选定候选 `split_async36_preload_a0_m0`，清理后全部有效机器指令一致。后续以当前通用版本为基础优化，目标仍为3.5P，尚未达到。

## 不变的范围

- tile1表示每WG一个完整256×256输出块，4 Wave64；输出拆成四个128×128区域不改变tile数量。
- 支持正M/N的256倍数、正K的128倍数；8192执行同一运行时K路径。继续支持连续batch、原E8M0/AITER ABI、原生16×16×128 MFMA、固定256 AGPR、零额外device workspace。
- 性能候选统一用8192³，在物理GPU2 = HIP2 / PCI `0000:65:00.0` 上同地址、相邻基线交替测量。其他K用于正确性；最终按要求记录四尺寸性能。

## 本轮成果

本轮比较基线为提交 `f0b117c4c18a543d73953776dae32b8df6949c8c`，冻结源码在 `results/generic_opt_20260912/baseline_source/`。五轮同地址确认中，BF16从3.213499P到3.261905P，FP32从3.023532P到3.051683P；相邻基线归一化提升中位数分别为1.582020%、0.908573%，均5/5轮为正。

正式构建在同一物理GPU的五轮中位数：

| M=N=K | BF16 P | FP32 P |
| ---: | ---: | ---: |
| 8192 | **3.258971** | **3.052929** |
| 1024 | 0.153562 | 0.116092 |
| 2048 | 0.774870 | 0.653551 |
| 4096 | 2.777857 | 2.458571 |

采用：SFA双half在MFMA2后b64预取，SFB双half在MFMA20后预取；两组AGPR初始化与SFA/B请求重叠；无符号tile索引；A0/M0下一K片段在MFMA30后预读、MFMA36后安装；BF16在20/36/52/64后发布四个输出区域，并在36处让独立C写回跨越LDS发布barrier。

FP32普通VGPR244、BF16普通VGPR248，另各有256 AGPR；combined500/504，SGPR74，LDS152064B，零spill/scratch。头文件SHA256：`6472526cabcb12957570f8540b13adae296ab35f637e9f254c4a7a00e0e58483`。

完整8192²参考、K128至32896的16组形状（含跨scale面板、非方阵、batch2）、静态LDS/VMEM依赖审查、实际AITER适配器均通过。详情和所有未采用思路在 [本轮记录](results/generic_opt_20260912/README.md)。之前3.214P检查点的记录保留在 `results/final_generic_20260912/`。

## 后续工作入口

公开比较工具已更新为“冻结f0b117c通用基线 vs 当前通用版本”，并检查两种输出的源码哈希和有效指令编码：

```bash
python3 tools/compare_versions.py --gpu 2 --rounds 5 --validate --tag new_compare
python3 tools/benchmark_shapes.py --gpu 2 --sizes 8192 1024 2048 4096 --rounds 5 --tag new_shapes
```

`results/generic_opt_20260912/selected/`保存最终源码、配置、资源和选择依据。`candidate_index.json`、`screening_windows.json`、`duplicate_encodings.json`和 `patch_reconstruction.json`已记录全部候选，避免重复试验。原始构建和ATT归档位置见 `archive_manifest.json`。

A0更早/更晚预取、额外尾部A1/B1预取、K0统一producer、canonical stride、删除MFMA36优先级指令都没有建立更好的BF16结果。后续可分析主循环指令发射和输出转换，但需要同卡配对证据；不要将单次3.27P当作稳定水平，也不要恢复只支持8192的专用主体。
