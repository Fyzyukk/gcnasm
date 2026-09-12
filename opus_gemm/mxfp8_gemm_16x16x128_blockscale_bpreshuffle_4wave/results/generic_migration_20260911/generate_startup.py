#!/usr/bin/env python3
"""Hide generic scale-panel memory latency during startup."""
import json

from generate_streaming import WORK, once, record


def preload_next_half(source):
    source = once(source, """        if (prefetch_scales) {
            load_scale_half_raw(tile + scale_half_tiles);""", """        if (prefetch_scales && tile != 0) {
            load_scale_half_raw(tile + scale_half_tiles);""")
    marker = "    // Seed the register rolling used by CX1."
    return once(source, marker, """    // The initial next-half request overlaps the operand seed LDS reads.
    // Later halves retain the runtime loop producer and publication.
    if (loops > scale_half_tiles) {
        load_scale_half_raw(scale_half_tiles);
        __builtin_amdgcn_sched_barrier(0);
    }

""" + marker)


def batch_panel_loads(source):
    begin = source.index("    auto prefetch_sfa_panel =")
    end = source.index("    auto load_sfa_dword", begin)
    original = source[begin:end]
    # Use the unchanged transpose mapping, but issue the four independent
    # vector reads before packing any one pass. The compiler tracks raw VGPR
    # readiness even when B DTLDS requests are issued before publication.
    helper = original.replace("    auto prefetch_sfa_panel = [&](int panel_begin) {", """    opus::vector_t<D_SF, 16> panel_raw_a[4];
    auto load_sfa_panel = [&](int panel_begin) {
        const int tid = thread_id_x();
        const int group = tid & 15;
        const int owner_wave = group / 4;
        const int call = group % 4;
        const int source_row = (owner_wave / T::T_M) * T::HALF_B_M +
            (owner_wave % T::T_M) * T::W_M + call * T::T_M * T::W_M;
        opus::static_for<4>([&](auto pass_i) {
            constexpr int pass = decltype(pass_i)::value;
            const int column = panel_begin + tid / 16 + pass * 16;
            const int valid_column = column < loops ? column : loops - 1;
            panel_raw_a[pass] = load<16>(g_sfa,
                valid_column * kargs.stride_sfa + source_row);
        });
        __builtin_amdgcn_sched_barrier(0);
    };

    auto publish_sfa_panel = [&]() {""")
    load_begin = helper.index("            const int global_column = panel_begin + k_column;")
    load_end = helper.index("            const auto words =", load_begin)
    helper = helper[:load_begin] + "            const auto raw = panel_raw_a[pass];\n" + helper[load_end:]
    source = source[:begin] + helper + source[end:]
    source = once(source, "            prefetch_sfa_panel(next_tile);", "            load_sfa_panel(next_tile);")
    source = once(source, "            s_waitcnt_vmcnt(0_I);\n            if (wave_id < T::SCALE_N_HALVES)",
                  "            s_waitcnt_vmcnt(0_I);\n            publish_sfa_panel();\n            if (wave_id < T::SCALE_N_HALVES)")
    source = once(source, "    prefetch_sfa_panel(0);", "    load_sfa_panel(0);")
    source = once(source, """    s_waitcnt_vmcnt(0_I);

    if (wave_id < T::SCALE_N_HALVES)""", """    // B matrix requests can progress while the scale transpose publishes.
    publish_sfa_panel();
    s_waitcnt_vmcnt(0_I);

    if (wave_id < T::SCALE_N_HALVES)""")
    return source


if __name__ == "__main__":
    for name, parent, transform, update in [
        ("stream32_prologue_next", "stream32_prefetch_rows4_vaddr", preload_next_half,
         dict(initial_next_half_load="before_operand_seed")),
        ("stream64_batch_scale", "stream64_rows4", batch_panel_loads,
         dict(panel_global_loads="four_before_transpose", initial_publish="after_B_requests")),
    ]:
        config = json.loads((WORK / parent / "candidate.json").read_text())["config"]
        record(name, transform((WORK / parent / "tmpl_generic.hpp").read_text()),
               parent, dict(config, **update))
