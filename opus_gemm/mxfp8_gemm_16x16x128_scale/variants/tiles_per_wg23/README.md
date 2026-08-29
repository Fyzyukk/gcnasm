# tiles_per_wg23 -- OUTPUT_TILES_PER_WG on clang 23

Section 28.7 closed 8/16 as "no gain" on clang 20.  Re-run here because the
clang 23 ablations (log 31.2) showed global traffic is 18% of runtime, and this
knob halves A's re-read factor.

## Result: closed again, but the old reason was wrong

At 8192^3 the knob is catastrophic -- t8 is -31.7%, t16 is -65.8% -- and the
cause is visible in the launch config, not in traffic: this box has 256 CUs and
t4's grid.x is exactly 256.  t8 leaves half the CUs idle.

At a shape where the grid stays >= 256 (16384x16384x4096) all three values are
flat: 2.543 / 2.546 / 2.547 P.  Halving A's DRAM traffic buys nothing, so the
kernel is *not* DRAM-bound -- L2 absorbs the re-reads.  The "7.6 TB/s, near the
8 TB/s wall" estimate was wrong because it assumed every re-read reaches DRAM.

    ./build.sh                  # VALUES="2 4 8 16"
