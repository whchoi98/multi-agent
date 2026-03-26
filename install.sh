#!/usr/bin/env bash
# install.sh — Multi-Agent CLI 대화형 설치 스크립트
# 설치 범위(프로젝트/사용자) + 에이전트 구성(2/3/4) 선택

set -euo pipefail

# --- 색상 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
DIM='\033[2m'
NC='\033[0m'
BOLD='\033[1m'

REPO_URL="https://github.com/whchoi98/multi-agent.git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- 배너 ---
banner() {
    echo ""
    echo -e "${BOLD}${WHITE}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${WHITE}║       Multi-Agent CLI Installer v1.0.0            ║${NC}"
    echo -e "${BOLD}${WHITE}║  Claude(Master) + Gemini + Codex + Kiro           ║${NC}"
    echo -e "${BOLD}${WHITE}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# --- 유틸 ---
info()    { echo -e "  ${BLUE}[info]${NC} $1"; }
success() { echo -e "  ${GREEN}[done]${NC} $1"; }
warn()    { echo -e "  ${YELLOW}[warn]${NC} $1"; }
error()   { echo -e "  ${RED}[error]${NC} $1"; }

separator() { echo -e "  ${DIM}$(printf '─%.0s' {1..50})${NC}"; }

ask_choice() {
    local prompt="$1"
    shift
    local options=("$@")
    echo ""
    echo -e "  ${BOLD}${prompt}${NC}"
    echo ""
    for i in "${!options[@]}"; do
        echo -e "    ${CYAN}$((i+1))${NC}) ${options[$i]}"
    done
    echo ""
    while true; do
        echo -ne "  선택 (1-${#options[@]}): "
        read -r choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
            return $((choice - 1))
        fi
        echo -e "  ${RED}1-${#options[@]} 사이 숫자를 입력하세요${NC}"
    done
}

# --- Step 1: 설치 범위 선택 ---
select_scope() {
    ask_choice "설치 범위를 선택하세요:" \
        "프로젝트 (.claude/)  — 현재 프로젝트에서만 사용" \
        "사용자   (~/.claude/) — 모든 프로젝트에서 사용"
    SCOPE_CHOICE=$?

    if [ "$SCOPE_CHOICE" -eq 0 ]; then
        INSTALL_SCOPE="project"
        INSTALL_DIR="$(pwd)/.claude/plugins/multi-agent"
        info "설치 위치: ${BOLD}$(pwd)/.claude/plugins/multi-agent/${NC}"
    else
        INSTALL_SCOPE="user"
        INSTALL_DIR="$HOME/.claude/plugins/multi-agent"
        info "설치 위치: ${BOLD}~/.claude/plugins/multi-agent/${NC}"
    fi
}

# --- Step 2: 에이전트 구성 선택 ---
select_agents() {
    ask_choice "에이전트 구성을 선택하세요:" \
        "2-Agent  Claude(Master) + Gemini(Speed)                    — ask, scan" \
        "3-Agent  Claude(Master) + Gemini(Speed) + Codex(Precision) — + craft, verify" \
        "4-Agent  Claude + Gemini + Codex + Kiro(Spec)              — + design, mobilize, build (전체)"
    AGENT_CHOICE=$?

    case $AGENT_CHOICE in
        0) AGENT_COUNT=2; AGENTS=("scan"); MODES="ask, scan" ;;
        1) AGENT_COUNT=3; AGENTS=("scan" "craft" "verify"); MODES="ask, scan, craft, verify" ;;
        2) AGENT_COUNT=4; AGENTS=("scan" "craft" "design" "verify" "mobilize" "build"); MODES="ask, scan, craft, design, verify, mobilize, build" ;;
    esac

    info "에이전트: ${BOLD}${AGENT_COUNT}-Agent${NC} (모드: ${MODES})"
}

