# 通用 4-wave / tile1 延迟优化：2026-09-12

本轮冻结基线为 **`f483077e0263bc8d39ad810ad4c1f03b93727702`**，即正式 BF16 3.286311P 版本。顶层生产源码尚未替换；**3.5P 尚未达到**。所有候选仍支持运行时 K，不包含 8192 专用主体。4-wave / tile1 表示四个 Wave64、每工作组一个完整 256×256 输出块。

历史五轮窗口中，`grid_group2` 在 GPU2 上为 **3.298755P**，相邻基线归一化提升中位数 **0.242146%**，5/5 轮为正。该窗口仅保存了开跑前空闲快照，随后观察到外部占用，**正式选择前需要空闲复测**。后续 19 个候选已完成编译、独立映射/操作数证明和链接 ISA 审查；按用户“先做，最后测试”的要求，运行验证与性能测试放到 GPU 空闲时。准确待测列表和源码/二进制哈希见 `pending_tests.json`。

## 范围和测量方法

- 正 M/N 为 256 的倍数，正 K 为 128 的倍数，在现有 ABI 字节数限制内支持连续 batch。
- 保留原生 `v_mfma_scale_f32_16x16x128_f8f6f4`、固定 256 AGPR、E8M0/AITER 输入、零额外 device workspace。
- 性能只筛选 8192³；其他 K、非方阵和 batch 用于正确性。正式选定后按 8192、1024、2048、4096 的顺序记录性能。
- 物理 GPU2 = HIP2，PCI `0000:65:00.0`。不改频率或功耗。计时期间不采 telemetry。
- 基线和候选在同一进程共享全部 tensor 地址，按基线—候选—基线交替，逐轮反转候选顺序。warmup200、iterations100，原生 HIP event 只测 GEMM。
- `screen.py` 核对 GPU2 固定 PCI，并在每个 shapes/full/shared 子进程前后保存占用快照。计时期间不查询监控；若任一阶段发现占用或检查失败，停止后续执行，保存样本并标为需重测。紧接测试后的利用率可能包含本次工作，只有显存已释放时才最多等待两秒重查。边界空闲也不能排除窗口内短暂干扰，仍要检查相邻基线漂移和重复窗口。
- `summarize.py` 同时用 **HPP 哈希和实际加载的 library 哈希**关联计时证据。编译选项相异的候选不能只按相同 HPP 合并。

`baseline_source/` 保存冻结的九份源码、配置和有效指令编码。基线 HPP SHA256 为 `69ef190d32fc10127deee1d06286233ecdde498e543a2d6c07d02b11696955be`。当前临时工作区记录在 `work_path.txt`；生产和本轮基线均为上述同一源码。

## 历史五轮窗口的小幅变化

实际计时窗口为 **2026-09-12 07:33:01.393747—07:33:10.738447 UTC**，PCI 为 `0000:65:00.0`。开跑前记录 GPU use=0%、VRAM=0%；07:58:39 的后续记录为100%/80%。原窗口没有运行中的 telemetry 或紧接运行后的快照，不能证明全程没有外部干扰，也不能由此确定外部作业开始时刻。以下数据保留原值并标记待空闲复测，细节在 `timing_provenance.json`。`output_materialized_gpu2` 的最大相邻基线漂移约1.896%，样本同样保留，不用于正式选择。

窗口：`shared_allocations/small_gains_confirm_gpu2/`。下表 P 由各版本时间中位数换算；配对提升对每个候选使用其相邻两次基线，统计口径不同。

| 版本 | BF16 P | BF16 配对提升 | 正轮数 | FP32 P | FP32 配对提升 | 正轮数 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 冻结基线 f483077 | 3.288553 | — | — | 3.078601 | — | — |
| grid_group2 | **3.298755** | **+0.242146%** | 5/5 | **3.084523** | **+0.137128%** | 5/5 |
| compact_uniform_preload8 | 3.293376 | +0.167012% | 5/5 | 3.081490 | +0.097869% | 4/5 |
| output_pingpong_136 | 3.291857 | +0.078512% | 4/5 | 3.079104 | −0.018451% | 2/5 |

