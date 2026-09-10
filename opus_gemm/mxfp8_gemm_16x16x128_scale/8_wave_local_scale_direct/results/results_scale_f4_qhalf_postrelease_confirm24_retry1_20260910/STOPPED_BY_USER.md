# Postrelease N24 retry: stopped by user, not a completed confirmation

2026-09-10. The user requested organizing the 8-wave no-host-scale-reorder
schemes and stopping further runs. Root interrupted the benchmark with Ctrl-C
(exit130). This is the historical stop record; do not resume or append to this
directory. A later user request authorized new sessions, recorded separately
in [final validation](../../FINAL_VALIDATION_20260910.md).

- Planned: 24 rotating rounds, three labels (`base_a`, `base_b`, `postrelease`),
  72 formal observations in total.
- Recorded: 15 complete rounds, 45 formal observations in `results.tsv`.
  Each label has 15 observations; no round16 observation was recorded.
- Before-round16 process snapshot exists, but the full N24, final after-run
  ownership check and final summary were not completed.
- Pre-run full-hash logs are retained. Correctness evidence does not make the
  incomplete timing sequence a completed N24 confirmation.

This session is excluded from performance selection because confirmation is
incomplete. **User cancellation does not, by itself, establish GPU contention
or invalid machine timing.** The foreign-process interruption belongs to the
separate first attempt, not an asserted cause for this retry.

Preserve all raw records. Do not pool these observations with the first attempt
or N3 to manufacture a completed N24. No candidate was promoted. If the user
later resumes testing, use a fresh guarded session and result directory.

See [current scheme overview](../../8_WAVE_NO_HOST_SCALE_SUMMARY_20260910.md).
