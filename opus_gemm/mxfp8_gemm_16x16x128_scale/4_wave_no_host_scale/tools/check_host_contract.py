#!/usr/bin/env python3
"""Host-only negative tests: reject unsupported inputs before any GPU launch."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("binary", type=Path)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    binary = args.binary.resolve(strict=True)
    args.out.mkdir(parents=True, exist_ok=False)
    env = {key: value for key, value in os.environ.items() if not key.startswith("MXFP8_")}
    env["OMP_TOOL"] = "disabled"
    cases = [
        ("unsupported_k", ["-k", "4096"], {}, "requires K=8192"),
        ("m_alignment", ["-m", "384"], {}, "must be multiples"),
        ("n_alignment", ["-n", "384"], {}, "must be multiples"),
        ("zero_batch", ["-b", "0"], {}, "Invalid arguments"),
        ("negative_warmup", ["-w", "-1"], {}, "Invalid arguments"),
        ("zero_iterations", ["-i", "0"], {}, "Invalid arguments"),
        ("verify_value", ["-v", "2"], {}, "--verify must be 0 or 1"),
        ("unknown_option", ["--not-an-option"], {}, "Unknown argument"),
        ("missing_value", ["-m"], {}, "Missing value"),
        ("invalid_integer", ["-m", "256junk"], {}, "Invalid integer argument"),
        ("negative_seed", [], {"MXFP8_RANDOM_SEED": "-1"}, "Invalid MXFP8_RANDOM_SEED"),
        ("spaced_negative_seed", [], {"MXFP8_RANDOM_SEED": " -1"}, "Invalid MXFP8_RANDOM_SEED"),
        ("invalid_seed", [], {"MXFP8_RANDOM_SEED": "bad"}, "Invalid MXFP8_RANDOM_SEED"),
        ("timeline_hash_conflict", ["--timeline"], {"MXFP8_OUTPUT_HASH": "1"}, "--timeline requires"),
    ]
    rows = []
    for label, extra, variables, expected in cases:
        result = subprocess.run([str(binary), *extra], env={**env, **variables}, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30)
        (args.out / (label + ".log")).write_text(result.stdout)
        if result.returncode == 0 or expected not in result.stdout or "Launching" in result.stdout or "Device identity:" in result.stdout:
            raise RuntimeError(f"negative contract test failed: {label}")
        rows.append({"label": label, "returncode": result.returncode, "expected": expected})
        print(f"PASS {label}")
    (args.out / "summary.json").write_text(json.dumps({
        "binary": str(binary), "binary_sha256": hashlib.sha256(binary.read_bytes()).hexdigest(),
        "status": "pass", "tests": rows}, indent=2) + "\n")

if __name__ == "__main__":
    main()
