#!/bin/bash
# Session Start Script
# Auto-executed at the beginning of each Claude Code session
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "======================================"
echo "       Session Start - v3"
echo "======================================"
echo ""

# Show current directory
echo -e "${BLUE}PWD:${NC} $(pwd)"
echo ""

# Show recent commits
echo -e "${BLUE}Recent commits:${NC}"
git log --oneline -5 2>/dev/null || echo "  (no commits yet)"
echo ""

# Show task status
echo -e "${BLUE}Task Status:${NC}"
if [ -f "task.json" ]; then
    python3 << 'PYTHON_SCRIPT' 2>/dev/null || echo "  (unable to parse task.json)"
import json
from pathlib import Path

try:
    data = json.loads(Path("task.json").read_text())
    tasks = data.get("tasks", [])
    total = len(tasks)
    completed = sum(1 for t in tasks if t.get("passes", False))
    blocked = sum(1 for t in tasks if t.get("blocked", False))

    print(f"  Total: {total} | Completed: {completed} | Blocked: {blocked}")

    # Show next available task
    completed_ids = {t["id"] for t in tasks if t.get("passes", False)}
    for t in sorted(tasks, key=lambda x: (x.get("priority", 3), x.get("id", 0))):
        if not t.get("passes", False) and not t.get("blocked", False):
            deps = t.get("depends_on", [])
            if all(d in completed_ids for d in deps):
                print(f"\n  Next: Task {t['id']} - {t['title']}")
                break
except Exception:
    pass
PYTHON_SCRIPT
else
    echo "  task.json not found - run /init first"
fi

echo ""
echo -e "${GREEN}Ready. Use /task to select a task.${NC}"
echo ""
