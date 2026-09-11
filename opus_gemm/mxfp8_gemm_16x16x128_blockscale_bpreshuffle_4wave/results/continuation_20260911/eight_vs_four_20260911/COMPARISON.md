# 8-wave 与当前 4-wave 交替复测（2026-09-11）

MI355X/gfx950，HIP_VISIBLE_DEVICES=2，PCI 0000:65:00.0。M=N=K=8192，batch=1，warmup=200，iterations=100。计时只覆盖 GEMM。输入为 FP8 A/B 与 E8M0 scale；BF16/FP32 指输出类型。

每个版本各三轮，第二轮反转版本顺序；全部由同一进程依次启动。8-wave 使用其正式 4 output tiles/WG 配置，当前 4-wave 使用 1 output tile/WG。此表比较完整 kernel，不能独立归因于 wave 数或 scale 路径。

| 输出 | 8-wave 中位数 ms / PFLOP/s | 4-wave 中位数 ms / PFLOP/s | 吞吐提升 |
|---|---:|---:|---:|
| BF16 | 0.369600 / 2.974550 | 0.360194 / 3.052557 | +2.62% |
| FP32 | 0.377300 / 2.914160 | 0.373042 / 2.947423 | +1.14% |

4-wave BF16 三轮分别为 0.367799225、0.360031662、0.360193672 ms；首轮较慢，全部保留在中位数计算中。8-wave 程序的时间输出只有小数点后 4 位，PFLOP/s 使用程序输出的 TFlops/1000，以避免根据已舍入的 ms 重算。

## 与 gfx950 MXScale BMM 的区别

两者保持原始 A 1×128、B 128×128 的 E8M0 量化语义，一个 K128 scale 覆盖四个 K32 子组，不在 global memory 创建展开的 1×32 scale 张量。

- BMM 的 mma_scale_accum 对单个 A/B scale 调用 pack_e8m0x4，即 s * 0x01010101，打包为四个相同字节，MFMA scale op_sel 固定为 0。
- 当前 4-wave K8192 路径在序言预加载完整紧凑 scale 面板；A 经向量 global load、quad DPP 和 byte permute 打包为每个 M128 half 内的四个不同行 scale（行偏移 0/32/64/96），主循环 LDS dword 读、op_sel=M_REPEAT（0..3）。四个 K32 lane group 通过相同 LDS 地址复用同一个字节。B 使用 s * 0x01010101。
- BMM 源码也提供可选 PRELOAD_SFA_LDS / PRELOAD_SFB_LDS 整段预加载；其面板保留紧凑按行字节布局，读取和打包方式与当前 4-wave 不同。这里不主张 BMM dispatcher 总是选择该预加载变体。
- 当前 4-wave 的输入契约和 scale/op_sel 打包思路延续 8-wave bpreshuffle，矩阵流水线继承 C256 AGPR 的 4-wave 版本，未移植 BMM 的完整流水线。

源码依据：

- 当前 4-wave：tmpl.hpp:114（op_sel）、:495（A 面板打包）、:529（LDS dword 读）、:557（B 复制）。
- /tmp/aiter_mxscale_bmm_review_feba81fdde04/csrc/opus_gemm/include/gfx950/opus_bmm_pipeline_a8w8_mxscale_gfx950.cuh:17（mma_scale_accum）、:211（A 面板）、:245（B 面板）。
- /tmp/aiter_mxscale_bmm_review_feba81fdde04/csrc/opus_gemm/include/opus_gemm_utils.cuh:102（pack_e8m0x4）。

完整命令、可执行文件及源码 SHA256、原始逐轮数据见 records.json；汇总见 summary.json。benchmark.py 保存本次测试脚本。
