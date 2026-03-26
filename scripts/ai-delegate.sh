#!/usr/bin/env bash
# ai-delegate.sh — Multi-Agent Orchestrator (4-Agent: Claude/Gemini/Codex/Kiro)
#
# Claude(Master)가 이 스크립트를 호출하여 Slave 에이전트를 실행합니다.
# 사용자가 직접 호출하지 않습니다.
#
# Usage: ai-delegate.sh <mode> <prompt> [--context <file>]
#
# Modes:
#   scan     - Gemini만 (속도 우선, 45s)
#   craft    - Codex만 (정밀도 우선, 90s)
#   design   - Kiro만 (설계/스펙 생성, 120s)
#   verify   - Gemini + Codex 병렬 → Master 비교 판정
#   mobilize - Kiro(설계) → Codex(검증) → Gemini(영향도) → Master 종합
#   build    - Kiro(스펙) → Codex(구현) → Master 판정
#
# 4-Block Format 강제: 모든 Slave 출력은 결론/근거/리스크/실행안

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="${PROJECT_ROOT}/.multi-agent-results"
POLICIES_DIR="${PROJECT_ROOT}/claude-policies"

# --- 타임아웃 설정 (가드레일) ---
TIMEOUT_SCAN=45
TIMEOUT_CRAFT=90
TIMEOUT_DESIGN=120
TIMEOUT_MOBILIZE=120

# --- 색상 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- 4-Block Format 프롬프트 접미사 ---
FOUR_BLOCK_SUFFIX="

반드시 아래 4-Block Format으로 응답하세요:

## 결론
최종 답변 또는 액션을 명확하게 서술

## 근거
결론에 도달한 이유, 분석 과정, 참고한 데이터

## 리스크
부작용, 엣지케이스, 주의사항

## 실행안
다음 단계, 구체적인 실행 방법
"

log() { echo -e "${BLUE}[orchestrator]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[orchestrator]${NC} $1" >&2; }
error() { echo -e "${RED}[orchestrator]${NC} $1" >&2; }
success() { echo -e "${GREEN}[orchestrator]${NC} $1" >&2; }

# --- 결과 디렉토리 초기화 ---
init_results() {
    rm -rf "$RESULTS_DIR"
    mkdir -p "$RESULTS_DIR"
}

# --- Slave 실행 함수 ---

run_gemini() {
    local prompt="$1"
    local timeout="${2:-$TIMEOUT_SCAN}"
    local output_file="${RESULTS_DIR}/gemini_result.md"

    log "${CYAN}Gemini(Speed)${NC} 실행 중... (timeout: ${timeout}s)"

    timeout "$timeout" gemini \
        --approval-mode yolo \
        --prompt "${prompt}${FOUR_BLOCK_SUFFIX}" \
        > "$output_file" 2>/dev/null || {
        warn "Gemini 타임아웃 또는 오류 (${timeout}s)"
        echo "## 결론
Gemini 실행 실패 (timeout: ${timeout}s)

## 근거
타임아웃 초과 또는 실행 오류

## 리스크
결과 없음 — Master가 ask로 fallback 필요

## 실행안
Master가 직접 처리하거나 다른 Slave로 재시도" > "$output_file"
        return 1
    }

    success "Gemini 완료"
    cat "$output_file"
}

run_codex() {
    local prompt="$1"
    local timeout="${2:-$TIMEOUT_CRAFT}"
    local output_file="${RESULTS_DIR}/codex_result.md"

    log "${PURPLE}Codex(Precision)${NC} 실행 중... (timeout: ${timeout}s)"

    timeout "$timeout" codex \
        --dangerously-bypass-approvals-and-sandbox \
        --prompt "${prompt}${FOUR_BLOCK_SUFFIX}" \
        > "$output_file" 2>/dev/null || {
        warn "Codex 타임아웃 또는 오류 (${timeout}s)"
        echo "## 결론
Codex 실행 실패 (timeout: ${timeout}s)

## 근거
타임아웃 초과 또는 실행 오류

## 리스크
정밀 검증 누락 — 수동 검증 필요

## 실행안
Master가 직접 처리하거나 타임아웃 증가 후 재시도" > "$output_file"
        return 1
    }

    success "Codex 완료"
    cat "$output_file"
}

