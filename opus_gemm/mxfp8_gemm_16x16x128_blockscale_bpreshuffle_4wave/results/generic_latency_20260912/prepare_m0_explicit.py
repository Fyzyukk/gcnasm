#!/usr/bin/env python3
"""Repair Clang's inline-asm-only lambda captures without changing old candidates."""
from make_candidates import BASE, record, replace_n
from prepare_m0 import transform

source = (BASE / "tmpl_generic.hpp").read_text()
for lead in (1, 2):
    candidate = transform(source, lead, ordered=True)
    candidate = replace_n(candidate,
                          "auto issue_matrix_prepared = [&](auto issue_i, int scalar_offset)",
                          "auto issue_matrix_prepared = [&matrix_addresses, &matrix_raw_rsrc](auto issue_i, int scalar_offset)")
    record(f"prepare_m0_explicit{lead}", candidate,
           dict(main_matrix_issue="explicit_m0_and_MUBUF",
                m0_setup_mfmas_before_request=lead,
                future_matrix_soffset="materialized_before_main_MFMA",
                preserve_prior_group_m0=True,
                explicit_inline_asm_captures=True))
