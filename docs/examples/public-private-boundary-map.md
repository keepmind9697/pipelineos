# Public Private Boundary Map v0.1

## Status

- Owner: Executor (Codex)
- Date: 2026-04-24
- Scope: A6
- Source meeting: `2026-04-24-pipelineos-github`

## Goal

This document maps what belongs in the public GitHub repo and what must remain inside the private workspace.

## Public: Include

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

## Export Strategy

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
