# 通用 4wave / tile1 续记：2026-09-12 延迟优化

目标仍为 **通用路径在 8192³ 达到 3.5P**，尚未达到。最新用户要求：scale也要像 `ga/sa/ra` 一样，使用真实的shape/dim/layout定义，保持无自定义宏。GPU有占用时仍按“先做，最后测试”执行；不要在满载卡上运行性能比较，不要再次询问已经授权的commit/push。没有授权停止其他GPU任务。

用户随后要求“整理完你先优化到这里吧”：完成本次整理、commit和push后暂停优化。下面的待测命令供后续恢复时使用，不自动继续运行或等待GPU。

## 当前生产与本轮基线

- 顶层 `tmpl_generic.hpp` 为 `generic_tile1_shape_dim_20260912`，六组scale均已接入真实的shape/dim/layout。**生成GPU代码与f483077不同；当前版本GPU正确性和性能未运行。** BF16 3.286311P / FP32 3.076707P属于f483077的历史成绩。
- **本轮比较基线就是 f483077**。9229d1a 和 f0b117c 是旧轮次基线。
- 冻结基线HPP SHA256：`69ef190d32fc10127deee1d06286233ecdde498e543a2d6c07d02b11696955be`；当前正式HPP为 `62d2f0f3b25bf89c70d55756348fff214937211a95ce669b0a3f12d512ecb513`，来源父提交为 `09734d65352d8ad46ab2902714158b0768f0b471`。
- 九份冻结源码：`results/generic_latency_20260912/baseline_source/`。
- 工作区：`/tmp/mxfp8_generic_latency_20260912_86xlkzt9`；候选源码、构建均在该目录，Git 保存可精确恢复的 patch/metadata。
- tile1 = 每 WG 一个完整 256×256 输出块，4 个 Wave64。所有新分工和 grid 变化仍是 tile1。
- 保持 M/N 正 256 倍数、K 正 128 倍数、现有 ABI 上限与连续 batch；原生 16×16×128 MFMA、256 AGPR、E8M0/AITER 输入、零额外 workspace。
- 物理 GPU2 = HIP2 = PCI `0000:65:00.0`。同进程同地址、相邻基线夹测，不改频率/功耗，计时不采 telemetry。
- 不使用子 agent；不修改或暂存相邻 fp32scale 目录。

此前移除全部7个自定义宏/undef，MMA直接调用已有内联模板，输出分为三个局部helper，`if constexpr` 从29处减少到7处。那次清理的完整GPU代码与f483077相同，历史证明保留在 `results/generic_source_cleanup_20260912/README.md`；旧验证脚本需要对应的09734d6 checkout，不能对当前HPP套用旧哈希。

本次进一步恢复 `make_layout_gsfa_scale/ssfa/rsfa` 与 `gsfb/ssfb/rsfb`，每组都有 `*_block_shape`、`*_block_dim`、`unfold_x_stride`、`unfold_p_coord`、`make_layout`。全局读取、LDS发布、首轮读取和下一K预取都使用对应 `u_*` layout。保持64个K128的面板容量、quad DPP打包、MFMA scale字节选择及运行时K流程；无宏、7处 `if constexpr` 和三行阶段标记保留。Epilogue从倒数第二个K128块开始，主循环每次K128、完整unroll4组K512。

隔离版本和正式目录均已 `make -j3 all inspect`，完整device object、实际共享库GPU fatbin及设备元数据相互一致；本次device object SHA256为 `3e8939186cf34434b178037c4c02724fbfb38627455192983c99d27b9ec0970c`。FP32/BF16普通VGPR为244/252、各256 AGPR、62 SGPR、152064B LDS，零spill；有效指令数2177/2759，各448条静态原生MFMA。使用实际layout函数的编译期断言通过，覆盖scale全局→打包→LDS→MFMA对应、完整且唯一的LDS写入、Vec4/Vec8、短K和多面板边界；链接ISA等待审查也通过。详见 `results/generic_scale_layouts_20260912/README.md`。

11:16:26 UTC只读查询GPU2，仍为100%利用率、80%显存占用，没有启动GPU kernel。新版运行验证与8192同地址复测单独记录在 `results/generic_scale_layouts_20260912/gpu_revalidation.json`。19个性能候选保持原始源码、二进制、命令和f483077基线；最终采用候选时也要保留无宏以及scale的shape/dim/layout写法。

## 历史五轮候选成绩，需空闲复测

针对用户询问“GPU2 有占用时怎么测试”：`small_gains_confirm_gpu2` 的实际计时为 **07:33:01.393747—07:33:10.738447 UTC**。启动前 GPU2 的利用率与显存占用为 0%，07:58:39 的后续记录为 100% / 80%。原窗口没有计时期间 telemetry，也没有紧接计时后的占用快照，因此不能证明全程无干扰或推断外部任务开始时间。3.298755P 是历史候选成绩，正式选择前必须在空闲窗口重新确认。详见 `timing_provenance.json`；原始样本未改动。

`small_gains_confirm_gpu2` 五轮同地址窗口：

| 版本 | BF16 P | BF16 配对提升 | 正轮数 | FP32 P | FP32 配对提升 | 正轮数 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| baseline | 3.288553 | — | — | 3.078601 | — | — |
| grid_group2 | **3.298755** | **+0.242146%** | 5/5 | **3.084523** | +0.137128% | 5/5 |
| compact_uniform_preload8 | 3.293376 | +0.167012% | 5/5 | 3.081490 | +0.097869% | 4/5 |
| output_pingpong_136 | 3.291857 | +0.078512% | 4/5 | 3.079104 | −0.018451% | 2/5 |

