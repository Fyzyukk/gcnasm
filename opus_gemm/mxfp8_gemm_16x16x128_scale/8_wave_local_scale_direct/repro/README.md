# 保留配置的源码对应关系

主源码仍在上一级目录；没有移动或修改四份C++源码。它们与历史
`build_offline2_control_final_20260909` 的 `source.sha256` 逐一相同。
该control构建的证据集中保留在 [control/](control/)：

- `config.sh`：T2 / exact4 / source1 / nohandoff，全部实验选择器明确记录。
- `source.sha256`：四份当前主源码的构建时hash。
- `kernel.isa`：与保留版仅objdump文件路径标题不同；GPU指令和编码一致。
- `kernel.s`：与保留版仅`__hip_cuid_*`编译单元标识不同。
- `kernel.notes`：与保留版完全一致。
- `host.o`：与保留版host对象的反汇编一致。

原始保留目录没有记录自己的config/source hash，这是历史上就缺失的，非清理
删除。这里补充的是已有control的证据，不能倒填成原始保留构建记录。
当前源码可重建保留配置，但不承诺新ELF与冻结exe逐字节相同；CUID等非指令
内容可以不同。本次清理没有重编译，也没有重新跑GPU。

冻结保留版SHA256：

```text
69e9a10aedfea1170e545d273bad99198396bfe2d44b2cef929186677cc72921
```

构建入口为 [build_retained.sh](../build_retained.sh)，不要直接使用原build.sh的
历史默认值（T1/source2/handoff1）。新入口固定全部实验开关，并把输出放入新
目录，不覆盖保留镜像。

验证已有源码对应关系，不编译、不运行GPU：

```bash
sha256sum -c repro/control/source.sha256
bash build_retained.sh --print-config
```

这里的source.sha256保留原绝对路径记录；若把整个项目迁往另一台机器，需要
按文件名核对hash，而不是假定原绝对路径还存在。
