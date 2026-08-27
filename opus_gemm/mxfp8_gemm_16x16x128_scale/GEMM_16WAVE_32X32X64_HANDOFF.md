# MXFP8 GEMM：16-wave 与 32x32x64_scale 实验交接

更新时间：2026-08-27

工作目录：

```text
/root/workspace/gcnasm/opus_gemm/mxfp8_gemm_16x16x128_scale
```

本文是当前实验的唯一续跑入口。`MXFP8_GEMM_OPTIMIZATION_LOG.md` 记录了此前从
1.878 P 到约 2.30 P 的优化历史，但其中第 17 节的 16-wave 性能来自受干扰环境，
该结论已撤回。最新的 16-wave、persistent 和 `32x32x64_scale` 状态以本文为准。

本文“需要实测”列表对应的 gfx950 executable 已随实验分支提交，可在兼容的
MI355X/ROCm 7 环境直接运行。正式源码只保留干净的 8-wave rolling 路径；这些
executable 是临时结构候选的精确测试快照，不应被误认为正式发布产物。

## 1. 当前可信最好结果

正式验证过的最好版本：

```text
build_clean_rolling_20_12/gemm_a8w8_mxfp8_scale.exe
8192 x 8192 x 8192, batch=1
约 0.4784 ms / 2.2982 P
多轮中位数约 2.301 P
230 VGPR, 65 TotalSGPR, 139264 B LDS
0 scratch, 2 waves/SIMD
```

旧 persistent x4 曾观察到约 `2.304--2.308 P`，相对 rolling 的收益只有约
`0.1%--0.3%`，尚未在完全空闲环境下完成全部新候选的统一交错复测。因此当前应表述为：

```text
可信稳定最好：约 2.30 P
最高 persistent 观察值：约 2.308 P，但尚未正式胜出
```

16-wave 旧的 `1.78--2.08 P` 数据是在 GPU 被其他任务占用时得到的，不得用来淘汰
16-wave，也不能用于跨时段归一化。

## 2. 正式源码状态

当前三个正式源码已恢复为干净的 8-wave rolling 20/12 路径：

```text
d7aca598ed38e67d6de7781030d5fa20e51a8c236efd90cdd1b3471a4a840e7a
gemm_a8w8_mxfp8_scale_common.h

7b635d86d4898eb8657ba769ad0b4ce2ca71cacb026139ad564f999d3d584f3e
gemm_a8w8_mxfp8_scale_host.cc

fbc7ce951535246a848df4de2a40f695bd53d973de43a822fabb2d622d78e7c1
gemm_a8w8_mxfp8_scale_kernel_template.hpp
```

不要用 `git checkout` 或 `git reset` 恢复这些文件。已有未提交修改和构建产物属于用户。

## 3. 需要实测的 8-wave 候选

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

## 4. 需要实测的 16-wave 候选

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

## 5. 统一的 8192 GEMM 测试方法

必须在空闲的 MI355X 上测试。确认目标卡连续多次接近 0% activity，且没有其他计算任务。

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

## 6. 独立 32x32x64_scale probe

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

## 7. 32x32x64_scale GEMM 候选结构

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

## 8. 达到 3 P 的 go/no-go 门槛

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

## 9. 需要带回的结果

```text
1. 所有 GEMM 输出中的 Kernel Performance 行
2. throughput_32x32x64.log
3. route_32x32x64.log
4. 测试期间 rocm-smi 的利用率、sclk 和功耗
5. 机器 GPU 型号、CU 数和 ROCm 版本
```

拿到这些数据后，下一步直接决定：保留 8-wave、采用 16-wave，或开始独立实现
`32x32x64_scale` GEMM。
