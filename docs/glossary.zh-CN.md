# PipelineOS 中文术语标注

本文件为中文读者提供术语辅助说明。  
PipelineOS 的正式协议字段仍以英文为准，本文件只用于理解，不改变任何 runtime 行为。

## 核心定位

| English Term | 中文理解 | 说明 |
|---|---|---|
| PipelineOS | 多 Agent 文件协议运行时 | 不是操作系统，而是一个用文件协议协调多个 AI Agent 的工作流运行层。 |
| file-protocol | 文件协议 | Agent 通过固定结构的文件读写状态、任务、报告，而不是只依赖聊天上下文。 |
| multi-agent workflow | 多 Agent 工作流 | 多个 AI Agent 分工协作，例如 Architect、Executor、Validator。 |
| runtime | 运行时 | 系统当前正在运行时的状态、入口、调度和控制逻辑。 |
| coordination layer | 协调层 | 不直接替代 Agent，而是协调多个 Agent 谁先做、做什么、怎么交接。 |

## 状态与事实源

| English Term | 中文理解 | 说明 |
|---|---|---|
| shared truth | 共享事实 | 多个 Agent 都承认并读取的事实来源，避免各自理解不同。 |
| meeting state | 会议状态 | 当前协作会议的状态，例如主题、阶段、参与者、recent events。 |
| action registry | 行动登记表 / 决策行动池 | 记录会议中被接受的行动项，是业务行动的主账本。 |
| runtime briefing | 运行时简报 / 当前入口快照 | 新 Agent 加入时优先读取的当前状态入口。 |
| current state | 当前状态 | 系统此刻的运行状态，不等同于历史记录。 |
| recent events | 最近事件 | 会议中刚发生的重要状态变化，用于追踪上下文。 |

## 行动、任务与调度

| English Term | 中文理解 | 说明 |
|---|---|---|
| action | 行动项 | 从会议决策中产生的可追踪事项，通常进入 action registry。 |
| task | 执行任务 | 从 action 派生出的具体执行单元。 |
| current task | 当前任务 | 当前被调度出来、应该优先执行的任务。 |
| selector | 选择器 | 根据状态和优先级选择下一个 current task 的规则或脚本。 |
| scheduling | 调度 | 决定谁下一步执行、执行哪一项、何时暂停或重试。 |
| priority | 优先级 | 用来决定多个候选 action/task 的执行顺序。 |
| backlog | 待办池 | 尚未执行或尚未进入当前执行状态的行动集合。 |
| task pool | 任务池 | 存放 task 文件的区域，但不一定所有 task 都可信。 |
| live candidate | 活跃候选任务 | 当前仍可被 selector 选中的有效任务。 |

## 节点角色

| English Term | 中文理解 | 说明 |
|---|---|---|
| node | 节点 | 一个参与系统的角色或 Agent。 |
| production node | 生产节点 | 负责生成内容或执行任务，例如 Architect、Executor。 |
| verification node | 验证节点 | 只读检查结果，不直接改状态，例如 Validator。 |
| scheduling node | 调度节点 | 控制流程、状态转换和下一步执行。 |
| Architect | 架构节点 | 负责边界判断、协议设计、系统结构决策。 |
| Executor | 执行节点 | 负责落文件、跑命令、生成具体产物。 |
| Validator | 验证节点 | 负责只读验收、输出 QA 报告。 |
| Host | 主持 / 调度入口 | 管理会议节奏和状态推进的角色。 |

## 验证与失败恢复

| English Term | 中文理解 | 说明 |
|---|---|---|
| validator contract | 验证者契约 | 规定 Validator 只能读什么、输出什么、不能改什么。 |
| qa-report | 质量验证报告 | Validator 的输出文件，用来说明是否通过检查。 |
| failure recovery | 失败恢复 | 当任务失败、阻塞或停滞时，系统如何处理。 |
| blocked | 被阻塞 | 缺少依赖、权限、输入或存在冲突，导致无法继续。 |
| failed | 已失败 | 执行完成但结果无效或不符合要求。 |
| retry | 重试 | 允许在记录原因后再次尝试执行。 |
| stale state | 过期状态 | 文件显示仍在进行，但长时间无更新，不能继续信任。 |
| timeout | 超时 | 判断状态是否过期的时间阈值。 |

## 发布与运行时控制

| English Term | 中文理解 | 说明 |
|---|---|---|
| BUILD | 构建动作 | 生成一个可发布或可验证的快照，例如 build 目录。 |
| PUBLISH | 发布动作 | 将本地成果发布到远端，例如 push 到 GitHub。 |
| runtime control action | 运行时控制动作 | BUILD、PUBLISH、VALIDATE 这类控制系统运行的动作，不等同于业务 action。 |
| runtime-control-actions | 运行时控制动作账本 | 记录 BUILD / PUBLISH 等控制动作发生过什么。 |
| deliverable | 交付物 | 某个 action 或 control action 产生的结果，例如目录、文件、commit。 |
| public snapshot | 公开快照 | 可以对外发布的一版项目内容。 |
| repository | 仓库 | Git 项目仓库。 |
| remote | 远端仓库 | GitHub 上的仓库地址。 |
| commit | 提交 | Git 中记录的一次版本快照。 |

## 容易混淆的概念

### action 和 task

`action` 是会议决策形成的行动项。  
`task` 是为了执行 `action` 而产生的具体任务。

简单理解：

```text
action = 决定要做什么
task = 具体派给谁去做
```

### runtime briefing 和 action registry

`action registry` 是业务行动账本。  
`runtime briefing` 是当前运行入口。

简单理解：

```text
action registry = 项目决定要推进什么
runtime briefing = 系统当前正在推进什么
```

### business action 和 runtime control action

`business action` 是项目要完成的事情。  
`runtime control action` 是系统为了推进项目而做的控制动作。

简单理解：

```text
business action = 项目要完成的事情
runtime control action = 系统为了推进项目而做的控制动作
```

### Architect、Executor、Validator 的区别

三者不是同一种 Agent 的不同说法，而是不同节点职责。

简单理解：

```text
Architect = 定规则、看边界、做结构判断
Executor = 动手做、落文件、跑执行
Validator = 只读验收、出 qa-report
```

## 中文读者建议阅读顺序

如果你是中文读者，建议按这个顺序理解 PipelineOS：

1. 先理解它不是一个 AI Agent，而是多 Agent 之间的协调层。
2. 再理解 `action registry`、`runtime briefing`、`selector` 三个核心文件。
3. 然后理解 `Validator` 为什么必须只读。
4. 最后再看 `failure recovery` 和 `task-pool audit`。
