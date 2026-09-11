#!/usr/bin/env python3
"""Create a K8192-only persistent tile4 experiment from the selected tile1."""
import difflib
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
dest = Path(__file__).resolve().parent
source_hash = "1b1c87b28c1ae645cd8986e00aae0f870f089044c8a8eac4d761e396deafe53a"
assert hashlib.sha256((root / "tmpl.hpp").read_bytes()).hexdigest() == source_hash
work = Path(tempfile.mkdtemp(prefix="mxfp8_current_tile4_20260911_"))
files = [
    "Makefile", "tmpl.hpp", "tmpl_generic.hpp", "traits.hpp", "kernel_dispatch.hpp",
    "gemm_a8w8_mxfp8_scale_common.h", "gemm_a8w8_mxfp8_scale_host.cc",
    "gemm_a8w8_mxfp8_scale_kernel.cc", "gemm_a8w8_blockscale_bpreshuffle_launch.cc",
    "blockscale_bpreshuffle.py",
]
for name in ["baseline", "tile4"]:
    d = work / name
    d.mkdir()
    for f in files:
        shutil.copy2(root / f, d / f)


def replace_once(text, before, after):
    assert text.count(before) == 1, before
    return text.replace(before, after, 1)


original = (root / "tmpl.hpp").read_text()
prefix, body = original.split("    const int wgid = block_id_x();", 1)
_, body = body.split("    auto g_a = make_gmem(", 1)
body = "    auto g_a = make_gmem(" + body
body, suffix = body.rsplit("\n}\n\n} // namespace blockscale_panel", 1)
assert not suffix.strip()
hoisted = [
    "    constexpr int smem_a_elem = T::smem_m_rep * (T::smem_linear_wave + T::smem_padding);\n",
    "    constexpr int smem_b_elem = T::smem_n_rep * (T::smem_linear_wave + T::smem_padding);\n",
    "    __shared__ char smem_a[smem_a_elem * 4 * sizeof(D_A)];\n",
    "    __shared__ char smem_b[smem_b_elem * 4 * sizeof(D_B)];\n",
    "    alignas(8) __shared__ char smem_sfa[T::SFA_PANEL_BYTES];\n",
    "    alignas(8) __shared__ char smem_sfb[T::SFB_PANEL_BYTES];\n",
]
for declaration in hoisted:
    body = replace_once(body, declaration, "")
header = """    const int wgid = block_id_x();
    const int num_tiles_n = ceil_div_scale(kargs.n, T::B_N);
    const int block_m_base = (wgid / num_tiles_n) * T::OUTPUT_TILES_PER_WG;
    const int block_n = wgid % num_tiles_n;
    const int col = block_n * T::B_N;
    const int batch_id = block_id_z();
    const int wave_id = __builtin_amdgcn_readfirstlane(thread_id_x() / T::WARP_SIZE);
    const int lane_id = thread_id_x() % T::WARP_SIZE;
    static_assert(T::OUTPUT_TILES_PER_WG == 4);
""" + "".join(hoisted) + """
    // Reuse this workgroup for up to four complete 256x256 output tiles.
    // The uniform tail guard supports M tile counts not divisible by four.
#pragma unroll 1
    for (int output_tile = 0; output_tile < T::OUTPUT_TILES_PER_WG; ++output_tile) {
        const int block_m = block_m_base + output_tile;
        const int row = block_m * T::B_M;
        if (row >= kargs.m) break;
"""
indented = "\n".join("    " + line if line else line for line in body.splitlines())
boundary = """

        // Finish every old-tile LDS/VMEM consumer before reusing the panels.
        s_waitcnt_vmcnt(0_I);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);
    }
}

} // namespace blockscale_panel
"""
(work / "tile4/tmpl.hpp").write_text(prefix + header + indented + boundary)

p = work / "tile4/traits.hpp"
p.write_text(replace_once(p.read_text(), "OUTPUT_TILES_PER_WG = 1;", "OUTPUT_TILES_PER_WG = 4;"))

p = work / "tile4/gemm_a8w8_mxfp8_scale_host.cc"
s = p.read_text()
for before, after in [
    ("int k = 256;", "int k = 8192;"),
    ("[--tiles 0|1]", "[--tiles 0|4]"),
    ("K must be a multiple of 128.", "This tile4 experiment requires K=8192."),
    ("K=256 batch=8", "K=8192 batch=8"),
    ("opts.tiles != 1", "opts.tiles != 4"),
    ("--tiles must be 0 (auto) or 1", "--tiles must be 0 (auto) or 4"),
    ("int pick_output_tiles_per_wg(int, int, int) { return 1; }", "int pick_output_tiles_per_wg(int, int, int) { return 4; }"),
    ("    return opts;", "    if (opts.k != 8192) throw std::invalid_argument(\"tile4 experiment requires K=8192\");\n    return opts;"),
]:
    s = replace_once(s, before, after)
p.write_text(s)

p = work / "tile4/gemm_a8w8_blockscale_bpreshuffle_launch.cc"
s = replace_once(p.read_text(), "const dim3 grid((args.m / 256) * (args.n / 256), 1, args.batch);",
                 "const dim3 grid(ceil_div_scale(args.m / 256, 4) * (args.n / 256), 1, args.batch);")
s = replace_once(s, "(tiles != 0 && tiles != 1)", "(tiles != 0 && tiles != 4)")
s = replace_once(s, "a.m % 256 || a.n % 256 || a.k % 128 ||", "a.m % 256 || a.n % 256 || a.k != 8192 ||")
p.write_text(s)

p = work / "tile4/blockscale_bpreshuffle.py"
s = p.read_text().replace("`tiles` may be 0/1.", "This experiment requires K=8192; `tiles` may be 0/4.")
s = s.replace("tiles not in (0, 1)", "tiles not in (0, 4)")
s = s.replace("tiles must be 0 or 1", "tiles must be 0 or 4")
p.write_text(s)

patch_dir = dest / "candidate_patches"
patch_dir.mkdir(exist_ok=True)
hashes = {}
for f in files:
    old, new = (root / f).read_bytes(), (work / "tile4" / f).read_bytes()
    hashes[f] = hashlib.sha256(new).hexdigest()
    if old != new:
        patch = "".join(difflib.unified_diff(old.decode().splitlines(True), new.decode().splitlines(True),
                                              fromfile="a/" + f, tofile="b/" + f))
        (patch_dir / (f + ".patch")).write_text(patch)

# The inner compute body is preserved byte-for-byte before indentation.
normalized = "\n".join(line.strip() for line in body.splitlines() if line.strip())
manifest = {
    "baseline": "current regroll_release8 tile1",
    "base_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip(),
    "baseline_tmpl_sha256": source_hash,
    "candidate": "current regroll_release8 with persistent tile4",
    "required_k": 8192,
    "num_waves": 4,
    "output_tile_shape": [256, 256],
    "output_tiles_per_wg": 4,
    "mapping": "block_m=(wgid/num_tiles_n)*4+output_tile; block_n=wgid%num_tiles_n",
    "tile_boundary": ["vmcnt(0)", "lgkmcnt(0)", "s_barrier", "sched_barrier(0)"],
    "inner_body_preserved_except_six_hoisted_declarations": True,
    "normalized_inner_body_sha256": hashlib.sha256(normalized.encode()).hexdigest(),
    "candidate_source_sha256": hashes,
    "work_directory": str(work),
}
(dest / "candidate.json").write_text(json.dumps(manifest, indent=2) + "\n")
(dest / "work_path.txt").write_text(str(work) + "\n")
print(work)
