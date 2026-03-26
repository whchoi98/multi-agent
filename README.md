# Multi-Agent CLI

**[한국어](#한국어) | [English](#english)**

---

<a id="한국어"></a>

# 한국어

> 4개의 AI CLI 에이전트를 오케스트레이션하여 DevOps/SRE/개발 작업을 수행하는 시스템

## 목차

- [개요](#개요)
- [아키텍처](#아키텍처)
  - [에이전트 구성](#에이전트-구성)
  - [시스템 흐름도](#시스템-흐름도)
- [7가지 실행 모드](#7가지-실행-모드)
  - [모드 상세](#모드-상세)
  - [모드 선택 가이드](#모드-선택-가이드)
- [자동 승격/다운그레이드](#자동-승격다운그레이드)
- [4-Block Format](#4-block-format)
- [프로젝트 구조](#프로젝트-구조)
- [시작하기](#시작하기)
  - [사전 요구사항](#사전-요구사항)
  - [설치](#설치)
  - [사용법](#사용법)
- [유스케이스 카탈로그](#유스케이스-카탈로그)
- [정책 관리 (Hub & Spoke)](#정책-관리-hub--spoke)
- [검증 및 시뮬레이션](#검증-및-시뮬레이션)

---

## 개요

Multi-Agent CLI는 4개의 AI CLI 에이전트를 오케스트레이션하여 DevOps, SRE, 개발 작업에서 단독 에이전트의 한계를 넘는 결과를 도출하는 시스템입니다.

**핵심 원칙:**
- 혼자 해도 되지만, 함께하면 놓치지 않는다
- 단독 에이전트는 80%의 답, Multi-Agent는 나머지 20% — 그 20%가 장애와 보안 사고의 차이
- 모든 출력은 4-Block Format (결론/근거/리스크/실행안)

---

## 아키텍처

### 에이전트 구성

| 에이전트 | 역할 | 강점 | 타임아웃 |
|---------|------|------|---------|
| **Claude** (Master) | 오케스트레이션 / 최종 판정 | 복합 추론, Judge 역할 | - |
| **Gemini** (Speed) | 속도 우선 처리 | 대량 분석, AWS API 호출, 로그 요약 | 45s |
| **Codex** (Precision) | 정밀도 우선 처리 | 코드 변경, 보안 검토, 테스트 작성 | 90s |
| **Kiro** (Spec) | 설계/스펙 생성 | 요구사항 분석, 아키텍처 설계, 태스크 분해 | 120s |

### 시스템 흐름도

```
사용자 프롬프트 (#모드 + 작업 내용)
    │
    ▼
┌─────────────────────────────────┐
│         Claude (Master)          │
│  모드 판단 → 자동 승격 판단 →    │
│  Slave 위임 또는 단독 처리       │
└──────────┬──────────────────────┘
           │
     ┌─────┼──────────┬──────────────┐
     │     │          │              │
     ▼     ▼          ▼              ▼
  #ask   #scan     #craft         #design
  Master  Gemini     Codex          Kiro
  단독    (45s)      (90s)         (120s)
           │          │              │
           ▼          ▼              ▼
     ┌─────┴──────────┴──────────────┘
     │
     ▼
  #verify         #mobilize              #build
  Gemini+Codex    Kiro→Codex→Gemini      Kiro→Codex
  (병렬→비교)    (순차→Go/No-Go)       (스펙→구현→갭분석)
     │               │                    │
     └───────────────┼────────────────────┘
                     ▼
              Master 최종 판정
              (4-Block Format)
```

---

## 7가지 실행 모드

사용자가 프롬프트 앞에 `#모드`를 붙여 실행합니다.

### 모드 상세

| 모드 | 명칭 | 에이전트 | 실행 방식 | 적합한 작업 |
|------|------|---------|----------|-----------|
| `#ask` | 단독처리 | Claude | 단독 | 단순 질문, 파일 읽기/수정 |
| `#scan` | 속도우선 | Gemini | 단독 | 로그 분석, 비용 조회, 대량 데이터 요약 |
| `#craft` | 정밀분석 | Codex | 단독 | 코드 변경, 테스트 작성, 설정 검증 |
| `#design` | 설계먼저 | Kiro | 단독 | 요구사항 분석, 아키텍처 설계, 런북 작성 |
| `#verify` | 교차검증 | Gemini + Codex | 병렬 → 비교 | IAM 정책, 보안 변경, 코드 리뷰 |
| `#mobilize` | 총동원 | Kiro → Codex → Gemini | 순차 | 프로덕션 장애, 배포, DB 마이그레이션 |
| `#build` | 스펙→구현 | Kiro → Codex | 순차 | 리팩토링, API 마이그레이션, 신규 기능 |

### 모드 선택 가이드

```
"빨리 파악해야 해"          → #scan
"정확해야 해"              → #craft
"설계부터 해야 해"          → #design
"두 번 확인해야 해"         → #verify
"절대 실패하면 안 돼"       → #mobilize
"설계하고 바로 구현까지"     → #build
"간단한 거"               → #ask
```

---

## 자동 승격/다운그레이드

사용자가 모드를 명시하지 않았거나, 작업 특성상 모드 전환이 필요할 때 Master가 자동 판단합니다.

### 승격 (더 신중하게)

```
ask → verify       보안 관련 코드 변경 (IAM, SG, 인증, 암호화)
ask → mobilize     프로덕션 배포/롤백, 데이터 삭제, 인프라 변경
ask → design       신규 기능 설계, 아키텍처 리팩토링
scan → verify      Gemini 결과에서 보안 리스크 감지
verify → mobilize  교차 검증 중 심각한 불일치 발견
```

### 다운그레이드 (더 효율적으로)

```
verify → scan      AWS 대량 읽기 조회 (Codex sandbox 네트워크 제한)
verify → ask       SSM 트러블슈팅, 레거시 코드베이스 탐색
design → ask       단순 설정 변경 (Kiro 오버헤드)
build → craft      스펙 불필요한 단순 코드 변경
mobilize → verify  장애가 아닌 일반 배포
```

### Fallback

- Slave 타임아웃 → Master가 `#ask`로 fallback
- Slave 2회 연속 실패 → 해당 세션 동안 비활성화
- 전체 Slave 실패 → Master 단독 + 사용자 상황 보고

---

## 4-Block Format

모든 에이전트 출력은 **예외 없이** 이 형식을 따릅니다.

```
## 결론
의사결정자가 이 블록만 읽고도 행동할 수 있어야 합니다.

## 근거
분석 과정, 참고 데이터, 대안 비교.

## 리스크
기술적/비즈니스/운영 리스크.

## 실행안
즉시 실행 항목, 후속 확인, 담당자 권장.
```

**왜 4-Block인가?**
1. 일관성 — 누가 어떤 모드를 쓰든 같은 구조
2. 의사결정 가속 — "결론"만 보면 됨
3. 감사 추적 — 포스트모템에 그대로 사용 가능
4. Master 종합 용이 — 구조화된 입력 = 구조화된 판정

---

## 프로젝트 구조

```
multi-agent/
├── CLAUDE.md                          # Master(Claude) 설정
├── GEMINI.md                          # Gemini Speed Slave 설정
├── .codex/AGENTS.md                   # Codex Precision Slave 설정
├── .kiro/steering/steering.md         # Kiro Spec Slave 설정
│
├── claude-policies/                   # 정책 Hub (Single Source of Truth)
│   ├── common/
│   │   ├── 4-block-format.md          #   출력 형식 정의
│   │   ├── aws-conventions.md         #   AWS 네이밍/태깅 컨벤션
│   │   └── security-baseline.md       #   보안 기준선
│   └── multi-agent/
│       ├── modes.md                   #   7가지 모드 정의
│       └── escalation-rules.md        #   승격/다운그레이드 규칙
│
├── scripts/
│   ├── ai-delegate.sh                 # Slave 위임 오케스트레이터
│   ├── simulate.sh                    # 시나리오 시뮬레이션
│   └── validate.sh                    # 구조 검증 (PASS/WARN/FAIL)
│
├── docs/
│   ├── architecture.md                # 시스템 아키텍처 문서
│   ├── decisions/                     # ADR (Architecture Decision Records)
│   ├── runbooks/                      # 운영 런북
│   └── superpowers/specs/             # 유스케이스 카탈로그
│
├── .claude/
│   ├── settings.json                  # 훅 설정 (doc-sync 자동 감지)
│   ├── hooks/check-doc-sync.sh        # 문서 동기화 감지 훅
│   └── skills/                        # 커스텀 스킬
│       ├── code-review/SKILL.md       #   코드 리뷰 (confidence scoring)
│       ├── refactor/SKILL.md          #   리팩토링
│       ├── release/SKILL.md           #   릴리스 자동화
│       └── sync-docs/SKILL.md         #   문서 동기화
│
└── tools/
    ├── scripts/                       # 보조 스크립트
    └── prompts/                       # 프롬프트 템플릿
```

---

## 시작하기

### 사전 요구사항

| 도구 | 용도 | 설치 |
|------|------|------|
| [Claude Code](https://claude.ai/claude-code) | Master 에이전트 | `npm install -g @anthropic-ai/claude-code` |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli) | Speed Slave | `npm install -g @anthropic-ai/gemini-cli` |
| [Codex CLI](https://github.com/openai/codex) | Precision Slave | `npm install -g @openai/codex` |
| [Kiro CLI](https://kiro.dev) | Spec Slave | Kiro 공식 설치 가이드 참조 |

### 설치

```bash
git clone <repository-url> multi-agent
cd multi-agent
```

### 사용법

**방법 1: Claude Code 내에서 직접 (권장)**

Claude Code 세션에서 프롬프트 앞에 `#모드`를 붙입니다.

```
#scan 최근 1시간 CloudWatch 로그에서 에러 패턴 분석해줘
#verify 이 IAM 정책 검토해줘
#mobilize 프로덕션 DB에 컬럼 추가 — 5천만 건, 무중단 필수
```

Master(Claude)가 모드를 판단하고 `ai-delegate.sh`를 통해 Slave를 위임합니다.

**방법 2: 스크립트 직접 실행**

```bash
# Slave 위임
bash scripts/ai-delegate.sh scan "CloudWatch 로그 분석"
bash scripts/ai-delegate.sh verify "IAM 정책 검토"
bash scripts/ai-delegate.sh mobilize "프로덕션 배포 검증"

# 시뮬레이션 (dry run)
bash scripts/simulate.sh all

# 구조 검증
bash scripts/validate.sh all
```

---

## 유스케이스 카탈로그

15개 실전 유스케이스가 역할별로 정리되어 있습니다.

전체 문서: [`docs/superpowers/specs/2026-03-26-usecase-catalog-design.md`](docs/superpowers/specs/2026-03-26-usecase-catalog-design.md)

| 편 | UC | 시나리오 | 모드 |
|----|-----|---------|------|
| **DevOps** | UC1 | IAM 정책 변경 검토 | `#verify` |
| | UC2 | CloudWatch 로그 대량 분석 | `#scan` |
| | UC3 | Terraform 모듈 리팩토링 | `#build` |
| | UC4 | CI/CD 파이프라인 장애 대응 | `#mobilize` |
| | UC5 | ECS 오토스케일링 튜닝 | `#craft` |
| **SRE** | UC6 | 프로덕션 P1 장애 대응 | `#mobilize` |
| | UC7 | SLO 기반 알림 설정 | `#verify` |
| | UC8 | 비용 이상 탐지 분석 | `#scan` |
| | UC9 | 재해복구(DR) 런북 작성 | `#design` |
| | UC10 | 보안 감사 대응 자동화 | `#verify`→`#mobilize` |
| **Developer** | UC11 | 레거시 API 마이그레이션 | `#build` |
| | UC12 | 유닛 테스트 일괄 생성 | `#craft` |
| | UC13 | PR 코드 리뷰 자동화 | `#verify` |
| | UC14 | 신규 마이크로서비스 설계 | `#design` |
| | UC15 | 프로덕션 DB 마이그레이션 | `#mobilize` |

---

## 정책 관리 (Hub & Spoke)

정책은 `claude-policies/`에서 중앙 관리합니다. 변경 시 Hub만 수정하면 모든 에이전트에 반영됩니다.

```
claude-policies/  ← Hub (Single Source of Truth)
├── common/
│   ├── 4-block-format.md       ← 출력 형식 (모든 에이전트 참조)
│   ├── aws-conventions.md      ← AWS 네이밍/태깅 규칙
│   └── security-baseline.md    ← 보안 기준선
└── multi-agent/
    ├── modes.md                ← 7가지 모드 정의
    └── escalation-rules.md     ← 승격/다운그레이드 규칙

CLAUDE.md   ──┐
GEMINI.md   ──┼── 각자 Hub 정책을 "참조"만 (복사 X)
AGENTS.md   ──┤
steering.md ──┘
```

---

## 검증 및 시뮬레이션

```bash
# 전체 구조 검증 (PASS/WARN/FAIL)
bash scripts/validate.sh all

# 시나리오별 시뮬레이션
bash scripts/simulate.sh scan        # Gemini 속도 테스트
bash scripts/simulate.sh build      # Kiro→Codex 파이프라인
bash scripts/simulate.sh mobilize   # 4-Agent 순차 실행
bash scripts/simulate.sh all        # 전체 시나리오
```

---

<a id="english"></a>

# English

> Orchestrate 4 AI CLI agents for DevOps/SRE/Developer workflows

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
  - [Agent Roles](#agent-roles)
  - [System Flow](#system-flow)
- [7 Execution Modes](#7-execution-modes)
  - [Mode Details](#mode-details)
  - [Mode Selection Guide](#mode-selection-guide-1)
- [Auto Escalation/De-escalation](#auto-escalationde-escalation)
- [4-Block Output Format](#4-block-output-format)
- [Project Structure](#project-structure-1)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Usage](#usage)
- [Usecase Catalog](#usecase-catalog)
- [Policy Management (Hub & Spoke)](#policy-management-hub--spoke)
- [Validation & Simulation](#validation--simulation)

---

## Overview

Multi-Agent CLI is an orchestration system where Claude (Master) coordinates three Slave agents — Gemini (Speed), Codex (Precision), and Kiro (Spec) — to produce results that exceed what any single agent can achieve alone.

**Core Principles:**
- One agent gives 80% of the answer. Multi-agent catches the remaining 20% — the difference between an incident and a near-miss.
- All outputs follow the 4-Block Format (Conclusion / Rationale / Risks / Action Plan).
- Slaves are read-only. Only Master executes changes with user approval.

---

## Architecture

### Agent Roles

| Agent | Role | Strengths | Timeout |
|-------|------|-----------|---------|
| **Claude** (Master) | Orchestration / Final Judge | Complex reasoning, synthesis | - |
| **Gemini** (Speed) | Fast analysis | Bulk queries, log analysis, AWS API calls | 45s |
| **Codex** (Precision) | Precise operations | Code changes, security review, test generation | 90s |
| **Kiro** (Spec) | Design & specification | Requirements analysis, architecture design, task decomposition | 120s |

### System Flow

```
User Prompt (#mode + task description)
    │
    ▼
┌─────────────────────────────────┐
│          Claude (Master)         │
│  Mode detection → Auto-escalate │
│  → Delegate or solo             │
└──────────┬──────────────────────┘
           │
     ┌─────┼──────────┬──────────────┐
     │     │          │              │
     ▼     ▼          ▼              ▼
  #ask   #scan     #craft         #design
  Master  Gemini     Codex          Kiro
  ask     (45s)      (90s)         (120s)
           │          │              │
           ▼          ▼              ▼
     ┌─────┴──────────┴──────────────┘
     │
     ▼
  #verify         #mobilize              #build
  Gemini+Codex    Kiro→Codex→Gemini      Kiro→Codex
  (parallel→      (sequential→           (spec→implement
   compare)        Go/No-Go)              →gap analysis)
     │               │                    │
     └───────────────┼────────────────────┘
                     ▼
              Master Final Verdict
              (4-Block Format)
```

---

## 7 Execution Modes

Users prefix their prompt with `#mode` to select the execution mode.

### Mode Details

| Mode | Name | Agent(s) | Execution | Best For |
|------|------|----------|-----------|----------|
| `#ask` | Solo | Claude | Single | Simple questions, file edits |
| `#scan` | Speed First | Gemini | Single | Log analysis, cost queries, bulk data |
| `#craft` | Precision First | Codex | Single | Code changes, tests, config validation |
| `#design` | Design First | Kiro | Single | Requirements, architecture, runbooks |
| `#verify` | Cross-Validation | Gemini + Codex | Parallel → Compare | IAM policies, security changes, code review |
| `#mobilize` | Full Pipeline | Kiro → Codex → Gemini | Sequential | Production incidents, deployments, DB migrations |
| `#build` | Spec-to-Impl | Kiro → Codex | Sequential | Refactoring, API migration, new features |

### Mode Selection Guide

```
"I need this fast"              → #scan
"This must be exact"            → #craft
"Design it first"               → #design
"Double-check this"             → #verify
"This cannot fail"              → #mobilize
"Design then implement"         → #build
"Just a quick thing"            → #ask
```

---

## Auto Escalation/De-escalation

When no mode is specified, or when the task context demands it, Master automatically adjusts.

### Escalation (More Careful)

```
ask → verify       Security-related code changes (IAM, SG, auth, encryption)
ask → mobilize     Production deploy/rollback, data deletion, major infra changes
ask → design       New feature design, architecture refactoring
scan → verify      Security risk detected in Gemini results
verify → mobilize  Severe inconsistency found during cross-validation
```

### De-escalation (More Efficient)

```
verify → scan      Bulk AWS read queries (Codex sandbox network limitation)
verify → ask       SSM troubleshooting, legacy codebase exploration
design → ask       Simple config changes (Kiro overhead)
build → craft      Simple code changes not requiring a spec
mobilize → verify  Non-incident deployments, low-risk changes
```

### Fallback

- Slave timeout → Master falls back to `#ask`
- Slave fails twice → Disabled for current session
- All Slaves fail → Master solo + user notification

---

## 4-Block Output Format

Every agent output follows this format. No exceptions.

```
## Conclusion
Decision-makers should be able to act on this block alone.

## Rationale
Analysis process, reference data, alternatives compared.

## Risks
Technical / business / operational risks.

## Action Plan
Immediate steps, follow-up checks, recommended owners.
```

**Why 4-Block?**
1. **Consistency** — Same structure regardless of mode or agent
2. **Decision acceleration** — Read "Conclusion" and act
3. **Audit trail** — Directly usable in postmortems
4. **Master synthesis** — Structured input = structured verdict

---

## Project Structure

```
multi-agent/
├── CLAUDE.md                          # Master (Claude) config
├── GEMINI.md                          # Gemini Speed Slave config
├── .codex/AGENTS.md                   # Codex Precision Slave config
├── .kiro/steering/steering.md         # Kiro Spec Slave config
│
├── claude-policies/                   # Policy Hub (Single Source of Truth)
│   ├── common/
│   │   ├── 4-block-format.md          #   Output format definition
│   │   ├── aws-conventions.md         #   AWS naming/tagging conventions
│   │   └── security-baseline.md       #   Security baseline
│   └── multi-agent/
│       ├── modes.md                   #   7 mode definitions
│       └── escalation-rules.md        #   Escalation/de-escalation rules
│
├── scripts/
│   ├── ai-delegate.sh                 # Slave delegation orchestrator
│   ├── simulate.sh                    # Scenario simulation
│   └── validate.sh                    # Structure validation (PASS/WARN/FAIL)
│
├── docs/
│   ├── architecture.md                # System architecture
│   ├── decisions/                     # ADRs (Architecture Decision Records)
│   ├── runbooks/                      # Operations runbooks
│   └── superpowers/specs/             # Usecase catalog
│
├── .claude/
│   ├── settings.json                  # Hook config (doc-sync detection)
│   ├── hooks/check-doc-sync.sh        # Documentation sync detection hook
│   └── skills/                        # Custom skills
│       ├── code-review/SKILL.md       #   Code review (confidence scoring)
│       ├── refactor/SKILL.md          #   Refactoring
│       ├── release/SKILL.md           #   Release automation
│       └── sync-docs/SKILL.md         #   Documentation sync
│
└── tools/
    ├── scripts/                       # Utility scripts
    └── prompts/                       # Prompt templates
```

---

## Getting Started

### Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| [Claude Code](https://claude.ai/claude-code) | Master agent | `npm install -g @anthropic-ai/claude-code` |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli) | Speed Slave | `npm install -g @anthropic-ai/gemini-cli` |
| [Codex CLI](https://github.com/openai/codex) | Precision Slave | `npm install -g @openai/codex` |
| [Kiro CLI](https://kiro.dev) | Spec Slave | See Kiro official install guide |

### Installation

```bash
git clone <repository-url> multi-agent
cd multi-agent
```

### Usage

**Method 1: Inside Claude Code (recommended)**

Prefix your prompt with `#mode` in a Claude Code session.

```
#scan  Analyze CloudWatch error patterns from the last hour
#verify  Review this IAM policy
#mobilize  Add column to production DB — 50M rows, zero downtime required
```

Master (Claude) determines the mode and delegates via `ai-delegate.sh`.

**Method 2: Direct script execution**

```bash
# Delegate to Slaves
bash scripts/ai-delegate.sh scan "Analyze CloudWatch logs"
bash scripts/ai-delegate.sh verify "Review IAM policy"
bash scripts/ai-delegate.sh mobilize "Validate production deployment"

# Simulation (dry run)
bash scripts/simulate.sh all

# Structure validation
bash scripts/validate.sh all
```

---

## Usecase Catalog

15 real-world usecases organized by role.

Full document: [`docs/superpowers/specs/2026-03-26-usecase-catalog-design.md`](docs/superpowers/specs/2026-03-26-usecase-catalog-design.md)

| Role | UC | Scenario | Mode |
|------|-----|---------|------|
| **DevOps** | UC1 | IAM policy review | `#verify` |
| | UC2 | CloudWatch bulk log analysis | `#scan` |
| | UC3 | Terraform module refactoring | `#build` |
| | UC4 | CI/CD pipeline incident | `#mobilize` |
| | UC5 | ECS autoscaling tuning | `#craft` |
| **SRE** | UC6 | Production P1 incident response | `#mobilize` |
| | UC7 | SLO-based alerting setup | `#verify` |
| | UC8 | Cost anomaly detection | `#scan` |
| | UC9 | Disaster recovery runbook | `#design` |
| | UC10 | Security audit automation | `#verify`→`#mobilize` |
| **Developer** | UC11 | Legacy API migration | `#build` |
| | UC12 | Bulk unit test generation | `#craft` |
| | UC13 | PR code review automation | `#verify` |
| | UC14 | New microservice design | `#design` |
| | UC15 | Production DB migration | `#mobilize` |

---

## Policy Management (Hub & Spoke)

Policies are centrally managed in `claude-policies/`. Modify the Hub once, all agents reflect the change.

```
claude-policies/  ← Hub (Single Source of Truth)
├── common/
│   ├── 4-block-format.md       ← Output format (all agents reference this)
│   ├── aws-conventions.md      ← AWS naming/tagging rules
│   └── security-baseline.md    ← Security baseline
└── multi-agent/
    ├── modes.md                ← 7 mode definitions
    └── escalation-rules.md     ← Escalation/de-escalation rules

CLAUDE.md   ──┐
GEMINI.md   ──┼── Each agent "references" Hub policies (no copy)
AGENTS.md   ──┤
steering.md ──┘
```

---

## Validation & Simulation

```bash
# Full structure validation (PASS/WARN/FAIL)
bash scripts/validate.sh all

# Per-scenario simulation
bash scripts/simulate.sh scan        # Gemini speed test
bash scripts/simulate.sh build      # Kiro→Codex pipeline
bash scripts/simulate.sh mobilize   # 4-Agent sequential
bash scripts/simulate.sh all        # All scenarios
```
