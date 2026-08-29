#!/usr/bin/env python3
"""Remove dead #if branches for macros that the retained build never defines.

The retained kernel carries 21 experiment macros but the default build defines
only four of them (verified with `clang -dM -E`):

    MXFP8_ASYMMETRIC_B_PRODUCER      MXFP8_SFB_READ2ST64
    MXFP8_SCALE_OUTPUT_TILES_PER_WG  MXFP8_MAIN_LOOP_UNROLL

Everything else is dead.  This evaluates the conditionals for the dead set and
drops the branches that can never be taken, leaving the live text unindented
and untouched.

It is deliberately conservative:
  * only `defined(X)` / `!defined(X)` over the KNOWN-OFF set is evaluated;
    anything else (including the four live macros, and any `#if` with a value
    comparison) is left completely alone, nesting and all.
  * `#include`, `#define`, `#pragma` are never touched.

The result must produce byte-identical ISA.  Verify, do not trust.
"""
import re
import sys

# Macros the default build leaves undefined.  Sourced from `clang -dM -E`, not
# from reading the source -- a macro that looks unused may be set by a .cc
# entry point or the Makefile.
DEAD = {
    'MXFP8_EXPERIMENTAL_4WAVE_LAYOUTS',
    'MXFP8_B0_THREE_SLOT',
    'MXFP8_SINGLE_STAGE_B',
    'MXFP8_A0_THREE_SLOT',
    'MXFP8_INTERLEAVED_TAIL_A_N0',
    'MXFP8_INTERLEAVED_TAIL_PRODUCER',
    'MXFP8_WIDE_N_WAVE',
    'MXFP8_SINGLE_STAGE_A',
    'MXFP8_INTERLEAVED_TAIL_A',
    'MXFP8_EARLY_C_STORE',
    'MXFP8_WIDE_AGPR_FRAGMENTS',
    'MXFP8_SCALE_PRODUCER_WAVE_N1',
    'MXFP8_ASYMMETRIC_A_PRODUCER_WAVE_N',
    'MXFP8_ASYMMETRIC_A_ONE_HALF',
    'MXFP8_STAGGERED_TAIL_MFMA',
    'MXFP8_ASYMMETRIC_B_TAIL_PRIORITY',
    'MXFP8_PRESHUFFLE_B',
    'MXFP8_ASYMMETRIC_B_SPLIT_3_1',
    'MXFP8_ASYMMETRIC_B_ALTERNATE',
}

# Macros the template #defines unconditionally at the top.  Their branches are
# just as statically decidable as the dead ones, only the other way round.
# Pass --fold-live to fold them too (and drop the two #defines by hand).
ALIVE = set()

COND = re.compile(r'^\s*#\s*(if|ifdef|ifndef|elif|else|endif)\b(.*)$')


def evaluate(expr):
    """Return True/False if expr is decidable from DEAD alone, else None."""
    e = expr.strip()
    if not e:
        return None
    # Normalise `defined X` to `defined(X)`.
    e = re.sub(r'defined\s+([A-Za-z_]\w*)', r'defined(\1)', e)
    names = re.findall(r'defined\s*\(\s*([A-Za-z_]\w*)\s*\)', e)
    if not names:
        return None
    # Every referenced macro must be in the known-dead set, or we cannot decide.
    if any(n not in DEAD and n not in ALIVE for n in names):
        return None
    py = re.sub(r'defined\s*\(\s*([A-Za-z_]\w*)\s*\)',
                lambda m: 'True' if m.group(1) in ALIVE else 'False', e)
    py = py.replace('&&', ' and ').replace('||', ' or ').replace('!', ' not ')
    # Reject anything that is not a pure boolean expression now.
    if not re.fullmatch(r'[\s()orandotFalseTru]*', py):
        return None
    try:
        return bool(eval(py, {'__builtins__': {}}, {}))
    except Exception:
        return None