# --- Step 3: 사전 요구사항 체크 ---
check_prerequisites() {
    echo ""
    echo -e "  ${BOLD}사전 요구사항 체크${NC}"
    separator

    # Claude Code
    if command -v claude &>/dev/null; then
        success "Claude Code CLI 감지됨"
    else
        warn "Claude Code CLI 미설치 — https://claude.ai/claude-code"
    fi

    # Gemini (2/3/4-Agent 모두)
    if command -v gemini &>/dev/null; then
        success "Gemini CLI 감지됨"
    else
        warn "Gemini CLI 미설치 — npm install -g @anthropic-ai/gemini-cli"
    fi

    # Codex (3/4-Agent)
    if [ "$AGENT_COUNT" -ge 3 ]; then
        if command -v codex &>/dev/null; then
            success "Codex CLI 감지됨"
        else
            warn "Codex CLI 미설치 — npm install -g @openai/codex"
        fi
    fi

    # Kiro (4-Agent)
    if [ "$AGENT_COUNT" -ge 4 ]; then
        if command -v kiro-cli &>/dev/null || command -v kiro &>/dev/null; then
            success "Kiro CLI 감지됨"
        else
            warn "Kiro CLI 미설치 — https://kiro.dev"
        fi
    fi
}

# --- Step 4: 설치 확인 ---
confirm_install() {
    echo ""
    separator
    echo ""
    echo -e "  ${BOLD}설치 요약${NC}"
    echo -e "    범위:     ${CYAN}${INSTALL_SCOPE}${NC} (${INSTALL_DIR})"
    echo -e "    에이전트: ${CYAN}${AGENT_COUNT}-Agent${NC}"
    echo -e "    모드:     ${CYAN}${MODES}${NC}"
    echo ""
    echo -ne "  설치를 진행할까요? (Y/n): "
    read -r confirm
    if [[ "$confirm" =~ ^[nN] ]]; then
        info "설치를 취소했습니다."
        exit 0
    fi
}

