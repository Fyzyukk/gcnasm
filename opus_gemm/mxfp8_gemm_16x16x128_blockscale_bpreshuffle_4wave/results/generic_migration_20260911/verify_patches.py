#!/usr/bin/env python3
"""Reconstruct all generic experiment sources from their frozen baseline patches."""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

here = Path(__file__).resolve().parent
index = json.loads((here / "candidate_index.json").read_text())
records = []
with tempfile.TemporaryDirectory(prefix="mxfp8_generic_patch_check_") as temporary:
    for item in index["candidates"]:
        directory = Path(temporary) / item["name"]
        directory.mkdir()
        hashes = {}
        for filename, expected in item["source_hashes"].items():
            shutil.copy2(here / "baseline_source" / filename, directory / filename)
            patch = here / "candidate_patches" / item["name"] / (filename + ".patch")
            result = subprocess.run(["patch", "--batch", "--forward", "-p1"], cwd=directory,
                                    input=patch.read_text(), capture_output=True, text=True)
            assert result.returncode == 0, (item["name"], result.stdout, result.stderr)
            digest = hashlib.sha256((directory / filename).read_bytes()).hexdigest()
            assert digest == expected, (item["name"], filename, digest, expected)
            hashes[filename] = digest
        records.append(dict(name=item["name"], status="PASS", source_hashes=hashes))
(here / "patch_reconstruction.json").write_text(json.dumps(dict(status="PASS", candidates=records), indent=2) + "\n")
print("All", len(records), "baseline-relative candidate patches match their source hashes")
