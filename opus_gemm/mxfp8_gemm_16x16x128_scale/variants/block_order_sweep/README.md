# block_order_sweep

独立 unified-scale / gfx950 workgroup 映射实验。基线固定为当前完整胜者：

```text
no s_setprio + p18 + two-quadrant early-C vmcnt(16) + ctrl_fill
+ clang23 prera top-down
```

不修改 retained 模板或主优化日志。`kern.cc` 只把物理 workgroup id 置换为 retained
模板使用的逻辑 row-major id；GEMM、persistent x4、同步和 store 路径均不变。

候选：

- `t4x8_nfast` / `t4x8_mfast`：每 32 个物理 WG 覆盖 4 个 M-group × 8 个 N tile。
- `t8x4_nfast` / `t8x4_mfast`：每 32 个物理 WG 覆盖 8 个 M-group × 4 个 N tile。
- `nmajor`：固定 N 后遍历全部 M-group。
- `t2x16_nfast_exact`：只在 `8192x8192` 网格启用 2 M-group × 16 N。
- `t4x8_nfast_exact` / `t8x4_nfast_exact`：对应 tiled order 的低开销
  `8192x8192` fast path；其他 shape 精确回退。
- `t2x16_direct`：在 exact 8192 fast path 直接向模板两次表达式提供
  `block_n`/`mgroup`，删除 logical-id 重组后再次动态 `%`/`/` 的开销。
- `identity_direct`：同样删除 exact 8192 的动态除法，但保持原 block order，作为
  `t2x16_direct` 的开销归因对照。
- `identity_coords` / `t2x16_coords`：由生成的本地模板直接定义两个坐标，避免
  operator-proxy 重复执行 exact-shape 分支；前者保持原顺序，后者使用 2×16。
- `t2x16_xor_m8` / `serpentine` / `gray` / `xor_macro8`：保持每个 32-WG
  chunk 的 2×16 集合不变，只置换 local N 位，用于寻找 XCD/L2 的低成本排列。
- `t2x16_insert_p1/p2/p3`：把 1 个 local-M bit 分别插到 5-bit local id
  的 bit 1/2/3；原 `t2x16_nfast_exact` 等价于插到 bit 4。
- `t2x16_n_bitreverse` / `n_rotl1/2/3`：保持 M bit 在 bit 4，只对四个
  local-N bits 做 bit-reverse 或循环移位，仍覆盖完全相同的 2×16 集合。

目标网格只有 `ceil(32 / 4) = 8` 个 persistent M-group，因此 16 M-group × 2 N
无法在 8192² 上构成双射，没有建立伪 16×2 候选。

矩形 tiled order 只有在两个网格维度都能整除时才启用，否则精确回退 retained
row-major 映射。`map_check.py` 对七组 correctness 网格、active tiled 网格和
`8192x8192` 网格验证一一映射。

构建本实验：

```bash
./build.sh
```

提交包中的统一 correctness/performance 入口是
`../mi355_3p_validation/run_mi355.sh`，其中最终保留项对应
`07_t2x16`；可用 `GPU=<index>` 选择物理 GPU。

所有 GPU 测试固定 GPU7 并持有 `/tmp/mxfp8_gpu7.lock`。长测只给短轮转有正信号的
候选运行，固定 `warmup=1000`、`iterations=500`、八轮 ABBA。

## Result

Fresh clang23 linked-resource gate:

```text
tag                    inst  nop  wait  MFMA  VGPR  SGPR  spill/scratch
retained                1593  100   50    192   240   101       0
ref (prera_top)          1582   88   50    192   240   101       0
t2x16_nfast_exact        1595   85   50    192   240   101       0
t4x8_nfast_exact         1594   84   50    192   240   101       0
t8x4_nfast_exact         1595   85   50    192   240   101       0
```

共同保持 91 个 direct-LDS load、32 store、7 barrier、139264 B LDS、零
`s_setprio`。七组要求的 unified-scale correctness（包括
`8192x512x16384`）在最终 `t2x16_nfast_exact` 上全部通过；另有静态 exhaustive
映射检查覆盖 exact `8192x8192` 网格。为避免只验证 fallback，另跑了实际进入
2×16 分支的 `8192x8192x128,batch=1` GPU-vs-CPU 检查，67108864 个输出元素零错误。

### 第一轮 generic mapping，4 rounds / w300 / i150

```text
t4x8_nfast   -0.1636%, 1/4
t8x4_nfast   -0.5966%, 1/4
t4x8_mfast   -2.6927%, 0/4
t8x4_mfast  -12.2329%, 0/4
nmajor      -12.2577%, 0/4
```

