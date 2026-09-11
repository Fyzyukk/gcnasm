#!/usr/bin/env python3
"""CPU model of the proposed R4/P36 one-A, three-B protocol.

This checks the proposed protocol, independently of compiler instruction
placement. Candidate source and machine waits require a separate audit.
"""
from collections import Counter, deque
from pathlib import Path
import json


def simulate(wrapped_slot=False, skip_dead=False, drain_at_release=False,
             drain_at_publish=False):
    # B0 and A0 are complete at the original prologue publication barrier.
    a_lds = 0
    a0 = [0] * 4
    a1 = None
    b0 = 0
    b1 = None
    b_slots = [{'logical_tile': 0, 'global_tile': 0, 'ready': True,
                'readers_released': False}, None, None]
    # One queue models each B-producer wave; waves2/3 have identical request
    # counts and both must reach the publication barrier. Each ticket is one
    # 16B-per-lane DTLDS instruction (64 participating lanes).
    pending = deque()
    complete = Counter()
    issue_times = {}
    forced_completion_times = {}

    def issue(logical_tile, at):
        if skip_dead and logical_tile >= 64:
            return
        global_tile = logical_tile & 63
        slot = global_tile % 3 if wrapped_slot else logical_tile % 3
        old = b_slots[slot]
        assert old is None or old['readers_released'], (
            'B destination still has live readers', logical_tile, global_tile, slot, old)
        assert not any(e[0] == slot for e in pending), ('pending B write would be overwritten', slot)
        b_slots[slot] = {'logical_tile': logical_tile, 'global_tile': global_tile,
                        'ready': False, 'readers_released': False}
        issue_times[logical_tile] = at
        for half in range(2):
            for role in range(2):
                for request in range(4):
                    pending.append((slot, logical_tile, half, role, request))

    def wait_b(allowed, at):
        # Conservative no-progress-until-wait execution. Dropping oldest
        # same-type VMEM tickets models the ordering used by vmcnt waits.
        while len(pending) > allowed:
            slot, logical_tile, half, role, request = pending.popleft()
            assert b_slots[slot]['logical_tile'] == logical_tile
            complete[logical_tile] += 1
            if complete[logical_tile] == 16:
                b_slots[slot]['ready'] = True
                forced_completion_times[logical_tile] = at

    def consume_b_slot(tile):
        slot = b_slots[tile % 3]
        assert slot is not None and slot['logical_tile'] == tile and slot['ready'], (
            'unpublished or wrong B generation', tile, slot, list(pending))
        assert slot['global_tile'] == tile
        return tile

    # B1/B2 use the SAME two-wave producer split as steady state: 16 tickets
    # per tile in EACH B-producer wave. No extra prologue drain is required.
    issue(1, -2)
    issue(2, -1)
    source_consumers = 0
    trace = []
    for tile in range(64):
        assert a_lds == tile and a0 == [tile] * 4 and b0 == tile
        current = tile % 3
        consume_b_slot(tile)
        a1 = None
        b1 = None
        a_requests = []
        released_a = False
        published_next_a = False
        for mfma in range(1, 65):
            # The current A1 DS read is issued after MFMA2 and completed by
            # the new lgkmcnt(0) at R4. Current B1 DS groups issue after4/16/20;
            # first c01 uses begin at33, with ordinary DS-register waits.
            if mfma == 3:
                a1 = tile
            if mfma == 33:
                b1 = consume_b_slot(tile)
            quadrant, local = divmod(mfma - 1, 16)
            mr = local // 4
            av = a0[mr] if quadrant in (0, 2) else a1
            bv = b0 if quadrant in (0, 1) else b1
            assert av == bv == tile, ('stale register consumer', tile, mfma, av, bv)
            source_consumers += 1
            if tile == 63:
                continue
            if mfma == 4:
                assert a1 == tile and a0 == [tile] * 4
                released_a = True
                if drain_at_release:
                    wait_b(0, tile * 64 + 4)
                trace.append({'tile': tile, 'point': 'R4', 'b_pending': len(pending)})
            elif mfma in (5, 6):
                assert released_a
                a_requests.extend([(tile + 1, mfma - 5, role, request)
                                   for role in range(2) for request in range(4)])
                assert len(a_requests) in (8, 16)
            elif mfma == 36:
                # A-producer vmcnt0 completes all16 A tickets. B-producer
                # vmcnt16 retires B(t+1), preserving B(t+2) if still pending.
                assert len(a_requests) == 16
                a_lds = tile + 1
                published_next_a = True
                wait_b(0 if drain_at_publish else 16, tile * 64 + 36)
                consume_b_slot(tile + 1)
                assert b1 == tile
                b_slots[current]['readers_released'] = True
                trace.append({'tile': tile, 'point': 'P36', 'b_pending': len(pending),
                              'a_published': a_lds, 'b_published': tile + 1,
                              'b_released_slot': current})
            elif mfma == 38:
                # The two B halves issue after37/38. There is no wait or LDS
                # read between them that uses their destination, so one
                # complete 16-ticket generation suffices for this model.
                issue(tile + 3, tile * 64 + 38)
                b0 = consume_b_slot(tile + 1)
            elif mfma == 48:
                assert published_next_a and a_lds == tile + 1
                a0 = [a_lds] * 4  # Both dtypes retain the original whole-A0 roll.
        if tile == 63:
            assert a_lds == 63 and b_slots[0]['logical_tile'] == 63
    assert source_consumers == 4096
    assert all(complete[t] == 16 for t in range(1, 64))
    b_completion_gaps = {str(t): forced_completion_times[t] - issue_times[t]
                         for t in range(3, 64)}
    return {'source_mfma_consumers': source_consumers,
            'source_barriers': {'prologue': 1, 'R4': 63, 'P36': 63, 'total': 127},
            'A_global_requests_per_producer_wave_per_iteration': 16,
            'B_global_requests_per_producer_wave_per_iteration': 16,
            'B_prologue_requests_per_producer_wave': 32,
            'A_global_issue_to_publish_mfma_gaps': [31, 30],
            'B_steady_issue_to_required_publish_mfma_gap': 126,
            'B_forced_completion_gaps': b_completion_gaps,
            'R4_pending_B_counts': sorted({x['b_pending'] for x in trace if x['point'] == 'R4'}),
            'P36_pending_B_counts': sorted({x['b_pending'] for x in trace if x['point'] == 'P36'}),
            'tail': {'tile': 63, 'A_slot': 0, 'B_slot': 0,
                     'dead_B64': {'global_tile': 0, 'physical_slot': 1},
                     'dead_B65': {'global_tile': 1, 'physical_slot': 2},
                     'unused_B_tickets_still_allowed_per_producer_wave': len(pending)},
            'trace': trace}


