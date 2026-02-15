# Initialize Project

Initialize the agent workflow for this project.

## Steps

1. **Detect project type**
   - Check for `package.json` -> Node.js
   - Check for `pyproject.toml` or `requirements.txt` -> Python
   - Check for `Cargo.toml` -> Rust
   - Check for `go.mod` -> Go

2. **Create .agent directory structure**
   ```
   .agent/
   ├── commands.json      # Build/test commands
   └── checkpoint.json    # Session state
   ```

3. **Generate commands.json based on project type**

   For Node.js (detect npm/yarn/pnpm):
   ```json
   {
     "install": "npm install",
     "typecheck": "npx tsc --noEmit",
     "lint": "npm run lint",
     "build": "npm run build",
     "test": "npm test",
     "dev": "npm run dev"
   }
   ```

   For Python (detect uv/poetry/pip):
   ```json
   {
     "install": "uv sync",
     "typecheck": "mypy .",
     "lint": "ruff check .",
     "build": "uv build",
     "test": "pytest",
     "dev": "uv run dev"
   }
   ```

4. **Copy task.json template** (if not exists)
   - Copy from `templates/task.json.example` to `task.json`

5. **Create progress.txt** (if not exists)
   - Empty file for progress logging

6. **Initialize checkpoint.json**
   ```json
   {"current_task": null, "completed_steps": []}
   ```

7. **Output next steps**
   - Tell user to edit task.json
   - Suggest running `/task` to select first task
