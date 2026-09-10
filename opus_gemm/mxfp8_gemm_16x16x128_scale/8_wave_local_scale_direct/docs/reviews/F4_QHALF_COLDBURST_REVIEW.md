# Q-half cold-burst: incremental source and dual-image address/event admission

2026-09-10. **Source binding PASS; target and generic native address/events
PASS.** This reviewer used CPU-only source/assembly/artifact checks. No build,
GPU query, GPU execution, ISA patch or resource-gate change was performed.
The independent sync/EXEC/raw/transpose/machine-image gate must be combined
with these results before root-owned hardware validation. This report makes
no GPU correctness, timing, generic-shape performance or promotion claim.

Candidate: prototype_scale_f4_qhalf_coldburst_20260910.
Frozen header SHA-256:

    fd9149c9d069caffda6e19e68e9b6f971bbb2533286b869ea50a3274c4982446

The base/source snapshot is Q-half alignall:

    d654e9aef97c45e58ef986bcdb7c6003824ed8a0a71a5dc3583f6bc3a70ce800

## Source and existing CPU proof

The exact reversible token delta contains only two cold-bootstrap regions:
replace the j=-2,-1,0 serial load/wait/publish loop with three named raw4
banks; keep j1 in the original queue; move the first six publications after
the unchanged common matrix VM0. There are four cold gathers, original matrix
A0/B0/A1/B1 source calls, common VM0, then eight publications in j=-2,-1,0,1
order, pair0 before pair2. Every cold tag remains one. The original three
scheduling boundaries move with their corresponding publishers, and final
LGKM0/workgroup barrier remains unchanged.

All hot gathers/publications/guards, current-phase driver, Q-half layout,
aligned consumer prebases, complete final-offset OOB sentinel and output
boundary releases are unchanged. This candidate does not include post-release
hot prefetch. Host/common/kernel.cc, build.sh and static checker/policy files
are byte-identical to alignall.

Source checker:

    PYTHONDONTWRITEBYTECODE=1 python3 -B 8_wave_local_scale_direct/analysis_scale_f4_diagonal_20260909/check_f4_qhalf_coldburst_source.py

Four tests and twelve no-hash mutation controls PASS, 0.095 s.
Frozen SHA-256:

    ca853c84dd212686ffcd8b47663a5b44586695a1d7146feaa1452969f8f26453

The checker binds the already independently rerun 33-test burst model
(a6a8261f065cbf1b7b2743440c05ae4ac41b3f10a095f6c3f880d96d03ae7928),
extracts the new source events, and bridges one bootstrap to the model.
It does not repeat the unchanged full byte-layout proof.

## Fresh target and generic address binding

Native checker:

    PYTHONDONTWRITEBYTECODE=1 python3 -B 8_wave_local_scale_direct/analysis_scale_f4_diagonal_20260909/check_f4_qhalf_coldburst_native.py

Six tests PASS, 1.682 s, including twenty-eight no-hash native mutations per
image. Baseline structural validation passes before the negative controls.
Frozen SHA-256:

    e429070d9dfc3e95e0c783256f028a9852a7aec7e35cc61d1af2a1624af1590c

Both images retain 254 VGPR, 106 SGPR, 159744 LDS bytes and zero vector/scalar
spills, scratch and AGPR. Passing generic here is a fresh review of this
generic image; it does not admit the resource-rejected alignall generic.

The instruction-bound checks cover:

- Selected SFA/SFB global pointers, target constant stride/batch arithmetic,
  generic independent runtime stride and batch-stride fields, A-only output
  row advancement, immutable resource low/high words and selected stride.
- All five gather sites: four independent cold banks and the unchanged
  hot raw4 bank. The descriptor is s[12:15], scalar offset is literal zero,
  and the final complete byte offset is replaced by 0xffffffff when invalid.
- Cold j=-2/-1 uses unsigned Q-2 for both the validity predicate and the
  16-byte offset. Cold j0/j1 uses Q. Generic performs a full MAD before
  cndmask; its high addend contains nonzero LUT bits, which do not change
  the low32 byte result. MAD carry uses s[4:5], not either cold predicate.
