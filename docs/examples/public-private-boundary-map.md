# Public Private Boundary Map v0.1

中文说明：本文件划分哪些资产应进入公开仓库，哪些必须留在私有工作区。

## Status

- Owner: Executor (Codex)
- Date: 2026-04-24
- Scope: A6
- Source meeting: `2026-04-24-pipelineos-github`

## Goal

This document maps what belongs in the public GitHub repo and what must remain inside the private workspace.

中文理解：目标是把“可复用产品内核”和“私有协作痕迹”明确切开。

## Public: Include

中文说明：以下内容可以进入公开仓库。

### Protocol Assets

- runtime spec
- validator contract
- audit report protocol
- audit judgment rules
- audit decision matrix / contract
- failure recovery spec
- time model spec
- current-task selector spec
- current-state / runtime-briefing protocol

### Runtime Assets

- read-only task-pool auditor
- meeting control renderer logic
- file/task renderer logic where repo-safe
- action-registry schema and example
- current-state example

### Example Assets

- demo meeting directory
- demo action-registry.json
- demo runtime-briefing.json
- demo task-pool-audit-report.json
- demo selector result

## Private: Exclude

中文说明：以下内容必须排除，不得直接公开。

### Historical Workspace State

- real meeting transcripts
- real recent_events history
- real task pool dump
- real handoff backlog

### Sensitive Local Context

- real project paths
- personal workflow details
- business references
- contracts, customers, or private references

### Dirty Runtime Artifacts

- current noisy task pool
- duplicate-heavy historical tasks
- local handoff history that is not part of the clean demo

## Transformation Rule

If an internal asset is conceptually important but context-sensitive, it should be:

1. abstracted into a protocol
2. reproduced as a clean example
3. not copied verbatim

中文理解：重要但带上下文的内部资产，应先抽象成协议，再生成干净示例，不能原样复制。

## Export Strategy

中文说明：导出时按三类处理，而不是统一打包。

### Export as-is

- protocol docs
- small safe scripts
- sanitized examples

### Export after sanitization

- runtime-briefing examples
- audit-report examples
- action-registry examples

### Never export directly

- raw `workspace/shared/tasks/`
- raw historical meetings
- raw private handoffs

## Consequence for Next Steps

The GitHub repo should be built from:

- protocol outputs
- runtime-safe scripts
- clean demo fixtures

It should not be built by copying the current workspace root.

中文结论：公开仓库应由协议产物、运行时安全脚本和 clean demo 组成，而不是从当前 workspace 根目录直接复制。
