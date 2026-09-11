# 复现工具冒烟验证

本目录记录 `tools/compare_versions.py` 保存后的一轮端到端运行，用于验证物理GPU5 → PCI `0000:95:00.0` → HIP7绑定、两版源码重建、ISA检查、完整CLI输入的输出比较及同地址计时流程。

基线和当前版本的BF16、FP32输出均完成67,108,864个元素的精确比较。运行日志见 `../../reproduction_smoke.log`。

此处单轮计时用于验证工具流程。正式性能采用 [GPU2五轮CLI记录](../../measurements/formal_cli_gpu2/) 和 [最终选择记录](../../selection.json) 中的中位数。
