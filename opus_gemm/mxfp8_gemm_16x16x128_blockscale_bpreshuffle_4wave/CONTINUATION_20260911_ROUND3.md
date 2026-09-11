# 4-wave E8M0 优化续记：第三轮（2026-09-11）

本文件保留第三轮历史结论。后续tile1优化、最新正式源码与3.2P短期目标的进展见 [本轮续记](CONTINUATION_20260911_TARGET32.md)。

本轮正式选入 `regroll_release8`，清理后的源码已放入 `tmpl.hpp`。它让A/B producer共用指令位置，提前缓存地址，按最后消费者滚动预读A1/B1，并把LDS交接提前到第8条MFMA之后。**GPU2最终五轮CLI中位数：BF16 3.074901P、FP32 2.975244P；目标3.5P尚未达到。**

**执行模式明确为 4wave + tile1：每WG独立计算一个256×256输出块。** 项目中tile数量指每WG处理的完整256×256输出块数量；tile4指每WG连续处理4块的持久化方案。第二轮基线与本轮正式版本均为 `OUTPUT_TILES_PER_WG=1`，8192³、batch1的grid均为 `(1024,1,1)`。最终五轮、两种输出、两版共20条CLI日志全部记录 `output_tiles_per_wg=1 (auto)`。K方向另有2-stage LDS双缓冲。

历史tile4候选 `scale_panel_persistent4` 的记录保存在 `OPTIMIZATION_LOG.md` 和 `results/persistent4/`；当时FP32/BF16单轮为2.873824256P/2.949399654P，未选入正式路径。这是早期候选的历史测量；本轮3.074901P/2.975244P对应上述tile1。

后续在第三轮版本的隔离副本中试验tile4，并应用户要求补测tile2。GPU2同期五轮CLI中位数：tile1 BF16/FP32为 **3.082924P / 2.975249P**，tile2为 **3.055072P / 2.963457P**，tile4为 **3.071371P / 2.973301P**。tile2与tile4的BF16/FP32 scratch均为44/48B每线程；同地址配对也未见收益，因此正式选择仍为tile1。实际grid、持久化循环、ISA变化、全量及尾块/batch2验证见 [持久化tile对照记录](results/persistent_tiles_20260911/README.md)。本节之后的正式选择表保留此前测量窗口的数据。

## 最终对照与基线身份

基线是第二轮正式选择 `pair_b_early_a_merge`，恢复时 `tmpl.hpp` 的SHA256为 `97fc15711b5aaad38a91ea7387b42bdf1f0cd11f761f071a83bdb84c111d8ab2`。其完整可重建源码保存在 `results/continuation_20260911/round3/baseline_source/`。本轮没有把某次失败实验或另一张卡上的速度重新命名为基线。

GPU2，MI355X/gfx950、256 CU、PCI `0000:65:00.0`，HIP索引2。M=N=K=8192、batch1、warmup200、iterations100、CLI seed1；kernel-only，两版本交替五轮，反序交替，取中位数。测前连续三次计算活动为0%，仍有18%显存被其他进程驻留；没有停止其他进程或修改时钟、功耗配置。显存驻留状态随同命令和版本哈希保存。

| 输出 | 同轮第二轮基线 ms / P | 当前正式 ms / P | 吞吐变化 |
| --- | ---: | ---: | ---: |
| BF16 | 0.358653145 / 3.065668 | **0.357576294 / 3.074901** | +0.30% |
| FP32 | 0.371911011 / 2.956384 | **0.369553413 / 2.975244** | +0.64% |

BF16新版本五轮范围0.353999939–0.361294289ms；最快单轮约3.106P，仅作波动范围记录，不代替中位数。FP32范围0.369544411–0.370748367ms。3.5P对应0.314146179ms，BF16仍需缩短约43.4µs，即12.1%。

原始五轮、物理卡/PCI/HIP绑定、源和EXE哈希见 `results/continuation_20260911/round3/measurements/formal_cli_gpu2/`。正式目录重建后的EXE、shared library、完整ISA和资源metadata，均与该测量版本逐字节一致；证据为 `formal_build_equivalence.json`。

GPU2历史约3.08P的记录有效：第二轮 `wg_group_m32` 的BF16三轮中位约3.077P，`a_interleave4` 单轮约3.085P，但未稳定超过当时最终选择。第二轮正式选择的历史三轮中位为3.060145P。这些历史结果与本表的同期对照分别保留。

