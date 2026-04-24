# PipelineOS Runtime Spec v0.1

## Status

- Owner: Executor (Codex)
- Date: 2026-04-24
- Scope: GitHub v0.1 runtime layer
- Source meeting: `2026-04-24-pipelineos-github`

## Purpose

This document defines `Runtime` as an explicit system node inside PipelineOS.

PipelineOS is not a loose collection of agents. It is a file-protocol workflow runtime that:

- reads shared truth files
- decides when actions become tasks
- selects the current task
- invokes validators
- performs state transitions
- drives execution-facing views

Without an explicit runtime, control leaks into individual agents and the system becomes unstable.

## Runtime Definition

`Runtime` is the scheduling and state-transition node of PipelineOS.

It is responsible for:

1. Reading `meeting state` and `action registry`
2. Determining which actions are eligible to become tasks
3. Selecting `current_task` using priority and status rules
4. Invoking validator nodes at the correct time
5. Applying state transitions based on execution and validation results
6. Updating runtime-facing views such as window 4 and window 5

`Runtime` is not:

- a producer of business content
- a validator
- a meeting participant

It is the control layer.

## Node Types

PipelineOS only allows three node types.

### 1. Producer Nodes

Producer nodes generate artifacts or implement changes.

Examples:

- Architect
- Executor

Allowed:

- create drafts
- create handoffs
- generate tasks or implementation outputs according to protocol

Not allowed:

- self-approve outputs
- bypass runtime transitions

### 2. Validator Nodes

Validator nodes are read-only.

Example:

- Gemini.Validator

Allowed:

- receive `target_path`
- receive `schema_path`
- receive `context`
- emit `qa-report`

Not allowed:

- modify `meeting state`
- modify `action registry`
- modify `task state`
- modify `decision`
- promote drafts into protocol
- define system direction without being explicitly asked by the control layer

### 3. Scheduler Nodes

Scheduler nodes control flow.

Examples:

- Runtime
- Host

Allowed:

- call validators
- convert actions to tasks
- pick `current_task`
- trigger state transitions
- determine which shared truth each view consumes

## Shared Truth Inputs

Runtime only consumes shared or protocol-approved inputs.

### Required Inputs

1. `meeting state`
2. `action registry`
3. `task registry` or `task JSON files`
4. `qa-report`
5. `decision` files when present

### Disallowed Inputs

- agent memory
- chat-only assumptions
- private drafts that were not promoted or explicitly referenced

## Real-World Runtime Constraint: Noisy Task Pool

Runtime must be designed for a dirty queue, not an ideal queue.

Current observed system pattern:

- the task pool can contain thousands of task files
- many are legacy or bulk-generated
- many remain stuck in `queued`
- active work may still be tied to a small number of meeting actions
- repeated action-to-task conversion can create duplicate task noise

Therefore:

- the raw task directory is not a reliable scheduling surface by itself
- runtime must not pick `current_task` by naively scanning all queued tasks
- runtime must prioritize action-driven scheduling over queue-volume heuristics

## Queue Hygiene Rules

Runtime must treat queue hygiene as part of scheduling, not as an optional cleanup step.

### Rule 4: Action Registry Is the Primary Scheduling Surface

When queue noise exists, runtime should schedule from the action layer first, then resolve into task records.

Order of trust:

1. current meeting state
2. action registry linked to the active meeting
3. eligible current task derived from that action set
4. broader task pool as a secondary lookup surface

This prevents legacy queued tasks from dominating active runtime focus.

### Rule 5: Task Pool Scanning Requires Deduplication

If runtime scans the task pool, it must deduplicate by at least:

- `source_action_id`
- meeting context
- working scope
- active owner role

Goal:

- prevent one action from appearing as many competing queued tasks
- prevent historical duplicates from hijacking `current_task`

### Rule 6: Current Task Must Be Focused, Not Merely Available

A task is not eligible for `current_task` just because it is `queued`.

Runtime should prefer tasks that are:

- linked to the active meeting
- linked to an active or accepted action
- not superseded by a duplicate task for the same source action
- recent enough to remain valid under stale policy
- aligned with the current phase of coordination

This is how the system avoids idle queue churn.

## Core Runtime Data Contracts

### Meeting State

Minimum runtime-facing fields:

- `meeting_id`
- `phase`
- `problems`
- `recent_events`
- `current_action_id` or equivalent pointer
- `current_task_id` or equivalent pointer

Purpose:

- define collaboration context
- expose current coordination phase
- provide view state for window 4

### Action Registry

Each action must be schedulable, not just human-readable.

Minimum fields:

- `action_id`
- `title`
- `priority`: `high | medium | low`
- `status`
- `owner_role`
- `preconditions`
- `created_from`
- `last_update`
- `timeout`
- `stale_state`
- `task_eligibility`

Suggested statuses:

- `proposed`
- `accepted`
- `active`
- `blocked`
- `done`
- `failed`
- `retry_pending`

### Task Record

Minimum runtime-facing fields:

- `task_id`
- `source_action_id`
- `source_meeting_id`
- `role`
- `status`
- `assigned_to`
- `last_update`
- `timeout`
- `stale_state`
- `working_scope`
- `validation_required`
- `handoff_to`

Suggested statuses:

- `queued`
- `in_progress`
- `ready_for_qa`
- `blocked`
- `failed`
- `retry`
- `done`

### QA Report

Validator output is informational, not authoritative over state.

Minimum fields:

- `target_path`
- `schema_path`
- `status`: `PASS | FAIL`
- `issues`
- `evidence`
- `generated_at`

## Control Rules

### Rule 1: Capabilities Only Exist When Accepted by the System

An agent capability is not active just because an agent claims it.

