# Q-half cold-burst native synchronization review

Status: complete native synchronization admission PASS for both frozen images,
including final independent source/address/event binding and negative controls.

Scope: `prototype_scale_f4_qhalf_coldburst_20260910`, target and generic native
images. The audit is CPU-only: no GPU query/execution, build, assembly, candidate
edit, or gate relaxation. Source header SHA-256:
`fd9149c9d069caffda6e19e68e9b6f971bbb2533286b869ea50a3274c4982446`.

Both images have 254 VGPR, 106 SGPR, 159744 LDS bytes, and zero scalar/vector
spills, scratch/private bytes, and AGPR. Artifact/helper hashes and resource
metadata were rechecked after resuming. This is a native safety review, not
GPU correctness or performance promotion, and not a general-shape guarantee.

## Fresh native evidence

| Check | Target | Generic |
| --- | --- | --- |
| Instructions / scalar branches | 1852 / 44 | 1866 / 47 |
| Entire ELF `.text` matched to `.isa` and `.s` | 12928 bytes | 13012 bytes |
| DS paths / states | 103 / 1110 | 103 / 1111 |
| Scale-tag paths / states | 103 / 1307 | 103 / 1308 |
| Whole-kernel EXEC states | 1852 | 1866 |
| Static waits / barriers | 73 / 9 | 75 / 9 |

Every image has eight scale heads, 256 MFMA, 192 matrix b128 reads, eight cold
masked publishers, and three hot/tail full-EXEC publishers. All eleven complete
transpose expression trees pass, including destructive aliases, source order,
and the 44 permutations. Both swaps and their input permutations are full
EXEC; only the last two lane-local permutations and store may be cold-masked.
All eight save/restore regions restore full EXEC before later collectives.

| Raw cohort / physical words | Target load → first sufficient wait (younger loads) | Generic load → first sufficient wait (younger loads) |
| --- | --- | --- |
| Cold -2 / `v8..11` | 615 → 632, VM6 (6) | 633 → 652, VM7 (7) |
| Cold -1 / `v4..7` | 616 → 642, VM0 (7) | 634 → 662, VM0 (8) |
| Cold 0 / `v0..3` | 629 → 642, VM0 (3) | 649 → 662, VM0 (3) |
| Cold 1 / `v128..131` | 631 → 642, VM0 (2) | 651 → 662, VM0 (2) |
| Hot / `v128..131` | 1575 → 1666, VM0 (0) | 1596 → 1687, VM0 (0) |

The first cold transpose starts after the partial wait; every cold publication
follows the common VM0. All eight matrix DTLDS loads are also drained before
the cold release. Pending raw words cannot be read or overwritten; completed
but unpublished cold words retain their exact cohort/pair identity. The hot
schedule remains MFMA2 gather → MFMA20 VM0, not postrelease. Raw pair2 remains
intact across tail pair0 reuse until its final publisher.

Each image rejects 38 fresh-text native mutations and four machine-consistency
mutations. Important added controls weaken VM6/VM7 by one, remove it, read the
second cohort too early, remove common VM0, and independently overwrite each
cohort's completed-but-unpublished pair2. Native negatives run the semantic
checker, not whole-file hash or line-count rejection. Machine negatives change
encoded wait bytes, decoded wait operands, branch destination, and SFB address.

## Final binding and handoff

The full standalone entry completed after binding the final native reviewer
and strengthening its direct dependency hashes. Nine cold and four hot event
mutations were rejected. The lifetime model keeps four simultaneous cold raw4
banks (raw16 peak), drains them at eight publishers after common VM0, then uses
only hot raw4. Across two output tiles and K-tiles 4..512 step 4, no live raw
bank is overwritten or crosses an output boundary. K64 totals are 36 gathers
and 72 publications; K68 totals are 40 and 80. This supplemental enumeration
does not establish other-shape hardware correctness.

The independent source checker was also rerun: four tests / 12 negatives PASS.
The independent native address/event checker was rerun: six tests / 28 no-hash
negative controls per image PASS. Its fresh constant-folded addresses retain
ADD for the overlapping SFA base/slot bit at cold j0/j1; no blanket OR
assumption is used. Phase2 scheduling is counted from its own scale head.
No candidate, binary, or fixed static gate was changed to obtain these passes.

| Frozen review file | SHA-256 |
| --- | --- |
| `check_f4_qhalf_coldburst_native_sync.py` | `dee0c504af918a48c95aef8656a23d593f58a5eabeb1331075383db10af79ee1` |
| `check_f4_qhalf_coldburst_native.py` | `e429070d9dfc3e95e0c783256f028a9852a7aec7e35cc61d1af2a1624af1590c` |
| `check_f4_qhalf_coldburst_source.py` | `ca853c84dd212686ffcd8b47663a5b44586695a1d7146feaa1452969f8f26453` |

| Frozen artifact | SHA-256 |
| --- | --- |
| Target executable | `5d6d6c4a96905dff1b26ac506373cbecfd3cdeea8f1ae6eea26786e4377b5443` |
| Target assembly | `ba88f229d2de53d31a2060ed472790ce279e3c3bdab36de528c30b543ddea637` |
| Generic executable | `a2e2feb5996179d2c02121568578f09c76055ac8b7335055958015ba6ea23dfb` |
| Generic assembly | `2e30fec6965f83ec323a9170e58b9afc25061a1c5316fbbac3b74b1d0bfa2632` |

The sync checker additionally pins device ELF, disassembly, notes, source,
frozen DS/EXEC helper files, and the direct address/event dependencies.

```text
python3 -B 8_wave_local_scale_direct/analysis_scale_f4_diagonal_20260909/check_f4_qhalf_coldburst_source.py
python3 -B 8_wave_local_scale_direct/analysis_scale_f4_diagonal_20260909/check_f4_qhalf_coldburst_native.py
python3 -B 8_wave_local_scale_direct/analysis_goal2700_20260909/check_f4_qhalf_coldburst_native_sync.py
```

All three commands passed. Root retains responsibility for GPU correctness,
full output-hash comparison, interleaved measurements, and any promotion.
