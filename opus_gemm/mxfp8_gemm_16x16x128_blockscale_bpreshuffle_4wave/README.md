gfx950 4-wave blockscale bpreshuffle GEMM
=========================================

本目录提供 gfx950 的 4-wave MXFP8 blockscale GEMM，接收 AITER 标准预排 B 和紧凑 E8M0 scales。最新 K8192 实现已放入 **`tmpl.hpp`**：分散 A0/B0 寄存器读取，在第4条 MFMA 后交接 LDS，主循环展开8次，单独处理 K62 以去掉末尾无用预取，并调整 C11 的末尾读取次序。

**执行模式为 4wave + tile1。** 本项目的 tile 数量指每个工作组处理的完整 **256×256 输出块数量**：tile1 每WG独立处理1块；tile2/tile4 为每WG连续处理2/4块的持久化方案。当前 `traits.hpp` 的 `OUTPUT_TILES_PER_WG=1`，接口 `tiles=0`（auto）也选择1，CLI、Python与C ABI均只接受0/1。K方向另有2-stage LDS双缓冲。

GPU2（PCI `0000:65:00.0`），8192³、batch1、warmup200、iterations100、CLI seed1，五轮交替中位数：**BF16 0.347990036 ms / 3.159607P，FP32 0.364447136 ms / 3.016930P**。同期冻结基线 `regroll_release8` 为3.066602P / 2.969736P，吞吐分别提升 **3.03% / 1.59%**。短期3.2P尚未达到，BF16还需减少约4.393µs。版本、资源、验证和测量口径见 [本轮续记](CONTINUATION_20260911_TARGET32.md) 和 [实验记录](results/tile1_target32_20260911/README.md)。

此前约3.08P对应 `regroll_release8` 的 tile1；其源码现冻结在 `results/tile1_target32_20260911/baseline_source/`。该版本的 [tile1 / tile2 / tile4 同期对照](results/persistent_tiles_20260911/README.md) 已完成，GPU2五轮CLI的BF16分别为3.082924P / 3.055072P / 3.071371P。tile2与tile4出现spill，后续按用户要求回到tile1优化。第三轮历史结果见 [第三轮续记](CONTINUATION_20260911_ROUND3.md)。

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

第4条MFMA后，完整VMEM/LGKM等待与barrier发布t+1并释放t的LDS stage。主循环仍在MFMA8、10、…、38后各发一次t+2预取；四个相邻LDS行利用MUBUF immediate共享m0基址，global和LDS两端的地址补偿一致。主循环处理K0..K61，单独的K62段只发布并滚入K63，不再发无消费者的全局矩阵请求；最后由直接写回段处理K63。

两种输出的A0均按M repeat在MFMA36、40、44、48后读取t+1；B0在32、34、36、38后分四对读取。C11前8条维持按行次序，后8条在M repeat 2/3间交替，使B1四个N repeat分别在58、60、62、64后读取，A1四个M repeat在52、56、63、64后读取。只调整同一K块内独立累加器的执行次序，每个累加器的K顺序、操作数和scale字节选择一致。

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

按物理卡号重建冻结的 `regroll_release8` tile1 基线和当前版本，进行同地址、相邻基线对照：

```bash
python3 tools/compare_versions.py --gpu 2 --rounds 5 --validate --max-initial-vram-percent 20
```

此工具按PCI地址解析HIP索引，要求GPU计算活动不超过5%，默认也要求显存占用不超过1%。若显存只是空闲驻留，可显式设置 `--max-initial-vram-percent`；初始状态写入结果。构建和结果保存在隔离目录及 `results/tile1_target32_20260911/shared_allocations/`。本轮原始trace与编译副本的保存位置见 [本轮实验记录](results/tile1_target32_20260911/README.md)；历史归档见 [清理记录](results/ARCHIVE_20260911.md)。

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
