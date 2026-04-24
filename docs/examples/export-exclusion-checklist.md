# Export Exclusion Checklist v0.1

## Status

- Owner: Executor (Codex)
- Date: 2026-04-24
- Scope: A8
- Source meeting: `2026-04-24-pipelineos-github`

## Block Export If

- file contains real local paths
- file contains private client, contract, or business references
- file is part of raw meeting history
- file is part of the dirty task pool
- file is part of unneeded historical handoff backlog

## Export Only After Sanitization

- runtime briefing examples
- action registry examples
- audit report examples
- selector result examples
- scripts with path assumptions removed

## Usually Safe

- protocol docs
- schemas
- sanitized runtime scripts
- demo fixtures

## Rule

When in doubt:

1. do not export the real file
2. create a clean demo replacement
