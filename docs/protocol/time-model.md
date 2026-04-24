# Runtime Time Model Spec v0.1

## Status

- Owner: Executor (Codex)
- Date: 2026-04-24
- Scope: A4
- Source meeting: `2026-04-24-pipelineos-github`

## Purpose

This document defines the minimum time metadata required for PipelineOS runtime decisions.

It formalizes:

- `last_update`
- `timeout`
- `stale_state`

## Why A4 Matters

Without time metadata:

- runtime cannot detect stalled work
- queued history looks equivalent to fresh work
- A2 cannot choose safely
- retry and takeover logic becomes guesswork

Therefore A4 is also a prerequisite for activating A2.

## Required Fields

### `last_update`

Definition:

- the latest timestamp when a task or action made meaningful progress or heartbeat

Format:

- ISO8601

### `timeout`

Definition:

- the maximum allowed dwell time in the current state before the item becomes stale

Format:

- implementation-defined duration value, but must be machine-readable

Examples:

- `24h`
- `4h`
- `30m`

### `stale_state`

Definition:

- the runtime judgment derived from current time, `last_update`, and `timeout`

Suggested values:

- `fresh`
- `warning`
- `stale`
- `expired`

## State Semantics

### `fresh`

- normal scheduling behavior

### `warning`

- still visible
- should increase operator awareness

### `stale`

- excluded from default `current_task` selection
- visible in audit output

### `expired`

- no longer trustworthy as an active scheduling candidate
- requires explicit recovery or regeneration

## Computation Rule

Runtime should compute `stale_state` using:

`now - last_update` compared against `timeout`

Recommended thresholds:

- below `timeout * 0.5` => `fresh`
- between `0.5` and `1.0` => `warning`
- above `1.0` => `stale`
- well beyond policy or after multiple missed cycles => `expired`

Exact multipliers may evolve, but the four-state ladder should remain stable.

## Scope of Use

Time metadata should apply to:

- actions
- tasks
- retries
- blocked items

It should not be limited to execution-only states.

## Runtime Behavior

### For `queued`

- `stale` means do not auto-select

### For `in_progress`

- `stale` means investigate
- `expired` means current execution assumption is invalid

### For `blocked`

- `stale` means blocked state needs intervention

### For `retry`

- `expired` means retry intent is no longer current and should be reassessed

## Minimal Metadata Extension

To support A4 cleanly, action and task records should gain or normalize:

- `created_at`
- `last_update`
- `timeout`
- `stale_state`
- `started_at` when execution begins

## Runtime Guardrails

### Guardrail 1

No task may be auto-selected if `stale_state` is `stale` or `expired`.

### Guardrail 2

Items without `last_update` or `timeout` must be treated conservatively.

Recommended behavior:

- visible for audit
- not eligible for automatic selection

### Guardrail 3

`stale` is a scheduling exclusion, not a destructive action.

### Guardrail 4

`expired` requires explicit operator or runtime recovery handling.

## A2 Activation Dependency

A2 should not be activated until:

- task-level time fields exist or are reliably inferable
- audit output can surface `stale_state`
- runtime selector can exclude stale work by rule
