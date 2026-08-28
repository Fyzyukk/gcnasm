# MXFP8 GEMM：16-wave 与 32x32x64_scale 实验交接

更新时间：2026-08-27

工作目录：

```text
/root/workspace/gcnasm/opus_gemm/mxfp8_gemm_16x16x128_scale
```

本文是当前实验的唯一续跑入口。`MXFP8_GEMM_OPTIMIZATION_LOG.md` 记录了此前从
1.878 P 到 rolling 20/12、persistent 和 16-wave 的完整优化历史。原“需要实测”
列表已于 2026-08-27 在空闲 MI350X 上完成统一复测。

收敛清理后只保留两个 gfx950 构建：`build_clean_rolling_20_12` 基线，以及当前最快的
`build_persistent_fixed_b_prefetch_4`。其他 build 目录均已删除，名称、资源和实测
结果仅作为历史记录保留在本文。fixed-B prefetch x4 已另存为独立源码和 Makefile
target，不再依赖临时构建快照恢复源码。

## 1. 当前可信最好结果

统一测试条件：空闲 MI350X（HIP 7 / card5）、`M=N=K=8192`、`batch=1`、
`verify=0`；每个候选执行 3 组 `REF-CAND-CAND-REF`，以下为中位数。

| build | 时间 | 性能 | 状态 |
|---|---:|---:|---|
| `build_clean_rolling_20_12` | 0.4194 ms | 2.6211 P | 保留的基线 |
| `build_persistent_fixed_a_basic_4` | 0.4627 ms | 2.3760 P | 已删除构建 |
| `build_persistent_fixed_a_prefetch_4` | 0.4580 ms | 2.4007 P | 已删除构建 |
| `build_persistent_fixed_b_basic_4` | 0.4167 ms | 2.6387 P | 已删除构建 |
| `build_persistent_fixed_b_prefetch_4` | 0.4151 ms | 2.6489 P | 保留的最佳构建 |
| `build_persistent_2x2_prefetch_4` | 0.4292 ms | 2.5621 P | 已删除构建 |
| `build_16wave_tn4_single_ab_u2` | 0.4587 ms | 2.3971 P | 已删除构建 |
| `build_16wave_tm8_tn2_u2` | 0.5335 ms | 2.0618 P | 已删除构建 |
| `build_16wave_tn4_persistent_2x2_basic_4` | 0.4822 ms | 2.2804 P | 已删除构建 |

`fixed_b_prefetch_4` 最终 10 次直接复测中位数为 `0.4144 ms / 2.6528 P`，最快单次
为 `0.4138 ms / 2.6571 P`；完整 `8192^3, -v 1` 报告 `ALL BATCHES VALID`。
对应静态资源为 242 VGPR、96 SGPR、139264 B LDS、0 scratch、2 waves/SIMD。

**最终性能口径：当前 kernel 按统一的 200 warmup + 100 timing benchmark，以正常
MI350X 上的 2.6528 P 中位数（约 2.65 P）为准。下述 MI355X 的约 2.30 P 来自已知
异常/降额节点 `smci355-ccs-aus-n12-25.cs-aus.dcgpu`，只保留作机器诊断数据，不得
用于判断 kernel 上限或代表正常 MI355X。**

```text
保留基线：build_clean_rolling_20_12
当前最快：build_persistent_fixed_b_prefetch_4
```

同一 fixed-B kernel 在上述异常 MI355X 节点上约 2.30 P，而正常 MI350X 上为
2.6528 P；该
差异来自异常节点的运行状态，不能解释为 MI350X 架构上快于正常 MI355X，也不能
拿该节点的绝对性能判断候选上限。

同日重新从独立 fixed-B prefetch x4 源码编译，并在当前空闲 MI355X 上做 3 组平衡
顺序复测（各版本 6 个无监控样本）：

| 目标卡 | rolling 基线 | 保存的 persistent | 源码重编 persistent |
|---|---:|---:|---:|
| HIP 7 / card5 | 0.4830 ms / 2.2764 P | 0.47835 ms / 2.2987 P | 0.4778 ms / 2.3013 P |
| HIP 4 / card7 | 0.49045 ms / 2.2418 P | 0.4864 ms / 2.2606 P | 0.4864 ms / 2.2606 P |

