# 8-wave MXFP8 GEMM：代码与使用入口

**主代码就在本目录根部，不在 build 目录或 source_snapshot 里。**

仓库发布说明：本分支上传当前保留源码、构建脚本、文档和验证记录；所有 `build*` 目录、编译产物、旧实验及未晋级的 coldburst 候选目录仅保留在原机器，不上传。下文关于这些路径的说明是历史验证记录。新克隆后请先执行 `bash build_retained.sh`，不要直接运行文档中的历史 binary 路径。

| 文件 | 用途 |
| --- | --- |
| [gemm_a8w8_mxfp8_scale_kernel.hpp](gemm_a8w8_mxfp8_scale_kernel.hpp) | 主内核；GEMM入口约1127行，row-major scale gather约2027行，转置及LDS发布约2166行 |
| [host.cc](host.cc) | host启动、参数和测试程序；启动入口约973行 |
| [kernel.cc](kernel.cc) | row-major开关、编译包装与显式实例化 |
| [gemm_a8w8_mxfp8_scale_common.h](gemm_a8w8_mxfp8_scale_common.h) | 参数ABI、tile和8-wave/512-thread traits |
| [build_retained.sh](build_retained.sh) | 推荐构建入口，固定保留配置，关闭其他实验开关 |

每WG为512线程/8 waves，顺序计算两个256×256输出tile；单次fused GEMM launch，
输入SFA/SFB保持原始row-major格式，无host scale重排、无全局packed-scale workspace。

## 编译保留配置

在本目录执行：

```bash
bash build_retained.sh
```

输出到新的 `build_retained_rebuild/`，不覆盖冻结保留版。也可指定新输出目录：

```bash
bash build_retained.sh /path/to/new_build_directory
```

主要参数固定为T2 / exact4 / source1 / nohandoff，pair10 / prefetch1 / unroll4 /
double queue。其余实验开关也显式固定，避免继承shell中的旧调参变量。
**不要直接用原build.sh的默认配置**，其历史默认值是T1/source2/handoff1。

默认依赖：

- LLVM23：`/root/toolchains/rocm-llvm23-46fcb339-build`
- ROCm：`/opt/rocm`
- OPUS headers：`/root/workspace/aiter/csrc/include`

可通过`TOOLCHAIN`、`ROCM_PATH`、`OPUS_INCLUDE_DIR`指定这些外部路径。
这里的exact4固定scale stride等8192³测试参数，不能将该二进制当成任意stride的
generic版本使用。现有源码与保留版指令的一致性证据见 [repro/README.md](repro/README.md)；
不承诺重建后的完整ELF hash必然相同。

只查看配置、核对源码，不编译或运行GPU：

```bash
bash build_retained.sh --print-config
sha256sum -c repro/control/source.sha256
```

## 保留二进制和候选代码

当前推荐二进制：
[build_side_t2_exact4_nohandoff_noprio/kernel.exe](build_side_t2_exact4_nohandoff_noprio/kernel.exe)。
8192³本轮约2.60–2.61P，源码就是上表中的根目录四文件。保留镜像未改。

Coldburst的独立源码在
[prototype_scale_f4_qhalf_coldburst_20260910/gemm_a8w8_mxfp8_scale_kernel.hpp](prototype_scale_f4_qhalf_coldburst_20260910/gemm_a8w8_mxfp8_scale_kernel.hpp)；
该目录同时保留target/generic镜像和静态检查。
它的2.63125P峰值尚未跨会话确认，未取代推荐版。
`source_snapshot/`是修改前的alignall，不是当前coldburst实现。

正式比较工具在 [tools/bench_formal.py](tools/bench_formal.py)，generic正确性工具在
[tools/validate_scale_generic.py](tools/validate_scale_generic.py)。它们不会自动运行。
现有镜像旁的`kernel.s`和`kernel.notes`也要保留，benchmark会读取这些文件。

## 结果与历史

- [方案总览](8_WAVE_NO_HOST_SCALE_SUMMARY_20260910.md)：各家族结论、scale路径发现。
- [最终补测记录](FINAL_VALIDATION_20260910.md)：N24/A-A结果、正确性和不晋级依据。
- [results/](results/)：最终原始日志、hash与进程快照，已集中收纳。
- [清理与恢复说明](docs/CLEANUP_20260910.md)：已删除444个冗余顶层项，596MiB缩至约5.2MiB；
  完整旧树另有约45MiB压缩备份，旧候选、profile、checker依赖和交接材料可恢复。

本次只清理目录、补构建入口，没有修改内核源码、重编译或重新跑GPU。
