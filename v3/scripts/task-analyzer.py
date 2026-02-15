#!/usr/bin/env python3
"""任务复杂度分析工具

分析 task.json 中的任务，识别潜在问题：
- 过于复杂的任务（建议拆分）
- 依赖循环
- 缺失的依赖引用
"""

import json
import sys
from collections import defaultdict
from pathlib import Path


def load_tasks(task_file: Path) -> dict:
    """加载任务文件"""
    if not task_file.exists():
        print(f"❌ 文件不存在: {task_file}")
        sys.exit(1)

    try:
        return json.loads(task_file.read_text())
    except json.JSONDecodeError as e:
        print(f"❌ JSON 格式错误: {e}")
        sys.exit(1)


def analyze_complexity(data: dict) -> None:
    """分析任务复杂度"""
    print("\n📊 任务复杂度分析")
    print("=" * 50)

    tasks = data.get("tasks", [])
    if not tasks:
        print("⚠️  没有定义任何任务")
        return

    issues = []

    for task in tasks:
        task_id = task.get("id", "?")
        title = task.get("title", "无标题")
        steps = task.get("steps", [])
        step_count = len(steps)
        criteria = task.get("acceptance_criteria", [])

        # 复杂度评估
        if step_count == 0:
            status = "⚠️ "
            issues.append(f"Task {task_id}: 没有定义步骤")
        elif step_count > 10:
            status = "🔴"
            issues.append(f"Task {task_id}: 步骤过多 ({step_count})，建议拆分")
        elif step_count > 5:
            status = "🟡"
        else:
            status = "✅"

        print(f"{status} Task {task_id}: {title}")
        print(f"   步骤: {step_count} | 验收标准: {len(criteria)} | 优先级: {task.get('priority', 3)}")

    print(f"\n总计: {len(tasks)} 个任务")

    if issues:
        print(f"\n⚠️  发现 {len(issues)} 个问题:")
        for issue in issues:
            print(f"   - {issue}")


def analyze_dependencies(data: dict) -> None:
    """分析任务依赖关系"""
    print("\n🔗 依赖关系分析")
    print("=" * 50)

    tasks = data.get("tasks", [])
    task_ids = {str(t.get("id")) for t in tasks}
    task_map = {str(t.get("id")): t for t in tasks}

    # 构建依赖图
    graph = defaultdict(list)
    in_degree = defaultdict(int)

    for task in tasks:
        task_id = str(task.get("id"))
        depends_on = task.get("depends_on", [])

        for dep in depends_on:
            dep_str = str(dep)
            if dep_str not in task_ids:
                print(f"❌ Task {task_id} 引用了不存在的依赖: {dep}")
            else:
                graph[dep_str].append(task_id)
                in_degree[task_id] += 1

    # 检测循环依赖
    def detect_cycle():
        visited = set()
        rec_stack = set()
        path = []

        def dfs(node):
            visited.add(node)
            rec_stack.add(node)
            path.append(node)

            for neighbor in graph[node]:
                if neighbor not in visited:
                    if dfs(neighbor):
                        return True
                elif neighbor in rec_stack:
                    path.append(neighbor)
                    return True

            rec_stack.remove(node)
            path.pop()
            return False

        for task_id in task_ids:
            if task_id not in visited:
                if dfs(task_id):
                    return path
        return None

    cycle = detect_cycle()
    if cycle:
        print(f"❌ 检测到循环依赖: {' -> '.join(cycle)}")
    else:
        print("✅ 无循环依赖")

    # 显示依赖层级
    print("\n依赖层级 (执行顺序):")

    # 拓扑排序
    queue = [tid for tid in task_ids if in_degree[tid] == 0]
    level = 0

    while queue:
        level += 1
        print(f"\n  Level {level}:")
        next_queue = []

        for tid in sorted(queue):
            task = task_map.get(tid, {})
            title = task.get("title", "无标题")
            passes = task.get("passes", False)
            status = "✓" if passes else "○"
            print(f"    {status} [{tid}] {title}")

            for neighbor in graph[tid]:
                in_degree[neighbor] -= 1
                if in_degree[neighbor] == 0:
                    next_queue.append(neighbor)

        queue = next_queue


def analyze_progress(data: dict) -> None:
    """分析任务进度"""
    print("\n📈 进度分析")
    print("=" * 50)

    tasks = data.get("tasks", [])
    if not tasks:
        return

    completed = sum(1 for t in tasks if t.get("passes", False))
    blocked = sum(1 for t in tasks if t.get("blocked", False))
    total = len(tasks)
    pending = total - completed - blocked

    print(f"  总任务: {total}")
    print(f"  ✓ 已完成: {completed} ({completed/total*100:.0f}%)")
    print(f"  ○ 待处理: {pending}")
    print(f"  ⚠ 已阻塞: {blocked}")

    # 进度条
    bar_width = 40
    completed_width = int(completed / total * bar_width)
    blocked_width = int(blocked / total * bar_width)

    bar = "█" * completed_width + "▓" * blocked_width + "░" * (bar_width - completed_width - blocked_width)
    print(f"\n  [{bar}]")

    # 显示阻塞任务
    blocked_tasks = [t for t in tasks if t.get("blocked", False)]
    if blocked_tasks:
        print("\n阻塞的任务:")
        for t in blocked_tasks:
            reason = t.get("blocked_reason", "无原因")
            print(f"  ⚠️  [{t.get('id')}] {t.get('title')}")
            print(f"      原因: {reason}")


def validate_schema(data: dict) -> None:
    """验证 JSON 结构"""
    print("\n🔍 结构验证")
    print("=" * 50)

    errors = []

    if "project" not in data:
        errors.append("缺少 'project' 字段")

    if "tasks" not in data:
        errors.append("缺少 'tasks' 字段")
    elif not isinstance(data["tasks"], list):
        errors.append("'tasks' 应为数组")
    else:
        for i, task in enumerate(data["tasks"]):
            prefix = f"tasks[{i}]"

            if "id" not in task:
                errors.append(f"{prefix}: 缺少 'id'")
            if "title" not in task:
                errors.append(f"{prefix}: 缺少 'title'")
            if "steps" not in task:
                errors.append(f"{prefix}: 缺少 'steps'")
            if "passes" not in task:
                errors.append(f"{prefix}: 缺少 'passes'")

    if errors:
        print("❌ 发现结构问题:")
        for err in errors:
            print(f"   - {err}")
    else:
        print("✅ 结构验证通过")


def main():
    task_file = Path("task.json")

    print("╔═══════════════════════════════════════════╗")
    print("║        Task Analyzer - 任务分析工具        ║")
    print("╚═══════════════════════════════════════════╝")

    data = load_tasks(task_file)

    print(f"\n项目: {data.get('project', '未命名')}")
    if data.get("description"):
        print(f"描述: {data.get('description')}")

    validate_schema(data)
    analyze_complexity(data)
    analyze_dependencies(data)
    analyze_progress(data)

    print("\n" + "=" * 50)
    print("分析完成!")


if __name__ == "__main__":
    main()
