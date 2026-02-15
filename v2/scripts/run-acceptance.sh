#!/bin/bash
# 执行验收标准脚本
# 从 task.json 读取指定任务的验收标准并执行
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# 参数检查
TASK_ID="$1"
if [ -z "$TASK_ID" ]; then
    echo "用法: $0 <task_id>"
    echo ""
    echo "示例:"
    echo "  $0 1        # 执行任务 1 的验收标准"
    echo "  $0 auth-01  # 执行任务 auth-01 的验收标准"
    exit 1
fi

# 检查 task.json 是否存在
if [ ! -f "task.json" ]; then
    log_error "task.json 不存在"
    log_info "请先运行 bash scripts/init-project.sh 初始化项目"
    exit 1
fi

# 检查 Python 是否可用
if ! command -v python3 &>/dev/null; then
    log_error "需要 Python 3 来执行此脚本"
    exit 1
fi

log_info "执行任务 $TASK_ID 的验收标准..."
echo ""

# 执行验收标准
python3 << PYTHON_SCRIPT
import json
import subprocess
import sys
from pathlib import Path

task_id = "$TASK_ID"
task_file = Path("task.json")

try:
    data = json.loads(task_file.read_text())
except json.JSONDecodeError as e:
    print(f"❌ task.json 格式错误: {e}")
    sys.exit(1)

# 查找任务
task = None
for t in data.get("tasks", []):
    if str(t.get("id")) == str(task_id):
        task = t
        break

if not task:
    print(f"❌ 未找到任务: {task_id}")
    sys.exit(1)

print(f"📋 任务: {task.get('title', 'N/A')}")
print(f"   ID: {task.get('id')}")
print("")

# 获取验收标准
criteria = task.get("acceptance_criteria", [])
if not criteria:
    print("⚠️  未定义验收标准 (acceptance_criteria)")
    print("   建议在 task.json 中添加验收标准")
    sys.exit(0)

print(f"📝 验收标准 ({len(criteria)} 项):")
print("")

passed = 0
failed = 0
skipped = 0

for i, criterion in enumerate(criteria, 1):
    print(f"--- 标准 {i}/{len(criteria)} ---")

    if isinstance(criterion, dict):
        # 字典格式的验收标准
        crit_type = criterion.get("type", "command")
        crit_value = criterion.get("value", criterion.get("command", ""))

        if crit_type == "command":
            criterion = f"command: {crit_value}"
        elif crit_type == "manual":
            print(f"  ⚠️  [手动验证] {crit_value}")
            skipped += 1
            continue
        elif crit_type == "file_exists":
            if Path(crit_value).exists():
                print(f"  ✓ 文件存在: {crit_value}")
                passed += 1
            else:
                print(f"  ✗ 文件不存在: {crit_value}")
                failed += 1
            continue

    if criterion.startswith("command:"):
        cmd = criterion[8:].strip()
        print(f"  执行: {cmd}")

        try:
            result = subprocess.run(
                cmd,
                shell=True,
                capture_output=True,
                text=True,
                timeout=300  # 5 分钟超时
            )

            if result.returncode == 0:
                print(f"  ✓ 通过")
                passed += 1
                if result.stdout.strip():
                    for line in result.stdout.strip().split("\n")[:5]:
                        print(f"    {line}")
            else:
                print(f"  ✗ 失败 (exit code: {result.returncode})")
                failed += 1
                if result.stderr.strip():
                    for line in result.stderr.strip().split("\n")[:5]:
                        print(f"    {line}")
        except subprocess.TimeoutExpired:
            print(f"  ✗ 超时 (>5分钟)")
            failed += 1
        except Exception as e:
            print(f"  ✗ 执行错误: {e}")
            failed += 1

    elif criterion.startswith("file:"):
        filepath = criterion[5:].strip()
        if Path(filepath).exists():
            print(f"  ✓ 文件存在: {filepath}")
            passed += 1
        else:
            print(f"  ✗ 文件不存在: {filepath}")
            failed += 1

    elif criterion.startswith("manual:"):
        desc = criterion[7:].strip()
        print(f"  ⚠️  [手动验证] {desc}")
        skipped += 1

    else:
        # 纯文本描述，需要手动验证
        print(f"  ⚠️  [手动验证] {criterion}")
        skipped += 1

    print("")

# 汇总
print("=" * 40)
print("           验收结果汇总")
print("=" * 40)
print(f"  ✓ 通过: {passed}")
print(f"  ✗ 失败: {failed}")
print(f"  ⚠ 跳过: {skipped}")
print("=" * 40)

if failed > 0:
    print("")
    print("❌ 验收未通过，请修复失败项后重新运行")
    sys.exit(1)
elif skipped > 0:
    print("")
    print("⚠️  部分验收标准需要手动验证")
    sys.exit(0)
else:
    print("")
    print("✅ 所有验收标准通过!")
    sys.exit(0)
PYTHON_SCRIPT
