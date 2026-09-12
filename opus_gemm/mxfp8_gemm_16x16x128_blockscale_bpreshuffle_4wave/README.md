gfx950 4-wave blockscale bpreshuffle GEMM
=========================================

本目录提供 gfx950 的 4-wave MXFP8 blockscale GEMM，接收 AITER 标准预排 B 和紧凑 E8M0 scales。**正式入口统一使用 `tmpl_generic.hpp`，K=8192也走通用kernel。** 专用版的矩阵预取、寄存器滚动、MFMA5后交接LDS、BF16合并输出等优化已迁入；scale面板按运行时K分段加载，末尾两个K128块按实际位置处理。

**执行模式为 4wave + tile1。** 本项目的 tile 数量指每个工作组处理的完整 **256×256 输出块数量**：tile1 每WG独立处理1块；tile2/tile4 为每WG连续处理2/4块的持久化方案。当前 `traits.hpp` 的 `OUTPUT_TILES_PER_WG=1`，接口 `tiles=0`（auto）也选择1，CLI、Python与C ABI均只接受0/1。K方向另有2-stage LDS双缓冲。

当前版本为 `generic_tile1_issue_20260912`，基于通过五轮确认的 `grid2d_unroll4` 清理而来。本轮在提交 `9229d1a` 的通用版本上继续优化矩阵请求发射、m0基址复用、主循环优先级、二维grid与循环展开。构建只含通用kernel的BF16/FP32两种输出实例，清理前后的全部有效机器指令一致。源码、正确性和测量见 [本轮记录](results/generic_issue_20260912/README.md)。

最终构建在GPU2（HIP2，PCI `0000:65:00.0`）实测，M=N=K、batch1、warmup200、iterations100、CLI seed1，五轮中位数：

| M=N=K | BF16 ms | BF16 P | FP32 ms | FP32 P |
| ---: | ---: | ---: | ---: | ---: |
| 8192 | 0.334573174 | **3.286311** | 0.357366333 | **3.076707** |
| 1024 | 0.013218050 | 0.162466 | 0.017790860 | 0.120707 |
| 2048 | 0.021611280 | 0.794949 | 0.025707681 | 0.668278 |
| 4096 | 0.048890672 | 2.811149 | 0.055321960 | 2.484347 |

本轮基线明确固定为提交 `9229d1a57f24cdd3da47ba3e03545d08d4f001e1` 的通用4wave/tile1版本。五轮同地址交替确认中，BF16为基线3.258160P、候选3.286620P，FP32为3.049997P、3.076171P；相邻基线归一化后的提升中位数分别为0.863%和0.871%，两种输出均五轮为正。上表是清理后正式构建的独立五轮结果。**3.5P目标尚未达到。** 8192用于compute-bound优化，另外三个尺寸用于记录最终性能。此前3.259P检查点见 [上一版记录](results/generic_opt_20260912/README.md)。

后续延迟优化以提交 **f483077**（上表正式版本）为新冻结基线。`grid_group2` 的历史五轮同地址窗口约 **3.299P**；该窗口只保存了开跑前空闲快照，需在空闲时复测，尚未替换生产版本。寄存器压缩、操作数提前读取、连续 wave 分工等19个候选已完成编译和静态核对，GPU运行验证仍待执行。当前筛选工具会在每个GPU阶段前后保存占用快照。见 [延迟优化记录](results/generic_latency_20260912/README.md)。

历史专用3.214P、持久化tile2/tile4对照及未采用实验保留在 `results/` 的冻结记录和归档中，不参与当前构建。继续工作的入口为 [最新通用路径续记](CONTINUATION_20260912_LATENCY35.md)，已发布版本的记录为 [发射调度轮续记](CONTINUATION_20260912_ISSUE35.md)。

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

