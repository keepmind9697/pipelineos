# Contributing to PipelineOS / 贡献指南

> v0.1 · 2026-04-24

---

## How to Clone and Run the Demo / 克隆与运行演示

```bash
git clone https://github.com/keepmind9697/pipelineos.git
cd pipelineos
```

The demo fixtures are in `runtime/examples/demo-v0.1/`. No installation required.

演示文件位于 `runtime/examples/demo-v0.1/`，无需安装任何依赖。

**Walkthrough / 阅读顺序：**

1. `00-agenda.md` — Meeting agenda / 会议议程
2. `action-registry.json` — Action list / 行动清单
3. `04-state.json` — Current meeting state / 当前会议状态
4. `selector-result.json` — Current task selection result / 当前任务选择结果
5. `README.md` — Full loop explanation / 完整闭环说明

> The demo is intentionally static — designed to be read, not executed as a live system.
>
> 演示为静态设计，用于阅读理解，不作为活跃系统运行。

---

## How to Open Issues / 如何提交 Issue

### Bug Report / 缺陷报告

Use when the protocol, demo, or documentation does not behave as described.

当协议、演示或文档与描述不符时使用。

Please include / 请包含：

- Affected file or section / 受影响的文件或章节
- Expected behavior / 预期行为
- Actual behavior or missing content / 实际行为或缺失内容
- Steps to reproduce if applicable / 可复现步骤（如适用）

### Feature Request / 功能请求

Use when proposing an extension beyond the current scope.

当你希望提出超出当前范围的扩展时使用。

Please include / 请包含：

- The problem you are solving / 你要解决的问题
- Your proposed approach (a rough sketch is fine) / 你的思路（粗略草案即可）
- Affected layer: protocol / runtime / demo / tooling
- 影响层级：协议层 / 运行时层 / 演示层 / 工具层

> v0.1 feature requests are tracked for reference. Acceptance into the roadmap requires maintainer approval.
>
> v0.1 的功能请求会被记录备案，纳入路线图需经维护者确认。

---

## Pull Request Guidelines / PR 规范

1. **One PR, one concern.** Do not mix protocol changes with tooling or documentation updates.
   **一个 PR，一件事。** 不要将协议变更与工具或文档更新混在同一个 PR 中。

2. **Stay in scope.** Check `docs/examples/mvp-definition.md` before proposing changes. Out-of-scope PRs will be closed without review.
   **保持在范围内。** 提交前请先阅读 MVP 定义文件，超出范围的 PR 将直接关闭。

3. **No live system data.** Do not include real paths, meeting records, task pool contents, or private workspace artifacts.
   **不包含真实系统数据。** 禁止提交真实路径、会议记录、任务池内容或私有工作区文件。

4. **Match existing format.** Follow the file structure and naming conventions already in the repo. Do not introduce new top-level directories without prior discussion.
   **遵循现有格式。** 文件结构和命名需与仓库保持一致，新增顶层目录须事先讨论。

5. **Write a clear description.** Explain what changed and why. Link to the relevant issue if one exists.
   **写清楚描述。** 说明改了什么、为什么改，如有对应 Issue 请关联。

---

## What Not to Include / 不得包含的内容

> Reference: `docs/examples/export-exclusion-checklist.md`
>
> 参考：`docs/examples/export-exclusion-checklist.md`

| Category / 类别 | Examples / 示例 |
|---|---|
| Real local paths / 真实本地路径 | `/Users/yourname/...` |
| Private meeting records / 私有会议记录 | Raw agenda files, internal decision logs |
| Raw task pool contents / 原始任务池 | Unfiltered `tasks/` directories |
| Client or business references / 客户或业务信息 | Customer names, contract details |
| Historical handoff artifacts / 历史 handoff 堆积 | Unprocessed executor backlogs |
| Environment-specific assumptions / 环境假设 | Hardcoded paths, machine-specific config |

When in doubt: do not include the real file. Create a sanitized demo replacement instead.

如有疑问：不要直接包含真实文件，改为制作净化后的演示替代物。

---

## Maintainer Review Note / 维护者说明

- PRs that follow the guidelines above will be reviewed within a reasonable time.
  符合上述规范的 PR 将在合理时间内得到审核。

- PRs that do not follow the guidelines may be closed without detailed feedback.
  不符合规范的 PR 可能直接关闭，不附详细反馈。

- If you are unsure whether a contribution is in scope, open an issue first before writing code or docs.
  如果不确定贡献是否在范围内，请先开 Issue 确认，再动手写代码或文档。
