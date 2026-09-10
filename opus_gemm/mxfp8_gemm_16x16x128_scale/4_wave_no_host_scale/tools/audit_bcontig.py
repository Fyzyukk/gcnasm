#!/usr/bin/env python3
"""Read-only, source-bound B-producer audit for the two frozen b-contig variants.

This supplements, rather than replaces, the scale/MFMA/synchronization gate and
GPU correctness tests.  It checks the actual source fingerprint, exhaustively
compares the old/new B-to-LDS images, checks the two distinct IOFFSET cancellation
schemes, and inspects the linked DTLDS instruction groups.  It never builds a
kernel, launches a GPU, imports candidate Python, or writes files.

Example:
  python3 audit_bcontig.py --source /path/to/candidate --build /path/to/build \
      --manifest /path/to/build/relink_manifest.json

Source accepts a directory containing tmpl.hpp/traits.hpp/kern.cc, or tmpl.hpp.
Only the two explicitly reviewed source/ISA pairs below are accepted.  A source
change must be reviewed; passing an independent mathematical model is not enough.
"""

from __future__ import annotations

import argparse
import collections
import hashlib
import json
from pathlib import Path
import re
import sys


VARIANTS = {
    "fd398910b44b7102450386e67e6712691d65c5cf50588727631fd96a61aa6316": {
        "name": "b_contig_ioffset_v1",
        "cancellation": "vaddr",
        "isa_sha256": "5ca609c937b77f21c51f806b20bcbf8c4a268b8060b0471385e8e6a5119c4c74",
        "instructions": 1872,
        "ordinary_vgpr": 168,
        "sgpr": 71,
        "nop": 75,
    },
    "06702267a0f0c32c1d8e1b9ff77f60e1264bf1d23b78c1e8b5ee09cdf371b624": {
        "name": "b_contig_common_vaddr_v1",
        "cancellation": "soffset",
        "isa_sha256": "590bd0440b757862062a03a1c471c1e5f2d896a0c57f6555976e3017a4b937fa",
        "instructions": 1920,
        "ordinary_vgpr": 176,
        "sgpr": 77,
        "nop": 92,
    },
}
TRAITS_SHA256 = "f1fa9239e09285412e89b996fcea1e46cb2692ffc2dd2388c2904dbf65f78e3f"
KERN_SHA256 = "9a63d273b88abbe7651c284246104ff2f6d50bf45060b1e18fbdc15e639739a1"
IMMEDIATES = [0, 1056, 2112, 3168]


