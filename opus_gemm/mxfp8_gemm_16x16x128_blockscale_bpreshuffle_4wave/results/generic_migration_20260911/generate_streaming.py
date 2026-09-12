#!/usr/bin/env python3
"""Port preserved pipelines to runtime K with reusable, bounded scale panels."""
import difflib
import hashlib
import json
from pathlib import Path
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
WORK = Path((HERE / "work_path.txt").read_text().strip())
BASE = HERE / "baseline_source"


def once(source, old, new):
    assert source.count(old) == 1, (source.count(old), old[:100])
    return source.replace(old, new)


def generalize(source):
    source = source.replace("namespace blockscale_panel", "namespace blockscale_generic")
    source = once(source,
        "    // The launcher enforces K=8192. Keep the trip count runtime-visible to\n"
        "    // preserve the validated hard-AGPR loop shape; constant folding it\n"
        "    // triggers conflicting hard-pin coalescing in this experimental LLVM.\n"
        "    const int loops = ceil_div_scale(kargs.k, T::B_K);\n"
        "    static_assert(T::SCALE_PANEL_K_TILES == 64 && T::REQUIRED_K == 8192);",
        "    // Runtime K controls every matrix iteration. The fixed panel size\n"
        "    // is a cache capacity; panels are refreshed for arbitrarily long K.\n"
        "    const int loops = ceil_div_scale(kargs.k, T::B_K);\n"
        "    static_assert(T::SCALE_PANEL_K_TILES == 64);\n"
        "    constexpr int panel_mask = T::SCALE_PANEL_K_TILES - 1;")
    source = once(source, "auto prefetch_sfa_panel = [&]() {", "auto prefetch_sfa_panel = [&](int panel_begin) {")
    source = once(source,
        "            const auto raw = load<16>(g_sfa, k_column * kargs.stride_sfa + source_row);",
        "            const int global_column = panel_begin + k_column;\n"
        "            // Unused tail slots duplicate the final valid column.\n"
        "            // Every vector load stays within the compact input tensor.\n"
        "            const int valid_column = global_column < loops ? global_column : loops - 1;\n"
        "            const auto raw = load<16>(g_sfa, valid_column * kargs.stride_sfa + source_row);")
    source = once(source, "const int addr = k_tile * T::SFA_PANEL_PITCH", "const int addr = (k_tile & panel_mask) * T::SFA_PANEL_PITCH")
    source = once(source, "(k_tile * T::SCALE_N_HALVES + half_tile_n) * 4", "((k_tile & panel_mask) * T::SCALE_N_HALVES + half_tile_n) * 4")
    assert source.count("(tile + 1) * T::SCALE_N_HALVES * 4") == 2
    source = source.replace("(tile + 1) * T::SCALE_N_HALVES * 4", "((tile + 1) & panel_mask) * T::SCALE_N_HALVES * 4")
    source = once(source, "    prefetch_sfa_panel();", "    prefetch_sfa_panel(0);")
    source = once(source,
        "        const auto raw = load<1>(g_sfb, lane_id, wave_id * kargs.stride_sfb);",
        "        const int valid_column = lane_id < loops ? lane_id : loops - 1;\n"
        "        const auto raw = load<1>(g_sfb, valid_column, wave_id * kargs.stride_sfb);")
    marker = "    async_load<T::VEC_A>(g_a, s_a.ptr, u_ga, u_sa + sa_offset(0, 0), ga_offset(0, 0));"
    refill = """    auto refill_scale_panel = [&](int next_tile) {
        if ((next_tile & panel_mask) == 0) {
            // Current scales are resident in registers. Retire every reader
            // of the previous panel before overwriting the same allocation.
            s_waitcnt_vmcnt(0_I);
            s_waitcnt_lgkmcnt(0_I);
            __builtin_amdgcn_s_barrier();
            __builtin_amdgcn_sched_barrier(0);
            prefetch_sfa_panel(next_tile);
            D_SF_PACK raw_b = 0;
            if (wave_id < T::SCALE_N_HALVES) {
                const int global_column = next_tile + lane_id;
                const int valid_column = global_column < loops ? global_column : loops - 1;
                const auto raw = load<1>(g_sfb, valid_column, wave_id * kargs.stride_sfb);
                raw_b = static_cast<D_SF_PACK>(raw[0]);
            }
            s_waitcnt_vmcnt(0_I);
            if (wave_id < T::SCALE_N_HALVES) {
                const D_SF_PACK packed = raw_b * 0x01010101u;
                store<4>(s_sfb, __builtin_bit_cast(opus::vector_t<D_SF, 4>, packed),
                    (lane_id * T::SCALE_N_HALVES + wave_id) * 4);
            }
            s_waitcnt_lgkmcnt(0_I);
            __builtin_amdgcn_s_barrier();
            __builtin_amdgcn_sched_barrier(0);
        }
    };

"""
    source = once(source, marker, refill + marker)
    start = source.index("    // Both matrices preload K1.")
    end = source.index("    // Seed the register rolling", start)
    original_k1 = source[start:end]
    source = source[:start] + "    // A single K128 block has no K1 producer.\n    if (loops > 1) {\n" + "".join("    " + line if line.strip() else line for line in original_k1.splitlines(True)) + "    }\n\n" + source[end:]
    source = once(source, "const int future_tile = (tile + 2) & 63;", "const int future_tile = tile + 2;")
    loop_header = "    for (tile = 0; tile + 2 < loops; ++tile) {\n"
    source = once(source, loop_header, loop_header + "        refill_scale_panel(tile + 1);\n")
    source = once(source,
        "    // Consume K62 and roll K63 without issuing the unused K64 matrix requests.\n    {",
        "    // Penultimate runtime K128 block: roll the final block with no\n"
        "    // unused future matrix request. K128 skips this segment entirely.\n"
        "    if (loops > 1) {\n        refill_scale_panel(tile + 1);")
    source = source.replace("Compact external scales are consumed only in the prologue.", "Compact external scales are consumed once per reusable K panel.")
    source = source.replace("// Prologue: preload both whole-K scale panels before the first barrier.", "// Prologue: preload the first bounded scale panel before the first barrier.")
    source = source.replace("// Process K0..K61 with matrix prefetching; K62 below has no future producer.", "// Prefetch while two later K128 blocks exist; peel the penultimate block.")
    source = source.replace("// Keep the measured scalar address schedule. Issued future tiles are K2..K63.", "// Future matrix addresses always use the complete runtime K index.")
    source = source.replace("// stage for t+2 prefetches covering K2..K63; K62 issues no future request.", "// stage for t+2 prefetches; the penultimate block issues no future request.")
    source = source.replace("// K=8192 always has a second tile. Its B data is ready by the first", "// This guarded K1 block has B data ready by the first")
    source = source.replace("// Publish the final K63 operands at MFMA5, then finish K62", "// Publish the final block at MFMA5, then finish its predecessor")
    source = source.replace("K63", "final-block").replace("K62", "penultimate-block")
    assert "REQUIRED_K" not in source and "8192" not in source
    return source


