# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目目标

此项目用于 **研究和探索 Agent 自动化执行的最佳提示词工程**。核心目标：

- 探索如何通过提示词设计让 AI Agent 可靠地完成复杂软件开发任务
- 对比不同提示词策略的效果（v1 详细版 vs v2 精简版）
- 研究如何在有限的 Context Window 中最大化指令效率
- 建立可复用的 Agent 工作流模板

## 项目性质

这是一个 **Agent 工作流模板仓库**，包含两套可复用的 AI Agent 指令模板，用于指导 Agent 完成软件开发任务。模板本身不是可执行代码，而是被复制到其他项目中使用的配置文件。

## 版本对比与实验

| 维度 | v1 (原始版) | v2 (精简版) |
|------|------------|------------|
| Token 占用 | ~8000+ | ~600 |
| 配置方式 | 模板变量手动替换 | 脚本自动检测 |
| Context 预留 | 较少 | 最大化 |
| 适用场景 | 精细控制需求 | 大型项目、复杂任务 |

**实验假设**: v2 通过将详细逻辑外部化到脚本，可以在保持工作流完整性的同时，为项目代码上下文预留更多 Context 空间。

## 版本结构

```
v1/  # 原始版 - 模板变量方式 (~8000 tokens)
v2/  # 精简版 - 脚本驱动方式 (~600 tokens)
```

## v2 脚本测试

修改 v2/scripts/ 后，测试脚本：

```bash
cd v2
bash scripts/init-project.sh      # 测试初始化
bash scripts/validate-env.sh      # 测试环境验证
python3 scripts/task-analyzer.py  # 测试任务分析
```

## JSON Schema 验证

修改 v2/schemas/task.schema.json 后，验证模板：

```bash
python3 -c "
import json
from jsonschema import validate
schema = json.load(open('v2/schemas/task.schema.json'))
data = json.load(open('v2/templates/task.json.example'))
validate(instance=data, schema=schema)
print('Schema valid')
"
```

## task.json 核心字段

| 字段 | 必需 | 说明 |
|------|------|------|
| id | ✓ | 唯一标识 |
| title | ✓ | 任务标题 |
| steps | ✓ | 实现步骤（也是验收标准）|
| passes | ✓ | 是否通过（只能 false→true）|
| priority | | 优先级 1-5 |
| depends_on | | 前置任务 ID 列表 |
| acceptance_criteria | | 验收标准（支持 `command:`, `file:`, `manual:` 前缀）|
| blocked | | 是否阻塞 |
| blocked_reason | | 阻塞原因 |

## 验收标准格式

```json
"acceptance_criteria": [
  "command: npm test",           // 执行命令
  "file: src/index.ts",          // 检查文件存在
  "manual: 人工审查代码质量"      // 手动验证
]
```

## 核心设计原则

1. **passes 单向流转**: 只能从 `false` 变为 `true`，不可逆
2. **依赖尊重**: `depends_on` 中的任务未完成时，当前任务不可开始
3. **原子提交**: 代码 + task.json + progress.txt 必须在同一 commit
4. **阻塞时停止**: 不提交、不伪造数据、输出结构化阻塞信息
