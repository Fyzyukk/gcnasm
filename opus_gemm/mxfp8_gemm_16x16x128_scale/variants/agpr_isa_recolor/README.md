# Full C-accumulator AGPR ISA recoloring

This experiment starts from a fresh clang23 build of the retained
`t2x16_nfast_exact` unified-scale stack.  It moves all 128 C dwords to
`a0:a127`, keeps MFMA SrcC in AGPRs, and sends all 32 output stores directly
from AGPRs.

The original `v128:v239` ordinary allocation is translated to `v0:v111`.
Setup temporaries originally in `v0:v8` move to `v24:v32`; one entry copy
preserves the ABI workitem id.  The primary target is 112 ordinary VGPRs plus
128 AGPRs, with accumulator offset 112 and a combined physical
vector-register footprint of 240.  Offset controls 116/120/124/128 retain
112 ordinary VGPR metadata while moving the AGPR window; rotate controls
4/8/16 cyclically change the logical-C-to-AGPR mapping at offset 112.

`half_upper` moves only C dwords 64:127, which are the half stored latest at
the output handoff.  Its ordinary operands occupy `v64:v175`, the retained C
half stays in `v0:v63`, and its 64 AGPRs begin at offset 176 (240 combined).

Build this experiment with:

```bash
./build.sh
```

The shipped end-to-end correctness and performance driver is
`../mi355_3p_validation/run_mi355.sh`; it includes this candidate as
`08_agpr` and supports selecting the physical GPU with `GPU=<index>`.

The build is fixed to `/opt/rocm-llvm23-46fcb339/bin/clang++`, applies
top-down pre-RA scheduling plus the retained `ctrl_fill` patch, and inspects
the image linked into each executable.  GPU runs are pinned to GPU7, take
`/tmp/mxfp8_gpu7.lock`, unset `MXFP8_UNIT_SCALE`, and require the
`unified scale producer` banner.

## Static gate

The reference remains 1595 instructions, 240 VGPR, 101 SGPR, 0 AGPR, and no
spill.  Every full-AGPR candidate is also 1595 instructions with:

```text
192 MFMA, all AGPR destination + SrcC
32 stores, all direct from AGPR
384 v_accvgpr_write_b32, 0 v_accvgpr_read_b32
112 VGPR, 128 AGPR, 101 SGPR
91 D2L loads, 50 waits, 7 barriers, 0 setprio
0 VGPR/SGPR spill, 0 scratch/private, 139264-byte LDS
```

The offset-112 layout uses 240 combined vector registers; offsets
116/120/124/128 use 244/248/252/256.  CFG lane-level def/use analysis found no
color collision for the full or half mappings.

`half_upper` is likewise 1595 instructions and uses 176 VGPR + 64 AGPR = 240.
It moves 96 of 192 MFMAs and 16 of 32 stores to AGPR, performs 192 AGPR clears,
has no AGPR readback, and has no spill.

## Correctness

- Full eight-shape unified-scale correctness passed for offset-112 rotate-0,
  the initial 128+128 control, rotate-4, and rotate-8.  This includes batch 2,
  `8192x512x16384`, and `8192x2048x128`.
- Every offset/rotate candidate passed the unified-scale `512^3` smoke gate.
- `half_upper` passed the same smoke gate.

Logs are in `correctness_gpu7.log`, `correctness_rotate4_gpu7.log`,
`correctness_rotate8_gpu7.log`, `correctness_sweep_smoke_gpu7.log`, and
`correctness_half_upper_smoke_gpu7.log`.

## Performance

All measurements are `8192^3`, batch 1, GPU7, unified scale.  Short tests use
four ABBA rounds with warmup 300 / iterations 150.

```text
candidate       geometric    median      wins
offset112 r0      +0.2359%    -0.0975%    3/4
offset116         +0.5391%    +0.4995%    2/4
offset120         +0.2059%    +0.0975%    2/4
offset124         +0.6786%    +0.7030%    2/4
offset128         -0.2298%    +0.0216%    1/4
offset112 r4      +0.4087%    +0.6272%    3/4
offset112 r8      +1.3482%    +1.2573%    4/4
offset112 r16     -0.3486%    -0.2586%    1/4
half_upper        -0.4835%    -0.6921%    1/4
```

The three apparent short-run winners were checked with eight ABBA rounds at
warmup 1000 / iterations 500:

```text
candidate       geometric    median      wins
offset112 r0      -0.0082%    -0.0110%    4/8
offset112 r4      -0.0686%    -0.0878%    2/8
offset112 r8      -0.0384%    -0.0879%    2/8
```

Therefore the long-window result is neutral: full or partial C-to-AGPR
recoloring is correct and removes the SrcC-VGPR WAR class, but none of the
full mappings survives the `w1000/i500` stability gate.

### User-selected `w200/i100` operating criterion

The requested production-screen criterion was subsequently changed to four
paired rounds at warmup 200 / iterations 100, retaining any positive
geometric result.  All runs still use GPU7, the shared lock, unified scale,
and the same freshly linked reference.  Under that explicit criterion:

```text
candidate       geometric    median      wins
offset112 r0      +1.1744%    +0.8299%    3/4
offset112 r4      -0.1302%    -0.1479%    2/4
offset112 r8      +0.3459%    +0.5060%    3/4
```

A direct `rotate8` versus `offset112 r0` ABBA selected rotate-0 by
`+0.4816%`, 3/4 wins.  Thus `agpr_recolor.exe` is retained for the requested
short-window operating metric, while the neutral long-window evidence above
must remain attached to that choice.

The raw files used for this historical sweep were local experiment artifacts
and are not part of the MI355X validation bundle.
