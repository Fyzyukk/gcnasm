#!/usr/bin/env python3
import json
from pathlib import Path
import re
import subprocess
import sys

here = Path(__file__).resolve().parent
work = Path((here / "work_path.txt").read_text().strip())
index = json.loads((here / "candidate_index.json").read_text())
names = sys.argv[1:] or [x["name"] for x in index["candidates"]]
logs = here / "build_logs"
logs.mkdir(exist_ok=True)
results = json.loads((here / "build_results.json").read_text()) if (here / "build_results.json").exists() else {}
for name in names:
    path = work / name
    with (logs / (name + ".log")).open("w") as log:
        proc = subprocess.run(["make", "-j3", "all", "inspect"], cwd=path, stdout=log, stderr=subprocess.STDOUT)
    record = dict(returncode=proc.returncode)
    if proc.returncode == 0:
        notes = re.split(r"  - \.agpr_count:", (path / "build/device.notes").read_text())[1:]
        record["resources"] = [{key: int(re.search(r"\." + key + r":\s*(\d+)", note)[1]) for key in [
            "vgpr_count", "sgpr_count", "private_segment_fixed_size", "vgpr_spill_count", "sgpr_spill_count"]} for note in notes[:2]]
    results[name] = record
    (here / "build_results.json").write_text(json.dumps(results, indent=2) + "\n")
    print(name, json.dumps(record), flush=True)
