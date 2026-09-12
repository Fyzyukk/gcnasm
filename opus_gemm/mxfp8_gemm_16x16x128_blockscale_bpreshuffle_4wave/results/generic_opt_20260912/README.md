# 通用4wave / tile1后续优化：2026-09-12

最终版本为 `generic_tile1_opt_20260912`，选自 `split_async36_preload_a0_m0`。顶层 `tmpl_generic.hpp` 是唯一通用实现，每WG处理一个完整256×256输出tile，使用4个Wave64。所有支持的正K128倍数，包括8192，都执行运行时K流水线；正M/N为256倍数，连续batch、原E8M0/AITER输入ABI和零额外device workspace保持支持。**3.5P目标尚未达到。**

本轮基线固定为提交 `f0b117c4c18a543d73953776dae32b8df6949c8c`。冻结的9份源码及支持文件在 `baseline_source/`；其通用头文件SHA256为 `681e64526624bdafd7f8d6c2117cd95dc516866f8d25f5aa8159a90c21687fd6`。当前头文件SHA256为 `6472526cabcb12957570f8540b13adae296ab35f637e9f254c4a7a00e0e58483`。

## 确认结果

物理GPU2 = HIP2，PCI `0000:65:00.0`。8192³、batch1，CLI seed1输入，同一进程内各版本共享全部输入和输出地址。每个候选按“基线—候选—基线”交替计时，逐轮反转候选次序。使用原生HIP event计时，warmup200、iterations100，不调整GPU频率或功耗。

`shared_allocations/final_candidate_confirm_gpu2/` 的五轮确认：

| 版本 | BF16 P | FP32 P |
| --- | ---: | ---: |
| 本轮基线 `f0b117c` | 3.213499 | 3.023532 |
| scale / quarter / split初始化组合 | 3.253180 | 3.048644 |
| **增加MFMA30后A0预取，最终选择** | **3.261905** | **3.051683** |
| 再删除MFMA36重复优先级指令 | 3.254393 | 3.052466 |

最终选择相对相邻基线的提升中位数为BF16 **1.582020%**、FP32 **0.908573%**，两种输出均5/5轮为正。上述P是各版本的时间中位数换算，不能用两个全窗口中位数之比替代逐轮配对统计。原始数据包含一次明显基线漂移，没有删除不利样本。短筛选中出现的3.27P等单次值不作为最终性能。

清理后的正式构建另外按8192、1024、2048、4096顺序测量，每种输出五轮，记录在 `final_shapes_gpu2/`：

| M=N=K | BF16 ms | BF16 P | FP32 ms | FP32 P |
| ---: | ---: | ---: | ---: | ---: |
| 8192 | 0.337379951 | **3.258971** | 0.360149727 | **3.052929** |
| 1024 | 0.013984480 | 0.153562 | 0.018498060 | 0.116092 |
| 2048 | 0.022171280 | 0.774870 | 0.026286960 | 0.653551 |
| 4096 | 0.049476609 | 2.777857 | 0.055901971 | 2.458571 |

性能只计GEMM；输入生成、shuffle、参考运算均在计时之外。四尺寸CLI测量与同地址候选比较是不同窗口。上一版四尺寸结果保留在 `../final_generic_20260912/`。

## 最终改动

- 下一K的两个SFA half合并为一次LDS b64，在MFMA2后发出；两个SFB half在MFMA20后用b64预取。在最后当前K消费者完成后再安装各dword。
- 在SFA请求之后初始化前128个AGPR，在B矩阵请求之后初始化后128个。输入约束的空asm只约束初始化位置，保留原生MFMA及256个固定AGPR。
- WG编号、N tile除法和K128循环数使用无符号计算；依据已有的正数、整除接口约束，运行时形状支持范围不变。
- A0的M repeat 0在MFMA30后预读下一K的两个16字节片段，在MFMA36完成当前值的最后消费后安装。主循环和倒数第二个K块都采用这一安排。
- BF16最终轮分别在MFMA20/36/52/64后发布C00/C10/C01/C11，每个128×128区域每线程执行8次16字节合并写回。MFMA36处保留LDS等待与barrier，让独立C00全局写回继续进行。四个区域仍属于一个256×256输出tile。FP32直接写回。

