The tile128/two-workgroup branch is complete and is not selected. Native
AGPR128 compiles without spills and passes the recorded FP32 correctness check,
but the final plain-SFA/end-fence combination adds no measured speed. The parent
ended the branch and deferred BF16 compiler repair. The direct-B candidate is
also archived without selection. Candidate source, executables, and compiler
were not modified during this finalization; all 63 source/build hashes listed
in the six candidate manifests were verified unchanged.

All GPU results below were produced by the parent through serial GPU2 runs.
This audit agent launched no GPU kernels. Each candidate's
`measurements/results.json` matches its current candidate name, `tmpl.hpp`
SHA256, and executable SHA256. The separate parent comparison record was checked
the same way. Exact checks, benchmark arguments, and hashes are collected in
[tile128_results.json](tile128_results.json), and each candidate manifest now
records its completed measurements and final decision.

Performance uses M=N=K=8192, batch 1, 200 warmups, and 100 timed iterations.

| Candidate | FP32 ms | FP32 PFlop/s | BF16 ms | BF16 PFlop/s |
| --- | ---: | ---: | ---: | ---: |
| `tile128x256_singlebuf_vgpr` | 0.450214882 | 2.442192988 | 0.433769531 | 2.534782986 |
| `tile128x256_singlebuf_vgpr_endfence` | 0.439723015 | 2.500464135 | 0.413703613 | 2.657727882 |
| `tile128x256_plain_sfa` | 0.441543312 | 2.490155773 | 0.417030830 | 2.636523604 |
| `tile128x256_agpr128_fp32` | 0.435959625 | 2.522049208 | Unsupported | Unsupported |
| `tile128x256_agpr128_plain_endfence_fp32` | 0.436213875 | 2.520579219 | Unsupported | Unsupported |
| `plain_sfa_direct_b` (M256) | 0.403750877 | 2.723242696 | 0.390173912 | 2.818003956 |
| `scale_panel_direct_roll_a0` (parent M256 comparison) | 0.382872276 | 2.871745216 | 0.373712082 | 2.942135620 |

The six audited candidates passed their recorded correctness cases with zero
reported errors: FP32 M256 x N512 x K8192, batch 1; supported BF16 candidates
M512 x N256 x K384, batch 2. The parent M256 comparison also passed FP32 at
M256 x N512 x K8192, batch 1 and BF16 at M512 x N256 x K8192, batch 2.
The 8192-cubed benchmark records use `-v 0`; they are timing records, with
correctness established only for the separate recorded validation cases.

The initial AGPR128 candidate improves FP32 throughput by about 3.3% over the
original VGPR/TR8 tile128 candidate. AGPR128 uses 128 AGPRs plus 120 ordinary
VGPR allocation, or 248 combined registers, with 66 SGPRs and no spill/scratch.
Its LDS footprint is 51,200B, rising to 51,712B for plain SFA. Both fit the
two-workgroup resource threshold on gfx950. A separate HIP occupancy query
confirmed two 256-thread workgroups per CU for the VGPR/TR8 candidates;
AGPR128 occupancy is predicted from the matching register/LDS threshold.
These resource results do not offset the observed performance gap. Compared
with the M256 tile, M128 requests 50% more A/B bytes per output and uses two
barriers per K128 step; this audit did not isolate each factor's runtime cost.

The final AGPR128/plain-SFA/end-fence ISA has 554 instructions, 32 native tied
AGPR MFMAs, 32 output stores, and no wait inside the MFMA group. The original
AGPR128/TR8 candidate has 534 instructions and allows the next `vmcnt(0)`
inside that group. Their almost identical timing is the stopping result.

Two distinct compiler diagnoses remain preserved:

- [BF16 AGPR128 diagnostic](agpr128_diagnostic/README.md): the two-dtype
  translation unit fails during BF16 register allocation, after FP32 succeeds.
  Evidence points to an AGPR hard pin crossing a required AGPR-to-VGPR BF16
  conversion COPY onto a VGPR-only class. The exact failing vreg/target was not
  instrumented. A future narrow fix should make incompatible cross-file COPYs
  pin-placement boundaries while retaining compatible accumulator/PHI chains.
- [Shared-zero coalescing diagnostic](agpr128_conflict_review/README.md):
  `assume(loops>0)` allows equal zero initializers pinned to a[0:3] and a[4:7]
  to coalesce. `updateRegAllocHint` discovers the conflict after the merge.
  A future `shouldCoalesce` guard should reject incompatible hard-pin merges
  beforehand; serialized MIR loses the custom HardPin hint kind, so validation
  must replay from the preserved LLVM IR.

The layout and scheduling evidence is preserved in the
[tile128 mapping audit](tile128_mapping_audit/README.md),
[occupancy audit](occupancy_audit/README.md), and each candidate's
`static_audit.json` and `lds_wait_audit.json`.
For direct B, [the extracted layout audit](plain_sfa_direct_b/direct_layout_audit.json)
checks 169,984 offsets and 5,439,488 byte coordinates with no mismatch or
out-of-bounds access. The independent
[rolling pipeline review](direct_b_cpu_review_report.json) covers 1 through 65
K tiles, and the [CFG VMEM review](direct_b_vmem_review_report.json) checks all
384 static MFMAs per dtype with zero pending VMEM input hazards. Removing waits
as a negative control detects hazards at all 384. These artifacts preserve the
successful correctness and implementation findings even though the candidates
are not selected for performance.
