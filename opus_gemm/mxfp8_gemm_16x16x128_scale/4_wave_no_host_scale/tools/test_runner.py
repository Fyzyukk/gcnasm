#!/usr/bin/env python3
"""CPU-only tests for fail-closed process checks and HIP/SMI identity mapping."""
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
import run_suite

HEADER = "GPUs Indexed by PID\n"

class RunnerTests(unittest.TestCase):
    def test_guard_reports(self):
        cases = [
            ("empty", HEADER + "No KFD PIDs currently running\n", 0, True),
            ("zero", HEADER + "PID 123 is using 0 DRM device(s)\n", 0, True),
            ("two_zero", HEADER + "PID 123 is using 0 DRM device(s)\nPID 124 is using 0 DRM device(s)\n", 0, True),
            ("foreign", HEADER + "PID 123 is using 1 DRM device(s):\n5\n", 0, False),
            ("mixed", HEADER + "PID 123 is using 0 DRM device(s)\nPID 124 is using 1 DRM device(s):\n3\n", 0, False),
            ("title_only", HEADER, 0, False),
            ("unknown", HEADER + "PID 123 is using unknown DRM device(s)\n", 0, False),
            ("zero_and_error", HEADER + "PID 123 is using 0 DRM device(s)\nERROR: query failed\n", 0, False),
            ("no_pids_and_error", HEADER + "No KFD PIDs currently running\nUnable to get device list\n", 0, False),
            ("failed_command", HEADER + "No KFD PIDs currently running\n", 1, False),
            ("missing_header", "No KFD PIDs currently running\n", 0, False),
        ]
        for label, text, code, passes in cases:
            with self.subTest(label=label), tempfile.TemporaryDirectory(prefix="mxfp8-guard-unit-") as directory:
                out = Path(directory)
                with patch.object(run_suite.subprocess, "run", return_value=SimpleNamespace(returncode=code, stdout=text)):
                    if passes:
                        run_suite.guard(out, label)
                        self.assertFalse((out / "quality.json").exists())
                    else:
                        with self.assertRaises(run_suite.GuardError):
                            run_suite.guard(out, label)
                        self.assertFalse(json.loads((out / "quality.json").read_text())["valid_for_selection"])

    def test_device_identity_uses_pci_not_index(self):
        report = 'Device identity: hip_device=0 pci=0000:98:00.0 arch=gfx950:sramecc+:xnack- cu=256 warp=64 name="AMD Instinct MI350X"\n'
        bus = 'GPU[5] : PCI Bus: 0000:98:00.0\nGPU[7] : PCI Bus: 0000:F9:00.0\n'
        with tempfile.TemporaryDirectory(prefix="mxfp8-identity-unit-") as directory:
            with patch.object(run_suite.subprocess, "run", return_value=SimpleNamespace(stdout=report)), \
                 patch.object(run_suite.subprocess, "check_output", return_value=bus):
                result = run_suite.identity(Path("unused.exe"), {}, Path(directory))
                self.assertEqual(result["hip_visible_devices"], 7)
                self.assertEqual(result["smi_index"], 5)
                self.assertEqual(result["pci_bdf"], "0000:98:00.0")

if __name__ == "__main__":
    unittest.main(verbosity=2)