# --- Step 5: 파일 복사 ---
install_files() {
    echo ""
    echo -e "  ${BOLD}설치 중...${NC}"
    separator

    # 소스 디렉토리 (로컬 clone 또는 현재 repo)
    local SRC_DIR
    if [ -f "$SCRIPT_DIR/plugin/plugin.json" ]; then
        SRC_DIR="$SCRIPT_DIR/plugin"
    else
        info "GitHub에서 다운로드 중..."
        local TEMP_DIR
        TEMP_DIR=$(mktemp -d)
        git clone --depth 1 "$REPO_URL" "$TEMP_DIR" 2>/dev/null
        SRC_DIR="$TEMP_DIR/plugin"
    fi

    # 기존 설치 제거
    if [ -d "$INSTALL_DIR" ]; then
        warn "기존 설치 감지 → 덮어씁니다"
        rm -rf "$INSTALL_DIR"
    fi

    # 디렉토리 구조 생성
    mkdir -p "$INSTALL_DIR"/{agents,skills,hooks,policies,scripts}

    # plugin.json
    cp "$SRC_DIR/plugin.json" "$INSTALL_DIR/"
    success "plugin.json"

    # 정책 파일 (공통)
    cp "$SRC_DIR/policies/"*.md "$INSTALL_DIR/policies/" 2>/dev/null || true
    success "정책 파일 (4-Block, 보안, 승격 규칙)"

    # 스크립트
    cp "$SRC_DIR/scripts/ai-delegate.sh" "$INSTALL_DIR/scripts/"
    chmod +x "$INSTALL_DIR/scripts/ai-delegate.sh"
    success "ai-delegate.sh 오케스트레이터"

    # Hook (자동 감지)
    cp "$SRC_DIR/hooks/auto-detect.md" "$INSTALL_DIR/hooks/"
    success "auto-detect hook"

    # 에이전트 & 스킬 (선택된 구성에 따라)
    for mode in "${AGENTS[@]}"; do
        if [ -f "$SRC_DIR/agents/${mode}.md" ]; then
            cp "$SRC_DIR/agents/${mode}.md" "$INSTALL_DIR/agents/"
        fi
        if [ -d "$SRC_DIR/skills/${mode}" ]; then
            mkdir -p "$INSTALL_DIR/skills/${mode}"
            cp "$SRC_DIR/skills/${mode}/SKILL.md" "$INSTALL_DIR/skills/${mode}/"
        fi
        success "@${mode} 에이전트 + 스킬"
    done

    # 2-Agent: verify/mobilize/build 제외된 모드의 정책 필터링
    if [ "$AGENT_COUNT" -eq 2 ]; then
        # modes.md에서 사용 불가 모드 표시
        cat > "$INSTALL_DIR/policies/modes-override.md" << 'MODES2'
# 2-Agent 모드 제한

사용 가능: ask, scan
사용 불가: craft, design, verify, mobilize, build (Codex/Kiro 미설치)

scan 결과에서 보안 리스크 감지 시 → Master가 직접 심층 분석 (verify 대체)
MODES2
        success "2-Agent 모드 제한 정책"
    elif [ "$AGENT_COUNT" -eq 3 ]; then
        cat > "$INSTALL_DIR/policies/modes-override.md" << 'MODES3'
# 3-Agent 모드 제한

사용 가능: ask, scan, craft, verify
사용 불가: design, mobilize, build (Kiro 미설치)

design 요청 시 → Master가 직접 설계 (ask 모드)
mobilize 요청 시 → verify로 대체 (Codex + Gemini 교차검증)
build 요청 시 → craft로 대체 (Codex 단독 구현)
MODES3
        success "3-Agent 모드 제한 정책"
    fi

    # CLI wrapper 생성
    local WRAPPER_PATH="$INSTALL_DIR/scripts/multi-agent"
    cat > "$WRAPPER_PATH" << WRAPPER
#!/usr/bin/env bash
# multi-agent — CLI wrapper
# Usage: multi-agent <mode> "<prompt>"
#        multi-agent --help

set -euo pipefail

INSTALL_DIR="$INSTALL_DIR"
AGENT_COUNT=$AGENT_COUNT

show_help() {
    echo "Multi-Agent CLI (${AGENT_COUNT}-Agent)"
    echo ""
    echo "Usage: multi-agent <mode> \"<prompt>\""
    echo "       multi-agent --help"
    echo "       multi-agent --info"
    echo ""
    echo "Modes:"
WRAPPER

    # 모드 도움말을 에이전트 수에 맞게 생성
    if [ "$AGENT_COUNT" -ge 2 ]; then
        echo '    echo "  scan      속도우선 (Gemini)"' >> "$WRAPPER_PATH"
    fi
    if [ "$AGENT_COUNT" -ge 3 ]; then
        echo '    echo "  craft     정밀분석 (Codex)"' >> "$WRAPPER_PATH"
        echo '    echo "  verify    교차검증 (Gemini+Codex)"' >> "$WRAPPER_PATH"
    fi
    if [ "$AGENT_COUNT" -ge 4 ]; then
        echo '    echo "  design    설계먼저 (Kiro)"' >> "$WRAPPER_PATH"
        echo '    echo "  mobilize  총동원   (Kiro→Codex→Gemini)"' >> "$WRAPPER_PATH"
        echo '    echo "  build     스펙→구현 (Kiro→Codex)"' >> "$WRAPPER_PATH"
    fi

    cat >> "$WRAPPER_PATH" << 'WRAPPER2'
    echo ""
}

show_info() {
    echo "Multi-Agent CLI"
    echo "  Install: $INSTALL_DIR"
    echo "  Agents:  $AGENT_COUNT"
    echo ""
    echo "Installed agents:"
    for f in "$INSTALL_DIR/agents/"*.md; do
        [ -f "$f" ] && echo "  - $(basename "$f" .md)"
    done
    echo ""
    echo "Installed skills:"
    for d in "$INSTALL_DIR/skills/"*/; do
        [ -d "$d" ] && echo "  - $(basename "$d")"
    done
}

case "${1:-}" in
    --help|-h) show_help; exit 0 ;;
    --info)    show_info; exit 0 ;;
    "")        show_help; exit 1 ;;
esac

MODE="$1"; shift
PROMPT="$*"

if [ -z "$PROMPT" ]; then
    echo "Error: prompt is required"
    echo "Usage: multi-agent $MODE \"<prompt>\""
    exit 1
