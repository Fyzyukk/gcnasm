#!/usr/bin/env python3
"""CPU-only guard checks; never query or launch a GPU."""
from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import runpy
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch

import gpu_window

HERE = Path(__file__).resolve().parent
PCI = "0000:65:00.0"


def sample(use=0, vram=0, pci=PCI):
    return dict(pci=pci, idle=use <= 5 and vram <= 1,
                status={"PCI Bus": pci, "GPU use (%)": str(use),
                        "GPU Memory Allocated (VRAM%)": str(vram)})


class DeviceWindows(unittest.TestCase):
    def test_snapshot_identity_and_busy_thresholds(self):
        for use, vram in [(0, 0), (100, 0), (0, 80), (100, 80)]:
            status = sample(use, vram)
            with patch("gpu_window.subprocess.check_output", return_value=json.dumps({"card2": status["status"]})):
                actual = gpu_window.snapshot(2, PCI)
                self.assertEqual(actual["idle"], status["idle"])
                with self.assertRaisesRegex(RuntimeError, "identity mismatch"):
                    gpu_window.snapshot(2, "0000:95:00.0")

    def test_recent_own_utilization_can_settle(self):
        probe = Mock(side_effect=[sample(100, 0), sample()])
        pause = Mock()
        after = gpu_window.after_process(2, PCI, probe=probe, pause=pause)
        self.assertEqual(len(after), 2)
        pause.assert_called_once_with(1)
        self.assertEqual(gpu_window.window_status(sample(), after, 0), "CLEAR_BOUNDARIES")

    def test_new_occupation_is_not_accepted(self):
        probe = Mock(return_value=sample(100, 80))
        pause = Mock()
        after = gpu_window.after_process(2, PCI, probe=probe, pause=pause)
        probe.assert_called_once_with(2, PCI)
        pause.assert_not_called()
        self.assertEqual(gpu_window.window_status(sample(), after, 0), "BUSY_AFTER")
        self.assertEqual(gpu_window.window_status(sample(), [sample()], 1), "COMMAND_FAILED")
        self.assertEqual(gpu_window.window_status(sample(), [], 0), "BUSY_AFTER")

    def test_busy_precheck_exits_before_any_child_or_manifest(self):
        tag = "__offline_device_guard_probe__"
        self.assertFalse((HERE / (tag + "_manifest.json")).exists())
        with patch("gpu_window.snapshot", return_value=sample(100, 80)), \
             patch("subprocess.check_output", side_effect=AssertionError("child probe must not start")) as check, \
             patch("subprocess.run", side_effect=AssertionError("GPU process must not start")) as run, \
             patch.object(sys, "argv", ["screen.py", "baseline", "--tag", tag]):
            with self.assertRaisesRegex(SystemExit, "GPU is busy"):
                runpy.run_path(str(HERE / "screen.py"), run_name="__main__")
        check.assert_not_called()
        run.assert_not_called()
        self.assertFalse((HERE / (tag + "_manifest.json")).exists())

    def test_occupation_after_shapes_stops_before_full_or_timing(self):
        with tempfile.TemporaryDirectory(prefix="mxfp8_window_guard_") as temp:
            directory = Path(temp)
            script = directory / "screen.py"
            script.write_text((HERE / "screen.py").read_text())
            with patch("gpu_window.snapshot", return_value=sample()), \
                 patch("gpu_window.after_process", return_value=[sample(100, 80)]), \
                 patch("subprocess.check_output", return_value=json.dumps([dict(hip_index=2, pci=PCI)])), \
                 patch("subprocess.run", return_value=SimpleNamespace(returncode=0)) as run, \
                 patch.object(sys, "argv", ["screen.py", "baseline", "--tag", "offline"]):
                with self.assertRaisesRegex(SystemExit, "BUSY_AFTER"), redirect_stdout(io.StringIO()):
                    runpy.run_path(str(script), run_name="__main__")
            record = json.loads((directory / "offline_manifest.json").read_text())
            self.assertEqual([p["label"] for p in record["phase_records"]], ["audit", "shapes"])
            self.assertEqual(record["phase_records"][-1]["status"], "BUSY_AFTER")
            self.assertEqual(run.call_count, 2)

    def test_busy_after_timing_is_persisted_with_raw_window(self):
        with tempfile.TemporaryDirectory(prefix="mxfp8_window_guard_") as temp:
            directory = Path(temp)
            script = directory / "screen.py"
            script.write_text((HERE / "screen.py").read_text())
            shared = directory / "shared_allocations/offline"
            shared.mkdir(parents=True)
            raw = shared / "summary.json"
            raw.write_text('[{"raw_result_preserved": true}]\n')
            with patch("gpu_window.snapshot", return_value=sample()), \
                 patch("gpu_window.after_process", side_effect=[[sample()], [sample()], [sample(100, 80)]]), \
                 patch("subprocess.check_output", return_value=json.dumps([dict(hip_index=2, pci=PCI)])), \
                 patch("subprocess.run", return_value=SimpleNamespace(returncode=0)), \
                 patch.object(sys, "argv", ["screen.py", "baseline", "--tag", "offline"]):
                with self.assertRaisesRegex(SystemExit, "BUSY_AFTER"), redirect_stdout(io.StringIO()):
                    runpy.run_path(str(script), run_name="__main__")
            evidence = json.loads((shared / "device_window.json").read_text())
            self.assertEqual(evidence["status"], "BUSY_AFTER")
            self.assertEqual(evidence["pci"], PCI)
            self.assertTrue(json.loads(raw.read_text())[0]["raw_result_preserved"])


if __name__ == "__main__":
    unittest.main()
