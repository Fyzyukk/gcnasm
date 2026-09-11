# 4-wave E8M0 优化续记：第二轮（2026-09-11）

> 这是对应轮次的历史记录。当前正式版本见 [第三轮续记](CONTINUATION_20260911_ROUND3.md)；清理后移出的原始实验路径见 [归档索引](results/ARCHIVE_20260911.md)。

本轮正式选入 `pair_b_early_a_merge`，清理后保存在本目录 `tmpl.hpp`。它合并两个 B scale half 的 LDS 读取、提前首批 A 预取，并合并 A/B 各自相邻的 producer 分支。实际提升很小，**尚未达到 3.5 PFLOP/s**。A 四路交错、WG 分组、m0 精简等实验保留在记录中，没有把最快一次当作最终性能。

## 正式复测

物理 GPU2，MI355X/gfx950，256 CU，PCI `0000:65:00.0`。M=N=K=8192，b=1、w=200、i=100；相同 CLI seed=1 输入，kernel-only，无 profiler。两个版本交替三轮，第二轮反序，取中位数。

| 输出 | 上一版 ms / PFLOP/s | 当前正式 ms / PFLOP/s | 吞吐变化 |
| --- | ---: | ---: | ---: |
| BF16 | 0.360179253 / 3.052679 | **0.359300537 / 3.060145** | 0.245% |
| FP32 | 0.371955032 / 2.956034 | **0.371294022 / 2.961296** | 0.178% |

BF16 三轮范围 0.357949295–0.359368172 ms；FP32 为 0.371293449–0.371666145 ms。3.5P 对应 0.314146179 ms，当前 BF16 还需缩短约 45.2 µs（12.6%）。本轮多组交替比较中，该组合相对上一版通常改善 BF16 约0.2%–0.5%、FP32 约0.2%；这个幅度不能解释为大幅突破。

命令、每轮源/EXE SHA256 和原始日志：`results/continuation_20260911/round2/interleaved/formal_final/`。正式重建静态核对：相邻 `formal_static_validation.json`。原正式源与二进制快照在 `/tmp/mxfp8_fourwave_round2_20260911/baseline_before_round2/`；其源码、资源与哈希也已归档。

## 当前执行流程

输入契约仍是：A 为行主序 E4M3FN FP8 `[M,K]`；B 为 AITER `(16,16)` 预排的 FP8 `[N,K]`；A scale 为 E8M0 1×128、物理 `[K/128,M]`；B scale 为 E8M0 128×128、物理 `[N/128,K/128]`。输出是 BF16 或 FP32。

1. **提前首批 A(t0) 预取。** 在 scale 面板加载、DPP/perm 打包之前，先发 A 的两半 global→LDS 请求，使它们的延迟与 scale 准备重叠。
2. **A scale 保留完整 K 面板。** 每 tile 16 KiB 紧凑输入，通过16B向量 global load、quad DPP、byte perm，在寄存器内把四个 M repeat 的 scale 打成一个 dword，再写 LDS。两个 M128 half 各用一个 pack。
3. **B scale 保留广播打包，改变内部面板顺序。** 每 tile 输入128B，每个字节乘 `0x01010101`。LDS由旧的 `[half,K]` 改成 `[K,half]`，仍512B；相同 K 的两个 N128 half 占相邻8B。
4. **主循环预取 B scale pair。** 第38条 MFMA 后，通过一次普通 LDS b64 同时读下一 K 的两个 B scale pack。SFB0 此时可以替换；当前 SFB1 一直保留到本 K 的 c01/c11 全部消费完，才替换成 next[1]。最后一对是K63的字节504..511，无K64越界。
5. **合并 producer 分支。** wave0/1 在第2条 MFMA 后，于一个角色分支中发16条 A(t+1) 请求；wave2/3 在第38条后，于一个分支中发16条 B(t+2) 请求。原版每个半 tile 单独判断角色，现在合并判断。工作组全局请求总量、LDS图像、MFMA顺序和第36条MFMA后的发布 barrier 均保持原语义。
6. **保留上一轮的输出和寄存器滚动。** BF16 使用vec8写回和整体A0滚动；FP32按M repeat滚动A0。所有四个wave参与MFMA，C仍固定a0:a255。

整个 K 主循环没有 scale global load、scale LDS write 或 TR8。A 的 `op_sel` 选择该 dword 的 M repeat 字节；四个 K32 lane group 复用同一个 K128 scale。B 的四字节相同，同样供四个 K32 子组复用。没有创建全局1×32展开scale，没有重新量化A/B。

单次仍仅一个GEMM kernel，额外device scale workspace为0B，无host scale重排；B预排是外部既定输入。4 Wave64、MFMA16×16×128不变。K8192资源为AGPR256，普通VGPR FP32 **176** / BF16 **192**（metadata combined432/448），SGPR91，LDS152064B，零spill/scratch。通用K的两个kernel机器指令完全不变。

## 验证与清理