run_kiro() {
    local prompt="$1"
    local timeout="${2:-$TIMEOUT_DESIGN}"
    local output_file="${RESULTS_DIR}/kiro_result.md"

    log "${CYAN}Kiro(Spec)${NC} 실행 중... (timeout: ${timeout}s)"

    timeout "$timeout" kiro-cli \
        --non-interactive \
        --prompt "${prompt}${FOUR_BLOCK_SUFFIX}" \
        > "$output_file" 2>/dev/null || {
        warn "Kiro 타임아웃 또는 오류 (${timeout}s)"
        echo "## 결론
Kiro 실행 실패 (timeout: ${timeout}s)

## 근거
타임아웃 초과 또는 실행 오류

## 리스크
스펙/설계 단계 누락 — 구현 품질 저하 가능

## 실행안
Master가 직접 설계하거나 Codex로 대체" > "$output_file"
        return 1
    }

    success "Kiro 완료"
    cat "$output_file"
}

# --- 모드별 실행 ---

mode_scan() {
    local prompt="$1"
    log "모드: ${GREEN}#scan${NC} — Gemini 단독 (속도 우선)"
    echo "---"
    echo "## Gemini (Speed Slave) 결과"
    echo ""
    run_gemini "$prompt"
}

mode_craft() {
    local prompt="$1"
    log "모드: ${PURPLE}#craft${NC} — Codex 단독 (정밀도 우선)"
    echo "---"
    echo "## Codex (Precision Slave) 결과"
    echo ""
    run_codex "$prompt"
}

mode_design() {
    local prompt="$1"
    log "모드: ${CYAN}#design${NC} — Kiro 단독 (설계/스펙 생성)"
    echo "---"
    echo "## Kiro (Spec Slave) 결과"
    echo ""
    run_kiro "$prompt"
}

mode_verify() {
    local prompt="$1"
    log "모드: ${YELLOW}#verify${NC} — Gemini + Codex 병렬 → Master 비교 판정"

    # 병렬 실행
    run_gemini "$prompt" "$TIMEOUT_SCAN" > "${RESULTS_DIR}/gemini_result.md" 2>&1 &
    local gemini_pid=$!

    run_codex "$prompt" "$TIMEOUT_CRAFT" > "${RESULTS_DIR}/codex_result.md" 2>&1 &
    local codex_pid=$!

    # 결과 대기
    wait "$gemini_pid" 2>/dev/null || true
    wait "$codex_pid" 2>/dev/null || true

    # 결과 출력
    echo "---"
    echo "## Verify-Validation 결과"
    echo ""
    echo "### Gemini (Speed Slave)"
    echo ""
    cat "${RESULTS_DIR}/gemini_result.md" 2>/dev/null || echo "(결과 없음)"
    echo ""
    echo "---"
    echo "### Codex (Precision Slave)"
    echo ""
    cat "${RESULTS_DIR}/codex_result.md" 2>/dev/null || echo "(결과 없음)"
    echo ""
    echo "---"
    echo ""
    echo "**Master(Claude)가 위 두 결과를 비교하여 최종 판정해주세요.**"
    echo "차이점, 누락 항목, 최종 채택 버전을 4-Block Format으로 정리해주세요."
}

mode_mobilize() {
    local prompt="$1"
    log "모드: ${RED}#mobilize${NC} — 4-Agent 순차 실행 (최고 위험)"

    echo "---"
    echo "## Mobilize Mode: 4-Agent 순차 실행"
    echo ""

    # Step 1: Kiro — 스펙/설계/체크리스트
    echo "### Step 1: Kiro (Spec) — 설계 및 체크리스트"
    echo ""
    local kiro_prompt="다음 작업의 설계 문서를 작성하세요. 요구사항 분석, 영향 범위, 체크리스트를 포함해주세요: ${prompt}"
    run_kiro "$kiro_prompt" "$TIMEOUT_DESIGN" > "${RESULTS_DIR}/kiro_result.md" 2>&1
    cat "${RESULTS_DIR}/kiro_result.md" 2>/dev/null || echo "(Kiro 결과 없음)"
    echo ""

    # Step 2: Codex — 코드/설정 검증 (Kiro 스펙 기반)
    echo "### Step 2: Codex (Precision) — 코드 및 설정 검증"
    echo ""
    local kiro_result
    kiro_result=$(cat "${RESULTS_DIR}/kiro_result.md" 2>/dev/null || echo "")
    local codex_prompt="아래 설계를 기반으로 코드/설정을 검증하세요.

[Kiro 설계 결과]:
${kiro_result}

[원본 요청]:
${prompt}"
    run_codex "$codex_prompt" "$TIMEOUT_CRAFT" > "${RESULTS_DIR}/codex_result.md" 2>&1
    cat "${RESULTS_DIR}/codex_result.md" 2>/dev/null || echo "(Codex 결과 없음)"
    echo ""

    # Step 3: Gemini — 영향도 분석 (이전 결과 반영)
    echo "### Step 3: Gemini (Speed) — 영향도 분석"
    echo ""
    local codex_result
    codex_result=$(cat "${RESULTS_DIR}/codex_result.md" 2>/dev/null || echo "")
    local gemini_prompt="아래 설계와 검증 결과를 바탕으로 영향도를 분석하세요.

[Kiro 설계]:
${kiro_result}

[Codex 검증]:
${codex_result}

[원본 요청]:
${prompt}"
    run_gemini "$gemini_prompt" "$TIMEOUT_SCAN" > "${RESULTS_DIR}/gemini_result.md" 2>&1
    cat "${RESULTS_DIR}/gemini_result.md" 2>/dev/null || echo "(Gemini 결과 없음)"
    echo ""

    echo "---"
    echo ""
    echo "**Master(Claude): 위 3단계 결과를 종합하여 최종 Go/No-Go 판정해주세요.**"
    echo "4-Block Format으로 최종 판정, 통합 체크리스트, 실행 계획을 작성해주세요."
}

