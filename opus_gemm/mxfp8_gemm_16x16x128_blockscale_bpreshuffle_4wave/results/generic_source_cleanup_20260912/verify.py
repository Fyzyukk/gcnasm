#!/usr/bin/env python3
"""Rebuild the cleanup and frozen baseline; compare complete GPU payloads offline."""
import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
BASE = HERE.parent / "generic_latency_20260912/baseline_source"
TOOLCHAIN = Path(os.environ.get("TOOLCHAIN", "/root/toolchains/rocm-llvm23-46fcb339-build"))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    work = Path(tempfile.mkdtemp(prefix="mxfp8_cleanup_verify_"))
    snapshots, artifacts = {}, {}
    for name, source, manifest in [
        ("baseline", BASE, BASE / "candidate.json"),
        ("cleaned", ROOT, HERE / "selected/candidate.json"),
    ]:
        metadata = json.loads(manifest.read_text())
        directory = work / name
        directory.mkdir()
        snapshots[name] = metadata["source_hashes"]
        for filename, expected in metadata["source_hashes"].items():
            assert sha(source / filename) == expected, (name, filename)
            shutil.copy2(source / filename, directory / filename)
        with (directory / "build.log").open("x") as log:
            subprocess.run(["make", "-j3", "all", "inspect"], cwd=directory,
                           stdout=log, stderr=subprocess.STDOUT, check=True)
        build = directory / "build"
        subprocess.run([str(TOOLCHAIN / "bin/llvm-objcopy"),
                        "--dump-section=.hip_fatbin=" + str(build / "library.fb"),
                        str(build / "libblockscale_bpreshuffle.so"), str(build / "inspect.so")],
                       check=True, capture_output=True)
        artifacts[name] = {filename: sha(build / filename) for filename in
                           ["device.co", "device.fb", "device.notes", "library.fb",
                            "libblockscale_bpreshuffle.so", "gemm_a8w8_blockscale_bpreshuffle.exe"]}
        print(name, "fresh CPU build complete", flush=True)
    for filename in ["device.co", "device.fb", "device.notes", "library.fb"]:
        assert artifacts["baseline"][filename] == artifacts["cleaned"][filename], filename
    source = (ROOT / "tmpl_generic.hpp").read_text()
    assert "#define MXFP8_" not in source and "#undef MXFP8_" not in source
    changed = [filename for filename in snapshots["baseline"]
               if snapshots["baseline"][filename] != snapshots["cleaned"][filename]]
    assert changed == ["tmpl_generic.hpp"]
    stamp = datetime.datetime.now(datetime.timezone.utc)
    report = dict(status="PASS", timestamp_utc=stamp.isoformat(), work_directory=str(work),
                  gpu_launched=False, baseline_commit="f483077e0263bc8d39ad810ad4c1f03b93727702",
                  source_hashes=snapshots, artifacts=artifacts, changed_source_files=changed,
                  macro_definitions=0, macro_undefinitions=0, if_constexpr_count=source.count("if constexpr"),
                  executable_device_code_objects_identical=True,
                  shared_library_device_fatbins_identical=True, complete_device_metadata_identical=True)
    path = HERE / ("verification_" + stamp.strftime("%Y%m%dT%H%M%S") + ".json")
    with path.open("x") as out:
        out.write(json.dumps(report, indent=2) + "\n")
    print("PASS: complete device binaries and metadata are byte-identical; no GPU launched.")
    print(path)


if __name__ == "__main__":
    main()
