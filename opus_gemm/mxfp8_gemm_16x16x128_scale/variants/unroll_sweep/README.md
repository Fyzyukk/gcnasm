# unroll_sweep -- main K-loop unroll factor

Makes `#pragma unroll N` on the main K loop a controllable variable
(`MXFP8_MAIN_LOOP_UNROLL`, default 4 = ISA-identical to the retained build)
and sweeps it on clang 23.

    ./build.sh                 # one exe per factor + what the compiler did
    FACTORS="4 6" ./build.sh
    python3 ../dvfs_study/guard.py && ./bench.sh    # ABBA vs u4

## Result: the factor is not a lever

u4 stays. u6/u8 are noise (+0.03% over 8 rounds); u2 loses 5.2% to 64 VGPR
spills; u1/u3 are flat-to-slightly-negative.

## What it did find

u1 is the *unrolled-off* build -- 64 MFMA, VGPR 236, same shape as clang 20's
output -- and it reads 2.804 P, not the 2.436 P that section 29.6 predicted.
Holding unrolling fixed, clang 23 beats clang 20 by 15.0% (0.4514 -> 0.3925 ms);
unrolling itself is worth 1.0%.  Section 29's +16% was misattributed to
unrolling because unrolling was the visible side effect of changing compiler.

Mechanism (log section 30.3): clang 20 emits 6 `s_waitcnt vmcnt(0)` in the hot
MFMA span that clang 23 emits zero of -- the conservative direct-to-LDS alias
guard that section 28 tried and failed to remove by hand.  Also 255 fewer
`s_nop` and no scratch traffic (despite `vgpr_spill_count: 0` in both).
