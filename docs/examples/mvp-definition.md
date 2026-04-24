# GitHub MVP Definition v0.1

## Status

- Owner: Executor (Codex)
- Date: 2026-04-24
- Scope: A5
- Source meeting: `2026-04-24-pipelineos-github`

## Product Definition

PipelineOS is:

`A file-protocol multi-agent workflow runtime that uses meeting state to manage collaboration, action registry to manage decision outputs, priority to schedule current task, and blocked / retry / stale_state to handle failure and stagnation.`

## v0.1 Goal

GitHub v0.1 is not a full internal workspace export.

It is the smallest public project that can demonstrate:

`meeting -> action registry -> task -> execution view -> done / blocked / retry`

If that loop is visible and understandable after clone, v0.1 succeeds.

## What v0.1 Must Prove

1. PipelineOS has a clear protocol layer
2. PipelineOS has a runnable runtime layer
3. PipelineOS can expose a clean current-state entrypoint
4. PipelineOS can refuse unsafe scheduling instead of guessing
5. PipelineOS can demonstrate one clean end-to-end flow

## What v0.1 Is Not

v0.1 is not:

- a full archive of the current workspace
- a private operating environment export
- a generic terminal multiplexer setup
- a business-specific project manager

## Required Public Layers

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

## Immediate Consequence

Because the current real workspace produces `no_live_task`, the GitHub MVP must rely on clean demo assets for closure rather than exporting the dirty real task pool.
