最新正式版本与第二轮性能见 [CONTINUATION_20260911_ROUND2.md](CONTINUATION_20260911_ROUND2.md)。下面保留第一轮实验记录。

> 这是对应轮次的历史记录。当前正式版本见 [第三轮续记](CONTINUATION_20260911_ROUND3.md)；清理后移出的原始实验路径见 [归档索引](results/ARCHIVE_20260911.md)。

4-wave E8M0 优化续记 — 2026-09-11
==================================

本轮选入 `selected_ab_dtype_roll`：BF16 使用 `ab_store8`，FP32 使用 `ab_store8_a0_mrepeat` 的排程。单个 C++ 模板通过 `if constexpr` 选择，两个 dtype 的完整机器指令与各自候选完全相同。通用 K 的两份 ISA 与上一版完全相同。

输入仍为 FP8 A/B，A 行主序，B 为 AITER `(16,16)` preshuffle。A scale 为 E8M0 1×128、物理 `[K/128,M]`；B scale 为 E8M0 128×128、`[N/128,K/128]`。每次只启动一个 GEMM，没有 host scale 重排、没有额外 device scale workspace，没有重新量化，也没有更改 MFMA 的 16×16×128 形状。C 仍固定在每线程 a0:a255。

性能
----

物理 GPU2，PCI `0000:65:00.0`，MI355X/gfx950、256 CU。所有性能均为 8192³、b=1、w=200、i=100，kernel-only。三轮交替、第二轮反序，取中位数。正式目录重建后的最终复测：

| 版本 | BF16 ms / PFLOP/s | FP32 ms / PFLOP/s |
| --- | ---: | ---: |
| 上一版快照，同时间段 | 0.373216 / 2.946044 | 0.382766 / 2.872541 |
| 本轮正式目录 | **0.359965 / 3.054498** | **0.372731 / 2.949882** |

BF16吞吐提高3.68%，FP32提高2.69%。正式目录的exe、shared library和四个kernel的完整ISA均与选定候选一致。12份性能日志及命令在 `results/continuation_20260911/interleaved/formal_final/`，重建哈希和资源检查在 `formal_static_validation.json`。

此前用于选择组合的另一组三轮记录：

| 版本 | BF16 ms / PFLOP/s | FP32 ms / PFLOP/s |
| --- | ---: | ---: |
| 上一版完整 K scale 面板 | 0.372633 / 2.950652 | 0.382401 / 2.875287 |
| A/B 分工 + BF16 vec8 | 0.360300 / 3.051660 | 0.376722 / 2.918629 |
| 上项 + A0 按 M repeat 滚动 | 0.365321 / 3.009717 | 0.372593 / 2.950972 |
| 本轮选择：按 dtype 保留快路径 | 0.360300 / 3.051660 | 0.372593 / 2.950972 |

BF16 吞吐提高约 3.42%，FP32 约 2.63%。BF16 最终采用的三轮范围为 0.360236–0.360406 ms。分片 A0 的 BF16 波动至 0.356733–0.367877 ms；没有用其最快一次 3.082P 作为结论。3.5P 需要 0.314146179 ms，尚未达到。

三轮原始命令、源码/二进制哈希和日志位于 `results/continuation_20260911/interleaved/combined_ab_store/`。另一次只比较 A/B 分工与跨输出块 handoff 的三轮结果位于相邻的 `first_ab_vs_full/`。

保留的改动
----------

1. **A/B producer 分工。** 旧版四个 wave 都发 A、B 请求。现在 wave0/1 发 A(t+1)，wave2/3 发 B(t+2)；每个 producer 覆盖两份原 wave 地址。单个 producer 的请求数增加，但整个工作组的字节数与 LDS 图像完全相同。四个 wave 继续计算。单独只分工 A 或 B 都没有得到这一收益，二者组合才有效。
2. **BF16 vec8 写回。** 两个相邻 N-repeat C 片段先做原来的 RNE BF16 转换，再通过 `permlane16_swap` 交换 lane 与 lane xor 16 的片段。每个 wave 的写回从 64×8B 变为 32×16B。输出坐标和数值保持一致，FP32 写回未改。
3. **仅 FP32 使用 A0 分片滚动。** 每个 M repeat 完成其四个 N consumer 后，提前读下一轮 A0 对应的两个 K64 片段。第一组仍在原第 36 条 MFMA 后的发布 barrier 之后，后面各组等待本 M 的最后一次使用。SFA0 保留到整个 c01 完成之后才替换。BF16 保留原来的整体 A0 滚动。
4. **修正 B 预取的 unsigned offset。** 原 contiguous B helper 的 Issue1 把 1056B 全折进 immediate，K0 时 scalar offset 为 -32。MUBUF 按 unsigned scalar offset 处理，不能依赖它与 immediate 相消。现在 immediate=1024、LDS base 增加32，源地址和目标 LDS 地址均正确。旧正式版只在不被消费的最后一次回绕预取碰到它；跨输出块或 K 旋转方案会消费它，因此本轮专门修复并审计。

Scale 路径及来源
----------------

Blockscale 输入契约、打包和 `op_sel` 的移植依据主要是此前 8-wave bpreshuffle；4-wave 矩阵流水线继承用户提供的 C256 AGPR 版本。gfx950 MXScale BMM 提供相同的 K128→四个 K32 子组复用语义，本实现未移植其完整加载流水线。

