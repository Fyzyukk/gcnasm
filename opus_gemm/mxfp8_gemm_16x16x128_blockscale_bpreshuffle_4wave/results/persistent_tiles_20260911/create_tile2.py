#!/usr/bin/env python3
"""Derive persistent tile2 from the recorded tile4 source transformation."""
import difflib
import hashlib
import json
from pathlib import Path
import shutil

here = Path(__file__).resolve().parent
work = Path((here / "work_path.txt").read_text().strip())
tile4 = json.loads((here / "candidate.json").read_text())
target = work / "tile2"
target.mkdir()
for name, digest in tile4["candidate_source_sha256"].items():
    p = work / "tile4" / name
    assert hashlib.sha256(p.read_bytes()).hexdigest() == digest, name
    shutil.copy2(p, target / name)

replacements = {
    "tmpl.hpp": [
        ("T::OUTPUT_TILES_PER_WG == 4", "T::OUTPUT_TILES_PER_WG == 2"),
        ("up to four complete", "up to two complete"),
        ("divisible by four.", "divisible by two."),
    ],
    "traits.hpp": [("OUTPUT_TILES_PER_WG = 4;", "OUTPUT_TILES_PER_WG = 2;")],
    "gemm_a8w8_mxfp8_scale_host.cc": [
        ("[--tiles 0|4]", "[--tiles 0|2]"),
        ("opts.tiles != 4", "opts.tiles != 2"),
        ("--tiles must be 0 (auto) or 4", "--tiles must be 0 (auto) or 2"),
        ("int pick_output_tiles_per_wg(int, int, int) { return 4; }", "int pick_output_tiles_per_wg(int, int, int) { return 2; }"),
    ],
    "gemm_a8w8_blockscale_bpreshuffle_launch.cc": [
        ("ceil_div_scale(args.m / 256, 4)", "ceil_div_scale(args.m / 256, 2)"),
        ("tiles != 4", "tiles != 2"),
    ],
    "blockscale_bpreshuffle.py": [
        ("`tiles` may be 0/4.", "`tiles` may be 0/2."),
        ("tiles not in (0, 4)", "tiles not in (0, 2)"),
        ("tiles must be 0 or 4", "tiles must be 0 or 2"),
    ],
}
for name, pairs in replacements.items():
    p = target / name
    source = p.read_text()
    for before, after in pairs:
        assert source.count(before) == 1, (name, before)
        source = source.replace(before, after)
    source = source.replace("tile4 experiment", "tile2 experiment")
    p.write_text(source)

patch_dir = here / "candidate_patches/tile2"
patch_dir.mkdir(exist_ok=True)
hashes = {}
for name in tile4["candidate_source_sha256"]:
    old = (work / "baseline" / name).read_bytes()
    new = (target / name).read_bytes()
    hashes[name] = hashlib.sha256(new).hexdigest()
    if old != new:
        patch = "".join(difflib.unified_diff(old.decode().splitlines(True), new.decode().splitlines(True),
                                              fromfile="a/" + name, tofile="b/" + name))
        (patch_dir / (name + ".patch")).write_text(patch)
manifest = dict(tile4,
    candidate="current regroll_release8 with persistent tile2",
    output_tiles_per_wg=2,
    mapping="block_m=(wgid/num_tiles_n)*2+output_tile; block_n=wgid%num_tiles_n",
    candidate_source_sha256=hashes,
)
(here / "tile2_candidate.json").write_text(json.dumps(manifest, indent=2) + "\n")
print(target)