mode_build() {
    local prompt="$1"
    log "모드: ${CYAN}#build${NC} — Kiro(스펙) → Codex(구현) → Master 판정"

    echo "---"
    echo "## Build Mode: Spec-Driven Implementation"
    echo ""

    # Step 1: Kiro — 스펙 생성
    echo "### Step 1: Kiro (Spec) — 요구사항 및 설계"
    echo ""
    local kiro_prompt="다음 요구사항의 상세 스펙을 작성하세요. 요구사항 분석, 기술 설계, 구현 태스크 분해를 포함해주세요: ${prompt}"
    run_kiro "$kiro_prompt" "$TIMEOUT_DESIGN" > "${RESULTS_DIR}/kiro_result.md" 2>&1
    cat "${RESULTS_DIR}/kiro_result.md" 2>/dev/null || echo "(Kiro 결과 없음)"
    echo ""

    # Step 2: Codex — 스펙 기반 구현
    echo "### Step 2: Codex (Precision) — 스펙 기반 구현"
    echo ""
    local kiro_result
    kiro_result=$(cat "${RESULTS_DIR}/kiro_result.md" 2>/dev/null || echo "")
    local codex_prompt="아래 스펙을 기반으로 구현해주세요. 스펙의 모든 요구사항을 충족해야 합니다.

[Kiro 스펙]:
${kiro_result}

[원본 요청]:
${prompt}"
    run_codex "$codex_prompt" "$TIMEOUT_CRAFT" > "${RESULTS_DIR}/codex_result.md" 2>&1
    cat "${RESULTS_DIR}/codex_result.md" 2>/dev/null || echo "(Codex 결과 없음)"
    echo ""

    echo "---"
    echo ""
    echo "**Master(Claude): Kiro 스펙과 Codex 구현을 비교하여 스펙 충족 여부를 판정해주세요.**"
}

# --- 자동 승격/다운그레이드 판단 보조 (Master가 참고) ---
print_escalation_guide() {
    cat << 'GUIDE'

## 자동 승격/다운그레이드 규칙 (Master 참고용)

### 승격 (더 신중하게)
- ask → verify   : 보안 관련 코드 변경 (IAM, SG, 인증, 암호화)
- ask → mobilize : 프로덕션 배포/롤백, 데이터 삭제, 인프라 변경
- ask → design   : 신규 기능 설계, 아키텍처 변경
- scan → verify  : Gemini 결과에 보안 리스크 감지

### 다운그레이드 (더 효율적으로)
- verify → scan    : AWS 대량 읽기 조회 (Codex sandbox 네트워크 제한)
- verify → ask     : SSM 기반 트러블슈팅 (Slave 타임아웃)
- verify → ask     : 대규모 레거시 코드베이스 탐색
- design → ask     : 단순 설정 변경 (Kiro 오버헤드)
- build → craft    : 스펙 불필요한 단순 코드 변경
- mobilize → verify: 장애 아닌 일반 배포

GUIDE
}

# --- 메인 ---
main() {
    local mode="${1:-}"
    shift || true
    local prompt="$*"

    if [[ -z "$mode" || -z "$prompt" ]]; then
        echo "Usage: ai-delegate.sh <mode> <prompt>"
        echo ""
        echo "Modes: scan | craft | design | verify | mobilize | build | guide"
        exit 1
    fi

    init_results

    case "$mode" in
        scan)     mode_scan "$prompt" ;;
        craft)    mode_craft "$prompt" ;;
        design)   mode_design "$prompt" ;;
        verify)   mode_verify "$prompt" ;;
        mobilize) mode_mobilize "$prompt" ;;
        build)    mode_build "$prompt" ;;
        guide)    print_escalation_guide ;;
        *)
            error "알 수 없는 모드: $mode"
            echo "사용 가능: scan | craft | design | verify | mobilize | build | guide"
            exit 1
            ;;
    esac
}

main "$@"
