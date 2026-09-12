#!/usr/bin/env python3
"""Test matrix-input cache policy and equivalent B-scale byte selection."""
from make_candidates import BASE, record, replace_n

source = (BASE / "tmpl_generic.hpp").read_text()
for policy in (1, 2, 3):
    candidate = replace_n(source,
                          "opus::number<immediate>{}, opus::number<0>{});",
                          f"opus::number<immediate>{{}}, opus::number<{policy}>{{}});")
    record(f"matrix_cache{policy}", candidate,
           dict(matrix_cache_policy=policy, matrix_cache_scope="K1_and_main_future_matrix_requests"))

candidate = replace_n(source, "        opus::number<N_REPEAT>{});",
                      "        opus::number<0>{});")
record("b_scale_byte0", candidate,
       dict(b_scale_byte_selector=0, b_scale_dword="four_identical_compact_E8M0_bytes"))
