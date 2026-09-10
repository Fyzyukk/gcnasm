#!/usr/bin/env python3
"""Guarded deterministic correctness and min-of-N comparisons; never overwrite results."""
import argparse
import csv
import datetime
import fcntl
import hashlib
import json
import math
import os
from pathlib import Path
import re
import statistics
import subprocess
import time
from static_common import audit

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def save(path, obj):
    path.write_text(json.dumps(obj, indent=2) + "\n")

def environment(seed=20260909):
    env = {k: v for k, v in os.environ.items() if not k.startswith("MXFP8_")}
    for key in ("ROCR_VISIBLE_DEVICES", "CUDA_VISIBLE_DEVICES", "GPU_DEVICE_ORDINAL"):
        env.pop(key, None)
    env.update(HIP_VISIBLE_DEVICES="7", OMP_TOOL="disabled", OMP_NUM_THREADS="32",
               OMP_DYNAMIC="FALSE", MXFP8_RANDOM_SEED=str(seed), PYTHONDONTWRITEBYTECODE="1")
    return env

def identity(binary, env, out):
    result = subprocess.run([str(binary), "--device-info"], env=env, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=True)
    (out / "device_identity.log").write_text(result.stdout)
    match = re.search(r"Device identity: hip_device=(\d+) pci=(\S+) arch=(\S+) cu=(\d+) warp=(\d+)", result.stdout)
    if not match or not match[3].startswith("gfx950") or match[5] != "64":
        raise RuntimeError("wrong or unidentified GPU")
    bus = subprocess.check_output(["rocm-smi", "--showbus"], text=True, stderr=subprocess.STDOUT)
    (out / "smi_bus.log").write_text(bus)
    mapping = {pci.lower(): int(index) for index, pci in re.findall(r"GPU\[(\d+)\].*PCI Bus:\s*(\S+)", bus)}
    pci = match[2].lower()
    if pci not in mapping:
        raise RuntimeError(f"HIP PCI {pci} does not map to SMI")
    return dict(hip_visible_devices=7, hip_device=int(match[1]), pci_bdf=pci,
                smi_index=mapping[pci], architecture=match[3], cu=int(match[4]), wave_size=64)

