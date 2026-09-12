#!/usr/bin/env python3
"""Reproduce generic issue-schedule candidates from the frozen 9229d1a source."""
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


def replace_n(source, old, new, count):
    assert source.count(old) == count, (old, source.count(old), count)
    return source.replace(old, new)


def publication(source, after):
    old = """        // MFMA5: publish t+1 and release stage t between independent MFMAs.
        __builtin_amdgcn_s_setprio(0);
        s_waitcnt_vmcnt(0_I);
        s_waitcnt_lgkmcnt(0_I);
        __builtin_amdgcn_s_barrier();
        __builtin_amdgcn_sched_barrier(0);
        __builtin_amdgcn_s_setprio(1);

"""
    source = replace_n(source, old, "", 2)
    barrier = old.replace("MFMA5:", f"MFMA{after}:")
    if after == 4:
        anchor = """        MXFP8_MMA_PAIR(0, 0, 1, v_a[0], v_b, c00_2, c00_3, v_sfa, v_sfb[0]);
        sched_barrier_pairs_scale();

"""
    elif after == 6:
        anchor = """        MXFP8_MMA_ONE(0, 1, 1, v_a[0], v_b, c00_5, v_sfa, v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

"""
    elif after == 7:
        pair = """        MXFP8_MMA_PAIR(0, 1, 1, v_a[0], v_b, c00_6, c00_7, v_sfa, v_sfb[0]);
        sched_barrier_pairs_scale();
"""
        first = """        MXFP8_MMA_ONE(0, 1, 2, v_a[0], v_b, c00_6, v_sfa, v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);

"""
        second = """        MXFP8_MMA_ONE(0, 1, 3, v_a[0], v_b, c00_7, v_sfa, v_sfb[0]);
        __builtin_amdgcn_sched_barrier(0);
"""
        source = replace_n(source, pair, first + second, 2)
        anchor = first
    else:
        raise ValueError(after)
    source = replace_n(source, anchor, anchor + barrier, 2)
    return source.replace("publication at MFMA5", f"publication at MFMA{after}").replace(
        "final block at MFMA5", f"final block at MFMA{after}")


def matrix_issues(source, sites):
    assert len(sites) == 16 and sites == sorted(sites)
    start = source.index("    for (tile = 0; tile + 2 < loops; ++tile) {")
    end = source.index("    // Penultimate runtime K128 block", start)
    body = source[start:end]
    pattern = re.compile(r"        MXFP8_MMA_(PAIR|ONE)\(\s*[^;]+\);\n"
                         r"        (?:sched_barrier_pairs_scale\(\)|__builtin_amdgcn_sched_barrier\(0\));\n")
    count = 0

    def split_pair(match):
        nonlocal count
        before = count
        count += 2 if match[1] == "PAIR" else 1
        if match[1] != "PAIR" or before + 1 not in sites:
            return match[0]
        arguments = [a.strip() for a in match[0].split("(", 1)[1].split(");", 1)[0].split(",")]
        assert len(arguments) == 9, arguments
        hm, mr, ng, va, vb, c0, c1, sa, sb = arguments
        return "".join(
            f"        MXFP8_MMA_ONE({hm}, {mr}, {2 * int(ng) + j}, {va}, {vb}, {c}, {sa}, {sb});\n"
            "        __builtin_amdgcn_sched_barrier(0);\n"
            for j, c in enumerate([c0, c1]))

    body = pattern.sub(split_pair, body)
    assert count == 64
    call = """        prefetch_matrix_issue(opus::number<ISSUE>{}, stage, future_tile);
        __builtin_amdgcn_sched_group_barrier(0x20, 1, 0);
        __builtin_amdgcn_sched_barrier(0);
"""
    # Preserve the order of scale and register prefetches at existing sites.
    # A marker at the original call position keeps this change limited to
    # the distribution of the sixteen matrix requests.
    original_sites = list(range(8, 39, 2))
    marker = lambda site: f"        // MATRIX_REQUEST_SITE_{site}\n"
    for issue, site in enumerate(original_sites):
        body = replace_n(body, call.replace("ISSUE", str(issue)), marker(site), 1)
    count = 0
    located = set(original_sites)

    def add_marker(match):
        nonlocal count
        count += 2 if match[1] == "PAIR" else 1
        if count in sites and count not in located:
            located.add(count)
            return match[0] + marker(count)
        return match[0]

    body = pattern.sub(add_marker, body)
    assert count == 64 and set(sites) <= located, (count, sites, located)
    for site in located:
        requests = "".join(call.replace("ISSUE", str(i)) for i, s in enumerate(sites) if s == site)
        body = replace_n(body, marker(site), requests, 1)
    body = body.replace("behind each pair through MFMA38.",
                        f"at the recorded issue sites through MFMA{max(sites)}.")
    return source[:start] + body + source[end:]


