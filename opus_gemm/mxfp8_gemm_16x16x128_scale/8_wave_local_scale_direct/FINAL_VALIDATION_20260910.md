# 8-wave 无 host scale 重排：最终补测记录

2026-09-10。用户先要求暂停整理，随后明确要求“把没测的测试了，然后统一收尾”。
性能补测之后又按用户要求清理了目录；本文保留当时的结果，原始日志现在集中在results。
旧原型与完整checker链可恢复，详见[清理记录](docs/CLEANUP_20260910.md)。

本次仅收尾已有合格镜像，不构建新优化，不组合 postrelease/coldburst，也不运行
资源或代码生成已被拒绝的镜像。

**补测已完成，不再运行GPU。没有晋级的新版本，2.7P尚未达到。** 继续保留
`build_side_t2_exact4_nohandoff_noprio/kernel.exe`，本轮约2.60–2.61P，最后一场
完整N24的较快保留标签为0.4213221ms / 2.609670P。Coldburst最高观测为
0.4178667ms / 2.631250P，但该较高峰值没有跨会话复现，不能写成稳定性能。

恢复后共完成四次独立完整N24（288条正式观测）、一次四标签N3（12条），合计
**300条正式观测**；另有3组generic CPU-reference正确性测试。16次全量hash
检查全部通过。旧N3及两次中断记录未计入这300条，也没有拼接取样。

清单核对：scale清单共32个候选、53个实际target/generic executable路径，均有
归档；早期31个可运行候选也已完成验证。恢复时只有postrelease的target待确认，
以及coldburst的target/generic待完整准入及GPU验证。地址缓存提案与组合版没有
实现镜像，不属于“漏测”。

## Postrelease：完整 N24 与独立复核均已结束，未晋级

保持冻结target SHA256
`f0e7f129033f3c5a94e81a4357a52e12d8a1510093e940b63be3f343d6d03e83`。
两次新会话均为GPU7、8192³、batch1、seed20260909、w200/i100、双基线标签与
候选交错运行，各24轮、72条正式观测。每次均重新通过三个标签的完整输出hash
`bb8d97357b61bd71`，26份进程快照包含最终after-run检查；未观察到GPU7其他进程。

| 会话 | 保留A / P | 保留B / P | Postrelease / P | 对较快保留版吞吐差 | A/A最小时间差 | 胜过同轮较快保留版 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 完整N24 |2.597760|2.605510|2.602870|−0.101324%|0.298334%|12/24|
| 独立N24 |2.590360|2.596780|2.601880|+0.196397%|0.247842%|15/24|

Postrelease最小时间分别为0.4224228ms、0.4225835ms。第一场较快保留版为
0.4219948ms / 2.605510P。对照均来自同场，未拼接中断记录或不同会话样本。
两场差值变号，且绝对幅度都小于各自A/A差；N3的+0.3784%未形成可确认优势。
此实现已完成复核，继续保留原版，不再作为待测项。

原始证据：

- [完整N24](results/results_scale_f4_qhalf_postrelease_finalize24_20260910/summary.json)。
- [独立N24](results/results_scale_f4_qhalf_postrelease_final_recheck24_20260910/summary.json)。
- [较早N3](results/results_scale_f4_qhalf_postrelease_screen3_20260910/summary.json)。
- [用户中断的旧重测记录](results/results_scale_f4_qhalf_postrelease_confirm24_retry1_20260910/STOPPED_BY_USER.md)，仍不用于选优。

注意：原始summary中的`min_time_gain_pct`按第一个基线标签算吞吐比，并非自动
选取两个基线中较快者。本表重新按较快基线计算；A/A为较慢最小时间/较快最小时间−1。
Generic仍有一个scalar spill，未执行，不能因target正确而称generic已验证。

## Coldburst：完整准入和GPU补测已结束，保留候选、不晋级

两图均保持254 VGPR（rounded256）/106 SGPR/159744B LDS，零所有spill、scratch
和AGPR。没有重编译、改写ISA或放宽原固定门槛。原33-test CPU模型之后补齐：

