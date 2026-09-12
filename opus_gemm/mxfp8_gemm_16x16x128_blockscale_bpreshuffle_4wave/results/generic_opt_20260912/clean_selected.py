#!/usr/bin/env python3
"""Prepare one measured candidate for production; require ISA equality after building."""
import argparse
import difflib
import json

from make_candidates import HERE, WORK, once, record


def clean(source):
    source = once(source, """    // Seed the operand register roll. B-half0, SFB0, and both SFA
    // dwords for the first K tile are loaded once here.  SFA0 is later reused
    // in place, while SFA1 is carried in a dedicated next-tile VGPR.
""", """    // Seed all four matrix halves and scale dwords for K0. The main
    // and penultimate blocks prefetch each next-K SFA/SFB pair in one b64
    // read, then install its halves after the last current-K consumers.
""")
    old = """        // Start panel SFA1 for tile t+1 in a dedicated VGPR; the remaining
        // ten c01 plus sixteen c11 MFMAs cover this immutable panel read.

        // The current tile no longer consumes B-half0 or SFB0. Read both
        // next scale halves in one LDS b64; retain current SFB1 through c11.
        // B-half0 was read in four pairs at MFMA32/34/36/38; its values
        // are retained for the next K tile.
"""
    assert source.count(old) == 2
    source = source.replace(old, """        // Install the low dword of the SFB pair prefetched after MFMA20.
        // Keep current SFB1 through C11. B0's four operand pairs have now
        // rolled to the next K block at MFMA32/34/36/38.
""")
    old = """        // SFA0 is dead after the final c01 MFMA.  Reuse the same VGPR for the
        // next tile's SFA0 now, then hide this LDS read under all sixteen c11
        // MFMAs.  The true register anti-dependency prevents the read from
        // moving above the last current-tile SFA0 consumer.
"""
    assert source.count(old) == 2
    source = source.replace(old, """        // C01 has consumed current SFA0. Install the low dword of the
        // SFA pair prefetched after MFMA2; keep current SFA1 through C11.
""")
    source = once(source, """    // Each half covers all output rows and 128 contiguous columns.
    // The first half is published before its copy overlaps second-half MFMAs.
""", """    // Publish each completed 128x128 quadrant after MFMA20/36/52/64.
    // Eight coalesced 16-byte copies per thread cover one quadrant. All
    // four quadrants belong to this workgroup's single 256x256 output tile.
""")
    marker = """    if constexpr (T::OUTPUT_BF16) {
        // Publish only the completed output quadrant before copying it.
        __builtin_amdgcn_sched_barrier(0);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);
        copy_output_quarter(1, 0, 0);
"""
    source = once(source, marker, marker.replace(
        "        // Publish only the completed output quadrant before copying it.\n",
        "        // C10 LDS writes must finish before publication. Prior global\n"
        "        // C00 stores are independent and may remain in flight here;\n"
        "        // all matrix loads retired before output reused their LDS.\n"))

    # Preserve all 64 input-only empty asm anchors and their order. A later
    # linked-instruction comparison is mandatory before promotion.
    definitions = ["// These input uses place AGPR zeroing under outstanding prologue loads.",
                   "#define MXFP8_MATERIALIZE_C_QUADRANT(PREFIX) \\"]
    for fragment in range(16):
        suffix = "; \\" if fragment != 15 else ""
        definitions.append(f'    asm volatile("" : : "a"(PREFIX##_{fragment})){suffix}')
    for half in ["00", "01", "10", "11"]:
        old = "".join(f'    asm volatile("" : : "a"(c{half}_{fragment}));\n' for fragment in range(16))
        source = once(source, old, f"    MXFP8_MATERIALIZE_C_QUADRANT(c{half});\n")
    source = once(source, "#undef MXFP8_PIN_C\n", "#undef MXFP8_PIN_C\n\n" + "\n".join(definitions) + "\n")
    source = once(source, "    MXFP8_MATERIALIZE_C_QUADRANT(c11);\n",
                  "    MXFP8_MATERIALIZE_C_QUADRANT(c11);\n#undef MXFP8_MATERIALIZE_C_QUADRANT\n")
    return source


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("candidate")
    parser.add_argument("--name", default="generic_tile1_opt_20260912")
    args = parser.parse_args()
    metadata = json.loads((WORK / args.candidate / "candidate.json").read_text())
    audit = json.loads((HERE / "audits" / (args.candidate + ".json")).read_text())
    assert audit["status"] == "PASS"
    original = (WORK / args.candidate / "tmpl_generic.hpp").read_text()
    source = clean(original)
    record(args.name, source, metadata["config"])
    for directory in [WORK / args.name, HERE / "candidate_patches" / args.name]:
        path = directory / "candidate.json"
        data = json.loads(path.read_text())
        data.update(selected_from=args.candidate, cleanup_requires_instruction_equality=True)
        path.write_text(json.dumps(data, indent=2) + "\n")
    patch = "".join(difflib.unified_diff(original.splitlines(True), source.splitlines(True),
                                        fromfile="a/tmpl_generic.hpp", tofile="b/tmpl_generic.hpp"))
    (HERE / "candidate_patches" / args.name / "cleanup.patch").write_text(patch)


if __name__ == "__main__":
    main()
