#!/usr/bin/env python3
"""Reuse the recorded round3 checks with each version's automatic tile mode.

Each library has one supported output tile count: baseline=1, tile2=2, tile4=4.
The common C ABI argument 0 selects that count. Results stay in this directory.
"""
import hashlib
import json
from pathlib import Path
import re
import sys

here = Path(__file__).resolve().parent
previous = here.parent / "continuation_20260911/round3"
mode = sys.argv.pop(1)
driver = {"cli": "run_resume.py", "verify": "verify_full.py", "shared": "benchmark_shared_cli.py"}[mode]
source = (previous / driver).read_text()
original_hash = hashlib.sha256(source.encode()).hexdigest()
if mode == "verify":
    old = 'int(dtype == "bf16"), 1, stream)'
    assert source.count(old) == 1
    source = source.replace(old, 'int(dtype == "bf16"), 0, stream)')
elif mode == "shared":
    assert source.count("(ptr,flag,1,stream)") == 3
    source = source.replace("(ptr,flag,1,stream)", "(ptr,flag,0,stream)")

namespace = {"__name__": "__main__", "__file__": str(Path(__file__).resolve())}
exec(compile(source, str(previous / driver), "exec"), namespace)
output = namespace["output" if mode == "cli" else "dest"]
tile_counts = {"baseline": 1, "tile2": 2, "tile4": 4}
versions = namespace["args"].names if mode == "cli" else namespace["names"]
(output / "tile_mode_identity.json").write_text(json.dumps({
    "baseline": "current regroll_release8 tile1; not the older second-round baseline",
    "output_tile_shape": [256, 256],
    "output_tiles_per_wg": {name: tile_counts[name] for name in versions},
    "tiles_argument": 0,
    "driver": str(previous / driver),
    "driver_sha256": original_hash,
}, indent=2) + "\n")
if mode == "cli":
    records = namespace["records"]
    for record in records:
        text = (output / record["log"]).read_text()
        tiles = int(re.search(r"output_tiles_per_wg=(\d+)", text).group(1))
        assert tiles == tile_counts[record["name"]]
        record["output_tiles_per_wg"] = tiles
        record["grid"] = [int(v) for v in re.search(r"grid=\((\d+),(\d+),(\d+)\)", text).groups()]
    (output / "records.json").write_text(json.dumps(records, indent=2) + "\n")