- 候选完整8192³的FP32/BF16各67,108,864个输出，与独立反量化GEMM参考逐值精确一致；该严格检查使用可精确累加的随机dyadic值。
- 另用完全复现CLI seed=1的FP8和E8M0输入，与已经独立验证的旧版作完整8192³逐值精确对比，通过。两种验证证据分别在 `shared_combinations.log` 和 `shared_cli_combinations.log`，不要混淆其参考来源。
- 小规模非dyadic CPU参考、真实AITER `shuffle_weight`、E8M0载体/metadata view、stream及out复用等既有测试适用；正式重建后又运行本目录接口测试，见 `formal_integration.log`。
- paired B scale边界、C256、native MFMA形状与dst=SrcC、LDS/VMEM CFG等待、wave内一致角色谓词、没有新增VMEM drain，均经CPU/ISA核对。详细审查在 `pair_b_early_a_merge/review/`。
- 清理了未用的单MFMA调度辅助函数、旧RSFB布局函数、多余空白与过时注释。保留两个stage地址表达式，因为删除它们会让编译器移动一条scalar multiply；清理后的完整ISA、EXE和shared library均与已验证候选相同。

当前正式源码SHA256：`97fc15711b5aaad38a91ea7387b42bdf1f0cd11f761f071a83bdb84c111d8ab2`。

## 本轮尝试与未采用原因

以下单轮值只用于筛选，不作为稳定性能结论；多轮结果明确标注。原始记录、源码及审核均在 `results/continuation_20260911/round2/`，`screening_index.json` 汇总所有候选。

| 方向 | 结果与结论 |
| --- | --- |
| A scale直接形成b128/b64 LDS store | pack_store16约3.034/2.926P；pack_store8约3.037/2.925P，未胜出。 |
| TR8读完整原始A scale面板 | 立即等待约2.988/2.888P；延后等待约3.032/2.927P。降低某些LDS计数但增加等待，未采用。 |
| A/B scale halves均成对读 | A pair约3.025/2.932P；AB pair约3.043/2.933P。只保留B pair组合。 |
| 独立wave私有LDS、减少WG同步 | 全局矩阵请求翻倍；原布局约1.857/1.821P，调整swizzle和B coalescing后约2.713/2.620P，仍慢。 |
| A0/A1按M repeat交错滚动 | 三轮BF16约3.063P，FP32约2.926P，综合不及选择。 |
| A/B DTLDS m0精简 | A每8请求m0更新8→4，SGPR降到76；B每8请求6→4，但单独版本未稳定胜出。叠加选中组合三轮约3.060/2.936P，FP32退步。 |
| WG按M分组 | group32三轮CLI BF16约3.077P、FP32约2.922P；同地址五轮BF16收益未稳定，未纳入。group4/8/16明显较慢。 |
| A四路交错producer行 | 全局请求数不变、CPU映射和GPU数值通过。BF16单次3.085P，但三轮中位3.028P；FP32中位2.962P。仅改A padding16/64后约3.06/2.94P，未纳入。 |
| A/B NT global、BF16 NT store | 分别出现约2.73/2.46P、2.88/2.70P、BF16约2.82P，均不采用。 |
| K展开调整 | unroll1约2.981/2.818P；unroll2及常量K展开触发原实验LLVM的hard-pin约束失败，没有修改编译器。 |

TR8的三个profile dispatch中，MFMA数与旧版同为16,777,216；LDS bank-conflict计数17,170,432→16,777,216，但SQ_WAIT_ANY中位25,775,247→32,725,578，SQ_WAVE_CYCLES 185,498,205→192,740,444。这证明不能仅凭减少bank-conflict计数选择版本。profile数据在 `profile_scale/`，正式性能不含profiler开销。

## 诊断限制与后续依据

`diagnostics/` 中四个程序故意省去部分实际GEMM数据操作，只为定位开销，均标为 `not_a_full_gemm=true`、不可选择。它们的“等效MFMA吞吐”不能宣称为GEMM性能，也不是严格硬件上限：

| 诊断（非完整GEMM） | BF16耗时ms | FP32耗时ms |
| --- | ---: | ---: |
| 重复驻寄存器操作数，仅保留MFMA/输出等 | 0.281357422 | 0.299609089 |
| 重复驻LDS操作数，省去steady matrix global | 0.316339417 | 0.334311218 |
| 共享流水线省去steady A global | 0.338828964 | 0.351880455 |
| 共享流水线省去steady B global | 0.344655914 | 0.357084084 |

它们表明矩阵LDS读取、矩阵global预取及同步重叠仍有代价；在已经消除主循环scale global与scale写入之后，只继续减少几条scale指令不足以填平45µs的差距。不同诊断使用的排程并非完全相同，因此不能把这些差值直接相加或视为某一路的精确耗时。

同地址测试还发现输入模式影响绝对吞吐：dyadic正确性输入使旧版本身也达到约3.183P，选中组合约3.203P；复现CLI的seed=1输入则恢复约3.04P的C-ABI计时。因此文首只报告固定标准CLI输入的3.060P，不将dyadic输入的3.2P混作代码优化收益。

本次只更新本地4-wave目录；AITER主仓分派、8-wave、rowmajor和原4-wave来源未改动。没有执行commit或push。适配器仍可作为gfx950/E8M0 blockscale_bpreshuffle的backend候选，尚未注册到AITER正式分派；FP32 scale不是本次工作范围。