M、N 为正的 256 倍数，K 为正的 128 倍数，全部使用同一通用路径。每次只启动 **一个 GEMM kernel**，不做host scale重排、不调用scale转换kernel、额外device workspace为 **0字节**。Python可以分配输出 `C`；使用 `out=` 时复用调用方输出。C ABI与CLI支持连续batch，Python当前为二维输入。

Scale 加载流程
--------------

Blockscale 的输入契约及打包 scale / `op_sel` 方案来自此前的 8-wave bpreshuffle 移植；矩阵流水线继承原 4-wave、256 AGPR 实现。与 gfx950 MXScale BMM 相同的是“一个 K128 scale 用于四个 K32 子组”的语义；本实现没有照搬 BMM 的加载流水线。下面的完整 K 面板、寄存器直接打包与普通 LDS dword 读取是 4-wave 的后续优化。

通用路径按固定容量缓存紧凑scales；容量限定单个面板，不限定GEMM的K长度：

1. A_scale：每个面板256行×64个K128分组，共 **16 KiB**。先一起发出四组向量全局读取，再用quad DPP和byte permute在寄存器内打包，直接写入最终LDS布局。启动时B矩阵请求与scale转置重叠。
2. 每个 A dword 的四个字节属于四个 M repeat：`s[r,q]、s[r+32,q]、s[r+64,q]、s[r+96,q]`。另一个 M128 half 使用另一组 dword。
3. B_scale：两个 N128 分组 × 64 个 K128 分组，共 **128 字节**输入。每个 E8M0 字节乘 `0x01010101`，成为四个相同字节，最终 LDS 面板为 512 字节，按 `[K,half]` 排列相邻两个 N128 half。
4. 发布面板后，主循环在MFMA2后用一次LDS b64预取下一K的两个A scale half，在MFMA20后用一次b64预取两个B scale half。各dword在当前K最后一次使用后再安装。需要下一面板时，先确认旧面板读取结束，再加载并发布下一段；短K和末尾不足64组的面板只读取有效输入，未使用的槽复制最后一个有效分组。
5. 四个 K32 lane group 读取同一个 A scale dword；MFMA 的 `op_sel` 选择对应 M repeat 字节。B dword 的四个字节相同。这样在硬件内部实现 K128 scale 对四个 K32 子组的复用。

这里没有创建全局 `[M,K/32]` 或 `[N,K/32]` scale张量，没有重新量化A/B。K32广播来自kernel内的LDS读取地址复用和寄存器打包。运行时K迭代和面板内寻址分开：矩阵地址使用完整K索引，scale地址在面板容量内循环。

矩阵流水线
----------

每个工作组256线程，即4个Wave64，计算256×256输出tile，K tile为128。grid X对应N tile，Y对应M tile，Z对应batch，直接取得输出块坐标。A/B通过异步global→LDS双缓冲，再进入VGPR；B producer接收标准 `(16,16)` 预排布局。累加结果固定在每线程256个AGPR。

先加载首个scale面板和矩阵K0，存在K1时才预取K1，并种入K0的A0/A1/B0/B1寄存器。AGPR清零分为两组，通过输入约束的空asm把初始化放在SFA请求和B矩阵请求的等待期间。wave0/1各负责一个A的M128 half，wave2/3各负责一个B的N128 half。资源描述符按wave选择一次，16个不可变地址提前缓存到VGPR；主循环的预取指令位置由四个wave共用。

第5条MFMA后，完整VMEM/LGKM等待与barrier发布t+1并释放t的LDS stage。主循环在MFMA7、9、…、37后各发一次t+2预取；四个相邻LDS行用MUBUF immediate 0/1056/2112/3168共享同一个m0基址，global端VOFFSET减去对应immediate。K1也使用这一统一producer。主循环保持priority 1，scale面板重填时降到0、发布后恢复1；采用unroll4。仅在存在t+2时发起预取，倒数第二个K128块只滚入最后一个块，不发无消费者的全局矩阵请求；K128单块输入直接进入最后计算段。

