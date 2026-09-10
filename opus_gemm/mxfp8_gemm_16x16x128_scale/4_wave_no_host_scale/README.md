# 最终 4-wave：row-major scale、单 GEMM kernel、零额外 global workspace

当前选择 **prepared-scale c11-after4 + B contiguous common-vaddr**。本目录是指定的 4-wave 最终实现；旧实验与对照产物的收尾状态及可恢复位置见文末清理报告，不作为另一个最终版本。

## 合同

- gfx950，256 线程 / 4 个 Wave64，wave 拓扑 2×2。
- 每 WG 计算一个 256×256 输出 tile，使用 16×16×128 scaled MFMA。
- **仅 K=8192**；M/N 是正的 256 倍数，支持 batch。
- A 为 FP8 E4M3 `[batch,M,K]`，B 为 FP8 E4M3 `[batch,N,K]`，C 为 FP32 `[batch,M,N]`；计算 `A·Bᵀ`。
- SFA/SFB 是 E8M0 `[batch,M或N,K/32]`，每行沿 K 连续。Host 不重排 scale，也不重排 B。
- **每次 GEMM 只有一个 GPU kernel，额外 global device workspace 为 0 字节。** A、B、C、SFA、SFB 是输入/输出张量，不计为 scratch workspace；不是“总共只调用一次 hipMalloc”。
- Scale 转换使用 kernel 内的寄存器和 **160 KiB LDS/WG**，无全局 packed-scale 中间结果、无额外 pack kernel、无 split-K reduction。

单次实际 dispatch 与五个输入/输出 allocation 的追踪证据见 [contract.json](results/single_kernel_trace_20260910/contract.json)。Profiler 时间不用于性能结论。

## 代码入口

| 文件 | 内容 |
| --- | --- |
| [tmpl.hpp](tmpl.hpp) | 完整 GEMM、scale slab/queue/transpose/prepare/publish、B contiguous producer、MFMA 流水线 |
| [traits.hpp](traits.hpp) | 4-wave / tile / scale 向量宽度与 LDS 基础参数 |
| [gemm_a8w8_mxfp8_scale_common.h](gemm_a8w8_mxfp8_scale_common.h) | 本地自包含的 96 字节参数 ABI |
| [kern.cc](kern.cc) | Device 编译包装和显式实例化 |
| [host.cc](host.cc) | 原始输入、单 kernel launch、确定性数据、CPU 验证和计时 |
| [build.sh](build.sh) | 构建、提取 linked CO/ISA、静态门禁和哈希 manifest |
| [gate.py](gate.py) | Scale / MFMA / 同步不变量，以及冻结源码与 native ISA 门禁 |

类型和 kernel symbol 沿用了历史 `...tail8_v1` 名称，只是 ABI/符号兼容；不代表使用那个旧实验。最终身份由本目录源码及 [已验证构建的 manifest 快照](docs/provenance/final_common_packaged_build_manifest.json) 确定。

## 已采用的优化

1. SFA K8 / SFB K16 raw LDS slab：相邻 2/4 lane 合作搬运每行 32/64 字节 scale，沿 K 摊薄 global refill。
2. SFA K4 VGPR queue 与提前读取的 SFB dword：控制寄存器生命期，隐藏 LDS 读取。
3. Wave 内 4×4 byte transpose，随后每 lane 各一次 dword store 发布 SFA/SFB。
4. Prepare/publish 分离：当前 tile 的 c11 前 4 条 MFMA 后准备 `t+2` 的 scale，剩余 12 条 MFMA 与其重叠；下一循环头只发布。
5. C/D 固定 AGPR、A/B direct-to-LDS 双缓冲、B1 的 4+2+2 分段读取、SFA/B0 滚动寄存器和必要的 partial wait。
6. K=8192 的 modulo-64 future-producer wrap、最后 tile 的提前输出 store。
7. B producer 改为每 wave 连续四行 LDS，共用 m0 和 vector address；用 scalar offset 抵消 MUBUF immediate，保持原始 B 地址及消费者 LDS 图像。

完整推导、历史收益、失败方向、本次七候选收尾记录见 [优化记录](docs/OPTIMIZATION_HISTORY_20260910.md)。

## 构建和运行

需要带硬 AGPR pin 补丁的 clang23，不可替换成 stock clang 或 soft-pin。默认依赖：

```text
/root/toolchains/rocm-llvm23-46fcb339-build
/opt/rocm
/root/workspace/aiter/csrc/include
```

编译器来源及按顺序应用的两个补丁已保存在 [tools/compiler/](tools/compiler/CLANG23_AMDGPU_HARD_PIN.md)。这里的“自包含”指源码不再引用旧实验目录；ROCm、OPUS 和编译器仍是外部依赖。

