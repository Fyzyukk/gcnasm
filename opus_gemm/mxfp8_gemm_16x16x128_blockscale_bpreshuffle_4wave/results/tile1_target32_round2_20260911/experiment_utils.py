"""Record isolated candidates as complete baseline-relative source patches."""
import difflib
import hashlib
import json
from pathlib import Path
import shutil

HERE = Path(__file__).resolve().parent
WORK = Path((HERE / "work_path.txt").read_text().strip())
BASE = HERE / "baseline_source"
ORIGINAL = (BASE / "tmpl.hpp").read_text()


def replace_once(source, old, new):
    assert source.count(old) == 1, (source.count(old), old[:100])
    return source.replace(old, new)


def record_candidate(name, source, config, parent):
    target = WORK / name
    patch_dir = HERE / "candidate_patches" / name
    index = json.loads((HERE / "candidate_index.json").read_text())
    assert not target.exists() and not patch_dir.exists(), name
    assert not any(c["name"] == name for c in index["candidates"]), name
    shutil.copytree(BASE, target)
    (target / "tmpl.hpp").write_text(source)
    patch_dir.mkdir(parents=True)
    (patch_dir / "tmpl.patch").write_text("".join(difflib.unified_diff(
        ORIGINAL.splitlines(True), source.splitlines(True),
        fromfile="a/tmpl.hpp", tofile="b/tmpl.hpp")))
    record = dict(name=name, parent=parent, config=config,
                  source_sha256=hashlib.sha256(source.encode()).hexdigest(),
                  num_waves=4, output_tiles_per_wg=1,
                  per_accumulator_k_order_unchanged=True)
    for path in [target / "candidate.json", patch_dir / "candidate.json"]:
        path.write_text(json.dumps(record, indent=2) + "\n")
    index["candidates"].append(record)
    (HERE / "candidate_index.json").write_text(json.dumps(index, indent=2) + "\n")
    print(name, config, flush=True)