def panel_traits():
    traits = (BASE / "traits.hpp").read_text()
    start = traits.index("    static constexpr int LDS_BYTES =")
    end = traits.index("    static_assert(E_M", start)
    traits = traits[:start] + """    // Scale-panel capacity is independent of the runtime GEMM K extent.
    static constexpr int SCALE_PANEL_K_TILES = 64;
    static constexpr int SFA_PANEL_PITCH = B_M;
    static constexpr int SFA_PANEL_BYTES = SFA_PANEL_PITCH * SCALE_PANEL_K_TILES;
    static constexpr int SFB_PANEL_BYTES = SCALE_N_HALVES * SCALE_PANEL_K_TILES * 4;
    static constexpr int LDS_BYTES =
        SMEM_A_ELEMS + SMEM_B_ELEMS + SFA_PANEL_BYTES + SFB_PANEL_BYTES;

""" + traits[end:]
    return once(traits, "static_assert(LDS_BYTES == 139264);", "static_assert(LDS_BYTES == 152064);")


def record(name, source, parent, config):
    target = WORK / name
    patch_dir = HERE / "candidate_patches" / name
    assert not target.exists() and not patch_dir.exists()
    shutil.copytree(BASE, target)
    changes = {"tmpl_generic.hpp": source, "traits.hpp": panel_traits()}
    patch_dir.mkdir(parents=True)
    hashes = {}
    for filename, content in changes.items():
        (target / filename).write_text(content)
        original = (BASE / filename).read_text()
        patch = "".join(difflib.unified_diff(original.splitlines(True), content.splitlines(True), fromfile="a/"+filename, tofile="b/"+filename))
        (patch_dir / (filename + ".patch")).write_text(patch)
        hashes[filename] = hashlib.sha256(content.encode()).hexdigest()
    info = dict(name=name, parent=parent, config=config, source_hashes=hashes,
                generic_runtime_k=True, performance_shape=[8192,8192,8192], waves=4, output_tiles_per_wg=1)
    for p in [target / "candidate.json", patch_dir / "candidate.json"]:
        p.write_text(json.dumps(info, indent=2) + "\n")
    index = json.loads((HERE / "candidate_index.json").read_text())
    index["candidates"].append(info)
    (HERE / "candidate_index.json").write_text(json.dumps(index, indent=2) + "\n")
    print(name, hashes, flush=True)


if __name__ == "__main__":
    sources = [
        ("stream64_direct", ROOT / "results/tile1_target32_round2_20260911/baseline_source/tmpl.hpp", "aabad81 specialized pipeline", dict(lds_output=False, release_mfma=4, unified_k1=False, early_a1_m3=False)),
        ("stream64_lds", ROOT / "results/tile1_target32_round2_20260911/selected/tmpl.hpp", "selected_32_clean specialized pipeline", dict(lds_output=True, release_mfma=5, unified_k1=True, early_a1_m3=True)),
    ]
    for name, source, parent, config in sources:
        record(name, generalize(source.read_text()), parent, dict(config, scale_panel_tiles=64, unroll=8))
