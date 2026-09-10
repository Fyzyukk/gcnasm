#!/usr/bin/env python3
"""Plan delayed GPU7 validation; only --execute --out NEW_DIR may launch work.

The default is a CPU-only dry run: it reads the queue and prints commands, but
does not run rocm-smi, kernels, or the formal benchmark. This tool never selects
a winner or updates the candidate queue. Run from any working directory; build
paths are resolved relative to the queue JSON.
Candidates may select generic_case_set="default" (the existing 256-tile
cases) or "tile128" (odd M-tile counts for the 128-tile prototype).
Prototype TARGET/DEFINES build metadata also enables the stricter resource
gate: at most 128 physical vector registers and 81920 LDS bytes per block.
"""

import argparse
import fcntl
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys

import audit_offline
import bench_formal


ROOT = Path(__file__).resolve().parent
LOCK_PATH = Path("/tmp/mxfp8_gpu7.lock")
BASE_ENV = dict(OMP_TOOL="disabled", HIP_VISIBLE_DEVICES="7", MXFP8_RANDOM_SEED="20260909")
NOTICE = ("Short w0/i1 runs are correctness-only, never performance observations. "
          "After formal runs, manually verify that the baseline recovered to this "
          "machine's normal 0.42–0.43 ms range and that gains exceed same-session "
          "A/A minimum-time noise. No automatic winner selection.")
GENERIC_CASES = (
    ("random", (256, 256, 512, 1), {}),
    ("k_rows", (768, 512, 1024, 1),
     dict(MXFP8_SFA_K_PATTERN="1", MXFP8_SFB_ROW_PATTERN="1")),
    ("row_k_tail", (2304, 256, 1536, 2),
     dict(MXFP8_SFA_ROW_PATTERN="1", MXFP8_SFB_K_PATTERN="1")),
)
GENERIC_CASE_SETS = {
    "default": GENERIC_CASES,
    "tile128": (
        ("random", (128, 128, 512, 1), {}),
        ("k_rows", (384, 256, 1024, 1),
         dict(MXFP8_SFA_K_PATTERN="1", MXFP8_SFB_ROW_PATTERN="1")),
        ("row_k_tail", (640, 384, 1536, 2),
         dict(MXFP8_SFA_ROW_PATTERN="1", MXFP8_SFB_K_PATTERN="1")),
    ),
}


def read_queue(path, tags=None):
    path = Path(path).resolve()
    data = json.loads(path.read_text())
    if not isinstance(data, dict) or not isinstance(data.get("baseline"), str):
        raise ValueError("queue requires a baseline kernel.exe path")
    baseline = (path.parent / data["baseline"]).resolve()
    if baseline.name != "kernel.exe":
        raise ValueError("baseline must name kernel.exe")
    baseline_sha256 = data.get("baseline_sha256")
    if baseline_sha256 is not None:
        if not isinstance(baseline_sha256, str) or not re.fullmatch(r"[0-9a-fA-F]{64}", baseline_sha256):
            raise ValueError("baseline_sha256 must be a 64-character hexadecimal digest")
        baseline_sha256 = baseline_sha256.lower()
    if data.get("expected_output_hash", bench_formal.EXPECTED_HASH) != bench_formal.EXPECTED_HASH:
        raise ValueError("queue expected_output_hash disagrees with the fixed validation contract")
    contract = dict(m=8192, n=8192, k=8192, b=1, w=200, i=100, gpu=7, seed=20260909)
    recorded_contract = data.get("contract", {})
    if not isinstance(recorded_contract, dict) or any(
            key in recorded_contract and recorded_contract[key] != value for key, value in contract.items()):
        raise ValueError("queue contract disagrees with the fixed validation contract")
    entries = data.get("candidates")
    if not isinstance(entries, list):
        raise ValueError("queue requires a candidates list")
    candidates, known, skipped = [], set(), []
    for entry in entries:
        if not isinstance(entry, dict):
            raise ValueError("candidate must be an object")
        tag = entry.get("tag")
        if (not isinstance(tag, str) or not re.fullmatch(r"[a-zA-Z0-9][a-zA-Z0-9_-]*", tag)
                or tag in {"base", "base_a", "base_b"} or tag in known):
            raise ValueError(f"invalid, reserved, or duplicate candidate tag: {tag!r}")
        known.add(tag)
        if not isinstance(entry.get("build_dir"), str):
            raise ValueError(f"{tag}: build_dir must be a string")
        priority = entry.get("priority")
        if not isinstance(priority, (int, float)) or isinstance(priority, bool):
            raise ValueError(f"{tag}: priority must be numeric")
        status = entry.get("gpu_status")
        if status not in {"pending", "hash_passed_perf_pending", "validated_not_promoted", "rejected_static"}:
            raise ValueError(f"{tag}: unsupported gpu_status {status!r}")
        case_set = entry.get("generic_case_set", "default")
        if not isinstance(case_set, str) or case_set not in GENERIC_CASE_SETS:
            raise ValueError(f"{tag}: generic_case_set must be 'default' or 'tile128'")
        candidate = dict(entry, build_dir=str((path.parent / entry["build_dir"]).resolve()))
        candidate["generic_case_set"] = case_set
        if "generic_build_dir" in entry:
            if not isinstance(entry["generic_build_dir"], str):
                raise ValueError(f"{tag}: generic_build_dir must be a string")
            candidate["generic_build_dir"] = str((path.parent / entry["generic_build_dir"]).resolve())
        candidates.append(candidate)
    if tags is not None:
        if len(tags) != len(set(tags)) or not tags or any(not tag for tag in tags):
            raise ValueError("--tags must contain distinct nonempty candidate tags")
        if set(tags) - known:
            raise ValueError(f"unknown candidate tags: {sorted(set(tags) - known)}")
    selected = []
    for entry in candidates:
        if tags is not None and entry["tag"] not in tags:
            continue
        if entry["gpu_status"] == "rejected_static":
            if tags is not None:
                raise ValueError(f"{entry['tag']}: explicitly selected candidate is rejected_static")
            skipped.append(dict(tag=entry["tag"], reason="rejected_static"))
        else:
            selected.append(entry)
    return baseline, sorted(selected, key=lambda item: (item["priority"], item["tag"])), skipped, baseline_sha256


