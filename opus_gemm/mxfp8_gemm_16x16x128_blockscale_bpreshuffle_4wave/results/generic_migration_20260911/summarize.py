#!/usr/bin/env python3
"""Record every candidate and contemporaneous timing window, including failures."""
import json
from pathlib import Path
import statistics

here = Path(__file__).resolve().parent
index = json.loads((here / "candidate_index.json").read_text())
builds = json.loads((here / "build_results.json").read_text())
summary = []
for candidate in index["candidates"]:
    name = candidate["name"]
    row = dict(candidate, build=builds.get(name), measurements=[], cli_measurements=[])
    row["static_audit_passed"] = (here / "audits" / (name + ".json")).exists()
    for path in sorted((here / "shared_allocations").glob("*/summary.json")):
        values = [v for v in json.loads(path.read_text()) if v["name"] == name]
        if not values:
            continue
        metadata = json.loads((path.parent / "metadata.json").read_text())
        comparisons = json.loads((path.parent / "bracketed_comparisons.json").read_text())
        for value in values:
            speeds = [v["speedup_percent"] for v in comparisons if v["name"] == name and v["dtype"] == value["dtype"]]
            row["measurements"].append(dict(window=path.parent.name, **value,
                reference=metadata.get("comparison_reference", "baseline"),
                paired_speedup_percent=speeds,
                paired_median_speedup_percent=statistics.median(speeds) if speeds else None))
    for path in sorted((here / "measurements").glob("*/summary.json")):
        for value in json.loads(path.read_text()):
            if value["name"] == name:
                row["cli_measurements"].append(dict(window=path.parent.name, **value))
    summary.append(row)
(here / "screening_summary.json").write_text(json.dumps(summary, indent=2) + "\n")
print("Recorded", len(summary), "candidates and all completed timing windows")