## 同地址测量与其他GPU

为区分代码变化和分配地址/运行时波动，本轮还用完全相同的CLI输入、同一组A/B/scale/C地址，通过C ABI执行“基线—候选—基线”。每段仍为w200/i100，原生C++循环提交kernel，HIP events计时；不计输入生成、B预排、参考计算和输出比较。

| 卡与方式 | 基线BF16 P | 当前BF16 P | 基线FP32 P | 当前FP32 P |
| --- | ---: | ---: | ---: | ---: |
| GPU2，同地址五轮 | 3.002506 | 3.061997 | 2.942825 | 2.959619 |
| GPU5，CLI三轮 | 2.974276 | 2.975565 | 2.734939 | 2.854314 |
| GPU5，同地址五轮 | 2.878814 | 2.914637 | 2.710572 | 2.818373 |

同地址表的基线是全部相邻基线耗时的中位数。每个候选按其前后两个基线的平均耗时作配对比较：GPU2配对提升中位数BF16为1.33%、FP32为0.66%；GPU5为2.01%和3.90%。因此不能把表中各自中位数的比值当成配对提升，也不能把GPU5的4%左右改善直接套到GPU2。

同地址和CLI独立进程分配的绝对值存在差异，BF16亦有约百分之几的波动。本轮在原卡CLI上的改善幅度很小，没有用最好一次或跨卡外推宣称稳定3.1P。

数据分别位于 `shared_allocations/formal_reference_gpu2/`、`measurements/final_candidate_cli_gpu5/`、`shared_allocations/native_register_roll_gpu5/`，均相对于第三轮结果目录。

| 物理卡（rocm-smi） | PCI | HIP索引 | 用途 |
| --- | --- | ---: | --- |
| GPU2 | `0000:65:00.0` | 2 | 原卡最终复测 |
| GPU4 | `0000:85:00.0` | 5 | 恢复后的探索、正确性验证 |
| GPU5 | `0000:95:00.0` | 7 | 用户同意换卡后的同期对照 |
| GPU7 | `0000:f5:00.0` | 4 | 最初绑定错误的无效测量 |

最初误用 `HIP_VISIBLE_DEVICES=4` 实际落到GPU7，相关结果在 `measurements/resume_baseline_gpu4/INVALID_DEVICE_BINDING.json` 明确作废。另一次带并发Python遥测的对照出现相同基线0.38ms与约1.45ms之间的异常跳变，已在 `shared_allocations/bracketed_release_gpu5/INVALID_PERFORMANCE_COMPARISON.json` 作废；该轮不能证明kernel收益。后续正式测量关闭并发遥测。

## 选定流水线

1. 外部格式保持A行主序E4M3FN、B的AITER `(16,16)` preshuffle、A scale E8M0 1×128物理 `[K/128,M]`、B scale E8M0 128×128物理 `[N/128,K/128]`。FP32累加，BF16/FP32输出。
2. 保留完整K scale面板的prologue打包和B scale pair读取。A/B均预取K0和K1，并在进入循环前读入K0的A0/A1/B0/B1。
3. wave0/1各生产一个M128的A half，wave2/3各生产一个N128的B half。按wave选择资源描述符一次；两种矩阵使用相同LDS行pitch，所有wave执行相同16个预取位置。
4. 16个不随K变化的global地址放入VGPR。四个相邻LDS行的MUBUF immediate为0、1024、2080、3136，m0基址补偿为0、32、32、32；global地址减去同一immediate，保证它作用于两端之后仍是原数据坐标。每个K块的相关标量地址加法从16次降到1次。
5. 第8条MFMA之后的完整VMEM/LGKM等待及barrier完成前一轮读取、发布t+1、释放stage t。随后在MFMA8、10、…、38后各发一个t+2请求。最终无消费者的A/B请求回绕到有效K0。
6. B0在38后预读t+1；A0保留BF16整片48后滚动及FP32按M repeat滚动。A1在52、56、60、64后分别覆盖已无消费者的M repeat；B1在62和64后分别覆盖已无消费者的N repeat。下一轮可以更早释放当前stage。
7. 最后一K保留原直接AGPR写回流程和保守A1/B1重读。BF16维持vec8写回。循环trip count保持runtime-visible，避免现有实验LLVM的hard-pin失败。

