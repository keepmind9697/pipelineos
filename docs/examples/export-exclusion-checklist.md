# Export Exclusion Checklist v0.1

中文说明：本文件用于说明哪些内容不能直接导出到公开仓库，避免把私有工作区痕迹带入 GitHub。

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

中文理解：

- 包含真实本地路径的文件不得导出
- 包含客户、合同、业务隐私引用的文件不得导出
- 原始会议历史、脏任务池、历史 handoff 堆积不得直接导出

## Export Only After Sanitization

- runtime briefing examples
- action registry examples
- audit report examples
- selector result examples
- scripts with path assumptions removed

中文理解：这类内容只有在去除真实路径、私有上下文和环境假设之后，才能作为公开示例导出。

## Usually Safe

- protocol docs
- schemas
- sanitized runtime scripts
- demo fixtures

中文理解：协议文档、schema、已净化脚本和 demo fixture 通常是公开仓库中最安全的部分。

## Rule

When in doubt:

1. do not export the real file
2. create a clean demo replacement

中文规则：

1. 不直接导出真实文件
2. 改为制作一个干净的 demo 替代物
