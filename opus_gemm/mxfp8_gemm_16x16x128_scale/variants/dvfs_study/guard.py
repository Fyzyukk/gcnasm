#!/usr/bin/env python3
"""Pre-flight: refuse to benchmark a GPU that another process is using.

The single biggest source of bogus cross-machine numbers in this study was a
co-tenant sharing the card: it depresses SCLK and gfx_activity in a way that
mimics power throttling.  Run this before any measurement.
"""
import json, subprocess, sys

def gpu_data(gpu):
    out = subprocess.run(["amd-smi", "metric", "-g", str(gpu), "--json"],
                         capture_output=True, text=True).stdout
    d = json.loads(out)
    if isinstance(d, dict) and "gpu_data" in d: d = d["gpu_data"]
    return d[0] if isinstance(d, list) else d

def val(x):
    return x.get("value") if isinstance(x, dict) else x

def procs_on(gpu):
    out = subprocess.run(["amd-smi", "process", "-g", str(gpu), "--json"],
                         capture_output=True, text=True).stdout
    try:
        d = json.loads(out)
        if isinstance(d, dict) and "gpu_data" in d: d = d["gpu_data"]
        if isinstance(d, list): d = d[0]
        pl = d.get("process_list") or []
        out_p = []
        for p in pl:
            p = p.get("process_info", p)
            if not isinstance(p, dict): continue
            pid = val(p.get("pid"))
            mem = val(p.get("mem_usage")) or val(p.get("memory_usage"))
            if pid: out_p.append((pid, mem))
        return out_p
    except Exception:
        return []

def main():
    gpu = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    d = gpu_data(gpu)
    act = val(d["usage"]["gfx_activity"]) or 0
    pw  = val(d["power"]["socket_power"]) or 0
    vram = val((d.get("mem_usage") or {}).get("vram_used")) or 0
    ps = procs_on(gpu)
    print(f"GPU {gpu}: idle_activity={act}%  power={pw}W  vram_used={vram}")
    if ps:
        print(f"  processes: {ps}")
    bad = []
    if act > 5:   bad.append(f"gfx_activity={act}% at rest (expect ~0)")
    if pw  > 400: bad.append(f"idle power={pw}W (expect <400)")
    if ps:        bad.append(f"{len(ps)} other process(es) hold this GPU")
    if bad:
        print("NOT CLEAN -- do not benchmark:")
        for b in bad: print("   -", b)
        sys.exit(1)
    print("CLEAN -- safe to benchmark")

main()