def single_m0_per_group(source):
    # Cached VOFFSET and IOFFSET add in the vector address path. Negative
    # VOFFSET values also occur in the baseline for small K; the sum is the
    # original nonnegative matrix coordinate. SOFFSET remains nonnegative.
    source = replace_n(source,
        "constexpr int immediate = local * matrix_pitch - (local ? 32 : 0);",
        "constexpr int immediate = local * matrix_pitch;", 2)
    return replace_n(source,
        "+ (issue / 4) * 4 * matrix_pitch + (local ? 32 : 0);",
        "+ (issue / 4) * 4 * matrix_pitch;", 1)


def output_lds_base(source):
    anchor = "    const auto gc_offsets = opus::layout_to_offsets<T::VEC_C>(u_gc);\n"
    source = replace_n(source, anchor, anchor + """    int output_lds_byte_base = 0;
    if constexpr (T::OUTPUT_BF16) {
        // The lane coordinate is shared by every native C fragment.
        // Keep its byte base intact so constant fragment offsets fold into DS.
        output_lds_byte_base = gc_offsets[0] * sizeof(D_C);
        asm volatile("" : "+v"(output_lds_byte_base));
    }
""", 1)
    old = """            s_c.template store<T::VEC_C>(cast<D_C>(ACC),                         \\
                gc_offsets[INDEX] + soff);                                      \\
"""
    new = """            s_c.template _store<T::VEC_C>(cast<D_C>(ACC),                        \\
                output_lds_byte_base + sizeof(D_C) * (soff                      \\
                    + (INDEX) / T::E_N * T::W_M * T::T_M * c_lds_pitch           \\
                    + (INDEX) % T::E_N * T::W_N * T::T_N));                      \\
"""
    return replace_n(source, old, new, 1)


def output_valu_ratio(source, count):
    prefix, tail = source.split("    // Consume the final resident tile", 1)
    helper = "__device__ inline void sched_barrier_pairs_output() {\n" + (
        "    __builtin_amdgcn_sched_group_barrier(0x08, 1, 0);\n"
        f"    __builtin_amdgcn_sched_group_barrier(0x02, {count}, 0);\n") * 2 + "}\n\n"
    anchor = "template<class T, int HALF_TILE_M, int M_REPEAT, int N_REPEAT, class MMA>"
    prefix = replace_n(prefix, anchor, helper + anchor, 1)
    tail = tail.replace("sched_barrier_pairs_scale();",
        "if constexpr (T::OUTPUT_BF16) sched_barrier_pairs_output();\n    else sched_barrier_pairs_scale();")
    return prefix + "    // Consume the final resident tile" + tail


def output_write_groups(source):
    old = "        MXFP8_STORE_FRAGMENT(ACC1, (INDEX) + 1); \\\n"
    new = old + "        if constexpr (T::OUTPUT_BF16) __builtin_amdgcn_sched_group_barrier(0x200, 2, 0); \\\n"
    return replace_n(source, old, new, 1)


