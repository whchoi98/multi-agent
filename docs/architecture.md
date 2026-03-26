# Architecture

## System Overview

4-Agent CLI 오케스트레이션 시스템. Claude(Master)가 Gemini(Speed), Codex(Precision), Kiro(Spec) 세 Slave 에이전트를 조율하여 작업을 수행합니다.

## Components

### Master (Claude Code)
- 역할: 오케스트레이션, 최종 판정, 복합 추론
- 설정: `CLAUDE.md`
- 모드에 따라 Slave를 위임하거나 단독 처리

### Speed Slave (Gemini CLI)
- 역할: 빠른 분석, 대량 조회, 로그 요약, AWS API 호출
- 설정: `GEMINI.md`
- 타임아웃: 45초

### Precision Slave (Codex CLI)
- 역할: 정밀 코드 변경, 보안 검토, 테스트 작성
- 설정: `.codex/AGENTS.md`
- 타임아웃: 90초

### Spec Slave (Kiro CLI)
- 역할: 요구사항 분석, 설계 문서, 태스크 분해, 스펙 생성
- 설정: `.kiro/steering/steering.md`
- 타임아웃: 120초

### Orchestrator Script
- `scripts/ai-delegate.sh`: Slave 실행, 타임아웃 관리, 결과 수집
- 7가지 모드: @ask, @scan, @craft, @design, @verify, @mobilize, @build

### Policy Hub
- `claude-policies/common/`: 공통 정책 (4-Block Format, AWS 컨벤션, 보안 기준)
- `claude-policies/multi-agent/`: 모드 정의, 승격/다운그레이드 규칙

## Data Flow

```
사용자 프롬프트
    │
    ▼
Claude (Master)
    │
    ├── @ask ──────→ Master 단독 처리
    │
    ├── @scan ─────→ Gemini(Speed) ────→ Master 검증
    │
    ├── @craft ────→ Codex(Precision) ──→ Master 검증
    │
    ├── @design ───→ Kiro(Spec) ────────→ Master 검증
    │
    ├── @verify ───→ Gemini + Codex (병렬) ──→ Master 비교 판정
    │
    ├── @mobilize ─→ Kiro → Codex → Gemini (순차) ──→ Master Go/No-Go
    │
    └── @build ────→ Kiro(스펙) → Codex(구현) ──→ Master 갭 분석
```

모든 출력은 4-Block Format (결론/근거/리스크/실행안)을 따릅니다.

## Infrastructure

- 실행 환경: 로컬 터미널 (CLI 기반)
- 결과 저장: `.multi-agent-results/` (임시, 실행마다 초기화)
- 정책 관리: Hub & Spoke 구조 (Hub 수정 시 모든 에이전트에 반영)
