# 通用 4-wave / tile1 scale 的 shape/dim/layout

按用户要求，正式 `tmpl_generic.hpp` 的六组 scale 寻址恢复为和 `ga/sa/ra` 相同的结构：各自定义 `*_block_shape`、`*_block_dim`，再通过 `unfold_x_stride`、`unfold_p_coord` 构造 `make_layout`。全局读取、LDS写入、首轮寄存器读取和下一K预取都实际使用这些layout。

源码版本为 `generic_tile1_shape_dim_20260912`，父提交为 `09734d65352d8ad46ab2902714158b0768f0b471`。九份生产源码中只有头文件变化，其SHA256为 `62d2f0f3b25bf89c70d55756348fff214937211a95ce669b0a3f12d512ecb513`。编译期映射、链接ISA检查和正式重建均通过，**GPU运行正确性与性能未测试**。

用户最后要求整理保存后暂停优化。本轮完成commit/push后停在这一版，以下GPU命令保留给后续恢复，不自动执行。

## 六组layout

`p_dim` 表示线程或当前K位置选择的坐标，`y_dim` 表示该线程读写的数据维度。`Ktiles = K/128` 在运行时决定；`Vec` 为4或8字节。

| 定义 | block shape | 实际用途 |
| --- | --- | --- |
| `make_layout_gsfa_scale` | `[Ktiles, 2 M128 half, 4 M repeat, 2 wave-M, 16 rows]` | 紧凑SFA全局向量读取，物理stride为`[stride_sfa, 1]` |
| `make_layout_ssfa_scale` | `[64 K slots, 2 wave-M, 16 rows, 2 M128 half, 4 bytes]` | quad DPP打包后，向最终LDS布局写入四个M repeat的scale字节 |
| `make_layout_rsfa_scale<T, Vec>` | `[64 K slots, 2 wave-M, 16 rows, Vec bytes]` | 从LDS读取一个或两个M128 half；row stride保持8字节 |
| `make_layout_gsfb_scale` | `[Ktiles, 1 byte]` | 紧凑SFB全局读取；N128 half仍由load的scalar offset选择 |
| `make_layout_ssfb_scale` | `[64 K slots, 2 N128 half, 4 bytes]` | 将一个E8M0字节复制四次后写入LDS |
| `make_layout_rsfb_scale<T, Vec>` | `[64 K slots, Vec bytes]` | 从LDS读取一个或两个N128 half，K slot stride为8字节 |

调用处的 `u_gsfa/u_ssfa/u_rsfa` 与 `u_gsfb/u_ssfb/u_rsfb` 分别传给对应load/store。Vec8预取保留单一的8字节`y_dim`，符合Opus的向量轴要求。四个K32 lane group共享K128 scale，MFMA的`op_sel`继续选择四个M repeat字节。

64个K128的scale面板、quad DPP打包、预取位置、边界补齐及运行时K控制保持原流程。4个Wave64，每工作组一个完整256×256输出块；BF16和FP32均保留。没有自定义宏，仍有7处`if constexpr`。三个阶段标记保留：主循环每次处理K128，完整unroll4组为K512；Epilogue从倒数第二个K128块开始，完成余下计算和输出。

## 已完成的CPU验证

- `layout_check.cc` 直接调用当前头文件的实际layout函数，在编译期检查SFA全局→quad transpose→LDS→MFMA和SFB全局→字节复制→LDS→MFMA的对应关系、完整且唯一的LDS写入覆盖、Vec4/Vec8一致性和对齐。覆盖所有wave/lane组，以及K tile数1、2、3、63、64、65、127、128、129、257；SFA stride为768。记录为 `layout_mapping.json` 与 `layout_check.log`。
- 隔离候选和正式目录均通过 `make -j3 all inspect`。两种输出通过原生绑定MFMA、256 AGPR、EXEC、LDS/VMEM等待依赖检查，详见 `selected/static_audit.json`。
- 正式可执行文件的完整device code object、共享库实际嵌入的完整GPU fatbin、完整device metadata均与本次选定候选逐字节相同，详见 `selected/production_identity.json` 和 `production_build.log`。