def main_priority(source, all_high):
    start = source.index("#pragma unroll 8\n    for (tile = 0;")
    end = source.index("    // Penultimate runtime K128 block", start)
    body = source[start:end]
    high = "        __builtin_amdgcn_s_setprio(1);\n"
    low = "        __builtin_amdgcn_s_setprio(0);\n"
    if all_high:
        body = replace_n(body, high, "", 3)
        body = replace_n(body, low, "", 2)
    else:
        body = body.replace(high, "", 1)
        last = body.rindex(low)
        body = body[:last] + body[last:].replace(low, "", 1)
    source = source[:start] + "    __builtin_amdgcn_s_setprio(1);\n" + body + source[end:]
    anchor = """        if ((next_tile & panel_mask) == 0) {
            // Current scales are resident in registers."""
    source = replace_n(source, anchor, """        if ((next_tile & panel_mask) == 0) {
            __builtin_amdgcn_s_setprio(0);
            // Current scales are resident in registers.""", 1)
    anchor = """            __builtin_amdgcn_s_barrier();
            __builtin_amdgcn_sched_barrier(0);
        }
    };

    async_load<T::VEC_A>"""
    return replace_n(source, anchor, """            __builtin_amdgcn_s_barrier();
            __builtin_amdgcn_sched_barrier(0);
            __builtin_amdgcn_s_setprio(1);
        }
    };

    async_load<T::VEC_A>""", 1)


def wave_private_output(source):
    old = """    auto c_offset = [&](int half_tile_m, int half_tile_n) {
        return half_tile_m * T::HALF_B_M * (T::OUTPUT_BF16 ? c_lds_pitch : kargs.stride_c) +
               half_tile_n * T::HALF_B_N;
    };
"""
    new = """    // Each wave stages its own compact 128x128 C image, with four padding
    // elements per row. All four images reuse exactly the retired matrix LDS.
    constexpr int output_wave_pitch = T::HALF_B_N + 4;
    static_assert(!T::OUTPUT_BF16 || T::NUM_WAVES * T::HALF_B_M
                  * output_wave_pitch * sizeof(D_C) == matrix_lds_bytes);
    auto c_offset = [&](int half_tile_m, int half_tile_n) {
        return half_tile_m * (T::OUTPUT_BF16 ? T::HALF_B_M / 2 * output_wave_pitch
                                           : T::HALF_B_M * kargs.stride_c)
             + half_tile_n * (T::OUTPUT_BF16 ? T::HALF_B_N / 2 : T::HALF_B_N);
    };
"""
    source = replace_n(source, old, new, 1)
    begin = source.index("    auto copy_output_quarter =")
    end = source.index("    const auto gc_offsets", begin)
    source = source[:begin] + """    auto copy_output_quarter = [&](int half_m, int half_n, int copy_index) {
        const int linear = lane_id * 8 + copy_index * T::WARP_SIZE * 8;
        const int local_row = linear / (T::HALF_B_N / 2) + half_m * (T::HALF_B_M / 2);
        const int local_col = linear % (T::HALF_B_N / 2) + half_n * (T::HALF_B_N / 2);
        const int lds_offset = wave_id * T::HALF_B_M * output_wave_pitch
            + local_row * output_wave_pitch + local_col;
        const int output_row = local_row / T::W_M * T::W_M * T::T_M
            + wave_id_m * T::W_M + local_row % T::W_M;
        const int output_col = local_col / T::W_N * T::W_N * T::T_N
            + wave_id_n * T::W_N + local_col % T::W_N;
        const auto value = s_c.template load<8>(lds_offset);
        g_c.template store<8>(value, output_row * kargs.stride_c + output_col,
                             0, opus::number<2>{});
    };

""" + source[end:]
    anchor = "    const auto gc_offsets = opus::layout_to_offsets<T::VEC_C>(u_gc);\n"
    source = replace_n(source, anchor, anchor + """    int output_lds_byte_base = 0;
    if constexpr (T::OUTPUT_BF16) {
        output_lds_byte_base = (wave_id * T::HALF_B_M * output_wave_pitch
            + (lane_id % T::W_M) * output_wave_pitch + (lane_id / T::W_M) * 4) * sizeof(D_C);
        asm volatile("" : "+v"(output_lds_byte_base));
    }
""", 1)
    old = """            s_c.template store<T::VEC_C>(cast<D_C>(ACC),                         \\
                gc_offsets[INDEX] + soff);                                      \\
"""
    new = """            s_c.template _store<T::VEC_C>(cast<D_C>(ACC),                        \\
                output_lds_byte_base + sizeof(D_C) * (soff                      \\
                    + (INDEX) / T::E_N * T::W_M * output_wave_pitch              \\
                    + (INDEX) % T::E_N * T::W_N));                              \\
"""
    source = replace_n(source, old, new, 1)
    prefix, tail = source.split("    // Publish each completed 128x128 quadrant", 1)
    tail = replace_n(tail, "        __builtin_amdgcn_s_barrier();\n", "", 4)
    tail = replace_n(tail, "        s_waitcnt_vmcnt(0_I);\n", "", 3)
    tail = tail.replace("// Publish only the completed output quadrant before copying it.",
        "// This wave reads only its own completed LDS writes; LGKM still retires them.")
    return prefix + "    // Publish each completed 128x128 quadrant" + tail