重编版与保存版在两张卡上均处于测量噪声内；gfx950 ISA 去除 HIP CUID 后逐字节
一致。当前 MI355X 没有达到 2.6 P，进一步确认跨机器绝对性能差异来自运行状态，
而不是源码恢复错误。

随后又原样测试了 MI350 侧提供的另一份 fixed-B 源码组织：把固定 B、layout 和
stage 提到输出循环外，并在最终 K tile 的 20/12 分界处预取下一输出。该版本编译为
236 VGPR、92 TotalSGPR、0 scratch；HIP 7/card5 上中位数为
`0.47875 ms / 2.2967 P`，没有超过保存版的 `0.4781 ms / 2.2998 P`。

持续 5000 次 kernel 的负载采样显示：8 个 XCD 全部 100% busy，热点温度 60°C，
但 gfx clock 仅约 1.48--1.64 GHz，socket power 约 1351 W，并出现
`PPT_VIOLATION_STATUS=ACTIVE`（PPT activity 47%）。因此当前约 2.30 P 的直接原因
是 MI355X 在功耗管理下维持了较低的有效时钟，不是代码、grid、CU 数或热限频问题。

MI350X 后续补充数据把“编译器”和“boost”两个因素分开了：clang 22 未展开版本
短测为 2.543 P，clang 23 历史最优二进制短测为 2.628 P，编译器差异约 0.085 P；
但 clang 22 同一版本延长到 1000 warmup + 1000 次计时后只有 2.245 P，短测到稳态
下降约 11.7%。按相同比例估算，clang 23 的 2.628 P 稳态约为 2.32 P，与当前
MI355X 的 2.29--2.30 P 接近。MI350X 短测时 FCLK 可处于 1500 MHz，持续负载后
降至 1250 MHz；当前 MI355X 的 FCLK 档位固定为 1250 MHz，并在短测试窗口内已经
触发 PPT。严格的跨机器比较还缺少“同一个 clang 23 二进制在 MI350X 上的长测”。

fixed-B host 现支持 `--timeline` 零预热诊断。MI355X 上两次时间线均显示：第 1--25
发受升频延迟影响，第 26--50 发短暂达到约 2.49--2.50 P，第 51--100 发降至约
2.34--2.36 P，第 101 发以后稳定在约 2.29--2.30 P。因此原来的 200 次 warmup 会
完全越过短暂峰值；同时确认该异常节点即使取消 warmup 仍未观测到 2.6 P。该曲线
用于说明此节点的异常 DPM/PPT 行为，不代表 MI355X 产品的正常性能。

## 2. 正式源码状态

rolling host 与 kernel template 保持为干净的 8-wave rolling 20/12 路径；common
header 只追加了独立 32x32 traits，没有改变原 16x16 traits：

```text
0f8fbd8a08069c2dddb1869b6b43715d981f9b70737cf3510b2351a7def21a39
gemm_a8w8_mxfp8_scale_common.h

7b635d86d4898eb8657ba769ad0b4ce2ca71cacb026139ad564f999d3d584f3e
gemm_a8w8_mxfp8_scale_host.cc

fbc7ce951535246a848df4de2a40f695bd53d973de43a822fabb2d622d78e7c1
gemm_a8w8_mxfp8_scale_kernel_template.hpp
```

另新增一套互不覆盖基线的 fixed-B prefetch x4 源码：

```text
gemm_a8w8_mxfp8_scale_kernel_template_fixed_b_prefetch_4.hpp
gemm_a8w8_mxfp8_scale_kernel_fixed_b_prefetch_4.cc
gemm_a8w8_mxfp8_scale_host_fixed_b_prefetch_4.cc
make BUILD=build_fixed_b_prefetch_4 scale_fixed_b_prefetch_4 -j4
```

专用 host 使用 `ceil_div(num_tiles_m, 4) * num_tiles_n`；8192³ 时 grid.x 为 256，
基线仍为 1024。不要用 `git checkout` 或 `git reset` 恢复这些文件。

## 3. 已完成实测的 8-wave 候选（历史记录）

本节列出的候选已完成统一复测。除 `build_clean_rolling_20_12` 和
`build_persistent_fixed_b_prefetch_4` 外，构建目录均已删除；结果见第 1 节。

