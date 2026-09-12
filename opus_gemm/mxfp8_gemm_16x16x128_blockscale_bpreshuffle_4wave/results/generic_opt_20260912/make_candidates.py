#!/usr/bin/env python3
"""Reproducible runtime-K candidates based on the committed generic kernel."""
import difflib
import hashlib
import json
from pathlib import Path
import re
import shutil
import sys

HERE = Path(__file__).resolve().parent
WORK = Path((HERE / "work_path.txt").read_text().strip())
BASE = HERE / "baseline_source"


def once(source, old, new):
    assert source.count(old) == 1, (old, source.count(old))
    return source.replace(old, new)


def distribute_scales(source, a_after, b_after, packed=False):
    a_load = "        v_sfa1_next = load_sfa_dword(tile + 1, 1);\n"
    b_load = """        v_sfb_next = __builtin_bit_cast(opus::vector_t<D_SF_PACK, 2>,
            load<8>(s_sfb, ((tile + 1) & panel_mask) * T::SCALE_N_HALVES * 4));
"""
    assert source.count(a_load) == source.count(b_load) == 2
    source = source.replace(a_load, "").replace(b_load, "")
    if packed:
        source = once(source, "    D_SF_PACK v_sfa1_next;",
                      "    opus::vector_t<D_SF_PACK, 2> v_sfa_next;")
        assert source.count("v_sfa1_next") == 2
        source = source.replace("v_sfa1_next", "v_sfa_next[1]")
        old = "v_sfa[0] = load_sfa_dword(tile + 1, 0);"
        assert source.count(old) == 2
        source = source.replace(old, "v_sfa[0] = v_sfa_next[0];")
        a_load = """        v_sfa_next = __builtin_bit_cast(opus::vector_t<D_SF_PACK, 2>,
            load<8>(s_sfa, ((tile + 1) & panel_mask) * T::SFA_PANEL_PITCH
                + (wave_id_m * T::W_M + (lane_id & 15)) * 8));
"""
    start = source.index("    for (tile = 0; tile + 2 < loops; ++tile) {")
    middle = source.index("    // Penultimate runtime K128 block", start)
    end = source.index("    // Consume the final resident tile", middle)
    pieces = [source[:start], source[start:middle], source[middle:end], source[end:]]
    pattern = re.compile(r"        MXFP8_MMA_(PAIR|ONE)\(\s*[^;]+\);\n"
                         r"        (?:sched_barrier_pairs_scale\(\)|__builtin_amdgcn_sched_barrier\(0\));\n")
    for index in [1, 2]:
        count = 0

        def insert(match):
            nonlocal count
            count += 2 if match[1] == "PAIR" else 1
            extra = (a_load if count == a_after else "") + (b_load if count == b_after else "")
            if extra:
                return match[0] + "\n        // Prefetch published scales ahead of the operand roll.\n" + extra + "        __builtin_amdgcn_sched_barrier(0);\n"
            return match[0]

        pieces[index] = pattern.sub(insert, pieces[index])
        assert count == 64, count
    return "".join(pieces)


def allwave_sfb(source):
    source = once(source, """    D_SF_PACK panel_sfb_raw = 0;
    if (wave_id < T::SCALE_N_HALVES) {
        const int valid_column = lane_id < loops ? lane_id : loops - 1;
        const auto raw = load<1>(g_sfb, valid_column, wave_id * kargs.stride_sfb);
        panel_sfb_raw = static_cast<D_SF_PACK>(raw[0]);
    }
""", """    // Every wave reads its M-parity's SFB row. The duplicate byte loads
    // avoid an early branch-join VMEM wait before the initial B requests.
    const int sfb_valid_column = lane_id < loops ? lane_id : loops - 1;
    const auto initial_sfb = load<1>(g_sfb, sfb_valid_column, wave_id_m * kargs.stride_sfb);
    const D_SF_PACK panel_sfb_raw = static_cast<D_SF_PACK>(initial_sfb[0]);
""")
    return once(source, """            D_SF_PACK raw_b = 0;
            if (wave_id < T::SCALE_N_HALVES) {
                const int global_column = next_tile + lane_id;
                const int valid_column = global_column < loops ? global_column : loops - 1;
                const auto raw = load<1>(g_sfb, valid_column, wave_id * kargs.stride_sfb);
                raw_b = static_cast<D_SF_PACK>(raw[0]);
            }
""", """            const int global_column = next_tile + lane_id;
            const int valid_column = global_column < loops ? global_column : loops - 1;
            const auto raw = load<1>(g_sfb, valid_column, wave_id_m * kargs.stride_sfb);
            const D_SF_PACK raw_b = static_cast<D_SF_PACK>(raw[0]);
""")


def uniform_initial_b(source):
    old = "auto gb_offset = [&](int half_tile_n, int tile_k) { return half_tile_n * T::HALF_B_N * kargs.stride_b + tile_k * T::B_K * 16; };"
    new = "auto gb_offset = [&](int half_tile_n, int tile_k) { return __builtin_amdgcn_readfirstlane(half_tile_n * T::HALF_B_N * kargs.stride_b + tile_k * T::B_K * 16); };"
    return once(source, old, new)


