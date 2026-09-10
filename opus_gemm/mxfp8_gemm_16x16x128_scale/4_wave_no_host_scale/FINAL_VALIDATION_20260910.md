# 4-wave 最终验证 — 2026-09-10

最终选择：`prepared_scale_c11_after4_b_contig_common_vaddr_v1`。活动代码在本目录，入口见 [README](README.md)。**七候选补测、独立选择确认、最终源码重建、正确性、单 kernel 追踪及打包版完整 N24 均已完成。最终打包版为 0.451738954 ms / 2.433953543 PFlop/s（8192³、batch1）。** 中断批次单独保留，不参与选择、不拼接。

## 1. 实现合同与最终身份

- gfx950，4 个 Wave64 / 256 线程，每 WG 一个 256×256 输出 tile。
- `K=8192`，M/N 是正的 256 倍数，支持 batch；不是任意 K 的通用 kernel。
- A `[batch,M,K]`、B `[batch,N,K]` 是原始 FP8 E4M3，计算 `A·Bᵀ`，C 为 FP32。
- SFA/SFB 是原始 E8M0 row-major `[batch,M或N,K/32]`；不在 host 重排 scale 或 B。
- 一次 GEMM 一次 kernel dispatch，额外 global device workspace **0 字节**；五个 allocation 是 A/B/C/SFA/SFB 本身，不是五份 workspace。
- 转换在同一 kernel 的寄存器和 LDS 中进行。每 WG LDS 163840 B，scratch/spill 为 0。

| 项目 | SHA256 |
| --- | --- |
| 最终 `tmpl.hpp` | `06702267a0f0c32c1d8e1b9ff77f60e1264bf1d23b78c1e8b5ee09cdf371b624` |
| 最终 `build/kernel.exe` | `6c5a9b271f589b905a3e34469b6f6e284c32c9ac5f3a9989d77eb8752b12c9a9` |
| 已测候选 executable | `73be0566fd67d5be805ee9647436ec08ec0d40a0205f749aa108e1aa1295d745` |
| 两者相同的规范化 native ISA | `590bd0440b757862062a03a1c471c1e5f2d896a0c57f6555976e3017a4b937fa` |

最终 source/host/compiler/linked CO 的完整绑定见 [已验证构建的 manifest 快照](docs/provenance/final_common_packaged_build_manifest.json)；原候选的编译与重链接记录见 [source_lineage.json](docs/provenance/source_lineage.json)。不同源码路径导致 CO / executable 字节不同，但新建最终源码的 native 指令流与选中候选完全一致，并另做最终 executable 的 GPU 回归。仓库按要求不上传 `build*` 目录，本文的 executable/CO/ISA 路径描述原机器上的验证产物。

静态门禁：1920 条指令、384 条 scaled MFMA、176 普通 VGPR + 256 AGPR、77 SGPR、21 个 MFMA→4×DTLDS 窗口，分布 `[1,10,10]`。B LDS 图像检查覆盖 16384 B/half，地址抵消穷举 393216 例。Scale transpose、队列、prepare-after4、真实 wait/barrier 不变量均通过。

## 2. 已完成的正确性

| 完整批次 | 镜像数 | CPU 参考用例 | 全输出 hash 回归 | 结果 |
| --- | ---: | ---: | ---: | --- |
| [候选补测](results/correctness_complete_20260910/summary.json) | 9：reference + after4 + 7 候选 | 72 | 27 | 全部通过 |
| [最终重建复验](results/final_correctness_20260910/summary.json) | 3：reference + selected + final | 24 | 9 | 全部通过 |
| 合计 | — | **96** | **36** | 两批 quality 均 complete/valid |

每个镜像验证以下 8 个 CPU 参考用例（K 均为 8192）：unit scale 256×256/b1；random 256×512/b1；SFA-K pattern 512×256/b1；SFB-K pattern 256×512/b1；第二 seed random 512²/b1；random 256²/b3；SFA-row pattern 768×256/b2；SFB-row pattern 256×768/b2。CPU 用例也计算完整输出 hash，并检查所有输出有限。

每个镜像另外检查三项完整输出：

| 形状与 seed | FP32 输出 bit hash |
| --- | --- |
| 8192³ / batch1 / 20260909 | `d7317b3740f24b47` |
| 8192³ / batch1 / 20260910 | `712d4716c77aae2e` |
| 1024×512×8192 / batch3 / 20260909 | `ddb29e2ff28ae34f` |

