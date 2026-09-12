# 通用4wave / tile1发射调度优化：2026-09-12

最终版本为 `generic_tile1_issue_20260912`，选自 `grid2d_unroll4`。顶层 `tmpl_generic.hpp` 仍是唯一实现：4个Wave64，每WG一个完整256×256输出tile，正M/N为256倍数，正K为128倍数，在已有ABI字节数限制内支持连续batch。8192走同一运行时K路径，输入仍为AITER预排B与紧凑E8M0 scales，额外device workspace为0。**当前8192³正式构建BF16为3.286311P，3.5P目标尚未达到。**

本轮基线固定为提交 `9229d1a57f24cdd3da47ba3e03545d08d4f001e1`，即上一轮已提交的3.259P通用版本。冻结的9份源码及支持文件在 `baseline_source/`。基线头文件SHA256为 `6472526cabcb12957570f8540b13adae296ab35f637e9f254c4a7a00e0e58483`；本轮最终头文件为 `69ef190d32fc10127deee1d06286233ecdde498e543a2d6c07d02b11696955be`。

## 同卡确认

物理GPU2 = HIP2，PCI `0000:65:00.0`。8192³、batch1、CLI seed1，同一进程内共享全部输入和输出地址，按“基线—候选—基线”交替计时，逐轮反转候选次序。warmup200、iterations100，原生HIP event只测GEMM，不包含输入生成、shuffle、参考运算或分配；计时期间无telemetry，不调整频率或功耗。

`shared_allocations/final_schedule_confirm_gpu2/` 的五轮中位数：

| 版本 | BF16 P | FP32 P |
| --- | ---: | ---: |
| 本轮基线 `9229d1a` | 3.258160 | 3.049997 |
| 发射位置 / m0 / 优先级组合，flat grid | 3.275938 | 3.067889 |
| 上述组合 + 2D grid，unroll8 | 3.280858 | 3.072687 |
| **2D grid + unroll4，最终选择** | **3.286620** | **3.076171** |
| 2D grid + unroll16 | 3.261916 | 3.056319 |

选定候选相对相邻基线归一化的提升中位数为BF16 **0.862868%**、FP32 **0.871002%**，两种输出均5/5轮为正。P由各版本的时间中位数换算，配对提升逐轮计算，两者统计口径不同。

`shared_allocations/unroll4_direct_confirm_gpu2/` 进一步直接比较unroll4与unroll8：BF16为3.287721P vs 3.284048P，FP32为3.080904P vs 3.077765P。unroll4配对提升中位数为0.089204% / 0.158498%，分别4/5与5/5轮为正。这项收益很小，整套改动的收益以对 `9229d1a` 的五轮比较为准。保留所有样本，不把短筛选中的单次3.295P作为稳定水平。

公开工具从源码独立重建后，`shared_allocations/reproduction_confirm_gpu2/` 的另一次五轮结果为BF16基线3.266057P、最终版3.288106P，FP32基线3.056781P、最终版3.080897P；配对提升中位数为 **0.725345% / 0.788958%**，均5/5轮为正。基线和最终版均通过源码与指令编码核对，增益在重建后保持。

## 正式构建四尺寸

清理后的正式构建按8192、1024、2048、4096顺序，各输出五轮测量，结果在 `final_shapes_gpu2/`：

| M=N=K | BF16 ms | BF16 P | FP32 ms | FP32 P |
| ---: | ---: | ---: | ---: | ---: |
| 8192 | 0.334573174 | **3.286311** | 0.357366333 | **3.076707** |
| 1024 | 0.013218050 | 0.162466 | 0.017790860 | 0.120707 |
| 2048 | 0.021611280 | 0.794949 | 0.025707681 | 0.668278 |
| 4096 | 0.048890672 | 2.811149 | 0.055321960 | 2.484347 |

这里是独立CLI测量窗口，不与另一窗口的基线直接相除来估计优化收益。之前的四尺寸结果保留在 `../generic_opt_20260912/final_shapes_gpu2/`。

## 最终改动

- 主循环16次矩阵预取移至MFMA7、9、…、37之后；相关MFMA pair拆成single，累加顺序和操作数保持一致。
- 每四次矩阵请求共用一个m0基址，MUBUF immediate为0/1056/2112/3168。删除原有LDS端32字节基址补偿，同时在缓存的VOFFSET中减去对应immediate；运行时K的标量offset保持非负。独立A/B坐标枚举与小K的实际GPU验证均通过。
- 主循环跨迭代保持priority 1，删除循环内部和边界的重复切换；scale-panel refill显式使用priority 0，发布后恢复1。倒数第二块保留原有流水线。
- grid X对应N tile，Y对应M tile，Z对应batch，去掉设备端tile坐标除法/取余；CLI和C ABI/Python两条launch路径同时更新。已有C字节数限制使BF16总WG不超过16383、FP32不超过8191，各维满足grid限制，没有增加shape限制。
- 主循环unroll8改为unroll4，静态原生MFMA从704条减至448条。每个运行时K128块仍执行64条MFMA。