K8192 的 scale 面板方案保留：A 的 16 KiB scale 经向量 global load、quad DPP 和 byte permute，在寄存器中直接打包后写入 LDS；B 128B 输入经 `s * 0x01010101` 写入 512B LDS。主循环用普通 LDS dword 读，A dword 的四个字节对应四个 M repeat，`op_sel` 选择行 repeat。四组 K32 lane 读取同一个 dword，所以复用同一 K128 scale。B dword 的四字节相同。

因此主循环没有 scale global load、scale LDS write 或 TR8；也没有创建全局 1×32 scale 张量。本轮主要减少矩阵预取和计算的相互等待，以及 BF16 写回的指令开销。

资源和正确性
------------

K8192：4 Wave64、256×256×128 tile、LDS152064B、SGPR92、AGPR256；FP32 普通 VGPR184，BF16 普通 VGPR192，零 spill/scratch。metadata 的 combined VGPR 为440/448，包含 AGPR。

- A/B producer 各枚举262144个16B请求，所有stage/K位置与独立全局坐标、原LDS图像一致，无漏、重、越界；Issue1 unsigned修复覆盖K0。
- ISA中每个panel的20个角色分支都由thread ID追溯到波内一致谓词；被选wave发8个DTLDS，其他wave发0个，然后汇合到同一下一条MFMA。没有EXEC修改。
- 所有kernel保持C固定a0:a255、MFMA dst=SrcC；LDS/VMEM控制流及循环回边等待检查通过。
- vec8枚举65536个输出坐标，16B对齐、无漏写/重写；256个AGPR每个在最后使用后读取一次。
- 新路径的非dyadic输入在M1280/N256/K8192、batch2通过FP32/BF16 CPU参考验证。
- 真实AITER shuffle、两种scale载体/metadata、当前stream和out复用检查通过。8192³的FP32/BF16各67108864个输出与独立反量化GEMM参考逐值精确一致，输入为可精确累加的随机dyadic值。

44份实验记录及源码相对旧版的差异见 `results/continuation_20260911/experiments.json` 与 `experiments/`；数值失败的原handoff和phase候选已明确标为不可用性能。审查见 `results/continuation_20260911/ab_role_review/`，全输出测试见 `full_integration.log`，合并模板与两份父候选ISA一致性见 `parent_isa_comparison.json`。AITER本机导入对其CK/HIP JIT发出了环境提示，但测试使用的真实shuffle及本目录独立C ABI均执行成功；没有将此测试声称为AITER正式backend注册验证。

性能计数器补充
--------------

对旧模板及新BF16排程各采集三个dispatch，MFMA数量均为16,777,216，LDS bank-conflict计数均为17,170,432。`SQ_WAVE_CYCLES`中位数从195,855,788降到185,266,635（约5.4%）；`SQ_ACTIVE_INST_VMEM`从10,346,693降到9,410,953。

`SQ_WAIT_INST_LDS`却从3,069,702升到4,575,246，`SQ_WAIT_ANY`从23,524,308升到25,716,068。后续三缓冲B的 `SQ_WAVE_CYCLES` 达218,970,939，`SQ_WAIT_ANY` 达54,936,018，均明显高于选定排程。因而提前B预取并不足以补偿额外同步和排程开销。

因此没有把单个wait或bank-conflict计数作为性能结论；本文PFLOP/s均来自未开启profiler的常规b1/w200/i100计时。命令和CSV在 `results/continuation_20260911/profile_coexecution/`。

未选择的方向
------------

- 原始矩阵 K0 handoff 在后续 M tile 数值失败，原因是上面的 unsigned B offset；它的旧性能无效。修正后正确，完整 scale+矩阵 handoff 三轮BF16约2.965P、FP32约2.896P，慢于本轮选择。
- A/B分工再叠加完整handoff得到29个SGPR spill到VGPR，单轮与只分工基本持平，未采用。
- 单独A分工约2.866P BF16；单独B分工约2.953P，二者组合才提升。
- 普通流水线发布点改32/40/44条MFMA、多个LDS padding、B scale驻寄存器、8-wave逐MFMA调度组、B1提前滚动和A直接global→VGPR均未胜出。直接A虽然正确，但重复请求增加，只有约1.7P。
- 新A/B分工+vec8上再把发布点改32/40/44，BF16分别约2.988/3.031/3.013P，仍不及保留的36点。
- A单缓冲+B三缓冲在相同152064B LDS内把B预取提前到t+3。尝试A在第4/12条MFMA后释放，两版正确且ISA确认B-wave的vmcnt(16)保留远期B请求，没有隐藏vmcnt(0)。但BF16仅2.786/2.799P，FP32约2.660P，均较慢，未选入。源码、部分等待ticket证明和日志见 `three_slot_b_review/` 与实验记录。
- 把A/B producer角色判断移到整个K循环之外的手工unswitch触发hard-pin约束失败，未运行GPU，也未修改编译器。
- 修复地址后的K循环phase8方案正确，但1倍展开只约2.963P BF16；4倍展开触发现有实验编译器hard-pin约束失败。没有为此修改编译器。

临时实验仍在 `/tmp/mxfp8_fourwave_e8_continue_20260910`；旧正式模板及二进制已快照到其 `baseline_before_abroles/`，正式目录只选入已验证的单tile快路径。
