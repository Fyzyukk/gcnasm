# 4-wave row-major 候选补测盘点 — 2026-09-10

这是补测前的只读审计记录，不是本轮 GPU 结果。审计过程中没有编译、没有运行 GPU，也没有修改历史候选。

收尾更新：下文六个待测候选及历史正候选均已重新构建，完成正确性和 N24 比较；最终选中 `b_contig_common_vaddr_v1`。本文件保留补测前审计原文，当前结果与打包状态以 [最终验证](../FINAL_VALIDATION_20260910.md) 和 [优化记录](OPTIMIZATION_HISTORY_20260910.md) 为准。

范围为当前 `prepared_scale_c11_after4` 合规主线的已有候选：gfx950、4 个 Wave64、256×256×128、K=8192、标准 A/B 与 row-major SFA/SFB、默认 clang23 调度选项、无 host scale 重排。旧 prepacked、额外编译器调度参数、错误映射、构建未完成的历史探针不作为“补测现有可执行候选”重新开发。

检查了 `variants/`、`.variants_quarantine_20260908/`、`recovery_sched_group_20260908/`、`RECOVERY_20260908.md`；同时搜索了总优化日志。`scale_*` 顶层目录共有 274 个，其中 after4 后代有 65 个目录（包含一个多配置 sweep 容器）。下文的最终待测范围是 after4 直接后代，不声称所有历史、非主线实验都经过了新的完整验证。

## 结论

应补测 6 个有不同 linked ISA、未找到候选专属完整正确性/性能证据的现成候选；另将历史已经胜出的纯源码 `b_contig_ioffset_v1` 纳入新一轮复核。以 after4 为参考，但最终保留版本由新的正确性与正式比较决定。

目录位于隔离区本身不是失败证据。特别是 `b_contig_ioffset_v1` 有候选专属 r4/r8 正结果，不能按隔离位置丢弃。

## 必须补测的 6 个目录

以下均为仓库根目录相对路径；各目录的 `build/four_wave_c_agpr_single_mfma_coexec_early_c_steady_b1_head_after4_tail8_v1.exe`、`build/kernel.co`、`build/kernel.isa`、`build/kernel.notes` 已确认存在。

```text
.variants_quarantine_20260908/scale_sfb_k16_carried_raw_coexec_dist22_sfa_k8_raw_k4_queue_exact_k64_wrap_prepared_scale_c11_after4_b0_split4_c01_89_v1/
.variants_quarantine_20260908/scale_sfb_k16_carried_raw_coexec_dist22_sfa_k8_raw_k4_queue_exact_k64_wrap_prepared_scale_c11_after4_b0_split4_c01_1213_v1/
.variants_quarantine_20260908/scale_sfb_k16_carried_raw_coexec_dist22_sfa_k8_raw_k4_queue_exact_k64_wrap_prepared_scale_c11_after4_b0_split4_c01_pair_between_v1/
.variants_quarantine_20260908/scale_sfb_k16_carried_raw_coexec_dist22_sfa_k8_raw_k4_queue_exact_k64_wrap_prepared_scale_c11_after4_b0_split4_c01_pair_between_open_v1/
.variants_quarantine_20260908/scale_sfb_k16_carried_raw_coexec_dist22_sfa_k8_raw_k4_queue_exact_k64_wrap_prepared_scale_c11_after4_transpose_staged_v1/
.variants_quarantine_20260908/scale_sfb_k16_carried_raw_coexec_dist22_sfa_k8_raw_k4_queue_exact_k64_wrap_prepared_scale_c11_after4_b_contig_common_vaddr_v1/
```

下表 ID 为以上长目录名的末尾部分。所有候选已有镜像均为 384 条 scaled MFMA、256 AGPR、163840 B LDS、零 VGPR/SGPR spill、零 private/scratch，且保留 21 个同 SRD 的 MFMA → 四次 DTLDS 窗口。它们仍必须通过当前源码重建/归属核对、数学与 ABI 审计及 GPU 正确性，才能计时。

