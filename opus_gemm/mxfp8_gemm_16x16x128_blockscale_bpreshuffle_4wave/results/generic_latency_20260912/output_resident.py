#!/usr/bin/env python3
"""Use the freed BF16 registers to keep final operands resident."""
from make_candidates import WORK, record, replace_n


for parent in ("output_pingpong_132", "output_pingpong_136", "output_pingpong_xor128"):
    source = (WORK / parent / "tmpl_generic.hpp").read_text()
    prefix, tail = source.split("    // Consume the final resident tile", 1)
    tail = replace_n(tail, "    v_a[1] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 1));",
                    "    if constexpr (!T::OUTPUT_BF16) v_a[1] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 1));")
    tail = replace_n(tail, "    v_sfb[1] = load_sfb_dword(loops - 1, 1);",
                    "    if constexpr (!T::OUTPUT_BF16) v_sfb[1] = load_sfb_dword(loops - 1, 1);")
    import json
    config = json.loads((WORK / parent / "candidate.json").read_text())["config"]
    config.update(final_bf16_operands_resident=True, final_fp32_operands_unchanged=True)
    record(parent + "_resident", prefix + "    // Consume the final resident tile" + tail, config)

parent = "output_pingpong_xor128"
source = (WORK / parent / "tmpl_generic.hpp").read_text()
prefix, tail = source.split("    // Consume the final resident tile", 1)
tail = replace_n(tail, "    v_a[1] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 1));",
                "    s_waitcnt_lgkmcnt(0_I);\n    v_a[1] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 1));")
config = json.loads((WORK / parent / "candidate.json").read_text())["config"]
config.update(final_a1_reload_retire_prior_lds=True)
record(parent + "_ordered", prefix + "    // Consume the final resident tile" + tail, config)