输入生成器为 `splitmix64-index-v1`，与 OpenMP 线程数无关。大规模 hash 是对 reference 的 bitwise 回归，不冒充大规模 CPU 逐元素参考；小规模 CPU 测试使用 host 内记录的数值容差。

另有 [14 项 host 非法输入测试](results/final_host_contract_20260910/summary.json) 全部通过：错误 K、M/N 对齐、batch、迭代参数、verify、未知/缺失/畸形参数、非法 seed 和 hash/timeline 冲突均在 launch 前拒绝。

CPU-only 工具自测也已通过：11 种进程状态门禁输入、HIP/SMI PCI 映射、错误 LDS stride / 缺少 immediate 抵消 / 未审阅源码拒绝，以及最终 B source/ISA/manifest 绑定。保留日志在 [offline_validation_20260910](results/offline_validation_20260910/runner_selftest.log)。

## 3. 单 kernel / allocation 实测

[实际追踪 contract.json](results/single_kernel_trace_20260910/contract.json) 绑定最终 executable SHA256，记录：

- `kernel_dispatches=1`、`hip_launch_calls=1`。
- `explicit_hip_malloc_calls=5`，分别是 A、B、C、row-major SFA、row-major SFB。
- `extra_global_workspace_bytes=0`，LDS 163840 B，scratch 0。
- HIP visibility index7 → PCI `0000:98:00.0` → SMI index5，MI350X/gfx950、256 CU。

Profiler 时间不参与性能判断；其寄存器统计的解码口径与 linked metadata 不同，资源使用以 `kernel.notes` 与静态 gate 为准。

## 4. 七候选的完整 N24 筛选与独立确认

条件：8192³/batch1，w200/i100，默认 seed=20260909，OMP_TOOL=disabled、OMP_NUM_THREADS=32；同机全 GPU 无外部进程时进行。每轮旋转/反向交错，每 label 24 个样本。每个样本是 100 次 GEMM 的平均时间，再对 24 个样本取最小值。报告 P 按 `2*M*N*K/(ms*10^12)` 计算，不含 host 输入初始化或 H2D。

所有完整批次同时保留同一 executable 的 A/A 标签、全部原始日志、TSV、quality、脚本快照和进程检查。这里的 `gain` 定义为 `faster_baseline_min / candidate_min - 1`；不用 median，亦不混用旧 ABBA 或另一台机器的绝对时间。

### 初筛：9 labels × N24 = 216 样本

证据：[candidates_n24 summary](results/candidates_n24_20260910/summary.json)。A/A spread 为 0.2831%。

| 候选 | min ms | PFlop/s | gain vs 较快 after4 A/A | 结论 |
| --- | ---: | ---: | ---: | --- |
| after4 | 0.461238712 | 2.383823 | 0 | 基线 |
| after4 A/A | 0.462544322 | 2.377095 | −0.2823% | 噪声对照 |
| B0 split c01 8/9 | 0.474690855 | 2.316269 | −2.8339% | 不保留 |
| B0 split c01 12/13 | 0.477380306 | 2.303219 | −3.3813% | 不保留 |
| B0 pair-between | 0.463743091 | 2.370950 | −0.5400% | 不保留 |
| B0 pair-between-open | 0.467963815 | 2.349565 | −1.4371% | 不保留 |
| transpose-staged | 0.461979151 | 2.380003 | −0.1603% | 无超噪声收益 |
| **B contiguous common-vaddr** | **0.452895761** | **2.427737** | **+1.8421%** | 晋级 |
| B contiguous ioffset | 0.453406185 | 2.425004 | +1.7275% | 晋级 |

### 独立复验与两种 B contiguous 的选择

| 完整批次 | 比较基线的 min ms | common min ms / P | common gain | A/A spread |
| --- | ---: | ---: | ---: | ---: |
| [对 after4 确认](results/contig_confirm_n24_20260910/summary.json)，96 样本 | 0.462160945 | 0.452787220 / 2.428319 | +2.0702% | 0.1368% |
| [contig 直接比较](results/contig_headtohead_n24_20260910/summary.json)，72 样本 | 0.452667266 | 0.452135444 / 2.431819 | +0.1176% | 0.0678% |
| [contig 独立再确认](results/contig_headtohead_recheck2_n24_20260910/summary.json)，72 样本 | 0.453220189 | 0.452487707 / 2.429926 | +0.1619% | 0.0184% |

