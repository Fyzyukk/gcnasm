#!/usr/bin/env python3
"""Record device availability only outside GPU validation/timing processes."""
import datetime
import json
import subprocess
import time

LIMITS = ("Availability is sampled before and after each GPU process, never "
          "during timing. Clear boundaries do not exclude transient interference "
          "inside a window; bracket drift and repeated idle-window comparisons "
          "must still be reviewed before selecting a winner.")


def snapshot(physical_gpu, expected_pci):
    started = datetime.datetime.now(datetime.timezone.utc).isoformat()
    status = json.loads(subprocess.check_output(
        ["rocm-smi", "--device", str(physical_gpu), "--showbus", "--showuse", "--showmemuse", "--json"],
        text=True, timeout=20))[f"card{physical_gpu}"]
    pci = status["PCI Bus"].lower()
    if expected_pci is not None and pci != expected_pci.lower():
        raise RuntimeError(f"GPU identity mismatch: card{physical_gpu} is {pci}, expected {expected_pci}")
    return dict(timestamp_utc=started,
                completed_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                physical_gpu=physical_gpu, pci=pci, status=status,
                idle=(int(status["GPU use (%)"]) <= 5
                      and int(status["GPU Memory Allocated (VRAM%)"]) <= 1))


def after_process(physical_gpu, expected_pci, *, probe=snapshot, pause=time.sleep):
    samples = []
    for attempt in range(3):
        sample = probe(physical_gpu, expected_pci)
        samples.append(sample)
        if sample["idle"]:
            break
        # The just-finished benchmark can leave a recent utilization sample.
        # Retry only that case; a live large allocation is already a blocker.
        if int(sample["status"]["GPU Memory Allocated (VRAM%)"]) > 1:
            break
        if attempt < 2:
            pause(1)
    return samples


def window_status(before, after, returncode):
    if not before["idle"]:
        return "BUSY_BEFORE"
    if returncode != 0:
        return "COMMAND_FAILED"
    if not after or not after[-1]["idle"]:
        return "BUSY_AFTER"
    return "CLEAR_BOUNDARIES"
