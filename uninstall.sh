#!/usr/bin/env bash
# uninstall.sh — Multi-Agent CLI 제거

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
DIM='\033[2m'
NC='\033[0m'
BOLD='\033[1m'

echo ""
echo -e "${BOLD}${WHITE}Multi-Agent CLI Uninstaller${NC}"
echo ""

FOUND=0

# 프로젝트 레벨
if [ -d "$(pwd)/.claude/plugins/multi-agent" ]; then
    echo -e "  ${BLUE}감지${NC} 프로젝트 설치: $(pwd)/.claude/plugins/multi-agent/"
    FOUND=1
fi

# 사용자 레벨
if [ -d "$HOME/.claude/plugins/multi-agent" ]; then
    echo -e "  ${BLUE}감지${NC} 사용자 설치: ~/.claude/plugins/multi-agent/"
    FOUND=1
fi

if [ "$FOUND" -eq 0 ]; then
    echo -e "  ${YELLOW}설치된 Multi-Agent CLI를 찾을 수 없습니다.${NC}"
    exit 0
fi

echo ""
echo -ne "  제거할까요? (y/N): "
read -r confirm
if [[ ! "$confirm" =~ ^[yY] ]]; then
    echo -e "  ${DIM}취소됨${NC}"
    exit 0
fi

# 제거
if [ -d "$(pwd)/.claude/plugins/multi-agent" ]; then
    rm -rf "$(pwd)/.claude/plugins/multi-agent"
    echo -e "  ${GREEN}[done]${NC} 프로젝트 설치 제거됨"
fi

if [ -d "$HOME/.claude/plugins/multi-agent" ]; then
    rm -rf "$HOME/.claude/plugins/multi-agent"
    echo -e "  ${GREEN}[done]${NC} 사용자 설치 제거됨"
fi

# PATH 정리
for RC in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash_profile"; do
    if [ -f "$RC" ] && grep -q "multi-agent CLI" "$RC"; then
        sed -i '/multi-agent CLI/d' "$RC"
        echo -e "  ${GREEN}[done]${NC} PATH 정리됨 ($(basename "$RC"))"
    fi
done

echo ""
echo -e "  ${GREEN}${BOLD}제거 완료${NC}"
echo ""