def guard(out, label):
    # Cross-GPU jobs can perturb power/fabric too. Require this full box to be quiet.
    result = subprocess.run(["rocm-smi", "--showpidgpus"], text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    (out / f"processes_{label}.log").write_text(result.stdout)
    if result.returncode or "GPUs Indexed by PID" not in result.stdout:
        raise RuntimeError("could not verify GPU ownership")
    pids = re.findall(r"\bPID (\d+) is using", result.stdout)
    if pids:
        save(out / "quality.json", dict(valid_for_selection=False,
             reason="foreign GPU process; no more launches", pids=pids, snapshot=label))
        raise RuntimeError(f"GPU(s) occupied by foreign PID(s): {pids}")

def invoke(out, label, binary, env, shape, verify=0, timing=False):
    m, n, batch = shape
    command = [str(binary), "-m", str(m), "-n", str(n), "-k", "8192", "-b", str(batch),
               "-v", str(verify), "-w", "200" if timing else "0", "-i", "100" if timing else "1"]
    selected_env = dict(env)
    if not timing:
        selected_env["MXFP8_OUTPUT_HASH"] = "1"
    started = time.time_ns()
    result = subprocess.run(command, env=selected_env, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=600)
    (out / f"{label}.log").write_text("COMMAND " + json.dumps(command) + "\n" + result.stdout)
    if result.returncode or "block=256," not in result.stdout:
        raise RuntimeError(f"execution/identity failure: {label}, code={result.returncode}")
    if timing:
        match = re.search(r"avg_time=([0-9.]+) ms, ([0-9.]+) TFlops", result.stdout)
        if not match:
            raise RuntimeError(f"missing timing: {label}")
        ms, reported = map(float, match.groups())
        tflops = 2 * m * n * 8192 * batch / (ms * 1e9)
        if not math.isfinite(ms) or ms <= 0 or abs(tflops / reported - 1) > 1e-5:
            raise RuntimeError(f"invalid timing: {label}")
        return dict(ms=ms, tflops=tflops, timestamp_ns=started)
    match = re.search(r"Output bit hash: ([0-9a-f]{16}) \((\d+) fp32 values\)", result.stdout)
    if not match or int(match[2]) != m * n * batch or "Output finite check: nonfinite=0" not in result.stdout:
        raise RuntimeError(f"missing/nonfinite full-output hash: {label}")
    if verify and (len(re.findall(r"^\[GEMM batch .*\] VALID$", result.stdout, re.M)) != batch
                   or "ALL BATCHES VALID" not in result.stdout):
        raise RuntimeError(f"CPU reference failed: {label}")
    return dict(hash=match[1], elements=int(match[2]), cpu_reference=bool(verify))

CASES = [
    ("unit", (256, 256, 1), {"MXFP8_UNIT_SCALE": "1"}),
    ("random", (256, 512, 1), {}),
    ("sfa_k", (512, 256, 1), {"MXFP8_SFA_K_PATTERN": "1"}),
    ("sfb_k", (256, 512, 1), {"MXFP8_SFB_K_PATTERN": "1"}),
    ("random_square", (512, 512, 1), {"MXFP8_RANDOM_SEED": "20260910"}),
    ("batch3", (256, 256, 3), {}),
    ("sfa_row", (768, 256, 2), {"MXFP8_SFA_ROW_PATTERN": "1"}),
    ("sfb_row", (256, 768, 2), {"MXFP8_SFB_ROW_PATTERN": "1"}),
]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("correctness", "bench"))
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--rounds", type=int, default=24)
    parser.add_argument("--extended", action="store_true")
    parser.add_argument("images", nargs="+", help="tag=/absolute/path/kernel.exe; first image is reference")
    args = parser.parse_args()
    images = dict(item.split("=", 1) for item in args.images)
    if len(images) != len(args.images) or args.rounds < 1 or any(not re.fullmatch(r"[a-zA-Z0-9_]+", tag) for tag in images):
        parser.error("positive rounds and unique simple tags required")
    images = {tag: Path(path).resolve(strict=True) for tag, path in images.items()}
    args.out.mkdir(parents=True, exist_ok=False)
    out = args.out.resolve()
    env = environment()
    manifest = dict(mode=args.mode, utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                    environment={k: env[k] for k in ("HIP_VISIBLE_DEVICES", "OMP_TOOL", "OMP_NUM_THREADS", "MXFP8_RANDOM_SEED")},
                    contract=dict(k=8192, m=8192, n=8192, batch=1, warmup=200, iterations=100,
                                  rounds=args.rounds, estimator="min-of-N; retain every observation"),
                    scripts={str(p): sha(p) for p in (Path(__file__), Path(__file__).with_name("static_common.py"))},
                    images={tag: dict(path=str(path), binary_sha256=sha(path), co_sha256=sha(path.with_name("kernel.co")),
                                      audit=audit(path.parent)) for tag, path in images.items()})
    save(out / "manifest.json", manifest)
    with open("/tmp/mxfp8_gpu7.lock", "a") as lock:
        print("Waiting for GPU7 lock", flush=True)
        fcntl.flock(lock, fcntl.LOCK_EX)
        guard(out, "before_identity")
        manifest["device"] = identity(next(iter(images.values())), env, out)
        save(out / "manifest.json", manifest)
        guard(out, "before_cases")
        hashes = {}
        if args.mode == "correctness":
            results, excluded = {}, {}
            for tag, binary in images.items():
                results[tag] = {}
                try:
                    cases = CASES if args.extended else CASES[:4]
                    for name, shape, flags in cases:
                        guard(out, f"before_{tag}_{name}")
                        result = invoke(out, f"{tag}_{name}", binary, {**env, **flags}, shape, verify=1)
                        results[tag][name] = result
                        print(f"PASS CPU {tag} {name}: {result['hash']}", flush=True)
                    for name, shape, flags in [
                        ("full8192", (8192, 8192, 1), {}),
                        ("full8192_seed2", (8192, 8192, 1), {"MXFP8_RANDOM_SEED": "20260910"}),
                        ("full_batch3", (1024, 512, 3), {})]:
                        guard(out, f"before_{tag}_{name}")
                        result = invoke(out, f"{tag}_{name}", binary, {**env, **flags}, shape)
                        if name in hashes and result["hash"] != hashes[name]:
                            raise RuntimeError(f"full-output reference hash mismatch: {tag}/{name}")
                        hashes.setdefault(name, result["hash"])
                        results[tag][name] = result
                        print(f"PASS full-hash {tag} {name}: {result['hash']}", flush=True)
                except RuntimeError as error:
                    # Numeric failures exclude that candidate, never become performance samples.
                    if (out / "quality.json").exists():
                        raise
                    excluded[tag] = str(error)
                    print(f"EXCLUDED {tag}: {error}", flush=True)
                save(out / "summary.json", dict(results=results, excluded=excluded,
                     eligible=[x for x in images if x in results and x not in excluded], reference_hashes=hashes))
            guard(out, "after_cases")
            if next(iter(images)) in excluded:
                raise RuntimeError("reference correctness failed")
            save(out / "quality.json", dict(valid_for_selection=True, complete=True))
            return
        if len(images) < 2:
            raise RuntimeError("benchmark requires at least two labels, including an A/A control")
        for tag, binary in images.items():
            guard(out, f"before_hash_{tag}")
            result = invoke(out, f"hash_{tag}", binary, env, (8192, 8192, 1))
            hashes[tag] = result["hash"]
            if len(set(hashes.values())) != 1:
                raise RuntimeError("full-output hashes differ; no timing permitted")
        manifest["full_output_hashes"] = hashes
        save(out / "manifest.json", manifest)
        rows = []
        tags = list(images)
        with (out / "results.tsv").open("x") as stream:
            writer = csv.DictWriter(stream, delimiter="\t", fieldnames=("round", "position", "tag", "ms", "tflops", "timestamp_ns"))
            writer.writeheader()
            for r in range(args.rounds):
                shift = r % len(tags)
                order = tags[shift:] + tags[:shift]
                if (r // len(tags)) % 2:
                    order.reverse()
                for pos, tag in enumerate(order, 1):
                    guard(out, f"r{r+1:02d}_p{pos}")
                    result = invoke(out, f"r{r+1:02d}_p{pos}_{tag}", images[tag], env, (8192, 8192, 1), timing=True)
                    row = dict(round=r+1, position=pos, tag=tag, **result)
                    rows.append(row)
                    writer.writerow(row)
                    stream.flush()
                    print(f"r{r+1:02d} {tag}: {result['ms']:.9f} ms {result['tflops']/1000:.6f}P", flush=True)
        guard(out, "after_last_round")
        reference = tags[0]
        reference_min = min(x["ms"] for x in rows if x["tag"] == reference)
        summary = {}
        for tag in tags:
            values = [x for x in rows if x["tag"] == tag]
            minimum = min(x["ms"] for x in values)
            gains = []
            for r in range(1, args.rounds+1):
                ref = next(x["ms"] for x in rows if x["tag"] == reference and x["round"] == r)
                cand = next(x["ms"] for x in rows if x["tag"] == tag and x["round"] == r)
                gains.append(ref / cand)
            summary[tag] = dict(observations=len(values), min_ms=minimum,
                                peak_p=2 * 8192**3 / (minimum * 1e12),
                                min_time_gain_pct=(reference_min/minimum-1)*100,
                                paired_wins=sum(x > 1 for x in gains),
                                paired_geomean_gain_pct=(statistics.geometric_mean(gains)-1)*100)
        save(out / "summary.json", summary)
        save(out / "quality.json", dict(valid_for_selection=True, complete=True,
             note="A/A spread and independent confirmation are still required for promotion"))
        print(json.dumps(summary, indent=2), flush=True)

if __name__ == "__main__":
    main()
