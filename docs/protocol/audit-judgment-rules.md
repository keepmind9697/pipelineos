# Task Pool Audit Judgment Rules v0.1

## Status

- Owner: Executor (Codex)
- Date: 2026-04-24
- Scope: A14 follow-up
- Source meeting: `2026-04-24-pipelineos-github`

## Purpose

This document defines the judgment rules that feed `task-pool-audit-report`.

The goal is not to clean the pool directly.
The goal is to decide:

- what Runtime may see
- what Runtime must exclude
- what should be repaired
- what should be archived later

## Rule Set

### R1: One Source Action May Have Only One Active Task

For automatic scheduling, one `source_action_id` may map to only one active representative task.

If multiple tasks point to the same `source_action_id`, then:

- choose one canonical live task
- classify the others as duplicates or cleanup candidates
- exclude duplicate tasks from `current_task`

### R2: Tasks Without `source_action_id` Cannot Enter Automatic Scheduling

Historical tasks that lack `source_action_id` may remain in the pool, but they cannot enter automatic runtime scheduling.

They must be classified as one of:

- `orphan`
- `repairable`
- `archive_candidate`

### R3: Tasks Outside the Active Meeting Cannot Become `current_task`

If a task does not belong to the active meeting, it cannot become `current_task` unless it was explicitly promoted as cross-meeting work.

Default behavior:

- exclude from selector
- keep for traceability

### R4: Queued Beyond Timeout Enters `stale`

A queued task that exceeds timeout and is not justified by the current meeting/action context must be classified as stale.

Stale means:

- excluded from live scheduling
- not deleted
- eligible for review, repair, or later archive handling

### R5: `stale` Does Not Mean Delete

Staleness is a scheduling exclusion, not destructive cleanup.

Required behavior:

- keep the record
- remove it from the live pool
- surface it in `stale_tasks`

### R6: Duplicate Tasks Cannot Be Auto-Deleted

Duplicate tasks must not be automatically removed.

Allowed:

- mark `cleanup_candidate`
- assign canonical representative
- suppress from live scheduling

Not allowed in v0.1:

- destructive delete
- silent overwrite

### R7: Unsafe Tasks Must Be Quarantined from Runtime

If a task is unreadable, structurally invalid, or state-contradictory, Runtime must not consume it directly.

Unsafe tasks belong in:

- `unsafe_tasks`
- `recommended_actions` with repair or exclusion guidance

### R8: Live Eligibility Requires Positive Proof

A task is not live merely because it exists or is queued.

A task must prove live eligibility through:

- active meeting linkage
- acceptable status
- no duplicate shadow
- no stale exclusion
- sufficient metadata for runtime use

### R9: Recommended Actions Must Be Non-Destructive in v0.1

Every audit recommendation in v0.1 must be read-only in effect.

Allowed outputs:

- exclude from selector
- mark cleanup candidate
- request metadata repair
- request task regeneration from action
- request archive review

Not allowed outputs:

- delete file
- move file automatically
- rewrite task status automatically

### R10: Runtime Consumes Audit, Not Raw Queue, for Live Mapping

Once an audit report exists, Runtime should treat it as the filter layer between the raw task pool and live scheduling.

Principle:

`raw task pool -> audit judgment -> live task mapping -> current_task selection`

Not:

`raw task pool -> current_task selection`

## Priority of Judgment

When multiple rules apply, use this order:

1. structural safety
2. active meeting linkage
3. source action linkage
4. duplicate suppression
5. stale exclusion
6. live eligibility

This prevents an old queued task from surviving only because it happens to look executable.