| ID | 现有指令数 | 普通 VGPR / SGPR | 变化与未闭环原因 |
| --- | ---: | ---: | --- |
| `b0_split4_c01_89_v1` | 1934 | 172 / 83 | 将下一 tile 的 8 次 B0 LDS 读分到 c01_8、c01_9 后；单 MFMA N-repeat 正确为 0、1。只找到初次构建和旧 fingerprint gate 失败，无候选正确性/计时。 |
| `b0_split4_c01_1213_v1` | 1934 | 172 / 83 | 同上，位置为 c01_12、c01_13，N-repeat 正确为 0、1；未找到完整运行证据。 |
| `b0_split4_c01_pair_between_v1` | 1936 | 180 / 83 | B0 LDS 读 4+4 分列原 c01_6/c01_7 pair 两侧，原 pair 数学映射保持；未找到完整运行证据。 |
| `b0_split4_c01_pair_between_open_v1` | 1936 | 176 / 83 | 同上，开放相应编译调度 fence/group；未找到完整运行证据。 |
| `transpose_staged_v1` | 1934 | 180 / 83 | SFA 第一 shuffle stage → SFB 第一 stage → SFA 第二 stage → SFB 第二 stage；存在普通和 09-08 recovery 构建，无专属运行结果。 |
| `b_contig_common_vaddr_v1` | 1920 | 176 / 77 | B producer 的 DTLDS immediate 与源地址补偿，共用 vector address；未找到这个独立镜像的专属正确性/计时。 |

### 静态 fingerprint 失败不等于数学错误

前四项的 `gate_initial.log` 报错是复制父版 gate 后，仍要求父版的 `wait=76` 或 `instructions=1934`。它们改变调度，本来就可能改变这些计数；不能仅依据该 fingerprint mismatch 判为错误或性能失败。本次只读核对另外确认了 MFMA 源映射、资源和 21 个 DTLDS 窗口。完整安全审计与正确性验证仍是计时前置条件。

`transpose_staged_v1` 的普通及 recovery 构建规范化 ISA 一致，SHA256 为 `ceb637dcf1ab5d35399ae4034145e69257070e37e106761b95d6dada00522459`，与 after4 的 `f77e1b4bad73e582b4916a9c03b0cc7f161366420ee06f38cd85c28934f78bb6` 不同，不是 compiler no-op。

`b_contig_common_vaddr_v1` 的规范化 ISA SHA256 为 `590bd0440b757862062a03a1c471c1e5f2d896a0c57f6555976e3017a4b937fa`。sweep 内名为 `build_top_t2_o4_m0_common_vaddr` 的另一镜像 hash 是 `88103d2d66ee4eb0b9d2a333b67e1565c927aed40692471128762213e8b47f53`；后者的 -0.4979% 结果不能归给这个独立默认编译器版本。

## 历史正候选：必须进入最终复核

```text
.variants_quarantine_20260908/scale_sfb_k16_carried_raw_coexec_dist22_sfa_k8_raw_k4_queue_exact_k64_wrap_prepared_scale_c11_after4_b_contig_ioffset_v1/
```

该目录的 `host.cc`、`kern.cc`、`traits.hpp`、`build.sh` 与 after4 相同；只改变内核源码。Host 没有 B preshuffle 宏、没有 scale pack 调用，也没有 packed-scale global workspace。构建没有额外 pre-RA scheduler 参数。

现有镜像：1872 指令、384 MFMA、168 普通 VGPR + 256 AGPR、71 SGPR、163840 B LDS、21 个 DTLDS 窗口、零 spill/private/scratch。

候选专属历史证据（不是从父目录继承的结果）：

- `correctness_gpu7_b_contig_ioffset.log`：4/4 exact-K64 correctness PASS。
- `results_vs_after4_gpu7_w200_i100_r4.tsv` 及同名 summary：+2.4436%，4/4 胜。
- `results_vs_after4_gpu7_w200_i100_r8.tsv` 及同名 summary：+2.2658%，8/8 胜；after4 2.35330 PFlop/s，候选 2.40672 PFlop/s。

以上是历史 paired-ABBA 数据；不能混入本轮 N24/min-of-N 数据，也不能当作本轮性能承诺。清理前需新建来源明确的镜像，并重新做正确性及正式比较。

## 不应计时的 7 个错误映射探针

以下原始源码把 `MXFP8_MMA_PAIR(..., NPAIR=1, ...)` 错拆成两次 `MXFP8_MMA_ONE(..., NREP=1, ...)`，正确展开应为 N-repeat 2、3。虽然静态 MFMA 数量仍为 384，但数学映射错误。它们不是“缺一次 benchmark”的合格候选；本轮收尾不修成新版本。

