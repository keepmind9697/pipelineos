# GitHub Repo Skeleton v0.1

中文说明：本文件定义 PipelineOS v0.1 公开仓库的最小目录骨架。

## Status

- Owner: Executor (Codex)
- Date: 2026-04-24
- Scope: A7
- Source meeting: `2026-04-24-pipelineos-github`

## Goal

Define the minimal public repo structure for PipelineOS v0.1.

中文理解：目标不是还原私有工作区，而是给公开项目一个足够清晰、可维护、可演示的结构。

## Proposed Structure

```text
pipelineos/
├── README.md
├── docs/
│   ├── protocol/
│   ├── runtime/
│   └── examples/
├── runtime/
│   ├── tools/
│   ├── schemas/
│   └── examples/
└── LICENSE
```

中文理解：`docs/` 放解释与协议，`runtime/` 放可运行工具和 demo，根目录保持尽量干净。

## Protocol Layer

中文说明：`docs/protocol/` 下应该放协议和规则文档，而不是私有历史材料。

Expected under `docs/protocol/`:

- runtime spec
- validator contract
- failure recovery
- time model
- current-task selector
- audit-report protocol
- audit judgment rules
- audit decision model

## Runtime Layer

中文说明：`runtime/tools/` 放可运行脚本，`runtime/examples/` 放干净的示例资产。

Expected under `runtime/tools/`:

- `task-pool-audit.py`
- `pipeline-meeting-view.sh`
- `pipeline-file-view.sh`

Expected under `runtime/examples/`:

- clean demo meeting
- clean action-registry
- clean runtime-briefing
- clean audit-report
- clean selector result

## Constraint

This skeleton is for export.
It must not mirror the private workspace layout directly.

中文约束：公开仓库骨架服务于发布，不应直接映射私有 workspace 结构。
