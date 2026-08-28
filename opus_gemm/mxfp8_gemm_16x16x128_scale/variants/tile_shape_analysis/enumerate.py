#!/usr/bin/env python3
"""Enumerate feasible WG tile shapes for the MXFP8 16x16x128 scale GEMM.

Purely analytic -- no code is changed and nothing is compiled.  The question
being answered is whether any tile shape reachable under this kernel's real
constraints moves enough bytes less than the current 256x256x128 to be worth
the rewrite, given that the instruction-placement line is closed.

Constraints encoded (all read out of gemm_a8w8_mxfp8_scale_common.h and the
kernel template, not assumed):

  * BLOCK_SIZE 512 threads = 8 waves, and NUM_WAVES == T_M * T_N * T_K.
  * MFMA is 16x16x128, so W_M = W_N = 16, W_K = 128, and B_K % W_K == 0.
  * HALF_B_M % (W_M*T_M) == 0 and HALF_B_N % (W_N*T_N) == 0  -- the kernel
    splits both M and N in half, so B_M and B_N must be even multiples.
  * LDS: A and B each take smem_?_rep*(smem_linear_wave+pad) * 2 halves * 2
    stages, plus 2 stages of E8M0 scales.  Hardware limit 163840 B/workgroup.
    Calibrated: 256x256x128 -> 139264 B, matching the compiler exactly.
  * Accumulators must fit in VGPRs.  v_c is [2][2][E_M*E_N] fragments of 4
    dwords, and the operand/address registers cost roughly what they cost
    today, so the accumulator budget is calibrated against the known-good
    256x256x128 point (236 VGPR total, 64 of which are accumulators).
"""

LDS_LIMIT = 163840
VGPR_LIMIT = 256
WARP = 64
BLOCK_SIZE = 512
NUM_WAVES = BLOCK_SIZE // WARP
W_M = W_N = 16
W_K = 128
VEC_A = VEC_B = 16
PAD = 32
GROUP_K = 32

# Calibration point: the retained winner.
REF = (256, 256, 128)
REF_VGPR_TOTAL = 236
REF_LDS = 139264

# Measured on GPU7 with the subtraction ladder (see session notes):
#   full kernel 0.4485 ms, minus C store 0.4086, minus global 0.3501,
#   MFMA+LDS skeleton 0.3215.  So of the 0.4485,
#     0.3215 is compute+LDS floor,
#     0.0286 is the global-load path,
#     0.0399 is the C store.
SKELETON_MS = 0.3215
GLOBAL_MS = 0.3501 - 0.3215
CSTORE_MS = 0.4485 - 0.4086
FULL_MS = 0.4485
PEAK_P = 5.008  # measured MFMA peak, PFlops


def acc_vgprs(bm, bn):
    """Accumulator VGPRs per lane.

    Each wave owns (bm/2/T_M/W_M)*(bn/2/T_N/W_N) = E_M*E_N fragments per
    quadrant, 4 quadrants ([2][2]), 4 dwords each.
    """
    for tm in (4, 2, 8, 1):
        tn = NUM_WAVES // tm
        if tm * tn != NUM_WAVES:
            continue
        hm, hn = bm // 2, bn // 2
        if hm % (W_M * tm) or hn % (W_N * tn):
            continue
        em = hm // (W_M * tm)
        en = hn // (W_N * tn)
        return 4 * em * en * 4, tm, tn, em, en
    return None