fi

export CLAUDE_PLUGIN_ROOT="$INSTALL_DIR"
exec bash "$INSTALL_DIR/scripts/ai-delegate.sh" "$MODE" "$PROMPT"
WRAPPER2

    chmod +x "$WRAPPER_PATH"
    success "multi-agent CLI wrapper"

    # 임시 디렉토리 정리
    if [ -n "${TEMP_DIR:-}" ] && [ -d "${TEMP_DIR:-}" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

# --- Step 6: PATH 설정 ---
setup_path() {
    local WRAPPER_DIR="$INSTALL_DIR/scripts"

    # 이미 PATH에 있는지 확인
    if echo "$PATH" | tr ':' '\n' | grep -qx "$WRAPPER_DIR"; then
        info "PATH에 이미 등록됨"
        return
    fi

    echo ""
    echo -e "  ${BOLD}PATH 설정${NC}"

    local SHELL_RC=""
    if [ -f "$HOME/.zshrc" ]; then
        SHELL_RC="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        SHELL_RC="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        SHELL_RC="$HOME/.bash_profile"
    fi

    if [ -n "$SHELL_RC" ]; then
        local PATH_LINE="export PATH=\"${WRAPPER_DIR}:\$PATH\"  # multi-agent CLI"
        if ! grep -q "multi-agent CLI" "$SHELL_RC" 2>/dev/null; then
            echo "" >> "$SHELL_RC"
            echo "$PATH_LINE" >> "$SHELL_RC"
            success "PATH 추가됨 → $(basename "$SHELL_RC")"
            info "적용하려면: ${BOLD}source ${SHELL_RC}${NC}"
        else
            info "PATH 이미 등록됨 ($(basename "$SHELL_RC"))"
        fi
    else
        warn "쉘 설정 파일을 찾을 수 없습니다. 수동으로 PATH에 추가하세요:"
        echo -e "    export PATH=\"${WRAPPER_DIR}:\$PATH\""
    fi
}

# --- Step 7: 완료 ---
print_summary() {
    echo ""
    echo -e "${BOLD}${WHITE}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${WHITE}║              설치 완료!                            ║${NC}"
    echo -e "${BOLD}${WHITE}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}구성${NC}"
    echo -e "    범위:     ${GREEN}${INSTALL_SCOPE}${NC}"
    echo -e "    에이전트: ${GREEN}${AGENT_COUNT}-Agent${NC}"
    echo -e "    위치:     ${DIM}${INSTALL_DIR}${NC}"
    echo ""
    echo -e "  ${BOLD}사용법${NC}"
    echo ""
    echo -e "    ${DIM}# Claude Code 내에서 (자동 감지)${NC}"
    echo -e "    ${CYAN}이 IAM 정책 검토해줘${NC}"
    echo ""
    echo -e "    ${DIM}# Claude Code 내에서 (수동 오버라이드)${NC}"
    echo -e "    ${CYAN}@verify 이 IAM 정책 검토해줘${NC}"
    echo ""
    echo -e "    ${DIM}# CLI 직접 실행${NC}"
    echo -e "    ${CYAN}multi-agent scan \"CloudWatch 로그 분석\"${NC}"

    if [ "$AGENT_COUNT" -ge 3 ]; then
        echo -e "    ${CYAN}multi-agent verify \"IAM 정책 검토\"${NC}"
    fi
    if [ "$AGENT_COUNT" -ge 4 ]; then
        echo -e "    ${CYAN}multi-agent mobilize \"프로덕션 배포 검증\"${NC}"
    fi

    echo ""
    echo -e "    ${DIM}# 설치 정보${NC}"
    echo -e "    ${CYAN}multi-agent --info${NC}"
    echo ""
    echo -e "  ${BOLD}제거${NC}"
    echo -e "    ${CYAN}bash $(cd "$SCRIPT_DIR" && pwd)/uninstall.sh${NC}"
    echo ""
}

# --- 메인 ---
main() {
    banner
    select_scope
    select_agents
    check_prerequisites
    confirm_install
    install_files
    setup_path
    print_summary
}

main "$@"