统一基线：

```text
build_clean_rolling_20_12
```

主要 persistent 对照：

```text
build_persistent_fixed_a_basic_4
build_persistent_fixed_a_prefetch_4
build_persistent_fixed_b_basic_4
build_persistent_fixed_b_prefetch_4
build_persistent_2x2_basic_4
build_persistent_2x2_prefetch_4
```

历史 persistent 对照：

```text
build_persistent_basic_4
build_persistent_prefetch_4
```

资源：basic 为 234 VGPR，prefetch 为 242 VGPR；全部 0 scratch、2 waves/SIMD、
139264 B LDS。

`build_clean_u4` 和 `build_repro_current_u4` 是约 2.24--2.25 P 的旧参考，只需各跑
一次确认机器状态，不需要参加全部复测。

## 4. 16-wave 候选（历史记录）

16-wave 构建目录已在最终收敛清理中删除，资源与实测结果保留如下。

以下四个候选有效且无 scratch：

| build | topology | VGPR | scratch | occupancy |
|---|---|---:|---:|---:|
| `build_16wave_tn4_single_ab_u1` | 4x4 rolling | 128 | 0 | 4 waves/SIMD |
| `build_16wave_tn4_single_ab_u2` | 4x4 rolling | 126 | 0 | 4 waves/SIMD |
| `build_16wave_tm8_tn2_u2` | 8x2 rolling | 126 | 0 | 4 waves/SIMD |
| `build_16wave_tn4_persistent_2x2_basic_4` | 4x4 persistent x4 | 124 | 0 | 4 waves/SIMD |

以下版本存在 scratch，不进入正式性能矩阵：

```text
build_16wave_tn4                         92 B/lane
build_16wave_tn4_nopin                  124 B/lane
build_16wave_tn4_reuse_b                 64 B/lane
build_16wave_tn4_single_ab               76 B/lane

build_16wave_tm8_tn2_persistent_2x2_basic_4             48 B/lane
build_16wave_tm8_tn2_persistent_2x2_basic_4_unroll      48 B/lane
build_16wave_tm8_tn2_persistent_fixed_b_basic_4         48 B/lane
build_16wave_tm8_tn2_persistent_fixed_b_basic_4_u1      20 B/lane
build_16wave_tm8_tn2_persistent_fixed_b_basic_4_u1_novb2 20 B/lane
```

## 5. 历史测试清单（已完成，不要按本节重跑）

本节保留 16-wave/persistent 收敛时的原始清单。其中多数 build 已删除，而且当时指定的
MI355X 后来确认是异常节点；当前测试协议和可运行命令以第 10 节为准。

所有 GEMM 只运行：

```text
M=N=K=8192, batch=1, verify=0
```

每个 executable 内部已经执行 200 次 warmup 和 100 次计时。

```bash
cd /root/workspace/gcnasm/opus_gemm/mxfp8_gemm_16x16x128_scale

GPU_ID=6
REF=build_clean_rolling_20_12
ARGS=(-m 8192 -n 8192 -k 8192 -b 1 -v 0)

CAND=build_16wave_tn4_single_ab_u2
for d in "$REF" "$CAND" "$CAND" "$REF"; do
    printf '\n===== %s =====\n' "$d"
    HIP_VISIBLE_DEVICES="$GPU_ID" \
        "./$d/gemm_a8w8_mxfp8_scale.exe" "${ARGS[@]}" \
        | tee -a gemm_8192_results.log
done
```

每个候选至少执行三组 `REF-CAND-CAND-REF`。接受条件：

- 配对时间收益至少约 0.2%；
- 大多数配对获胜；
- 测试期间频率和外部负载稳定；
- 最终胜者再运行一次完整 `8192^3, -v 1` 正确性验证。

优先顺序：

1. rolling 20/12 基线；
2. 三个 16-wave rolling；
3. 16-wave 4x4 persistent；
4. 六个 8-wave persistent；
5. 两个历史 persistent。

## 6. 历史 32x32x64_scale probe（已被完整 pipeline 取代）

源文件：

```text
probes/probe_scaled_mfma_32x32x64.cu
```

它已经确认生成真正的硬件 opcode：

