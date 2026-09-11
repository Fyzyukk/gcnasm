gfx950 4-wave blockscale bpreshuffle GEMM
=========================================

本目录从 `../mxfp8_gemm_16x16x128_scale/4_wave_no_host_scale` 的 4-wave 流水线移植，接收 AITER 标准预排 B 及紧凑 block scales。2026-09-11 第三轮选入 `regroll_release8`：A/B 共用预取指令位置、缓存地址、滚动预读全部矩阵操作数，并在第8条 MFMA 后交接 LDS stage。保留完整 K scale 面板和 BF16 vec8 写回。

GPU2（PCI `0000:65:00.0`）、8192³、b1/w200/i100、CLI seed=1，最终五轮交替中位数为 **BF16 0.357576294 ms / 3.074901P、FP32 0.369553413 ms / 2.975244P**。同轮第二轮基线为3.065668P和2.956384P，提升约0.30%和0.64%。BF16最快单轮约3.106P；正式数值取中位数。测前GPU计算活动为0%，另有18%显存驻留；同地址比较和GPU5对照另行记录。**3.5P目标尚未达到。** 最新流程、测量条件及清理记录见 [第三轮续记](CONTINUATION_20260911_ROUND3.md)。

输入和输出
----------

| 参数 | dtype / 物理布局 |
| --- | --- |
| A | E4M3FN FP8，连续 `[M,K]`，不重排 |
| B | 原权重 `[N,K]` 经 `aiter.ops.shuffle.shuffle_weight(B, layout=(16,16))`；形状仍为 `[N,K]`，字节已预排 |
| A_scale | E8M0，量化分组 **1×128**；物理连续 `[K/128,M]`，逻辑 `[M,K/128]` 的 stride 为 `(1,M)` |
| B_scale | E8M0，量化分组 **128×128**；连续 `[N/128,K/128]` |
| C | 连续 `[M,N]`，BF16（默认）或 FP32；内部 FP32 累加 |

E8M0 以 `uint8` 或 `torch.float8_e8m0fnu` 传递，B 可由 FP8 或 uint8 承载。适配器也接受 AITER quantizer 将已按列主序排列的 A_scale 字节套成 contiguous `[M,K/128]` 的 metadata view；它不将真正按行主序排列的 scale 转置。普通 FP32 scale 不符合此 MX 接口，不能直接 reinterpret 成 E8M0。

M、N 为正的 256 倍数，K 为正的 128 倍数。K=8192 自动选择完整 K scale 面板路径，其余 K 使用按 K128 tile 预取的通用路径。两条路径每次都只启动 **一个 GEMM kernel**，不做 host scale 重排、不调用 scale 转换 kernel、额外 device workspace 为 **0 字节**。Python 可以分配输出 `C`；使用 `out=` 时复用调用方输出。C ABI 与 CLI 支持连续 batch，Python 当前为二维输入。

Scale 加载流程
--------------

Blockscale 的输入契约及打包 scale / `op_sel` 方案来自此前的 8-wave bpreshuffle 移植；矩阵流水线继承原 4-wave、256 AGPR 实现。与 gfx950 MXScale BMM 相同的是“一个 K128 scale 用于四个 K32 子组”的语义；本实现没有照搬 BMM 的加载流水线。下面的完整 K 面板、寄存器直接打包与普通 LDS dword 读取是 4-wave 的后续优化。

K=8192 路径在 kernel 开头读取本输出 tile 所需的全部紧凑 scales：

1. A_scale：256 行 × 64 个 K128 分组，共 **16 KiB**。向量全局读取后，用 quad DPP 和 byte permute 在寄存器内打包，直接写入最终 LDS 布局。
2. 每个 A dword 的四个字节属于四个 M repeat：`s[r,q]、s[r+32,q]、s[r+64,q]、s[r+96,q]`。另一个 M128 half 使用另一组 dword。
3. B_scale：两个 N128 分组 × 64 个 K128 分组，共 **128 字节**输入。每个 E8M0 字节乘 `0x01010101`，成为四个相同字节，最终 LDS 面板为 512 字节，按 `[K,half]` 排列相邻两个 N128 half。
4. 发布面板后，主循环对 A 使用普通 LDS dword 读取、对 B 使用一次 b64 预取下一 K 的两个 half，不再做 scale 全局加载或 scale LDS 写入，也不使用 TR8。
5. 四个 K32 lane group 读取同一个 A scale dword；MFMA 的 `op_sel` 选择对应 M repeat 字节。B dword 的四个字节相同。这样在硬件内部实现 K128 scale 对四个 K32 子组的复用。

这里没有创建全局 `[M,K/32]` 或 `[N,K/32]` scale 张量，没有重新量化 A/B。K32 广播来自 kernel 内的 LDS 读取地址复用和寄存器打包。通用 K 路径也使用打包 dword 与 `op_sel`，只把完整 K 面板改为两个 K128 scale stage。

