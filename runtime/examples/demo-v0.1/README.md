# Demo v0.1

中文说明：这个 demo 用一组干净样例展示 PipelineOS 的最小闭环。

This fixture demonstrates the clean PipelineOS loop:

`meeting notes -> accepted actions -> task-pool audit -> runtime briefing -> selected current task`

中文流程：

`meeting notes -> accepted actions -> task-pool audit -> runtime briefing -> selected current task`

Files:

- `00-agenda.md`
- `04-state.json`
- `action-registry.json`
- `task-pool-audit-report.json`
- `runtime-briefing.json`
- `selector-result.json`

中文说明：

- `00-agenda.md`：会议输入
- `04-state.json`：会议当前状态
- `action-registry.json`：已接受行动项
- `task-pool-audit-report.json`：任务池审计结果
- `runtime-briefing.json`：当前运行入口
- `selector-result.json`：当前任务选择结果

Note: validator output is part of the broader PipelineOS flow, but this fixture stops at selector output.

中文补充：`validator report` 属于更完整的 PipelineOS 验证链路，但当前 fixture 先收口到 `selector-result.json`。

Expected outcome:

- selector chooses `task-demo-001`
- runtime state remains safe and understandable without private workspace history

中文预期：

- selector 会选择 `task-demo-001`
- 即使没有私有工作区历史，读者仍能理解当前运行状态
