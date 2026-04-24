# Current Task Selector Spec v0.1

## Status

- Owner: Executor (Codex)
- Date: 2026-04-24
- Scope: A2
- Source meeting: `2026-04-24-pipelineos-github`

## Purpose

This document defines how Runtime selects `current_task`.

It activates A2 on top of:

- canonical `action-registry.json`
- canonical `runtime-briefing.json`
- canonical `task-pool-audit-report.json`
- completed A1, A3, A4, and A11

## Selector Inputs

Runtime must read, in order:

1. `workspace/shared/runtime-briefing.json`
2. `workspace/shared/action-registry.json`
3. `workspace/executor/outputs/task-pool-audit-report.json`

The selector must not fall back to raw `workspace/shared/tasks/` scanning in the same cycle.

## Selector Preconditions

Before selection may run:

- `A1 = DONE`
- `A3 = DONE`
- `A4 = DONE`
- `A11 = DONE`
- canonical audit report path exists

If any prerequisite is false, selector returns:

- `status = gated`
- `selected_task = none`

## Action Eligibility

An action is eligible to feed task selection only if:

- `state = READY`
- `priority in {high, medium}`
- it is not blocked by explicit activation gate

Automatic selection order:

1. `high`
2. `medium`

`low` never enters automatic selection.

## Task Eligibility

A task is eligible only if all are true:

- present in `live_candidates`
- `selection_eligible = true`
- not stale
- not duplicate
- not orphan
- not unsafe
- linked to the active meeting

## Selector Algorithm

### Step 1

Read `priority_selection_policy` from `action-registry.json`.

### Step 2

Find `READY` actions in priority order.

### Step 3

For each candidate action, try to find a matching live task from audit output.

Matching preference:

1. exact `source_action_id`
2. explicit linked task mapping
3. current runtime execution pointer if already aligned

### Step 4

If a matching live task exists, select it.

### Step 5

If no matching live task exists for any eligible action, return:

- `status = no_live_task`
- `selected_task = none`

This is a valid selector outcome.

## Selector Output

Each selector run should produce a result object:

```json
{
  "generated_at": "ISO8601",
  "active_meeting_id": "string",
  "selector_status": "selected | gated | no_live_task",
  "selected_action_id": "string | null",
  "selected_task_id": "string | null",
  "reason": "string"
}
```

## Runtime Safety Rule

`none selected` is safer than selecting from a dirty queue.

If the audited live pool is empty, Runtime must not guess from raw queued tasks.

## Current Real-System Result

Given the current canonical audit report:

- `live_candidate_count = 0`
- no safe live task exists

Therefore the correct current selector result is:

- `selector_status = no_live_task`
- `selected_action_id = A2` remains the action under activation
- `selected_task_id = null`

This is not failure.
It is a correct runtime refusal to select unsafely.
