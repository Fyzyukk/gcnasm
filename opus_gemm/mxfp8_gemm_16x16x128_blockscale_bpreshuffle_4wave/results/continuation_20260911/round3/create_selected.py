#!/usr/bin/env python3
"""Remove obsolete producer helpers and describe the selected register roll."""
from pathlib import Path
import hashlib
import json
import re
import shutil

root = Path(__file__).resolve().parent
work = Path((root / 'work_path.txt').read_text().strip())
parent = work / 'regroll_release8'
original = (parent / 'tmpl.hpp').read_text()
source = original
begin = source.index('// Issue exactly one request from an OPUS')
end = source.index('__device__ inline void sched_barrier_pairs_scale()', begin)
source = source[:begin] + source[end:]
begin = source.index('    // Two wave-N0 producers cover both original A producer roles.')
end = source.index('    constexpr int smem_a_elem', begin)
source = source[:begin] + source[end:]
source = source.replace(
    '    // B wave ownership is unchanged. The consumer LDS image is unchanged.',
    '    // Each B producer owns one N128 half. Consumer LDS images stay unchanged.')
source = source.replace(
    '    // K64 specialization: the last dead B producer wraps to valid tile zero.',
    '    // K64 specialization: final unused A/B producers wrap to valid tile zero.')
source = source.replace('''        // One scaled MFMA occupies the XDL pipe for roughly 32 cycles on
        // gfx950.  Place the four independent A0(t+1) DTLDS requests directly
        // behind it so their issue work can co-execute with that XDL window.
        // Co-execute both half-tile producer groups under one role branch.''',
    '''        // After publication at MFMA8, all waves issue one t+2 request
        // behind each pair through MFMA38. Wave-uniform resources select
        // the A or B producer without role branches inside the K loop.''')
source = source.replace('''        // The two B producer waves issue sixteen requests under one role
        // branch after MFMA38. The old stage was released at MFMA36.''',
    '''        // Finish the common A/B producer sequence at MFMA38. The
        // old stage was released at MFMA8; next_stage holds published t+1.''')
source = source.replace('''        // remaining twenty-six current-tile MFMAs execute.  The future-B
        // request groups above are already in flight before these DS reads.''',
    '''        // remaining twenty-six current-tile MFMAs execute. The t+2
        // A/B requests are in flight before these next-stage LDS reads.''')
source = source.replace('    // Consume the final resident tile; A0 is already rolling in VGPRs.',
    '''    // Consume the final resident tile with the original direct-store
    // epilogue. Retain its conservative A1 and B1 reloads.''')
source = re.sub(r'\n{3,}', '\n\n', source)
dest = work / 'selected_register_roll'
dest.mkdir(exist_ok=False)
for path in parent.iterdir():
    if path.is_file() and (path.suffix in ['.hpp', '.h', '.cc'] or path.name == 'Makefile'):
        shutil.copy2(path, dest / path.name)
(dest / 'tmpl.hpp').write_text(source)
(dest / 'candidate.json').write_text(json.dumps(dict(
    name=dest.name, parent=parent.name,
    parent_sha256=hashlib.sha256(original.encode()).hexdigest(),
    source_sha256=hashlib.sha256(source.encode()).hexdigest(),
    changes=['Remove unused old asynchronous copy helpers and producer aliases', 'Update pipeline comments', 'Collapse repeated blank lines'],
    intended_machine_code_change=False, not_a_full_gemm=False,
), indent=2) + '\n')
print(dest)
