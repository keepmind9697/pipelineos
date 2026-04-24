# PipelineOS

**A file-protocol multi-agent workflow runtime.**

PipelineOS is a file-based coordination layer for multiple AI agents.
Instead of relying on separate chat histories, agents collaborate through a shared workspace: meeting state, action registry, runtime briefing, selector results, and validation reports. This lets the system coordinate decisions, choose the next executable task, and recover from blocked or stale work.
For Chinese readers, see [`docs/glossary.zh-CN.md`](docs/glossary.zh-CN.md) for terminology notes.

---

## What problem does this solve?

When multiple AI agents work together, three things break down quickly:

1. **No shared truth** — each agent has its own context, and they diverge
2. **No scheduling discipline** — every agent thinks it should go next
3. **No failure handling** — a blocked task silently stops the system

PipelineOS solves this with a simple file-based protocol. Agents read and write structured files. A runtime layer coordinates who goes next. A validator checks outputs without touching state.

---

## The v0.1 loop

The demo shows one complete coordination loop:

```
meeting notes
→ accepted actions
→ task-pool audit
→ runtime briefing
→ selected current task
→ validator report
```

Start here: [`runtime/examples/demo-v0.1/README.md`](runtime/examples/demo-v0.1/README.md)

---

## Structure

```
PipelineOS/
├── docs/
│   ├── protocol/          # The shared protocol layer
│   │   ├── runtime-spec.md
│   │   ├── current-task-selector.md
│   │   ├── failure-recovery.md
│   │   ├── time-model.md
│   │   ├── validator-contract.md
│   │   ├── node-type-permission-matrix.md
│   │   ├── audit-report-protocol.md
│   │   └── audit-judgment-rules.md
│   ├── runtime/
│   │   └── current-state.md   # The runtime entry point contract
│   └── examples/          # MVP definition and boundary planning
├── runtime/
│   ├── tools/             # Runnable runtime scripts
│   │   ├── task-pool-audit.py         # Read-only task pool auditor
│   │   ├── pipeline-meeting-view.sh   # Window 4: runtime control panel
│   │   └── pipeline-file-view.sh      # Window 5: current execution view
│   └── examples/
│       └── demo-v0.1/     # Clean end-to-end demo fixture
└── BUILD_MANIFEST.md
```

---

## Core concepts

| Concept | What it is |
|---------|------------|
| **Meeting** | A structured collaboration session with agenda, decisions, and actions |
| **Action Registry** | The authoritative list of decisions with priority and state |
| **Runtime Briefing** | The narrow entry point for any new agent joining the system |
| **Current Task Selector** | Picks the next executable task from ready actions using priority and scheduling rules |
| **Validator** | A read-only node that outputs `qa-report` — never touches state |
| **Node types** | Three roles: production (generates), verification (validates), scheduling (controls) |

---

## Three node types

PipelineOS enforces strict separation between node roles:

- **Production nodes** (Architect, Executor): generate content, write to their own output dirs
- **Verification nodes** (Validator): read-only, output only `qa-report`
- **Scheduling nodes** (Runtime, Host): control flow, state transitions, who goes next

No node can act outside its type boundary. See [`docs/protocol/node-type-permission-matrix.md`](docs/protocol/node-type-permission-matrix.md).

---

## Failure recovery

Tasks don't always succeed. PipelineOS has explicit states for this:

- `blocked` — cannot continue due to missing dependency or conflict
- `failed` — execution completed but result is invalid
- `retry` — allowed to re-attempt with a recorded reason

Stale detection runs via `last_update` + `timeout` + `stale_state`. The runtime discovers stuck tasks automatically — they don't silently disappear.

See [`docs/protocol/failure-recovery.md`](docs/protocol/failure-recovery.md).

---

## Getting started

Run commands from the repository root.

**To explore the protocol:**
```
docs/protocol/runtime-spec.md
```

**To run the demo:**
```
runtime/examples/demo-v0.1/README.md
```

**To audit a task pool:**
```bash
python3 runtime/tools/task-pool-audit.py \
  --tasks-dir <your-tasks-dir> \
  --meeting-id <meeting-id> \
  --action-registry <action-registry.json>
```

**To view meeting control state:**
```bash
bash runtime/tools/pipeline-meeting-view.sh
```

---

## What v0.1 is not

- Not a full-featured project management system
- Not a terminal multiplexer
- Not tied to any specific AI provider or SDK
- Not a replacement for git, issue trackers, or CI pipelines

PipelineOS is a coordination layer — it handles *who decides what, when, and how* between agents. What the agents actually do is up to you.

---

## License

MIT
