#!/usr/bin/env python3
"""Time-series telemetry during a workload: shows soak/degradation behaviour."""
import subprocess, sys, time, json, statistics

def snap(gpu):
    out = subprocess.run(["amd-smi","metric","-g",str(gpu),"--json"],
                         capture_output=True, text=True).stdout
    try:
        d = json.loads(out)
        if isinstance(d, dict) and "gpu_data" in d: d = d["gpu_data"]
        if isinstance(d, list): d = d[0]
    except Exception:
        return None
    def val(x):
        return x.get("value") if isinstance(x, dict) else x
    gfx = [val(v.get("clk")) for k, v in (d.get("clock") or {}).items()
           if k.startswith("gfx") and isinstance(v, dict)]
    gfx = [g for g in gfx if isinstance(g, (int, float))]
    th = d.get("throttle") or {}
    return dict(gfx=gfx,
                power=val((d.get("power") or {}).get("socket_power")),
                temp=val((d.get("temperature") or {}).get("hotspot")),
                act=val((d.get("usage") or {}).get("gfx_activity")),
                ppt=str(th.get("ppt_violation_status")),
                ppta=val(th.get("ppt_violation_activity")))

gpu = int(sys.argv[1]); cmd = sys.argv[2:]
p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
t0 = time.time(); rows = []
while p.poll() is None:
    s = snap(gpu)
    if s and s["gfx"]: rows.append((time.time() - t0, s))
    time.sleep(0.5)
print(p.stdout.read().strip())
print(f"\n{'t(s)':>6} {'SCLKavg':>8} {'min':>5} {'max':>5} {'W':>5} {'C':>4} {'act%':>5} {'PPT':>10}")
for t, s in rows:
    print(f"{t:6.1f} {statistics.mean(s['gfx']):8.0f} {min(s['gfx']):5.0f} {max(s['gfx']):5.0f} "
          f"{s['power'] if s['power'] is not None else -1:5.0f} {s['temp'] if s['temp'] is not None else -1:4.0f} "
          f"{s['act'] if s['act'] is not None else -1:5.0f} {s['ppt'][:10]:>10}")
busy = [s for _, s in rows if (s["act"] or 0) >= 50]
if busy:
    allg = [g for s in busy for g in s["gfx"]]
    print(f"\nBUSY-ONLY: sclk mean={statistics.mean(allg):.0f} min={min(allg)} max={max(allg)}  "
          f"power mean={statistics.mean([s['power'] for s in busy if s['power'] is not None]):.0f}W  "
          f"temp max={max([s['temp'] for s in busy if s['temp'] is not None])}C  n={len(busy)}")
