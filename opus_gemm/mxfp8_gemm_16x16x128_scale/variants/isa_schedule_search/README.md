# Linked-ISA schedule search

This directory keeps clang23/gfx950 scheduling experiments isolated from the
unified-scale source template.  `build.sh` rebuilds the p1/no-setprio kernel
with `/opt/rocm-llvm23-46fcb339/bin/clang++`, emits editable device assembly,
assembles each candidate, and replaces only the executable's device image.

The initial candidates preserve the complete non-NOP instruction multiset:

- `b1_swap`: swap the two independent MFMAs immediately before each steady
  B1 DS-read quartet, increasing the distance to the nearest VGPR WAR.
- `b1_war3`: apply that swap only to the three quartets where the first DS
  read immediately overwrites the latest MFMA SrcA; leave the two quartets
  that clang23 already schedules at distance two or three unchanged.
- `b1_front1`: move the first independent post-read MFMA before the quartet.
- `b1_split2`: place one independent MFMA before each pair of B1 DS reads.
- `ctrl_fill`: replace existing MFMA-spacing NOP slots with the producer
  `s_andn2`/`s_add`/`s_cmp` operations and remove those operations from the
  post-barrier control path.
- `vadd_gap`: move the single `v158` address update past an independent MFMA
  so it no longer immediately overwrites an XDL source VGPR.
- `vmem_imm_offset`: fold each compact producer's tile offset into the eight
  buffer-load immediate fields, removing one scalar add and allowing the first
  load to issue earlier.
- `setup_resource`: move the compact producer's `s18:s19` resource restore
  into two existing VMEM m0-latency slots from the preceding producer stage.
- `setup_m0`: move the compact producer's first m0 setup into the final
  available MFMA-spacing slot before its barrier.
- `ctrl_full_setup`: keep the proven control hoist, move the compact m0 setup
  into its third MFMA-spacing slot, and use two preceding VMEM latency slots
  for `s18:s19`; the post-barrier producer path then starts with two branches,
  one offset add, and the first load.

All candidates use the unified-scale host and `MXFP8_OUTPUT_B1_HANDOFF_PAIRS=1`.
