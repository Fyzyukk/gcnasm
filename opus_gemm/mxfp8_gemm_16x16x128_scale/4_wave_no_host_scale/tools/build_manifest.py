#!/usr/bin/env python3
"""Bind the final source, native instructions, compiler and linked image."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import datetime
import os

build = Path(sys.argv[1]).resolve(strict=True)
source = build.parent
expected_isa = "590bd0440b757862062a03a1c471c1e5f2d896a0c57f6555976e3017a4b937fa"
instructions = [line.split("//", 1)[0].strip()
                for line in (build / "kernel.isa").read_text().splitlines()
                if re.search(r"// [0-9A-F]{12,}:", line)]
normalized = "\n".join(instructions) + "\n"
isa_hash = hashlib.sha256(normalized.encode()).hexdigest()
if isa_hash != expected_isa:
    raise RuntimeError(f"native instructions changed: {isa_hash} != {expected_isa}")
names = ["tmpl.hpp", "host.cc", "kern.cc", "traits.hpp",
         "gemm_a8w8_mxfp8_scale_common.h", "build.sh", "gate.py",
         "tools/build_manifest.py", "tools/static_common.py", "tools/audit_bcontig.py"]
files = {"source/" + name: source / name for name in names}
files.update({"build/" + name: build / name for name in
              ("kernel.exe", "kernel.o", "host.o", "kernel.co", "kernel.isa",
               "kernel.notes", "static_gate.log")})
toolchain = Path(os.environ.get("TOOLCHAIN", "/root/toolchains/rocm-llvm23-46fcb339-build"))
manifest = {
    "created_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "variant": "four_wave_rowmajor_prepared_scale_c11_after4_b_contig_common_vaddr",
    "contract": {"architecture": "gfx950", "threads": 256, "wave_size": 64,
                 "tile": [256, 256, 128], "k": 8192, "m_n_multiple": 256,
                 "scale_layout": "row-major", "kernel_launches_per_gemm": 1,
                 "global_workspace_bytes": 0, "lds_bytes_per_wg": 163840},
    "compiler": subprocess.check_output([str(toolchain / "bin/clang++"), "--version"], text=True),
    "normalized_isa_sha256": isa_hash,
    "sha256": {name: hashlib.sha256(path.read_bytes()).hexdigest()
               for name, path in files.items()},
}
(build / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
print(f"PASS: exact selected native ISA reproduced ({len(instructions)} instructions)")