def main():
    correct = simulate()
    failures = {}
    for name, kwargs in [('wrapped_global_tile_selects_slot', {'wrapped_slot': True}),
                         ('skip_dead_prefetch_keep_vmcnt16', {'skip_dead': True})]:
        try:
            simulate(**kwargs)
        except AssertionError as exc:
            failures[name] = str(exc)
        else:
            raise AssertionError(('known invalid variant was accepted', name))
    r4_drain = simulate(drain_at_release=True)
    p36_drain = simulate(drain_at_publish=True)
    report = {'status': 'PASS for proposed protocol; source and ISA audits still required',
              'scope': 'CPU specification model; no candidate edits or GPU calls',
              'layout': {'A_bytes': 33792, 'B_bytes': 101376,
                         'matrix_bytes': 135168, 'scale_bytes': 16896, 'total_LDS_bytes': 152064},
              'correct': correct, 'rejected_counterexamples': failures,
              'compiler_drain_effect': {
                  'R4_vmcnt0_steady_B_forced_window': sorted(set(r4_drain['B_forced_completion_gaps'].values())),
                  'P36_all_wave_vmcnt0_steady_B_forced_window': sorted(set(p36_drain['B_forced_completion_gaps'].values())),
                  'intended_steady_B_forced_window': sorted(set(correct['B_forced_completion_gaps'].values()))}}
    path = Path(__file__).resolve().parent / 'lifecycle_spec_audit.json'
    path.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({k: v for k, v in report.items() if k != 'correct'}, indent=2))


if __name__ == '__main__':
    main()
