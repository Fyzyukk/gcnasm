import hashlib
import json
import os
from pathlib import Path
import re
import statistics
import subprocess
import time

four = Path('/root/workspace/gcnasm_new/gcnasm-mxfp8-final-pipeline-source-20260910/opus_gemm/mxfp8_gemm_16x16x128_blockscale_bpreshuffle_4wave')
eight = Path('/root/workspace/gcnasm_new/gcnasm/opus_gemm/mxfp8_gemm_16x16x128_blockscale_bpreshuffle')
out = four / 'results/continuation_20260911/eight_vs_four_20260911'
out.mkdir(parents=True, exist_ok=False)
env = dict(os.environ, HIP_VISIBLE_DEVICES='2', OMP_TOOL='disabled', OMP_NUM_THREADS='16')
versions = {
    '8wave': (eight, 'gemm_a8w8_mxfp8_scale_kernel_template.hpp', ['--tiles', '4']),
    '4wave': (four, 'tmpl.hpp', []),
}
records = []
for round_index in range(3):
    order = ['8wave', '4wave'] if round_index % 2 == 0 else ['4wave', '8wave']
    for name in order:
        directory, source, extra = versions[name]
        exe = directory / 'build/gemm_a8w8_blockscale_bpreshuffle.exe'
        for dtype in ['bf16', 'fp32']:
            args = [str(exe), '-m', '8192', '-n', '8192', '-k', '8192', '-b', '1', '-w', '200', '-i', '100', '-v', '0', '--dtype', dtype] + extra
            start = time.monotonic()
            result = subprocess.run(args, env=env, capture_output=True, text=True, timeout=50)
            log = f'r{round_index + 1}_{name}_{dtype}.log'
            (out / log).write_text(result.stdout + result.stderr)
            matches = re.findall(r'avg_time=([0-9.]+) ms, ([0-9.]+) TFlops', result.stdout)
            if result.returncode != 0 or not matches:
                raise RuntimeError((name, dtype, result.returncode, result.stdout, result.stderr))
            ms, tflops = map(float, matches[-1])
            record = dict(round=round_index + 1, name=name, dtype=dtype, command=args, environment={k:env[k] for k in ['HIP_VISIBLE_DEVICES','OMP_TOOL','OMP_NUM_THREADS']}, ms=ms, pflops=tflops/1000, wall_seconds=time.monotonic()-start, source_sha256=hashlib.sha256((directory/source).read_bytes()).hexdigest(), exe_sha256=hashlib.sha256(exe.read_bytes()).hexdigest(), log=log)
            records.append(record)
            (out / 'records.json').write_text(json.dumps(records, indent=2) + '\n')
            print(f'round={round_index+1} {name} {dtype}: {ms:.9f} ms / {tflops/1000:.6f} P', flush=True)

summary = []
for name in versions:
    for dtype in ['bf16', 'fp32']:
        selected = [r for r in records if r['name'] == name and r['dtype'] == dtype]
        values = [r['ms'] for r in selected]
        summary.append(dict(name=name, dtype=dtype, median_ms=statistics.median(values), min_ms=min(values), max_ms=max(values), median_pflops=statistics.median(r['pflops'] for r in selected)))
(out / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')
print(json.dumps(summary, indent=2), flush=True)
print(f'LOG_DIRECTORY={out}', flush=True)
