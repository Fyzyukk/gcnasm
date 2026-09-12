# 专用与通用路径：两者均跑8192³

按用户最新要求，性能测试仅覆盖 **M=N=K=8192，batch=1**。两条路径都是4个Wave64、每WG一个完整256×256输出tile，内部FP32累加，分别测BF16和FP32输出。

GPU2（PCI `0000:65:00.0`）在计时前被其他任务占用，idle guard中止测试；`generic_8192_shared_gpu2.log`保留该失败记录，没有采用受干扰的GPU2性能值。实际比较在空闲的 **物理GPU6 / HIP6 / PCI `0000:e5:00.0`** 上顺序执行。

## 五轮CLI结果

每次warmup200、iterations100、seed1，仅计时GEMM kernel；五轮交替正反序，报告耗时中位数，不取最快一次。测量期间没有并发profiler或遥测。

| 路径 | BF16耗时 ms | BF16 P | FP32耗时 ms | FP32 P |
| --- | ---: | ---: | ---: | ---: |
| 当前专用 `tmpl.hpp` | 0.359153709 | **3.061396** | 0.376270790 | **2.922129** |
| 强制通用 `tmpl_generic.hpp` | 0.389636078 | **2.821894** | 0.402216148 | **2.733634** |

专用路径吞吐分别高 **8.487% / 6.895%**。原始命令、每轮耗时、源码及exe哈希、初始GPU状态在 `measurements/generic_8192_cli_gpu6/`；机器可读摘要为 `comparison.json`。

## 同一组地址的交叉检查

在单一进程中加载两个C ABI库，复用同一组A/B/scales/C地址。每种输出每轮顺序为“专用—通用—专用”，共五轮，使用原生C++ HIP-event计时，w200/i100。

| 路径 | BF16 P | FP32 P |
| --- | ---: | ---: |
| 专用 | 3.059062 | 2.890281 |
| 通用 | 2.808895 | 2.727388 |

这里专用每种输出有10个相邻参考值，通用有5个值；表中分别取各自中位耗时换算吞吐。逐对参考值和漂移在 `shared_allocations/generic_8192_shared_gpu6/bracketed_comparisons.json`。这组数据与CLI分别记录，没有混成一个中位数。

每条路径、每种输出的 **67,108,864** 个元素完全一致。另有8192³的独立反量化FP32参考和CLI seed1全量检查，见 `full_validation/generic_k8192_full_gpu2/`。用户缩小范围前已完成其他K的正确性检查，因此目录保留这些日志；其他K没有性能测量，后续计时只跑8192。

## 路径和版本

`tmpl.hpp` 的完整scale面板固定为64个K128分组，并显式处理K62/K63，**不能直接用于其他K**。正常 `kernel_dispatch.hpp` 在K8192选它，其他合法K走 `tmpl_generic.hpp`。通用路径自身可以处理8192。

为了在8192执行通用kernel，隔离的 `generic/` 副本只把host dispatch条件改为 `if (false)`；没有修改kernel源码。`specialized/` 是当前正式实现 `selected_32_clean`，与此前GPU2测得3.213975P的 `tail_a3_prefetch56` 二进制完全一致。`baseline` 软链接指向 `specialized`，供独立参考验证驱动复用；它不表示历史3.0666P或3.1596P基线。

- 专用源码SHA256：`bdfc2445113a3b404a1d194a5f2110ddbf998fdcd407ca0b786730e00fa1fa25`。
- 通用源码SHA256：`3681ebf7093140a3f1216b1c6faab22e6d726dbd15c4ec3167b931029f84f180`。
- `kernel_identity_audit.json`确认两个构建中的四个device kernel（两条路径×两种输出）指令逐条一致；改变的是host选择。
- `manifest.json`保存完整输入源码哈希及强制dispatch的完整文本。

GPU6的专用3.061396P与此前GPU2的3.213975P属于不同卡的独立记录；性能差距使用本次同卡对照计算。

## 重跑

`work_path.txt`指向保留的隔离构建；恢复归档时可用 `MXFP8_WORK_DIR`指定新目录。先确认目标物理卡的PCI地址及HIP索引，使用新的tag避免覆盖旧结果。下例仍然只测8192³：

```bash
env -u CUDA_VISIBLE_DEVICES -u ROCR_VISIBLE_DEVICES -u GPU_DEVICE_ORDINAL \
  HIP_VISIBLE_DEVICES=6 MXFP8_EXPECTED_PCI=0000:e5:00.0 \
  MXFP8_SHARED_ROUNDS=5 MXFP8_BRACKETED=1 MXFP8_NATIVE_TIMING=1 \
  MXFP8_TELEMETRY=0 MXFP8_MAX_INITIAL_VRAM_PERCENT=1 \
  python3 results/generic_k_survey_20260911/run.py \
  shared new_generic_8192_shared_gpu6 generic
python3 results/generic_k_survey_20260911/sweep.py \
  --gpu 6 --hip-index 6 --pci 0000:e5:00.0 --tag new_generic_8192_cli_gpu6
```

正常接口的dispatch没有改变。后续专用/通用的性能对照维持“两条路径均为8192³”的口径。
