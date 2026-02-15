# {{project_name}} - Agent 工作流指令

## Project Context

{{project_description}}

---

## ⚙️ 项目配置（Configuration）

> 使用本模板时，替换所有 `{{variable}}` 为项目实际值。

```yaml
# === 项目基本信息 ===
project_name: "{{project_name}}"
project_description: "{{project_description}}"

# === 文件路径 ===
task_file: "{{task_file}}"              # 默认: task.json
progress_file: "{{progress_file}}"      # 默认: progress.txt
init_command: "{{init_command}}"        # 例: ./init.sh, make setup, uv sync && uv run dev

# === 工作目录 ===
working_directory: "{{working_directory}}"  # 例: ., ./frontend, ./src

# === 构建与检查命令 ===
type_check_command: "{{type_check_command}}"  # 例: npx tsc --noEmit, mypy ., cargo check
lint_command: "{{lint_command}}"              # 例: npm run lint, ruff check ., golangci-lint run
build_command: "{{build_command}}"            # 例: npm run build, cargo build, go build ./...
test_command: "{{test_command}}"              # 例: npm test, pytest, go test ./...

# === 浏览器测试（仅 UI 项目需要）===
browser_test_tool: "{{browser_test_tool}}"   # 例: MCP Playwright, Cypress, none
dev_server_url: "{{dev_server_url}}"         # 例: http://localhost:3000

# === Git ===
commit_message_template: "{{commit_message_template}}"  # 默认: "[task title] - completed"

# === 测试分级触发条件（可自定义）===
heavy_test_triggers:
  - "新建页面或路由"
  - "重写组件"
  - "修改核心交互逻辑"
  - "修改 API 端点"
  - "修改数据库 schema"

light_test_triggers:
  - "修复 bug"
  - "调整样式"
  - "添加辅助函数"
  - "更新文档或配置"
  - "重构不改变行为的代码"

# === 编码规范（项目特定）===
coding_conventions:
  - "{{convention_1}}"  # 例: TypeScript strict mode
  - "{{convention_2}}"  # 例: 函数式组件 + Hooks
  - "{{convention_3}}"  # 例: Tailwind CSS
```

---

## MANDATORY: Agent 工作流

每个新 agent session 必须严格按以下 6 步执行。

### Step 1: 初始化环境

```bash
{{init_command}}
```

**不可跳过。** 确认环境就绪后再继续。

### Step 2: 选择任务

读取 `{{task_file}}`，选择一个任务。

选择标准（按优先级排序）：
1. `passes: false` 的任务
2. `depends_on` 中的前置任务必须全部 `passes: true`
3. `priority` 值最小（1 = 最高优先级）的任务
4. 如有多个候选，选 `id` 最小的

**每个 session 只做一个任务。**

### Step 3: 实现

- 仔细阅读任务的 `description` 和 `steps`
- `steps` 既是实现清单，也是验收标准
- 遵循项目现有代码风格和约定
- 不要引入不必要的依赖

### Step 4: 测试

**强制测试要求（MANDATORY）：**

#### 重度测试（Heavy）

触发条件：新建页面、重写组件、修改核心交互、修改 API、修改 schema

- 必须在浏览器/运行环境中测试（使用 {{browser_test_tool}}）
- 验证页面/功能能正确加载和运行
- 验证交互功能（表单提交、按钮点击等）
- 截图或日志确认结果正确

#### 轻度测试（Light）

触发条件：修复 bug、调整样式、添加辅助函数、更新配置

- 可以使用单元测试或 lint/build 验证
- 如有疑虑，升级为重度测试

#### 通用基线（所有修改必须通过）

```bash
{{type_check_command}}   # 类型检查
{{lint_command}}          # 代码规范
{{build_command}}         # 构建
```

**测试清单：**
- [ ] 类型检查通过
- [ ] lint 通过
- [ ] build 成功
- [ ] 功能验证通过（重度测试时必须在浏览器/运行环境中验证）

### Step 5: 记录进度

将工作内容追加到 `{{progress_file}}`。

根据任务类型选择对应模板（见下方「进度日志格式」）。

### Step 6: 原子提交

**所有更改必须在同一个 commit 中提交：**

1. 更新 `{{task_file}}`：将任务的 `passes` 从 `false` 改为 `true`
2. 更新 `{{progress_file}}`：记录工作内容
3. 一次性提交：

```bash
git add .
git commit -m "{{commit_message_template}}"
```

**规则：**
- 只有在所有 steps 都验证通过后才标记 `passes: true`
- 永远不要删除或修改任务的 `id`、`title`、`description`、`steps`
- 永远不要从列表中移除任务
- 代码 + `{{progress_file}}` + `{{task_file}}` 必须在同一个 commit

---

## ⚠️ 阻塞处理（Blocking Protocol）

**如果任务无法完成或需要人工介入，必须遵循以下规则。**

### 阻塞类别