```text
v_mfma_scale_f32_32x32x64_f8f6f4
```

没有混入 `16x16x128_scale`。吞吐实例的静态资源：

| chains | VGPR | scratch | 用途 |
|---:|---:|---:|---|
| 1 | 38 | 0 | 依赖延迟 |
| 2 | 51 | 0 | 两链交错 |
| 4 | 86 | 0 | 近似未来 16-wave 的 accumulator 数量 |
| 8 | 150 | 0 | 近似未来 8-wave 的 accumulator 数量 |

编译：

```bash
mkdir -p build_probe_scaled_mfma_32x32x64

/opt/rocm/bin/hipcc \
    probes/probe_scaled_mfma_32x32x64.cu \
    -I. \
    -I/root/workspace/yanze/aiter/csrc/include \
    -std=c++17 -O3 -Wall \
    --offload-arch=gfx950 \
    -ffast-math \
    -Rpass-analysis=kernel-resource-usage \
    -save-temps=obj \
    -o build_probe_scaled_mfma_32x32x64/probe_scaled_mfma_32x32x64.exe
```

先运行 scale routing：

```bash
HIP_VISIBLE_DEVICES=6 \
    ./build_probe_scaled_mfma_32x32x64/probe_scaled_mfma_32x32x64.exe route \
    | tee route_32x32x64.log
```

再运行吞吐：

```bash
HIP_VISIBLE_DEVICES=6 \
    ./build_probe_scaled_mfma_32x32x64/probe_scaled_mfma_32x32x64.exe \
    throughput 1024 512 2048 20 5 0 \
    | tee throughput_32x32x64.log
```

注意：当前 probe 重复使用一组 A/B，只能作为 opcode ceiling。若结果有希望，下一步要
增加 `2A x 4B + 8 accumulator` 的 full-topology probe，之后才能决定是否实现 GEMM。

## 7. 32x32x64_scale 历史候选结构（已实现，结果见第 12 节）

第一版保持：

```text
block tile: 256x256x128
LDS:        每次仍搬完整 K128
compute:    同一个 K128 内执行两个 K64 phase
barrier:    每个 K128 仍只使用一次，不拆成两个 K64 barrier
```

两个需要对照的拓扑：

| topology | 每 wave 输出 | accumulator | MFMA/wave/K128 | 目标 occupancy |
|---|---:|---:|---:|---:|
| 8-wave | 64x128 | 8 个 32x32 fragment，128 FP32/lane | 16 | 2 waves/SIMD |
| 16-wave | 64x64 | 4 个 fragment，64 FP32/lane | 8 | 4 waves/SIMD |

实现顺序：

1. 先做独立 8-wave 32x32 prototype，以复用当前 loader/LDS/barrier 并隔离 opcode 收益；
2. 再做 16-wave 版本，目标总 VGPR 不超过 128；
3. 根据 route probe 单独设计 host scale pack 和 `rsfa/rsfb`，不能直接套当前 16x16 layout；
4. rolling 明确胜出后才叠加 persistent，persistent 预计只是小于 1% 的尾部收益。

## 8. 历史 go/no-go 门槛（基于异常节点，已作废）

本节的 2.30 P 起点和 5.0/5.7/6.0 P 绝对 probe 门槛不再用于决策。正式预算必须从
健康 MI350X 的 2.6528 P 出发；更新后的预算和停止条件见第 11 节。

当前：

```text
2.30 P ~= 0.478 ms
3.00 P ~= 0.3665 ms
```

20/12 pipeline 的稳态 barrier 间隔约 2370 ticks，其中当前 16x16 MFMA 计算下限约
2048 ticks，其余约 322 ticks。若这部分开销不变，新的 MFMA 拓扑至少需要约 1.37 倍
计算吞吐。以现有 16x16 full-topology ceiling 约 4.15 P 计算，32x32 可比 ceiling 至少
需要约 5.7 P 才有现实机会达到 3 P。

判断标准：

```text
chains=4/8 < 5.0 P:  不进入完整 GEMM
5.0--5.7 P:          可能超过 2.30 P，但单靠该 opcode 很难到 3 P
> 5.7 P:             实现 8-wave/16-wave 两个 prototype
> 6.0 P 且 route 规则整齐: 当前最值得投入的 3 P 路线
```