def wave_output_read64(source):
    old = "        const auto value = s_c.template load<8>(lds_offset);\n"
    new = """        opus::vector_t<D_C, 8> value;
        opus::set_slice(value, s_c.template load<4>(lds_offset), opus::number<0>{}, opus::number<4>{});
        opus::set_slice(value, s_c.template load<4>(lds_offset + 4), opus::number<4>{}, opus::number<8>{});
"""
    return replace_n(source, old, new, 1)


def wave_output_xor(source):
    source = replace_n(source, "constexpr int output_wave_pitch = T::HALF_B_N + 4;",
                       "constexpr int output_wave_pitch = T::HALF_B_N;", 1)
    source = replace_n(source,
        "* output_wave_pitch * sizeof(D_C) == matrix_lds_bytes);",
        "* output_wave_pitch * sizeof(D_C) <= matrix_lds_bytes);", 1)
    source = replace_n(source,
        "+ local_row * output_wave_pitch + local_col;",
        "+ local_row * output_wave_pitch + (local_col ^ ((local_row & 7) * 8));", 1)
    old = """    int output_lds_byte_base = 0;
    if constexpr (T::OUTPUT_BF16) {
        output_lds_byte_base = (wave_id * T::HALF_B_M * output_wave_pitch
            + (lane_id % T::W_M) * output_wave_pitch + (lane_id / T::W_M) * 4) * sizeof(D_C);
        asm volatile("" : "+v"(output_lds_byte_base));
    }
"""
    new = """    int output_lds_byte_base = 0;
    int output_lds_lane_col = 0;
    if constexpr (T::OUTPUT_BF16) {
        output_lds_byte_base = (wave_id * T::HALF_B_M * output_wave_pitch
            + (lane_id % T::W_M) * output_wave_pitch) * sizeof(D_C);
        output_lds_lane_col = ((lane_id / T::W_M) * 4) ^ ((lane_id & 7) * 8);
        asm volatile("" : "+v"(output_lds_byte_base), "+v"(output_lds_lane_col));
    }
"""
    source = replace_n(source, old, new, 1)
    old = "                    + (INDEX) % T::E_N * T::W_N));                              \\\n"
    new = "                    + (output_lds_lane_col ^ ((INDEX) % T::E_N * T::W_N))));    \\\n"
    return replace_n(source, old, new, 1)


