# Runtime Briefing Protocol v0.1

## Status

- Owner: Executor (Codex)
- Date: 2026-04-24
- Scope: A18
- Source meeting: `2026-04-24-pipelineos-github`

## Purpose

This document defines the single narrow-entry file that agents should read before touching the wider workspace.

PipelineOS needs a current-state artifact because the workspace is no longer self-evident:

- many meetings may exist
- many tasks may be stale or duplicated
- many handoffs may be proposals rather than current truth
- active runtime state can no longer be inferred safely from raw file volume

Therefore:

Agents should not begin by browsing the full workspace.
They should begin by reading a runtime-generated briefing.

## Definition

`runtime-briefing` or `current-state` is the runtime-authored summary of the current control situation.

It is the primary entry point for:

- Architect onboarding
- Runtime resumption
- operator orientation
- current control visibility

It is not:

- a README
- a meeting transcript
- a generic project overview
- a historical archive

It is the current operational snapshot.

## Core Design Rule

Do not let agents read the workspace first.
Let agents read the briefing first.

The briefing exists to answer:

- what is current
- what is visible
- what is blocked
- what is forbidden
- what should happen next

## Output Targets

The protocol should support at least:

1. `runtime-briefing.json`
2. `runtime-briefing.md`

The JSON file is the runtime-facing source of truth.
The Markdown file is the human-facing control panel summary.

## Required Top-Level Sections

The briefing must include these sections:

1. `runtime_identity`
2. `current_control_state`
3. `current_meeting`
4. `action_registry_pointer`
5. `visible_task_pool`
6. `blocked_zones`
7. `recommended_next_actions`
8. `source_map`

## 1. Runtime Identity

Purpose:

- establish who generated the briefing and when

Required fields:

- `generated_at`
- `generated_by`
- `briefing_version`
- `active_runtime_mode`

## 2. Current Control State

Purpose:

- expose the minimum runtime state needed to resume safely

Required fields:

- `current_meeting_id`
- `current_phase`
- `current_mode`
- `current_action_id`
- `current_task_id`
- `current_executor`
- `current_step`
- `started_at`
- `current_task_status`
- `current_blocker`
- `system_health`

Suggested `system_health` values:

- `stable`
- `degraded`
- `blocked`
- `recovery_required`

### Execution Pointer Rule

`current_mode=execution` is not enough to describe active work.

The briefing must expose an explicit execution pointer so Runtime and UI can answer:

- which action is currently being executed
- which task represents that action
- which executor owns it
- which concrete step is in flight
- when that execution step started

This pointer is the source of truth for "currently executing" state.
It must not be inferred from Action Registry state alone.

## 3. Current Meeting

Purpose:

- identify which meeting is authoritative right now

Required fields:

- `meeting_id`
- `meeting_state_path`
- `agenda_path`
- `discussion_path`
- `decisions_path`
- `actions_path`
- `why_current`

Rule:

- only one meeting may be treated as the active control meeting by default

## 4. Action Registry Pointer

Purpose:

- direct agents to the current action surface without making them infer it from meeting prose

Required fields:

- `registry_path`
- `registry_status`
- `active_actions`
- `ready_actions`
- `linked_actions`
- `selection_policy_summary`

If no dedicated registry file exists yet, this section must explicitly state the current fallback source.

### Action Registry Boundary

Action Registry remains the lifecycle view of meeting outputs.

It may contain states such as:

- `OPEN`
- `READY`
- `LINKED`
- `DONE`
- `BLOCKED`

It should not be overloaded to describe fine-grained execution progress.

Execution progress belongs to the execution pointer in `current_control_state`.

## 5. Visible Task Pool

Purpose:

- define what Runtime currently allows agents to see as schedulable work

Required fields:

- `audit_report_path`
- `live_candidate_source`
- `live_candidate_count`
- `current_selector_scope`
- `suppressed_categories`
- `notes`

Suggested `suppressed_categories` values:

- `stale`
- `duplicate`
- `orphan`
- `unsafe`
- `out_of_meeting_scope`

Rule:

- this section represents the filtered task pool, not the raw task directory

## Runtime Status Rendering Rule

Any control-facing UI, including window 4, should render a dedicated `Runtime Status` block above the Action Registry.

That block should read from the execution pointer fields in `current_control_state`, not from action lifecycle rows.

Minimum rendered fields:

- `Mode`
- `Current Action`
- `Current Task`
- `Executor`
- `Step`
- `Started At`
- `Source`

Recommended `Source` value:

- `runtime-briefing`

## 6. Blocked Zones

Purpose:

- tell agents what they must not treat as live or editable truth

Required fields:

- `do_not_use_as_entry`
- `do_not_mutate_without_runtime_or_user`
- `historical_only`
- `proposal_only`

Examples:

- raw full task pool
- old meeting directories
- unpromoted handoffs
- legacy role paths

## 7. Recommended Next Actions

Purpose:

- turn current state into an immediately actionable control plan

This section is mandatory.

Each item should include:

- `action_id`
- `summary`
- `priority`
- `owner_role`
- `why_now`
- `depends_on`
- `safe_to_execute_now`

This is the section new agents should use first.

## 8. Source Map

Purpose:

- show exactly which files the briefing was derived from

Required fields:

- `pipeline_state_path`
- `meeting_state_path`
- `action_registry_path`
- `audit_report_path`
- `runtime_spec_path`
- `decision_sources`

This provides traceability without requiring first-pass workspace exploration.

## Runtime Consumption Order

Any agent onboarding into current control state should read in this order:

1. `runtime-briefing`
2. `current meeting state`
3. `action registry`
4. `task-pool-audit-report`
5. `runtime spec`
6. only then, any specific task or meeting files required for execution

This is the official narrow-entry path.

## Architect-Specific Rule

Architect should not begin by scanning the whole workspace.

Architect should begin from the briefing and only expand outward when:

- a recommended next action requires deeper evidence
- a decision needs source verification
- runtime marks a path as safe and relevant

This protects the control role from historical queue pollution.

## Minimal JSON Shape

```json
{
  "runtime_identity": {},
  "current_control_state": {},
  "current_meeting": {},
  "action_registry_pointer": {},
  "visible_task_pool": {},
  "blocked_zones": {},
  "recommended_next_actions": [],
  "source_map": {}
}
```

## Non-Goals

- full project documentation
- historical archive browsing
- raw queue introspection
- replacing detailed task specs

The briefing is an entry file, not the whole system.
