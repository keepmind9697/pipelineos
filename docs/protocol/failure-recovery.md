# Workflow Failure Recovery Spec v0.1

## Status

- Owner: Executor (Codex)
- Date: 2026-04-24
- Scope: A3
- Source meeting: `2026-04-24-pipelineos-github`

## Purpose

This document formalizes failure and recovery behavior for PipelineOS runtime scheduling.

It turns the meeting-level decisions around `blocked`, `failed`, and `retry` into an executable protocol surface.

## Why A3 Matters

Without explicit failure states:

- `current_task` selection is unsafe
- runtime cannot distinguish delay from failure
- retries become implicit and untraceable
- blocked work pollutes the active queue

Therefore A3 is a prerequisite for activating A2.

## State Set

Runtime-facing task states for v0.1:

- `queued`
- `in_progress`
- `ready_for_qa`
- `blocked`
- `failed`
- `retry`
- `done`

## Core Semantics

### `blocked`

Use when the task cannot continue because of:

- missing dependency
- missing context
- protocol conflict
- explicit external wait

Requirements:

- `blocked_reason`
- `last_update`
- `recovery_hint`

Runtime behavior:

- visible for awareness
- not eligible for `current_task`
- may remain in the filtered live pool as `live_blocked`

### `failed`

Use when a real execution attempt completed, but the output is not acceptable.

Examples:

- validation failed
- expected output missing
- implementation contradicted spec

Requirements:

- `failure_reason`
- failed check or evidence reference
- `last_update`
- `retry_allowed`

Runtime behavior:

- excluded from `current_task`
- must produce an explicit next decision

### `retry`

Use when the system intends another attempt after repair, clarification, or reassignment.

Requirements:

- `retry_reason`
- `retry_precondition`
- `retry_owner`
- `last_update`

Runtime behavior:

- not immediately eligible by default
- only re-enters `queued` or `in_progress` when retry preconditions are satisfied

## Transition Rules

### Allowed Forward Transitions

- `queued -> in_progress`
- `in_progress -> ready_for_qa`
- `in_progress -> blocked`
- `in_progress -> failed`
- `failed -> retry`
- `blocked -> retry`
- `retry -> queued`
- `retry -> in_progress`
- `ready_for_qa -> done`
- `ready_for_qa -> failed`

### Disallowed Silent Transitions

These must not happen without explicit reason capture:

- `blocked -> in_progress`
- `failed -> in_progress`
- `failed -> done`
- `blocked -> done`

## Failure Decision Payload

When a task enters `blocked`, `failed`, or `retry`, runtime should record:

- `task_id`
- `from_state`
- `to_state`
- `reason`
- `evidence_path` or `evidence_note`
- `decision_time`
- `decided_by`

## Runtime Guardrails

### Guardrail 1

`blocked` and `failed` must never be treated as synonyms.

### Guardrail 2

`retry` must not be inferred from operator memory.

### Guardrail 3

A task in `blocked`, `failed`, or `retry` must not remain a silent `current_task`.

### Guardrail 4

If validation output causes failure, runtime performs the transition.
Validator does not.

## Minimal Metadata Extension

To support A3 cleanly, task records should gain or normalize:

- `blocked_reason`
- `failure_reason`
- `retry_reason`
- `retry_precondition`
- `retry_allowed`
- `recovery_hint`

## Runtime Consumption Rule

Before A2 may select a task as `current_task`, it must exclude:

- `blocked`
- `failed`
- `retry` without satisfied preconditions

This is the minimum safe selector boundary.
