# GitHub MVP Definition v0.1

中文说明：本文件解释 GitHub v0.1 最小公开版本要证明什么，不是完整内部工作区导出。

## Status

- Owner: Executor (Codex)
- Date: 2026-04-24
- Scope: A5
- Source meeting: `2026-04-24-pipelineos-github`

## Product Definition

PipelineOS is:

`A file-protocol multi-agent workflow runtime that uses meeting state to manage collaboration, action registry to manage decision outputs, priority to schedule current task, and blocked / retry / stale_state to handle failure and stagnation.`

中文理解：

`PipelineOS 是一个基于文件协议的多 Agent 工作流运行时，用 meeting state 管协作，用 action registry 管决策结果，用 priority 调度 current task，并用 blocked / retry / stale_state 处理失败和停滞。`

## v0.1 Goal

GitHub v0.1 is not a full internal workspace export.

It is the smallest public project that can demonstrate:

`meeting -> action registry -> task -> execution view -> done / blocked / retry`

If that loop is visible and understandable after clone, v0.1 succeeds.

中文理解：只要用户 clone 后能看懂并验证这条最小闭环，v0.1 就算成立。

## What v0.1 Must Prove

1. PipelineOS has a clear protocol layer
2. PipelineOS has a runnable runtime layer
3. PipelineOS can expose a clean current-state entrypoint
4. PipelineOS can refuse unsafe scheduling instead of guessing
5. PipelineOS can demonstrate one clean end-to-end flow

中文理解：v0.1 的重点不是“功能多”，而是证明协议层、运行时层和一条可验证闭环都真实存在。

## What v0.1 Is Not

v0.1 is not:

- a full archive of the current workspace
- a private operating environment export
- a generic terminal multiplexer setup
- a business-specific project manager

中文理解：它不是当前私有工作环境的镜像，也不是某个业务项目专用的项目管理器。

## Required Public Layers

中文说明：公开仓库至少需要三层，少一层都不足以证明项目成立。

### 1. Protocol Layer

Must include:

- meeting state schema
- action registry schema
- task schema
- validator contract
- runtime status / current-state contract
- failure recovery rules
- time model and stale rules
- current-task selector rules

### 2. Runtime Layer

Must include:

- runtime briefing / current-state example
- action registry example
- audit report example
- meeting control rendering logic
- current task rendering logic
- read-only task-pool auditor

### 3. Example Layer

Must include:

- one clean demo meeting
- one clean demo action registry
- one clean demo task or task chain
- one demo selector result with non-empty live task mapping

## Acceptance Standard

v0.1 is ready when a new reader can:

1. identify the active control file
2. understand which action is active
3. understand which task is selectable
4. understand why the runtime selected or refused selection
5. run through one minimal loop without reading private history

中文理解：新读者不需要读取私有历史，也应该能独立跑通并理解一条最小工作流。

## Immediate Consequence

Because the current real workspace produces `no_live_task`, the GitHub MVP must rely on clean demo assets for closure rather than exporting the dirty real task pool.

中文结论：由于真实任务池当前不能安全形成 live task，公开版本必须依赖 clean demo，而不是直接导出真实任务池。
