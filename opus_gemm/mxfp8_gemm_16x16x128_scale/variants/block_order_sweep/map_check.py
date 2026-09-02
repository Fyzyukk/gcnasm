#!/usr/bin/env python3
"""Prove every tested block-order formula is a bijection or exact fallback."""

from __future__ import annotations


ORDERS = (
    "t4x8_nfast",
    "t4x8_mfast",
    "t8x4_nfast",
    "t8x4_mfast",
    "nmajor",
    "t2x16_nfast_exact",
    "t4x8_nfast_exact",
    "t8x4_nfast_exact",
    "t2x16_direct",
    "identity_direct",
    "t2x16_coords",
    "identity_coords",
    "t2x16_xor_m8",
    "t2x16_serpentine",
    "t2x16_gray",
    "t2x16_xor_macro8",
    "t2x16_insert_p1",
    "t2x16_insert_p2",
    "t2x16_insert_p3",
    "t2x16_n_bitreverse",
    "t2x16_n_rotl1",
    "t2x16_n_rotl2",
    "t2x16_n_rotl3",
)


def ordered_id(order: str, physical: int, m: int, n: int) -> int:
    tiles_m = (m + 255) // 256
    tiles_n = (n + 255) // 256
    mgroups = (tiles_m + 3) // 4

    if order in {"identity_direct", "identity_coords"}:
        return physical
    if order in {"t2x16_direct", "t2x16_coords"}:
        if m != 8192 or n != 8192:
            return physical
        macro_id, local = divmod(physical, 32)
        mgroup = (macro_id // 2) * 2 + local // 16
        block_n = (macro_id % 2) * 16 + local % 16
    elif order.startswith("t2x16_") and order in {
        "t2x16_xor_m8",
        "t2x16_serpentine",
        "t2x16_gray",
        "t2x16_xor_macro8",
        "t2x16_insert_p1",
        "t2x16_insert_p2",
        "t2x16_insert_p3",
        "t2x16_n_bitreverse",
        "t2x16_n_rotl1",
        "t2x16_n_rotl2",
        "t2x16_n_rotl3",
    }:
        if mgroups != 8 or tiles_n != 32:
            return physical
        macro_id, local = divmod(physical, 32)
        if order == "t2x16_insert_p1":
            local_m = (local >> 1) & 1
            raw_n = (local & 1) | ((local >> 2) << 1)
        elif order == "t2x16_insert_p2":
            local_m = (local >> 2) & 1
            raw_n = (local & 3) | ((local >> 3) << 2)
        elif order == "t2x16_insert_p3":
            local_m = (local >> 3) & 1
            raw_n = (local & 7) | ((local >> 4) << 3)
        else:
            local_m, raw_n = divmod(local, 16)
        mgroup = (macro_id // 2) * 2 + local_m
        if order == "t2x16_xor_m8":
            permuted_n = raw_n ^ (local_m * 8)
        elif order == "t2x16_serpentine":
            permuted_n = raw_n ^ (local_m * 15)
        elif order == "t2x16_gray":
            permuted_n = raw_n ^ (raw_n // 2)
        elif order == "t2x16_xor_macro8":
            permuted_n = raw_n ^ (((macro_id // 2) & 1) * 8)
        elif order == "t2x16_n_bitreverse":
            permuted_n = int(f"{raw_n:04b}"[::-1], 2)
        elif order == "t2x16_n_rotl1":
            permuted_n = ((raw_n << 1) | (raw_n >> 3)) & 15
        elif order == "t2x16_n_rotl2":
            permuted_n = ((raw_n << 2) | (raw_n >> 2)) & 15
        elif order == "t2x16_n_rotl3":
            permuted_n = ((raw_n << 3) | (raw_n >> 1)) & 15
        else:
            permuted_n = raw_n
        block_n = (macro_id % 2) * 16 + permuted_n
    elif order.endswith("_exact"):
        if mgroups != 8 or tiles_n != 32:
            return physical
        macro_id, local = divmod(physical, 32)
        if order == "t2x16_nfast_exact":
            mgroup = (macro_id // 2) * 2 + local // 16
            block_n = (macro_id % 2) * 16 + local % 16
        elif order == "t4x8_nfast_exact":
            mgroup = (macro_id // 4) * 4 + local // 8
            block_n = (macro_id % 4) * 8 + local % 8
        else:
            mgroup = local // 4
            block_n = macro_id * 4 + local % 4
    elif order.startswith("t4x8"):
        if mgroups % 4 or tiles_n % 8:
            return physical
        macro_n_count = tiles_n // 8
        macro_id, local = divmod(physical, 32)
        if order.endswith("nfast"):
            mgroup = (macro_id // macro_n_count) * 4 + local // 8
            block_n = (macro_id % macro_n_count) * 8 + local % 8
        else:
            mgroup = (macro_id // macro_n_count) * 4 + local % 4
            block_n = (macro_id % macro_n_count) * 8 + local // 4
    elif order.startswith("t8x4"):
        if mgroups % 8 or tiles_n % 4:
            return physical
        macro_n_count = tiles_n // 4
        macro_id, local = divmod(physical, 32)
        if order.endswith("nfast"):
            mgroup = (macro_id // macro_n_count) * 8 + local // 4
            block_n = (macro_id % macro_n_count) * 4 + local % 4
        else:
            mgroup = (macro_id // macro_n_count) * 8 + local % 8
            block_n = (macro_id % macro_n_count) * 4 + local // 8
    else:
        mgroup = physical % mgroups
        block_n = physical // mgroups

    return mgroup * tiles_n + block_n


def main() -> None:
    shapes = (
        (256, 256),
        (256, 512),
        (512, 512),
        (768, 512),
        (1024, 512),
        (1280, 768),
        (8192, 512),
        (8192, 2048),
        (8192, 8192),
    )
    for m, n in shapes:
        tiles_m = (m + 255) // 256
        tiles_n = (n + 255) // 256
        total = ((tiles_m + 3) // 4) * tiles_n
        expected = list(range(total))
        for order in ORDERS:
            actual = [ordered_id(order, physical, m, n)
                      for physical in range(total)]
            if sorted(actual) != expected:
                raise SystemExit(
                    f"FAIL {order} M={m} N={n}: mapping is not bijective")
    print("PASS: all block orders are bijective/fallback-safe on correctness, activation, and 8192^2 grids")


if __name__ == "__main__":
    main()