## 9. 历史待办（已完成）

```text
1. 所有 GEMM 输出中的 Kernel Performance 行
2. throughput_32x32x64.log
3. route_32x32x64.log
4. 测试期间 rocm-smi 的利用率、sclk 和功耗
5. 机器 GPU 型号、CU 数和 ROCm 版本
```

拿到这些数据后，下一步直接决定：保留 8-wave、采用 16-wave，或开始独立实现
`32x32x64_scale` GEMM。

## 10. 当前统一测试协议

后续正式性能必须在健康 MI350X，或经 retained fixed-B 基线确认正常的 MI355X 上
测量。已知异常节点 `smci355-ccs-aus-n12-25.cs-aus.dcgpu` 只能做同机相对比较，
不能产生正式绝对性能结论。

```text
shape:       M=N=K=8192, batch=1
benchmark:   200 warmup + 100 timing
comparison:  每个候选至少 3 组 REF-CAND-CAND-REF
acceptance:  中位时间收益 >=0.2%，大多数配对获胜
target:      3 P 必须以中位数 <=0.366504 ms 验收
```

当前唯一有效的 16x16 reference 是 retained fixed-B winner：

```bash
REF=./build_persistent_fixed_b_prefetch_4/gemm_a8w8_mxfp8_scale.exe
ARGS=(-m 8192 -n 8192 -k 8192 -b 1 -v 0 -w 200 -i 100)
```

不要再把已删除的 16-wave 或 persistent build 放入待跑矩阵。每个新候选还必须满足：

- 0 scratch、0 spill，记录 VGPR/SGPR/LDS 和 code-object hash；
- 随机 E8M0 覆盖 K=128/256/384/512、batch=2；
- 覆盖 persistent 的 1/2/3/4-output group；
- 最终胜者再运行完整 `8192^3, -v 1`；
- 性能测试期间同时记录 GFX、FCLK、PPT，确认 HIP ordinal 对应的物理 BDF。

## 11. 16x16 到 3 P 的执行顺序

正式起点是健康 MI350X 上的 `0.4144 ms / 2.6528 P`。3 P 需要
`0.366504 ms`，即减少 47.896 us / 11.56%，吞吐提高 13.09%。rolling ATT 的
2370-tick K128 间隔与 2048-tick MFMA floor 表明，3 P 只允许约 23--48 ticks
非 MFMA 余量，需要消掉当前余量约 85%--93%。详细推导见优化日志第 27 节。

| 顺序 | 实验 | 现实收益/作用 | 保留条件 |
|---:|---|---|---|
| 0 | 健康卡上采 exact fixed-B ATT+PMC | 建立真实关键路径 | 必须匹配 242 VGPR、43 wait、7 barrier |
| 1 | final-K C-store 穿插后续 MFMA | 已完成，慢 0.27% | **NO-GO**，见第 16 节 |
| 2 | barrier 分界窄扫 | 已完成；存档数据中 20/12 最好 | **NO-GO**，不重复 |
| 3 | 8192 full-x4 显式展开 | 用户决定跳过 | 不实现 |
| 4 | 16x16 `T_M=2,T_N=4` 转置 wave-grid | 已完成，慢 1.51% | **NO-GO**，见第 14 节 |
| 5 | direct-to-VGPR | 用户确认历史实测性能差 | **NO-GO**，不重复 |

显式 x4 路径不做；分界窄扫、2x4 wave-grid、direct-to-VGPR 和 final-K/C-store
都已实测淘汰。健康卡 exact ATT 现在只有诊断价值，不再对应一个未完成的
低风险代码候选。现有证据不支持靠局部调度把 2.65 P 推到 3 P。

现有 `trace_persistent_prefetch_4_8192` 不是 retained fixed-B 的 trace：旧 trace 为
248 VGPR/45 waitcnt，winner 为 242 VGPR/43 waitcnt。因此不得依据旧 trace 直接移动
winner 的 wait/barrier。

## 12. 已完成的 8-wave 32x32x64 pipeline

独立源码：

