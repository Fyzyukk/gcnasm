#!/usr/bin/env python3
"""Build and compare frozen regroll_release8 tile1 with the current source.

The GPU argument is the physical rocm-smi card, resolved to HIP by PCI address.
Every candidate uses the same inputs and output pointers within one process.
"""
import argparse
import datetime
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--gpu', type=int, required=True, help='Physical rocm-smi card index')
    parser.add_argument('--rounds', type=int, default=5)
    parser.add_argument('--tag', help='Unique result directory name')
    parser.add_argument('--validate', action='store_true', help='Also run the independent full-output reference')
    parser.add_argument('--max-initial-vram-percent', type=int, default=1,
                        help='Allow idle resident allocations up to this percentage; activity must still be <=5%%')
    args = parser.parse_args()
    if args.rounds <= 0 or not 0 <= args.max_initial_vram_percent <= 100:
        parser.error('rounds must be positive and the VRAM threshold must be in [0,100]')
    root = Path(__file__).resolve().parents[1]
    evidence = root / 'results/tile1_target32_20260911'
    support = root / 'results/continuation_20260911/round3/support'
    status = json.loads(subprocess.check_output(
        ['rocm-smi', '--showbus', '--showuse', '--showmemuse', '--json'], text=True))
    card = status[f'card{args.gpu}']
    pci = card['PCI Bus'].lower()
    if int(card['GPU use (%)']) > 5 or int(card['GPU Memory Allocated (VRAM%)']) > args.max_initial_vram_percent:
        raise SystemExit(f'GPU{args.gpu} {pci} exceeds the selected idle thresholds: {card}')
    visibility = {'HIP_VISIBLE_DEVICES', 'ROCR_VISIBLE_DEVICES', 'CUDA_VISIBLE_DEVICES', 'GPU_DEVICE_ORDINAL'}
    env = {k: v for k, v in os.environ.items() if k not in visibility}
    probe = '''import ctypes,json
hip=ctypes.CDLL('/opt/rocm/lib/libamdhip64.so')
count=ctypes.c_int();assert hip.hipGetDeviceCount(ctypes.byref(count))==0
out=[]
for i in range(count.value):
 b=ctypes.create_string_buffer(64)
 assert hip.hipDeviceGetPCIBusId(b,64,i)==0
 out.append(dict(hip_index=i,pci=b.value.decode().lower()))
print(json.dumps(out))
'''
    devices = json.loads(subprocess.check_output([sys.executable, '-c', probe], env=env, text=True))
    hip_index = next(x['hip_index'] for x in devices if x['pci'] == pci)
    tag = args.tag or 'reproduced_' + datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d_%H%M%S')
    work = Path(tempfile.mkdtemp(prefix='mxfp8_4wave_compare_'))
    print(f'GPU{args.gpu}, PCI {pci}, HIP {hip_index}; work directory: {work}', flush=True)
    for name, source in [('baseline', evidence / 'baseline_source'), ('current', root)]:
        dest = work / name
        dest.mkdir()
        for path in source.iterdir():
            if path.is_file() and (path.suffix in ['.hpp', '.h', '.cc'] or path.name in ['Makefile', 'blockscale_bpreshuffle.py']):
                shutil.copy2(path, dest / path.name)
        with (dest / 'build.log').open('w') as log:
            subprocess.run(['make', '-j2', 'all', 'inspect'], cwd=dest, stdout=log, stderr=subprocess.STDOUT, check=True)
    shutil.copy2(evidence / 'selected/candidate.json', work / 'current/candidate.json')
    subprocess.run(['make', '-j2', 'all'], cwd=support, check=True)
    env.update(HIP_VISIBLE_DEVICES=str(hip_index), MXFP8_EXPECTED_PCI=pci,
               MXFP8_WORK_DIR=str(work), MXFP8_SHARED_ROUNDS=str(args.rounds),
               MXFP8_BRACKETED='1', MXFP8_NATIVE_TIMING='1', MXFP8_TELEMETRY='0',
               MXFP8_MAX_INITIAL_VRAM_PERCENT=str(args.max_initial_vram_percent),
               MXFP8_AUDIT_OUTPUT_DIR=str(work / 'audits'),
               OMP_TOOL='disabled', OMP_NUM_THREADS='16')
    subprocess.run([sys.executable, str(evidence / 'audit_unroll.py'), 'current'], env=env, check=True)
    if args.validate:
        subprocess.run([sys.executable, str(evidence / 'run.py'), 'verify', '--tag', tag,
                        '--pci', pci, 'current'], env=env, check=True)
    subprocess.run([sys.executable, str(evidence / 'run.py'), 'shared', tag,
                    'baseline', 'current'], env=env, check=True)
    result = evidence / 'shared_allocations' / tag
    shutil.copy2(work / 'audits/current.json', result / 'static_audit.json')
    print(f'Results: {result}', flush=True)


if __name__ == '__main__':
    main()