资源：FP32普通VGPR244 + AGPR256，BF16普通VGPR248 + AGPR256，combined500/504；SGPR74，LDS152064B，零spill和scratch。静态MFMA为704条，全部是原生 `v_mfma_scale_f32_16x16x128_f8f6f4`，SrcC和DstC绑定相同的a0:a255片段；没有EXEC修改。

只整理注释和重复的空asm定义后，两种kernel的全部有效指令编码与实测候选一致，证据为 `cleanup_equivalence.json`。当前生产构建也通过相同编码核对，见 `audits/production_top.json`。`selected/` 保存最终源码、配置、ISA、资源审查、选择理由和构建哈希。

## 验证及未采用方案

最终实测候选在FP32/BF16上精确匹配独立反量化FP32 bmm：K128、256、384、896、1152、3968、4096、4224、4352、8064、8192、8320、8448、16384、16512、32896，包含非方阵和batch2。完整8192²的67,108,864个输出也精确匹配独立参考和CLI seed1基线。证据在 `shape_validation/initial_roll_gpu2/`、`full_validation/initial_roll_gpu2/`。

最终适配器验证真实AITER shuffle、两种E8M0 scale metadata布局、uint8承载的预排B、`out=`、分配输出、非默认stream和输入重叠拒绝，见 `production_adapter_checks.log`。`reproduction_smoke_gpu2.log` 验证公共复现工具从源码重建基线及当前版本；其中单轮计时仅用于复现流程检查。

异步输出审查按类型跟踪VMEM事件：矩阵到LDS的输入、寄存器输入、独立C写回。仅声明的BF16输出发布点允许未完成的C写回，任何未退休输入都会失败；其他发布点仍要求VMEM全部完成。`audit_guard_checks.json` 包含实际程序的正例，以及注入未退休输入和取消声明的反例，合成反例未在GPU执行。

没有采用的主要方向：

- SFB全wave重复读取、放松整个主循环的调度限制，有的溢出或生成EXEC waterfall；失败版本没有上卡。
- 输出地址预计算、32/64行输出发布、unroll4/16、最终操作数常驻、scale预取位置变化，在组合比较中未优于最终选择。
- canonical stride表达式使首块A/B标量offset产生waterfall。只统一B offset仍不够；首块复用主循环producer后可通过验证，但BF16无收益。
- A0预取移动到MFMA26/28/32、继续预取尾部A1/B1片段，均未提高BF16最终性能。MFMA36优先级指令删除也未稳定胜出。
- 主循环VALU比率1/4与其父版的机器编码完全相同，计时差异按噪声处理。全部编码重复关系见 `duplicate_encodings.json`。

ATT只用于定位指令间隙，不作为性能证据。选定优化链的跟踪显示MFMA36访存集中程度下降，但单CU的整体周期并不总随benchmark同向变化。`profiles_gpu2/` 保存命令、原始数据路径和摘要；继续分析应结合整卡交替测量。

## 复现和记录

在本kernel目录运行：

```bash
make -j3 all inspect
python3 tools/compare_versions.py --gpu 2 --rounds 5 --validate --tag my_compare
python3 tools/benchmark_shapes.py --gpu 2 --sizes 8192 1024 2048 4096 --rounds 5 --tag my_shapes
HIP_VISIBLE_DEVICES=2 OMP_TOOL=disabled OMP_NUM_THREADS=16 python3 test_blockscale_bpreshuffle.py
```

比较工具明确重建 `baseline_source/` 的f0b117c基线及顶层当前源码，按PCI解析物理卡号，核对两者源码哈希及kernel指令编码。结果目录名必须唯一，避免覆盖测量。公共复现不依赖本轮临时工作目录。

`candidate_index.json` 包含全部版本的配置、构建、审查、验证和测量窗口；`screening_windows.json` 包含每个窗口的reference与配对结果。`early_rejections.json` 记录上卡前排除原因。`make_candidates.py` 保存实验变换，`clean_selected.py` 保存最终清理过程。`patch_reconstruction.json` 验证所有 `candidate_patches/*/change.patch` 都能从冻结基线精确还原源码；手动恢复候选时复制 `baseline_source/`，应用对应补丁，再运行 `make` 即可。

临时二进制、完整候选目录及原始ATT的本机归档由 `archive_manifest.json` 记录。Git保留最终实现、冻结基线、所有源码补丁和测量证据；后续优化以当前通用版本为起点。
