# Q-half post-release prefetch: CPU, source and target-native gates

2026-09-10. **Q-half composition PASS, source binding PASS, target native
address/events PASS. Generic remains resource-rejected.** This reviewer only
read files and ran CPU checks; no builds, GPU queries or GPU launches.
Root must combine the separate target sync/EXEC/raw gate and resource gate
before target-only hardware tests. No performance result is asserted here.

Candidate: prototype_scale_f4_qhalf_postrelease_20260910.
Header SHA-256:
05f7e9bbfa51f784c465e66e68e3971b4da42fc29760272cd1036cfdc809b6ac.
The snapshot remains alignall
d654e9aef97c45e58ef986bcdb7c6003824ed8a0a71a5dc3583f6bc3a70ce800.

The complete two-hunk source change disables the old PF1 call for F4, then
adds an independent phase1 load with j=(tile+7)>>2 immediately after the
active position10 VM0/LGKM0/barrier/scheduler boundary and before B prefetch.
The scalar epoch guard and complete final-voffset sentinel are unchanged.
Tile1's j2 load is not nested in the skipped old pair2 publication. Cold
bootstrap, layout, publications, consumer addresses and source waits remain.

## CPU and source checks

    PYTHONDONTWRITEBYTECODE=1 python3 -B 8_wave_local_scale_direct/analysis_scale_f4_diagonal_20260909/check_f4_qhalf_postrelease.py
    PYTHONDONTWRITEBYTECODE=1 python3 -B 8_wave_local_scale_direct/analysis_scale_f4_diagonal_20260909/check_f4_qhalf_postrelease_source.py

The composition checker passes **9 tests / 12.407 s**, SHA-256
d34ee761789ee0ebb4c17ea778d65f4f636b03e0ab4dce23b08f758dd181dfa4.
It inherits all seven frozen post-release tests unchanged, replacing only
a private model's actual producer address with Q-half and consumer image
with the aligned-prebase implementation. Two extra tests bind frozen
dependencies, compare the full Q-half ownership/byte image and reject a
dropped producer Q-half twist. Two continuous outputs, raw4 lifetime,
all unchanged LDS/release events, t1, next-tile VM0, tails and boundary
negatives pass. Event coverage remains Ktiles multiples of four through 2048.

The source binder passes **4 tests / 0.227 s**, with **12 no-hash negatives**,
SHA-256
039a262cb62b1d47df8de49eb27d1f8374d932dba4b1c0fd1ff9fc58ef56a762.
It binds header/snapshot plus host/common/kernel identities, reverses the
exact two-hunk token delta, checks active position10 placement and F4
configuration isolation, and compares the actual new phase/epoch formula
with the CPU proof. The unused old loader lambda is still present in source,
but PF1 is disabled and all alternative PF sites are excluded by F4's gate.

## Target-only native incremental checks

    PYTHONDONTWRITEBYTECODE=1 python3 -B 8_wave_local_scale_direct/analysis_scale_f4_diagonal_20260909/check_f4_qhalf_postrelease_target_native.py

**4 tests PASS / 0.284 s**, including **12 no-hash native negatives**.
Checker SHA-256:
eaf01706892be0a2e6befee9603186b1ad6570a634bac6b4a438f8ce9c6655b9.

    target/kernel.exe f0e7f129033f3c5a94e81a4357a52e12d8a1510093e940b63be3f343d6d03e83
    target/kernel.dev d7855a662fc2698335ee835c9b1555f0433c6984814e2387f3b72675792e38fb
    target/kernel.s   c548e5c255a2575cbf18557867ea47d648903bc64d056f4357c353652733aee0
    target/kernel.isa d1cbef0767d8d62179c44081d4eb7babb47818380c056c917654fbb0224941f5

Metadata remains 252 VGPR, 106 SGPR, zero all spills/scratch/AGPR and 159744
LDS bytes. Generic has one scalar lane spill and is excluded, exactly as in
the preceding alignall checkpoint. The new checker does not open generic.

This is an incremental audit, not a repetition of unchanged layout math.
It pins the old admitted assembly/checker and proves exact prefix equality
through phase1's pair2 publication, plus exact suffix equality from phase3
publication through all tails/final/output boundaries. It rebinds the fresh
entry/LUT/base/producer/consumer instruction slices without rerunning the
entire old formula census.

The changed native portion is checked explicitly:

- BB30 executes existing VM0/LGKM0 and barrier, then increments s95=j and
  computes s49=b+8, checks base(j)<L, and skips the new gather when invalid.
- BB31 is byte-for-byte instruction text identical to the old BB35 gather
  dependency slice: same complete sentinel, unsigned comparison and literal
  soffset zero. The actual gather is now at assembly line 1368.
- B prefetch starts after the gather. Its temporary s12 becomes s22 so the
  newly created s[12:13] allow mask remains untouched until phase3 pair0.
  That local scalar rename is matched exactly, including all uses.
- The next actual VM0 is phase2's retained release at line 1595. There are
  exactly 32 MFMA instructions after the new gather and before that VM0:
  twelve remaining in phase1 plus twenty in phase2. This is an instruction
  interval, not an elapsed-cycle or speedup claim.
- The three total raw gather sites, descriptor words, seven write2 chains,
  cached heads and eight literal read phases remain bound. No hot SMEM or
  duplicate old phase2 gather appears.

The exported native_events(tile, tiles) is a freshly instruction-bound
scalar formula, not a general CFG interpreter. Ordered same-tile events:

    t1:  load j2
    t5:  issue pair2(j2), then load j3
    t53: issue pair2(j14), then load j15

The publisher precedes the common release; the new load follows it. Every
tile at Ktiles multiples of four through 512 matches the independent
post-release event model, including the scalar-dead tail gather. Native
raw readiness, EXEC restoration, DS tag correctness and machine-image
correspondence remain the parallel ISA review's responsibility.

Negative controls cover induction, j formula, guard polarity/bound,
allow-mask clobber through B prefetch, gather row bits/sentinel/soffset,
cold-pair exclusion, tail predicate and either missing common wait/barrier.
All fail without consulting the artifact hash gate.

This target-limited review preserves the root's 8192³ hardware scope. Passing
algebra over additional tile counts does not admit the generic image or
claim arbitrary-shape correctness.