def early_accumulator_use(source, read_write):
    marker = "    // B matrix requests can progress while the scale transpose publishes."
    constraint = '+a' if read_write else 'a'
    args = ': ' if read_write else ': : '
    lines = ["    // Materialize C while the initial global requests are in flight."]
    for half in ['00', '01', '10', '11']:
        for fragment in range(16):
            lines.append(f'    asm volatile("" {args}"{constraint}"(c{half}_{fragment}));')
    return once(source, marker, '\n'.join(lines) + '\n\n' + marker)


def scalar_output_copy(source, split_lds):
    begin = source.index("    auto copy_output_half =")
    end = source.index("    const auto gc_offsets", begin)
    setup = """    int copy_global_base = 0;
    opus::vector_t<int, 2> copy_lds_bases = {};
    if constexpr (T::OUTPUT_BF16) {
        const int copy_row = thread_id_x() / 16;
        const int copy_col = (thread_id_x() % 16) * 8;
        copy_global_base = copy_row * kargs.stride_c + copy_col;
        copy_lds_bases[0] = copy_row * c_lds_pitch + copy_col;
        copy_lds_bases[1] = copy_lds_bases[0] + T::HALF_B_M * c_lds_pitch;
        asm volatile("" : "+v"(copy_global_base), "+v"(copy_lds_bases));
    }
    auto copy_output_half = [&](int half_n, int copy_index) {
LDS_ADDRESS
        const auto value = s_c.template load<8>(lds_address);
        const int scalar_offset = copy_index * 16 * kargs.stride_c + half_n * T::HALF_B_N;
        g_c.template store<8>(value, copy_global_base, scalar_offset, opus::number<2>{});
    };

"""
    address = ("        const int lds_address = copy_lds_bases[copy_index / 8]\n"
               "            + (copy_index % 8) * 16 * c_lds_pitch + half_n * T::HALF_B_N;") if split_lds else (
               "        const int lds_address = copy_lds_bases[0]\n"
               "            + copy_index * 16 * c_lds_pitch + half_n * T::HALF_B_N;")
    return source[:begin] + setup.replace("LDS_ADDRESS", address) + source[end:]


def relax_scalar_schedule(source, mask):
    start = source.index("    for (tile = 0; tile + 2 < loops; ++tile) {")
    end = source.index("    // Consume the final resident tile", start)
    body = source[start:end].replace("__builtin_amdgcn_sched_barrier(0);",
                                     f"__builtin_amdgcn_sched_barrier({mask});")
    return source[:start] + body + source[end:]


def unsigned_tile_indices(source):
    source = once(source, "    const int wgid = block_id_x();", "    const unsigned int wgid = block_id_x();")
    source = once(source, "    const int num_tiles_n = ceil_div_scale(kargs.n, T::B_N);",
                  "    // Both launch paths require positive N divisible by B_N.\n"
                  "    const unsigned int num_tiles_n = static_cast<unsigned int>(kargs.n) / T::B_N;")
    return once(source, "    const int loops = ceil_div_scale(kargs.k, T::B_K);",
                "    // Positive K is a multiple of B_K under the public contract.\n"
                "    const int loops = static_cast<unsigned int>(kargs.k) / T::B_K;")


def quarter_output_copy(source, scalar_addresses=False):
    # At MFMA20/36/52/64 one more C quadrant has completed its LDS stores.
    # Each publication copies exactly that 128x128 quadrant, with eight
    # coalesced 16-byte copies per thread. Matrix and K schedules are unchanged.
    prefix, tail = source.split("    // Consume the final resident tile", 1)
    begin = tail.index("    auto copy_output_half =")
    end = tail.index("    const auto gc_offsets", begin)
    definition = """    auto copy_output_quarter = [&](int half_m, int half_n, int copy_index) {
        const int linear = thread_id_x() * 8 + copy_index * T::BLOCK_SIZE * 8;
        const int output_row = linear / T::HALF_B_N + half_m * T::HALF_B_M;
        const int output_col = linear % T::HALF_B_N + half_n * T::HALF_B_N;
        const auto value = s_c.template load<8>(output_row * c_lds_pitch + output_col);
        g_c.template store<8>(value, output_row * kargs.stride_c + output_col,
                             0, opus::number<2>{});
    };

"""
    tail = tail[:begin] + definition + tail[end:]
    begin = tail.index("    if constexpr (T::OUTPUT_BF16) {\n        // All first-half rows are complete;")
    end = tail.index("    }\n", begin) + len("    }\n")
    tail = tail[:begin] + tail[end:]

    def publication(hm, hn):
        return """
    if constexpr (T::OUTPUT_BF16) {
        // Publish only the completed output quadrant before copying it.
        __builtin_amdgcn_sched_barrier(0);
        s_waitcnt_vmcnt(0_I);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);
""" + "\n".join(f"        copy_output_quarter({hm}, {hn}, {i});" for i in range(8)) + "\n    }\n"

    for hm, hn in [(0, 0), (1, 0), (0, 1)]:
        quadrant = f"c{hm}{hn}"
        marker = (f"        MXFP8_STORE_TWO_FRAGMENTS({quadrant}_12, {quadrant}_13, 12);\n"
                  f"        MXFP8_STORE_TWO_FRAGMENTS({quadrant}_14, {quadrant}_15, 14);\n    }}\n")
        tail = once(tail, marker, marker + publication(hm, hn))
    final = """        opus::static_for<T::B_M * T::HALF_B_N / (T::BLOCK_SIZE * 8)>([&](auto copy_i) {
            copy_output_half(1, decltype(copy_i)::value);
        });"""
    tail = once(tail, final, """        opus::static_for<T::HALF_B_M * T::HALF_B_N / (T::BLOCK_SIZE * 8)>([&](auto copy_i) {
            copy_output_quarter(1, 1, decltype(copy_i)::value);
        });""")
    return prefix + "    // Consume the final resident tile" + tail


