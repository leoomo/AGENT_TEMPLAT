# Verify Implementation

Verify the implementation of the current task.

## Verification Steps

1. **Run standard checks** (from .agent/commands.json)
   - typecheck (if available)
   - lint (if available)
   - build (if available)

2. **Execute acceptance_criteria**
   - `command: <cmd>` -> Execute command, check exit code
   - `file: <path>` -> Check file exists
   - `manual: <desc>` -> Output as manual verification needed

3. **Run tests** (if applicable)
   - From .agent/commands.json test command
   - Report pass/fail with details

4. **Browser testing** (if web project)
   - Use Playwright/MCP for visual verification
   - Check key user flows

5. **Output results**
   ```
   === Verification Results ===

   Standard Checks:
     typecheck: PASS
     lint: PASS
     build: PASS

   Acceptance Criteria:
     [✓] command: npm test
     [✓] file: src/index.ts
     [!] manual: Review code quality

   Summary: 2/3 automated checks passed
   Manual verification required: 1 item
   ```

## Failure Handling

- If any automated check fails, output detailed error
- Do NOT mark task as passed
- Suggest fixes based on error output
