# Demo v0.1

This fixture demonstrates the clean PipelineOS loop:

`meeting -> action registry -> task-pool audit -> runtime briefing -> selector result`

Files:

- `00-agenda.md`
- `04-state.json`
- `action-registry.json`
- `task-pool-audit-report.json`
- `runtime-briefing.json`
- `selector-result.json`

Expected outcome:

- selector chooses `task-demo-001`
- runtime state remains safe and understandable without private workspace history
