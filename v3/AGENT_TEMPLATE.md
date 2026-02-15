# Agent Workflow v3

> Core: Execute `/task` to pick a task, then `/commit` when done.

## Workflow

1. `/init` - First-time init (auto-detect project type)
2. `/task` - Select and execute one task
3. `/verify` - Validate implementation (auto-triggered)
4. `/commit` - Atomic commit (code + task.json + progress.txt)

## Rules

- Only change `passes: false -> true`
- Do NOT commit when blocked, record reason instead
- Never use fake/mock data

## Files

| File | Purpose |
|------|---------|
| task.json | Task definitions with `passes` field |
| progress.txt | Progress log (append only) |
| .agent/commands.json | Build commands |

## Task Selection Priority

1. `passes: false`
2. All `depends_on` tasks have `passes: true`
3. Sort by: `priority` ASC, then `id` ASC

## Blocked Handling

```
BLOCKED:
  task_id: <id>
  reason: <why blocked>
  need: <what's needed>
  done: <what was completed>
```

## Acceptance Criteria Formats

- `command: npm test` - Execute command
- `file: src/index.ts` - Check file exists
- `manual: Review code quality` - Manual verification
