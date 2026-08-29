#!/usr/bin/env python3
"""Clock-normalized efficiency, the one number comparable across machines.

    eff = (GEMM FLOP/cycle) / (pure-MFMA FLOP/cycle)

Both terms use the BUSY-ONLY mean SCLK measured during that same workload, so
DVFS state, power cap, and boost behaviour all cancel.  Two machines running
the same kernel should agree on eff even if their PFLOPS differ.

    ./eff_calc.py <mfma_PFLOPS> <mfma_MHz> <gemm_PFLOPS> <gemm_MHz> [label]
"""
import sys
mp, mc, gp, gc = (float(x) for x in sys.argv[1:5])
label = sys.argv[5] if len(sys.argv) > 5 else ""
mfc = mp * 1e15 / (mc * 1e6)
gfc = gp * 1e15 / (gc * 1e6)
print(f"{label}")
print(f"  pure MFMA : {mp:.3f} P @ {mc:.0f} MHz -> {mfc/1e6:.3f} MFLOP/cycle")
print(f"  GEMM      : {gp:.3f} P @ {gc:.0f} MHz -> {gfc/1e6:.3f} MFLOP/cycle")
print(f"  eff       = {gfc/mfc:.3f}")