def correctness_job(tag, binary, case, shape, patterns=None, generic=False):
    m, n, k, batch = shape
    env = {**BASE_ENV, **(patterns or {})}
    if not generic:
        env["MXFP8_OUTPUT_HASH"] = "1"
    return dict(kind="correctness", name=f"{tag}_{case}", tag=tag, binary=str(binary),
                generic=generic, case=case, env=env,
                argv=[str(binary), "-m", str(m), "-n", str(n), "-k", str(k),
                      "-b", str(batch), "-v", "1" if generic else "0", "-w", "0", "-i", "1"])


def make_plan(queue_path, phase, tags=None, out=None):
    baseline, candidates, skipped, baseline_sha256 = read_queue(queue_path, tags)
    out = Path(out).resolve() if out is not None else Path("<OUT>")
    jobs = []
    images = [("base", baseline)] + [(item["tag"], Path(item["build_dir"]) / "kernel.exe")
                                     for item in candidates]

    def formal_job(name, pairs, order, rounds):
        return dict(kind="formal", name=name, images=[dict(tag=tag, binary=str(binary))
                                                      for tag, binary in pairs],
                    order=order, rounds=rounds, observations_per_image=rounds * (2 if order == "abba" else 1),
                    argv=[sys.executable, str(ROOT / "bench_formal.py"), "--out", str(out / name),
                          "--order", order, "--rounds", str(rounds),
                          *[f"{tag}={binary}" for tag, binary in pairs]])

    if phase == "hash":
        jobs = [correctness_job(tag, binary, "full_hash", (8192, 8192, 8192, 1))
                for tag, binary in images]
    elif phase == "generic":
        covered = {}
        for item in candidates:
            if "generic_build_dir" not in item:
                skipped.append(dict(tag=item["tag"], reason="no generic_build_dir"))
                continue
            binary = Path(item["generic_build_dir"]) / "kernel.exe"
            case_set = item["generic_case_set"]
            key = (binary, case_set)
            if key in covered:
                skipped.append(dict(tag=item["tag"], reason=f"generic image already covered by {covered[key]} "
                                    f"(case_set={case_set})"))
                continue
            covered[key] = item["tag"]
            jobs.extend(dict(correctness_job(item["tag"], binary, case, shape, patterns, generic=True),
                             generic_case_set=case_set)
                        for case, shape, patterns in GENERIC_CASE_SETS[case_set])
    elif phase == "aa":
        jobs = [formal_job("aa", [("base_a", baseline), ("base_b", baseline)], "abba", 12)]
    elif phase == "screen":
        if not candidates:
            raise ValueError("screen requires at least one eligible candidate")
        jobs = [formal_job("screen", images, "rotate", 3)]
    elif phase == "confirm":
        jobs = [formal_job(f"confirm_{tag}", [("base", baseline), (tag, binary)], "abba", 12)
                for tag, binary in images[1:]]
    else:
        raise ValueError(f"unknown phase: {phase}")
    if not jobs:
        raise ValueError(f"phase {phase} has no eligible jobs")
    return dict(phase=phase, queue=str(Path(queue_path).resolve()), notice=NOTICE,
                baseline=dict(binary=str(baseline), expected_sha256=baseline_sha256),
                contract=dict(device=7, seed=20260909, formal_w=200, formal_i=100,
                              formal_shape=[8192, 8192, 8192, 1]),
                jobs=jobs, skipped=skipped, winner_selection="manual_only")