- Source binding：4 tests / 12 no-hash negatives PASS。
- Native地址/events：6 tests / 每图28 no-hash negatives PASS。
- 完整sync/raw/EXEC/transpose/machine gate：每图38 native + 4 machine negatives、
  13 event negatives全部拒绝。Root也独立复跑最终绑定版本通过。

证据：[source/native地址审核](docs/reviews/F4_QHALF_COLDBURST_REVIEW.md)、
[完整同步审核](docs/reviews/F4_QHALF_COLDBURST_NATIVE_SYNC_REVIEW.md)。
原来`EVENT_SHA=None`的阶段已结束；最终绑定为
`e429070d9dfc3e95e0c783256f028a9852a7aec7e35cc61d1af2a1624af1590c`。

### GPU正确性

Target的8192³ full random-scale hash为`bb8d97357b61bd71`，与保留版一致。
Generic的随机、SFA-K/SFB-row、SFA-row/SFB-K尾部三组CPU-reference用例全部通过，
形状分别为`(256,256,512,1)`、`(768,512,1024,1)`、`(2304,256,1536,2)`。
所有运行验证block512，generic准入例外列表为空，没有借用旧scalar-spill豁免。
[正确性记录](results/results_scale_f4_qhalf_coldburst_generic_20260910/correctness.json)。

### N3及两次独立N24

N3对照包含retained A/B、Q-half alignall和coldburst。Coldburst2.606360P，较快
retained2.592470P，差+0.535782%；但A/A差达1.474479%，不能由此晋级。
本表仅记录后续两场完整N24，仍按各自同场较快retained比较：

| 会话 | 保留A / P | 保留B / P | Coldburst / P | 对较快保留版吞吐差 | A/A最小时间差 | 胜过同轮较快保留版 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 完整N24 |2.605560|2.597950|2.610810|+0.201492%|0.292923%|13/24|
| 独立N24 |2.609670|2.598230|2.631250|+0.826924%|0.440300%|13/24|

Coldburst最小时间分别为0.4211381ms、0.4178667ms。每场各24轮/72条观测、
三个标签的完整hash通过，26份进程快照均包括最终after-run检查，保存的快照
未观察到其他GPU7进程。两个保留标签使用同一冻结二进制。

第一场收益小于A/A；第二场收益确实大于A/A，不能把它写成“都在噪声以内”。
但第二场2.631250P只出现于第9轮的一条正式观测，其他23条最高2.604960P；
第一场最高2.610810P。**保留2.631250P这个min-of-N结果，不剔除该样本，也
不凭它断言平台无效**；只是跨会话确认仍不足，不能将其当作稳定可交付收益。
每条正式观测都是100次launch平均，并非单次launch峰值。

因此本实现已完成本次规定补测，但仍为`validated_not_promoted`。Coldburst
是可保留的正向线索，不是已确认赢家。本次到此收尾，不继续追加会话、组合或新方案。

原始证据：

- [N3筛选](results/results_scale_f4_qhalf_coldburst_screen3_20260910/summary.json)。
- [完整N24](results/results_scale_f4_qhalf_coldburst_confirm24_20260910/summary.json)。
- [独立N24](results/results_scale_f4_qhalf_coldburst_recheck24_20260910/summary.json)。

## 最终交付边界

清理前Scale清单32个候选为23个已验证未晋级、7个资源拒绝、2个codegen拒绝；没有
合格但遗漏未测的镜像。被拒绝镜像未运行。原始源码、二进制、失败产物、基线及
所有旧记录均在压缩归档中保留；活动目录另保留当前源码、镜像和最终证据。

当前推荐版仍是冻结retained，SHA256：

```text
69e9a10aedfea1170e545d273bad99198396bfe2d44b2cef929186677cc72921
```

当前约束仍为8-wave/512 threads、一次fused GEMM launch、原始row-major scale、
无host重排、无global packed-scale workspace。本次未修改PC sampling开关，
未创建producer-base-cache或postrelease+coldburst组合版。后续寻优需用户另行要求。
