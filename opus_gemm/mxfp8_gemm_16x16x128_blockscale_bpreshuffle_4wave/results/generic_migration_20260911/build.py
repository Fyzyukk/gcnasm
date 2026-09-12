#!/usr/bin/env python3
import json
from pathlib import Path
import re
import subprocess
import sys

here = Path(__file__).resolve().parent
work = Path((here / "work_path.txt").read_text().strip())
logs = here / "build_logs"
logs.mkdir(exist_ok=True)
record_path = here / "build_results.json"
results = json.loads(record_path.read_text()) if record_path.exists() else {}
failed = False
for name in sys.argv[1:]:
    with (logs / (name + ".log")).open("x") as log:
        proc = subprocess.run(["make", "-j3", "all", "inspect"], cwd=work/name, stdout=log, stderr=subprocess.STDOUT)
    result = dict(returncode=proc.returncode)
    failed = failed or proc.returncode != 0
    if proc.returncode == 0:
        notes = re.split(r"  - \.agpr_count:", (work/name/"build/device.notes").read_text())[1:]
        result["generic_resources"] = [
            {key: int(re.search(r"\."+key+r":\s*(\d+)", note)[1]) for key in ["vgpr_count", "sgpr_count", "group_segment_fixed_size", "private_segment_fixed_size", "vgpr_spill_count", "sgpr_spill_count"]}
            for note in notes[2:]]
    results[name] = result
    record_path.write_text(json.dumps(results, indent=2)+"\n")
    print(name, json.dumps(result), flush=True)
raise SystemExit(1 if failed else 0)