def plan_images(plan):
    baseline = plan["baseline"]
    images = {baseline["binary"]: False} if baseline["expected_sha256"] else {}
    for job in plan["jobs"]:
        if job["kind"] == "correctness":
            images[job["binary"]] = job["generic"] or images.get(job["binary"], False)
        else:
            for image in job["images"]:
                images[image["binary"]] = False
    return images


def generic_admission_error(config, case_sets):
    """Accept one complete generic-build schema; mixed schemas fail closed.

    The standalone tile128 build does not use MXFP8_EXACT_8192. Requiring
    its actual TARGET/DEFINES evidence avoids inventing legacy metadata.
    """
    for name in ("DEVICE_DEFINES", "DEFINES"):
        if name in config and (not isinstance(config[name], list)
                               or any(not isinstance(value, str) for value in config[name])):
            return f"{name} must be a recorded string array"
    # Include flags outside the usual define array when checking for
    # contradictory or duplicate specialization declarations.
    flags = [value for values in config.values() if isinstance(values, list)
             for value in values if isinstance(value, str)]

    def declarations(name):
        return [value for value in flags if value == f"-D{name}" or value.startswith(f"-D{name}=")]

    exact = declarations("MXFP8_EXACT_8192")
    prototype = declarations("MXFP8_PROTOTYPE_TARGET")
    legacy_schema = "EXACT_MASK" in config or "DEVICE_DEFINES" in config or bool(exact)
    prototype_schema = "TARGET" in config or "DEFINES" in config or bool(prototype)
    if legacy_schema and prototype_schema:
        return "mixed legacy/prototype generic admission schemas are not supported"
    if legacy_schema:
        required = "-DMXFP8_EXACT_8192=0"
        if (config.get("EXACT_MASK") == "0" and exact == [required]
                and required in config.get("DEVICE_DEFINES", [])):
            return None
        return "generic validation requires recorded EXACT_MASK=0 and unique -DMXFP8_EXACT_8192=0"
    if prototype_schema:
        if case_sets != {"tile128"}:
            return "prototype generic admission requires only generic_case_set=tile128"
        required = "-DMXFP8_PROTOTYPE_TARGET=0"
        if (config.get("TARGET") == "0" and prototype == [required]
                and required in config.get("DEFINES", [])):
            return None
        return "prototype generic validation requires recorded TARGET=0 and unique -DMXFP8_PROTOTYPE_TARGET=0"
    return "generic build has neither a complete legacy nor prototype admission schema"


def preflight(plan):
    """Finish all static checks before any GPU process check or kernel launch."""
    audits, errors = {}, []
    case_sets = {}
    for job in plan["jobs"]:
        if job["kind"] == "correctness" and job["generic"]:
            case_sets.setdefault(job["binary"], set()).add(job.get("generic_case_set", "default"))
    for binary, generic in plan_images(plan).items():
        result = audit_offline.audit_build(Path(binary).parent)
        audits[binary] = result
        errors.extend(f"{binary}: {error}" for error in result["errors"])
        config = result["build_config"]
        flags = [value for values in config.values() if isinstance(values, list)
                 for value in values if isinstance(value, str)]
        if "TARGET" in config or any(value == "-DMXFP8_PROTOTYPE_TARGET" or
                                     value.startswith("-DMXFP8_PROTOTYPE_TARGET=")
                                     for value in flags):
            # Apply to target and generic images, in every phase. This is
            # determined by actual build metadata, not a user-selected tag.
            for field, limit in (("physical_vgpr", 128), ("lds_bytes", 81920)):
                value = result.get("resources", {}).get(field)
                if (not isinstance(value, int) or isinstance(value, bool)
                        or not 0 < value <= limit):
                    errors.append(f"{binary}: tile128 {field} must be in 1..{limit}; got {value!r}")
        if generic:
            error = generic_admission_error(result["build_config"], case_sets[binary])
            if error:
                errors.append(f"{binary}: {error}")
    baseline = plan["baseline"]
    if baseline["expected_sha256"] and (
            audits[baseline["binary"]]["binary_sha256"] != baseline["expected_sha256"]):
        errors.append("retained baseline SHA256 does not match the pinned queue digest")
    return audits, errors