def output_valu_ratio(source, count, bf16_only=False):
    prefix, tail = source.split("    // Consume the final resident tile", 1)
    body = ("    __builtin_amdgcn_sched_group_barrier(0x08, 1, 0);\n"
            f"    __builtin_amdgcn_sched_group_barrier(0x02, {count}, 0);\n") * 2
    helper = "__device__ inline void sched_barrier_pairs_output() {\n" + body + "}\n\n"
    prefix = once(prefix, "template<class T, int HALF_TILE_M, int M_REPEAT, int N_REPEAT, class MMA>",
                  helper + "template<class T, int HALF_TILE_M, int M_REPEAT, int N_REPEAT, class MMA>")
    call = "sched_barrier_pairs_output();"
    if bf16_only:
        call = "if constexpr (T::OUTPUT_BF16) sched_barrier_pairs_output();\n    else sched_barrier_pairs_scale();"
    tail = tail.replace("sched_barrier_pairs_scale();", call)
    return prefix + "    // Consume the final resident tile" + tail


def final_resident_operands(source, late_retire=False):
    prefix, tail = source.split("    // Consume the final resident tile", 1)
    tail = once(tail, "    v_a[1] = load<T::VEC_A>(s_a, u_ra + sa_offset(stage, 1));\n", "")
    tail = once(tail, "    v_sfb[1] = load_sfb_dword(loops - 1, 1);\n", "")
    old = """    if constexpr (T::OUTPUT_BF16) {
        // Final B1 is resident from the operand seed or the penultimate block.
        v_b = v_b_second;
    } else {
        v_b = load<T::VEC_B>(s_b, u_rb + sb_offset(stage, 1));
    }
"""
    tail = once(tail, old, "    // Both output types retain B1 from the seed or penultimate roll.\n    v_b = v_b_second;\n")
    if late_retire:
        begin = tail.index("    __builtin_amdgcn_s_setprio(1);")
        tail = " and stage completed BF16 rows in LDS.\n" + tail[begin:]
        marker = "    if constexpr (T::OUTPUT_BF16) {\n        const int soff = c_offset(0, 0);"
        assert tail.count(marker) == 4
        replacement = """    if constexpr (T::OUTPUT_BF16) {
        // First eight MFMAs overlap the last matrix readers. Retire those
        // readers on every wave before the first output reuses matrix LDS.
        __builtin_amdgcn_sched_barrier(0);
        s_waitcnt_vmcnt(0_I);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);
        const int soff = c_offset(0, 0);"""
        tail = tail.replace(marker, replacement, 1)
    return prefix + "    // Consume the final resident tile" + tail


