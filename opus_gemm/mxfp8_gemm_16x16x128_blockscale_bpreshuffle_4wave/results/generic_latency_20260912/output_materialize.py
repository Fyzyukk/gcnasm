#!/usr/bin/env python3
"""Keep compiler-visible AGPR copies and BF16 conversions at output stages."""
import importlib.util
import json
from make_candidates import BASE, HERE, WORK, record, replace_n

spec = importlib.util.spec_from_file_location("issue_candidates", HERE.parent / "generic_issue_20260912/make_candidates.py")
previous = importlib.util.module_from_spec(spec)
spec.loader.exec_module(previous)


def transform(source, mode, stream):
    source = previous.output_lds_base(source)
    if stream:
        source = previous.output_fragment_stream(source, True)
    begin = source.index("#define MXFP8_STORE_FRAGMENT")
    end = source.index("// Store two native", begin)
    fragment = source[begin:end]
    old = "            s_c.template _store<T::VEC_C>(cast<D_C>(ACC),                        \\\n"
    body = ""
    value = "ACC"
    if mode == "both":
        body += "            auto fp32_fragment = ACC;                                         \\\n"
        body += '            asm volatile("" : "+v"(fp32_fragment));                           \\\n'
        value = "fp32_fragment"
    body += f"            auto packed_fragment = cast<D_C>({value});                       \\\n"
    body += '            asm volatile("" : "+v"(packed_fragment));                         \\\n'
    body += "            s_c.template _store<T::VEC_C>(packed_fragment,                     \\\n"
    fragment = replace_n(fragment, old, body)
    return source[:begin] + fragment + source[end:]


if __name__ == "__main__":
    for parent in ["baseline", "output_pingpong_136"]:
        directory = BASE if parent == "baseline" else WORK / parent
        source = (directory / "tmpl_generic.hpp").read_text()
        for mode, stream in [("packed", False), ("packed", True), ("both", True)]:
            suffix = "" if parent == "baseline" else "_out136"
            name = f"output_{'stream_' if stream else ''}{mode}_materialized{suffix}"
            config = json.loads((directory / "candidate.json").read_text())["config"]
            config.update(output_materialize=mode, output_lds_shared_byte_base=True)
            if stream:
                config.update(output_store_fragment_lag=4, output_fragment_schedule="strict_with_materialized_values")
            record(name, transform(source, mode, stream), config)