上一轮的SFA-after2/SFB-after20预取、分组AGPR初始化、A0/M0-after30预读并在36后安装，以及BF16在20/36/52/64后发布四个128×128输出区域全部保留。四个区域属于同一个256×256输出tile；MFMA36处仍只允许独立C stores跨越LDS发布barrier。

资源为FP32普通VGPR244 + AGPR256，BF16普通VGPR256 + AGPR256，combined500/512；SGPR62，LDS152064B，零spill/scratch。全部MFMA为原生 `v_mfma_scale_f32_16x16x128_f8f6f4`，SrcC/DstC绑定相同的a0:a255片段，EXEC不变。

最终清理只改注释和空行，两种输出全部有效机器指令与实测父版一致，见 `cleanup_equivalence.json`。正式构建再次通过源码哈希和同一指令编码核对，见 `audits/production_top.json`。两条host launch对象确实重编，见 `production_build.log`；`selected/` 保存最终9份源码、配置、ISA、资源和选择依据。

## 验证与实验记录

选定父版在FP32/BF16上通过16组通用形状：K128、256、384、896、1152、3968、4096、4224、4352、8064、8192、8320、8448、16384、16512、32896，包含非方阵和batch2。完整8192²的67,108,864个输出精确匹配独立反量化参考，CLI seed1输入也与基线完全相等。证据为 `shape_validation/final_schedule_confirm_gpu2/` 和 `full_validation/final_schedule_confirm_gpu2/`。

`production_adapter_checks.log` 记录正式构建使用真实AITER shuffle的验证，覆盖两种E8M0 metadata布局、uint8承载预排B、`out=`、输出分配、非默认stream、输入重叠拒绝及完整8192输出。公共工具的独立重建、源码/ISA审查、完整参考与五轮同地址复现见 `reproduction_confirm_gpu2.log`、`full_validation/reproduction_confirm_gpu2/` 和 `shared_allocations/reproduction_confirm_gpu2/`。

`audit_guard_checks.json` 验证输出发布例外只允许C stores；取消声明、注入未退休矩阵到LDS输入或寄存器输入都被拒绝。反例只用于CPU审查，没有执行修改后的指令。`matrix_mapping_audit.json` 独立枚举A/B逻辑坐标、预排地址和LDS覆盖，包括小K下出现负中间VOFFSET的情况。

未采用的方向均保留可重建补丁：

- 提前release到MFMA4单独有小收益，与最终发射/优先级组合后更慢；release6/7也未胜出，保留5。
- 输出LDS基址共享与VALU分组有小幅独立变化，合入选定组合后没有继续增益。
- wave私有BF16输出的read64/xor变体正确且零spill，但只有约3.07～3.09P，保留工作组级合并输出。最初pitch132且假定16字节读取对齐的两版在GPU执行前排除，不能把它们列为通过版本。
- `out_packed_asm` 的不透明AGPR读取/转换helper在K128 BF16有20388/262144输出不符，没有测性能。`out_packed_asm_base` 仅完成FP32检查，尚未运行BF16即停止；它不是已证实BF16失败的版本。具体依赖问题未定位，最终代码未采用此helper。
- 编译器可见的输出fragment stream通过正确性，但没有可靠增益。B1-after60/62与A0/M1-after34的短距离预读未改善最终组合。
- unroll16比unroll4慢。全部候选和重复编码关系见 `candidate_index.json`、`duplicate_encodings.json`，避免按名称重复试验。

ATT仅用于定位指令间隙。诊断中基线主循环K128平均约2122.8 cycles，发射组合约2095.3，加入2D grid的另一次trace约2104.0；这些数字不替代整卡benchmark，也不代表最终unroll4的trace。命令与摘要在 `profiles_gpu2/`。

## 复现与清理

在kernel目录运行：

```bash
make -j3 all inspect
python3 tools/compare_versions.py --gpu 2 --rounds 5 --validate --tag my_compare
python3 tools/benchmark_shapes.py --gpu 2 --sizes 8192 1024 2048 4096 --rounds 5 --tag my_shapes
HIP_VISIBLE_DEVICES=2 OMP_TOOL=disabled OMP_NUM_THREADS=16 python3 test_blockscale_bpreshuffle.py --large
```

公共比较工具按PCI解析物理GPU，重建本轮冻结的 `9229d1a` 与顶层当前版本，检查9份源码哈希及两种输出的有效指令编码。结果目录名必须唯一；该流程不依赖原临时工作目录。测量metadata还记录两份修改过的host/launch源码哈希。

`make_candidates.py` 保存候选变换，`clean_selected.py` 保存最终清理；`patch_reconstruction.json` 逐一证明保存的补丁能从冻结基线精确还原全部9份源码，包括两份launch支持文件。手动恢复某一候选时，复制 `baseline_source/`，应用相应 `candidate_patches/*/change.patch` 再构建。

临时构建和原始ATT由 `archive_work.py` 逐文件校验归档，位置及清理范围见 `archive_manifest.json`。保留本轮基线、选定父版、最终清理版和正式构建审查目录；Git保留源码补丁、测量和诊断摘要。后续以顶层通用版本继续，具体入口见 `../../CONTINUATION_20260912_ISSUE35.md`。
