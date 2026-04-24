# Task Pool Audit Decision Matrix v0.1

## Status

- Owner: Executor (Codex)
- Date: 2026-04-24
- Scope: A16
- Source meeting: `2026-04-24-pipelineos-github`

## Purpose

This matrix translates audit judgment rules into explicit runtime-facing outcomes.

It answers one practical question:

When a task matches a condition, what category should it enter, and what must Runtime do with it?

## Matrix

| Condition | Category | Runtime Visibility | Selector Eligibility | Required Report Section | Required Recommended Action |
|---|---|---|---|---|---|
| Unreadable JSON or severe schema drift | `unsafe` | hidden from live pool | no | `unsafe_tasks` | `repair_metadata` or `exclude_from_current_selector` |
| Missing `source_action_id` and no safe relink path | `orphan` | hidden from live pool | no | `orphan_tasks` | `archive_review` or `repair_metadata` |
| Non-active meeting task without explicit cross-meeting promotion | `out_of_meeting_scope` | hidden from live pool | no | `orphan_tasks` or `stale_tasks` | `exclude_from_current_selector` |
| Same `source_action_id` as an already chosen canonical task | `duplicate` | hidden from live pool | no | `duplicate_groups` | `mark_cleanup_candidate` |
| `queued` beyond timeout and not justified by active action context | `stale` | hidden from live pool | no | `stale_tasks` | `suppress_from_live_pool` |
| Structurally valid, current-meeting-linked, action-linked, non-duplicate, non-stale task | `live` | visible | yes, if no blocker | `live_candidates` | optional |
| Structurally valid but blocked by missing dependency or validation wait | `live_blocked` | visible | no | `live_candidates` | `repair_metadata`, `relink_to_action`, or wait-state note |

## Category Semantics

### `live`

- can appear in the filtered live task pool
- may enter `current_task` resolution if all selector checks pass

### `live_blocked`

- remains visible to runtime for awareness
- must not be selected as `current_task`
- should include explicit blockers

### `stale`

- excluded from active scheduling
- still retained as known historical work

### `duplicate`

- excluded from active scheduling
- must reference a canonical representative task

### `orphan`

- excluded from active scheduling
- needs repair, relink, or archive review

### `unsafe`

- excluded from all runtime decisions
- requires repair before any further classification

### `out_of_meeting_scope`

- excluded from current meeting scheduling
- may remain historically valid
- should not be treated as current work without explicit promotion

## Canonical Precedence

When a task matches multiple categories, classify using this precedence:

1. `unsafe`
2. `out_of_meeting_scope`
3. `orphan`
4. `duplicate`
5. `stale`
6. `live_blocked`
7. `live`

This prevents a malformed or mis-scoped task from surviving because it also looks active.

## Runtime Rule

Only `live` and `live_blocked` may appear in the visible filtered task pool.

Only `live` may be eligible for `current_task`.
