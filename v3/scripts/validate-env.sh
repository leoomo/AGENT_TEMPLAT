#!/bin/bash
# 环境验证脚本
# 检查必要的工具和环境变量
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

PASS=0
WARN=0
FAIL=0

check_cmd() {
    if command -v "$1" &>/dev/null; then
        log_success "$1 已安装"
        ((PASS++))
        return 0
    else
        log_error "$1 未安装"
        ((FAIL++))
        return 1
    fi
}

check_cmd_optional() {
    if command -v "$1" &>/dev/null; then
        log_success "$1 已安装"
        ((PASS++))
        return 0
    else
        log_warn "$1 未安装（可选）"
        ((WARN++))
        return 1
    fi
}

check_var() {
    local var_name="$1"
    local var_value="${!var_name}"
    if [ -n "$var_value" ]; then
        log_success "$var_name 已设置"
        ((PASS++))
        return 0
    else
        log_warn "$var_name 未设置"
        ((WARN++))
        return 1
    fi
}

check_file() {
    if [ -f "$1" ]; then
        log_success "$1 存在"
        ((PASS++))
        return 0
    else
        log_error "$1 不存在"
        ((FAIL++))
        return 1
    fi
}

check_file_optional() {
    if [ -f "$1" ]; then
        log_success "$1 存在"
        ((PASS++))
        return 0
    else
        log_warn "$1 不存在（可选）"
        ((WARN++))
        return 1
    fi
}

echo "======================================"
echo "       环境验证 - Environment Check"
echo "======================================"
echo ""

# 基础工具检查
log_info "检查基础工具..."
check_cmd git

# 检测项目类型并验证对应工具
if [ -f "package.json" ]; then
    log_info "检测到 Node.js 项目"
    check_cmd node
    check_cmd npm

    # 检查包管理器
    if [ -f "pnpm-lock.yaml" ]; then
        check_cmd pnpm
    elif [ -f "yarn.lock" ]; then
        check_cmd yarn
    fi

    # 检查 node_modules
    if [ -d "node_modules" ]; then
        log_success "node_modules 存在"
        ((PASS++))
    else
        log_warn "node_modules 不存在，请运行 npm install"
        ((WARN++))
    fi

elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
    log_info "检测到 Python 项目"
    check_cmd python3

    # 检查包管理器
    if command -v uv &>/dev/null; then
        check_cmd uv
    elif [ -f "poetry.lock" ]; then
        check_cmd poetry
    fi

    # 检查虚拟环境
    if [ -d ".venv" ] || [ -d "venv" ]; then
        log_success "虚拟环境存在"
        ((PASS++))
    else
        log_warn "虚拟环境不存在"
        ((WARN++))
    fi

elif [ -f "Cargo.toml" ]; then
    log_info "检测到 Rust 项目"
    check_cmd cargo
    check_cmd rustc

elif [ -f "go.mod" ]; then
    log_info "检测到 Go 项目"
    check_cmd go
fi

echo ""
log_info "检查项目文件..."
check_file_optional "task.json"
check_file_optional "progress.txt"
check_file_optional ".agent/commands.json"

# 检查 .env 文件
echo ""
log_info "检查环境变量..."
if [ -f ".env.example" ]; then
    log_info "发现 .env.example，检查必需变量..."
    while IFS= read -r line || [ -n "$line" ]; do
        # 跳过注释和空行
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue

        # 提取变量名
        var_name=$(echo "$line" | cut -d'=' -f1 | tr -d ' ')
        if [ -n "$var_name" ]; then
            check_var "$var_name"
        fi
    done < ".env.example"
else
    log_info "未找到 .env.example"
fi

# 检查 .agent/commands.json 中的命令是否可用
if [ -f ".agent/commands.json" ]; then
    echo ""
    log_info "验证 commands.json 中的命令..."

    # 简单解析 JSON（不依赖 jq）
    if command -v python3 &>/dev/null; then
        python3 -c "
import json
import shutil
import sys

with open('.agent/commands.json') as f:
    cmds = json.load(f)

for key, cmd in cmds.items():
    if key == 'package_manager':
        continue
    # 提取命令的第一个词
    first_word = cmd.split()[0] if cmd else ''
    if first_word and first_word not in ['echo', 'npx']:
        if shutil.which(first_word):
            print(f'  ✓ {key}: {first_word} 可用')
        else:
            print(f'  ⚠ {key}: {first_word} 未找到')
    elif first_word == 'npx':
        print(f'  ℹ {key}: 使用 npx（需要网络）')
" 2>/dev/null || true
    fi
fi

# 汇总
echo ""
echo "======================================"
echo "              验证结果"
echo "======================================"
echo -e "  ${GREEN}通过: $PASS${NC}"
echo -e "  ${YELLOW}警告: $WARN${NC}"
echo -e "  ${RED}失败: $FAIL${NC}"
echo "======================================"

if [ $FAIL -gt 0 ]; then
    echo ""
    log_error "环境验证未通过，请解决上述问题后重试"
    exit 1
elif [ $WARN -gt 0 ]; then
    echo ""
    log_warn "环境验证通过，但有一些警告"
    exit 0
else
    echo ""
    log_success "环境验证完全通过!"
    exit 0
fi
