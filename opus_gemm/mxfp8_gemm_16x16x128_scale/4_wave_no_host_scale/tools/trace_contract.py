#!/usr/bin/env python3
"""One untimed-profiled GEMM dispatch: verify no scale preprocessing kernel/workspace."""
import argparse
import csv
import fcntl
import json
from pathlib import Path
import subprocess
from run_suite import environment, guard, identity, sha, save

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("binary", type=Path)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    binary = args.binary.resolve(strict=True)
    args.out.mkdir(parents=True, exist_ok=False)
    out = args.out.resolve()
    env = environment()
    command = ["/opt/rocm/bin/rocprofv3", "--kernel-trace", "--hip-trace",
               "--memory-allocation-trace", "--output-format", "csv", "--output-directory", str(out / "trace"),
               "--output-file", "contract", "--", str(binary),
               "-m", "8192", "-n", "8192", "-k", "8192", "-b", "1", "-v", "0", "-w", "0", "-i", "1"]
    with open("/tmp/mxfp8_gpu7.lock", "a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        guard(out, "before_identity")
        device = identity(binary, env, out)
        guard(out, "before_trace")
        result = subprocess.run(command, env=env, text=True, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, timeout=180)
        (out / "profiler.log").write_text(result.stdout)
        if result.returncode:
            raise RuntimeError(f"profiler failed: {result.returncode}")
        guard(out, "after_trace")
    kernel_files = list((out / "trace").rglob("*kernel_trace.csv"))
    hip_files = list((out / "trace").rglob("*hip_api_trace.csv"))
    if len(kernel_files) != 1 or len(hip_files) != 1:
        raise RuntimeError(f"unexpected trace files: kernel={kernel_files}, hip={hip_files}")
    with kernel_files[0].open() as stream:
        kernels = list(csv.DictReader(stream))
    with hip_files[0].open() as stream:
        hip = list(csv.DictReader(stream))
    mallocs = [row for row in hip if any(value == "hipMalloc" for value in row.values())]
    launches = [row for row in hip if any(value == "hipLaunchKernel" for value in row.values())]
    if len(kernels) != 1 or len(mallocs) != 5 or len(launches) != 1:
        raise RuntimeError(f"unexpected dispatch/allocation contract: kernels={len(kernels)}, malloc={len(mallocs)}, launch={len(launches)}")
    report = dict(status="PASS", binary=str(binary), binary_sha256=sha(binary), device=device,
                  command=command, kernel_dispatches=len(kernels), explicit_hip_malloc_calls=len(mallocs),
                  hip_launch_calls=len(launches), kernel_rows=kernels,
                  allocation_roles=["A input", "B input", "C output", "row-major SFA input", "row-major SFB input"],
                  extra_global_workspace_bytes=0, profiler_timing_used_for_performance=False)
    save(out / "contract.json", report)
    print(json.dumps(report, indent=2))

if __name__ == "__main__":
    main()
