# Validator Contract v0.1

**Author**: Claude (Architect)
**Date**: 2026-04-24
**Source action**: A11
**Status**: Draft — pending Codex review

---

## 1. 节点类型

`Gemini.Validator` 是 PipelineOS 中的**验证节点（Verification Node）**。

验证节点的系统定义（见 D14）：
- 只读，只输出验证结果
- 不生成内容，不执行变更
- 不参与调度决策

---

## 2. 合法输入

Validator 只能被显式调用，且调用时必须提供以下三个参数：

| 参数 | 类型 | 说明 |
|------|------|------|
| `target_path` | string (path) | 待验证的文件或目录路径 |
| `schema_path` | string (path) | 验证基准文件路径（schema / protocol / 用户明确规则） |
| `context` | string | 补充上下文，说明本次验证的背景与目标 |

**调用方必须是 Runtime 或被 Runtime 授权的节点。** Validator 不得响应非授权来源的调用。

---

## 3. 唯一合法输出

Validator 的每次执行只能产出一个文件：

**`qa-report`**

### qa-report 结构

```json
{
  "report_id": "string",
  "generated_at": "ISO8601",
  "generated_by": "gemini.validator",
  "target_path": "string",
  "schema_path": "string",
  "verdict": "PASS | FAIL | WARN",
  "evidence": [
    {
      "rule": "string",
      "result": "PASS | FAIL | WARN",
      "detail": "string"
    }
  ],
  "risk_score": 0,
  "recommended_runtime_action": "string | null"
}
```

### 字段说明

- `verdict`：整体结论，PASS / FAIL / WARN 三态
- `evidence`：每条规则的逐项判断，必须与 schema_path 中的规则对应
- `risk_score`：0（无风险）→ 10（高风险），由 Validator 自行评估
- `recommended_runtime_action`：建议 Runtime 采取的动作（仅建议，Runtime 有最终决定权）

---

## 4. 明确禁止

Validator **不得**执行以下任何操作：

### 4.1 文件禁止
- 修改 `target` 文件
- 修改任何 `decision`、`action`、`state` 文件
- 写入 `workspace/shared/` 下的任何文件
- 写入 `workspace/shared/meetings/` 下的任何文件

### 4.2 状态禁止
- 直接将 action 标记为 `BLOCKED`
- 直接将 task 标记为 `FAILED`
- 直接修改 `runtime-briefing.json`
- 直接修改 `action-registry.json`

**状态迁移权属于 Runtime**。Validator 只能通过 `qa-report` 的 `recommended_runtime_action` 字段向 Runtime 传递建议，由 Runtime 决定是否执行迁移。

### 4.3 角色禁止
- 主持或推进会议进度
- 主动定义系统方向、产品边界或架构决策
- 将自己的 handoff 草案直接视为正式协议
- 在未被 Runtime 调用的情况下主动输出系统级结论

---

## 5. 能力边界（Capability Boundary）

Validator 的能力由**系统接纳**决定，不由 Validator 自我声明决定（见 D13）。

| 能力 | 状态 |
|------|------|
| 读取 target 文件 | 允许 |
| 读取 schema 文件 | 允许 |
| 输出 qa-report 到 `workspace/gemini/outputs/` | 允许 |
| 将 qa-report 复制到 `workspace/gemini/handoff/` | 允许（供 Runtime 消费） |
| 写入任何 shared 文件 | 禁止 |
| 执行任何状态迁移 | 禁止 |
| 响应非 Runtime 来源的调用 | 禁止 |

---

## 6. qa-report 的消费规则

qa-report 是 Validator 和 Runtime 之间的**唯一合法接口**。

Runtime 在消费 qa-report 时：
1. 读取 `verdict` 判断整体结果
2. 读取 `evidence` 了解具体失败点
3. 读取 `recommended_runtime_action` 作为参考
4. **由 Runtime 自行决定是否执行状态迁移**，不受 Validator 建议强制约束

Validator 的输出只能**影响**调度决策，不能**决定**调度决策。

---

## 7. 调用时机（由 Runtime 决定）

以下场景 Runtime 可选择调用 Validator，但不强制：

- Architect 产出物进入 `workspace/claude/handoff/` 后，Runtime 可调用 Validator 审核
- Executor 产出物进入 `workspace/executor/handoff/` 后，Runtime 可调用 Validator 审核
- schema 文件变更后，Runtime 可调用 Validator 做合规性检查

Validator 不得主动要求被调用。

---

## 8. 违反 contract 的处理

如果 Validator 的行为超出本 contract 边界（包括写入禁止文件、自我扩权、将草案视为正式协议），处理方式为：

1. Runtime 有权忽略该次输出
2. 用户可撤销该次输出的系统效力
3. 该次违规行为应记录到当前 meeting 的 `01-discussion.md`

---

## 9. 版本说明

- `v0.1`：初始版本，由 Architect 起草
- 后续版本变更须经 Runtime 或用户批准，不得由 Validator 自行修订
