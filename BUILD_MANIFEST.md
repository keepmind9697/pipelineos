# Build Manifest

Build target: `workspace/builds/pipelineos-v0.1`

Build intent:

- assemble a public-safe PipelineOS v0.1 snapshot
- include accepted protocol docs and runtime-safe scripts
- include a clean demo fixture set that proves the end-to-end loop

Included protocol files:

- `docs/protocol/runtime-spec.md`
- `docs/protocol/failure-recovery.md`
- `docs/protocol/time-model.md`
- `docs/protocol/audit-report-protocol.md`
- `docs/protocol/audit-judgment-rules.md`
- `docs/protocol/audit-decision-matrix.md`
- `docs/protocol/audit-decision-contract.md`
- `docs/protocol/current-task-selector.md`
- `docs/protocol/validator-contract.md`
- `docs/protocol/node-type-permission-matrix.md`
- `docs/runtime/current-state.md`

Included example and planning files:

- `docs/examples/mvp-definition.md`
- `docs/examples/public-private-boundary-map.md`
- `docs/examples/repo-skeleton.md`
- `docs/examples/export-exclusion-checklist.md`

Included runtime files:

- `runtime/tools/task-pool-audit.py`
- `runtime/tools/pipeline-meeting-view.sh`
- `runtime/tools/pipeline-file-view.sh`

Included demo fixture files:

- `runtime/examples/demo-v0.1/00-agenda.md`
- `runtime/examples/demo-v0.1/04-state.json`
- `runtime/examples/demo-v0.1/action-registry.json`
- `runtime/examples/demo-v0.1/runtime-briefing.json`
- `runtime/examples/demo-v0.1/task-pool-audit-report.json`
- `runtime/examples/demo-v0.1/selector-result.json`
- `runtime/examples/demo-v0.1/README.md`

Source traceability:

- runtime spec source: `workspace/executor/outputs/pipelineos-runtime-spec-v0.1.md`
- validator contract source: `workspace/claude/handoff/validator-contract-v0.1.md`
- node permission matrix source: `workspace/claude/handoff/node-type-permission-matrix-v0.1.md`
- selector source: `workspace/executor/outputs/current-task-selector-spec-v0.1.md`
- demo source root: `workspace/executor/outputs/demo-v0.1/`

Explicit exclusions:

- `workspace/shared/tasks/`
- `workspace/shared/meetings/` real meeting records
- `workspace/shared/pipeline-state.json`
- all private role workspaces except accepted protocol handoff inputs copied into this snapshot
