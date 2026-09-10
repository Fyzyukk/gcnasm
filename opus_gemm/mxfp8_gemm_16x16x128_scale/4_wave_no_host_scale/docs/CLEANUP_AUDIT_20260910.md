# Four-wave cleanup and dependency audit — 2026-09-10

Status: **plan only**. This audit has not moved or deleted files, compiled a
kernel, or queried/launched a GPU. The parent owns final validation and any
subsequent recoverable archive.

Machine-readable exact paths are in [cleanup_plan.json](cleanup_plan.json).
Paths are relative to the `path_base` recorded there. Do not turn its scope
into a recursive cleanup of the parent `variants/` or quarantine directory.

## Scope and inventory

| Group | Archive after final validation | Keep |
| --- | ---: | ---: |
| Current `variants/` top-level directories | 23 | 30 containing Git-tracked files |
| Existing mixed quarantine directories | 459 | 208 |
| `recovery_sched_group_20260908/` | 1 | — |

There are **483 exact directory targets**, approximately **390 MiB**
(`du -sk`: 399,580 KiB at audit time). The current variants account for
15,288 KiB, quarantine targets for 333,604 KiB, and recovery diagnostics for
50,688 KiB. All 483 targets were checked against the 171 current
`git ls-files` entries: no overlap. No symlinks were found under these targets.
The plan does not include the new `4_wave_no_host_scale/`.

The old cleanup documents/manifests say 643 quarantined directories. The actual
count is **667**, so the old manifests are not a current deletion list.

The 23 current untracked directories all contain explicit four-wave traits.
They include the formal after4 source and 22 predecessor/reference directories.
Do not archive the formal source until the standalone package's source,
native ISA, numerical results and historical evidence have been preserved.

The 459 quarantine targets are justified as follows:

- 439 have explicit `BLOCK_SIZE = 256`, `WARP_SIZE = 64`, and
  `static_assert(NUM_WAVES == 4)`: 179 `four_wave*` and 260 `scale_*`.
- Eight CX2 persistent x4/x8 directories inherit audited four-wave traits.
  Here x4/x8 is the output-tile count, not the wave count.
- Four pure four-wave counter diagnostics identify four-wave kernels in their
  README or recorded counter CSV.
- Three wait6/zero-SrcC probes explicitly target the four-wave wait6 lineage.
- `scale_load16_k4_raw_lds_tr_b8_consumer_v1` is a static mapping audit for
  this four-wave lineage. Inclusion is historical classification, not an
  endorsement of its old lane-semantics model.
- Four other-named diagnostics are exact-K64-wrap, prepared-scale,
  row-major-scale, and `profile_bcontig_vs_wait6_20260908`. Their scripts or
  recorded kernel-name/workgroup-size columns establish four-wave ownership.

The five scale-prefixed eight-wave directories are deliberately kept:

- `scale_direct_packed_b96`
- `scale_fused_ds_read`
- `scale_global_packed_b96`
- `scale_lds_prefetch`
- `scale_producer_wave_sweep`

Both `four_wave_vs_eight_wave_*` diagnostic directories are mixed and also
kept. All remaining unknown/other directories and the five loose files in the
quarantine root are outside this cleanup. The plan explicitly lists all 208
retained quarantine directories.

## Protected user and shared state

Every tracked file remains untouched, including the six dirty tracked files:

- `MXFP8_GEMM_OPTIMIZATION_LOG.md`
- `gemm_a8w8_mxfp8_scale_common.h`
- `gemm_a8w8_mxfp8_scale_kernel_template_fixed_b_asym_b_read2_unified_scale.hpp`
- `variants/agpr_isa_recolor/patch_recolor.py`
- `variants/early_c_store_full_stack/tmpl.hpp`
- `variants/sched_probe/gemm_a8w8_mxfp8_scale_kernel_template_sched_probe.hpp`

The eight-wave final/history directories, existing eight-wave archive,
unattributed root build directories, repository-level profiler data/probe,
and mixed old cleanup manifests are not cleanup targets.

Three untracked historical four-wave documents are a separate optional group:
`4-wave.md`, `FOUR_WAVE_COEXEC_PIN_STATUS.md`, and
`RECOVERY_20260908.md`. Preserve/copy their contents and provenance into the
final documentation or verified archive **before** optionally moving originals.
They are not included in the 483 automatic directory targets.

## Standalone build boundary

The original formal directory is:

```text
variants/scale_sfb_k16_carried_raw_coexec_dist22_sfa_k8_raw_k4_queue_exact_k64_wrap_prepared_scale_c11_after4_v1
```

Its four source files depend on the root common header:

- `traits.hpp` includes `../../gemm_a8w8_mxfp8_scale_common.h`.
- `host.cc` and `tmpl.hpp` include the same filename by the build include path.
- `build.sh` adds both `-I HERE` and the two-level parent `-I TOP`.

