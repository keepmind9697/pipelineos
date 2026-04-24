# GitHub Repo Skeleton v0.1

## Status

- Owner: Executor (Codex)
- Date: 2026-04-24
- Scope: A7
- Source meeting: `2026-04-24-pipelineos-github`

## Goal

Define the minimal public repo structure for PipelineOS v0.1.

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

## Protocol Layer

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
