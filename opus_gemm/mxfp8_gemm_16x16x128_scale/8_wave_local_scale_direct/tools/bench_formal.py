#!/usr/bin/env python3
"""Fixed-contract GPU7 comparisons; correctness must pass before timing."""

import argparse
import csv
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import statistics
import subprocess
import time


EXPECTED_HASH = "bb8d97357b61bd71"
FLOPS = 2 * 8192**3


def check_gpu7_available(out, label):
    """No benchmark child is alive here, so any GPU7 context is foreign."""
    result = subprocess.run(["rocm-smi", "--showpidgpus"], text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    (out / f"gpu_processes_{label}.log").write_text(result.stdout)
    if result.returncode or "GPUs Indexed by PID" not in result.stdout:
        raise RuntimeError("could not verify GPU7 process ownership")
    owners = []
    for match in re.finditer(
            r"PID (\d+) is using [1-9]\d* DRM device\(s\):\s*\n([\d \t]+)",
            result.stdout):
        if 7 in map(int, match[2].split()):
            owners.append(int(match[1]))
    if owners:
        quality = dict(valid_for_performance_selection=False,
                       reason="foreign processes occupy GPU7", pids=owners,
                       snapshot=label, timestamp_ns=time.time_ns())
        (out / "quality.json").write_text(json.dumps(quality, indent=2) + "\n")
        raise RuntimeError(f"GPU7 is occupied by PID(s) {owners}; no further kernels launched")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--rounds", type=int, default=3)
    parser.add_argument("--order", choices=("abba", "rotate"), default="abba")
    parser.add_argument("images", nargs="+", help="tag=/path/to/kernel.exe")
    args = parser.parse_args()
    images = dict(item.split("=", 1) for item in args.images)
    if len(images) != len(args.images) or args.rounds < 1:
        parser.error("use unique tags and positive rounds")
    if args.order == "abba" and len(images) != 2:
        parser.error("ABBA requires exactly two images")
    images = {tag: Path(path).resolve(strict=True) for tag, path in images.items()}
    args.out.mkdir(parents=True, exist_ok=False)
    env = os.environ.copy()
    for key in list(env):
        if key.startswith("MXFP8_"):
            del env[key]
    env.update(OMP_TOOL="disabled", HIP_VISIBLE_DEVICES="7",
               MXFP8_RANDOM_SEED="20260909")
    shape = ["-m", "8192", "-n", "8192", "-k", "8192", "-b", "1", "-v", "0"]
    manifest = {
        "contract": dict(M=8192, N=8192, K=8192, b=1, w=200, i=100,
                         GPU=7, seed=20260909),
        "order": args.order, "rounds": args.rounds,
        "images": {tag: {"path": str(path),
                         "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
                   for tag, path in images.items()},
    }
    for tag, path in images.items():
        notes = path.with_name("kernel.notes").read_text()
        fields = ("vgpr_count", "agpr_count", "sgpr_count",
                  "private_segment_fixed_size", "group_segment_fixed_size")
        resources = {}
        for field in fields:
            match = re.search(r"\." + field + r":\s+(\d+)", notes)
            if not match:
                raise RuntimeError(f"{tag}: missing {field} in kernel.notes")
            resources[field] = int(match[1])
        manifest["images"][tag]["resources"] = resources
        # This clang23 backend reports TotalNumVgprs in .vgpr_count,
        # including the AGPR allocation (do not add .agpr_count again).
        assembly = path.with_name("kernel.s").read_text()
        total = re.search(r"TotalNumVgprs:\s+(\d+)", assembly)
        if not total or int(total[1]) != resources["vgpr_count"]:
            raise RuntimeError(f"{tag}: inconsistent physical vector-register metadata")
        if resources["vgpr_count"] > 256:
            raise RuntimeError(f"{tag}: exceeds 256 physical vector registers")
        if resources["private_segment_fixed_size"]:
            raise RuntimeError(f"{tag}: scratch allocation is not allowed")
        config = path.with_name("config.sh")
        if config.exists():
            manifest["images"][tag]["build_config"] = config.read_text()
    (args.out / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    rows = []
    with open("/tmp/mxfp8_gpu7.lock", "a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        check_gpu7_available(args.out, "before_hash")
        # These are correctness-only launches, never performance observations.
        for tag, path in images.items():
            output = subprocess.check_output(
                [str(path), *shape, "-w", "0", "-i", "1"],
                env={**env, "MXFP8_OUTPUT_HASH": "1"},
                stderr=subprocess.STDOUT, text=True)
            (args.out / f"hash_{tag}.log").write_text(output)
            if f"Output bit hash: {EXPECTED_HASH} " not in output:
                raise RuntimeError(f"{tag}: incorrect full-size hash; excluded from timing")
            if "block=512," not in output:
                raise RuntimeError(f"{tag}: expected eight waves / 512 threads")
            print(f"hash {tag}: {EXPECTED_HASH}", flush=True)
        with (args.out / "results.tsv").open("w") as result_file:
            writer = csv.DictWriter(result_file, delimiter="\t", fieldnames=(
                "round", "position", "tag", "ms", "tflops", "timestamp_ns"))
            writer.writeheader()
            tags = list(images)
            for round_id in range(1, args.rounds + 1):
                check_gpu7_available(args.out, f"before_r{round_id:02d}")
                if args.order == "abba":
                    first, second = tags if round_id % 2 else tags[::-1]
                    order = [first, second, second, first]
                else:
                    shift = (round_id - 1) % len(tags)
                    order = tags[shift:] + tags[:shift]
                    if (round_id - 1) // len(tags) % 2:
                        order.reverse()
                for position, tag in enumerate(order, 1):
                    output = subprocess.check_output(
                        [str(images[tag]), *shape, "-w", "200", "-i", "100"],
                        env=env, stderr=subprocess.STDOUT, text=True)
                    (args.out / f"r{round_id:02d}_p{position}_{tag}.log").write_text(output)
                    match = re.search(r"avg_time=([\d.]+) ms, ([\d.]+) TFlops", output)
                    if not match:
                        raise RuntimeError(f"{tag}: missing timing")
                    row = dict(round=round_id, position=position, tag=tag,
                               ms=float(match[1]), tflops=float(match[2]),
                               timestamp_ns=time.time_ns())
                    writer.writerow(row)
                    result_file.flush()
                    rows.append(row)
                    print(f"r{round_id:02d} p{position} {tag}: "
                          f"{row['ms']:.4f} ms {row['tflops'] / 1000:.5f}P", flush=True)
            check_gpu7_available(args.out, "after_last_round")
    summary = {}
    baseline = next(iter(images))
    base = [r["tflops"] for r in rows if r["tag"] == baseline]
    for tag in images:
        values = [r["tflops"] for r in rows if r["tag"] == tag]
        ratios = []
        for round_id in range(1, args.rounds + 1):
            ref = [r["tflops"] for r in rows if r["round"] == round_id and r["tag"] == baseline]
            cand = [r["tflops"] for r in rows if r["round"] == round_id and r["tag"] == tag]
            ratios.append(statistics.mean(cand) / statistics.mean(ref) - 1)
        summary[tag] = dict(
            observations=len(values), min_ms=FLOPS / (max(values) * 1e9),
            peak_p=max(values) / 1000, mean_p=statistics.mean(values) / 1000,
            min_time_gain_pct=(max(values) / max(base) - 1) * 100,
            mean_gain_pct=(statistics.mean(values) / statistics.mean(base) - 1) * 100,
            paired_gains_pct=[x * 100 for x in ratios],
            paired_wins=sum(x > 0 for x in ratios), paired_rounds=len(ratios))
    (args.out / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    for tag, result in summary.items():
        print(f"summary {tag}: N={result['observations']} "
              f"min={result['min_ms']:.6f} ms peak={result['peak_p']:.6f}P "
              f"min-time gain={result['min_time_gain_pct']:+.4f}% "
              f"mean gain={result['mean_gain_pct']:+.4f}% "
              f"paired wins={result['paired_wins']}/{result['paired_rounds']}", flush=True)


if __name__ == "__main__":
    main()