The root common header is dirty only by the optional
`MXFP8_SCALE_KARGS_EXTRA_FIELDS` extension hook; no formal source defines that
macro. Preserve that root header for other branches. The new final package
uses a local minimal ABI header, retaining the 96-byte field order and explicit
size/offset assertions, and changes the traits include to its local filename.
That is a parent-owned packaging decision; the fresh build and host ABI audit
must validate it.

At inspection, the new final `kern.cc` and `tmpl.hpp` were byte-identical to
the formal source, and the only `traits.hpp` delta was the local include path.
The parent is changing host test/reporting support independently. This cleanup
audit does not claim the final host or full validation was finished.

Retain the external prerequisites:

- Patched clang23 at
  `/root/toolchains/rocm-llvm23-46fcb339-build`, based on ROCm LLVM commit
  `46fcb339fb61119b337f973c7ca9e710a319fdd0`.
- ROCm at `/opt/rocm`, HIP runtime, OpenMP runtime, and
  `/root/workspace/aiter/csrc/include/opus/` headers.
- `tools/CLANG23_AMDGPU_HARD_PIN.md`,
  `tools/clang23_amdgpu_hard_pin.patch`, and
  `tools/clang23_amdgpu_agpr_accumulator_pin.patch`.

The base pin patch must be applied before the accumulator supplement. The
formal template uses `amdgpu_pin_agpr`; a stock compiler or soft-pin mode
is not a replacement for the validated hard-pin compiler. These untracked
compiler patches are required reproduction material, not disposable experiments.

The original build deletes outputs in its chosen build directory. The final
build now refuses an existing direct-child build name, eliminating this
relocation hazard. The original `gate.py` finds source at
`build.parent / "tmpl.hpp"`, so keep that source/build relationship unless the
gate is deliberately adapted.

The inherited `abba.sh` is not standalone: it references sibling candidates
and uses an old candidate tag. Its old `correctness.sh` hardcodes the long
historical executable under `build/` and covers only four small exact-K64
cases. Do not promote these scripts unchanged into the final validation suite.

## Provenance and measured evidence

The current formal template independently hashes to:

```text
c44276cd5df57755e05a26433452a990f9c13da43afedf4e78eb7d02886a0669
```

The original and recovery linked ISA were independently normalized from their
objdump instruction lines (remove address/encoding comments and trim) and both
hash to:

```text
f77e1b4bad73e582b4916a9c03b0cc7f161366420ee06f38cd85c28934f78bb6
```

All four historical source hashes, the dirty root-common hash, and each
original/recovery executable, CO and raw ISA hash are recorded in the JSON
plan. Distinct raw build hashes are expected; both linked instruction streams
match exactly.

Keep only the correctly attributed after4 performance evidence:

- `results_vs_wrap_r4_gpu7.*`: +1.4703%, 4/4.
- `results_vs_wrap_r8_gpu7.*`: +1.3656%, 8/8.
- `results_vs_prepared_v0_r8_gpu7.*`: +0.8968%, 8/8.

The inherited `results_vs_exact_k64_wrap_8192_*` files describe prepared V0,
not after4. Do not relabel them as final-package results.
`four_wave_c_agpr_tail_split2_sfa_hybrid_wait6_v1` is a host-prepacked reference,
not a replacement for the required row-major/no-host-repack formal kernel.

The recovery directory's `local_half_canonical_v1_*` manifests name an
after4-derived four-wave candidate. Those files are not the mistaken
eight-wave recovery run. Their provenance stays together in the archive.

## References that need an archive map

No retained tracked source/build script was found to require these old
four-wave directories to build the new final package. Retained historical
references remain in the dirty tracked optimization log and compiler pin
documentation; preserve those texts and provide the old-to-archive map.

The retained mixed
`four_wave_vs_eight_wave_single_output_counter_diag/run.sh` points
`FOUR_EXE` to the old wait6 directory. Moving wait6 makes that historical
script's default path unavailable; rerunning it requires explicit restoration
or a supplied reference path. This is not a final-build dependency and should
not be silently rewritten or rerun during cleanup.

Historical sources already span the old `variants/` and quarantine trees,
often via relative includes. A verified archive preserves evidence, but does
not by itself make every relocated historical script runnable. Preserve
relative path names and an explicit restoration map.

## Execution gate

The parent should execute cleanup only after completing the final package's
build, strict source/ISA checks, host ABI/contract audit and numerical suite.
Recheck the plan's exact targets and Git boundary immediately beforehand.
Create and verify a recoverable archive plus SHA256 inventory, then move/remove
only those exact audited targets according to the parent's authorized cleanup
workflow. If state changed or verification fails, retain the originals.