def strip(folded):
    """folded: list of (logical_text, [physical_lines]).  Returns physical."""
    out = []
    # stack of dicts: decided(bool), emitting(bool), taken(bool)
    stack = []
    for line, physical in folded:
        m = COND.match(line)
        if not m:
            if all(f['emitting'] for f in stack):
                out.extend(physical)
            continue
        kind, rest = m.group(1), m.group(2)

        if kind in ('if', 'ifdef', 'ifndef'):
            if kind == 'ifdef':
                val = evaluate(f'defined({rest.strip()})')
            elif kind == 'ifndef':
                val = evaluate(f'!defined({rest.strip()})')
            else:
                val = evaluate(rest)
            parent_emit = all(f['emitting'] for f in stack)
            if val is None:
                stack.append({'decided': False, 'emitting': parent_emit,
                              'taken': False})
                if parent_emit:
                    out.extend(physical)
            else:
                stack.append({'decided': True, 'emitting': parent_emit and val,
                              'taken': val})
        elif kind == 'elif':
            f = stack[-1]
            parent_emit = all(x['emitting'] for x in stack[:-1])
            if f['decided']:
                val = evaluate(rest)
                if val is None:
                    # The chain started with a dead condition but this branch
                    # tests something live.  If no earlier branch was taken,
                    # every one of them was statically false, so the chain can
                    # be reopened as a plain `#if` with the same meaning; the
                    # rest of the chain then passes through untouched.
                    if f['taken']:
                        f['emitting'] = False
                        continue
                    f['decided'] = False
                    f['emitting'] = parent_emit
                    if parent_emit:
                        head = re.sub(r'(#\s*)elif\b', r'\1if', physical[0], 1)
                        out.append(head)
                        out.extend(physical[1:])
                    continue
                f['emitting'] = parent_emit and val and not f['taken']
                f['taken'] = f['taken'] or val
            else:
                if parent_emit:
                    out.extend(physical)
        elif kind == 'else':
            f = stack[-1]
            parent_emit = all(x['emitting'] for x in stack[:-1])
            if f['decided']:
                f['emitting'] = parent_emit and not f['taken']
                f['taken'] = True
            else:
                if parent_emit:
                    out.extend(physical)
        elif kind == 'endif':
            f = stack.pop()
            if not f['decided'] and all(x['emitting'] for x in stack):
                out.extend(physical)
    if stack:
        raise SystemExit('unbalanced conditionals')
    return out


def join_continuations(lines):
    """Fold backslash-continued preprocessor lines into one logical line.

    Kept as a (text, original_lines) pair so unfolded output is byte-identical
    for the branches we leave alone.
    """
    out, i = [], 0
    while i < len(lines):
        cur = lines[i]
        group = [cur]
        while cur.rstrip().endswith('\\') and i + 1 < len(lines):
            i += 1
            cur = lines[i]
            group.append(cur)
        joined = ' '.join(l.rstrip().rstrip('\\').strip() for l in group) \
            if len(group) > 1 else group[0]
        out.append((joined, group))
        i += 1
    return out


def main():
    args = sys.argv[1:]
    if '--fold-live' in args:
        args.remove('--fold-live')
        ALIVE.update({'MXFP8_SFB_READ2ST64', 'MXFP8_ASYMMETRIC_B_PRODUCER'})
    src = args[0]
    raw = open(src).read().split('\n')
    folded = join_continuations(raw)
    # strip() decides on logical lines but returns physical ones, so a
    # continued directive comes back exactly as it was written.
    out = strip(folded)
    # Collapse runs of 3+ blank lines left behind by removed branches.
    collapsed, blanks = [], 0
    for l in out:
        if l.strip() == '':
            blanks += 1
            if blanks > 2:
                continue
        else:
            blanks = 0
        collapsed.append(l)
    sys.stdout.write('\n'.join(collapsed))


if __name__ == '__main__':
    main()
