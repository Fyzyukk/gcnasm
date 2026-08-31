#!/usr/bin/env python3
"""Benchmark only inside the co-tenant's idle windows.

This box is a shared container: a neighbour in another PID namespace runs a
~60s-busy / ~50s-idle duty cycle on every GPU.  Section 29.4 of the log traces
a bogus -2.0% reading to exactly this.  `guard.py` is a one-shot pre-flight;
this is the loop version -- it blocks until the card is quiet, then fires runs
back to back until the neighbour wakes up, discarding any sample that spans a
wake-up.

Usage:
    gated_bench.py --gpu 6 --n 20 -- BIN [BIN ...]

Multiple binaries are interleaved ABBA-style within each window so that a
drifting clock cannot favour whichever one happens to run first.
"""
import argparse
import json
import os
import re
import statistics
import subprocess
import sys
import time

IDLE_ACT = 5        # percent; neighbour at rest reads 0, ours reads 100
IDLE_PWR = 400      # watts; idle floor here is ~310, busy is ~700
SETTLE = 2.0        # seconds of continuous quiet before trusting the window


def metric(gpu):
    """(gfx_activity %, socket power W) or (None, None) if amd-smi hiccups."""
    try:
        out = subprocess.run(["amd-smi", "metric", "-g", str(gpu), "--json"],
                             capture_output=True, text=True, timeout=20).stdout
        d = json.loads(out)
        if isinstance(d, dict) and "gpu_data" in d:
            d = d["gpu_data"]
        if isinstance(d, list):
            d = d[0]
        v = lambda x: x.get("value") if isinstance(x, dict) else x
        return v(d.get("usage", {}).get("gfx_activity")), \
               v(d.get("power", {}).get("socket_power"))
    except Exception:
        return None, None


def quiet(gpu):
    a, p = metric(gpu)
    if a is None or p is None:
        return False
    return a <= IDLE_ACT and p <= IDLE_PWR


def wait_quiet(gpu, verbose=True):
    """Block until the card has been quiet continuously for SETTLE seconds."""
    announced = False
    while True:
        if quiet(gpu):
            t0 = time.time()
            while time.time() - t0 < SETTLE:
                time.sleep(0.4)
                if not quiet(gpu):
                    break
            else:
                return
        if verbose and not announced:
            print("  waiting for a clean window...", flush=True)
            announced = True
        time.sleep(3)


TIME_RE = re.compile(r"avg_time=([0-9.]+)\s*ms")


def run_once(binary, gpu, args):
    env = dict(os.environ, HIP_VISIBLE_DEVICES=str(gpu))
    omp = "/opt/rocm/lib/llvm/lib"
    env["LD_LIBRARY_PATH"] = omp + ":" + env.get("LD_LIBRARY_PATH", "")
    out = subprocess.run([binary] + args, capture_output=True, text=True,
                         env=env, timeout=600).stdout
    m = TIME_RE.search(out)
    return float(m.group(1)) if m else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--gpu", type=int, default=6)
    ap.add_argument("--n", type=int, default=20, help="samples per binary")
    ap.add_argument("-m", type=int, default=8192)
    ap.add_argument("-n_", "--N", type=int, default=8192)
    ap.add_argument("-k", type=int, default=8192)
    ap.add_argument("-w", type=int, default=200)
    ap.add_argument("-i", type=int, default=100)
    ap.add_argument("bins", nargs="+")
    a = ap.parse_args()

    kargs = ["-m", str(a.m), "-n", str(a.N), "-k", str(a.k), "-b", "1",
             "-v", "0", "-w", str(a.w), "-i", str(a.i)]
    flop = 2 * a.m * a.N * a.k
    labels = [os.path.basename(b) for b in a.bins]
    got = {b: [] for b in a.bins}
    dropped = 0

    print(f"gated_bench: gpu={a.gpu}  {a.m}x{a.N}x{a.k} b=1  "
          f"w={a.w} i={a.i}  target n={a.n}/binary")

    # ABBA within a window: forward order then reverse, so position in the
    # window is balanced across binaries.
    order = a.bins + a.bins[::-1]
    while min(len(v) for v in got.values()) < a.n:
        wait_quiet(a.gpu)
        t_open = time.time()
        while min(len(v) for v in got.values()) < a.n:
            batch = {}
            ok = True
            for b in order:
                if not quiet_enough_before(a.gpu):
                    ok = False
                    break
                t = run_once(b, a.gpu, kargs)
                if t is None or not quiet_enough_after(a.gpu):
                    ok = False
                    break
                batch.setdefault(b, []).append(t)
            if not ok:
                dropped += 1
                break
            for b, ts in batch.items():
                got[b].extend(ts)
            print(f"  [{time.time()-t_open:5.1f}s] " +
                  "  ".join(f"{os.path.basename(b)}={min(ts):.4f}"
                            for b, ts in batch.items()), flush=True)

    print()
    print(f"dropped windows (neighbour woke mid-sample): {dropped}")
    print(f"{'binary':<52} {'n':>3} {'best':>8} {'median':>8} {'P(med)':>8}")
    res = {}
    for b in a.bins:
        v = sorted(got[b])
        med = statistics.median(v)
        res[b] = med
        print(f"{os.path.basename(b):<52} {len(v):>3} {v[0]:>8.4f} "
              f"{med:>8.4f} {flop/(med/1000)/1e15:>8.3f}")
    if len(a.bins) == 2:
        x, y = a.bins
        print(f"\nspeedup {labels[1]} vs {labels[0]}: "
              f"{res[x]/res[y]:.4f}x  ({(res[x]/res[y]-1)*100:+.2f}%)")


# The neighbour can wake up mid-run; sample the gate on both sides of each
# kernel launch and throw the whole ABBA batch away if either side is dirty.
def quiet_enough_before(gpu):
    return quiet(gpu)


# Our own kernel leaves the activity counter hot for ~1.2s after the process
# exits, so the post-run gate has to let it drain before it means anything.
POST_RUN_DRAIN = 1.4


def quiet_enough_after(gpu):
    time.sleep(POST_RUN_DRAIN)
    return quiet(gpu)


if __name__ == "__main__":
    main()
