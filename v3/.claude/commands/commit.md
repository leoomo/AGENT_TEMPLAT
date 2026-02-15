# Atomic Commit

Commit the completed task with all related files.

## Pre-commit Checks

1. **Verify task completion**
   - All acceptance_criteria passed OR manual items verified
   - No blocking issues

2. **Verify no broken state**
   - typecheck passes (if configured)
   - build passes (if configured)

## Commit Steps

1. **Update task.json**
   - Set `passes: true` for completed task
   - Do NOT modify any other field

2. **Append to progress.txt**
   ```
   ## [YYYY-MM-DD] - Task <id>: <title>

   ### What was done:
   - <change 1>
   - <change 2>

   ### Testing:
   - typecheck: PASS
   - lint: PASS
   - build: PASS
   - tests: PASS

   ### Notes:
   - <any notes for future reference>
   ```

3. **Stage files**
   ```bash
   git add task.json progress.txt <modified files>
   ```

4. **Create commit**
   ```
   <title>

   - <key change 1>
   - <key change 2>

   Task: #<id>
   ```

5. **Update checkpoint.json**
   ```json
   {"current_task": null, "completed_steps": ["<id>"]}
   ```

## Blocked Task Handling

If task is blocked:
- Do NOT commit
- Update task.json with:
  ```json
  {
    "blocked": true,
    "blocked_reason": "<why blocked>"
  }
  ```
- Append to progress.txt with blocked template
- Output structured BLOCKED message
