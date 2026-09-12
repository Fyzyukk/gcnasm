#!/usr/bin/env python3
"""Read the linked AMDHSA descriptors directly; no optional ELF package needed."""
import hashlib
import json
from pathlib import Path
import struct
import sys

HERE = Path(__file__).resolve().parent
WORK = Path((HERE / "work_path.txt").read_text().strip())


def descriptors(path):
    data = path.read_bytes()
    assert data[:6] == b"\x7fELF\x02\x01"
    shoff = struct.unpack_from("<Q", data, 40)[0]
    shsize, shnum = struct.unpack_from("<HH", data, 58)
    assert shsize == 64
    sections = [struct.unpack_from("<IIQQQQIIQQ", data, shoff+i*shsize) for i in range(shnum)]
    for section in sections:
        if section[1] != 2:
            continue
        strings = sections[section[6]]
        table = data[strings[4]:strings[4]+strings[5]]
        for offset in range(section[4], section[4]+section[5], section[9]):
            name, info, other, shndx, value, size = struct.unpack_from("<IBBHQQ", data, offset)
            name = table[name:table.index(b"\0", name)].decode()
            if not name.endswith(".kd"):
                continue
            storage = sections[shndx]
            descriptor = data[storage[4]+value-storage[3]:storage[4]+value-storage[3]+64]
            preload = struct.unpack_from("<H", descriptor, 58)[0]
            yield dict(kernel=name, kernarg_segment_bytes=struct.unpack_from("<I", descriptor, 8)[0],
                       preload_dwords=preload & 127, preload_offset_dwords=preload >> 7)


reports = []
for name in sys.argv[1:]:
    metadata = json.loads((WORK/name/"candidate.json").read_text())
    count = metadata["config"].get("kernarg_preload_count", 0)
    kernels = list(descriptors(WORK/name/"build/device.co"))
    assert len(kernels) == 2
    expected = {0:0, 3:6, 8:13}[count]
    for kernel in kernels:
        assert kernel["preload_dwords"] == expected and kernel["preload_offset_dwords"] == 0, kernel
    reports.append(dict(name=name,status="PASS",explicit_device_argument_bytes=52 if metadata["config"].get("compact_device_arguments") else 96,
                        public_c_abi_bytes=96,kernels=kernels,
                        code_object_sha256=hashlib.sha256((WORK/name/"build/device.co").read_bytes()).hexdigest()))
    print(name,"PASS",expected,"preloaded SGPR dwords")
(HERE/"kernarg_preload_descriptors.json").write_text(json.dumps(reports,indent=2)+"\n")
