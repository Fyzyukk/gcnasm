#!/usr/bin/env python3
"""Batch coalesced LDS reads so each copy waits behind more independent work."""
from experiment_utils import WORK, record_candidate

PARENT = "lds_release5_k1"
source = (WORK / PARENT / "tmpl.hpp").read_text()
start = source.index("        opus::static_for<T::B_M * T::B_N / (T::BLOCK_SIZE * 8)>")
end = source.index("        });", start) + len("        });")
for group in [4, 8, 16, 32]:
    copy = f"""        const int copy_row = thread_id_x() / (T::B_N / 8);
        const int copy_col = (thread_id_x() % (T::B_N / 8)) * 8;
        int copy_global_base = copy_row * kargs.stride_c + copy_col;
        int copy_lds_base = copy_row * c_lds_pitch + copy_col;
        asm volatile("" : "+v"(copy_global_base), "+v"(copy_lds_base));
        constexpr int copy_group = {group};
        opus::static_for<T::B_M * T::B_N / (T::BLOCK_SIZE * 8 * copy_group)>([&](auto group_i) {{
            opus::vector_t<D_C, 8> values[copy_group];
            opus::static_for<copy_group>([&](auto item_i) {{
                constexpr int item = decltype(item_i)::value;
                constexpr int copy_i = decltype(group_i)::value * copy_group + item;
                constexpr int row_delta = copy_i * T::BLOCK_SIZE * 8 / T::B_N;
                values[item] = s_c.template load<8>(copy_lds_base + row_delta * c_lds_pitch);
            }});
            __builtin_amdgcn_sched_barrier(0);
            opus::static_for<copy_group>([&](auto item_i) {{
                constexpr int item = decltype(item_i)::value;
                constexpr int copy_i = decltype(group_i)::value * copy_group + item;
                constexpr int row_delta = copy_i * T::BLOCK_SIZE * 8 / T::B_N;
                g_c.template store<8>(values[item], copy_global_base, row_delta * kargs.stride_c,
                                      opus::number<2>{{}});
            }});
            __builtin_amdgcn_sched_barrier(0);
        }});"""
    record_candidate(f"lds_copy_group{group}", source[:start] + copy + source[end:],
                     dict(copy_group=group, scalar_copy_offsets=True,
                          release_mfma=5, unified_initial_matrix_stages=[1],
                          bf16_lds_epilogue=True, bf16_store_aux=2, c_lds_pitch=264), PARENT)
