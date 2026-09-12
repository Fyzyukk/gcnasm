# 通用 4-wave / tile1 C++ 源码清理

本目录为历史记录，适用于无宏清理及阶段注释提交 `09734d65352d8ad46ab2902714158b0768f0b471`。当前生产源码后来恢复了scale的shape/dim/layout，生成GPU代码已变化，见 [新布局记录](../generic_scale_layouts_20260912/README.md)。下面的哈希与二进制等价证明只适用于本目录所记录的旧版本。

按用户要求，正式 `tmpl_generic.hpp` 不再使用自定义宏。算法、通用 K、两种输出类型和 GPU 指令保持原样；这次没有运行 GPU，也没有新增性能成绩。

## 最终代码

- 删除全部7个 `MXFP8_*` 宏及其 `#undef`，包括 MMA、输出、AGPR 声明与初始化宏。
- MMA 使用显式赋值与已有的 `mma_scale_one` 内联模板；64个累加片段直接声明固定 AGPR 位置。
- 输出集中为 `stage_output_row`、`store_output_quadrant`、`publish_output_quarter` 三个局部 C++ helper，分别负责 BF16 行暂存、FP32 直接写回、BF16 区域发布。
- `if constexpr` 从29处减少到7处：保留 BF16/FP32 的编译期选择，以及 C10 发布时允许独立 C00 全局写回继续进行的编译期规则。主流程仅保留最终矩阵退休和 B1 选择所需的3处类型判断。它们不产生运行时类型分支。
- 公共 C ABI、Python 接口、输出类型和构建依赖保持原样。`tools/compare_versions.py` 改为读取本次清理后的源码哈希，比较基线仍为其原有的9229d1a；它不是19个待测性能候选的筛选入口。

正式头文件 SHA256：`ed44bd448691f21182af5c988ccdbb91b6ed8a1d44f7ee6900e3b598233b42ef`。

随后仅增加 Prologue、Main loop、Epilogue 三行阶段标记；删除这三行后与已验证源码（SHA256：`ad3fc41bb598e1534d170efa3839f4a169fcbd8cb7323c9bcc3cbdbb03620261`）逐字节相同。已有编译验证记录保留原始哈希，本次注释更新未重新构建或运行 GPU。

本次清理基于 `f483077e0263bc8d39ad810ad4c1f03b93727702`，旧头文件 SHA256 为 `69ef190d32fc10127deee1d06286233ecdde498e543a2d6c07d02b11696955be`。九份生产源码中只有该头文件发生变化。

## 验证

隔离版本、正式目录重编译，以及从冻结源码和正式源码各自重新构建的结果均一致。比较覆盖完整可执行文件 device code object、完整设备元数据，以及实际共享库内嵌的完整 device fatbin，均逐字节相同。

| 输出 | 普通 VGPR | AGPR | SGPR | LDS 字节 | spill / scratch | 有效指令数 |
| --- | ---: | ---: | ---: | ---: | --- | ---: |
| BF16 | 256 | 256 | 62 | 152064 | 0 / 0 | 2761 |
| FP32 | 244 | 256 | 62 | 152064 | 0 / 0 | 2179 |

两种输出各有448条静态原生 MFMA，与原版相同。完整 device code object SHA256 为 `0c1581177fffdc40dc46826ee46bd6fade6db57d14d07af46da275534d0ed169`；device fatbin 为 `8559e60d074354726f59d79e4c01f24a6e4516b973edcb3ad4ff28a0ecdf7e3b`。

证据在 `selected/comparison.json`、`selected/device_identity.json`、`selected/production_identity.json`、`selected/static_audit.json`，独立干净构建记录为 `verification_20260912T092419.json`。公共比较工具使用的静态审查也通过了源码哈希、原生绑定 MFMA、EXEC、LDS/VMEM 等待检查。

在提交 `09734d65352d8ad46ab2902714158b0768f0b471` 的独立checkout中，可在不使用 GPU 的情况下重新构建并验证。此脚本会读取该checkout顶层源码并核对旧哈希，不能直接用来验证后续shape/dim版本：

```bash
python3 results/generic_source_cleanup_20260912/verify.py
```

BF16 3.286311P / FP32 3.076707P 仍是原内核在8192³的历史正式成绩。由于 GPU 执行代码完全相同，这次没有将源码整理写成性能提升。延迟优化轮的19个候选、冻结基线和已有跑分保持原始内容；GPU 正确性与性能验证仍未执行。未来提升后的正式代码继续保持无自定义宏。

## 过程记录

`probe_results.json` 保留8次 CPU 编译尝试的状态与哈希；只有最终版本进入正式代码。对累加器使用可写引用的 MMA pair helper 触发 hard-pin 后端错误；输出按值传参的版本改变了部分寄存器分配，因此没有采用。最终方案在调用方显式赋值，输出 helper 使用只读引用，完整代码对象恢复为与原版相同。

中间试验的源码、构建日志与补丁保留在 `work_path.txt` 指向的隔离目录。仓库只保留最终版本的验证证据、验证工具和简要尝试记录。