`grid_group2` 交换完整 2×2 tile 组中的最低 M/N 坐标位；不完整分组保持原二维映射。每个工作组仍是 tile1。之前两个独立三轮窗口的 BF16 配对提升分别为 +0.2543% 和 +0.3423%，均 3/3 为正。

`compact_uniform_preload8` 保留公开 96 字节 C ABI，在私有 device 参数中只传五个指针和 M/N/K，派生已由公开入口校验的连续 strides。编译器选项 `-amdgpu-kernarg-preload-count=8` 的链接 descriptor 实际预加载 13 个 SGPR dword；`audit_kernarg_preload.py` 从 ELF 读取并验证。K0 的标量 offset 显式 `readfirstlane`，避免 EXEC waterfall。此路径只存在于候选中，生产 ABI 和 device 签名未改变。

`output_pingpong_136` 让 C00/C10 使用两个 LDS 槽，随后 C01/C11 复用，保持 16 字节读取/写回。既有 publication36/52 先退休被复用槽的旧读取。BF16 普通 VGPR 从 256 降为 248，但实测收益很小。

## 最后待测的候选

以下均**尚未执行 GPU kernel，不能填写性能或宣称运行正确性通过**。它们通过零 spill、256 AGPR、原生绑定 MFMA、EXEC 不变、LDS/VMEM 等待依赖检查。

| 候选 | BF16 普通 VGPR | FP32 普通 VGPR | SGPR | 主要变化 |
| --- | ---: | ---: | ---: | --- |
| scalar_matrix_group4 | 244 | 232 | 74 | 4 份地址缓存，其他矩阵行组使用非负 SOFFSET |
| scalar_matrix_group4_resident | 252 | 240 | 74 | 上述变化，并去掉末尾重复 A1/SFB1/B1 读取 |
| scalar_matrix_group8 | 248 | 236 | 62 | 8 份地址缓存，两个行组复用 |
| scalar_matrix_group8_resident | 256 | 244 | 60 | 上述变化，并保留最终操作数在寄存器中 |
| scalar4_a1m2_prefetch54 | 244 | 232 | 74 | A1/M2 从 MFMA63 后提前到54读取，仍在63后安装 |
| scalar4_b1n3_prefetch54 | 252 | 232 | 74 | B1/N3 从 MFMA64 后提前到54读取，仍在64后安装 |
| scalar4_tail_prefetch54 | 252 | 248 | 74 | 同时提前 A1/M2 和 B1/N3 |
| scalar4_resident_b1n3_prefetch54 | 244 | 232 | 74 | B1 提前读取，加最终操作数驻留 |
| contiguous_waves | 256 | 244 | 62 | 每个 128×128 区域内，各 wave 负责连续 64×64 |
| contiguous_waves_private68 | 248 | 244 | 62 | 连续分工，加 wave 私有输出槽，两个 b64 读取 |
| contiguous_waves_private72 | 248 | 244 | 62 | 连续分工，加 wave 私有输出槽，一个 b128 读取 |
| grid_group2_out136 | 248 | 244 | 62 | 组合 grid_group2 和双输出槽 |
| grid_group2_compact8 | 256 | 244 | 60 | 组合 grid_group2 和私有参数预加载 |
| grid_group2_out136_compact8 | 248 | 244 | 60 | 三项组合 |
| grid_morton_g4_nfirst / mfirst | 256 | 244 | 62 | 完整 4×4 tile 组的 M/N 位交错 |
| grid_morton_g8_nfirst / mfirst | 256 | 244 | 62 | 完整 8×8 tile 组的 M/N 位交错 |
| grid_morton_g16_mfirst | 256 | 244 | 62 | 完整 16×16 tile 组的 M/N 位交错 |

所有版本额外各有 256 AGPR，LDS 仍为 152064B。减少普通 VGPR 不等同于增加驻留 wave 数。