def launch_environment(overrides):
    env = {key: value for key, value in os.environ.items() if not key.startswith("MXFP8_")}
    env.update(overrides)
    return env


def unchanged(binary, audits):
    if audit_offline.file_sha256(Path(binary)) != audits[binary]["binary_sha256"]:
        raise RuntimeError(f"binary changed after static admission: {binary}")


def run_correctness(plan, out, audits):
    rows = []
    with LOCK_PATH.open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            raise RuntimeError("GPU7 benchmark lock is occupied; no kernels launched") from exc
        for job in plan["jobs"]:
            unchanged(job["binary"], audits)
            bench_formal.check_gpu7_available(out, f"before_{job['name']}")
            result = subprocess.run(job["argv"], env=launch_environment(job["env"]), text=True,
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            (out / f"{job['name']}.log").write_text(result.stdout)
            if result.returncode:
                raise RuntimeError(f"{job['name']}: executable returned {result.returncode}")
            if "block=512," not in result.stdout:
                raise RuntimeError(f"{job['name']}: expected actual block=512")
            if job["generic"]:
                if "[Overall] ALL BATCHES VALID" not in result.stdout:
                    raise RuntimeError(f"{job['name']}: CPU-reference correctness failed")
            elif f"Output bit hash: {bench_formal.EXPECTED_HASH} " not in result.stdout:
                raise RuntimeError(f"{job['name']}: complete target hash does not match")
            rows.append(dict(name=job["name"], passed=True, correctness_only=True,
                             binary_sha256=audits[job["binary"]]["binary_sha256"]))
            (out / "correctness.json").write_text(json.dumps(rows, indent=2) + "\n")
            print(f"{job['name']}: correctness passed; timing ignored", flush=True)
        bench_formal.check_gpu7_available(out, "after_last_correctness")


def execute_plan(plan, out):
    out = Path(out).resolve()
    out.mkdir(parents=True, exist_ok=False)
    (out / "plan.json").write_text(json.dumps(plan, indent=2) + "\n")
    status = dict(completed=False, winner_selected=False, manual_quality_review_required=True,
                  notice=NOTICE)
    try:
        audits, errors = preflight(plan)
        (out / "audit.json").write_text(json.dumps(audits, indent=2) + "\n")
        if errors:
            raise RuntimeError("static preflight rejected the queue:\n" + "\n".join(errors))
        if plan["phase"] in {"hash", "generic"}:
            run_correctness(plan, out, audits)
        else:
            # bench_formal owns the lock and process checks. Do not hold a
            # second outer flock while invoking it, which would deadlock.
            for job in plan["jobs"]:
                for image in job["images"]:
                    unchanged(image["binary"], audits)
                result = subprocess.run(job["argv"], env=launch_environment(BASE_ENV))
                if result.returncode:
                    raise RuntimeError(f"{job['name']}: formal harness failed ({result.returncode})")
        status["completed"] = True
    except Exception as exc:
        status["error"] = str(exc)
        raise
    finally:
        (out / "execution_status.json").write_text(json.dumps(status, indent=2) + "\n")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--queue", type=Path, default=ROOT / "offline_candidates_20260909.json")
    parser.add_argument("--phase", choices=("hash", "generic", "aa", "screen", "confirm"), default="hash")
    parser.add_argument("--tags", help="comma-separated candidate tags; rejected_static cannot be selected")
    parser.add_argument("--execute", action="store_true")
    parser.add_argument("--out", type=Path, help="fresh output directory; required with --execute")
    args = parser.parse_args(argv)
    if args.execute and args.out is None:
        parser.error("--execute also requires --out NEW_DIRECTORY")
    try:
        tags = [tag.strip() for tag in args.tags.split(",")] if args.tags is not None else None
        plan = make_plan(args.queue, args.phase, tags, args.out)
        print("EXECUTION REQUESTED" if args.execute else "DRY RUN: no subprocesses or GPU queries")
        print(NOTICE)
        for skipped in plan["skipped"]:
            print(f"skip {skipped['tag']}: {skipped['reason']}")
        for job in plan["jobs"]:
            env = [f"{key}={value}" for key, value in job.get("env", {}).items()]
            print(f"{job['name']}: " + shlex.join(env + job["argv"]))
        if args.execute:
            execute_plan(plan, args.out)
            print(NOTICE)
    except (OSError, ValueError, RuntimeError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
