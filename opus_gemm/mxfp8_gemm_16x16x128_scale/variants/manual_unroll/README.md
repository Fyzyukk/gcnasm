# manual_unroll -- hand-unrolled fork + ablation diagnostics

The `diag_*` kernels are DELIBERATELY INCORRECT: each neuters one wait, the
barrier, the global loads, or the C store to price what that construct costs.
Never ship one.  `diag23.sh` builds them with clang 23.

## Attribution on the clang 23 baseline (log 31.2)

| variant | P | vs retained |
|---|---:|---:|
| retained | 2.828 | -- |
| nowait (lgkmcnt open) | 2.840 | +0.4% |
| novmwait (vmcnt open) | 2.857 | +1.0% |
| noglobal | 3.373 | +19.3% |
| pure (also no C store) | 3.747 | +32.5% |

Deleting *every* wait is worth 1.0%: section 28's whole wait-elimination premise
is spent on clang 23, which already removed the six redundant `vmcnt(0)` that
clang 20 emitted (log 30.3).  `nobarrier` is -2.4% -- the barrier earns its keep.

`pure` at 3.747 P shows the skeleton allows 3 P; the gap is in the data path.
The C store's 11.1% is latency exposure, not bandwidth -- see log 31.4.
