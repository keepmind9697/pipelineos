# Task Pool Audit Report Protocol v0.1

## Status

- Owner: Executor (Codex)
- Date: 2026-04-24
- Scope: A14 follow-up
- Source meeting: `2026-04-24-pipelineos-github`

## Purpose

This document defines the output contract for a read-only task-pool audit.

The audit report exists so Runtime can consume a filtered, actionable view of the task pool.
It is not a generic statistics dump.

The report must answer:

- which tasks are safe for Runtime to see
- which tasks must be excluded from live scheduling
- which tasks require repair, archive review, or re-generation
- what the next non-destructive actions should be

## Design Rule

The report must optimize for runtime decisions, not raw counts.

Counts are useful, but insufficient.
Every report must include a `recommended_actions` section that translates observations into execution-safe next steps.

## Output Formats

The audit should eventually support both:

1. `task-pool-audit-report.json`
2. `task-pool-audit-report.md`

The JSON file is the runtime-facing source of truth.
The Markdown file is the human-facing explanation.

## Top-Level Structure

The report must contain these top-level sections:

1. `summary`
2. `live_candidates`
3. `stale_tasks`
4. `duplicate_groups`
5. `orphan_tasks`
6. `unsafe_tasks`
7. `recommended_actions`

Optional sections may be added later, but these are required in v0.1.

## 1. Summary

Purpose:

- provide a compact snapshot of task-pool health
- expose the minimum counts needed for runtime and operator awareness

Required fields:

- `generated_at`
- `active_meeting_id`
- `total_files_seen`
- `parseable_tasks`
- `unparseable_files`
- `queued_count`
- `in_progress_count`
- `ready_for_qa_count`
- `stale_count`
- `duplicate_count`
- `orphan_count`
- `unsafe_count`
- `live_candidate_count`

## 2. Live Candidates

Purpose:

- define which tasks Runtime is allowed to consider for live scheduling

This section is the most important runtime input after the active meeting and action registry.

Each item should include:

- `task_id`
- `source_meeting_id`
- `source_action_id`
- `status`
- `priority`
- `working_scope`
- `why_live`
- `selection_eligible`: `true | false`
- `selection_blockers`

Rule:

- a task may appear in `live_candidates` even if not immediately selectable
- but only `selection_eligible=true` items may enter `current_task` resolution

## 3. Stale Tasks

Purpose:

- identify tasks that should be excluded from the active pool because time invalidated their scheduling relevance

Each item should include:

- `task_id`
- `status`
- `last_update`
- `timeout`
- `stale_state`
- `source_meeting_id`
- `source_action_id`
- `stale_reason`
- `reactivation_requirement`

Rule:

- `stale` means excluded from live scheduling by default
- `stale` does not mean delete

## 4. Duplicate Groups

Purpose:

- group tasks that appear to represent the same source work

Each group should include:

- `group_id`
- `canonical_task_id`
- `duplicate_task_ids`
- `match_basis`
- `source_meeting_id`
- `source_action_id`
- `recommended_cleanup_state`

Rule:

- duplicate tasks must be grouped, not merely counted
- Runtime must know which task is canonical

## 5. Orphan Tasks

Purpose:

- isolate tasks that lack enough linkage to participate in current scheduling

Each item should include:

- `task_id`
- `status`
- `missing_fields`
- `last_update`
- `reason_orphaned`
- `archive_candidate`: `true | false`
- `repairable`: `true | false`

Rule:

- orphan tasks are excluded from automatic scheduling

## 6. Unsafe Tasks

Purpose:

- identify tasks that should not be trusted by Runtime because their structure or state is unsafe

Unsafe includes:

- unreadable JSON
- required-field violations
- invalid status values
- contradictory metadata

Each item should include:

- `task_path`
- `task_id` if recoverable
- `unsafe_reason`
- `severity`
- `repair_suggestion`

## 7. Recommended Actions

Purpose:

- convert audit observations into non-destructive next steps

Without this section, the report is observational only and cannot enter runtime use.

Each recommended action should include:

- `action_id`
- `action_type`
- `target_scope`
- `reason`
- `priority`
- `owner_role`
- `destructive`: `true | false`
- `requires_human_review`: `true | false`

Suggested `action_type` values:

- `suppress_from_live_pool`
- `mark_cleanup_candidate`
- `repair_metadata`
- `relink_to_action`
- `regenerate_task_from_action`
- `archive_review`
- `exclude_from_current_selector`

## Runtime Consumption Rules

Runtime should consume the report in this order:

1. read `summary` for health signals
2. read `live_candidates` to build the live task pool
3. read `duplicate_groups`, `orphan_tasks`, `stale_tasks`, and `unsafe_tasks` to exclude items from live scheduling
4. read `recommended_actions` to decide next non-destructive control steps

Runtime must not override the report by going back to naive full-queue scanning during the same cycle.

## Minimal JSON Shape

```json
{
  "summary": {},
  "live_candidates": [],
  "stale_tasks": [],
  "duplicate_groups": [],
  "orphan_tasks": [],
  "unsafe_tasks": [],
  "recommended_actions": []
}
```

## Non-Goals

- direct task mutation
- automatic deletion
- automatic archival move
- direct status rewrite during report generation

v0.1 audit output is read-only.