尚未正式选择或替换生产版本。不要把约 3.30P 候选写成 3.5P，也不要将本轮候选性能与旧窗口正式基线直接相除。

## 已完成源码和静态检查，待最后 GPU 验证

准确列表、哈希、命令在 `results/generic_latency_20260912/pending_tests.json`。19 版均已编译、零 spill，并通过独立坐标/操作数证明及链接 LDS/VMEM 等待检查，**尚未跑 GPU**。

1. `scalar_matrix_group4` / `group8` 及各自 `_resident`：16 份 VOFFSET 缓存改为 4/8 份，完整行组的位移放到非负 SOFFSET。BF16 普通 VGPR 分别 244/248；去掉末尾 A1/SFB1/B1 reload 后分别 252/256，仍然零 spill。原来未释放寄存器就删 reload 的版本有 spill，不能混用。每版独立枚举 110592 个请求向量，覆盖小 K、面板边界和 ABI 上限，并证明任意 K 的代数恒等式。
2. `contiguous_waves`、`contiguous_waves_private68/72`：每个 M128×N128 区域内每 wave 计算连续 64×64；成对改变 A/B consumer、scale pack 来源和输出坐标，物理矩阵 producer 保持原样。私有输出槽尝试每行连续 128 字节写回，保留初次矩阵退休的 WG barrier。
3. `grid_group2_out136`、`grid_group2_compact8`、`grid_group2_out136_compact8`：组合已经单独测量的小收益。
4. `grid_morton_g4_nfirst/mfirst`、`grid_morton_g8_nfirst/mfirst`、`grid_morton_g16_mfirst`：完整 tile 组内交错 M/N 坐标位，不完整组使用原映射。仍是二维 grid，Z=batch。
5. `scalar4_a1m2_prefetch54`、`scalar4_b1n3_prefetch54`、`scalar4_tail_prefetch54`、`scalar4_resident_b1n3_prefetch54`：在 group4 地址压缩基础上，把 A1/M2、B1/N3 的读取分别或同时从 MFMA63/64 提前到54，安装仍留在63/64。最后一版同时去掉最终重复读取。BF16 普通 VGPR 分别244/252/252/244，FP32分别232/232/248/232。逐个 MFMA 的符号执行证明当前操作数不被提前覆盖、下一轮操作数完整；所有带 t+2 请求的链接主体与父版 LDS 发射计数逐点一致，只发生预定的读取移动。错误提前覆盖的反例被拒绝。没有运行成绩。

没有未收取的编译任务，也没有后台 GPU 任务。`combinations_gpu2` 先前在空闲预检查处退出，未创建测量窗口、未启动候选。

新增四版全部完成 CPU 检查后，08:29:16 UTC 重新查询 GPU2：仍为100%利用率、80%显存占用；见 `results/generic_latency_20260912/gpu2_availability_20260912T082916.json`。本次没有启动任何 GPU kernel，19个候选仍待运行验证。

## 已排除的方向和诊断

A LDS XOR mask3/7 四版的映射/运行正确性均通过，但较好的也只有约 3.27P，同窗口基线约 3.28P。强制 BF16 pack 落实与逐 fragment 调度没有明显提升；两个强制原 FP32 累加片段进入可写 VGPR 的版本因 hard-pin 约束编译失败。未修改共用编译器。

当前基线 ATT：主循环约 2092.1 cycles/K128、启动5860、尾部7766；尾部含最后64条MFMA。`a_xor7` 约2100/5850/7870，严格输出调度版约2106.5/6102/7870，诊断数据不当作性能结果。

显式 m0、矩阵 cache、旧 wave4×1、输出双槽、compact 参数等更早实验的细节见 [本轮记录](results/generic_latency_20260912/README.md)。m0 额外精确身份审查只证实 explicit1/2；组合 m0_grid_group2 仅标准 ISA/GPU 检查通过。literal-zero SrcC probe 的 hard-pin 编译失败已单独保存。

## 接下来

空闲GPU2先单独验证当前shape/dim版本，按新布局记录中的命令执行22组通用正确性、完整8192独立参考和五轮同地址比较；该次对照为09734d6源码，其GPU代码与f483077逐字节相同。当前版本尚无跑分，不能直接沿用旧成绩。

19个性能候选仍按 `pending_tests.json` 的五批原命令筛选，新预取批次包括两个scalar_group4父版作为同窗口对照。保留负结果。胜出者对f483077五轮确认，微小组合另做父版直接比较。随后按无宏和shape/dim/layout风格整理选定源码、重建、核对实际GPU代码；若整理改变指令，须重新验证和计时最终版本。验证实际适配器后，按8192、1024、2048、4096顺序记录性能与正式更新。

`screen.py` 现在默认核对 GPU2 的固定 PCI，并在 shapes/full/shared 每个 GPU 子进程前后保存占用快照。出现占用或检查失败就停止后续阶段，原始计时保留并标记需重测；计时过程不采 telemetry。两端快照均空闲仍不能排除窗口内短暂干扰，必须结合相邻基线漂移与重复窗口。6 项 CPU 模拟检查通过，涵盖开跑前阻止启动、验证后停止计时、计时后占用证据保存，未调用 GPU。

`summarize.py` 当前索引 78 个版本、120 条计时汇总；77 个补丁已精确重建。计时关联使用 HPP + library 双哈希，并标记窗口占用证据与是否需要空闲复测。生产公开比较工具暂时仍属于上一轮，不要误拿它测试本轮候选。
