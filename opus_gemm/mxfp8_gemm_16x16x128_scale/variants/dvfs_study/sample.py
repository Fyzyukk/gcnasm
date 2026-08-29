#!/usr/bin/env python3
"""Synchronous telemetry sampler: samples amd-smi during a workload, not after."""
import subprocess, sys, time, json, statistics, re

def sample_once(gpu):
    out = subprocess.run(["amd-smi","metric","-g",str(gpu),"--json"],
                         capture_output=True, text=True).stdout
    try:
        d = json.loads(out)
        if isinstance(d, dict) and "gpu_data" in d: d = d["gpu_data"]
        if isinstance(d, list): d = d[0]
    except Exception:
        return None
    def dig(*path):
        cur = d
        for p in path:
            if not isinstance(cur, dict) or p not in cur: return None
            cur = cur[p]
        if isinstance(cur, dict) and "value" in cur: cur = cur["value"]
        return cur
    clocks = d.get("clock") or {}
    gfx = []
    for k,v in clocks.items():
        if k.upper().startswith("GFX") and isinstance(v, dict):
            c = v.get("clk")
            if isinstance(c, dict): c = c.get("value")
            if isinstance(c,(int,float)): gfx.append(c)
    return {
        "gfx": gfx,
        "power": dig("power","socket_power"),
        "hotspot": dig("temperature","hotspot"),
        "gfx_act": dig("usage","gfx_activity"),
        "ppt": dig("throttle","ppt_violation_status"),
        "ppt_act": dig("throttle","ppt_violation_activity"),
    }

def main():
    gpu = int(sys.argv[1]); cmd = sys.argv[2:]
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    samples = []
    t0 = time.time()
    while proc.poll() is None:
        s = sample_once(gpu)
        if s and s["gfx"]: samples.append(s)
        time.sleep(0.25)
    out = proc.stdout.read()
    print(out.strip())
    # discard first 30% (warmup/alloc) so we report steady-state under load
    n = len(samples)
    steady = samples[int(n*0.3):] if n >= 6 else samples
    # only count samples where the GPU is actually busy
    busy = [s for s in steady if (s["gfx_act"] or 0) >= 50] or steady
    if not busy:
        print("NO TELEMETRY"); return
    allg = [g for s in busy for g in s["gfx"]]
    pw  = [s["power"] for s in busy if isinstance(s["power"],(int,float))]
    tp  = [s["hotspot"] for s in busy if isinstance(s["hotspot"],(int,float))]
    ppt_on = sum(1 for s in busy if str(s["ppt"]).upper().startswith("ACTIVE"))
    ppta = [s["ppt_act"] for s in busy if isinstance(s["ppt_act"],(int,float))]
    print(f"TELEMETRY n={len(busy)}/{n} busy samples over {time.time()-t0:.1f}s")
    print(f"  SCLK   mean={statistics.mean(allg):.0f} min={min(allg)} max={max(allg)} MHz  (per-XCD spread)")
    print(f"  POWER  mean={statistics.mean(pw):.0f} max={max(pw)} W" if pw else "  POWER n/a")
    print(f"  HOTSPOT mean={statistics.mean(tp):.0f} max={max(tp)} C" if tp else "  TEMP n/a")
    print(f"  PPT    active={ppt_on}/{len(busy)} samples  mean_activity={statistics.mean(ppta):.1f}%" if ppta else f"  PPT active={ppt_on}/{len(busy)}")

main()
