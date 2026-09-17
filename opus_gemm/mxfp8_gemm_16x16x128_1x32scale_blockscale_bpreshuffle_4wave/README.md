# gfx950 4-wave MXFP8 blockscale GEMM

该目录是一个独立的命令行版本：

- 每个 workgroup 使用 4 个 Wave64。
- 每个 workgroup 计算一个 256×256 输出 tile。
- K tile 为 128。
- A/B 为 FP8，scale 使用紧凑 E8M0 blockscale。
- 支持 BF16 和 FP32 输出。

## 文件

- `gemm_a8w8_mxfp8_scale_common.h`：kernel traits 与公共参数结构。
- `gemm_a8w8_mxfp8_scale_kernel_template.hpp`：kernel 主体。
- `gemm_a8w8_mxfp8_scale_kernel.cc`：kernel 实例化入口。
- `gemm_a8w8_mxfp8_scale_host.cc`：命令行、输入生成、验证和性能测试。
- `Makefile`：构建、检查、验证和基准测试。
- `rebuild.sh`：清理、重新构建并运行默认测试。

## 构建

```bash
make -j3
```

或者：

```bash
./rebuild.sh
```

默认工具链为：

```text
/root/toolchains/rocm-llvm23-46fcb339-build
```

可以通过 `TOOLCHAIN`、`ROCM_PATH` 和 `OPUS_INCLUDE_DIR` 覆盖。

## 验证

```bash
make verify GPU=2
```

## 8192³ 性能测试

```bash
make benchmark GPU=2
```

## 查看 ISA

```bash
make inspect
```

生成文件位于 `build/device.isa` 和 `build/device.notes`。
