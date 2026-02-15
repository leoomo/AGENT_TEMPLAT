# Agent Template

Agent 工作流模板，用于指导 AI Agent 完成软件开发任务。

## 版本

### v1 - 原始版（半自动化）

- 路径: `v1/AGENT_TEMPLATE.md`
- 特点: 模板变量 + 手动配置
- 适用: 需要精细控制每个步骤的项目
- Token 占用: ~8000+ tokens

### v2 - 精简版（高度自动化）

- 路径: `v2/AGENT_TEMPLATE.md`
- 特点: 脚本驱动 + 自动检测
- 适用: 追求最大 Context 效率的项目
- Token 占用: ~600 tokens

```
v2/
├── AGENT_TEMPLATE.md       # 精简核心指令
├── scripts/
│   ├── init-project.sh     # 项目初始化
│   ├── validate-env.sh     # 环境验证
│   ├── run-acceptance.sh   # 验收执行
│   └── task-analyzer.py    # 任务分析
├── templates/
│   ├── task.json.example   # 任务模板
│   └── progress.md.template
└── schemas/
    └── task.schema.json    # JSON Schema
```

## 使用方式

### v1 使用

1. 复制 `v1/AGENT_TEMPLATE.md` 到项目根目录
2. 替换所有 `{{variable}}` 为项目实际值
3. 重命名为 `CLAUDE.md`

### v2 使用

1. 复制整个 `v2/` 目录内容到项目根目录
2. 运行 `bash scripts/init-project.sh`
3. 编辑 `task.json` 定义任务

## Context 预算对比

| 版本 | 模板大小 | 可用于项目上下文 |
|------|---------|-----------------|
| v1 | ~8000+ tokens | 较少 |
| v2 | ~600 tokens | 最大化 |