```text
gemm_a8w8_mxfp8_scale_kernel_template_32x32x64_fixed_b_prefetch_4.hpp
gemm_a8w8_mxfp8_scale_kernel_32x32x64_fixed_b_prefetch_4.cc
gemm_a8w8_mxfp8_scale_host_32x32x64_fixed_b_prefetch_4.cc
```

构建与运行：

```bash
make BUILD=/tmp/mxfp8_32x32x64_pipeline -B -j4 scale_32x32x64

HIP_VISIBLE_DEVICES="$GPU_ID" \
  /tmp/mxfp8_32x32x64_pipeline/gemm_a8w8_mxfp8_scale_32x32x64_fixed_b_prefetch_4.exe \
  -m 8192 -n 8192 -k 8192 -b 1 -v 0 -w 200 -i 100
```

它复用了 16x16 winner 的 `256x256x128` workgroup tile、8 waves、双缓冲 LDS、每
K128 单 barrier、fixed-B x4、下一 output K0 prefetch 和 consumer-major scale。
差异是每个 K128 使用两个 K64 phase；每 wave 有 8 个 32x32 accumulator chain，
每个 chain 被两个 phase 更新。

默认 u4 编译结果：

```text
220 VGPR, 96 SGPR, 139264 B LDS
0 scratch / 0 spill, 2 waves/SIMD
96 条静态 v_mfma_scale_f32_32x32x64_f8f6f4
0 条 16x16x128 scaled MFMA
```

A/B/C 和 scale selector 已做完整静态枚举；随机 E8M0、K=128/256/384/512、batch=2、
scale row/K-group 定向模式以及 persistent tail 均为 `ALL BATCHES VALID`。

当前异常 MI355X 上三组 `REF-CAND-CAND-REF` 的最终结果：

| kernel | 6 个样本中位时间 | 中位性能 |
|---|---:|---:|
| 16x16 retained fixed-B | 0.4794 ms | 2.2934 P |
| 32x32 fixed-B u4 | 0.5692 ms | 1.9319 P |

32x32 的时间慢约 18.7%，吞吐低约 15.8%。同机比值仅 0.842；若机械外推到健康
MI350X 的 2.6528 P，大约是 2.23 P，但该数字不是健康机实测值。

| PMC 中位数 | 16x16 | 32x32 |
|---|---:|---:|
| MfmaUtil | 66.1% | 48.5% |
| LdsUtil | 27.9% | 38.3% |
| MeanOccupancyPerActiveCU | 1.99 | 1.97 |
| MemUnitStalled | 0.25% | 0.79% |

结论：把 MFMA 指令数从 192 减到 96 没有减少 162 条 `ds_read`、7 条 barrier、global
payload 或 occupancy；独立 accumulator chain 又从约 32 条/wave 降到 8 条/wave。
因此当前 8-wave 32x32 是一个已经闭环的负结果，不替换 16x16 winner，也不再做
普通 unroll/scheduler 小扫。

## 13. 16-wave 32x32 已完成，32x32 路线停止

为验证更高 occupancy 是否能挽救 32x32，又新增独立 rolling target：

```text
gemm_a8w8_mxfp8_scale_32x32x64_16wave_common.h
gemm_a8w8_mxfp8_scale_kernel_template_32x32x64_16wave_rolling.hpp
gemm_a8w8_mxfp8_scale_kernel_32x32x64_16wave_rolling.cc
gemm_a8w8_mxfp8_scale_host_32x32x64_16wave_rolling.cc
```

```bash
make BUILD=/tmp/mxfp8_32x32x64_16wave -j4 scale_32x32x64_16wave
```

资源目标全部达到：1024 threads / 16 waves、4x4 wave grid、117 VGPR、54 compiler
SGPR、139264 B LDS、0 scratch/spill、4 waves/SIMD。随机 E8M0 的 K=128/256/384/512、
batch=2、M/N 多 tile和所有 scale 定向模式均验证通过；ISA 只有 32x32x64 scaled MFMA。

但是三组 fixed-B reference 与 candidate 交叉复测为：

| kernel | 6 个样本中位时间 | 中位性能 |
|---|---:|---:|
| 16x16 retained fixed-B | 0.4791 ms | 2.2950 P |
| 32x32 16-wave rolling | 0.5911 ms | 1.8602 P |

