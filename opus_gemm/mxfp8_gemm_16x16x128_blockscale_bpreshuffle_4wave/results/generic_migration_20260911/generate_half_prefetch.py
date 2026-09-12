#!/usr/bin/env python3
"""Prefetch 32 scale groups into alternating halves of a 64-group allocation.

K remains fully runtime. Tile 0/32/64/... prefetches the next half before
MFMA1; the existing MFMA5 VMEM drain completes raw loads. MFMA6 then hides
packing/publication. The following iteration's existing barrier publishes
the half long before its first consumer. No new steady-state barrier is used.
"""
import json
from generate_streaming import WORK, once, record


def block_end(source, opening):
    depth = 1
    end = opening+1
    while depth:
        depth += (source[end] == "{") - (source[end] == "}")
        end += 1
    return end


def transform(source):
    begin = source.index("    auto prefetch_sfa_panel =")
    end = source.index("    auto load_sfa_dword",begin)
    helpers = """    constexpr int scale_half_tiles = T::SCALE_PANEL_K_TILES / 2;
    static_assert(scale_half_tiles == 32);
    const int scale_tid = thread_id_x();
    const int scale_group = scale_tid & 15;
    const int scale_owner = scale_group / 4;
    const int scale_call = scale_group % 4;
    const int scale_source_row = (scale_owner / T::T_M) * T::HALF_B_M +
        (scale_owner % T::T_M) * T::W_M + scale_call * T::T_M * T::W_M;
    const unsigned int scale_select_pair = (scale_call & 1) ? 0x03070105u : 0x06020400u;
    const unsigned int scale_select_quad = (scale_call & 2) ? 0x03020706u : 0x05040100u;
    opus::vector_t<D_SF, 16> scale_raw_a[2];
    D_SF_PACK scale_raw_b;

    auto load_scale_half_raw = [&](int first_tile) {
        opus::static_for<2>([&](auto pass_i) {
            constexpr int pass = decltype(pass_i)::value;
            const int column = first_tile + scale_tid / 16 + pass * 16;
            const int valid_column = column < loops ? column : loops - 1;
            scale_raw_a[pass] = load<16>(g_sfa,
                valid_column * kargs.stride_sfa + scale_source_row);
        });
        // One wave covers 32 K groups for both N128 scale halves.
        if (wave_id == 0) {
            const int column = first_tile + (lane_id & (scale_half_tiles - 1));
            const int valid_column = column < loops ? column : loops - 1;
            const auto raw = load<1>(g_sfb, valid_column,
                (lane_id / scale_half_tiles) * kargs.stride_sfb);
            scale_raw_b = static_cast<D_SF_PACK>(raw[0]);
        }
    };

    auto publish_scale_half = [&](int first_tile) {
        const int physical_first = first_tile & panel_mask;
        opus::static_for<2>([&](auto pass_i) {
            constexpr int pass = decltype(pass_i)::value;
            const int k_column = physical_first + scale_tid / 16 + pass * 16;
            const auto words = __builtin_bit_cast(opus::vector_t<D_SF_PACK, 4>, scale_raw_a[pass]);
            opus::static_for<4>([&](auto word_i) {
                constexpr int word = decltype(word_i)::value;
                const D_SF_PACK adjacent = opus::mov_dpp(words[word], opus::number<0xb1>{});
                const D_SF_PACK pair = __builtin_amdgcn_perm(adjacent, words[word], scale_select_pair);
                const D_SF_PACK opposite = opus::mov_dpp(pair, opus::number<0x4e>{});
                const D_SF_PACK packed = __builtin_amdgcn_perm(opposite, pair, scale_select_quad);
                const int output_row = word * 4 + scale_call;
                const int dst = k_column * T::SFA_PANEL_PITCH
                    + ((scale_owner % T::T_M) * T::W_M + output_row) * 8
                    + (scale_owner / T::T_M) * 4;
                store<4>(s_sfa, __builtin_bit_cast(opus::vector_t<D_SF, 4>, packed), dst);
            });
        });
        if (wave_id == 0) {
            const D_SF_PACK packed = scale_raw_b * 0x01010101u;
            const int column = physical_first + (lane_id & (scale_half_tiles - 1));
            const int half_n = lane_id / scale_half_tiles;
            store<4>(s_sfb, __builtin_bit_cast(opus::vector_t<D_SF, 4>, packed),
                (column * T::SCALE_N_HALVES + half_n) * 4);
        }
    };

"""
    source = source[:begin]+helpers+source[end:]
    begin = source.index("    auto refill_scale_panel =")
    end = source.index("    async_load<T::VEC_A>(g_a, s_a.ptr, u_ga, u_sa + sa_offset(0, 0), ga_offset(0, 0));",begin)
    source = source[:begin]+source[end:]
    begin = source.index("    // Prologue: preload the first bounded scale panel")
    end = source.index("    async_load<T::VEC_B>(g_b, s_b.ptr, u_gb, u_sb + sb_offset(0, 0), gb_offset(0, 0));",begin)
    source = source[:begin]+"    // Seed the first half; later halves are prefetched inside matrix compute.\n    load_scale_half_raw(0);\n"+source[end:]
    begin = source.index("    if (wave_id < T::SCALE_N_HALVES)",begin)
    end = block_end(source,source.index("{",begin))
    source = source[:begin]+"    publish_scale_half(0);"+source[end:]
    assert source.count("        refill_scale_panel(tile + 1);\n") == 2
    source = source.replace("        refill_scale_panel(tile + 1);\n","")
    header = "    for (tile = 0; tile + 2 < loops; ++tile) {\n"
    source = once(source,header,header+"""        const bool prefetch_scales = (tile & (scale_half_tiles - 1)) == 0
                                  && tile + scale_half_tiles < loops;
        if (prefetch_scales) {
            load_scale_half_raw(tile + scale_half_tiles);
            __builtin_amdgcn_sched_barrier(0);
        }
""")
    cut = """        MXFP8_MMA_ONE(0, 1, 1, v_a[0], v_b, c00_5, v_sfa, v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);
"""
    start = source.index(header)
    pos = source.index(cut,start)+len(cut)
    source = source[:pos]+"""
        if (prefetch_scales) {
            // MFMA5 completed the raw loads and retired all readers of the
            // destination half. The next existing barrier publishes writes.
            publish_scale_half(tile + scale_half_tiles);
            __builtin_amdgcn_sched_barrier(0);
        }
"""+source[pos:]
    source = source.replace("// is a cache capacity; panels are refreshed for arbitrarily long K.", "// is a cache capacity; halves are prefetched for arbitrarily long K.")
    assert "refill_scale_panel" not in source and "prefetch_sfa_panel" not in source
    return source


if __name__ == "__main__":
    for parent,name in [("stream64_rows4","stream32_prefetch_rows4"),("stream64_lds_fence","stream32_prefetch_pair8")]:
        config = json.loads((WORK/parent/"candidate.json").read_text())["config"]
        record(name,transform((WORK/parent/"tmpl_generic.hpp").read_text()),parent,
               dict(config,scale_load_batch=32,scale_refill="alternating_half_prefetch",scale_load_mfma=0,scale_publish_mfma=6))
