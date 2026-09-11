# 4wave / tile1 优化续记：短期目标 3.2P

正式实现为目录顶层 `tmpl.hpp`，选入 `peel8_tail_columns` 的清理版本。GPU2 五轮 CLI 中位数：**BF16 3.159607P，FP32 3.016930P**。短期 3.2P 尚未达到；BF16 还需从 0.347990036ms 降至 0.343597384ms，差约 **4.393µs / 1.26% 耗时**。

## 版本与测量

本轮基线固定为第三轮 `regroll_release8`：提交 `f804018` 时的正式 tile1，`tmpl.hpp` SHA256 为 `1b1c87b28c1ae645cd8986e00aae0f870f089044c8a8eac4d761e396deafe53a`。完整源码冻结在 `results/tile1_target32_20260911/baseline_source/`。此前约3.08P及tile1/tile2/tile4对照均属于这个版本，历史数据保留。

物理 GPU2 = HIP2 = PCI `0000:65:00.0`，MI355X/gfx950，256 CU。M=N=K=8192、batch1、warmup200、iterations100、CLI seed1，kernel-only。每轮交替版本，隔轮反序，取五轮中位数。测前计算活动为0%，有18%空闲显存驻留；记录允许20%显存驻留的阈值，计算活动阈值仍为5%。计时期间关闭并发遥测。

| 输出 | 同期 regroll_release8 | 当前正式 | 吞吐变化 |
| --- | ---: | ---: | ---: |
| BF16 | 0.358544006ms / 3.066602P | **0.347990036ms / 3.159607P** | **+3.03%** |
| FP32 | 0.370238876ms / 2.969736P | **0.364447136ms / 3.016930P** | **+1.59%** |

当前版 BF16 五轮范围 0.347481804–0.348342285ms，FP32 为0.364020729–0.364731865ms。原始命令、PCI/HIP绑定、输入参数、源码和EXE哈希保存在 `results/tile1_target32_20260911/measurements/final_selection_gpu2/`。独立CLI和同地址C ABI的绝对耗时分别记录；不以单次最快值或跨窗口比值判断达到3.2P。

同地址原生C ABI另做五轮“基线—当前—基线”确认：BF16基线/当前中位数为3.055927P / **3.154957P**，FP32为2.963729P / **3.019398P**；相邻两个基线耗时平均值用于逐轮配对，配对提升中位数为4.15% / 1.89%。BF16当前版范围0.344579518–0.355649978ms。单轮复现冒烟测试曾为3.223786P，五轮未持续复现，不作为达到3.2P的证据。完整数据见`shared_allocations/formal_same_address_gpu2/`和`reproduction_smoke_gpu2/MEASUREMENT_SCOPE.json`。

## 正式流水线

每WG为4个Wave64、256线程，独立计算一个完整256×256输出块，`OUTPUT_TILES_PER_WG=1`。8192³的grid为1024个WG。tile2/tile4指每WG连续处理2/4个完整输出块，已按用户要求停止该方向；本轮所有候选均为tile1。候选名中的 `r4` 指MFMA4处的barrier。

1. 延续原来的完整K scale面板、A/B双缓冲LDS、native MFMA16×16×128和固定a0:a255累加器。A/B生产者仍共用16个预取位置与缓存的global地址。
2. 第4条MFMA后完整等待VMEM/LGKM并执行barrier，发布t+1、释放stage t。主循环的t+2矩阵请求仍放在MFMA8、10、…、38后。
3. 两种输出的A0均按M repeat在MFMA36/40/44/48后读取t+1。B0在32/34/36/38后分四对读取，分散LDS读取压力。
4. C11前8条保持按行次序；后8条在M repeat 2/3间交替。B1的N repeat 0/1/2/3分别在58/60/62/64后读取，A1的M repeat 0/1/2/3在52/56/63/64后读取。每个累加器的K累加顺序和操作数一致。
5. 主循环展开8次，处理K0..K61；随后单独处理K62并滚入K63，省掉最后一批没有消费者的全局矩阵请求。最终K63使用原来的直接AGPR写回段，BF16仍为vec8。保留已经实测的标量地址表达式和runtime-visible trip count。