16-wave 32x32 吞吐低约 18.9%，并且比 8-wave 32x32 的 1.9319 P 再低约 3.7%。
4 waves/SIMD 没有弥补每 wave 只剩 4 条独立 chain、LDS consumer read 增加约 33%、
以及 16-wave barrier 的成本；139264 B LDS 仍只允许一个 WG/CU。

因此不再给它叠加 fixed-B/persistent，也不再扫描 unroll。32x32 的 8-wave 与 16-wave
完整 pipeline 都已正确实现并实测失败，当前路线正式停止。分界扫描、
direct-to-VGPR 和 final-K/C-store 都不再重复。

## 14. 16x16 `T_M=2,T_N=4` go/no-go：已完成并淘汰

候选以独立文件存在，没有覆盖 rolling 基线或 retained fixed-B winner：

```text
gemm_a8w8_mxfp8_scale_tm2_tn4_common.h
gemm_a8w8_mxfp8_scale_kernel_template_tm2_tn4_fixed_b_prefetch_4.hpp
gemm_a8w8_mxfp8_scale_kernel_tm2_tn4_fixed_b_prefetch_4.cc
gemm_a8w8_mxfp8_scale_host_tm2_tn4_fixed_b_prefetch_4.cc
Makefile target: scale_tm2_tn4_fixed_b_prefetch_4
```

构建使用 `/tmp`，不在仓库内新增 build 目录：

```bash
make BUILD=/tmp/mxfp8_tm2_tn4_npair -B -j4 \
  scale_tm2_tn4_fixed_b_prefetch_4
```

它保持 `256x256x128` WG tile、512 threads / 8 waves、fixed-B persistent x4、K128
双缓冲和每 K128 一次 barrier，只把 wave-grid 从 `4x2` 转置为 `2x4`。因此
`E_M,E_N` 从 `2,4` 变为 `4,2`：B 每 half 的 LDS read 从 8 减到 4，A 则从
4 增到 8。SFA 每个 M half 使用一个 dword，SFB 把两个 N half 合并为一个
dword，用 `op_sel_b=2*half_n+n_repeat` 选择四个 byte，所以 SFB 每 wave/K128
只需一个 dword load。

当前保留的 N-pair 发射顺序与 winner 的 scheduler-group 形状一致。静态结果：

| 项目 | retained `T_M=4,T_N=2` | `T_M=2,T_N=4` |
|---|---:|---:|
| VGPR | 242 | 252 |
| next-free SGPR | 96 | 96 |
| compiler TotalSGPR | 101 | 95 |
| LDS | 139264 B | 139264 B |
| scratch/spill | 0 | 0 |
| occupancy | 2 waves/SIMD | 2 waves/SIMD |
| 16x16x128 scaled MFMA | 192 | 192 |
| `ds_read` | 162 | 156 |
| `buffer_load` | 68 | 67 |
| `s_waitcnt` | 43 | 28 |
| `s_barrier` | 7 | 7 |

正确性已覆盖 K=128/256/384/512、batch=2、N 多 tile、persistent 1/2/3/4 output、
一个完整 x4 group 加 tail group，以及 unit/random E8M0、SFA/SFB row/K-group 定向
pattern，全部为 `ALL BATCHES VALID`。因为性能已触发 NO-GO，没有再运行
完整 `8192^3 -v 1`。

在异常 MI355X 的后续稳定窗口中，GPU 7、`8192^3`、`w200/i100`，做了 5 组
`REF-CAND-CAND-REF`：

```text
reference 10 个样本中位数: 0.48885 ms / 2.249 P
candidate 10 个样本中位数: 0.49625 ms / 2.216 P
candidate 时间增加:            1.51%
candidate 吞吐下降:            1.49%
```

10/10 个 candidate 样本都慢于 reference 的最慢稳定样本。把同机相对比例机械外推到
健康 MI350X 的 2.6528 P，也只有约 `2.61 P`，低于至少 `2.6796 P` 的 `+1%`
保留门槛。另测的 M-pair 与 N-pair 发射顺序只相差约 0.16%，属于噪声，
说明重排 MFMA 配对无法挽救该拓扑。