矩阵流水线
----------

每个工作组256线程，即4个Wave64，计算256×256输出tile，K tile为128。A/B通过异步global→LDS双缓冲，再进入VGPR；B producer接收标准 `(16,16)` 预排布局。累加结果固定在每线程256个AGPR。

K8192先加载完整scale面板和矩阵K0/K1，种入K0的A0/A1/B0/B1寄存器。wave0/1各负责一个A的M128 half，wave2/3各负责一个B的N128 half。资源描述符按wave选择一次，16个不可变地址提前缓存到VGPR；主循环的预取指令位置由四个wave共用。

第8条MFMA后，完整VMEM/LGKM等待与barrier发布t+1并释放t的LDS stage。随后在MFMA8、10、…、38后各发一次t+2预取。四个相邻LDS行利用MUBUF immediate共享m0基址；global和LDS两端的地址补偿一致。最后无消费者的A/B预取均回绕到有效的K0。

B0在MFMA38后读取t+1。BF16在MFMA48后整体滚入下一A0；FP32按M repeat在36、40、44、48后滚入。A1各M repeat在52、56、60、64的最后消费者之后读取下一tile；B1的两组N repeat分别在62、64之后滚入。这样下一轮的矩阵操作数已有寄存器预读，前半段可以集中发global预取，后半段完成LDS读取。MFMA顺序及scale字节选择保持一致。

BF16写回仍使用 `permlane16_swap` 合并为vec8，每wave32次16B store；FP32保持原写回。完整路径LDS为 **152064字节**，普通VGPR为FP32 **216** / BF16 **220**，另有固定 **256 AGPR**，SGPR **48**，零spill/scratch。metadata combined VGPR为472/476，已经包含AGPR。通用K路径的源代码和机器指令保持不变。

构建与运行
----------

需要带原 4-wave 两个 hard-pin 补丁的 clang23；普通 ROCm clang 不支持 `amdgpu_pin_agpr`，不能当作等价编译器。当前已在独立目录构建好：

```bash
make -j3 all inspect
HIP_VISIBLE_DEVICES=2 OMP_TOOL=disabled OMP_NUM_THREADS=16 \
  build/gemm_a8w8_blockscale_bpreshuffle.exe \
  -m 8192 -n 8192 -k 8192 -b 1 -w 200 -i 100 -v 0 --dtype bf16
HIP_VISIBLE_DEVICES=2 OMP_TOOL=disabled OMP_NUM_THREADS=16 \
  python3 test_blockscale_bpreshuffle.py --large
```

Makefile 默认 `TOOLCHAIN=/root/toolchains/rocm-llvm23-46fcb339-build`，`OPUS_INCLUDE_DIR=/root/workspace/aiter/csrc/include`，均可覆盖。编译器基线、补丁顺序和哈希保存在 `results/toolchain_manifest.json`；补丁原件仍在原 4-wave 目录的 `tools/compiler/`。

按物理卡号重建第二轮基线和当前版本，并进行同地址、相邻基线对照：

```bash
python3 tools/compare_versions.py --gpu 5 --rounds 5 --validate
```

此工具按PCI地址解析HIP索引，要求GPU计算活动不超过5%，默认也要求显存占用不超过1%。若显存只是空闲驻留，可显式设置 `--max-initial-vram-percent`；初始状态写入结果。构建和结果保存在隔离目录及 `results/continuation_20260911/round3/shared_allocations/`。原始trace和重复实验产物的归档索引见 [清理记录](results/ARCHIVE_20260911.md)。

Python 调用：

```python
from aiter.ops.shuffle import shuffle_weight
from blockscale_bpreshuffle import gemm_a8w8_blockscale_bpreshuffle

# A/B 已量化；sa_storage 是 [K//128,M] 连续 E8M0 字节。
packed_b = shuffle_weight(raw_b, layout=(16, 16))
sa = sa_storage.T
out = gemm_a8w8_blockscale_bpreshuffle(a, packed_b, sa, sb)
```

AITER 集成范围
--------------

本目录提供独立 C ABI/Python 适配器，已用真实 `shuffle_weight` 验证输入布局、当前 stream 与 `out=`。可以作为 AITER 的 gfx950/E8M0 `blockscale_bpreshuffle` 分派候选；本次未改动 AITER 主仓的正式分派和构建系统。FP32 blockscale 路径需要单独处理其数值语义，不会由此适配器自动调用 `fp8_legacy_to_mxfp8`。

主要代码：`tmpl.hpp` 为 K8192 优化 kernel，`tmpl_generic.hpp` 为通用 K kernel，`traits.hpp` 为 tile/资源配置；`gemm_a8w8_blockscale_bpreshuffle_launch.cc` 和 `blockscale_bpreshuffle.py` 为适配层。测试、测量和优化证据分别保存在 `test_blockscale_bpreshuffle.py`、`results/` 与 `OPTIMIZATION_LOG.md`。