Only these count as effective capability:

- written into shared protocol
- called by runtime
- explicitly accepted by the system

Any standalone draft remains a proposal.

### Rule 2: Validators Cannot Mutate Shared Truth

Validator output can influence scheduling decisions, but it cannot directly rewrite state.

Valid:

- `FAIL` in `qa-report`
- evidence and issue listing

Invalid:

- directly setting an action to `blocked`
- directly setting a task to `failed`
- directly editing shared truth files

Runtime consumes `qa-report` and performs the transition.

### Rule 3: Producer, Validator, and Scheduler Roles Must Not Collapse

If one node starts producing, validating, and scheduling at the same time, the system loses control boundaries.

PipelineOS must preserve separation between:

- production
- validation
- scheduling

## Action-to-Task Conversion

Runtime decides when an action is eligible to become a task.

### Eligibility Conditions

An action can be converted to a task only if:

1. `status` is in an allowed schedulable state such as `accepted` or `active`
2. required `preconditions` are satisfied
3. action definition is concrete enough to execute
4. no higher-priority conflicting action is already selected as `current_task`
5. no equivalent live task already exists for the same `source_action_id`

### Rejection Conditions

An action must not become a task if:

- the action is ambiguous
- missing context makes execution unsafe
- it is stale and requires revalidation
- it is blocked by dependency or explicit decision

When rejected, runtime should either:

- keep it in action form
- mark it `blocked`
- mark it `retry_pending`
- escalate it back to meeting flow

### Duplicate Prevention

Runtime must not repeatedly materialize the same action into many queued tasks.

Before creating a new task, runtime should check for an existing live task with the same:

- `source_action_id`
- `source_meeting_id`
- comparable `working_scope`
- non-terminal status

If such a task exists, runtime should:

- reuse that task as the active representative
- or explicitly supersede and retire the older one

It must not silently create another equivalent queued task.

## Current Task Selection

Runtime chooses `current_task` using strict priority order.

### Selection Order

1. Choose only from `high` priority eligible items
2. If and only if no eligible `high` item exists, choose from `medium`
3. `low` priority is excluded from default selection

### Additional Filters

A task is eligible for `current_task` only if:

- status is executable
- not stale beyond policy
- not blocked
- not waiting on validation
- not superseded by a newer retry candidate
- not a duplicate shadow of an already active source action
- traceable to the active meeting or explicitly promoted cross-meeting work

## Time Model

Runtime must treat time as a first-class signal.

### Required Fields

- `last_update`
- `timeout`
- `stale_state`

### Stale State Semantics

Suggested values:

- `fresh`
- `warning`
- `stale`
- `expired`

### Runtime Behavior

- `fresh`: normal execution
- `warning`: show urgency, but do not force transition yet
- `stale`: require runtime attention, possible escalation or retry planning
- `expired`: current execution assumption is invalid and must be re-evaluated

## Failure and Recovery Model

Runtime must not assume success as the default lifecycle.

### Blocked

Use `blocked` when progress cannot continue because of:

- missing dependency
- missing context
- protocol conflict
- external wait state

Blocked requires:

- explicit reason
- recovery hint or missing prerequisite
- timestamp

### Failed

Use `failed` when execution completed a real attempt but did not produce acceptable output.

Failed requires:

- failure reason
- evidence or failed check
- whether retry is allowed

### Retry

Use `retry` when the system intends another attempt after:

- context repair
- spec clarification
- dependency resolution
- runtime reassignment

Retry must not be implicit. Runtime must record:

- retry trigger
- retry owner
- retry precondition

## Validator Invocation Model

Runtime decides when validators run.

### Validator Input Contract

- `target_path`
- `schema_path`
- `context`

### Validator Output Contract

- `qa-report`

### Invocation Points

Validators may be called:

1. before promotion
2. before state escalation
3. before converting sensitive action outputs into accepted task inputs
4. when stale or retry conditions demand revalidation

## View Binding

Window conflicts happen when views consume mixed truth sources.

### Window 4

Window 4 must bind to meeting control state, not arbitrary discussion text.

Primary sources:

- `meeting state`
- action summary derived from action registry
- phase status
- recent runtime events

Purpose:

- show coordination state
- show what the system is deciding now

### Window 5

Window 5 must bind to task execution state.

Primary sources:

- `current_task`
- task record
- handoff path
- validation state
- stale or blocked indicators

Purpose:

- show what is actively being executed
- show what is preventing completion

## Minimal GitHub v0.1 Runtime Loop

The runtime layer is sufficient for v0.1 only if this loop can run:

1. read demo `meeting state`
2. read demo `action registry`
3. compute eligible actions
4. select `current_task`
5. expose window 4 and window 5 views
6. accept execution result
7. detect `done | blocked | failed | retry | stale`
8. update runtime-visible state

## Runtime Recovery for Backlog-Heavy Systems

When the system starts from a backlog-heavy state, runtime should recover in this order:

1. identify the active meeting
2. identify active actions for that meeting
3. map actions to existing live tasks
4. suppress duplicate queued tasks from immediate selection
5. select one `current_task` under priority rules
6. mark stale or orphaned tasks for later audit instead of letting them pollute current execution

This allows recovery without requiring the full historical queue to be cleaned first.

## Non-Goals for v0.1

- full autonomous multi-agent planning
- dynamic role reassignment
- hidden memory orchestration
- generic file explorer behavior in runtime views
- business-specific workflow customization

## Open Follow-Up

This spec should be followed by:

1. `validator-contract.md`
2. `action-registry.schema.json`
3. `meeting-state.schema.json`
4. `runtime-state-machine.md`
5. `github-v0.1-repo-layout.md`