M-fast 和 pure N-major 的大幅回退说明跨 WG 的 A 局部性不能牺牲。generic tiled
版本还包含动态整除与通用 fallback，因此继续测试只在正式 shape 启用的 fast path。

### Exact-8192 fast path

四轮短测相对 fresh `prera_top`：

```text
t2x16_nfast_exact  +1.3180%, 3/4
t4x8_nfast_exact   +0.6392%, 3/4
t8x4_nfast_exact   +1.1061%, 4/4
```

长测消除了前两项的大部分短测漂移：

```text
candidate             geometric  median   wins
t8x4 vs prera_top       +0.0523%  +0.0110%  5/8   neutral
t2x16 vs prera_top      +0.0921%  +0.1210%  7/8   weak positive
t2x16 vs retained       +0.1745%  +0.1868%  7/8   cumulative check
```

这里的长测均为 `8192x8192x8192,batch=1,warmup=1000,iterations=500` 的八轮
mirrored ABBA。`t2x16_nfast_exact` 是本目录唯一保留的正信号，但绝对收益只有约
0.1%，不能解释或补齐到 3 P 的剩余差距。

### Direct coordinates 与 local permutation

两种绕过模板 `%`/`/` 的实现都没有收益：operator proxy 的 2×16 为 `-0.5051%`，
生成模板的 direct-coordinate 2×16 为 `-0.2520%`；对应 identity 对照也分别为
`-0.1966%`、`-0.2726%`。因此入口动态除法不在可见关键路径。

在同一个 2×16 chunk 内继续置换 N，四轮短测只有 Gray code 看似为正
（`+0.1926%`, 3/4）；其八轮长测为 `-0.0713%`、0/8，明确是假阳性。
`xor_m8` 为 `+0.0724%`、2/4，macro-XOR 为 `-0.2589%`，serpentine 为
`-2.2817%`，均不晋级。

进一步扫描 M bit 插入位置和 N-bit permutation。所有候选均保持 240 VGPR、
101 SGPR、零 spill，并通过静态双射、七组 fallback correctness，以及实际进入
exact 分支的 `8192x8192x128` GPU-vs-CPU 验证。

四轮短测相对 `t2x16_nfast_exact`：

```text
candidate              geometric  median   wins
t2x16_insert_p1          -0.4729% -0.4517%  1/4
t2x16_insert_p2          +0.4608% +0.4558%  4/4
t2x16_insert_p3          +0.3584% +0.5103%  3/4
t2x16_n_bitreverse       -0.2889% -0.3767%  1/4
t2x16_n_rotl1            +0.2894% +0.1406%  4/4
t2x16_n_rotl2            -0.4756% -0.3767%  0/4
t2x16_n_rotl3            +0.0131% +0.2817%  3/4
```

三个正信号进入八轮 `warmup=1000, iterations=500` 长测后均未保留：

```text
candidate              geometric  median   wins
t2x16_insert_p2          -0.2303% -0.2961%  0/8
t2x16_insert_p3          -0.0233% +0.0110%  2/8
t2x16_n_rotl1            -0.0823% -0.0658%  0/8
```

因此 chunk 内 bit-layout 也不能叠加到原 2×16 n-fast 的弱正收益上；本目录仍只
保留 `t2x16_nfast_exact` 作为约 `+0.1%` 的候选。

以下原始数据文件名来自本地历史 sweep，不包含在 MI355X 验证包中：

- `results_short_gpu7.tsv`
- `results_exact_short_gpu7.tsv`
- `results_t8x4_nfast_exact_long_gpu7.tsv`
- `results_t2x16_nfast_exact_long_gpu7.tsv`
- `results_t2x16_nfast_exact_vs_retained_long_gpu7.tsv`
- `results_direct_short_gpu7.tsv`
- `results_coords_short_gpu7.tsv`
- `results_t2_permute_short_gpu7.tsv`
- `results_t2x16_gray_vs_t2x16_nfast_exact_long_gpu7.tsv`
- `results_t2_bitlayout_short_gpu7.tsv`
- `results_t2x16_insert_p2_vs_t2x16_nfast_exact_long_gpu7.tsv`
- `results_t2x16_insert_p3_vs_t2x16_nfast_exact_long_gpu7.tsv`
- `results_t2x16_n_rotl1_vs_t2x16_nfast_exact_long_gpu7.tsv`
- `correctness_bitperm_gpu7.log`
- `correctness_t2x16_exact_gpu7.log`
- `correctness_t2x16_exact_active_8192_gpu7.log`
