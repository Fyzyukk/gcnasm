#!/usr/bin/env python3
"""Archive this experiment's temporary files, verify hashes, then remove duplicates."""
import datetime
import hashlib
import json
from pathlib import Path
import shutil
import tarfile

HERE = Path(__file__).resolve().parent
WORK = Path((HERE / "work_path.txt").read_text().strip())
assert WORK.parent == Path("/tmp") and WORK.name.startswith("mxfp8_generic_opt_20260912_")
assert not (HERE / "archive_manifest.json").exists(), "This experiment is already archived"
selection = json.loads((HERE / "selected/candidate.json").read_text())
reproduction = json.loads((HERE / "shared_allocations/reproduction_smoke_gpu2/metadata.json").read_text())
reproduction_work = Path(reproduction["versions"]["baseline"]["path"]).parent
assert reproduction_work.parent == Path("/tmp") and reproduction_work.name.startswith("mxfp8_4wave_compare_")
stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%d_%H%M%S")
dest = Path("/root/workspace/gcnasm_new/archives") / ("mxfp8_generic_opt_" + stamp)
dest.mkdir(parents=True, exist_ok=False)
archive = dest / "candidates_and_traces.tar.gz"


def digest(path):
    with path.open("rb") as stream:
        value = hashlib.sha256()
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            value.update(block)
    return value.hexdigest()


files, manifest = [], {}
for prefix, source in [("work", WORK), ("reproduction", reproduction_work)]:
    for path in sorted(source.rglob("*")):
        relative = path.relative_to(source)
        # This check-only directory links to the retained production build.
        if prefix == "work" and relative.parts[0] == "production_top":
            continue
        if path.is_symlink():
            raise AssertionError(("Unexpected symlink", path))
        if not path.is_file():
            continue
        name = str(Path(prefix) / relative)
        files.append((name, path))
        manifest[name] = dict(bytes=path.stat().st_size, sha256=digest(path))

(dest / "file_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
with tarfile.open(archive, "w:gz", compresslevel=6) as output:
    for name, path in files:
        output.add(path, arcname=name, recursive=False)

verified = set()
with tarfile.open(archive, "r:gz") as saved:
    for member in saved:
        assert member.isfile() and member.name in manifest, member.name
        stream = saved.extractfile(member)
        value = hashlib.sha256()
        size = 0
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            value.update(block)
            size += len(block)
        assert manifest[member.name] == dict(bytes=size, sha256=value.hexdigest()), member.name
        verified.add(member.name)
assert verified == set(manifest)
# Recheck the originals before deleting anything in case a job modified them.
for name, path in files:
    assert path.stat().st_size == manifest[name]["bytes"] and digest(path) == manifest[name]["sha256"], path

keep = {"baseline", selection["name"], selection["selected_from"], "production_top"}
candidates = {path.name for path in (HERE / "candidate_patches").iterdir() if path.is_dir()}
remove = [WORK / name for name in sorted(candidates - keep) if (WORK / name).is_dir()]
if (WORK / "profiles").is_dir():
    remove.append(WORK / "profiles")
remove.append(reproduction_work)
removed_files = []
for directory in remove:
    prefix = "reproduction" if directory == reproduction_work else "work"
    source = reproduction_work if prefix == "reproduction" else WORK
    for path in directory.rglob("*"):
        if path.is_file():
            name = str(Path(prefix) / path.relative_to(source))
            assert name in verified, path
            removed_files.append(name)
    shutil.rmtree(directory)

record = dict(status="VERIFIED_AND_CLEANED", timestamp_utc=stamp, archive=str(archive),
              archive_sha256=digest(archive), archive_bytes=archive.stat().st_size,
              file_manifest=str(dest / "file_manifest.json"),
              file_manifest_sha256=digest(dest / "file_manifest.json"),
              archived_files=len(manifest), uncompressed_bytes=sum(r["bytes"] for r in manifest.values()),
              every_archived_file_sha256_verified=True, original_work_path=str(WORK),
              original_reproduction_work_path=str(reproduction_work), retained_work_directories=sorted(keep),
              removed_directories=[str(path) for path in remove], removed_files=len(removed_files),
              removed_bytes=sum(manifest[name]["bytes"] for name in removed_files),
              scope="Only this experiment's temporary candidate/reproduction builds and raw ATT; production, baseline and selected builds retained")
(dest / "removed_files.json").write_text(json.dumps(removed_files, indent=2) + "\n")
(HERE / "archive_manifest.json").write_text(json.dumps(record, indent=2) + "\n")
for path in HERE.rglob("__pycache__"):
    shutil.rmtree(path)
print(json.dumps({k: v for k, v in record.items() if k != "removed_directories"}, indent=2))