地址缓存压缩保留每四个请求的 m0 和 immediate。原来 16 份 VOFFSET 中的完整行组位移改为 SOFFSET，K 仍在运行时推进。独立证明对每版枚举 110592 个请求向量，覆盖 K128、256、384、8192、8320、32896 和 ABI 上限附近的 K8388480，并证明通用代数恒等式、对齐与非负标量偏移。此前直接删除最终 reload 会产生 2 个 VGPR spill / 12B scratch；这次先释放地址缓存后，两种 resident 版均已达到零 spill，但仍需实际验证与计时。

新增四版在 group4 基础上利用独立寄存器提前读取下一 K 的末尾操作数，保持旧值的最后一次消费与安装位置。`audit_tail_operands.py` 对主循环、倒数第二轮逐个 MFMA 执行操作数版本检查，并确认所有 A/B/scales 完整滚入下一 K；错误的提前覆盖反例会失败。链接 ISA 的每个 t+2 producer 主体都与对应父版逐点比较 LDS 发射计数，验证读取实际移到54，63/64处对应读取消失；证据绑定 HPP 与 ISA 哈希。寄存器分配变化由编译产物确认，性能变化尚未测试。

本次 CPU 准备后的占用检查为 **08:29:16 UTC**，GPU2 仍为100%利用率、80%显存占用，未启动任何 GPU 验证或 benchmark；快照为 `gpu2_availability_20260912T082916.json`。

连续 wave 分工保留原矩阵 producer 的物理 LDS 布局，成对修改 A/B consumer、A-scale 四个 repeat 的来源和 C 坐标。每个 wave 在四个 128×128 区域中各拥有连续 64×64，四个区域共同组成工作组的唯一 256×256 tile。独立证明枚举两级 A/B 缓冲区、256 行 scale 配对和全部 65536 个输出。私有输出版的连续 64 列对应每行 128 字节，尝试改善此前 wave 私有输出的合并写回。

Morton 候选仅重排完整局部 tile 组；不足组大小时保持二维 grid 的原映射。证明检查生成的精确坐标表达式、独立逆映射、组间平移和边界 fallback。Z 仍是 batch。

## 已完成但未采用的方向

完整状态、资源、计时窗口和失败原因在 `candidate_index.json`、`screening_windows.json`、`early_rejections.json`。

- A LDS K-vector XOR：mask3/7 的 producer/consumer 对应关系、两级缓冲区和 signed K64 stride 全部通过；四版均通过 22 组通用形状和完整 8192。较好的 mask7 约 3.27P，同窗口基线约 3.28P，未胜出。
- 显式提前准备 m0：一条/两条 MFMA lead 的修复版正确且零 spill，小收益未超过 grid_group2。原 `prepare_m0_lead2` 在上一组最后请求前改变 m0，已在 GPU 执行前排除。单独 explicit1/2 通过精确 m0 顺序核对；组合 `m0_grid_group2` 仅通过标准 ISA/GPU 检查，额外精确寄存器身份审查尚不支持该组合，不能混称全部通过。
- 输出转换顺序：强制 BF16 pack 落实到 VGPR、严格逐 fragment 流式存储均通过运行正确性，收益很小。对原 FP32 累加片段施加可写 VGPR 约束的两版触发 hard-pin 编译失败；没有放松约束或执行 GPU。
- 矩阵 cache2/3 策略使 BF16 降至约 2.534P；cache1 和 B-scale byte0 没有改善。已有缓存复用对性能很重要。
- 四个 M wave 的 4×1 分工正确但较慢；unroll4 的两版因硬寄存器约束编译失败。此方向与新 2×2 连续 wave 分工不同。
- 输出双槽的原始 xor128 版被链接等待审查拒绝；加显式 LGKM 退休的另名修复版正确但更慢。三个旧 resident 输出版有 spill，未执行 GPU。
- 初始 compact 参数版本产生 EXEC waterfall，未执行 GPU。`uniform` / `roles` 修复版通过；实际 descriptor 预加载数量已保存。
- literal-zero SrcC 的 compile-only probe 在 hard-pin pass 失败，见 `zero_acc_probe_result.json`。未修改共用编译器。

没有删除测得的负结果或异常样本。`output_materialized_gpu2` 有一个偏慢基线样本，保留原始记录；其后观察到全卡外部占用，此筛选未用于正式选择。