- The four fresh constant-folded producer LUT/address chains. Negative-j
  slot masks exclude SFA base bit12 and permit the target OR. For j0/j1,
  fixed base plus slot is ADD, not OR; the remaining role/row/kg fields
  are disjoint from that sum. Generic ADD3 and target optimized expressions
  match every cold Q-half producer address for all waves/lanes/pairs.
- Eight cold write2 sites, original order, pair2 base+512 and literal
  word offsets (0,2), with four negative-Q masks followed by four Q masks.
  Predicate definitions survive to each use, and every region restores EXEC.
  Masks are closed under lane XOR16/XOR32. Full payload transpose/readiness
  verification remains the independent ISA checker's responsibility.
- Fresh hot Q-half producer chains, cached SFA/SFB consumer prebases, bit6
  XAD inversion, all eight literal consumer phase sites and hot epoch guards.
  The inherited mathematical layout functions are hash-bound and rebound to
  these new instructions; no old generic assembly is used for admission.

Cold address/offset comparison covers both kinds, every role/lane, both
outputs, all four cold j values, and target/generic strides and tails.
Hot raw/event equivalence covers Ktiles multiples of four through 512.
The native event transcription remains a reviewed scalar formula, not an
arbitrary CFG emulator.

## Timing and event boundaries

The exported APIs for the independent synchronization checker are:

    HASHES["target" / "generic"]["exe" / "dev" / "s" / "isa"]
    validate_native(name, assembly)
    native_events(tile, tiles)
    cold_events()

Cold events are ordered tuples:

    ("load", -2, None), ("load", -1, None),
    ("load", 0, None), ("load", 1, None),
    ("wait", None, None),
    ("issue", -2, 0), ("issue", -2, 2),
    ("issue", -1, 0), ("issue", -1, 2),
    ("issue", 0, 0), ("issue", 0, 2),
    ("issue", 1, 0), ("issue", 1, 2)

Here wait means common VM0 completion of all four raw banks before any
publication. It does not claim every transpose starts after that VM0:
target VM6 / generic VM7 permits the first transpose to begin earlier.
The independent ISA review checks the exact younger-request ordering.

Hot events retain the original phase2/MFMA2 load, phase3 pair0 and
phase1/tile>=5 pair2 schedule. The native hot gather follows two MFMAs
from the actual phase2 scale-read head. Counting from the surrounding
basic-block label is wrong because that block also contains twelve final
MFMAs of the preceding tile.

All cold publishers precede the final LGKM0/barrier. Existing common hot
releases and between-output release remain bound. Logical raw capacity
is16 only during cold bootstrap, then returns to4. Four cold source VM0
events becoming one does not imply fewer static native wait sites:
the target/generic counts remain73/75.

## Exact artifacts

| Image | Artifact | SHA-256 |
| --- | --- | --- |
| target | kernel.exe | 5d6d6c4a96905dff1b26ac506373cbecfd3cdeea8f1ae6eea26786e4377b5443 |
| target | kernel.dev | da56898195d688e162666d0491caf462ba8add367cc2bfc38c93f3ccdcacaf24 |
| target | kernel.s | ba88f229d2de53d31a2060ed472790ce279e3c3bdab36de528c30b543ddea637 |
| target | kernel.isa | 8b55ed3a187d3af3859541266359d19620b7275018bfb9098c3dec0578a13863 |
| generic | kernel.exe | a2e2feb5996179d2c02121568578f09c76055ac8b7335055958015ba6ea23dfb |
| generic | kernel.dev | 34e7da6dad0b5d2d1780df74814b60192e638de498ad592f288aa6e48f8752df |
| generic | kernel.s | 2e30fec6965f83ec323a9170e58b9afc25061a1c5316fbbac3b74b1d0bfa2632 |
| generic | kernel.isa | 7ba0e5337f788663e0c2b829837e0415043a738eb440a43aad945a440b0fda36 |

These hashes bind the reviewed artifacts. Actual assembly/disassembly/ELF
correspondence and full sync/raw checks are separately reviewed, not inferred
from this table. Hardware validation and any performance decision belong to
root and must use the existing fixed benchmark contract.