```text
.variants_quarantine_20260908/scale_sfb_k16_carried_raw_coexec_dist22_sfa_k8_raw_k4_queue_exact_k64_wrap_prepared_scale_c11_after4_b0_split4_c01_1011_v1/
.variants_quarantine_20260908/scale_sfb_k16_carried_raw_coexec_dist22_sfa_k8_raw_k4_queue_exact_k64_wrap_prepared_scale_c11_after4_b0_split4_c01_1415_v1/
.variants_quarantine_20260908/scale_sfb_k16_carried_raw_coexec_dist22_sfa_k8_raw_k4_queue_exact_k64_wrap_prepared_scale_c11_after4_b0_split4_c01_group_nofull_v1/
.variants_quarantine_20260908/scale_sfb_k16_carried_raw_coexec_dist22_sfa_k8_raw_k4_queue_exact_k64_wrap_prepared_scale_c11_after4_b0_split4_c01_open_v1/
.variants_quarantine_20260908/scale_sfb_k16_carried_raw_coexec_dist22_sfa_k8_raw_k4_queue_exact_k64_wrap_prepared_scale_c11_after4_b0_split4_c01_pairbar_v1/
.variants_quarantine_20260908/scale_sfb_k16_carried_raw_coexec_dist22_sfa_k8_raw_k4_queue_exact_k64_wrap_prepared_scale_c11_after4_b0_split4_c01_single_nogroup_v1/
.variants_quarantine_20260908/scale_sfb_k16_carried_raw_coexec_dist22_sfa_k8_raw_k4_queue_exact_k64_wrap_prepared_scale_c11_after4_b0_split4_c01_single_v1/
```

证据是各自 `tmpl.hpp` 对正式 after4 的源码差异，不仅是过时 gate 的退出码。`RECOVERY_20260908.md` 的 midfull 修复记录也说明同类 NPAIR/NREP 错误；已修复的 midfull 后续正确性通过、r4 -1.9149%，不重复测试。

## 其他明确排除与已关闭结果

下表目录均在 `.variants_quarantine_20260908/`，长前缀为 `scale_sfb_k16_carried_raw_coexec_dist22_sfa_k8_raw_k4_queue_exact_k64_wrap_prepared_scale_c11_after4_`。

| 后缀 | 结论与证据 |
| --- | --- |
| `a_dtlds_salu8_v1` | `build_20260908.log`：严格窗口检查由 21 降至 13；是真正静态拒绝，不是等待计数指纹误拒绝。 |
| `b_dtlds_salu8_v1` | 同日志：窗口由 21 降至 11，静态拒绝。两者 README 的 pending 字样过时。 |
| `diagonal_mailbox_v1` | `correctness_diagonal_mailbox_gpu7.log`：random case 98196/131072 elements 错误，明确数值失败。 |
| `remote_pair_mailbox_prera_top_v1` | `build.sh` 增加 `-misched-prera-direction=topdown`，不符合本轮默认 clang23/source-only contract；普通 `remote_pair_mailbox_v1` 已 r8 -0.5821%、1/8 胜。 |
| `rawsfb_schedcut_v1` | 现有规范化 ISA hash 精确等于 after4 的 `f77e1b4b...`，compiler no-op；继承的 after4 TSV/README 不算新候选数据。 |
| `c11_trans1_v1` | `STATIC_AUDIT.txt`：0x400 是超越函数 TRANS 类，不匹配 v_perm/permlane；所需调度机制未实现，静态探针关闭。 |
| `early_publish_sfa_only_v1` | 专属 `results_vs_after4_8192_gpu7_w200_i100_r4.summary.txt`：-0.3909%、1/4 胜。 |
| `early_publish_sfb_only_v1` | 同格式专属结果：+0.1462%、2/4 胜。 |
| `early_publish_sfb_only_wait5_v1` | 同格式专属结果：-0.1158%、2/4 胜。 |
| `sfa_local_forward_branchless_v1` | 同格式专属结果：-1.4810%、0/4 胜。 |
| `sfb_local_forward_branchless_v1` | 同格式专属结果：-0.0186%、2/4 胜。 |
| `sfa_refill_with_sfb_v1` | 同格式专属结果：+0.0388%、2/4 胜。 |

上面六个 early-publication/local-forward/refill 目录的 README 或 STATIC_AUDIT 中仍有 “not run” 字样，但后来已经生成候选专属标签的完整 r4 结果。按实际结果归属判断，不能再次列为未测。

`RECOVERY_20260908.md` 中其余 completed scheduling 表，以及 recovery 三个 A1/B1 候选、next-B fence opening、c11 SyncID1+VALU1 的 r4/r8 关闭记录均有效；不因缺少 r8 而重跑已在 r4 明确淘汰的版本。旧非 after4 的 `...exact_k64_wrap_nextb_dsmfmavalu_open_v1` stub 也不新开发；同类 after4 改动已正确性通过并 r4 -0.7348%、0/4 胜。

## 归档注意

历史源码/结果在这里的相对路径用于定位补测前原件。清理移动它们时应在归档 manifest 中保留映射；本文件不授权永久删除。最终目录只保留已选定源码和必要构建/验证入口，历史失败候选与证据应可恢复归档。8-wave 和无关 tracked 修改不在本次范围。
