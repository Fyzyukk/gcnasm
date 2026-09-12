#!/usr/bin/env python3
"""Prevent initial LDS-load scalar offsets from becoming waterfall loops."""
from compact_arguments import FIELDS, transform
from initial_roles import transform as initial_roles
from make_candidates import BASE, record, replace_n

source, support = transform((BASE / "tmpl_generic.hpp").read_text())
uniform = replace_n(source,
                    "return half_tile_m * T::HALF_B_M * k + tile_k * T::B_K;",
                    "return __builtin_amdgcn_readfirstlane(half_tile_m * T::HALF_B_M * k + tile_k * T::B_K);")
uniform = replace_n(uniform,
                    "return half_tile_n * T::HALF_B_N * k + tile_k * T::B_K * 16;",
                    "return __builtin_amdgcn_readfirstlane(half_tile_n * T::HALF_B_N * k + tile_k * T::B_K * 16);")
roles = initial_roles(source, "split")
for kind, candidate in (("uniform", uniform), ("roles", roles)):
    for count in (0, 8):
        changed = dict(support)
        if count:
            changed["Makefile"] = replace_n((BASE / "Makefile").read_text(),
                                              "$(FLAGS) -D__HIPCC_RTC__",
                                              f"$(FLAGS) -mllvm -amdgpu-kernarg-preload-count={count} -D__HIPCC_RTC__")
        record(f"compact_{kind}_preload{count}", candidate,
               dict(compact_device_arguments=FIELDS, public_c_abi_bytes=96,
                    public_strides_validated_and_derived=True, kernarg_preload_count=count,
                    initial_matrix_producer="same_A_B_roles_as_main" if kind=="roles" else "baseline",
                    initial_matrix_offsets_forced_uniform=kind=="uniform"), changed)