def check(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def source_variant(source: bytes) -> dict:
    digest = sha256(source)
    check(digest in VARIANTS, f"unreviewed kernel source SHA256: {digest}")
    return VARIANTS[digest]


def check_source(source_file: Path) -> dict:
    data = source_file.read_bytes()
    variant = source_variant(data)
    source = data.decode()
    directory = source_file.parent
    # Final packaging changes only this include from ../../ to a local header.
    # Canonicalize that one exact include; do not tolerate other traits changes.
    traits = (directory / "traits.hpp").read_bytes().replace(
        b'#include "gemm_a8w8_mxfp8_scale_common.h"',
        b'#include "../../gemm_a8w8_mxfp8_scale_common.h"')
    check(sha256(traits) == TRAITS_SHA256, "unreviewed traits/layout constants")
    check(sha256((directory / "kern.cc").read_bytes()) == KERN_SHA256,
          "unreviewed kernel instantiation")
    compact = re.sub(r"\s+", "", source)
    for marker in (
        "constintproducer_rep=wave_id_n*T::T_M+wave_id_m;",
        "opus::make_tuple(opus::p_dim{},opus::y_dim{},opus::p_dim{},opus::y_dim{})",
        "opus::make_tuple(opus::p_dim{},opus::y_dim{},opus::y_dim{})",
        "auto*dst=smem_base+smem_offsets[0];",
        "constexprintlds_ioffset=Issue*lds_issue_stride;",
        "opus::number<lds_ioffset>{},opus::number<0>{}",
    ):
        check(marker in compact, f"reviewed source mapping expression missing: {marker}")
    if variant["cancellation"] == "vaddr":
        check("gmem_offsets[Issue]-lds_ioffset,s_os," in compact,
              "vector-address IOFFSET compensation missing")
    else:
        check("gmem_offsets[0],s_os+source_row_delta*source_stride-lds_ioffset," in compact,
              "scalar-offset IOFFSET compensation missing")
        check("(Issue/T::T_M)*threads_n_per_wave*T::T_M+Issue%T::T_M" in compact,
              "common-vaddr logical row delta changed")
    check(source.count("async_load_issue_b_contiguous_scale<T,") == 8,
          "expected four steady DTLDS requests for each B half")
    return variant


def b_image(contiguous: bool, row_stride: int = 1056) -> dict[int, tuple[int, int]]:
    """One B half: exact [4,2,8,2,8,16] source / [4,2,2,16] LDS layouts.

    The accepted source hashes fix which axes are producer (p) versus iteration
    (y).  DTLDS supplies lane*16 at the destination; lanes do not have independent
    arbitrary LDS destinations.  Values are logical B (n,k) coordinates.
    """
    image: dict[int, tuple[int, int]] = {}
    for wave in range(4):
        wave_m, wave_n = wave % 2, wave // 2
        for issue in range(4):
            lds_row = 4 * wave + issue if contiguous else 4 * issue + wave
            for lane in range(64):
                row_lane, k_lane = divmod(lane, 8)
                if contiguous:
                    n = 32 * wave + 16 * (issue // 2) + 2 * row_lane + issue % 2
                else:
                    n = 32 * issue + 16 * wave_n + 2 * row_lane + wave_m
                for byte in range(16):
                    address = lds_row * row_stride + lane * 16 + byte
                    check(address not in image, "duplicate B producer LDS byte")
                    image[address] = (n, 16 * k_lane + byte)
    return image


def cancellation_address(kind: str, wave: int, lane: int, issue: int,
                         stride_b: int, scalar_base: int) -> tuple[int, int, int]:
    row_lane, k_lane = divmod(lane, 8)
    row0 = 32 * wave + 2 * row_lane
    row_delta = 16 * (issue // 2) + issue % 2
    immediate = issue * 1056
    g0 = row0 * stride_b + k_lane * 16
    expected = (row0 + row_delta) * stride_b + k_lane * 16 + scalar_base
    if kind == "vaddr":
        vector_offset = g0 + row_delta * stride_b - immediate
        scalar_offset = scalar_base
    else:
        vector_offset = g0
        scalar_offset = scalar_base + row_delta * stride_b - immediate
    return vector_offset + scalar_offset + immediate, expected, immediate


def check_math(kind: str) -> dict:
    old, new = b_image(False), b_image(True)
    expected_coordinates = {(n, k) for n in range(128) for k in range(128)}
    check(len(old) == len(new) == 16384, "B-half byte count changed")
    check(set(old.values()) == set(new.values()) == expected_coordinates,
          "B source rows/K bytes not covered exactly once")
    check(old == new, "new producer changes the LDS image consumed by unchanged B reads")
    for address, (n, k) in new.items():
        lds_row, within_row = divmod(address, 1056)
        row_lane, k_offset = divmod(within_row, 128)
        check(within_row < 1024, "producer writes LDS padding")
        check(n == 16 * (lds_row // 2) + 2 * row_lane + lds_row % 2 and k == k_offset,
              "canonical consumer-major B image mismatch")

    checked = 0
    # All 64 K128 tiles, both N halves and all lane/issue addresses.  Three
    # legal row strides also verify that the identity is not an 8192-only trick.
    for stride_b in (8192, 8208, 16384):
        for half_n in range(2):
            for tile_k in range(64):
                scalar_base = half_n * 128 * stride_b + tile_k * 128
                for wave in range(4):
                    for lane in range(64):
                        for issue in range(4):
                            actual, expected, immediate = cancellation_address(
                                kind, wave, lane, issue, stride_b, scalar_base)
                            check(actual == expected, "IOFFSET source compensation mismatch")
                            check(0 <= immediate <= 4095, "MUBUF IOFFSET outside 12-bit range")
                            checked += 1
    return {"b_bytes_per_half": len(new), "b_bytes_per_k128_tile": 2 * len(new),
            "source_address_cases": checked, "old_wave_lds_row_stride": 4224,
            "new_wave_lds_row_stride": 1056, "immediates": IMMEDIATES,
            "same_raw_B_coordinates": True, "same_consumer_LDS_image": True}


def instructions(text: str) -> list[str]:
    return [line.split("//", 1)[0].strip() for line in text.splitlines()
            if re.search(r"// [0-9A-F]{12,}:", line)]


def metadata(text: str, name: str) -> int:
    value = re.search(r"\." + re.escape(name) + r":\s*(\d+)", text)
    check(value is not None, f"metadata field missing: {name}")
    return int(value.group(1))


def m0_write(inst: str) -> bool:
    return re.match(r"s_\S+\s+m0\s*,", inst) is not None


def check_isa(build: Path, variant: dict) -> dict:
    ins = instructions((build / "kernel.isa").read_text())
    digest = sha256(("\n".join(ins) + "\n").encode())
    check(digest == variant["isa_sha256"], f"unreviewed linked ISA SHA256: {digest}")
    counts = collections.Counter(x.split(None, 1)[0] for x in ins)
    check(len(ins) == variant["instructions"], "instruction count changed")
    check(counts["v_mfma_scale_f32_16x16x128_f8f6f4"] == 384, "scaled MFMA count changed")
    notes = (build / "kernel.notes").read_text()
    for key, expected in {
        "agpr_count": 256, "sgpr_count": variant["sgpr"],
        "vgpr_count": variant["ordinary_vgpr"] + 256,
        "vgpr_spill_count": 0, "sgpr_spill_count": 0,
        "private_segment_fixed_size": 0, "group_segment_fixed_size": 163840,
        "wavefront_size": 64, "max_flat_workgroup_size": 256,
    }.items():
        check(metadata(notes, key) == expected, f"metadata changed: {key}")
    check(not any("scratch_" in x for x in ins), "scratch instruction present")

    mfmas = [i for i, x in enumerate(ins) if x.startswith("v_mfma_scale_")]
    windows = 0
    b_windows = []
    nonzero_loads = 0
    load_re = re.compile(r"^buffer_load_dwordx4\s+(v\d+),\s+s\[(\d+:\d+)\],\s+(\S+).*\blds$")
    for begin, end in zip(mfmas, mfmas[1:]):
        loads = [(i, x, load_re.match(x)) for i, x in enumerate(ins[begin + 1:end], begin + 1)
                 if x.startswith("buffer_load_dwordx4") and x.endswith("lds")]
        if len(loads) != 4 or any(match is None for _, _, match in loads):
            continue
        if len({match.group(2) for _, _, match in loads}) != 1:
            continue
        windows += 1
        immediates = [int(m.group(1)) if (m := re.search(r"\boffset:(\d+)", x)) else 0
                      for _, x, _ in loads]
        if not any(immediates):
            continue
        # The last common-vaddr group legally issues 2112 before 0/1056.
        # Its four independent writes must cover the same destinations once;
        # numerical issue order is not a memory-dependence requirement.
        check(sorted(immediates) == IMMEDIATES, "B DTLDS immediate destinations changed")
        check(not any(m0_write(x) for x in ins[loads[0][0] + 1:loads[-1][0]]),
              "B group changes m0 between its four requests")
        vectors = [match.group(1) for _, _, match in loads]
        scalars = [match.group(3) for _, _, match in loads]
        if variant["cancellation"] == "vaddr":
            check(len(set(vectors)) == 4 and len(set(scalars)) == 1,
                  "vector-compensated group no longer has four vaddrs / common soffset")
        else:
            check(len(set(vectors)) == 1 and len(set(scalars)) > 1,
                  "common-vaddr group no longer has common vaddr / scalar compensation")
        nonzero_loads += 3
        b_windows.append({"mfma_instruction_index": begin, "srd": loads[0][2].group(2),
                          "vaddr": vectors, "soffset": scalars, "immediates": immediates})
    check(windows == 21 and len(b_windows) == 10, "expected 21 DTLDS windows including 10 B groups")
    actual_nonzero = sum(bool(re.search(r"\boffset:[1-9]\d*", x)) for x in ins
                         if x.startswith("buffer_load_dwordx4") and x.endswith("lds"))
    check(actual_nonzero == nonzero_loads == 30, "unaccounted nonzero DTLDS immediate")
    check(sum(map(m0_write, ins)) == 92, "m0 write count changed")
    check(counts["s_nop"] == variant["nop"], "NOP count changed")
    return {"normalized_sha256": digest, "instructions": len(ins), "scaled_mfma": 384,
            "dtlds_windows": windows, "same_m0_b_groups": len(b_windows),
            "m0_writes": 92, "nop": counts["s_nop"], "b_groups": b_windows}


def check_manifest(manifest_file: Path | None, source_file: Path, build: Path) -> dict:
    if manifest_file is None:
        return {"checked": False, "note": "source/ISA fingerprints checked; no external provenance manifest supplied"}
    manifest = json.loads(manifest_file.read_text())
    recorded = manifest["sha256"]
    targets = [(source_file, "source/tmpl.hpp"),
               (source_file.parent / "traits.hpp", "source/traits.hpp"),
               (source_file.parent / "kern.cc", "source/kern.cc")]
    targets += [(build / name, "build/" + name) for name in
                ("kernel.exe", "kernel.o", "kernel.co", "kernel.isa", "kernel.notes")]
    for path, relative in targets:
        keys = [key for key in (str(path.resolve()), relative) if key in recorded]
        check(keys, f"manifest does not bind {path}")
        check(all(recorded[key] == sha256(path.read_bytes()) for key in keys),
              f"manifest hash mismatch: {path}")
    for command in manifest.get("commands", []):
        check(not any("-mllvm" in arg for arg in command),
              "manifest contains additional backend compiler flags")
    return {"checked": True, "file": str(manifest_file), "files_checked": len(targets)}


def self_test() -> dict:
    check(b_image(False) == b_image(True), "positive image self-test failed")
    check(b_image(False) != b_image(True, row_stride=1057), "bad LDS stride escaped self-test")
    for kind in ("vaddr", "soffset"):
        for issue in range(4):
            actual, expected, immediate = cancellation_address(kind, 3, 63, issue, 8192, 128)
            check(actual == expected, "positive cancellation self-test failed")
            if issue:
                check(actual + immediate != expected, "missing IOFFSET subtraction escaped self-test")
    try:
        source_variant(b"a different kernel must not validate using the old model")
    except RuntimeError:
        pass
    else:
        raise RuntimeError("unreviewed source escaped fingerprint self-test")
    return {"self_test": "PASS", "negative_cases": ["wrong LDS row stride", "missing immediate subtraction", "unreviewed source"]}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path)
    parser.add_argument("--build", type=Path)
    parser.add_argument("--manifest", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        print(json.dumps(self_test(), indent=2))
        return
    check(args.source is not None and args.build is not None, "--source and --build are required")
    source_file = args.source.resolve(strict=True)
    if source_file.is_dir():
        source_file /= "tmpl.hpp"
    build = args.build.resolve(strict=True)
    variant = check_source(source_file)
    result = {
        "status": "PASS", "variant": variant["name"], "source": str(source_file),
        "source_sha256": sha256(source_file.read_bytes()), "build": str(build),
        "compensation_location": variant["cancellation"],
        "math": check_math(variant["cancellation"]), "isa": check_isa(build, variant),
        "provenance": check_manifest(args.manifest, source_file, build),
        "limits": "Supplemental B-path audit only; real GPU correctness, scale/MFMA/wait gates and performance validation remain required.",
    }
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, ValueError, KeyError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        raise SystemExit(1)