| 输出 | 普通VGPR | AGPR | SGPR | LDS字节 | spill / scratch | 有效指令数 |
| --- | ---: | ---: | ---: | ---: | --- | ---: |
| FP32 | 244 | 256 | 62 | 152064 | 0 / 0 | 2177 |
| BF16 | 252 | 256 | 62 | 152064 | 0 / 0 | 2759 |

两种输出各有448条静态原生MFMA。device code object SHA256为 `3e8939186cf34434b178037c4c02724fbfb38627455192983c99d27b9ec0970c`；设备元数据SHA256为 `c444f5af7cce5949cc55e236cc83ffb9706a436b03050e1f6293d2d09a7e131f`。完整九份源码哈希及本次期望指令编码在 `selected/candidate.json`。

这次地址代码和寄存器分配发生变化：旧版BF16普通VGPR为256，FP32/BF16有效指令为2179/2761。**不能宣称与旧版二进制相同，也不能由寄存器减少推断性能提升。** 静态审查工具的历史字段`measured_generic_instructions_identical`只比较metadata中的期望编码；保存的报告已明确改名为`expected_generic_instructions_match`并记录字段映射，参考对象是本次未跑GPU的候选。

从kernel目录可单独重跑编译期映射检查，不启动GPU：

```bash
scale_check_work=$(mktemp -d /tmp/mxfp8_scale_layout_check_XXXXXX)
/root/toolchains/rocm-llvm23-46fcb339-build/bin/clang++ \
  -x hip results/generic_scale_layouts_20260912/layout_check.cc \
  -I. -I/root/workspace/aiter/csrc/include -std=c++17 -O3 \
  --offload-arch=gfx950 --offload-device-only --rocm-path=/opt/rocm \
  -D__HIPCC_RTC__ -fconstexpr-steps=200000000 \
  -c -o "$scale_check_work/layout_check.o"
```

现有Opus tuple deduction guide会触发clang的deprecated-attributes警告，构建和断言均通过，原始日志已保留。

## 待空闲GPU验证

11:16:26 UTC只读查询物理GPU2 / PCI `0000:65:00.0`，利用率100%、显存占用80%，见 `gpu2_availability.json`。本次没有启动GPU kernel。历史BF16 **3.286311P** / FP32 **3.076707P**属于f483077，不是当前shape/dim版的成绩。

本次整理的GPU复测独立于19个冻结性能候选，详见 `gpu_revalidation.json`。准备好的工作区见 `work_path.txt`：`shape_dim_layouts/`为当前生产源码与对应构建，`baseline/`为09734d6源码与构建，后者GPU代码已核对与f483077逐字节相同。原有19个候选、f483077基线、五批命令和历史成绩均未改写。

GPU2空闲后，从kernel目录执行以下命令，做22组通用正确性、完整8192独立参考和五轮8192同地址夹测；两种输出均测，warmup200、iterations100、native HIP event，计时中不采telemetry。`screen.py`会在每个GPU阶段前后检查占用与固定PCI，发现占用即停止后续阶段。该命令尚未执行：

```bash
MXFP8_WORK_DIR=/tmp/mxfp8_scale_layouts_20260912_srbvhgm7 \
MXFP8_AUDIT_OUTPUT_DIR=/tmp/mxfp8_scale_layouts_20260912_srbvhgm7/gpu_retest_audits \
python3 results/generic_latency_20260912/screen.py shape_dim_layouts \
  --tag shape_dim_layouts_gpu2 --gpu 2 --rounds 5
```

若临时目录丢失，在新的隔离目录中分别恢复09734d6的九份源码及当前九份源码，使用历史无宏清理metadata与本目录metadata核对哈希，再各自 `make -j3 all inspect`。不要对当前头文件运行旧的 `generic_source_cleanup_20260912/verify.py`；它只适用于对应历史checkout。
