#!/bin/bash
# 项目初始化脚本
# 自动检测项目类型并生成配置
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# 检测项目类型
detect_type() {
    if [ -f "package.json" ]; then
        echo "nodejs"
        return
    fi
    if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
        echo "python"
        return
    fi
    if [ -f "Cargo.toml" ]; then
        echo "rust"
        return
    fi
    if [ -f "go.mod" ]; then
        echo "go"
        return
    fi
    echo "unknown"
}

# 检测 Node.js 包管理器
detect_node_pm() {
    if [ -f "pnpm-lock.yaml" ]; then
        echo "pnpm"
    elif [ -f "yarn.lock" ]; then
        echo "yarn"
    else
        echo "npm"
    fi
}

# 检测 Python 包管理器
detect_python_pm() {
    if command -v uv &>/dev/null && [ -f "pyproject.toml" ]; then
        echo "uv"
    elif [ -f "poetry.lock" ]; then
        echo "poetry"
    elif [ -f "Pipfile" ]; then
        echo "pipenv"
    else
        echo "pip"
    fi
}

log_info "开始项目初始化..."

# 检测项目类型
TYPE=$(detect_type)
log_info "检测到项目类型: $TYPE"

# 创建 .agent 目录
mkdir -p .agent

# 复制任务模板（如果不存在）
if [ ! -f "task.json" ]; then
    if [ -f "templates/task.json.example" ]; then
        cp templates/task.json.example task.json
        log_success "已创建 task.json"
    else
        log_warn "templates/task.json.example 不存在，跳过"
    fi
else
    log_info "task.json 已存在，跳过"
fi

# 创建 progress.txt（如果不存在）
if [ ! -f "progress.txt" ]; then
    touch progress.txt
    log_success "已创建 progress.txt"
fi

# 根据类型生成命令配置
case $TYPE in
    nodejs)
        PM=$(detect_node_pm)
        log_info "Node.js 包管理器: $PM"

        cat > .agent/commands.json << EOF
{
  "package_manager": "$PM",
  "install": "$PM install",
  "typecheck": "npx tsc --noEmit",
  "lint": "$PM run lint",
  "build": "$PM run build",
  "test": "$PM test",
  "dev": "$PM run dev"
}
EOF
        log_success "已生成 .agent/commands.json (nodejs)"
        ;;

    python)
        PM=$(detect_python_pm)
        log_info "Python 包管理器: $PM"

        INSTALL_CMD=""
        case $PM in
            uv) INSTALL_CMD="uv sync" ;;
            poetry) INSTALL_CMD="poetry install" ;;
            pipenv) INSTALL_CMD="pipenv install" ;;
            *) INSTALL_CMD="pip install -r requirements.txt" ;;
        esac

        cat > .agent/commands.json << EOF
{
  "package_manager": "$PM",
  "install": "$INSTALL_CMD",
  "typecheck": "mypy .",
  "lint": "ruff check .",
  "build": "$PM build",
  "test": "$PM run pytest",
  "dev": "$PM run dev"
}
EOF
        log_success "已生成 .agent/commands.json (python)"
        ;;

    rust)
        cat > .agent/commands.json << 'EOF'
{
  "package_manager": "cargo",
  "install": "cargo fetch",
  "typecheck": "cargo check",
  "lint": "cargo clippy",
  "build": "cargo build",
  "test": "cargo test",
  "dev": "cargo run"
}
EOF
        log_success "已生成 .agent/commands.json (rust)"
        ;;

    go)
        cat > .agent/commands.json << 'EOF'
{
  "package_manager": "go",
  "install": "go mod download",
  "typecheck": "go vet ./...",
  "lint": "golangci-lint run",
  "build": "go build ./...",
  "test": "go test ./...",
  "dev": "go run ."
}
EOF
        log_success "已生成 .agent/commands.json (go)"
        ;;

    *)
        log_warn "未知项目类型，创建通用配置"

        cat > .agent/commands.json << 'EOF'
{
  "package_manager": "unknown",
  "install": "echo '请手动配置安装命令'",
  "typecheck": "echo '请手动配置类型检查命令'",
  "lint": "echo '请手动配置 lint 命令'",
  "build": "echo '请手动配置构建命令'",
  "test": "echo '请手动配置测试命令'",
  "dev": "echo '请手动配置开发命令'"
}
EOF
        log_warn "请手动编辑 .agent/commands.json 配置正确的命令"
        ;;
esac

# 创建 checkpoint.json
if [ ! -f ".agent/checkpoint.json" ]; then
    echo '{"current_task": null, "completed_steps": []}' > .agent/checkpoint.json
    log_success "已创建 .agent/checkpoint.json"
fi

echo ""
log_success "初始化完成!"
echo ""
echo "生成的文件:"
echo "  - task.json          任务定义"
echo "  - progress.txt       进度日志"
echo "  - .agent/commands.json   构建命令配置"
echo "  - .agent/checkpoint.json 断点记录"
echo ""
echo "下一步:"
echo "  1. 编辑 task.json 定义任务"
echo "  2. 运行 bash scripts/validate-env.sh 验证环境"