两种输出的A0/M repeat 0均在MFMA30后预读t+1的两个16字节片段，到MFMA36完成当前值的最后消费后再安装；其余A0 M repeat仍在40、44、48后读取。B0在32、34、36、38后分四对读取。C11前8条维持按行次序，后8条在M repeat 2/3间交替，使B1四个N repeat分别在58、60、62、64后读取。A1的M repeat 0/1/2在52、56、63后读取；M repeat 3的两个16字节片段提前到56后读入临时寄存器，在64后旧值最后一次使用完毕再安装。每个累加器的K顺序、操作数和scale字节选择一致。

BF16把完成的累加片段转换为4元素向量，提前写入pitch264的输出LDS，再合并为16字节GMEM stores并使用 `nt`。A/B矩阵的双缓冲合为一个对齐的135168字节分配；矩阵DMA和读取全部结束并经等待与barrier后，BF16输出才复用它。最后一轮MFMA20、36、52、64后，依次发布C00、C10、C01、C11的128×128区域，每区域每线程执行8次16字节合并写回。MFMA36的发布仍等待LDS完成，允许独立的前一块C00全局写回继续进行。这四个区域共同组成每WG唯一的256×256输出tile。FP32直接写回。LDS为 **152064字节**，普通VGPR为FP32 **244** / BF16 **256**，另有固定 **256 AGPR**，SGPR **62**，零spill/scratch。metadata combined VGPR为500/512，已经包含AGPR；静态原生MFMA为448条。

构建与运行
----------

需要带原 4-wave 两个 hard-pin 补丁的 clang23；普通 ROCm clang 不支持 `amdgpu_pin_agpr`，不能当作等价编译器。当前已在独立目录构建好：

```bash
make -j3 all inspect
HIP_VISIBLE_DEVICES=2 OMP_TOOL=disabled OMP_NUM_THREADS=16 \
  build/gemm_a8w8_blockscale_bpreshuffle.exe \
  -m 8192 -n 8192 -k 8192 -b 1 -w 200 -i 100 -v 0 --dtype bf16
python3 tools/benchmark_shapes.py --gpu 2 --sizes 8192 1024 2048 4096 \
  --rounds 5 --tag my_run
HIP_VISIBLE_DEVICES=2 OMP_TOOL=disabled OMP_NUM_THREADS=16 \
  python3 test_blockscale_bpreshuffle.py --large
```

Makefile 默认 `TOOLCHAIN=/root/toolchains/rocm-llvm23-46fcb339-build`，`OPUS_INCLUDE_DIR=/root/workspace/aiter/csrc/include`，均可覆盖。编译器基线、补丁顺序和哈希保存在 `results/toolchain_manifest.json`；补丁原件仍在原 4-wave 目录的 `tools/compiler/`。

按物理卡号重建冻结的 `9229d1a` 通用kernel和当前通用版本，在8192³进行同地址、相邻基线对照；两者均检查源码哈希和指令编码：

```bash
python3 tools/compare_versions.py --gpu 2 --rounds 5 --validate
```

此工具按PCI地址解析HIP索引，要求GPU计算活动不超过5%，默认也要求显存占用不超过1%。若显存只是空闲驻留，可显式设置 `--max-initial-vram-percent`；初始状态写入结果。构建和结果保存在隔离目录及 `results/generic_issue_20260912/shared_allocations/`。四尺寸工具的结果也保存到本轮记录目录。历史专用实验和原始trace的归档位置见 [专用实验记录](results/tile1_target32_round2_20260911/README.md) 及 [清理记录](results/ARCHIVE_20260911.md)。

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

主要代码：`tmpl_generic.hpp`为唯一通用实现，`traits.hpp`为tile/资源配置；`gemm_a8w8_blockscale_bpreshuffle_launch.cc`和 `blockscale_bpreshuffle.py`为适配层。历史专用`tmpl.hpp`已从当前源码和构建中移除；其冻结副本保留在 [历史检查点](results/tile1_target32_round2_20260911/selected/)。
