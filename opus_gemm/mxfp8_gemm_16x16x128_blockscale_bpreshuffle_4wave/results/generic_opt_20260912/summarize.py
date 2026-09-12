#!/usr/bin/env python3
"""Rebuild the experiment index and verify every saved source patch."""
from collections import defaultdict
import hashlib
import json
from pathlib import Path
import re
import shutil
import statistics
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
WORK = Path((HERE / "work_path.txt").read_text().strip())


def read(path, default=None):
    return json.loads(path.read_text()) if path.exists() else default


def write(name, value):
    (HERE / name).write_text(json.dumps(value, indent=2) + "\n")


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fingerprints(path):
    result = {}
    name, words, instructions = None, [], 0
    for line in path.read_text().splitlines():
        symbol = re.fullmatch(r"[0-9a-fA-F]+ <([^>]+)>:", line)
        if symbol:
            name, words, instructions = symbol[1], [], 0
        elif name and "//" in line:
            assembly, tail = line.split("//", 1)
            if assembly.strip().startswith("s_code_end"):
                continue
            encoded = re.match(r"\s*[0-9a-fA-F]+:\s*((?:[0-9a-fA-F]{8}(?:\s+|$))+)", tail)
            assert encoded, line
            words.extend(encoded[1].split())
            instructions += 1
            if assembly.strip().startswith("s_endpgm"):
                result[name] = dict(instructions=instructions, words=len(words),
                                    encoding_sha256=hashlib.sha256(" ".join(words).encode()).hexdigest())
                name = None
    return result


builds = read(HERE / "build_results.json", {})
rejected = read(HERE / "early_rejections.json", {})
baseline = read(HERE / "baseline_source/candidate.json")
for filename, expected in baseline["source_hashes"].items():
    assert sha(HERE / "baseline_source" / filename) == expected

windows = []
for directory in sorted((HERE / "shared_allocations").iterdir()):
    summary = read(directory / "summary.json")
    if summary is None:
        continue
    metadata = read(directory / "metadata.json")
    brackets = read(directory / "bracketed_comparisons.json", [])
    reference = metadata.get("comparison_reference", "baseline")
    records = read(directory / "records.json", [])
    for row in summary:
        samples = [r for r in records if r["name"] == row["name"] and r["dtype"] == row["dtype"]]
        paired = [r["speedup_percent"] for r in brackets
                  if r["name"] == row["name"] and r["dtype"] == row["dtype"]]
        windows.append(dict(tag=directory.name, comparison_reference=reference, **row,
                            source_sha256=metadata["versions"][row["name"]]["source_sha256"],
                            timed_samples=len(samples),
                            median_paired_speedup_percent=statistics.median(paired) if paired else None,
                            paired_speedups_percent=paired, positive_pairs=sum(v > 0 for v in paired)))
write("screening_windows.json", windows)

validation = defaultdict(lambda: defaultdict(list))
for kind in ["shape_validation", "full_validation"]:
    for path in sorted((HERE / kind).glob("*/results.json")):
        data = read(path)
        for name in sorted({r["name"] for r in data["records"]}):
            records = [r for r in data["records"] if r["name"] == name]
            assert all(r["exact_equal"] for r in records)
            validation[name][kind].append(dict(tag=path.parent.name, checks=len(records)))

all_fingerprints = read(HERE / "encoding_fingerprints.json", {})
previous_index = {r["name"]: r for r in read(HERE / "candidate_index.json", [])}
selection = read(HERE / "selected/candidate.json", {})
reconstruction, index = [], []
names = ["baseline"] + sorted(p.name for p in (HERE / "candidate_patches").iterdir() if p.is_dir())
for name in names:
    directory = WORK / name
    metadata_path = (HERE / "baseline_source" if name == "baseline" else HERE / "candidate_patches" / name) / "candidate.json"
    metadata = read(metadata_path)
    if name != "baseline":
        patch = metadata_path.parent / "change.patch"
        with tempfile.TemporaryDirectory(prefix="mxfp8_patch_check_") as temp:
            dest = Path(temp)
            shutil.copy2(HERE / "baseline_source/tmpl_generic.hpp", dest / "tmpl_generic.hpp")
            subprocess.run(["patch", "--batch", "--forward", "-p1", "-i", str(patch)],
                           cwd=dest, check=True, capture_output=True, text=True)
            reconstructed = sha(dest / "tmpl_generic.hpp")
        assert reconstructed == metadata["source_hashes"]["tmpl_generic.hpp"], name
        for filename, expected in metadata["source_hashes"].items():
            if filename != "tmpl_generic.hpp":
                assert expected == baseline["source_hashes"][filename], (name, filename)
        reconstruction.append(dict(name=name, status="PASS", source_sha256=reconstructed,
                                   patch_sha256=sha(patch), unchanged_support_files=True))
    artifacts = previous_index.get(name, {}).get("artifact_hashes", {})
    if directory.exists():
        for filename, expected in metadata["source_hashes"].items():
            assert sha(directory / filename) == expected, (name, filename)
        for filename in ["device.isa", "device.notes", "libblockscale_bpreshuffle.so",
                         "gemm_a8w8_blockscale_bpreshuffle.exe"]:
            path = directory / "build" / filename
            if path.exists():
                artifacts[filename] = sha(path)
        if (directory / "build/device.isa").exists():
            all_fingerprints[name] = fingerprints(directory / "build/device.isa")
            assert len(all_fingerprints[name]) == 2, name
    source_hash = metadata["source_hashes"]["tmpl_generic.hpp"]
    evidence = [r for r in windows if r["source_sha256"] == source_hash]
    audit = read(HERE / "audits" / (name + ".json"))
    status = (rejected[name]["status"] if name in rejected else "MEASURED" if evidence
              else "AUDITED" if audit else "BUILT" if builds.get(name, {}).get("returncode") == 0
              else "BUILD_FAILED" if name in builds else "SOURCE_SAVED")
    selected = name == selection.get("name")
    if selected:
        status = "SELECTED"
    index.append(dict(name=name, status=status, source_sha256=source_hash,
                      config=metadata["config"], build=builds.get(name),
                      static_audit=audit["status"] if audit else None,
                      rejection=rejected.get(name), validation=validation[name],
                      measurement_tags=sorted({r["tag"] for r in evidence}), artifact_hashes=artifacts,
                      instruction_equivalent_measured_candidate=selection.get("selected_from") if selected else None))

assert all_fingerprints.get("baseline", baseline["expected_generic_isa"]) == baseline["expected_generic_isa"]
if not all_fingerprints:
    all_fingerprints = read(HERE / "encoding_fingerprints.json", {})
write("encoding_fingerprints.json", all_fingerprints)
write("patch_reconstruction.json", reconstruction)
write("candidate_index.json", index)

groups = defaultdict(list)
for name, functions in all_fingerprints.items():
    for function, record in functions.items():
        groups[(function, record["encoding_sha256"])].append(name)
duplicates = [dict(function=function, encoding_sha256=encoding, names=members)
              for (function, encoding), members in groups.items() if len(members) > 1]
write("duplicate_encodings.json", duplicates)
print(f"Indexed {len(index)} versions, {len(windows)} timing rows; reconstructed {len(reconstruction)} patches exactly.")
