# regroll_release8 的 tile1 / tile2 / tile4 历史对照

本实验从提交 `f8040182670b270cd7cddb8ab062c0acd1d6c794` 的正式 `regroll_release8` 出发。本文及原始结果中的 `baseline` 均指当时的 **tile1**，其 `tmpl.hpp` SHA256 为 `1b1c87b28c1ae645cd8986e00aae0f870f089044c8a8eac4d761e396deafe53a`，源码冻结在 `../tile1_target32_20260911/baseline_source/`。后续正式tile1的变化见 [最新续记](../../CONTINUATION_20260911_TARGET32.md)。第二轮 `pair_b_early_a_merge` 未参与本实验。

**结论：直接持久化为tile2或tile4均未带来收益，tile2仍有与tile4相同的spill；正式版本保留tile1。** 两个候选均通过完整8192³独立参考及CLI输入检查。

## 同期性能

物理GPU2、PCI `0000:65:00.0`、HIP2，MI355X/gfx950。M=N=K=8192、batch1、warmup200、iterations100、CLI seed1；两种输出均计kernel-only。测前计算活动0%，显存驻留18%，允许空闲驻留阈值20%；未调整时钟或功耗配置。

三版本交替五轮，每轮反转顺序，以下为各自中位数：

| 模式 | 每WG完整256×256输出块 | 工作组数 | BF16 ms / P | FP32 ms / P |
| --- | ---: | ---: | ---: | ---: |
| regroll_release8 tile1 | 1 | 1024 | **0.356645737 / 3.082924** | **0.369552803 / 2.975249** |
| tile2 | 2 | 512 | 0.359897118 / 3.055072 | 0.371023293 / 2.963457 |
| tile4 | 4 | 256 | 0.357987289 / 3.071371 | 0.369794960 / 2.973301 |

相对此次tile1中位数，tile2吞吐变化为BF16 **−0.90%**、FP32 **−0.40%**；tile4为 **−0.37%**、**−0.07%**。原始30条日志均保存实际 `output_tiles_per_wg` 和grid，见 `measurements/current_tile1_tile2_tile4_gpu2/`。

同一组A/B/scales/C地址上还执行了五轮原生C++计时的“tile1—候选—tile1”配对比较。每个候选与其前后两次tile1平均耗时相比，吞吐变化中位数如下：

| 候选 | BF16配对变化 | FP32配对变化 |
| --- | ---: | ---: |
| tile2 | −0.7130% | −0.4689% |
| tile4 | −0.1996% | −0.0274% |

配对比较见 `shared_allocations/current_tile1_tile2_tile4_gpu2/`。测量关闭并发遥测，GPU绑定经PCI断言。tile2两个输出在五轮配对中均较慢；tile4的FP32接近持平。

最先单独比较tile1/tile4的一轮五次CLI结果也保留在 `measurements/current_tile1_vs_tile4_gpu2/`，当时BF16中位数为3.076619P与3.051944P。它与后续三版本比较使用同一份候选二进制。绝对耗时随测量窗口和分配地址波动，本文以同一窗口的比较为准。

## Tile 数实际改变的流程

tile数量始终以完整256×256输出块为单位。tile2/tile4在当前kernel外层增加按M方向连续处理输出块的循环：

```text
block_m_base = (wgid / num_tiles_n) * output_tiles_per_wg
block_n      = wgid % num_tiles_n
for output_tile in [0, output_tiles_per_wg):
    row = (block_m_base + output_tile) * 256
    if row >= M: break
    初始化a0:a255累加器
    执行本输出块的scale与矩阵prologue、完整K循环和写回
    vmcnt(0) + lgkmcnt(0) + barrier，完成LDS交接
```

因此输出块映射、grid、每WG执行的完整K循环次数及跨输出块同步都会改变。当前单输出块内部的MFMA顺序、寄存器滚动及MFMA8发布策略在源码层面保留；最终LLVM寄存器分配与指令排程仍会随外层循环改变。`tile2_vs_tile4_isa_diff.json` 记录了实际ISA差异，其中FP32还有LDS读取和尾段排程变化。

tile2/tile4仅为K8192实验。各自的CLI和C ABI接受 `tiles=0`（auto）或对应的2/4，并拒绝其他K；两套launcher均按对应数量减少grid。比较中的C ABI参数0选择每个独立库实际编译的模式。通用K源和ISA保持原样，但不由这两个实验入口调用。

