#!/usr/bin/env python3
"""Run the recorded GPU/PCI-aware round3 drivers for this tile1 worktree."""
from pathlib import Path
import shutil
import sys

here = Path(__file__).resolve().parent
previous = here.parent / "continuation_20260911/round3"
mode = sys.argv.pop(1)
driver = {"cli": "run_resume.py", "verify": "verify_full.py", "shared": "benchmark_shared_cli.py", "audit": "audit_resumed.py"}[mode]
source = (previous / driver).read_text()
source = source.replace("root/'support/", "root.parent/'continuation_20260911/round3/support/")
source = source.replace('root / "support/', 'root.parent / "continuation_20260911/round3/support/')
source = source.replace('root / "support"', 'root.parent / "continuation_20260911/round3/support"')
namespace = {"__name__": "__main__", "__file__": str(Path(__file__).resolve())}
exec(compile(source, str(previous / driver), "exec"), namespace)
if mode == "audit":
    work = Path((here / "work_path.txt").read_text().strip())
    dest = here / "audits"
    dest.mkdir(exist_ok=True)
    for name in sys.argv[1:]:
        shutil.copy2(work / name / "resumed_static_audit.json", dest / (name + ".json"))