1. **缺少环境配置**：API 密钥未填写、外部服务未创建、.env 缺失
2. **外部依赖不可用**：第三方 API 宕机、需要人工 OAuth 授权、需要付费服务
3. **测试无法进行**：需要真实账号、依赖未部署的外部系统、需要特定硬件

### 禁止（DO NOT）

- ❌ 提交 git commit
- ❌ 将 `passes` 设为 `true`
- ❌ 假装任务已完成
- ❌ 使用模拟数据或虚假数据欺骗验证

### 必须（DO）

- ✅ 在 `{{progress_file}}` 中记录当前进度和阻塞原因
- ✅ 输出结构化阻塞信息（格式见下）
- ✅ 停止任务，等待人工介入

### 阻塞信息格式

```
🚫 任务阻塞 - 需要人工介入

**当前任务**: [task title] (id: [task id])

**已完成的工作**:
- [已完成的代码/配置]

**阻塞原因**:
- [具体说明为什么无法继续]

**阻塞类别**: [缺少环境配置 / 外部依赖不可用 / 测试无法进行]

**需要人工帮助**:
1. [具体的步骤 1]
2. [具体的步骤 2]

**解除阻塞后**:
- 运行 [命令] 继续任务
```

---

## 📋 进度日志格式（Progress Log Templates）

### 标准任务模板

```
## [Date] - Task [id]: [task title]

### What was done:
- [具体的代码/配置变更]

### Testing:
- [测试方式和验证结果]

### Notes:
- [对后续 agent 有用的信息、决策、注意事项]
```

### Bug 修复模板

```
## [Date] - Bug Fix: [问题简述]

### 问题描述:
- [用户报告的现象]

### 根本原因:
- [分析出的根因]

### What was done:
- [修复的具体内容]

### Testing:
- [验证修复有效的方式]

### Notes:
- [经验教训、相关联的组件、防止复发的建议]
```

### 阻塞记录模板

```
## [Date] - 🚫 阻塞: Task [id] - [task title]

### 已完成的工作:
- [已完成的部分]

### 阻塞原因:
- [为什么无法继续]

### 需要人工操作:
1. [步骤]

### 教训:
- [从这次阻塞中学到的]
```

---

## 📦 task.json 模板

```jsonc
{
  "project": "{{project_name}}",
  "description": "{{project_description}}",
  "tasks": [
    {
      "id": 1,
      "title": "任务标题",
      "description": "任务描述 - 要达成什么目标",
      "priority": 1,           // 1(最高) - 5(最低)
      "depends_on": [],        // 前置任务 id 列表，例: [1, 2]
      "steps": [
        "步骤1 - 同时也是验收标准1",
        "步骤2 - 同时也是验收标准2"
      ],
      "passes": false          // 只能从 false → true，不可逆
    },
    {
      "id": 2,
      "title": "依赖前一个任务的任务",
      "description": "需要任务1完成后才能开始",
      "priority": 1,
      "depends_on": [1],
      "steps": [
        "步骤1",
        "步骤2"
      ],
      "passes": false
    }
  ]
}
```

**task.json 规则：**
- `id` 全局唯一，递增
- `steps` 既是实现指南，也是验收标准 — 所有 steps 通过才能标记 `passes: true`
- `passes` 只能从 `false` 翻转为 `true`，不可逆
- 不可删除任务、不可修改 `id`/`title`/`description`/`steps`
- `depends_on` 中的所有任务必须 `passes: true` 才能开始当前任务
- `priority` 用于同级任务的排序，数字越小优先级越高

---

## 📁 项目结构

```
/
├── CLAUDE.md              # Agent 工作流指令（本文件）
├── {{task_file}}          # 任务定义（唯一真相源）
├── {{progress_file}}      # 进度日志
├── init.sh / Makefile     # 初始化脚本（对应 {{init_command}}）
└── {{working_directory}}/ # 项目代码
    └── ...
```

## 常用命令

```bash
# 在 {{working_directory}}/ 下执行
{{type_check_command}}    # 类型检查
{{lint_command}}           # 代码规范检查
{{build_command}}          # 构建
{{test_command}}           # 运行测试
```

## 编码规范

{{coding_conventions}}

---

## 核心规则（Key Rules）

1. **每 session 一个任务** — 专注完成一个任务
2. **测试后才能标记完成** — 所有 steps 必须验证通过
3. **重度修改必须环境测试** — 新建页面/核心交互必须在浏览器或运行环境中验证
4. **记录到 progress log** — 帮助后续 agent 理解上下文
5. **原子提交** — 代码 + {{progress_file}} + {{task_file}} 在同一个 commit
6. **不可删除任务** — 只能将 `passes: false` 翻转为 `true`
7. **阻塞时停止** — 需要人工介入时，不提交、不伪造，输出阻塞信息并停止
8. **不使用假数据** — 禁止用模拟数据或虚假数据绕过验证
9. **尊重依赖** — `depends_on` 中的前置任务未完成时，不可开始当前任务
