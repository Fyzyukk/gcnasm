# DVFS / cross-machine measurement kit

Built to settle "why is MI350X 2.65 P and MI355X only 2.30 P". The short answer
so far: **most of the reported gap is measurement protocol, not hardware.**

## Three confounds this kit exists to remove

1. **Co-tenant contention.** This box is shared; other containers hold ~214 GB
   on every GPU. A co-tenant drags SCLK to ~1570 MHz and gfx_activity to 52-72%,
   which looks exactly like power throttling. `guard.py` refuses to benchmark a
   dirty GPU. **This is almost certainly the origin of the "1483 MHz" reading.**
2. **Idle samples in the telemetry average.** Reading amd-smi without filtering
   on `gfx_activity` mixes 157 MHz idle samples into the mean. `sample.py` keeps
   only busy samples (>=50% activity) and drops the first 30%.
3. **Short vs long protocol.** 200 warmup + 100 iters captures transient boost.
   The logged MI350X 2.65 P is a short test; the same machine at 1000+1000 gave
   2.245 P (log sec. 24). Never compare a short number to a long one.

## Files

| file | purpose |
|---|---|
| `guard.py` | pre-flight: is the GPU free of other processes? exit 1 if not |
| `sample.py` | run a workload, report busy-only SCLK / power / temp / PPT |
| `series.py` | same, as a time series -- shows decay vs stable clock |
| `mfma_peak.cc` | pure `v_mfma_scale_f32_16x16x128_f8f6f4`, no LDS/global. Denominator |
| `measure.sh` | **the portable protocol -- run this on each machine** |
| `eff_calc.py` | compute clock-normalized `eff` from the numbers `measure.sh` prints |
| `cap_sweep.sh` | power-cap sweep, proves power-limit causality |
| `eff.sh` | local locked-clock vs auto comparison |

## Running on the MI350X box

```sh
# 1. build (note: the Makefile's default OPUS_INCLUDE_DIR does not exist here;
#    point it at wherever aiter/csrc/include actually lives on that machine)
cd <repo>/opus_gemm/mxfp8_gemm_16x16x128_scale
make scale_fixed_b_asym_b_read2 -j OPUS_INCLUDE_DIR=/root/workspace/aiter/csrc/include

# 2. build the MFMA denominator probe
cd variants/dvfs_study
/opt/rocm/bin/hipcc mfma_peak.cc -o mfma_peak --offload-arch=gfx950 -O3 -std=c++17
#   (MI350X is also gfx950; if not, adjust --offload-arch)

# 3. find a GPU with NO other processes, then:
./measure.sh <amd_smi_gpu_id> <hip_device_id> MI350X-box
```

Build the binary **on** the target machine. The prebuilt `.exe` in `build/`
needs GLIBC 2.38 / GLIBCXX_3.4.32; this host has 2.35 and cannot run it.

`HIP_VISIBLE_DEVICES` order != amd-smi GPU order. On this box HIP 7 -> BDF
95:00.0 -> amd-smi GPU 5. Verify the mapping before trusting telemetry.

## Comparing

Feed section 2 and 4 numbers into `eff_calc.py` for each machine and compare
`eff`. Equal `eff` => identical kernel behaviour, all remaining delta is
clock/power. Different `eff` => a real microarchitectural or memory-system
difference worth chasing.
