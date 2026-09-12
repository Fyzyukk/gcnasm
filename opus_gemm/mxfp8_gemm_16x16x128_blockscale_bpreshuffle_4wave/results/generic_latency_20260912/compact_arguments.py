#!/usr/bin/env python3
"""Keep the public C ABI and compact the private device arguments for SGPR preload."""
import re
from make_candidates import BASE, record, replace_n

PARAMETERS = "const void* __restrict__ ptr_a, const void* __restrict__ ptr_b, void* __restrict__ ptr_c, const void* __restrict__ ptr_sfa, const void* __restrict__ ptr_sfb, int m, int n, int k"
TYPES = "const void*, const void*, void*, const void*, const void*, int, int, int"
FIELDS = ["ptr_a", "ptr_b", "ptr_c", "ptr_sfa", "ptr_sfb", "m", "n", "k"]


def transform(source):
    assert "kargs.batch" not in source
    source = replace_n(source, "void gemm_a8w8_mxfp8_scale_kernel(opus_gemm_scale_kargs kargs) {",
                        "void gemm_a8w8_mxfp8_scale_kernel(" + PARAMETERS + ") {")
    marker = "    using D_SF_PACK = unsigned int;\n"
    source = replace_n(source, marker, marker + """
    // The public launch validates contiguous batches and all canonical strides.
    // Derive those redundant strides from the three generic dimensions.
    const int scale_k = static_cast<unsigned int>(k) / T::B_K;
    const int stride_a_batch = m * k;
    const int stride_b_batch = n * k;
    const int stride_c_batch = m * n;
    const int stride_sfa_batch = m * scale_k;
    const int stride_sfb_batch = (n / T::GROUP_N) * scale_k;
""")
    substitutions = {f:f for f in FIELDS}
    substitutions.update(stride_a="k", stride_b="k", stride_c="n", stride_sfa="m", stride_sfb="scale_k")
    substitutions.update({f:f for f in ["stride_a_batch", "stride_b_batch", "stride_c_batch",
                                       "stride_sfa_batch", "stride_sfb_batch"]})
    source = re.sub(r"\bkargs\.(\w+)\b", lambda match: substitutions[match[1]], source)
    assert "kargs" not in source
    dispatch = (BASE / "kernel_dispatch.hpp").read_text()
    dispatch = replace_n(dispatch, "gemm_a8w8_mxfp8_scale_kernel(opus_gemm_scale_kargs);",
                         "gemm_a8w8_mxfp8_scale_kernel(" + TYPES + ");")
    dispatch = replace_n(dispatch, "<<<grid, block, 0, stream>>>(args);",
                         "<<<grid, block, 0, stream>>>(" + ", ".join("args." + f for f in FIELDS) + ");")
    kernel = (BASE / "gemm_a8w8_mxfp8_scale_kernel.cc").read_text()
    kernel = replace_n(kernel, "(opus_gemm_scale_kargs)", "(" + TYPES + ")", 3)
    return source, {"kernel_dispatch.hpp":dispatch, "gemm_a8w8_mxfp8_scale_kernel.cc":kernel}


if __name__ == "__main__":
    source, support = transform((BASE / "tmpl_generic.hpp").read_text())
    makefile = (BASE / "Makefile").read_text()
    for count in (0, 3, 8):
        changed = dict(support)
        if count:
            changed["Makefile"] = replace_n(makefile, "$(FLAGS) -D__HIPCC_RTC__",
                                              f"$(FLAGS) -mllvm -amdgpu-kernarg-preload-count={count} -D__HIPCC_RTC__")
        record(f"compact_args_preload{count}", source,
               dict(compact_device_arguments=FIELDS, public_c_abi_bytes=96,
                    public_strides_validated_and_derived=True, kernarg_preload_count=count), changed)
