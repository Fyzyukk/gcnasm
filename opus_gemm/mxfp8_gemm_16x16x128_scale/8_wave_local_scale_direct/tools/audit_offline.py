#!/usr/bin/env python3
"""Read-only, CPU-only resource/ISA audit; never execute a kernel or shell config.

Examples:
  python3 audit_offline.py --reference build_side_t2_exact4_nohandoff_noprio build_new
  python3 audit_offline.py --format json build_new

A static pass is NOT a correctness result, a measured speedup, or proof of the
host's launch dimensions. Full output hashing and uncontended GPU timing remain
required. Exit status is 0 for static acceptance and 2 for any rejected image.
"""

import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import shlex


NOTICE = ("STATIC AUDIT ONLY: no GPU execution; correctness, actual launch block, "
          "and performance remain unvalidated by this script.")
NOTE_FIELDS = {
    "vgpr_count": "physical_vgpr",
    "agpr_count": "agpr",
    "sgpr_count": "sgpr",
    "private_segment_fixed_size": "scratch_bytes",
    "group_segment_fixed_size": "lds_bytes",
    "max_flat_workgroup_size": "max_block_threads",
    "wavefront_size": "wavefront_size",
    "vgpr_spill_count": "vgpr_spills",
    "sgpr_spill_count": "sgpr_spills",
}


def file_sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def parse_resources(notes, assembly):
    """This compiler's .vgpr_count is TotalNumVgprs, NOT VGPR minus AGPR."""
    resources, errors, warnings = {}, [], []
    for field, output in NOTE_FIELDS.items():
        matches = re.findall(r"^[ \t]*(?:-[ \t]+)?\." + field + r":[ \t]*(\d+)[ \t]*$",
                             notes, re.MULTILINE)
        resources[output] = int(matches[0]) if len(matches) == 1 else None
        if len(matches) != 1:
            errors.append(f"kernel.notes: expected one .{field}, found {len(matches)}")

    totals = re.findall(r"^[ \t]*;[ \t]*TotalNumVgprs:[ \t]*(\d+)[ \t]*$",
                        assembly, re.MULTILINE)
    resources["assembly_total_vgpr"] = int(totals[0]) if len(totals) == 1 else None
    if len(totals) != 1:
        errors.append(f"kernel.s: expected one TotalNumVgprs, found {len(totals)}")
    elif (resources["physical_vgpr"] is not None and
          resources["physical_vgpr"] != resources["assembly_total_vgpr"]):
        errors.append(".vgpr_count and TotalNumVgprs disagree")

    targets = re.findall(r"^amdhsa.target:[ \t]*(\S+)[ \t]*$", notes, re.MULTILINE)
    resources["target"] = targets[0] if len(targets) == 1 else None
    if len(targets) != 1 or not re.search(r"--gfx950(?::.*)?$", targets[0]):
        errors.append("kernel.notes: expected one gfx950 amdhsa.target")

    # max_flat_workgroup_size is a limit, not the host's actual block dimension.
    # reqd_workgroup_size may be absent in this clang23 output.
    required = re.search(r"^[ \t]*\.reqd_workgroup_size:[ \t]*(.*)$", notes, re.MULTILINE)
    dimensions = None
    if required:
        inline = required[1].strip()
        if inline:
            match = re.fullmatch(r"\[\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\]", inline)
            dimensions = list(map(int, match.groups())) if match else None
        else:
            following = notes[required.end():]
            match = re.match(r"\s*\n\s*- (\d+)\s*\n\s*- (\d+)\s*\n\s*- (\d+)",
                             following)
            dimensions = list(map(int, match.groups())) if match else None
        if dimensions is None or any(value < 1 for value in dimensions):
            errors.append("kernel.notes: malformed .reqd_workgroup_size")
        elif dimensions[0] * dimensions[1] * dimensions[2] != 512:
            errors.append("required workgroup dimensions do not contain 512 threads")
    else:
        warnings.append("only max block size is present; verify actual block=512 at GPU validation")
    resources["required_workgroup_size"] = dimensions
    block, wave = resources["max_block_threads"], resources["wavefront_size"]
    resources["max_waves_per_block"] = (block // wave if block and wave and block % wave == 0
                                         else None)
    if resources["physical_vgpr"] is not None and not 0 < resources["physical_vgpr"] <= 256:
        errors.append("physical vector-register allocation must be in 1..256")
    for field in ("scratch_bytes", "vgpr_spills", "sgpr_spills"):
        if resources[field]:
            errors.append(f"{field}={resources[field]}: scratch/spills are not allowed")
    if block is not None and block != 512:
        errors.append(f"max block size is {block}, expected 512")
    if wave is not None and wave != 64:
        errors.append(f"wavefront size is {wave}, expected 64")
    if resources["sgpr"] is not None and resources["sgpr"] < 1:
        errors.append("SGPR count must be positive")
    if resources["lds_bytes"] is not None and resources["lds_bytes"] < 1:
        errors.append("LDS allocation must be positive for this pipeline")
    return resources, errors, warnings


