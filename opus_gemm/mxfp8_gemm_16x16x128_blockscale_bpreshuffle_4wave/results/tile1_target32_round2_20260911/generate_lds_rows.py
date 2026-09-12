#!/usr/bin/env python3
"""Overlap final-K MFMA with BF16 conversion and output LDS writes."""
import re
from experiment_utils import WORK, record_candidate, replace_once

PARENT = "tail_a3_prefetch56"
parent = (WORK / PARENT / "tmpl.hpp").read_text()


def stage_rows(source, delay):
    start = source.index("    MXFP8_MMA_PAIR(0, 0, 0, v_a[0], v_b, c00_0", source.index("    // Consume the final resident tile"))
    prefix, body = source[:start], source[start:]
    quadrants = [("c00", 0, 0), ("c10", 1, 0), ("c01", 0, 1), ("c11", 1, 1)]
    for c, hm, hn in quadrants:
        old = f"    MXFP8_STORE_QUADRANT({c}, {hm}, {hn});"
        body = replace_once(body, old, "    if constexpr (!T::OUTPUT_BF16) {\n    " + old + "\n    }")
    matches = list(re.finditer(r"    MXFP8_MMA_PAIR\([^\n]+\);\n    sched_barrier_pairs_scale\(\);", body))
    assert len(matches) == 32
    edits = {}
    for quadrant, (c, hm, hn) in enumerate(quadrants):
        for row in range(4):
            site = min(64, quadrant * 16 + (row + 1) * 4 + delay)
            fragment = row * 4
            edits.setdefault(site, "")
            edits[site] += f"""

    // Stage this completed output row while later independent MFMAs execute.
    if constexpr (T::OUTPUT_BF16) {{
        const int soff = c_offset({hm}, {hn});
        MXFP8_STORE_AGPR_PAIR8({c}_{fragment}, {c}_{fragment+1}, {fragment});
        MXFP8_STORE_AGPR_PAIR8({c}_{fragment+2}, {c}_{fragment+3}, {fragment+2});
    }}"""
    for site, code in sorted(edits.items(), reverse=True):
        at = matches[site // 2 - 1].end()
        body = body[:at] + code + body[at:]
    return prefix + body


def vec4(source):
    source = replace_once(source, "mma, opus::make_tuple(kargs.stride_c, 1_I), p_coord_c);",
                           "mma, opus::make_tuple(T::OUTPUT_BF16 ? c_lds_pitch : kargs.stride_c, 1_I), p_coord_c);")
    old = """            g_c.template store<T::VEC_C>(cast<D_C>(ACC),                         \\
                gc_offsets[INDEX], soff, opus::number<0>{});                     \\"""
    new = """            s_c.template store<T::VEC_C>(cast<D_C>(ACC),                         \\
                gc_offsets[INDEX] + soff);                                      \\"""
    source = replace_once(source, old, new)
    start = source.index("#define MXFP8_STORE_AGPR_PAIR8(")
    end = source.index("#define MXFP8_STORE_QUADRANT(", start)
    macro = """#define MXFP8_STORE_AGPR_PAIR8(ACC0, ACC1, INDEX) \\
    do { \\
        MXFP8_STORE_AGPR_FRAGMENT(ACC0, INDEX); \\
        MXFP8_STORE_AGPR_FRAGMENT(ACC1, (INDEX) + 1); \\
    } while (false)
"""
    return source[:start] + macro + source[end:]


for delay, native_vec4 in [(0, False), (4, False), (8, False), (4, True)]:
    name = f"lds_rows{delay}" + ("_vec4" if native_vec4 else "")
    source = stage_rows(vec4(parent) if native_vec4 else parent, delay)
    record_candidate(name, source, dict(epilogue_row_store_delay=delay,
                     lds_fragment_elements=4 if native_vec4 else 8,
                     bf16_lds_epilogue=True, release_mfma=5,
                     tail_prefetch_schedule=[["a", 3, 56]], unified_initial_matrix_stages=[1]), PARENT)