| 资源 | FP32 | BF16 |
| --- | ---: | ---: |
| 普通VGPR | 216 | 220 |
| AGPR | 256 | 256 |
| metadata combined VGPR | 472 | 476 |
| SGPR | 48 | 48 |
| LDS | 152064B | 152064B |
| scratch / VGPR spill / SGPR spill | 0 / 0 / 0 | 0 / 0 / 0 |

外部E8M0格式、AITER `(16,16)` B预排、单次GEMM launch及0B额外scale workspace保持一致。通用K源码和ISA逐字节一致。

## 验证与实验结论

选定候选通过两个8192³全量数据集、两种输出的逐值精确检查：可精确累加的dyadic输入与独立反量化FP32 GEMM参考一致；CLI seed1输入与已独立验证的冻结基线一致。每次执行前输出填为NaN。ISA检查覆盖native MFMA、固定且完整的a0:a255、SrcC绑定、无EXEC修改、无spill、CFG上的LDS/VMEM寄存器等待及barrier前全量VMEM完成。

本轮循环展开和K62单独处理会改变静态指令数。当前每个累加器在ISA中有11次静态MFMA，动态执行仍覆盖64个K128块；审计按实际循环结构检查。C11只在同一K块内调整独立累加器次序，source operand-to-C映射逐项一致。

清理去掉无条件实验分支、修正注释与缩进。清理前后及正式目录重建的ISA、metadata、EXE和共享库完全一致，证据在 `selected/cleanup_equivalence.json` 和 `selected/formal_build_equivalence.json`。归档后的最后修订只将预取注释改为K2..K63，四项构建产物仍逐字节一致，见 `selected/comment_only_equivalence.json`；历史测量保留实际测量时的源码哈希。正式Python接口及batch2检查记录随实验保存。

共探索48个候选，另保存选定版的清理副本。初始预取集中发射和减少展开没有BF16收益；A0/B0分散读取形成主要改善，MFMA4交接、末尾预取裁剪、展开8次及C11尾部调整进一步改善。padding、workgroup顺序和额外预读寄存器没有形成足以替代最终选择的收益。A/B直接读VGPR虽减少LDS与barrier，但全局矩阵读取量增加，实测BF16约1.88P，未选入。

ATT只用于诊断。冻结基线的被采样wave中，稳态K块中位约2341 cycles；A0/B0分散后约2227 cycles，MFMA48后的平均间隔由约132降至54 cycles。它解释了排程方向，不能替代非profiling的CLI结果。两个profile的命令、指令统计及原始数据保存位置均保留。

## 继续复现

当前正式 `tmpl.hpp` SHA256：`4193c75a9fac14d7782c7f8d91fac58f95700b56989fb2b5242a21e5216cc1b0`。

```bash
python3 tools/compare_versions.py --gpu 2 --rounds 5 --validate --max-initial-vram-percent 20
```

工具按物理卡PCI解析HIP索引，从冻结 `regroll_release8` 源码和当前正式源码分别重建，完成ISA审计，再以相同输入和地址执行相邻基线对照。`--validate`增加全量独立参考检查。结果保存在 `results/tile1_target32_20260911/`；候选补丁、全部测量窗口、资源和验证索引见该目录的README。

## 保存与清理

tile1和持久化tile实验的原始工作目录已合并归档至仓库外，共1126个文件逐一通过SHA256校验。归档后清理51个冗余构建或原始profile目录，共558个文件、89.31MiB；保留正式build以及tile1基线、选定候选和清理版的build。归档位置、哈希、被清理路径与恢复方式保存在两个实验目录的 `archive_manifest.json`。候选源码均可由Git中的冻结基线和补丁恢复；原始测量和验证记录保留在Git中。
