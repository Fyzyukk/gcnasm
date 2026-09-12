#!/usr/bin/env python3
"""Reuse the recorded full-output and native-event comparison drivers."""
from pathlib import Path
import sys

here = Path(__file__).resolve().parent
previous = here.parent / "continuation_20260911/round3"
mode = sys.argv.pop(1)
driver = {"verify": "verify_full.py", "shared": "benchmark_shared_cli.py"}[mode]
source = (previous / driver).read_text()
source = source.replace("root/'support/", "root.parent/'continuation_20260911/round3/support/")
source = source.replace('root / "support/', 'root.parent / "continuation_20260911/round3/support/')
source = source.replace('root / "support"', 'root.parent / "continuation_20260911/round3/support"')
if mode == "verify":
    source = source.replace("m = n = k = 8192", 'm = n = 8192\nk = int(os.environ.get("MXFP8_SURVEY_K", "8192"))')
if mode == "shared":
    # The comparison reference is the current formal specialized implementation.
    source = source.replace("'baseline'", "'specialized'")
namespace = {"__name__": "__main__", "__file__": str(Path(__file__).resolve())}
exec(compile(source, str(previous / driver), "exec"), namespace)