## 资源和正确性

| 模式 | BF16 combined VGPR | FP32 combined VGPR | SGPR | BF16 scratch B/线程 | FP32 scratch B/线程 |
| --- | ---: | ---: | ---: | ---: | ---: |
| tile1 | 476 | 472 | 48 | 0 | 0 |
| tile2 | 512 | 512 | 106 | 44 | 48 |
| tile4 | 512 | 512 | 106 | 44 | 48 |

combined VGPR已包含固定的256个AGPR；各版本都是4个Wave64，LDS152064B。tile2/tile4的metadata分别报告BF16/FP32为10/11个VGPR spill，均有15个SGPR spill。减少持久化循环次数未降低本次编译的峰值资源占用。

- `full_validation/full_gpu2/`：tile4的两种输出各67,108,864个元素通过独立反量化FP32 GEMM参考（精确dyadic输入），并与已验证tile1的完整CLI seed1输出精确相等。
- `full_validation/tile2_full_gpu2/`：tile2通过相同全量检查。输出执行前填NaN，检查覆盖完整持久化循环的所有输出块。
- `tail_batch_validation/`：两候选、两输出均通过1280×256×8192、batch2 CPU参考检查，覆盖完整持久化组、剩余1块和batch偏移；使用显式 `--tiles 2/4`。
- `tile2_static_audit.json`、`tile4_static_audit.json`：source MFMA顺序、native tied dst=SrcC、a0:a255、无EXEC修改、LDS等待和普通VMEM发布检查通过。scratch与spill单独如实记录。
- `source_integrity.json`：正式tile1源码/二进制身份、两套候选补丁恢复后的文件哈希。

## 保存与复现

`candidate.json` 和 `tile2_candidate.json` 保存候选身份及源码哈希；`candidate_patches/` 根目录是tile4补丁，子目录 `tile2/` 是tile2补丁，两者均相对冻结的 `regroll_release8` tile1。原始二进制和构建中间文件的归档位置见 `archive_manifest.json`。

从项目目录执行以下命令，可由冻结源码和补丁恢复隔离目录，并核对候选哈希：

```python
from pathlib import Path
import hashlib, json, shutil, subprocess, tempfile

records = Path("results/persistent_tiles_20260911").resolve()
base = records.parent / "tile1_target32_20260911/baseline_source"
work = Path(tempfile.mkdtemp(prefix="mxfp8_restore_persistent_"))
shutil.copytree(base, work / "baseline")
for name, manifest in [("tile4", "candidate.json"), ("tile2", "tile2_candidate.json")]:
    target = work / name
    shutil.copytree(base, target)
    patches = records / "candidate_patches"
    if name == "tile2":
        patches /= "tile2"
    for patch in sorted(patches.glob("*.patch")):
        subprocess.run(["patch", "--batch", "-p1", "-i", str(patch)], cwd=target, check=True)
    for file, digest in json.loads((records / manifest).read_text())["candidate_source_sha256"].items():
        assert hashlib.sha256((target / file).read_bytes()).hexdigest() == digest, file
print(f"export MXFP8_WORK_DIR={work}")
```

在Python中运行上面的代码，再执行它打印的 `export` 命令。在生成的 `baseline/`、`tile2/`、`tile4/` 中分别执行 `make -j3 all inspect`，再在本目录的 `support/` 下执行 `make -j2`。构建使用正式版本记录的clang23 hard-pin工具链。`create_candidate.py` 和 `create_tile2.py` 保留当时的转换过程；它们要求顶层源码仍为旧基线，不能直接用于后续正式源码。

重新执行CLI同期比较（tag须使用新的名称）：

```bash
python3 results/persistent_tiles_20260911/run_experiment.py cli \
  baseline tile2 tile4 --gpu 2 --max-initial-vram-percent 20 \
  --rounds 5 --tag rerun_tile_modes_gpu2
```

`--gpu`为物理卡号，CLI驱动按PCI解析HIP索引并保存绑定。全量检查、尾块检查和同地址比较的入口分别为 `run_experiment.py verify`、`verify_tail_batches.py` 和 `run_experiment.py shared`；后两类驱动使用明确的HIP可见设备及预期PCI。尾块驱动仍读取 `work_path.txt`，重建后需在本地将该文件改为恢复目录。性能记录中的基线始终是冻结的 `regroll_release8` tile1。
