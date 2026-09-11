#!/usr/bin/env python3
"""Collect every recorded timing window without selecting fastest repeats."""
import json
from pathlib import Path
import statistics

here = Path(__file__).resolve().parent
index = json.loads((here / "candidate_index.json").read_text())
builds = json.loads((here / "build_results.json").read_text())
out = []
for candidate in index["candidates"]:
    name = candidate["name"]
    row = dict(candidate, build=builds.get(name), measurements=[], cli_measurements=[])
    for path in sorted((here / "shared_allocations").glob("*/summary.json")):
        values = [v for v in json.loads(path.read_text()) if v["name"] == name]
        if not values:
            continue
        comparisons = json.loads((path.parent / "bracketed_comparisons.json").read_text())
        for value in values:
            speeds = [v["speedup_percent"] for v in comparisons if v["name"] == name and v["dtype"] == value["dtype"]]
            row["measurements"].append(dict(window=path.parent.name, **value,
                                            paired_speedup_percent=speeds,
                                            paired_median_speedup_percent=statistics.median(speeds)))
    for path in sorted((here / "measurements").glob("*/summary.json")):
        for value in json.loads(path.read_text()):
            if value["name"] == name:
                row["cli_measurements"].append(dict(window=path.parent.name, **value))
    out.append(row)
(here / "screening_summary.json").write_text(json.dumps(out, indent=2) + "\n")
print("Recorded", len(out), "candidates and all completed timing windows")