def lds_bytes(bm, bn, bk, stages=2):
    # Each of A and B is allocated smem_?_elem * 4: two pipeline stages times
    # two physical halves (the kernel splits M and N in half).  Verified: at
    # 256x256x128 this reproduces the actual 139264 B exactly.
    smem_linear_wave = WARP * VEC_A
    smem_sub = smem_linear_wave // bk
    if smem_sub == 0:
        return None
    m_rep = (bm // 2) // smem_sub
    n_rep = (bn // 2) // smem_sub
    if m_rep == 0 or n_rep == 0:
        return None
    a = m_rep * (smem_linear_wave + PAD)
    b = n_rep * (smem_linear_wave + PAD)
    kg = bk // GROUP_K
    sf = (bm * kg + bn * kg) * 2  # 2 stages of E8M0 scales, 1 B each
    return (a + b) * 2 * stages + sf


def feasible(bm, bn, bk):
    if bm % (2 * W_M) or bn % (2 * W_N) or bk % W_K:
        return None
    got = acc_vgprs(bm, bn)
    if not got:
        return None
    acc, tm, tn, em, en = got
    lds = lds_bytes(bm, bn, bk)
    if lds is None or lds > LDS_LIMIT:
        return None
    # Non-accumulator VGPR cost, calibrated at the reference point.
    ref_acc = acc_vgprs(*REF[:2])[0]
    overhead = REF_VGPR_TOTAL - ref_acc
    vgpr = acc + overhead
    if vgpr > VGPR_LIMIT:
        return None
    return dict(bm=bm, bn=bn, bk=bk, tm=tm, tn=tn, em=em, en=en,
                acc=acc, vgpr=vgpr, lds=lds)


def bytes_per_flop(bm, bn, bk):
    """Global bytes moved per unit of MACs, for the K loop only.

    Per K tile a workgroup reads A (bm x bk) and B (bn x bk), 1 byte each,
    plus E8M0 scales at 1 byte per 32 elements.  It performs bm*bn*bk MACs.
    C store is handled separately since it does not scale with K.
    """
    ab = (bm * bk + bn * bk)
    sf = (bm * bk + bn * bk) / GROUP_K
    return (ab + sf) / (bm * bn * bk)


READ_BW = 6.119e12    # measured HBM read, B/s
L2_HIT = 0.728        # measured with fixed-B persistent x4


def ab_bytes(cand, m=8192, n=8192, k=8192):
    """Total A+B global bytes for the whole problem at this tile shape."""
    bm, bn, bk = cand['bm'], cand['bn'], cand['bk']
    tiles = (m // bm) * (n // bn)
    per_wg = (bm * 128 + bn * 128) * (1 + 1 / GROUP_K) * (k // 128)
    return per_wg * tiles


def model(cand, m=8192, n=8192, k=8192):
    """Two-term model: compute floor vs DRAM floor, whichever binds.

    The ladder's "minus global loads" delta (0.0286 ms) is NOT a traffic
    cost -- it is the *exposed* wait left after the pipeline has already
    hidden most of the latency.  The traffic itself is far larger: 4.4 GB of
    A+B at 256x256, which at 6.119 TB/s would be 0.719 ms of DRAM time,
    more than the entire 0.4485 ms kernel.  L2 absorbs the difference.

    So a shape change moves the DRAM floor, not merely the exposed wait.
    Runtime is modelled as max(compute floor, DRAM floor) + exposed wait.
    """
    dram = ab_bytes(cand, m, n, k) * (1 - L2_HIT)
    dram_ms = dram / READ_BW * 1000
    compute_ms = SKELETON_MS + CSTORE_MS
    t = max(compute_ms, dram_ms) + GLOBAL_MS
    perf = 2 * m * n * k / (t / 1000) / 1e15
    ref_bpf = bytes_per_flop(*REF)
    bpf = bytes_per_flop(cand['bm'], cand['bn'], cand['bk'])
    cand['dram_ms'] = dram_ms
    cand['bound'] = 'DRAM' if dram_ms > compute_ms else 'compute'
    return t, perf, perf / PEAK_P * 100, bpf / ref_bpf


rows = []
for bm in (64, 96, 128, 160, 192, 224, 256, 320, 384, 448, 512):
    for bn in (64, 96, 128, 160, 192, 224, 256, 320, 384, 448, 512):
        for bk in (128, 256):
            c = feasible(bm, bn, bk)
            if c:
                t, p, mfu, br = model(c)
                c.update(t=t, p=p, mfu=mfu, br=br)
                rows.append(c)

rows.sort(key=lambda r: -r['p'])
ref = next(r for r in rows if (r['bm'], r['bn'], r['bk']) == REF)

print(f"LDS limit {LDS_LIMIT} B   VGPR limit {VGPR_LIMIT}   waves {NUM_WAVES}")
print(f"reference {REF[0]}x{REF[1]}x{REF[2]}: LDS {ref['lds']} B (actual "
      f"{REF_LDS}), VGPR {ref['vgpr']} (actual {REF_VGPR_TOTAL})")
print()
print(f"{'shape':>16} {'TmxTn':>6} {'ExE':>6} {'acc':>4} {'VGPR':>5} "
      f"{'LDS':>7} {'bytes':>6} {'DRAM ms':>8} {'model ms':>9} "
      f"{'model P':>8} {'MFU':>6} {'bound':>7}")
print("-" * 92)
for r in rows[:22]:
    tag = "  <-- current" if (r['bm'], r['bn'], r['bk']) == REF else ""
    print(f"{r['bm']:>5}x{r['bn']}x{r['bk']:<4} {r['tm']}x{r['tn']:>4} "
          f"{r['em']}x{r['en']:>4} {r['acc']:>4} {r['vgpr']:>5} "
          f"{r['lds']:>7} {r['br']:>6.3f} {r['dram_ms']:>8.4f} "
          f"{r['t']:>9.4f} {r['p']:>8.3f} "
          f"{r['mfu']:>5.1f}% {r['bound']:>7}{tag}")

print()
print(f"feasible shapes: {len(rows)}")
best = rows[0]
print(f"best modelled: {best['bm']}x{best['bn']}x{best['bk']} -> "
      f"{best['p']:.3f} P ({best['mfu']:.1f}% MFU), "
      f"{(best['p'] / ref['p'] - 1) * 100:+.1f}% vs current")
print()
print("Ceiling check -- if the global-load path were free entirely:")
t0 = SKELETON_MS + CSTORE_MS
print(f"  {t0:.4f} ms -> {2 * 8192 ** 3 / (t0 / 1000) / 1e15:.3f} P "
      f"({2 * 8192 ** 3 / (t0 / 1000) / 1e15 / PEAK_P * 100:.1f}% MFU)")
t1 = SKELETON_MS
print(f"  and if C store were also free: {t1:.4f} ms -> "
      f"{2 * 8192 ** 3 / (t1 / 1000) / 1e15:.3f} P "
      f"({2 * 8192 ** 3 / (t1 / 1000) / 1e15 / PEAK_P * 100:.1f}% MFU)")