## ATT 诊断

| 候选 | 主循环 cycles/K128 | 启动 cycles | 尾部 cycles |
| --- | ---: | ---: | ---: |
| baseline | 2092.1 | 5860 | 7766 |
| wave4x1_private_u2 | 2152.9 | 5778 | 7294 |
| output_pingpong_132 | 2088.1 | 5946 | 7856 |
| a_xor7 | 2100.0 | 5850 | 7870 |
| output_stream_packed_materialized_out136 | 2106.5 | 6102 | 7870 |

尾部包含最后 64 条 MFMA。ATT 只用于定位指令间隙，不能替代整卡 benchmark；相邻 MFMA 的短/长 gap 也不能逐项当作额外开销相加。原始路径、命令与 HPP 哈希在各 `profiles_gpu2/*/command.json` 中。

## 验证、恢复和后续执行

`screen.py` 依次执行链接 ISA 审查、通用 shape 正确性、完整 8192 独立反量化参考与 CLI seed1 基线相等检查，然后同地址计时。当前通用集为 22 组；早期窗口实际使用 16 或 20 组，以各 validation 记录为准。

从 kernel 目录继续，以下五批均需 GPU2 空闲，tag 必须尚未使用：

```bash
python3 results/generic_latency_20260912/screen.py scalar_matrix_group4 scalar_matrix_group4_resident scalar_matrix_group8 scalar_matrix_group8_resident --tag scalar_addresses_gpu2 --gpu 2 --rounds 3
python3 results/generic_latency_20260912/screen.py scalar_matrix_group4 scalar_matrix_group4_resident scalar4_a1m2_prefetch54 scalar4_b1n3_prefetch54 scalar4_tail_prefetch54 scalar4_resident_b1n3_prefetch54 --tag tail_prefetch_gpu2 --gpu 2 --rounds 3
python3 results/generic_latency_20260912/screen.py contiguous_waves contiguous_waves_private68 contiguous_waves_private72 --tag contiguous_waves_gpu2 --gpu 2 --rounds 3
python3 results/generic_latency_20260912/screen.py grid_group2_out136 grid_group2_compact8 grid_group2_out136_compact8 --tag combinations_gpu2 --gpu 2 --rounds 3
python3 results/generic_latency_20260912/screen.py grid_morton_g4_nfirst grid_morton_g4_mfirst grid_morton_g8_nfirst grid_morton_g8_mfirst grid_morton_g16_mfirst --tag morton_gpu2 --gpu 2 --rounds 3
```

`combinations_gpu2` 的首次尝试在 GPU 空闲预检查处退出，尚未创建该窗口或执行任何候选。

每个 `candidate_patches/NAME/change.patch` 都相对于本轮 `baseline_source/`，包含实际更改的支持文件；同目录 `candidate.json` 给出全部九份源码哈希。复制基线文件到隔离目录、应用补丁后即可重建。生成脚本记录变换的原因与实现；不要重复运行会覆盖现存候选的生成步骤。`summarize.py` 已逐字节证明 **77 个补丁**能精确重建，当前共 **78 个版本、120 条计时汇总记录**。

`check_device_windows.py` 的6项检查完全使用 CPU 与模拟子进程，确认错误卡号会被拒绝、开跑前占用时不启动 HIP probe/GPU 子进程、验证后占用时不进入性能阶段，以及计时后出现占用时保存原始结果和 `BUSY_AFTER` 标记。实际占用快照是后续 GPU 阶段必须新增的证据，不能反填到历史窗口。

最终胜出者仍需对 f483077 做五轮确认，微小组合收益需直接与其父候选对比。随后清理代码并证明指令等价，重新构建、验证实际适配器、按 8192/1024/2048/4096 记录性能，再更新正式版本与公开比较工具。顶层 `tools/compare_versions.py` 当前仍比较旧轮次冻结的 9229d1a 与生产 f483077；它不是本轮候选比较入口。

本轮未触碰相邻 `../mxfp8_gemm_16x16x128_blockscale_bpreshuffle_4wave_fp32scale/`。
