#!/usr/bin/env python3
"""Combine independently measured grid locality and private argument preload."""
import json
from compact_arguments import transform as compact_arguments
from make_candidates import BASE, WORK, grouped_grid, record, replace_n
from output_pingpong import transform as output_pingpong

for use_output, use_compact in [(True, False), (False, True), (True, True)]:
    config = json.loads((WORK / "grid_group2/candidate.json").read_text())["config"]
    source = grouped_grid((BASE / "tmpl_generic.hpp").read_text(), 2)
    support = {}
    name = "grid_group2"
    if use_output:
        source = output_pingpong(source, 136)
        config.update(json.loads((WORK / "output_pingpong_136/candidate.json").read_text())["config"])
        name += "_out136"
    if use_compact:
        source, support = compact_arguments(source)
        source = replace_n(source,
            "return half_tile_m * T::HALF_B_M * k + tile_k * T::B_K;",
            "return __builtin_amdgcn_readfirstlane(half_tile_m * T::HALF_B_M * k + tile_k * T::B_K);")
        source = replace_n(source,
            "return half_tile_n * T::HALF_B_N * k + tile_k * T::B_K * 16;",
            "return __builtin_amdgcn_readfirstlane(half_tile_n * T::HALF_B_N * k + tile_k * T::B_K * 16);")
        support["Makefile"] = (WORK / "compact_uniform_preload8/Makefile").read_text()
        compact_cfg = json.loads((WORK / "compact_uniform_preload8/candidate.json").read_text())["config"]
        for key in ["compact_device_arguments", "public_c_abi_bytes", "public_strides_validated_and_derived",
                    "kernarg_preload_count", "initial_matrix_producer", "initial_matrix_offsets_forced_uniform"]:
            config[key] = compact_cfg[key]
        name += "_compact8"
    config.update(grid_order="transpose_low_bits", grid_group=2)
    record(name, source, config, support)