def isa_instructions(isa):
    """Parse disassembled instructions, not labels, comments, or filename headers."""
    instructions = []
    for line in isa.splitlines():
        line = line.split("//", 1)[0].strip()
        match = re.fullmatch(r"((?:s|v|ds|buffer|global|flat|scratch|tbuffer|image)_[a-z0-9_]+)"
                             r"(?:\s+(.*))?", line)
        if match:
            instructions.append((match[1], match[2] or ""))
    return instructions


def count_isa(isa):
    instructions = isa_instructions(isa)
    histogram = Counter(op for op, _ in instructions)

    def prefix_count(prefix):
        return sum(count for op, count in histogram.items() if op.startswith(prefix))

    dtlds = sum(op.startswith("buffer_load_") and bool(re.search(r"\blds\b", args))
                for op, args in instructions)
    counts = {
        "instructions": len(instructions),
        "scaled_mfma": prefix_count("v_mfma_scale_"),
        "ds_read_b128": histogram["ds_read_b128"],
        "ds_read_b32": histogram["ds_read_b32"],
        "ds_read_b64": histogram["ds_read_b64"],
        "ds_read2": prefix_count("ds_read2"),
        "ds_read2st64_b32": histogram["ds_read2st64_b32"],
        "ds_write2": prefix_count("ds_write2"),
        "ds_write_b32": histogram["ds_write_b32"],
        "ds_write_b8": prefix_count("ds_write_b8"),
        "dtlds_loads": dtlds,
        # In this kernel, non-LDS buffer loads carry scales. The ISA alone
        # cannot establish data provenance; this is explicitly a proxy count.
        "scale_vmem_loads_proxy": prefix_count("buffer_load_") - dtlds,
        "waits": prefix_count("s_wait"),
        "waits_vmcnt": sum(op.startswith("s_wait") and "vmcnt(" in args
                           for op, args in instructions),
        "waits_lgkmcnt": sum(op.startswith("s_wait") and "lgkmcnt(" in args
                             for op, args in instructions),
        "barriers": prefix_count("s_barrier"),
        "scratch_instructions": prefix_count("scratch_"),
        "buffer_stores": prefix_count("buffer_store_"),
        "v_perm_b32": histogram["v_perm_b32"],
        "v_permlane": prefix_count("v_permlane"),
        "v_mov": prefix_count("v_mov"),
        "s_nop": histogram["s_nop"],
    }
    return counts, dict(sorted(histogram.items()))


def normalize_isa(isa):
    """Ignore only the objdump file-format header and its leading empty line.

    Preserve labels, addresses, register allocation, and encoded instruction
    words. This is exact disassembly equality, not semantic equivalence.
    """
    lines = [line for line in isa.splitlines()
             if not re.fullmatch(r".*:\s+file format\s+\S+\s*", line)]
    while lines and not lines[0]:
        lines.pop(0)
    return "\n".join(lines)


def parse_config(config):
    """Parse build.sh's declare output as data. Never source or eval this file."""
    values, unparsed = {}, []
    for line in config.splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        match = re.fullmatch(r"(?:declare\s+(?:-[a-zA-Z-]+\s+)+|export\s+)?"
                             r"([a-zA-Z_]\w*)=(.*)", line)
        if not match:
            unparsed.append(line)
            continue
        key, value = match.groups()
        try:
            if value.startswith("(") and value.endswith(")"):
                items = re.findall(r'\[\d+\]=("(?:\\.|[^"\\])*")', value)
                values[key] = [shlex.split(item)[0] for item in items]
                if not items:
                    unparsed.append(line)
            else:
                words = shlex.split(value)
                if len(words) == 1:
                    values[key] = words[0]
                else:
                    unparsed.append(line)
        except ValueError:
            unparsed.append(line)
    return values, unparsed