def output_row_groups(source, rows):
    assert rows in [32, 64]
    prefix, tail = source.split("    // Consume the final resident tile", 1)
    begin = tail.index("    if constexpr (T::OUTPUT_BF16) {\n        // All first-half rows are complete;")
    end = tail.index("    }\n", begin) + len("    }\n")
    tail = tail[:begin] + tail[end:]
    begin = tail.index("    if constexpr (T::OUTPUT_BF16) {\n        // The padded LDS rows distribute")
    end = tail.index("#undef MXFP8_STORE_QUADRANT", begin)
    tail = tail[:begin] + tail[end:]
    tail = once(tail, "auto copy_output_half = [&](int half_n, int copy_index)",
                "auto copy_output_rows = [&](int row_begin, int half_n, int copy_index)")
    tail = once(tail, "const int output_row = linear / T::HALF_B_N;",
                "const int output_row = row_begin + linear / T::HALF_B_N;")
    pattern = re.compile(r"    if constexpr \(T::OUTPUT_BF16\) \{\n"
                         r"        const int soff = c_offset\(([01]), ([01])\);\n"
                         r"        MXFP8_STORE_TWO_FRAGMENTS\(c[01]{2}_(\d+), c[01]{2}_\d+, \d+\);\n"
                         r"        MXFP8_STORE_TWO_FRAGMENTS\(c[01]{2}_\d+, c[01]{2}_\d+, \d+\);\n"
                         r"    \}\n")
    publications = 0

    def publish(match):
        nonlocal publications
        hm, hn, index = map(int, match.groups())
        row_end = (index // 4 + 1) * 32
        if row_end % rows:
            return match[0]
        publications += 1
        row_begin = hm * 128 + row_end - rows
        copy = "\n".join(f"        copy_output_rows({row_begin}, {hn}, {i});" for i in range(rows // 16))
        return match[0] + """
    if constexpr (T::OUTPUT_BF16) {
        // The completed row group is disjoint from all subsequent stores.
        __builtin_amdgcn_sched_barrier(0);
        s_waitcnt_vmcnt(0_I);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);
""" + copy + "\n    }\n"

    tail, matches = pattern.subn(publish, tail)
    assert matches == 16 and publications == 512 // rows
    assert "copy_output_half" not in tail
    return prefix + "    // Consume the final resident tile" + tail


def move_zero_uses(source, split):
    matches = re.findall(r'    asm volatile\("" : : "a"\(c[01]{2}_\d+\)\);\n', source)
    assert len(matches) == 64
    old = "    // Materialize C while the initial global requests are in flight.\n" + ''.join(matches) + '\n'
    early = 32 if split else 64
    later = ("    // Finish C initialization while the initial B requests progress.\n" + ''.join(matches[early:]) + '\n') if split else ''
    source = once(source, old, later)
    marker = "    D_SF_PACK panel_sfb_raw = 0;"
    return once(source, marker,
                "    // Initialize C while the four SFA requests progress.\n" + ''.join(matches[:early]) + '\n' + marker)


def async_quarter_stores(source, all_quarters):
    targets = [(0, 0), (1, 0), (0, 1), (1, 1)] if all_quarters else [(1, 0)]
    for hm, hn in targets:
        marker = f'copy_output_quarter({hm}, {hn}, '
        copy = source.index(marker)
        line = "        s_waitcnt_vmcnt(0_I);\n"
        wait = source.rfind(line, 0, copy)
        assert copy - wait < 450
        source = source[:wait] + source[wait+len(line):]
    return source


def compute_valu_ratio(source, count):
    body = ("    __builtin_amdgcn_sched_group_barrier(0x08, 1, 0);\n"
            f"    __builtin_amdgcn_sched_group_barrier(0x02, {count}, 0);\n") * 2
    helper = "__device__ inline void sched_barrier_pairs_compute() {\n" + body + "}\n\n"
    source = once(source, "template<class T, int HALF_TILE_M, int M_REPEAT, int N_REPEAT, class MMA>",
                  helper + "template<class T, int HALF_TILE_M, int M_REPEAT, int N_REPEAT, class MMA>")
    start = source.index("    for (tile = 0; tile + 2 < loops; ++tile) {")
    end = source.index("    // Consume the final resident tile", start)
    return source[:start] + source[start:end].replace('sched_barrier_pairs_scale();', 'sched_barrier_pairs_compute();') + source[end:]


def canonical_strides(source, full):
    # These identities are already required by both public launch paths;
    # retain the 96-byte ABI and all supported shapes.
    replacements = {'stride_a': 'kargs.k', 'stride_b': 'kargs.k'}
    if full:
        replacements.update(stride_c='kargs.n', stride_sfa='kargs.m',
                            stride_sfb='(kargs.k / T::B_K)',
                            stride_a_batch='(kargs.m * kargs.k)',
                            stride_b_batch='(kargs.n * kargs.k)',
                            stride_c_batch='(kargs.m * kargs.n)',
                            stride_sfa_batch='(kargs.m * (kargs.k / T::B_K))',
                            stride_sfb_batch='((kargs.n / T::GROUP_N) * (kargs.k / T::B_K))')
    for field, value in replacements.items():
        source = re.sub(r'\bkargs\.' + field + r'\b', value, source)
    return source


def initial_matrix_roles(source, early):
    first = """    async_load<T::VEC_A>(g_a, s_a.ptr, u_ga, u_sa + sa_offset(0, 0), ga_offset(0, 0));
    async_load<T::VEC_A>(g_a, s_a.ptr, u_ga, u_sa + sa_offset(0, 1), ga_offset(1, 0));
"""
    last = """    async_load<T::VEC_B>(g_b, s_b.ptr, u_gb, u_sb + sb_offset(0, 0), gb_offset(0, 0));
    async_load<T::VEC_B>(g_b, s_b.ptr, u_gb, u_sb + sb_offset(0, 1), gb_offset(1, 0));
"""

    def requests(begin, count):
        return f"""    // K0 uses the same complete A/B producer partition as later K blocks.
    opus::static_for<{count}>([&](auto initial_issue) {{
        using Issue = opus::number<decltype(initial_issue)::value + {begin}>;
        prefetch_matrix_issue(Issue{{}}, 0, 0);
    }});
"""

    source = once(source, first, requests(0, 16 if early else 8))
    return once(source, last, "" if early else requests(8, 8))


def preload_a0_m0(source, after=30):
    start = source.index("    for (tile = 0; tile + 2 < loops; ++tile) {")
    end = source.index("    // Consume the final resident tile", start)
    body = source[start:end]
    old = "        load_a_mrepeat_scale<T, 0>(s_a, ra0_next_offsets, v_a[0]);\n"
    assert body.count(old) == 2
    new = """        opus::set_slice(v_a[0], a0_m0_next_0, opus::number<0>{}, opus::number<16>{});
        opus::set_slice(v_a[0], a0_m0_next_1, opus::number<16>{}, opus::number<32>{});
"""
    body = body.replace(old, new)
    assert after in [26, 28, 30, 32]
    first_fragment = after - 18
    marker = f"""        MXFP8_MMA_PAIR(
            1, {first_fragment // 4}, {(first_fragment % 4) // 2}, v_a[1], v_b, c10_{first_fragment}, c10_{first_fragment + 1}, v_sfa, v_sfb[0]);
        sched_barrier_pairs_scale();
"""
    assert body.count(marker) == 2
    extra = """
        // Read next A0/M0 while its current-K operand is still live.
        // The temporary is installed only after the last MFMA36 consumer.
        const auto a0_m0_prefetch_offsets =
            opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 0));
        auto a0_m0_next_0 = s_a.template load<16>(a0_m0_prefetch_offsets[0]);
        auto a0_m0_next_1 = s_a.template load<16>(a0_m0_prefetch_offsets[1]);
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);
"""
    return source[:start] + body.replace(marker, marker + extra) + source[end:]


def preload_tail_operands(source, a1, b1):
    start = source.index("    for (tile = 0; tile + 2 < loops; ++tile) {")
    end = source.index("    // Consume the final resident tile", start)
    body = source[start:end]
    options = []
    if a1:
        options.append(("a1_m2", "ra1_next_offsets", "s_a", 4,
                        "1, 1, 0, v_a[1], v_b_n1, c11_4, c11_5, v_sfa, v_sfb[1]",
                        "load_a_mrepeat_scale<T, 2>(s_a, ra1_next_offsets, v_a[1]);", "v_a[1]", 64))
    if b1:
        options.append(("b1_n3", "rb1_next_offsets", "s_b", 6,
                        "1, 0, 0, v_a[1], v_b_n1, c11_0, c11_1, v_sfa, v_sfb[1]",
                        "load_b_range_scale<T, 6, 8>(s_b, rb1_next_offsets, v_b_second);", "v_b_second", 96))
    for name, offsets, memory, index, arguments, load, target, element in options:
        marker = f"        MXFP8_MMA_PAIR({arguments});\n        sched_barrier_pairs_scale();\n"
        assert body.count(marker) == 2, (name, body.count(marker))
        extra = f"""
        // Prefetch the final operand slices into separate registers; retain
        // the current values through their actual last MFMA consumer.
        auto {name}_next_0 = {memory}.template load<16>({offsets}[{index}]);
        auto {name}_next_1 = {memory}.template load<16>({offsets}[{index + 1}]);
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);
"""
        body = body.replace(marker, marker + extra)
        old = "        " + load + "\n"
        assert body.count(old) == 2
        new = f"""        opus::set_slice({target}, {name}_next_0, opus::number<{element}>{{}}, opus::number<{element + 16}>{{}});
        opus::set_slice({target}, {name}_next_1, opus::number<{element + 16}>{{}}, opus::number<{element + 32}>{{}});
"""
        body = body.replace(old, new)
    return source[:start] + body + source[end:]


def record(name, source, config):
    directory = WORK / name
    directory.mkdir(exist_ok=False)
    metadata = json.loads((BASE / "candidate.json").read_text())
    for filename in metadata["source_hashes"]:
        shutil.copy2(BASE / filename, directory / filename)
    (directory / "tmpl_generic.hpp").write_text(source)
    # Reuse only unchanged host objects; every candidate compiles and links
    # its own kernel, executable, shared library and ISA.
    (directory / "build").mkdir()
    for filename in ["host.o", "launch.o"]:
        shutil.copy2(WORK / "baseline/build" / filename, directory / "build" / filename)
    metadata.pop("expected_generic_isa", None)
    metadata.update(name=name, parent="baseline", parent_commit=metadata["parent"])
    metadata["config"].update(config)
    metadata["source_hashes"] = {f: hashlib.sha256((directory/f).read_bytes()).hexdigest()
                                 for f in metadata["source_hashes"]}
    (directory / "candidate.json").write_text(json.dumps(metadata, indent=2) + "\n")
    dest = HERE / "candidate_patches" / name
    dest.mkdir(parents=True, exist_ok=False)
    (dest / "candidate.json").write_text(json.dumps(metadata, indent=2) + "\n")
    original = (BASE / "tmpl_generic.hpp").read_text()
    patch = "".join(difflib.unified_diff(original.splitlines(True), source.splitlines(True),
                                         fromfile="a/tmpl_generic.hpp", tofile="b/tmpl_generic.hpp"))
    (dest / "change.patch").write_text(patch)
    print(name, metadata["source_hashes"]["tmpl_generic.hpp"], flush=True)


if __name__ == "__main__":
    source = (BASE / "tmpl_generic.hpp").read_text()
    for name in sys.argv[1:]:
        if name == "scale_packed6":
            record(name, distribute_scales(source, 6, 6, True),
                   dict(sfa_next_read_mfma=6, sfb_next_read_mfma=6, sfa_read_pair=True))
        elif name == "scale_split8_20":
            record(name, distribute_scales(source, 8, 20),
                   dict(sfa_next_read_mfma=8, sfb_next_read_mfma=20, sfa_read_pair=False))
        elif name == "sfb_allwave":
            record(name, allwave_sfb(source), dict(sfb_global_read="all_waves"))
        elif name == "sfb_allwave_packed6":
            record(name, distribute_scales(allwave_sfb(source), 6, 6, True),
                   dict(sfb_global_read="all_waves", sfa_next_read_mfma=6,
                        sfb_next_read_mfma=6, sfa_read_pair=True))
        elif name == "packed6_sfb_uniform":
            record(name, distribute_scales(uniform_initial_b(allwave_sfb(source)), 6, 6, True),
                   dict(sfb_global_read="all_waves", initial_b_scalar_offset="readfirstlane",
                        sfa_next_read_mfma=6, sfb_next_read_mfma=6, sfa_read_pair=True))
        elif name in ["packed6_zero_after_loads", "packed6_zero_read_after_loads"]:
            read_write = name == "packed6_zero_after_loads"
            record(name, early_accumulator_use(distribute_scales(source, 6, 6, True), read_write),
                   dict(sfa_next_read_mfma=6, sfb_next_read_mfma=6, sfa_read_pair=True,
                        accumulator_early_use="read_write" if read_write else "read_only"))
        elif name == "packed6_startup_combo":
            record(name, early_accumulator_use(distribute_scales(uniform_initial_b(allwave_sfb(source)), 6, 6, True), False),
                   dict(sfb_global_read="all_waves", initial_b_scalar_offset="readfirstlane",
                        sfa_next_read_mfma=6, sfb_next_read_mfma=6, sfa_read_pair=True,
                        accumulator_early_use="read_only"))
        elif name in ["packed6_copy_scalar", "packed6_copy_scalar_split"]:
            split = name.endswith("_split")
            parent = early_accumulator_use(distribute_scales(source, 6, 6, True), False)
            record(name, scalar_output_copy(parent, split),
                   dict(sfa_next_read_mfma=6, sfb_next_read_mfma=6, sfa_read_pair=True,
                        accumulator_early_use="read_only", output_copy_scalar_offset=True,
                        output_copy_split_lds_bases=split))
        elif name in ["packed6_schedule_salu", "packed6_schedule_salu_valu", "packed6_unsigned_index"]:
            parent = early_accumulator_use(distribute_scales(source, 6, 6, True), False)
            config = dict(sfa_next_read_mfma=6, sfb_next_read_mfma=6, sfa_read_pair=True,
                          accumulator_early_use="read_only")
            if name == "packed6_unsigned_index":
                record(name, unsigned_tile_indices(parent), dict(config, unsigned_tile_indices=True))
            else:
                mask = 4 if name == "packed6_schedule_salu" else 6
                record(name, relax_scalar_schedule(parent, mask), dict(config, compute_sched_barrier_mask=mask))
        elif name == "packed6_quarter_output":
            parent = early_accumulator_use(distribute_scales(source, 6, 6, True), False)
            record(name, quarter_output_copy(parent),
                   dict(sfa_next_read_mfma=6, sfb_next_read_mfma=6, sfa_read_pair=True,
                        accumulator_early_use="read_only", output_half_overlap=False,
                        output_quarter_publication_mfmas=[20, 36, 52, 64]))
        elif name in ["packed6_output_valu4", "packed6_output_valu6", "packed6_output_valu8"]:
            count = int(name[-1])
            parent = early_accumulator_use(distribute_scales(source, 6, 6, True), False)
            record(name, output_valu_ratio(parent, count),
                   dict(sfa_next_read_mfma=6, sfb_next_read_mfma=6, sfa_read_pair=True,
                        accumulator_early_use="read_only", output_valu_per_mfma=count))
        elif name in ["packed6_unroll4", "packed6_unroll16"]:
            count = int(name.split("unroll")[1])
            parent = early_accumulator_use(distribute_scales(source, 6, 6, True), False)
            record(name, once(parent, "#pragma unroll 8", f"#pragma unroll {count}"),
                   dict(sfa_next_read_mfma=6, sfb_next_read_mfma=6, sfa_read_pair=True,
                        accumulator_early_use="read_only", unroll=count))
        elif name in ["packed6_final_resident", "packed6_final_retire8"]:
            late = name.endswith("retire8")
            parent = early_accumulator_use(distribute_scales(source, 6, 6, True), False)
            record(name, final_resident_operands(parent, late),
                   dict(sfa_next_read_mfma=6, sfb_next_read_mfma=6, sfa_read_pair=True,
                        accumulator_early_use="read_only", final_operands="resident",
                        final_matrix_retire_mfma=8 if late else 0))
        elif name in ["packed6_unsigned_quarter", "packed6_unsigned_out6", "packed6_unsigned_quarter6"]:
            parent = unsigned_tile_indices(early_accumulator_use(distribute_scales(source, 6, 6, True), False))
            quarter = 'quarter' in name
            ratio6 = name.endswith('6')
            if quarter:
                parent = quarter_output_copy(parent)
            if ratio6:
                parent = output_valu_ratio(parent, 6, True)
            config = dict(sfa_next_read_mfma=6, sfb_next_read_mfma=6, sfa_read_pair=True,
                          accumulator_early_use="read_only", unsigned_tile_indices=True,
                          output_bf16_valu_per_mfma=6 if ratio6 else 2)
            if quarter:
                config.update(output_half_overlap=False, output_quarter_publication_mfmas=[20,36,52,64])
            record(name, parent, config)
        elif name in ["packed6_unsigned_rows32", "packed6_unsigned_rows64"]:
            rows = int(name.split('rows')[1])
            parent = unsigned_tile_indices(early_accumulator_use(distribute_scales(source, 6, 6, True), False))
            record(name, output_row_groups(parent, rows),
                   dict(sfa_next_read_mfma=6, sfb_next_read_mfma=6, sfa_read_pair=True,
                        accumulator_early_use="read_only", unsigned_tile_indices=True,
                        output_half_overlap=False, output_group_rows=rows))
        elif name in ["packed2_unsigned_quarter", "packed2_20_unsigned_quarter", "packed4_unsigned_quarter"]:
            a_after = 4 if name.startswith('packed4_') else 2
            b_after = 20 if name.startswith('packed2_20_') else a_after
            parent = quarter_output_copy(unsigned_tile_indices(early_accumulator_use(
                distribute_scales(source, a_after, b_after, True), False)))
            record(name, parent,
                   dict(sfa_next_read_mfma=a_after, sfb_next_read_mfma=b_after, sfa_read_pair=True,
                        accumulator_early_use="read_only", unsigned_tile_indices=True,
                        output_half_overlap=False, output_quarter_publication_mfmas=[20,36,52,64]))
        elif name in ["packed6_quarter_zero_sfa", "packed6_quarter_zero_split"]:
            split = name.endswith('split')
            parent = quarter_output_copy(unsigned_tile_indices(early_accumulator_use(distribute_scales(source, 6, 6, True), False)))
            record(name, move_zero_uses(parent, split),
                   dict(sfa_next_read_mfma=6, sfb_next_read_mfma=6, sfa_read_pair=True,
                        accumulator_early_use="split_sfa_b" if split else "after_sfa",
                        unsigned_tile_indices=True, output_half_overlap=False,
                        output_quarter_publication_mfmas=[20,36,52,64]))
        elif name in ["packed2_20_quarter_async36", "packed2_20_quarter_async_all"]:
            all_quarters = name.endswith('all')
            parent = quarter_output_copy(unsigned_tile_indices(early_accumulator_use(distribute_scales(source, 2, 20, True), False)))
            record(name, async_quarter_stores(parent, all_quarters),
                   dict(sfa_next_read_mfma=2, sfb_next_read_mfma=20, sfa_read_pair=True,
                        accumulator_early_use="read_only", unsigned_tile_indices=True,
                        output_half_overlap=False, output_quarter_publication_mfmas=[20,36,52,64],
                        final_barrier_vmem_drain=not all_quarters,
                        output_barriers_without_vmem_drain=[1,2,3,4] if all_quarters else [3]))
        elif name in ["packed2_12_unsigned_quarter", "packed2_28_unsigned_quarter", "packed2_20_quarter_zero_split"]:
            b_after = 12 if name.startswith('packed2_12_') else 28 if name.startswith('packed2_28_') else 20
            parent = quarter_output_copy(unsigned_tile_indices(early_accumulator_use(distribute_scales(source, 2, b_after, True), False)))
            split = name.endswith('zero_split')
            if split:
                parent = move_zero_uses(parent, True)
            record(name, parent,
                   dict(sfa_next_read_mfma=2, sfb_next_read_mfma=b_after, sfa_read_pair=True,
                        accumulator_early_use="split_sfa_b" if split else "read_only",
                        unsigned_tile_indices=True, output_half_overlap=False,
                        output_quarter_publication_mfmas=[20,36,52,64]))
        elif name in ["packed2_20_compute_valu1", "packed2_20_compute_valu4"]:
            count = int(name[-1])
            parent = quarter_output_copy(unsigned_tile_indices(early_accumulator_use(distribute_scales(source, 2, 20, True), False)))
            record(name, compute_valu_ratio(parent, count),
                   dict(sfa_next_read_mfma=2, sfb_next_read_mfma=20, sfa_read_pair=True,
                        accumulator_early_use="read_only", unsigned_tile_indices=True,
                        output_half_overlap=False, output_quarter_publication_mfmas=[20,36,52,64],
                        compute_valu_per_mfma=count))
        elif name in ["packed2_20_matrix_stride", "packed2_20_all_strides", "packed2_20_split_async36"]:
            parent = quarter_output_copy(unsigned_tile_indices(early_accumulator_use(distribute_scales(source, 2, 20, True), False)))
            config = dict(sfa_next_read_mfma=2, sfb_next_read_mfma=20, sfa_read_pair=True,
                          accumulator_early_use="read_only", unsigned_tile_indices=True,
                          output_half_overlap=False, output_quarter_publication_mfmas=[20,36,52,64])
            if name.endswith('async36'):
                parent = async_quarter_stores(move_zero_uses(parent, True), False)
                config.update(accumulator_early_use="split_sfa_b", output_barriers_without_vmem_drain=[3])
            else:
                full = name.endswith('all_strides')
                parent = canonical_strides(parent, full)
                config.update(canonical_stride_expressions="all" if full else "matrix")
            record(name, parent, config)
        elif name in ["split_async36_matrix_stride_uniform", "split_async36_all_strides_uniform"]:
            full = name == "split_async36_all_strides_uniform"
            parent = quarter_output_copy(unsigned_tile_indices(early_accumulator_use(
                distribute_scales(source, 2, 20, True), False)))
            parent = async_quarter_stores(move_zero_uses(parent, True), False)
            # Keep the initial B offset explicitly uniform before folding the
            # validated canonical strides. Otherwise LLVM inserts waterfalls
            # around the initial async buffer-to-LDS requests.
            parent = canonical_strides(uniform_initial_b(parent), full)
            record(name, parent,
                   dict(sfa_next_read_mfma=2, sfb_next_read_mfma=20, sfa_read_pair=True,
                        accumulator_early_use="split_sfa_b", unsigned_tile_indices=True,
                        output_half_overlap=False, output_quarter_publication_mfmas=[20,36,52,64],
                        output_barriers_without_vmem_drain=[3], initial_b_scalar_offset="readfirstlane",
                        canonical_stride_expressions="all" if full else "matrix"))
        elif name in ["split_async36_initial_roles", "split_async36_initial_roles_early",
                      "split_async36_initial_roles_strides", "split_async36_preload_a0_m0"]:
            parent = quarter_output_copy(unsigned_tile_indices(early_accumulator_use(
                distribute_scales(source, 2, 20, True), False)))
            parent = async_quarter_stores(move_zero_uses(parent, True), False)
            config = dict(sfa_next_read_mfma=2, sfb_next_read_mfma=20, sfa_read_pair=True,
                          accumulator_early_use="split_sfa_b", unsigned_tile_indices=True,
                          output_half_overlap=False, output_quarter_publication_mfmas=[20,36,52,64],
                          output_barriers_without_vmem_drain=[3])
            if name.endswith('preload_a0_m0'):
                parent = preload_a0_m0(parent)
                config.update(a0_m0_prefetch_mfma=30, a0_m0_install_mfma=36)
            else:
                early = name.endswith('early')
                parent = initial_matrix_roles(parent, early)
                config.update(initial_matrix_producer="main_roles", initial_matrix_split=not early)
                if name.endswith('strides'):
                    parent = canonical_strides(parent, True)
                    config.update(canonical_stride_expressions="all")
            record(name, parent, config)
        elif name in ["preload_a0_after26", "preload_a0_after28", "preload_a0_after32", "preload_a0_prio_clean"]:
            parent = quarter_output_copy(unsigned_tile_indices(early_accumulator_use(
                distribute_scales(source, 2, 20, True), False)))
            parent = async_quarter_stores(move_zero_uses(parent, True), False)
            after = 30 if name.endswith('prio_clean') else int(name.split('after')[1])
            parent = preload_a0_m0(parent, after)
            config = dict(sfa_next_read_mfma=2, sfb_next_read_mfma=20, sfa_read_pair=True,
                          accumulator_early_use="split_sfa_b", unsigned_tile_indices=True,
                          output_half_overlap=False, output_quarter_publication_mfmas=[20,36,52,64],
                          output_barriers_without_vmem_drain=[3], a0_m0_prefetch_mfma=after,
                          a0_m0_install_mfma=36)
            if name.endswith('prio_clean'):
                old = """        __builtin_amdgcn_s_setprio(1);

        // Continue C01 while next-tile operands roll into dead registers.
"""
                assert parent.count(old) == 2
                parent = parent.replace(old, "        // Continue C01 while next-tile operands roll into dead registers.\n")
                config.update(omit_redundant_mfma36_setprio=True)
            record(name, parent, config)
        elif name in ["preload_tail_a1_m2", "preload_tail_b1_n3", "preload_tail_both"]:
            parent = quarter_output_copy(unsigned_tile_indices(early_accumulator_use(
                distribute_scales(source, 2, 20, True), False)))
            parent = preload_a0_m0(async_quarter_stores(move_zero_uses(parent, True), False))
            old = """        __builtin_amdgcn_s_setprio(1);

        // Continue C01 while next-tile operands roll into dead registers.
"""
            assert parent.count(old) == 2
            parent = parent.replace(old, "        // Continue C01 while next-tile operands roll into dead registers.\n")
            a1 = name != "preload_tail_b1_n3"
            b1 = name != "preload_tail_a1_m2"
            parent = preload_tail_operands(parent, a1, b1)
            record(name, parent,
                   dict(sfa_next_read_mfma=2, sfb_next_read_mfma=20, sfa_read_pair=True,
                        accumulator_early_use="split_sfa_b", unsigned_tile_indices=True,
                        output_half_overlap=False, output_quarter_publication_mfmas=[20,36,52,64],
                        output_barriers_without_vmem_drain=[3], a0_m0_prefetch_mfma=30,
                        a0_m0_install_mfma=36, omit_redundant_mfma36_setprio=True,
                        a1_m2_prefetch_mfma=54 if a1 else None,
                        b1_n3_prefetch_mfma=50 if b1 else None))
        else:
            raise ValueError(name)