def packed_accumulator_output(source):
    helper = """template<class Acc>
__device__ inline auto pack_bf16_fragment(const Acc& acc) {
    unsigned int low, high, temporary0, temporary1;
    asm volatile(
        "v_accvgpr_read_b32 %0, %4\\n"
        "v_accvgpr_read_b32 %2, %5\\n"
        "v_accvgpr_read_b32 %1, %6\\n"
        "v_accvgpr_read_b32 %3, %7\\n"
        "v_cvt_pk_bf16_f32 %0, %0, %2\\n"
        "v_cvt_pk_bf16_f32 %1, %1, %3\\n"
        : "=&v"(low), "=&v"(high), "=&v"(temporary0), "=&v"(temporary1)
        : "a"(acc[0]), "a"(acc[1]), "a"(acc[2]), "a"(acc[3]));
    const opus::vector_t<unsigned int, 2> packed{low, high};
    return __builtin_bit_cast(opus::vector_t<opus::bf16_t, 4>, packed);
}

"""
    anchor = "template<class T, int HALF_TILE_M, int M_REPEAT, int N_REPEAT, class MMA>"
    source = replace_n(source, anchor, helper + anchor, 1)
    return replace_n(source, "cast<D_C>(ACC)", "pack_bf16_fragment(ACC)", 1)