def audit_build(build_dir, reference_isa=None):
    build_dir = Path(build_dir).resolve()
    result = dict(build_dir=str(build_dir), static_only=True, accepted=False,
                  correctness="not_checked", performance="not_measured",
                  errors=[], warnings=[], artifacts={})
    errors, warnings = result["errors"], result["warnings"]
    texts = {}
    for name in ("kernel.notes", "kernel.s", "kernel.isa", "kernel.exe",
                 "config.sh", "source.sha256"):
        path = build_dir / name
        try:
            result["artifacts"][name] = {"sha256": file_sha256(path), "bytes": path.stat().st_size}
            if name != "kernel.exe":
                texts[name] = path.read_text()
        except (OSError, UnicodeError) as exc:
            target = warnings if name in ("config.sh", "source.sha256") else errors
            target.append(f"{name}: unavailable ({exc})")
    if "kernel.exe" in result["artifacts"] and not result["artifacts"]["kernel.exe"]["bytes"]:
        errors.append("kernel.exe is empty")
    result["binary_sha256"] = result["artifacts"].get("kernel.exe", {}).get("sha256")
    resources, resource_errors, resource_warnings = parse_resources(
        texts.get("kernel.notes", ""), texts.get("kernel.s", ""))
    result["resources"] = resources
    errors.extend(resource_errors)
    warnings.extend(resource_warnings)
    isa = texts.get("kernel.isa", "")
    counts, histogram = count_isa(isa)
    result.update(isa_counts=counts, opcode_histogram=histogram)
    if not counts["instructions"] or not counts["scaled_mfma"]:
        errors.append("kernel.isa contains no recognized scaled-MFMA kernel")
    if counts["scratch_instructions"]:
        errors.append("scratch instructions are present in kernel.isa")
    result["normalized_isa_sha256"] = (hashlib.sha256(normalize_isa(isa).encode()).hexdigest()
                                        if isa else None)
    result["same_instructions_as_reference"] = (
        normalize_isa(isa) == normalize_isa(reference_isa) if isa and reference_isa else None)
    config, unparsed = parse_config(texts.get("config.sh", ""))
    result["build_config"] = config
    if unparsed:
        result["unparsed_config_lines"] = unparsed
        warnings.append("config.sh contains unparsed declarations; preserved in JSON")
    sources = []
    for line in texts.get("source.sha256", "").splitlines():
        match = re.fullmatch(r"([0-9a-fA-F]{64}) [ *](.+)", line)
        if match:
            sources.append(dict(sha256=match[1].lower(), recorded_path=match[2]))
        elif line.strip():
            warnings.append(f"unparsed source.sha256 line: {line}")
    result["recorded_source_sha256"] = sources
    result["source_hash_scope"] = "build-time manifest only; current mutable sources are not compared"
    result["accepted"] = not errors
    return result


def format_table(report):
    lines = [NOTICE, "status\tbuild\tphysicalVGPR\tAGPR\tSGPR\tscratchB\tLDSB\twave/maxBlock"
             "\tMFMA\tDTLDS\tscaleVMEM*\twait/barrier\tsameRef"]
    for result in report["builds"]:
        r, c = result["resources"], result["isa_counts"]
        row = (
            "PASS" if result["accepted"] else "REJECT", Path(result["build_dir"]).name,
            r["physical_vgpr"], r["agpr"], r["sgpr"], r["scratch_bytes"], r["lds_bytes"],
            f"{r['wavefront_size']}/{r['max_block_threads']}", c["scaled_mfma"], c["dtlds_loads"],
            c["scale_vmem_loads_proxy"], f"{c['waits']}/{c['barriers']}",
            result["same_instructions_as_reference"])
        lines.append("\t".join(map(str, row)))
        for field in ("errors", "warnings"):
            lines.extend(f"  {field[:-1]}: {message}" for message in result[field])
    if report["reference"] and not report["reference"]["accepted"]:
        lines.append("REJECT: reference failed static validation")
        lines.extend(f"  error: {message}" for message in report["reference"]["errors"])
    lines.append("* scaleVMEM is a non-LDS buffer-load proxy, not proven data provenance.")
    lines.append("Physical VGPR already includes AGPR allocation; never add AGPR again. "
                 "Use --format json for all opcode counts and provenance hashes.")
    return "\n".join(lines)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("build_dirs", nargs="+", type=Path)
    parser.add_argument("--reference", type=Path, help="retained build directory for exact ISA comparison")
    parser.add_argument("--format", choices=("table", "json"), default="table")
    args = parser.parse_args(argv)
    reference, reference_isa = None, None
    if args.reference:
        reference = audit_build(args.reference)
        try:
            reference_isa = (args.reference / "kernel.isa").read_text()
        except (OSError, UnicodeError):
            pass  # audit_build recorded the missing/unreadable artifact.
    builds = [audit_build(path, reference_isa) for path in args.build_dirs]
    report = dict(notice=NOTICE, reference=reference, builds=builds,
                  all_static_accepted=all(item["accepted"] for item in builds)
                  and (reference is None or reference["accepted"]))
    print(json.dumps(report, indent=2) if args.format == "json" else format_table(report))
    return 0 if report["all_static_accepted"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
