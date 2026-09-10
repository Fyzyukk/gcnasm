# Postrelease target native synchronization admission

CPU-only audit: PASS for the exact target image in
`prototype_scale_f4_qhalf_postrelease_20260910`. The generic image has a scalar
spill and was not opened or admitted. This is not a performance promotion.

`check_f4_qhalf_postrelease_target_sync.py` completed with 26 native mutations,
four machine mutations, and six event mutations rejected. The fresh native
event checker is pinned to SHA-256
`eaf01706892be0a2e6befee9603186b1ad6570a634bac6b4a438f8ce9c6655b9`.

The hot gather at assembly line 1368 now follows phase-1 MFMA20's common
VM0/LGKM0/barrier. It is **not** admitted by that earlier wait: all 202
conservative tracking states reach the next phase-2 VM0 at line 1595, with
four or twelve younger matrix DTLDS loads, before touching the pending raw
bank. The ordered event model checks old pair2 publication, release, then new
gather, including the independent tile-1 gather. Omitting the next phase-2
wait, reversing issue/load, or deleting tile-1's gather is rejected.

Other results: 105 DS paths / 1117 states; 105 scale-tag paths / 1328 states;
1805 whole-kernel EXEC states; all seven transpose trees; 256 MFMA, 192 matrix
b128 reads, eight scale heads, nine barriers, and 71 waits. The cold/native
prefix through line 1350 is identical to the admitted alignall target.

Fresh `.s` / decoded `.isa` / ELF `.text` correspondence covers all 1805
instructions, 43 branches, and 12588 bytes. Resources are 252 VGPR, 106 SGPR,
159744 LDS, zero scalar/vector spills, scratch, and AGPR.

Artifact SHA-256:

| Artifact | SHA-256 |
| --- | --- |
| Header | `05f7e9bbfa51f784c465e66e68e3971b4da42fc29760272cd1036cfdc809b6ac` |
| Target assembly | `c548e5c255a2575cbf18557867ea47d648903bc64d056f4357c353652733aee0` |
| Target executable | `f0e7f129033f3c5a94e81a4357a52e12d8a1510093e940b63be3f343d6d03e83` |
| Target device ELF | `d7855a662fc2698335ee835c9b1555f0433c6984814e2387f3b72675792e38fb` |
| Target disassembly | `d1cbef0767d8d62179c44081d4eb7babb47818380c056c917654fbb0224941f5` |
| Target notes | `fbb9af8cbcbb5f48cbd0b512426429022194a92fc6f9b2b0cf3eceaf2374a039` |

Supplemental event enumeration covers K-tiles 4..512 step 4 and two output
tiles; this does not authorize any other binary, generic image, or shape.
No GPU query, compiler, assembler, benchmark, or profiler was run by this audit.
