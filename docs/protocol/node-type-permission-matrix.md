# Node Type Permission Matrix v0.1

**Author**: Claude (Architect)
**Date**: 2026-04-24
**Source action**: A12
**Status**: Draft — pending Codex review

---

## 1. 节点分类（来源：D14）

PipelineOS 中所有参与者（人类或 AI）必须被归入且只归入以下三类节点之一：

| 类型 | 英文标识 | 当前实例 |
|------|----------|----------|
| 生产节点 | `production` | Architect (Claude), Executor (Codex) |
| 验证节点 | `verification` | Validator (Gemini) |
| 调度节点 | `scheduling` | Runtime, Host (Codex 在会议中担任) |

规则：节点类型由系统接纳决定，不由节点自我声明决定（D13）。

---

## 2. 权限矩阵

### 2.1 文件操作权限

| 操作 | 生产节点 | 验证节点 | 调度节点 |
|------|----------|----------|----------|
| 读取 `workspace/shared/` | ✅ | ✅ | ✅ |
| 写入 `workspace/shared/meetings/` | ❌ | ❌ | ✅ |
| 写入 `workspace/shared/action-registry.json` | ❌ | ❌ | ✅ |
| 写入 `workspace/shared/runtime-briefing.json` | ❌ | ❌ | ✅ |
| 写入 `workspace/shared/pipeline-state.json` | ❌ | ❌ | ✅ |
| 写入 `workspace/shared/tasks/` | ❌ | ❌ | ✅ |
| 写入自身 outputs 目录 | ✅ | ✅ | ✅ |
| 写入自身 handoff 目录 | ✅ | ✅ | ✅ |
| 读取其他节点的 handoff 目录 | ✅ | ✅ | ✅ |
| 写入其他节点的 handoff 目录 | ❌ | ❌ | ❌ |

### 2.2 状态迁移权限

| 操作 | 生产节点 | 验证节点 | 调度节点 |
|------|----------|----------|----------|
| 将 action 状态改为 READY / LINKED / DONE | ❌ | ❌ | ✅ |
| 将 action 状态改为 BLOCKED | ❌ | ❌ | ✅ |
| 将 task 状态改为 in_progress / done | ❌ | ❌ | ✅ |
| 将 task 状态改为 blocked / failed / retry | ❌ | ❌ | ✅ |
| 触发 stale 判定 | ❌ | ❌ | ✅ |
| 触发 retry | ❌ | ❌ | ✅ |
| 输出影响调度的建议（不直接执行） | ✅（产出物） | ✅（qa-report） | ✅ |

### 2.3 会议与调度权限

| 操作 | 生产节点 | 验证节点 | 调度节点 |
|------|----------|----------|----------|
| 主持会议 / 推进讨论 | ❌ | ❌ | ✅ |
| 宣布会议阶段切换（discussion → execution） | ❌ | ❌ | ✅ |
| 写入 `02-decisions.md` | ❌ | ❌ | ✅ |
| 写入 `03-actions.md` | ❌ | ❌ | ✅（经用户确认） |
| 选择 current task | ❌ | ❌ | ✅ |
| 调用 Validator | ❌ | ❌ | ✅ |
| 定义系统方向 / 架构边界 | ✅（提案） | ❌ | ✅（裁定） |

### 2.4 产出物权限

| 操作 | 生产节点 | 验证节点 | 调度节点 |
|------|----------|----------|----------|
| 生成协议草案 / 文档 | ✅ | ❌ | ✅ |
| 生成代码 / 脚本 | ✅ | ❌ | ✅ |
| 生成 qa-report | ❌ | ✅（唯一合法产出） | ❌ |
| 将草案提升为正式协议 | ❌ | ❌ | ✅（经用户确认） |
| 将 handoff 内容视为正式系统状态 | ❌ | ❌ | ✅（审核后） |

---

## 3. 跨类型行为禁止清单

以下行为无论由哪类节点发起，均属违规：

1. **伪装为调度节点**：生产节点或验证节点不得自行修改 shared 状态文件
2. **自我提升产出物**：任何节点不得将自己未经 Runtime 审核的 handoff 视为正式系统状态
3. **混用节点角色**：在同一个动作中同时承担生产 + 验证职责（如"我生成并自验证"）
4. **绕过 Runtime 直接写入**：生产节点和验证节点的产出必须经过 handoff 路径，由 Runtime 决定是否接纳
5. **响应非授权调用**：验证节点不得响应非 Runtime 来源的调用请求

---

## 4. 节点权限扩展规则

如果系统需要为某节点增加权限（如赋予生产节点直接写入某个共享文件的权限）：

1. 必须由用户或 Runtime 显式授权
2. 授权必须写入会议决策（`02-decisions.md`）或本矩阵的 v0.x+1 版本
3. 授权不可溯及既往
4. 节点不得自行声明权限扩展

---

## 5. 当前节点权限快照

| 节点 | 类型 | 当前 owner 状态 | 特殊权限备注 |
|------|------|-----------------|--------------|
| Claude | 生产节点（Architect） | 活跃 | 可起草协议，产出进 `workspace/claude/handoff/` |
| Codex | 调度节点（Host）+ 生产节点（Executor） | 活跃 | 本场会议双角色，可写 shared 状态 |
| Gemini | 验证节点（Validator） | 待命 | 仅在 Runtime 调用时激活，产出只有 qa-report |
| 用户 | 超调度节点 | 活跃 | 可覆盖任何节点的权限与决策 |

注：Codex 在本场会议中同时担任 Host（调度节点）和 Executor（生产节点），是经用户明确指定的双角色。这是例外，不是常规模式。

---

## 6. 版本说明

- `v0.1`：初始版本，由 Architect 起草，覆盖 D13 / D14 / D15 / D16 决策要求
- 后续变更须经 Runtime 或用户批准