初筛和对 after4 的确认中，common 均为逐轮 24/24 胜，约 2% 收益明确。与 ioffset 的差距很小：两次 min-of-N 优势均超过同场 A/A spread，故按既定选择标准保留 common；逐轮只分别 12/24、16/24 胜，paired geomean 分别为 −0.1117%、−0.0982%，**不宣称 common 在均值或每轮都胜出**。

以上四个完整性能批次共 456 样本。选择后的 native kernel 性能约 **2.43 P**，不是 2.7 P。新约 2% 增益属于 B producer 的地址准备 / m0 / 调度变化，不属于删除 scale 转置；scale 路径仍使用 after4 的 prepare/publish 方案。

## 5. 最终打包版复验与中断记录

最终独立复验 [final_release_retry4_n24_20260910](results/final_release_retry4_n24_20260910/summary.json) 已完整通过：selected、相同 executable 的 selected A/A、final，三者各 N24，共 72 个样本；quality 为 complete/valid，最后一轮后进程门禁也通过。

| 镜像 | min ms | PFlop/s |
| --- | ---: | ---: |
| selected | 0.452264607 | 2.431125 |
| selected A/A | 0.452096850 | 2.432027 |
| **最终打包 final** | **0.451738954** | **2.433954** |

A/A spread=0.0371064%。Final 与 selected 的 native ISA 和 host.o 一致；final 在本次 min 指标上高 0.0792%，但只有 8/24 逐轮胜，paired geomean 为 −0.2497%。因此这里只确认最终打包没有丢失约 2.43 P 性能，**不把重新打包当作新的 kernel 优化，不宣称额外 0.0792% 的稳定收益**。五个完整正式性能批次合计 **528 个样本**，所有原始数据保留。

本次实际复验命令（历史 selected 路径在清理后进入可恢复归档）：

```bash
python3 -B 4_wave_no_host_scale/tools/run_suite.py bench --rounds 24 \
  --correctness 4_wave_no_host_scale/results/final_correctness_20260910 \
  --baseline selected --baseline-aa selected_aa \
  --out 4_wave_no_host_scale/results/final_release_retry4_n24_20260910 \
  selected=.4wave_closeout_20260910.GW0Avl/candidates/b_contig_common_vaddr_v1/kernel.exe \
  selected_aa=.4wave_closeout_20260910.GW0Avl/candidates/b_contig_common_vaddr_v1/kernel.exe \
  final=4_wave_no_host_scale/build/kernel.exe
```

该结果目录已存在，不能直接覆盖重跑；需用新 `--out`，如需历史 selected 必须先按清理报告恢复原件。

下列批次保留但不参与任何选择、不与完整批次拼接：

- `correctness_20260910`：72 项 CPU 与 25 项 full-hash 已通过后，旧 guard 将零 DRM-device 的退出进程误判为占用；没有数值失败。修正 guard 后整批重跑为 `correctness_complete_20260910`。
- `contig_headtohead_recheck_n24_20260910`：外部进程，0 样本；后来完整重跑为 `contig_headtohead_recheck2_n24_20260910`。
- `final_release_n24_20260910`：取得 14 个样本后检测到其他 GPU 作业，停止；整批不用。
- `final_release_retry_n24_20260910`：开始前检测到八张 GPU 上的外部作业，0 样本。
- `final_release_retry2_n24_20260910`：完成 21 轮 / 63 个样本后检测到外部 PID 1825077，未完成既定 N24，整批不用。
- `final_release_retry3_n24_20260910`：完成 5 轮 / 15 个样本后检测到外部 PID 1841067，整批不用。

## 6. 路径与清理后的可追溯性

历史 manifest 中的路径记录执行当时的位置，不改写旧记录。初筛时 `4_wave_no_host_scale/build/` 还是 after4；晋升 common 前已将那个 after4 build 保存在 `.4wave_closeout_20260910.GW0Avl/after4_baseline/build/`。请按 SHA256 和 [source_lineage.json](docs/provenance/source_lineage.json) 分辨，不能按当前同名路径内容误认基线。

最终目录保留一份实现、构建产物、必要验证工具和结果；历史候选及本次临时构建目录的可恢复范围见 [清理报告](docs/CLEANUP_20260910.md)。优化机制、历史结果归属、关闭方向见 [优化记录](docs/OPTIMIZATION_HISTORY_20260910.md)。