def output_fragment_stream(source, strict):
    begin = source.index("    // Consume the final resident tile")
    begin = source.index("    MXFP8_MMA_PAIR(0, 0, 0,",begin)
    end = source.index("#undef MXFP8_STORE_QUADRANT",begin)
    legacy = source[begin:end]
    quads = [(0,0),(1,0),(0,1),(1,1)]
    lines = ["    if constexpr (T::OUTPUT_BF16) {",
             "        // One completed native fragment follows each MFMA, four MFMAs",
             "        // behind its producer. LLVM sees every AGPR read and conversion."]

    def emit_store(index):
        hm, hn = quads[index//16]
        fragment = index % 16
        lines.extend(["        {",f"            const int soff = c_offset({hm}, {hn});",
                      f"            MXFP8_STORE_FRAGMENT(c{hm}{hn}_{fragment}, {fragment});",
                      "        }"])
        if strict:
            lines.append("        __builtin_amdgcn_sched_barrier(0);")
        else:
            lines.extend(["        __builtin_amdgcn_sched_group_barrier(0x02, 6, 0);",
                          "        __builtin_amdgcn_sched_group_barrier(0x200, 1, 0);"])

    def publish(quad):
        hm, hn = quads[quad]
        lines.append("        __builtin_amdgcn_sched_barrier(0);")
        if quad != 1:
            lines.append("        s_waitcnt_vmcnt(0_I);")
        lines.extend(["        s_waitcnt_lgkmcnt(0_I);",
                      "        __builtin_amdgcn_s_barrier();",
                      "        __builtin_amdgcn_sched_barrier(0);"])
        lines.extend(f"        copy_output_quarter({hm}, {hn}, {i});" for i in range(8))

    for index in range(64):
        hm, hn = quads[index//16]
        f = index % 16
        if index == 32:
            lines.extend(["        v_b = v_b_second;","        __builtin_amdgcn_sched_barrier(0);"])
        lines.append(f"        MXFP8_MMA_ONE({hm}, {f//4}, {f%4}, v_a[{hm}], v_b, c{hm}{hn}_{f}, v_sfa, v_sfb[{hn}]);")
        lines.append("        __builtin_amdgcn_sched_barrier(0);" if strict else
                     "        __builtin_amdgcn_sched_group_barrier(0x08, 1, 0);")
        if index >= 4:
            emit_store(index-4)
        if index + 1 in [20,36,52]:
            publish((index+1-20)//16)
    for index in range(60,64):
        emit_store(index)
    lines.append("        __builtin_amdgcn_s_setprio(0);")
    publish(3)
    lines.append("    } else {")
    lines.extend("    " + line for line in legacy.splitlines())
    lines.append("    }\n")
    return source[:begin] + "\n".join(lines) + source[end:]


def grid_2d(source):
    old = """    const unsigned int wgid = block_id_x();
    // Both launch paths require positive N divisible by B_N.
    const unsigned int num_tiles_n = static_cast<unsigned int>(kargs.n) / T::B_N;
    const int block_m = wgid / num_tiles_n;
    const int block_n = wgid % num_tiles_n;
"""
    source = replace_n(source, old, """    // N varies along grid X and M along grid Y. The public byte-count
    // bound limits either tile dimension to less than 16384.
    const int block_m = block_id_y();
    const int block_n = block_id_x();
""", 1)
    launch = (BASE/"gemm_a8w8_blockscale_bpreshuffle_launch.cc").read_text()
    launch = replace_n(launch,
        "const dim3 grid((args.m / 256) * (args.n / 256), 1, args.batch);",
        "const dim3 grid(args.n / T::B_N, args.m / T::B_M, args.batch);", 1)
    host = (BASE/"gemm_a8w8_mxfp8_scale_host.cc").read_text()
    host = replace_n(host, """    const int grid_x = checked_count("Grid X", ceil_div_scale(m_tiles, output_tiles), n_tiles);
    const dim3 grid(grid_x, 1, batch);
""", """    const dim3 grid(n_tiles, ceil_div_scale(m_tiles, output_tiles), batch);
""", 1)
    return source, {"gemm_a8w8_blockscale_bpreshuffle_launch.cc":launch,
                    "gemm_a8w8_mxfp8_scale_host.cc":host}


def short_operand_prefetch(source, kind):
    start = source.index("    for (tile = 0; tile + 2 < loops; ++tile)")
    end = source.index("    // Consume the final resident tile", start)
    body = source[start:end]
    if kind.startswith("b1_"):
        after = int(kind.split("_")[1])
        first = 2 if after == 60 else 4
        marker = f"""        load_b_range_scale<T, {first}, {first+2}>(s_b, rb1_next_offsets, v_b_second);
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);
"""
        extra = """
        // Prefetch the last B1 slice close to its final current-K consumers.
        auto b1_n3_next_0 = s_b.template load<16>(rb1_next_offsets[6]);
        auto b1_n3_next_1 = s_b.template load<16>(rb1_next_offsets[7]);
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);
"""
        body = replace_n(body,marker,marker+extra,2)
        body = replace_n(body,
            "        load_b_range_scale<T, 6, 8>(s_b, rb1_next_offsets, v_b_second);\n",
            """        opus::set_slice(v_b_second, b1_n3_next_0, opus::number<96>{}, opus::number<112>{});
        opus::set_slice(v_b_second, b1_n3_next_1, opus::number<112>{}, opus::number<128>{});
""",2)
    elif kind == "a0_m1_34":
        marker = """        load_b_range_scale<T, 2, 4>(s_b, rb0_next_offsets, v_b);
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);
"""
        extra = """
        // Keep current A0/M1 live until MFMA40 while reading its successor.
        const auto a0_m1_prefetch_offsets =
            opus::layout_to_offsets<T::VEC_A>(u_ra + sa_offset(next_stage, 0));
        auto a0_m1_next_0 = s_a.template load<16>(a0_m1_prefetch_offsets[2]);
        auto a0_m1_next_1 = s_a.template load<16>(a0_m1_prefetch_offsets[3]);
        __builtin_amdgcn_sched_group_barrier(0x100, 2, 0);
        __builtin_amdgcn_sched_barrier(0);
"""
        body = replace_n(body,marker,marker+extra,2)
        body = replace_n(body,
            "        load_a_mrepeat_scale<T, 1>(s_a, ra0_next_offsets, v_a[0]);\n",
            """        opus::set_slice(v_a[0], a0_m1_next_0, opus::number<32>{}, opus::number<48>{});
        opus::set_slice(v_a[0], a0_m1_next_1, opus::number<48>{}, opus::number<64>{});
""",2)
    else:
        raise ValueError(kind)
    return source[:start]+body+source[end:]


def record(name, source, config, support_changes=None):
    directory = WORK / name
    directory.mkdir(exist_ok=False)
    metadata = json.loads((BASE / "candidate.json").read_text())
    for filename in metadata["source_hashes"]:
        shutil.copy2(BASE / filename, directory / filename)
    (directory / "tmpl_generic.hpp").write_text(source)
    for filename, contents in (support_changes or {}).items():
        (directory / filename).write_text(contents)
    (directory / "build").mkdir()
    for filename in ["host.o", "launch.o"]:
        shutil.copy2(WORK / "baseline/build" / filename, directory / "build" / filename)
    metadata.pop("expected_generic_isa", None)
    metadata.update(name=name, parent="baseline", parent_commit=metadata["parent"])
    metadata["config"].update(config)
    if support_changes:
        metadata["changed_support_files"] = sorted(support_changes)
    metadata["source_hashes"] = {f: hashlib.sha256((directory/f).read_bytes()).hexdigest()
                                 for f in metadata["source_hashes"]}
    (directory / "candidate.json").write_text(json.dumps(metadata, indent=2) + "\n")
    dest = HERE / "candidate_patches" / name
    dest.mkdir(parents=True, exist_ok=False)
    (dest / "candidate.json").write_text(json.dumps(metadata, indent=2) + "\n")
    patch = ""
    for filename in ["tmpl_generic.hpp", *sorted(support_changes or {})]:
        original = (BASE / filename).read_text()
        final = (directory / filename).read_text()
        patch += "".join(difflib.unified_diff(original.splitlines(True), final.splitlines(True),
                                             fromfile="a/"+filename, tofile="b/"+filename))
    (dest / "change.patch").write_text(patch)
    print(name, metadata["source_hashes"]["tmpl_generic.hpp"], flush=True)


if __name__ == "__main__":
    source = (BASE / "tmpl_generic.hpp").read_text()
    for name in sys.argv[1:]:
        if name in ["release4", "release6", "release7"]:
            after = int(name[len("release"):])
            record(name, publication(source, after), dict(release_mfma=after,
                   matrix_issue_mfmas=list(range(8, 39, 2)), original_singles_retained=True))
        elif name in ["issue6_36", "issue7_37", "issue9_39"]:
            first, last = map(int, name.removeprefix("issue").split("_"))
            sites = list(range(first, last + 1, 2))
            record(name, matrix_issues(source, sites), dict(matrix_issue_mfmas=sites))
        elif name == "m0_group4":
            record(name, single_m0_per_group(source), dict(
                matrix_group_immediates=[0,1056,2112,3168],
                matrix_group_m0_adjustments=[0,0,0,0], matrix_scalar_k_offset_unchanged=True))
        elif name == "m0_issue7":
            sites = list(range(7,38,2))
            record(name, matrix_issues(single_m0_per_group(source), sites), dict(
                matrix_group_immediates=[0,1056,2112,3168],
                matrix_group_m0_adjustments=[0,0,0,0], matrix_issue_mfmas=sites))
        elif name in ["out_lds_base", "out_lds_base_valu6", "out_lds_base_write_groups"]:
            candidate = output_lds_base(source)
            config = dict(output_lds_shared_byte_base=True)
            if name.endswith("valu6"):
                candidate = output_valu_ratio(candidate, 6)
                config.update(output_bf16_valu_per_mfma=6)
            if name.endswith("write_groups"):
                candidate = output_write_groups(candidate)
                config.update(output_bf16_write_group_size=2)
            record(name, candidate, config)
        elif name in ["main_keep_prio", "main_allprio1"]:
            all_high = name.endswith("allprio1")
            record(name, main_priority(source, all_high), dict(
                maintain_priority_between_main_tiles=True, release_priority=1 if all_high else 0,
                scale_refill_priority=0))
        elif name in ["compute_tuned", "compute_tuned_release4", "compute_tuned_outbase6"]:
            candidate = publication(source,4) if name.endswith("release4") else source
            sites = list(range(7,38,2))
            candidate = main_priority(matrix_issues(single_m0_per_group(candidate),sites),True)
            config = dict(matrix_group_immediates=[0,1056,2112,3168],
                          matrix_group_m0_adjustments=[0,0,0,0],matrix_issue_mfmas=sites,
                          maintain_priority_between_main_tiles=True,release_priority=1,
                          release_mfma=4 if name.endswith("release4") else 5,scale_refill_priority=0)
            if name.endswith("outbase6"):
                candidate = output_valu_ratio(output_lds_base(candidate),6)
                config.update(output_lds_shared_byte_base=True,output_bf16_valu_per_mfma=6)
            record(name,candidate,config)
        elif name in ["out_packed_asm", "out_packed_asm_base"]:
            candidate = output_lds_base(source) if name.endswith("base") else source
            record(name,packed_accumulator_output(candidate),dict(
                output_pack="inline_AGPR_read_then_native_bf16_RNE",
                output_lds_shared_byte_base=name.endswith("base")))
        elif name in ["out_fragment_stream", "out_fragment_stream_base", "out_fragment_group_base"]:
            base = name.endswith("base")
            strict = "group" not in name
            candidate = output_lds_base(source) if base else source
            record(name,output_fragment_stream(candidate,strict),dict(
                output_lds_shared_byte_base=base,output_store_fragment_lag=4,
                output_fragment_schedule="strict" if strict else "MFMA_VALU6_DSWRITE1"))
        elif name in ["grid2d", "compute_tuned_grid2d"]:
            candidate = source
            config = dict(grid_order="2d_N_then_M",unsigned_tile_indices=False)
            if name.startswith("compute_tuned"):
                sites = list(range(7,38,2))
                candidate = main_priority(matrix_issues(single_m0_per_group(candidate),sites),True)
                config.update(matrix_group_immediates=[0,1056,2112,3168],
                    matrix_group_m0_adjustments=[0,0,0,0],matrix_issue_mfmas=sites,
                    maintain_priority_between_main_tiles=True,release_priority=1,scale_refill_priority=0)
            candidate, support = grid_2d(candidate)
            record(name,candidate,config,support)
        elif name in ["compute_b1_60", "compute_b1_62", "compute_a0_m1_34"]:
            sites = list(range(7,38,2))
            candidate = main_priority(matrix_issues(single_m0_per_group(source),sites),True)
            kind = name.removeprefix("compute_")
            candidate = short_operand_prefetch(candidate,kind)
            record(name,candidate,dict(matrix_group_immediates=[0,1056,2112,3168],
                matrix_group_m0_adjustments=[0,0,0,0],matrix_issue_mfmas=sites,
                maintain_priority_between_main_tiles=True,release_priority=1,scale_refill_priority=0,
                short_operand_prefetch=kind))
        elif name in ["grid2d_unroll4", "grid2d_unroll16"]:
            count = int(name.split("unroll")[1])
            sites = list(range(7,38,2))
            candidate = main_priority(matrix_issues(single_m0_per_group(source),sites),True)
            candidate,support = grid_2d(candidate)
            candidate = replace_n(candidate,"#pragma unroll 8",f"#pragma unroll {count}",1)
            record(name,candidate,dict(grid_order="2d_N_then_M",unsigned_tile_indices=False,unroll=count,
                matrix_group_immediates=[0,1056,2112,3168],matrix_group_m0_adjustments=[0,0,0,0],
                matrix_issue_mfmas=sites,maintain_priority_between_main_tiles=True,
                release_priority=1,scale_refill_priority=0),support)
        elif name in ["out_wave_private", "out_wave_private_valu6", "out_wave_read64",
                      "out_wave_read64_valu6", "out_wave_xor", "out_wave_xor_valu6"]:
            candidate = wave_private_output(source)
            config = dict(output_lds_scope="wave_private", output_lds_shared_byte_base=True,
                          output_wave_pitch=132, output_quarter_barriers=0,
                          output_barriers_without_vmem_drain=[])
            if "read64" in name:
                candidate = wave_output_read64(candidate)
                config.update(output_lds_read_alignment=8)
            if "xor" in name:
                candidate = wave_output_xor(candidate)
                config.update(output_wave_pitch=128, output_lds_read_alignment=16,
                              output_column_xor="(local_row & 7) * 8")
            if name.endswith("valu6"):
                candidate = output_valu_ratio(candidate, 6)
                config.update(output_bf16_valu_per_mfma=6)
            record(name, candidate, config)
        else:
            raise ValueError(name)
