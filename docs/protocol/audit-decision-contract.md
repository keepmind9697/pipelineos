# Task Pool Audit Decision Contract v0.1

## Status

- Owner: Executor (Codex)
- Date: 2026-04-24
- Scope: A16
- Source meeting: `2026-04-24-pipelineos-github`

## Purpose

This document defines the minimum decision payload that an audit implementation must produce for each classified task or task group.

It is the bridge between:

- audit judgment rules
- audit report structure
- runtime consumption

## Per-Item Decision Payload

Each classified item in the audit process should resolve to a decision object with:

- `subject_type`: `task | task_group | task_path`
- `subject_id`
- `classification`
- `visible_to_runtime`: `true | false`
- `eligible_for_current_selector`: `true | false`
- `reason_codes`
- `recommended_action_type`
- `requires_human_review`: `true | false`

## Required Classification Values

- `live`
- `live_blocked`
- `stale`
- `duplicate`
- `orphan`
- `unsafe`
- `out_of_meeting_scope`

## Required Reason Codes

Reason codes should be short, stable, and machine-friendly.

Suggested v0.1 set:

- `missing_source_action_id`
- `missing_source_meeting_id`
- `not_active_meeting`
- `queued_timeout_exceeded`
- `duplicate_source_action`
- `schema_invalid`
- `json_unreadable`
- `waiting_validation`
- `missing_dependency`
- `canonical_task_exists`

## Required Recommended Action Types

- `exclude_from_current_selector`
- `suppress_from_live_pool`
- `mark_cleanup_candidate`
- `repair_metadata`
- `relink_to_action`
- `regenerate_task_from_action`
- `archive_review`

## Decision Invariants

### Invariant 1

If `visible_to_runtime=false`, the subject must not appear in `live_candidates`.

### Invariant 2

If `eligible_for_current_selector=true`, then:

- `classification` must be `live`
- `visible_to_runtime` must be `true`

### Invariant 3

If `classification=duplicate`, then `recommended_action_type` must not be destructive.

### Invariant 4

If `classification=unsafe`, then `eligible_for_current_selector` must always be `false`.

### Invariant 5

If `classification=out_of_meeting_scope`, then the subject must not become `current_task` in the active meeting cycle.

## Minimal Example

```json
{
  "subject_type": "task",
  "subject_id": "task-1971",
  "classification": "stale",
  "visible_to_runtime": false,
  "eligible_for_current_selector": false,
  "reason_codes": ["queued_timeout_exceeded", "not_active_meeting"],
  "recommended_action_type": "suppress_from_live_pool",
  "requires_human_review": false
}
```
