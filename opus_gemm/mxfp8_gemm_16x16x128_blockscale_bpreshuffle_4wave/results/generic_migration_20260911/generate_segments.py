#!/usr/bin/env python3
"""Hoist panel refresh work out of the steady MFMA loop and port row stores."""
import json
from pathlib import Path
from generate_streaming import HERE, ROOT, WORK, generalize, once, record


def segmented(source):
    start = source.index("#pragma unroll 8\n    for (tile = 0; tile + 2 < loops; ++tile) {")
    opening = source.index("{",start)
    depth = 1
    end = opening+1
    while depth:
        depth += (source[end] == "{") - (source[end] == "}")
        end += 1
    body = source[opening+1:end-1]
    body = once(body,"        refill_scale_panel(tile + 1);\n","")
    body = "".join("    "+line if line.strip() else line for line in body.splitlines(True))
    replacement = """    const int main_end = loops - 2;
    int panel_end = main_end < panel_mask ? main_end : panel_mask;
    while (tile < main_end) {
#pragma unroll 8
        for (; tile < panel_end; ++tile) {""" + body + """        }
        if (tile < main_end) {
            // The next scale read crosses a panel boundary. Current matrix
            // and scale operands stay resident while the panel is replaced.
            refill_scale_panel(tile + 1);
            const int next_panel_end = panel_end + T::SCALE_PANEL_K_TILES;
            panel_end = next_panel_end < main_end ? next_panel_end : main_end;
        }
    }"""
    return source[:start]+replacement+source[end:]


def fence(source):
    begin = source.index("    // Consume the final resident")
    pos = source.index("    v_a[1] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 1));",begin)
    source = source[:pos] + "    if constexpr (T::OUTPUT_BF16) {\n        s_waitcnt_vmcnt(0_I);\n    }\n" + source[pos:]
    source = source.replace("// Consume the final resident tile with the original direct-store\n    // epilogue. Retain its conservative A1 and B1 reloads.", "// Consume the final resident tile and stage completed BF16 rows in LDS.")
    return source


if __name__ == "__main__":
    source = (WORK/"stream64_lds_fence/tmpl_generic.hpp").read_text()
    config = json.loads((WORK/"stream64_lds_fence/candidate.json").read_text())["config"]
    record("stream64_segmented",segmented(source),"stream64_lds_fence",dict(config,loop_style="panel_segments"))
    previous_work = Path((HERE.parent/"tile1_target32_round2_20260911/work_path.txt").read_text().strip())
    rows = fence(generalize((previous_work/"lds_rows4_vec4/tmpl.hpp").read_text()))
    record("stream64_rows4",rows,"preserved lds_rows4_vec4",dict(config,output_rows=True,store_delay=4,lds_vector_elements=4))
    record("stream64_rows4_segmented",segmented(rows),"stream64_rows4",dict(config,loop_style="panel_segments",output_rows=True,store_delay=4,lds_vector_elements=4))
