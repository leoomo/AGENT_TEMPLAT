# Select Task

Select the next available task from task.json.

## Selection Logic

1. **Read task.json**
   - If not exists, output: "Run /init first"

2. **Filter eligible tasks**
   ```
   eligible = [
     t for t in tasks
     if t.passes == false
     and all(dep.passes == true for dep in t.depends_on)
   ]
   ```

3. **Sort by priority**
   - Primary: `priority` ascending (1 = highest)
   - Secondary: `id` ascending

4. **Output selected task**
   ```
   === Selected Task ===
   ID: <id>
   Title: <title>
   Priority: <priority>
   Depends on: <list of task ids or "none">

   Description:
   <description>

   Steps:
   1. <step 1>
   2. <step 2>
   ...

   Acceptance Criteria:
   - <criterion 1>
   - <criterion 2>
   ```

5. **Begin implementation**
   - Start working on the first step
   - Update checkpoint.json with current task

## Edge Cases

- **No eligible tasks**: Output "All tasks completed or blocked by dependencies"
- **Blocked task**: Output blocked reason and suggest resolution
- **Circular dependency**: Report error in task.json
