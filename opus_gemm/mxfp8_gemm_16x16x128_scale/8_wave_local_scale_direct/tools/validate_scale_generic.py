#!/usr/bin/env python3
"""Generic scale prototypes, with explicit admission for SGPR-to-VGPR lanes.

The older offline queue deliberately rejects all scalar spills and reserves
TARGET/DEFINES for tile128. This separate gate records the actual rawslab
schema and small lane-spill exception; it never changes that older policy.
"""

import argparse
import json
from pathlib import Path
import re

import audit_offline
from validate_offline_queue import GENERIC_CASES, correctness_job, run_correctness


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("images", nargs="+", help="tag=generic/kernel.exe")
    args = parser.parse_args()
    images = dict(item.split("=", 1) for item in args.images)
    if len(images) != len(args.images):
        parser.error("unique tags required")
    args.out.mkdir(parents=True, exist_ok=False)
    plan = dict(phase="generic", jobs=[], admission="explicit scale-prototype audit")
    audits = {}
    for tag, path in images.items():
        binary = str(Path(path).resolve(strict=True))
        result = audit_offline.audit_build(Path(binary).parent)
        audits[binary] = result
        config = result["build_config"]
        flags = [flag for values in config.values() if isinstance(values, list)
                 for flag in values if isinstance(flag, str)]
        if config.get("EXACT_MASK") != "0" or [flag for flag in flags
            if flag.startswith("-DMXFP8_EXACT_8192=")] != ["-DMXFP8_EXACT_8192=0"]:
            raise RuntimeError(f"{tag}: not an actual generic-stride build")
        if "TARGET" in config and (config["TARGET"] != "0" or
                                   "-DMXFP8_PROTOTYPE_TARGET=0" not in flags):
            raise RuntimeError(f"{tag}: incompatible prototype specialization")
        resource = result["resources"]
        if not (0 < resource["lds_bytes"] <= 163840 and
                0 < resource["physical_vgpr"] <= 256 and
                resource["scratch_bytes"] == resource["vgpr_spills"] == 0):
            raise RuntimeError(f"{tag}: scratch/vector/LDS resource gate failed")
        accepted_exceptions = []
        for error in result["errors"]:
            if error == f"sgpr_spills={resource['sgpr_spills']}: scratch/spills are not allowed":
                # These spills are to lanes of the explicitly counted last
                # physical VGPR, not to any global scratch allocation.
                if not 0 < resource["sgpr_spills"] <= 4:
                    raise RuntimeError(f"{tag}: unexpected scalar-spill count")
                asm = Path(binary).with_name("kernel.s").read_text()
                last = resource["physical_vgpr"] - 1
                writes = re.findall(r"v_writelane_b32 v(\d+), s\d+, (\d+)", asm)
                reads = re.findall(r"v_readlane_b32 s\d+, v(\d+), (\d+)", asm)
                if not writes or not reads or any(int(reg) != last for reg, lane in writes + reads):
                    raise RuntimeError(f"{tag}: scalar spill is not in its dedicated counted VGPR")
                accepted_exceptions.append(dict(error=error, lane_writes=writes, lane_reads=reads,
                    reason="dedicated counted VGPR lanes; scratch=0; correctness-only admission"))
            else:
                raise RuntimeError(f"{tag}: {error}")
        result["scale_prototype_admission_exceptions"] = accepted_exceptions
        for case, shape, patterns in GENERIC_CASES:
            plan["jobs"].append(correctness_job(tag, binary, case, shape, patterns, generic=True))
    (args.out / "plan.json").write_text(json.dumps(plan, indent=2) + "\n")
    (args.out / "audit.json").write_text(json.dumps(audits, indent=2) + "\n")
    run_correctness(plan, args.out, audits)


if __name__ == "__main__":
    main()
