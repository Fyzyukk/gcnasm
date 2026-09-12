# 4wave / tile1：3.214P检查点，继续向3.5P优化

这是保留的K8192专用版历史记录。用户已明确最终目标为通用kernel在8192³达到3.5P；当前正式入口和后续优化已迁至通用路径，恢复工作请先读 [通用路径续记](CONTINUATION_20260911_GENERIC35.md)。本文的专用代码、测量和未实现思路继续保留。

本历史检查点的 `tmpl.hpp` 是 `selected_32_clean`，现已从当前构建删除并冻结在 `results/tile1_target32_round2_20260911/selected/`。它与测量候选 `tail_a3_prefetch56` 仅有注释和空白差异，当时的exe、共享库、完整ISA和metadata均逐字节一致。

## 当前结果与基线身份

GPU2 / HIP2 / PCI `0000:65:00.0`，8192³、batch1、w200/i100、CLI seed1、五轮交替中位数：

| 版本 | BF16 P | FP32 P |
| --- | ---: | ---: |
| 本轮冻结基线 `aabad81 / peel8_tail_columns` | 3.160158 | 3.013654 |
| `lds_release5_k1` | 3.194943 | 3.023530 |
| 正式 `tail_a3_prefetch56` 等价清理版 | **3.213975** | **3.042226** |
| `tail_b3_prefetch56` | 3.210113 | 3.033126 |

正式BF16耗时0.342103310ms，五轮吞吐范围3.21017–3.21888P。3.2P里程碑已达到；3.5P需要0.314146179ms，尚需减少约27.957µs。不能把里程碑视为最终目标完成。

之前3.0666P/约3.08P对应 `f804018 / regroll_release8`，冻结在 `results/tile1_target32_20260911/baseline_source/`。本轮的3.1596P基线是提交 `aabad812aca199d3b91bbb567f176f26f92cf6e0`，冻结在 `results/tile1_target32_round2_20260911/baseline_source/`。两个基线不能混用。顶层 `tools/compare_versions.py` 已切到本轮的aabad81基线和匹配的审查器。

## 正式优化

1. BF16输出先写pitch264的LDS，再合并16字节GMEM stores并使用 `nt`。A/B矩阵LDS合为一个135168字节的拥有者，最后矩阵读取全部结束并经LGKM等待与barrier后复用；输出复制前再次等待与barrier。没有增加workspace或LDS。
2. 发布t+1和释放矩阵stage的barrier从MFMA4移到MFMA5，两条独立MFMA拆开安排。
3. K1初始矩阵加载复用主循环的统一producer。
4. A1的M repeat 3两段16字节读取从MFMA64后提前到56后，先放入临时寄存器，64后再覆盖已完成最后一次使用的旧操作数。

保持4 Wave64 / 256线程 / 每WG一个完整256×256输出块；保持native MFMA16×16×128、每个累加器K顺序、unroll8、单独K62、外部布局及ABI。两种输出均为224普通VGPR+256固定AGPR（metadata combined480），SGPR48、LDS152064B、零spill/scratch。通用源码及其ISA没有改变。

## 专用与通用范围

当前3.214P及最近优化都属于 **K8192专用 `tmpl.hpp`**。它固定64个scale分组和K62/K63流程，不能直接用于其他K。`tmpl_generic.hpp`支持正的K128倍数，包括8192；正常dispatch仅在8192选专用。

用户最新要求两条路径都只测8192。GPU2被其他任务占用后，已在空闲GPU6 / HIP6 / PCI `0000:e5:00.0` 强制通用路径，与当前专用做五轮同卡对照：

| 路径 | BF16 P | FP32 P |
| --- | ---: | ---: |
| 专用 | 3.061396 | 2.922129 |
| 通用 | 2.821894 | 2.733634 |

这是GPU6的CLI中位数，专用高8.487%/6.895%；同地址的C ABI五轮对照确认相同方向。两种输出均全量精确相等，隔离构建只改变host dispatch。详见 `results/generic_k_survey_20260911/README.md`。不跨卡外推通用路径在GPU2的性能。

## 已验证及待做方向

- 所有进入计时筛选的候选均通过独立dyadic FP32参考及CLI seed1全量对比，BF16/FP32各67,108,864个输出。静态审查涵盖固定累加器、LDS/VMEM等待、资源和通用ISA一致性。54个候选补丁均可恢复到记录的源码哈希。
- `lds_rows4_vec4` 五轮确认BF16为3.216377P，同期正式父版本3.213319P，仅约0.095%差距，暂未替换正式版本。它在最终K按输出行提前转换/写LDS，并消除permlane交换，可作为后续组合起点。
- A/B更多提前读取、A优先象限次序、LDS copy分组及几个细调时点没有稳定改善。记录保留全部窗口；没有选择单次最快值。
- K0零SrcC初始化尝试均因编译器hard-pin冲突或约束错误而未编译通过；没有执行或进入正式代码。不要把这些候选当作已工作的优化。
- ATT显示选中版本steady K块约2115.3 cycles，基线约2154.6；启动段6306 vs7118，final K+epilogue10212 vs10412。ATT仅用于定位排程，不能替代性能计时。后续可调查启动/输出及剩余LDS等待；VGPR pinning和LDS转置读取均尚未实现。

最新代码、全部候选补丁、未采用结果、复现方法及归档指针见 `results/tile1_target32_round2_20260911/README.md`。继续优化时维持tile1及两条路径在8192的清晰测量口径，目标仍为3.5P。