始终为4个Wave64、256×256 tile、native MFMA16×16×128，C固定a0:a255。资源为普通VGPR FP32 **216** / BF16 **220**，AGPR256，metadata combined472/476，SGPR48，LDS152064B，零spill/scratch。相比第二轮增加了操作数寄存器驻留，仍为每SIMD一个wave；没有以缩减C或改变tile冒充同一实现。

通用K源和机器指令、外部ABI及输出契约保持一致。每次调用仅一次GEMM launch，额外scale workspace为0B，host不重排scale。

## 验证与未选方向

- 两种输出各67,108,864个元素，通过完整8192³独立反量化FP32 GEMM参考的逐值精确检查；该参考使用可精确累加的dyadic输入。
- 完整CLI seed1非dyadic输入，与独立验证过的第二轮基线逐值精确一致；每次执行前把输出填为NaN。
- 最终源码的batch2在256×512×8192 BF16、512×256×8192 FP32和512×256×1152 BF16通过CPU参考检查。
- 正式Python接口的真实AITER shuffle、scale载体及metadata view、非默认stream、out复用和通用K测试通过。
- 源展开MFMA顺序一致；ISA为tied dst=SrcC、a0:a255、无EXEC修改、无额外VMEM drain、零scratch/spill；CFG上的LDS和VMEM寄存器等待检查通过。旧版producer-role正则审计不适用于新排程，未把它称作通过；新映射另有逐字节CPU枚举及完整GPU输出验证。
- 清理只删除无用旧producer helper/别名并更新注释。清理前后、正式重建后的完整ISA、metadata、EXE和shared library逐字节一致。
- 38个候选补丁均恢复出匹配记录哈希的源码；重新构建的CLI输入生成器与原始A/B/scale字节完全一致。保存后的比较工具通过一轮端到端冒烟验证，记录见 `patch_restore_validation.json`、`input_generator_rebuild_validation.json` 和 `reproduction_smoke.log`。

主要证据为 `full_validation/final_register_roll_gpu5/`、`formal_batch_validation/`、`formal_integration.log`、`selected/resumed_static_audit.json` 和 `selected/cleanup_equivalence.json`。

恢复出的第三轮unroll/cache/A领先/B成组预取实验，以及新增的细粒度分支、对称预取、提前24/28发布、stride常量化、统一LDS行、VGPR地址缓存和完整寄存器滚动均已记录。细粒度角色分支增加开销；单纯提前发布未形成稳定收益。若干常量化和m0组合触发原LLVM hard-pin失败，未修改编译器强行通过。`sym_rel24_vaddr` 的FP32较快，但BF16不及最终滚动版本；`regroll_release4` 与release8接近，BF16配对稳定性较差，选择release8。

`recovered_index.json`、`resumed_candidate_index.json` 汇总恢复和新增实验，`candidate_patch_index.json` 保存38个候选相对冻结基线的源码补丁、哈希及必要配置差异。

## 保存、清理与继续复现

第三轮选定 `tmpl.hpp` SHA256：`1b1c87b28c1ae645cd8986e00aae0f870f089044c8a8eac4d761e396deafe53a`。

原始trace、编译副本、失败实验全量文件和临时工作目录已归档并逐文件验哈希，清理1803个冗余结果文件、约81.6MiB。提交内容保留正式源码、基线源码、候选补丁、静态/正确性证据、关键同期测量和本续记。归档位置、SHA256和历史路径恢复方式见 `results/ARCHIVE_20260911.md`。归档本体保留在本机仓库外，不进入Git。

重新比较当前版本与冻结基线：

```bash
python3 tools/compare_versions.py --gpu 5 --rounds 5 --validate
```

`--gpu`始终指物理rocm-smi卡号；工具自动解析HIP索引并断言PCI，重建两版、执行ISA检查、复用同一组输入和输出地址，再交替计时。GPU必须满足空闲阈值。若要像本轮GPU2一样允许空闲显存驻留，显式传入 `--max-initial-vram-percent 20`，计算活动阈值仍为5%。

下一阶段仍需解决约43µs的BF16差距。本次先保存已验证结果；不能把诊断kernel的等效吞吐、dyadic输入的速度或单轮最快值当作达到3.5P。