最终结论是 **NO-GO**：转置确实减少 B 读和 B live range，但对称增加了 A 读和
10 VGPR；总 operand 字节、MFMA、barrier 与 occupancy 都没改变。它只把压力从 B
转移到 A，没有缩短真实关键路径，不再继续调度扫描，也不替换 retained winner。

## 15. 历史路线去重更正

分界扫描已在 rolling 阶段完成，不应因为 fixed-B 版本更名而重新当成新方案：

| 分界 | 历史性能 | 结论 |
|---|---:|---|
| 16/16 | 2.2769 P | barrier 过早 |
| 18/14 | 2.2992 P | 与 20/12 持平，交错复测略慢 |
| 20/12 | 约 2.301 P | 保留点 |
| 22/10 | 2.2776 P | B 隐藏窗口不足 |

`19/13` 和 `21/11` 也已实测无收益；当前工作树没有保留它们的独立原始
数字，因此只记录 NO-GO，不虚构精确性能。

已保留数据的早期 scale global-to-VGPR 路径仅为 `1.903--1.959 P`，而后续
consumer-major direct-to-LDS 为 `2.143--2.157 P`。用户进一步确认过 direct-to-VGPR
方向整体性能不好；当前工作树未保留 full-A/B direct 版本的独立原始数字。
两者必须区分，但执行结论相同：**不再重建或重测 direct-to-VGPR 路线**。

因此，现有 `16x16x128_scale` 路线不再重复上述实验。final-K/C-store overlap
也已按严格门槛完成并失败，见第 16 节。`2.6528 P` 是当前算法/编译器
组合的收敛点，而不再轮换已失败的微调参数。

## 16. final-K/C-store overlap go/no-go：已完成并淘汰

候选保持 next-output K0 prefetch 先于所有 C store，并保留原有 continuation
`vmcnt(0) + lgkmcnt(0) + s_barrier`。final-K 按 C00、C10、C01、C11 的完成
顺序，在后一个 bank 至少发射一对独立 MFMA 后，提前写回前一个已完成
bank。生成 ISA 中第一批 store 后仍有 22 条 scaled MFMA，说明编译器没有把
32 条 store 全部重新聚合到 epilogue。

独立源码和 target：

```text
gemm_a8w8_mxfp8_scale_kernel_template_fixed_b_prefetch_4_cstore_overlap.hpp
gemm_a8w8_mxfp8_scale_kernel_fixed_b_prefetch_4_cstore_overlap.cc
gemm_a8w8_mxfp8_scale_host_fixed_b_prefetch_4_cstore_overlap.cc
Makefile target: scale_fixed_b_prefetch_4_cstore_overlap
```

```bash
make BUILD=/tmp/mxfp8_cstore_overlap -B -j4 \
  scale_fixed_b_prefetch_4_cstore_overlap
```

候选与 reference 的资源和静态指令数完全相同：242 VGPR、compiler TotalSGPR 101、
139264 B LDS、0 scratch/spill、2 waves/SIMD、192 条 scaled MFMA、68 条 buffer load、
32 条 buffer store、43 条 waitcnt 和 7 条 barrier。

正确性覆盖 K=128/256/384/512、batch=2、N 多 tile、persistent 1/2/3/4 output、
`4+1` output tail，random/unit E8M0 及 SFA/SFB row/K-group pattern，全部为
`ALL BATCHES VALID`。

在同一异常 MI355X 上执行 GPU 7、`8192^3`、`w200/i100`、5 组
`REF-CAND-CAND-REF`：

```text
reference: 0.4811, 0.4808, 0.4811, 0.4796, 0.4809,
           0.4805, 0.4801, 0.4802, 0.4804, 0.4805 ms
candidate: 0.4819, 0.4826, 0.4817, 0.4810, 0.4816,
           0.4814, 0.4857, 0.4820, 0.4826, 0.4817 ms

reference median: 0.48050 ms / 2.2883 P
candidate median: 0.48180 ms / 2.2821 P
candidate time:   +0.2706%
candidate perf:   -0.2698%
```

5/5 个交叉 group 的 candidate 均值都慢于对应 reference 均值。候选不仅没有
达到 `+0.2%` 保留门槛，方向还是负的，因此正式 **NO-GO**。不再继续测
age-aware waitcnt 或更细的 store 插入位置，避免重新变成微调扫描。