在本目录执行：

```bash
# 从仓库新克隆后，首次构建生成 build/；构建产物不随仓库上传。
bash build.sh

# 原机器已存在 build/ 时，复建使用新目录名；脚本拒绝覆盖旧产物。
bash build.sh build_recheck

# 8192³、batch1，先确保实际 GPU 空闲。
HIP_VISIBLE_DEVICES=7 OMP_TOOL=disabled OMP_NUM_THREADS=32 \
  ./build/kernel.exe -m 8192 -n 8192 -k 8192 -b 1 -v 0 -w 200 -i 100

# 小规模 CPU 参考验证，只运行一次 GEMM，不进行计时。
HIP_VISIBLE_DEVICES=7 OMP_TOOL=disabled MXFP8_OUTPUT_HASH=1 \
  ./build/kernel.exe -m 256 -n 512 -k 8192 -b 1 -v 1

# 支持范围内的代表性形状验证；结果目录必须尚不存在。
python3 -B tools/run_suite.py correctness --extended \
  --out results/recheck_1 final=build/kernel.exe

# 完整 N24 与同一 executable 的 A/A；不需要恢复旧候选。
python3 -B tools/run_suite.py bench --rounds 24 \
  --correctness results/recheck_1 --baseline final --baseline-aa final_aa \
  --out results/bench_recheck_1 \
  final=build/kernel.exe final_aa=build/kernel.exe

# 无 GPU 的测试工具检查。
python3 -B tools/test_runner.py
```

Host 的固定输入生成器是 `splitmix64-index-v1`，默认 seed 为 `20260909`，由元素 index 决定，不依赖 OpenMP 线程数。`MXFP8_OUTPUT_HASH=1` 进行一次 GEMM 后 D2H 和 CPU 全输出哈希，跳过 benchmark。

8192³、batch1、默认 seed 的完整输出哈希为 **`d7317b3740f24b47`**；seed=20260910 为 `712d4716c77aae2e`。不要使用其他分支的固定 hash。

## 性能与证据

本次完整候选筛选与独立确认采用 w200/i100，每 label N=24，旋转/反向交错，**以 min-of-N 为选择依据**。每个样本是 100 次 GEMM 的平均时间，不是单条最快 dispatch。保留所有样本和中断批次，不用 median 替代 min，也不拼接中断样本。

- 对 after4：两次完整 N24 的最小时间收益为 +1.8421%、+2.0702%，同场 A/A spread 为 0.2831%、0.1368%。
- 对 B ioffset：两次独立 N24 的最小时间收益为 +0.1176%、+0.1619%，A/A spread 为 0.0678%、0.0184%。这是小的 min-of-N 优势，不代表所有轮次都更快；逐轮胜数为 12/24、16/24。
- 最终打包 `build/kernel.exe` 已独立完成 N24：**0.451738954 ms / 2.433954 PFlop/s**（8192³、batch1）。连同候选筛选，五个完整性能批次共 528 个样本；详见 [最终验证报告](FINAL_VALIDATION_20260910.md)。打包前后 native ISA 相同，不把这次小的测量差异算成新优化。

最终静态资源：**176 普通 VGPR + 256 AGPR、77 SGPR、160 KiB LDS、零 scratch/spill**；384 条静态 scaled MFMA，21 个 MFMA→4×DTLDS 窗口。Profiler 的 VGPR/SGPR 字段有不同解码口径，资源以 linked `kernel.notes` 和本目录 gate 为准。

实际测试设备为 HIP visibility index7 → PCI `0000:98:00.0` → SMI index5，MI350X/gfx950、256 CU；不是 SMI index7。Runner 先动态核对 PCI，再保存所有 GPU 的进程快照。

## 清理与恢复

只清理明确属于 4-wave 的未跟踪旧实验、对照与诊断；不修改 8-wave、混合/未知目录、Git 已跟踪文件或现有用户修改。精确范围和可恢复归档位置见 [清理报告](docs/CLEANUP_20260910.md)。

## 仓库发布范围

整个项目的当前源码、文档与验证记录保存在分支 `mxfp8-final-pipeline-source-20260910`。按用户要求，**所有 `build*` 目录、编译产物与旧实验/恢复归档不上传**；原机器上的文件不删除。本目录 `docs/provenance/` 保存构建 manifest 快照，但不包含 executable、CO 或 object。仅克隆仓库不能恢复旧归档内的候选或直接运行尚未构建的 executable。

历史报告中的 `build/` 文件和绝对路径描述当时的本地验证，不是仓库附带文件或新机器上的安装路径。重建与运行请使用上面的命令，并配置外部 ROCm、OPUS 和补丁编译器依赖。
