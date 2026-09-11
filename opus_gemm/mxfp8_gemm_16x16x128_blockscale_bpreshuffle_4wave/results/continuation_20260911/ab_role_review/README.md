This directory records independent CPU-only reviews of `ab_role_split_safe_b`, `ab_store8`, and `ab_store8_a0_mrepeat`. All three passed the checks below. The review did not compile or launch a GPU, edit any candidate, modify formal source, or modify the compiler. GPU correctness and timing remain owned by the root task.

The reviewed candidates are in `/tmp/mxfp8_fourwave_e8_continue_20260910/`. Their source and executable hashes are bound in `review_manifest.json` and in the three `*_isa_exec_wait_audit.json` reports.

| Candidate | Panel FP32 combined VGPR | Panel BF16 combined VGPR | SGPR | AGPR | LDS bytes | Spills / scratch |
|---|---:|---:|---:|---:|---:|---:|
| `ab_role_split_safe_b` | 416 | 460 | 92 | 256 | 152064 | 0 / 0 |
| `ab_store8` | 416 | 448 | 92 | 256 | 152064 | 0 / 0 |
| `ab_store8_a0_mrepeat` | 440 | 448 | 92 | 256 | 152064 | 0 / 0 |

All candidates retain four Wave64 waves and native 16×16×128 scaled MFMA. Each of their four kernels has 384 static MFMA instructions; every destination equals SrcC, and each four-AGPR tuple in a0:a255 appears six times. The source MFMA call order and external ABI files are unchanged. Both generic kernels retain the complete normalized formal baseline ISA. `ab_store8` also retains the complete normalized `ab_role_split_safe_b` FP32 panel ISA.

The producer mapping review is in `producer_mapping_audit.py` and `producer_mapping_audit.json`. For each operand, it enumerates two stages, 64 K tiles, and 2048 sixteen-byte requests per stage/tile: 262144 requests and 4194304 bytes. Both the original four-wave destination/source map and an independent expected global-coordinate set match exactly. There are no duplicated, omitted, or out-of-bounds requests.

| Physical wave | A requests per lane per hot iteration | A original roles covered | B requests per lane per hot iteration | B original roles covered |
|---:|---:|---|---:|---|
| 0 | 16 | 0, 2 | 0 | — |
| 1 | 16 | 1, 3 | 0 | — |
| 2 | 0 | — | 16 | 0, 2 |
| 3 | 0 | — | 16 | 1, 3 |

Prologue copies retain their original participation. Hot A copies target tile t+1 in next_stage. Hot B copies target tile `(t+2)&63` in the released current stage. The common publication barrier remains after MFMA 36; both producer groups complete their pending VMEM before reaching it. The 4096-consumer lifecycle model retains final A/B tile63 in stage1, with the wrapped dead B prefetch in stage0 and no A tile64 load.

The B Issue1 unsigned-offset fix preserves both addresses. The four immediate offsets are `[0,1024,2112,3168]`, with m0 base adjustments `[0,32,0,0]`. At K0/half0, Issue1 now uses soffset=0, producing global delta1024 and LDS delta `32+1024=1056`. The previous soffset=-32 would become an unsigned value and produce global delta `2^32+1024`. All four new soffset ranges are nonnegative and fit uint32.

`audit_isa_exec_wait.py` proves every panel role predicate from CFG reaching definitions: the initial v0 thread IDs feed the scalar wave-N comparison and the full-lane branch masks. Each panel has 20 role branches across five static loop bodies: ten A branches execute only on waves0/1, and ten B branches execute only on waves2/3. Each selected path issues eight DTLDS instructions, each other path issues zero, and both paths join at the same next MFMA. No path bypasses an MFMA or publication barrier. There are zero EXEC writes, including implicit v_cmpx changes.

LDS and VMEM wait analyses explore both conditional successors and loop backedges. VMEM accounting includes DTLDS and stores, since gfx950 stores share vmcnt. All analyses report zero register hazards. Every static publication barrier has zero pending VMEM on every explored path.

| Candidate | FP32 LDS CFG states | BF16 LDS CFG states | FP32 VMEM CFG states | BF16 VMEM CFG states |
|---|---:|---:|---:|---:|
| `ab_role_split_safe_b` | 2531 | 2918 | 12591 | 15687 |
| `ab_store8` | 2531 | 2956 | 12591 | 15947 |
| `ab_store8_a0_mrepeat` | 2520 | 2945 | 12382 | 15734 |

The generic FP32/BF16 analyses cover 1869/2256 LDS states and 2488/3649 VMEM states. All four kernels in every candidate retain six static barriers.

The two BF16 vec8 epilogues each have 32 `buffer_store_dwordx4` instructions, 64 `v_permlane16_swap_b32_e64` instructions, and 128 native packed BF16 RNE conversions. All 256 AGPRs are read exactly once after their last static MFMA write. Cache policy remains the default. The source changes exactly match the frozen `store_bf16_vec8` component, whose CPU lane-exchange model proved exact coverage of all 65536 output coordinates and sixteen-byte store alignment.

`combination_source_audit.py` and `combination_source_audit.json` verify exact changed-line composition: `ab_store8` adds exactly the two edit groups in the frozen vec8 patch, and `ab_store8_a0_mrepeat` adds exactly the five edit groups in the frozen A0 patch. Producer sources and the final tail are preserved. The manually inserted M0 load is at source line800, after the publication barrier at line793 and after MFMA36. M1/M2/M3 occur after source MFMA40/44/48. SFA0 remains current until its update after MFMA48, and the old whole-128B A0 reload is removed. A separate mixed-generation A0 model checks all 4096 consumers and finds no premature next-stage read, stale slice, stale scale, or A tile64 load.

The A0 combination increases FP32 combined allocation by 24 registers relative to `ab_store8`. CPU checks establish the reviewed mapping, participation, accumulator, and wait properties; the root task's GPU results determine whether that tradeoff is useful.

To repeat the ISA checks without touching candidate artifacts:

```bash
python3 -B audit_isa_exec_wait.py ab_role_split_safe_b
python3 -B audit_isa_exec_wait.py ab_store8
python3 -B audit_isa_exec_wait.py ab_store8_a0_mrepeat
```

The script writes only the corresponding JSON report in this review directory. Its LDS parser/checker dependency is `/tmp/mxfp8_fourwave_bpreshuffle_20260910/audit_lds_waits.py`; that dependency's hash is recorded in the review manifest.
