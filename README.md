# Multi-Agent CLI

**[한국어](#한국어) | [English](#english)**

---

<a id="한국어"></a>

# 한국어

> 4개의 AI CLI 에이전트를 오케스트레이션하여 단독 에이전트의 한계를 넘는 결과를 도출하는 시스템

## 목차

- [개요](#개요)
- [왜 Multi-Agent인가?](#왜-multi-agent인가)
- [아키텍처](#아키텍처)
  - [에이전트 구성](#에이전트-구성)
  - [시스템 흐름도](#시스템-흐름도)
  - [에이전트 구성 옵션](#에이전트-구성-옵션)
- [하이브리드 모드 시스템](#하이브리드-모드-시스템)
  - [자동 감지 (기본)](#자동-감지-기본)
  - [수동 오버라이드 (@모드)](#수동-오버라이드-모드)
  - [자동 감지 키워드 매핑](#자동-감지-키워드-매핑)
- [7가지 실행 모드](#7가지-실행-모드)
  - [모드 상세](#모드-상세)
  - [모드 선택 가이드](#모드-선택-가이드)
  - [모드별 실행 흐름 상세](#모드별-실행-흐름-상세)
- [자동 승격/다운그레이드](#자동-승격다운그레이드)
- [4-Block Format](#4-block-format)
- [설치](#설치)
  - [방법 A: Claude Code Plugin](#방법-a-claude-code-plugin)
  - [방법 B: 대화형 설치 스크립트](#방법-b-대화형-설치-스크립트)
  - [방법 C: 수동 클론](#방법-c-수동-클론)
  - [사전 요구사항](#사전-요구사항)
- [사용법](#사용법)
  - [Claude Code 내에서 (권장)](#claude-code-내에서-권장)
  - [CLI 직접 실행](#cli-직접-실행)
- [프로젝트 구조](#프로젝트-구조)
- [유스케이스 카탈로그](#유스케이스-카탈로그)
- [실전 적용 가이드](#실전-적용-가이드)
  - [즉시 활용 가능한 사례](#즉시-활용-가능한-사례)
  - [AWS 연동이 필요한 사례](#aws-연동이-필요한-사례)
  - [Multi-Agent가 단독보다 확실히 나은 경우](#multi-agent가-단독보다-확실히-나은-경우)
  - [Master 단독이 더 효율적인 경우](#master-단독이-더-효율적인-경우)
  - [시스템의 본질적 가치](#시스템의-본질적-가치)
- [정책 관리 (Hub & Spoke)](#정책-관리-hub--spoke)
- [검증 및 시뮬레이션](#검증-및-시뮬레이션)
- [제거](#제거)

---

## 개요

Multi-Agent CLI는 4개의 AI CLI 에이전트를 오케스트레이션하여 DevOps, SRE, 개발 작업에서 단독 에이전트의 한계를 넘는 결과를 도출하는 시스템입니다.

**핵심 원칙:**
- 혼자 해도 되지만, 함께하면 놓치지 않는다
- 단독 에이전트는 80%의 답, Multi-Agent는 나머지 20% — 그 20%가 장애와 보안 사고의 차이
- 모든 출력은 4-Block Format (결론/근거/리스크/실행안)
- 프롬프트만 입력하면 Master가 최적 모드를 **자동 선택** — 모드를 외울 필요 없음

---

## 왜 Multi-Agent인가?

| 상황 | 단독 에이전트 | Multi-Agent |
|------|------------|-------------|
| IAM 정책 리뷰 | "문법은 맞습니다" | Gemini가 패턴 감지 + Codex가 PoC 작성 → **kms:* 와일드카드 발견** |
| 프로덕션 장애 | "RDS 확인하세요, Redis도요" | Kiro가 트리아지 → Codex가 근본 원인 특정 → Gemini가 영향도 분석 → **10분 만에 복구** |
| Terraform 리팩토링 | "모듈을 분리했습니다" (state 깨짐) | Kiro가 분리 설계 → Codex가 state mv 스크립트 작성 → **안전한 마이그레이션** |
| DB 마이그레이션 | "ALTER TABLE 하세요" | Kiro가 전략 설계 → Codex가 Pre-check → Gemini가 영향 분석 → **Go/No-Go 판정** |

---

## 아키텍처

### 에이전트 구성

| 에이전트 | 역할 | 강점 | 타임아웃 |
|---------|------|------|---------|
| **Claude** (Master) | 오케스트레이션 / 최종 판정 | 복합 추론, Judge 역할, 자동 모드 감지 | - |
| **Gemini** (Speed) | 속도 우선 처리 | 대량 분석, AWS API 호출, 로그 요약 | 45s |
| **Codex** (Precision) | 정밀도 우선 처리 | 코드 변경, 보안 검토, 테스트 작성 | 90s |
| **Kiro** (Spec) | 설계/스펙 생성 | 요구사항 분석, 아키텍처 설계, 태스크 분해 | 120s |

### 시스템 흐름도

```
사용자 프롬프트 (자동 감지 또는 @모드 오버라이드)
    │
    ▼
┌─────────────────────────────────────┐
│           Claude (Master)            │
│                                      │
│  1. @모드 접두어 확인 → 있으면 강제  │
│  2. 없으면 키워드 자동 감지          │
│  3. 승격/다운그레이드 판단           │
│  4. Slave 위임 또는 단독 처리        │
└──────────┬──────────────────────────┘
           │
     ┌─────┼──────────┬──────────────┐
     │     │          │              │
     ▼     ▼          ▼              ▼
   @ask  @scan     @craft         @design
  Master  Gemini    Codex           Kiro
  단독    (45s)     (90s)          (120s)
           │         │               │
           ▼         ▼               ▼
     ┌─────┴─────────┴───────────────┘
     │
     ▼
  @verify          @mobilize               @build
  Gemini+Codex     Kiro→Codex→Gemini       Kiro→Codex
  (병렬→비교)     (순차→Go/No-Go)        (스펙→구현→갭분석)
     │                │                     │
     └────────────────┼─────────────────────┘
                      ▼
               Master 최종 판정
               (4-Block Format)
```

### 에이전트 구성 옵션

모든 CLI를 설치할 필요 없습니다. 보유한 도구에 맞게 2/3/4-Agent로 구성할 수 있습니다.

| 구성 | 에이전트 | 사용 가능 모드 | 적합한 상황 |
|------|---------|--------------|-----------|
| **2-Agent** | Claude + Gemini | ask, scan | 빠른 분석 위주, Codex/Kiro 미설치 환경 |
| **3-Agent** | Claude + Gemini + Codex | ask, scan, craft, verify | 코드 작업 + 교차검증 필요 |
| **4-Agent** | Claude + Gemini + Codex + Kiro | **전체 7모드** | 설계 + 구현 + 검증 풀 파이프라인 |

`install.sh` 실행 시 대화형으로 선택할 수 있습니다.

---

## 하이브리드 모드 시스템

모드를 외울 필요 없습니다. **평소엔 자동, 필요할 때만 수동.**

### 자동 감지 (기본)

프롬프트만 입력하면 Master가 키워드를 분석하여 최적 모드를 자동 선택합니다.

```
이 IAM 정책 검토해줘
  → [verify 모드] IAM 보안 변경 감지 → Gemini + Codex 교차검증으로 실행합니다.

CloudWatch 로그 빨리 분석해줘
  → [scan 모드] 로그 + 속도 감지 → Gemini 속도우선으로 실행합니다.

프로덕션 DB에 컬럼 추가해야 해
  → [mobilize 모드] 프로덕션 + DB 변경 감지 → 4-Agent 총동원으로 실행합니다.
```

### 수동 오버라이드 (@모드)

자동 감지를 무시하고 특정 모드를 강제 지정할 때 사용합니다.

```
@scan 프로덕션 로그 확인해줘         ← 자동이면 mobilize지만 scan 강제
@verify 이 코드 한 번 더 봐줘       ← 자동이면 craft지만 verify 강제
```

### 자동 감지 키워드 매핑

| 우선순위 | 키워드 패턴 | 선택 모드 |
|---------|-----------|----------|
| 1 | 프로덕션 + (배포/롤백/삭제/마이그레이션/장애/P1) | **mobilize** |
| 2 | (IAM/SG/보안/인증/암호화) + (검토/변경/추가) | **verify** |
| 3 | (설계/아키텍처/요구사항/분리/런북) + 신규 | **design** |
| 4 | (리팩토링/마이그레이션/구현) + 설계 필요 | **build** |
| 5 | (로그/비용/대량/조회/요약) + 속도 암시 | **scan** |
| 6 | (코드/테스트/설정/수정/최적화) + 정밀 필요 | **craft** |
| 7 | 기본값 (미매칭) | **ask** |

---

## 7가지 실행 모드

### 모드 상세

| 모드 | 명칭 | 에이전트 | 실행 방식 | 적합한 작업 |
|------|------|---------|----------|-----------|
| `@ask` | 단독처리 | Claude | Master 단독 | 단순 질문, 파일 읽기/수정, 짧은 작업 |
| `@scan` | 속도우선 | Gemini | 단독 (45s) | 로그 분석, 비용 조회, 대량 데이터 요약 |
| `@craft` | 정밀분석 | Codex | 단독 (90s) | 코드 변경, 테스트 작성, 설정 검증 |
| `@design` | 설계먼저 | Kiro | 단독 (120s) | 요구사항 분석, 아키텍처 설계, 런북 작성 |
| `@verify` | 교차검증 | Gemini + Codex | 병렬 → 비교 | IAM 정책, 보안 변경, 코드 리뷰 |
| `@mobilize` | 총동원 | Kiro → Codex → Gemini | 순차 | 프로덕션 장애, 배포, DB 마이그레이션 |
| `@build` | 스펙→구현 | Kiro → Codex | 순차 | 리팩토링, API 마이그레이션, 신규 기능 |

### 모드 선택 가이드

```
"빨리 파악해야 해"          → @scan
"정확해야 해"              → @craft
"설계부터 해야 해"          → @design
"두 번 확인해야 해"         → @verify
"절대 실패하면 안 돼"       → @mobilize
"설계하고 바로 구현까지"     → @build
"간단한 거"               → @ask
```

### 모드별 실행 흐름 상세

**@verify (교차검증)**
```
사용자 요청 → Master
  ├─→ Gemini (빠른 1차 분석)  ─┐
  └─→ Codex  (정밀 2차 분석)  ─┤
                                ▼
                    Master 비교 판정
                    ├ 차이점 식별
                    ├ 근거별 채택
                    └ 병합 버전 생성
```

**@mobilize (총동원)**
```
사용자 요청 → Master
  1→ Kiro (설계/체크리스트)
       ▼ 설계 결과 전달
  2→ Codex (코드/설정 검증)
       ▼ 검증 결과 전달
  3→ Gemini (영향도 분석)
       ▼ 3단계 결과 통합
  Master → Go/No-Go 최종 판정
```

**@build (스펙→구현)**
```
사용자 요청 → Master
  1→ Kiro (스펙/설계 생성)
       ▼ 스펙 전달
  2→ Codex (스펙 기반 구현)
       ▼ 스펙↔구현 대조
  Master → 충족률 판정 + 갭 분석
```

---

## 자동 승격/다운그레이드

자동 감지 또는 수동 지정 후에도, 작업 특성에 따라 Master가 모드를 자동 조정합니다.

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

- Slave 타임아웃 → Master가 `@ask`로 fallback
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

| 이점 | 설명 |
|------|------|
| 일관성 | 누가 어떤 모드를 쓰든 같은 구조 |
| 의사결정 가속 | "결론"만 보면 됨 |
| 감사 추적 | 포스트모템에 그대로 사용 가능 |
| Master 종합 용이 | 구조화된 입력 = 구조화된 판정 |

---

## 설치

3가지 설치 방법을 제공합니다. 상황에 맞게 선택하세요.

### 방법 A: Claude Code Plugin

프로젝트 디렉토리를 오염시키지 않고, 어떤 프로젝트에서든 즉시 사용할 수 있습니다.

```bash
# GitHub에서 설치
claude plugins add github:whchoi98/multi-agent/plugin

# 또는 로컬 경로로 설치
git clone https://github.com/whchoi98/multi-agent.git
claude plugins add ./multi-agent/plugin
```

설치 후 아무 프로젝트에서 바로 사용:
```
cd ~/any-project
claude
> 이 IAM 정책 검토해줘    ← 자동으로 @verify 실행
```

### 방법 B: 대화형 설치 스크립트

**설치 범위**(프로젝트/사용자)와 **에이전트 구성**(2/3/4-Agent)을 대화형으로 선택합니다.

```bash
git clone https://github.com/whchoi98/multi-agent.git
cd multi-agent
bash install.sh
```

```
╔════════════════════════════════════════════════════╗
║       Multi-Agent CLI Installer v1.0.0            ║
╚════════════════════════════════════════════════════╝

  설치 범위를 선택하세요:
    1) 프로젝트 (.claude/)  — 현재 프로젝트에서만 사용
    2) 사용자   (~/.claude/) — 모든 프로젝트에서 사용

  에이전트 구성을 선택하세요:
    1) 2-Agent  Claude + Gemini               — ask, scan
    2) 3-Agent  Claude + Gemini + Codex       — + craft, verify
    3) 4-Agent  Claude + Gemini + Codex + Kiro — 전체 7모드
```

설치 후 CLI wrapper로 직접 실행:
```bash
multi-agent scan "CloudWatch 로그 분석"
multi-agent verify "IAM 정책 검토"
multi-agent --info    # 설치 정보 확인
```

### 방법 C: 수동 클론

```bash
git clone https://github.com/whchoi98/multi-agent.git
cd multi-agent
bash scripts/ai-delegate.sh verify "IAM 정책 검토"
```

### 사전 요구사항

| 도구 | 용도 | 필요 구성 | 설치 |
|------|------|----------|------|
| [Claude Code](https://claude.ai/claude-code) | Master | 2/3/4-Agent 모두 | `npm install -g @anthropic-ai/claude-code` |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli) | Speed Slave | 2/3/4-Agent 모두 | `npm install -g @google/gemini-cli` |
| [Codex CLI](https://github.com/openai/codex) | Precision Slave | 3/4-Agent | `npm install -g @openai/codex` |
| [Kiro CLI](https://kiro.dev) | Spec Slave | 4-Agent만 | Kiro 공식 설치 가이드 |

---

## 사용법

### Claude Code 내에서 (권장)

**자동 감지** — 프롬프트만 입력하면 Master가 최적 모드를 선택합니다.

```
이 IAM 정책 검토해줘
  → [verify 모드] Gemini + Codex 교차검증으로 실행합니다.

최근 1시간 CloudWatch 로그에서 에러 패턴 분석해줘
  → [scan 모드] Gemini 속도우선으로 실행합니다.

프로덕션 DB에 phone_number 컬럼 추가. 5천만 건, 무중단 필수.
  → [mobilize 모드] 4-Agent 총동원으로 실행합니다.
```

**수동 오버라이드** — `@모드`를 프롬프트 앞에 붙여 강제 지정합니다.

```
@scan 프로덕션 로그 빨리 확인해줘
@verify 이 코드 한 번 더 봐줘
@mobilize 프로덕션 배포 검증해줘
@build Terraform 모듈 리팩토링해줘
```

### CLI 직접 실행

```bash
# Slave 위임 (ai-delegate.sh)
bash scripts/ai-delegate.sh scan "CloudWatch 로그 분석"
bash scripts/ai-delegate.sh verify "IAM 정책 검토"
bash scripts/ai-delegate.sh mobilize "프로덕션 배포 검증"
bash scripts/ai-delegate.sh build "Terraform 리팩토링"

# CLI wrapper (install.sh로 설치한 경우)
multi-agent scan "CloudWatch 로그 분석"
multi-agent verify "IAM 정책 검토"

# 시뮬레이션 (dry run — 실제 CLI 없이 흐름 재현)
bash scripts/simulate.sh all

# 구조 검증
bash scripts/validate.sh all
```

---

## 프로젝트 구조

```
multi-agent/
├── CLAUDE.md                          # Master(Claude) 설정 + 자동 감지 규칙
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
│   ├── simulate.sh                    # 5개 시나리오 시뮬레이션
│   └── validate.sh                    # 6개 검증 시나리오 (PASS/WARN/FAIL)
│
├── plugin/                            # Claude Code Plugin (배포용)
│   ├── plugin.json                    #   플러그인 매니페스트
│   ├── agents/                        #   6개 에이전트 정의
│   ├── skills/                        #   6개 사용자 호출 스킬
│   ├── hooks/auto-detect.md           #   자동 모드 감지 훅
│   ├── policies/                      #   정책 (Hub 미러)
│   └── scripts/ai-delegate.sh         #   오케스트레이터 (CLAUDE_PLUGIN_ROOT 지원)
│
├── install.sh                         # 대화형 설치 (범위/에이전트 수 선택)
├── uninstall.sh                       # 제거 + PATH 정리
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
│   └── skills/                        # 커스텀 스킬 (code-review, refactor 등)
│
└── tools/
    ├── scripts/                       # 보조 스크립트
    └── prompts/                       # 프롬프트 템플릿
```

---

## 유스케이스 카탈로그

15개 실전 유스케이스가 역할별로 정리되어 있습니다. 각 유스케이스는 Pain Point → 단독 한계 → Multi-Agent 해법 → 예제 출력(4-Block) 구조입니다.

전체 문서: [`docs/superpowers/specs/2026-03-26-usecase-catalog-design.md`](docs/superpowers/specs/2026-03-26-usecase-catalog-design.md)

### DevOps편 (UC1-5)

| UC | 시나리오 | 모드 | 핵심 가치 |
|----|---------|------|----------|
| UC1 | IAM 정책 변경 검토 | `@verify` | Gemini가 빠르게 잡고, Codex가 정밀하게 고침 |
| UC2 | CloudWatch 로그 대량 분석 (10만 줄) | `@scan` | 37초 만에 OOMKilled 원인 특정 |
| UC3 | Terraform 모듈 리팩토링 | `@build` | Kiro가 설계 → Codex가 state mv 스크립트 작성 |
| UC4 | CI/CD 파이프라인 장애 대응 | `@mobilize` | 3-Agent가 각자 다른 각도에서 원인 추적 |
| UC5 | ECS 오토스케일링 튜닝 | `@craft` | "70→60, cooldown 300→60" 구체적 숫자 제시 |

### SRE편 (UC6-10)

| UC | 시나리오 | 모드 | 핵심 가치 |
|----|---------|------|----------|
| UC6 | 프로덕션 P1 장애 대응 | `@mobilize` | MTTR 30분 → 10분 (병렬 사고) |
| UC7 | SLO 기반 알림 설정 | `@verify` | Gemini(프레임워크) + Codex(수학적 정확성) 병합 |
| UC8 | 비용 이상 탐지 ($15K→$28K) | `@scan` | 28초 만에 Top 3 원인 + 절감 방안 |
| UC9 | 재해복구(DR) 런북 작성 | `@design` | 실제 엔드포인트가 포함된 즉시 실행 가능 런북 |
| UC10 | 보안 감사 대응 (87개 항목) | `@verify`→`@mobilize` | 자동 승격으로 72개 항목 자동 점검 |

### 개발자편 (UC11-15)

| UC | 시나리오 | 모드 | 핵심 가치 |
|----|---------|------|----------|
| UC11 | 레거시 SOAP→REST 마이그레이션 | `@build` | Strangler Fig 패턴 설계 + 프록시 구현 |
| UC12 | 유닛 테스트 일괄 생성 (47개 함수) | `@craft` | 커버리지 23%→84%, 의미 있는 assertion |
| UC13 | PR 코드 리뷰 자동화 | `@verify` | SQL injection PoC + 인증 누락 동시 감지 |
| UC14 | 신규 마이크로서비스 설계 | `@design` | 경계 결정 + 이벤트 드리븐 전환 설계 |
| UC15 | 프로덕션 DB 마이그레이션 (5천만 건) | `@mobilize` | Aurora Instant DDL + Pre-check + 영향도 분석 |

---

## 실전 적용 가이드

> 15개 유스케이스의 솔직한 현실 점검. 어디서 즉시 가치를 얻고, 어디에 추가 설정이 필요한지.

### 즉시 활용 가능한 사례

입력이 **코드/설정 파일/텍스트**이고, 출력이 **분석/코드/문서**인 작업은 지금 바로 실용적입니다.

| UC | 시나리오 | 모드 | 왜 바로 되는가 |
|----|---------|------|--------------|
| UC1 | IAM 정책 검토 | `@verify` | JSON 텍스트 분석 → 교차검증 즉시 작동 |
| UC3 | Terraform 리팩토링 | `@build` | 파일 기반 설계→구현. 외부 의존성 없음 |
| UC5 | 오토스케일링 튜닝 | `@craft` | 설정 파일 분석 + 수정안 제시 |
| UC9 | DR 런북 작성 | `@design` | Terraform/CloudFormation 읽고 설계 문서 생성 |
| UC11 | API 마이그레이션 | `@build` | 설계→구현 파이프라인. 코드 생성이 핵심 |
| UC12 | 테스트 일괄 생성 | `@craft` | 소스 분석 → 테스트 코드 생성. **가장 실용적** |
| UC13 | PR 코드 리뷰 | `@verify` | git diff 텍스트 기반. 즉시 가능 |
| UC14 | 마이크로서비스 설계 | `@design` | 코드 분석 → 설계 문서. Kiro 핵심 강점 |

### AWS 연동이 필요한 사례

**실시간 AWS API 호출**, **외부 시스템 접근**이 전제되는 작업은 추가 설정이 필요합니다.

| UC | 시나리오 | 모드 | 제약 사항 |
|----|---------|------|----------|
| UC2 | CloudWatch 로그 분석 | `@scan` | Gemini CLI의 AWS API 호출에 네트워크/인증 설정 필요 |
| UC4 | CI/CD 장애 대응 | `@mobilize` | GitHub Actions + Terraform state + git log 교차 확인 — Master 단독이 더 빠를 수 있음 |
| UC6 | P1 장애 대응 | `@mobilize` | 실시간 AWS 메트릭 조회 필요. Slave 타임아웃(45~120초) 제약 |
| UC8 | 비용 분석 | `@scan` | Cost Explorer API 호출 필요. Codex는 sandbox 네트워크 제한 |
| UC10 | 보안 감사 | `@mobilize` | 대량 AWS API 호출 — aws cli 스크립트가 더 현실적일 수 있음 |
| UC15 | DB 마이그레이션 | `@mobilize` | Pre-check 스크립트는 유용하지만 실행은 DBA가 직접 수행 |

### Multi-Agent가 단독보다 확실히 나은 경우

```
1. 교차검증이 필요할 때 (@verify)
   → IAM 리뷰, 코드 리뷰에서 "두 번째 눈"의 가치는 실재
   → Gemini가 놓치는 인증 누락을 Codex가 잡고, Codex가 놓치는 컨벤션을 Gemini가 잡음

2. 설계→구현 파이프라인 (@build)
   → "설계한 것과 구현한 것이 일치하는가?" 자체 검증이 가능
   → 단독 에이전트는 자기가 빠뜨린 것을 자기가 발견하기 어려움

3. 대량 코드 생성/분석 (@craft)
   → 테스트 생성, 리팩토링처럼 반복적이지만 정확해야 하는 작업
   → 비즈니스 로직을 이해한 의미 있는 테스트 vs assert is not None
```

### Master 단독이 더 효율적인 경우

```
1. AWS 실시간 조회
   → Claude가 MCP/도구로 직접 호출하는 게 Slave 위임보다 빠름

2. 장애 대응 초기 5분
   → Slave 타임아웃 기다리는 동안 상황이 악화될 수 있음
   → Master가 먼저 빠르게 파악 후, 심층 분석만 Slave에 위임하는 것이 현실적

3. 컨텍스트가 풍부한 작업
   → 대화 맥락, 이전 작업 이력 등 Slave에게 전달하기 어려운 배경 지식이 많은 경우

4. 단순 질문/수정
   → 3-Agent 오케스트레이션 오버헤드가 답변 지연만 유발
```

### 시스템의 본질적 가치

유스케이스 카탈로그의 **진짜 가치**는 특정 사례의 실행 여부가 아니라, 세 가지 구조적 이점에 있습니다.

| 가치 | 설명 | 에이전트 없이도 적용 가능 |
|------|------|----------------------|
| **사고 프레임워크** | "이 상황에서 뭘 먼저 해야 하지?"에 대한 구조화된 접근법 | Yes — 모드 선택 가이드만으로도 의사결정 품질 향상 |
| **4-Block Format** | 결론→근거→리스크→실행안 형식이 의사결정을 강제 구조화 | Yes — 포스트모템, 설계 리뷰에 즉시 적용 가능 |
| **자동 승격 규칙** | "이건 더 신중하게 해야 해"를 시스템이 판단 | Yes — 체크리스트로 사용하면 사람의 판단도 개선 |

> **핵심 인사이트**: 15개 사례 중 **8개는 지금 바로 실용적**이고, **7개는 AWS 연동 설정이 전제**됩니다.
> 하지만 가장 큰 가치는 개별 사례의 실행이 아니라, **"이 작업은 어떤 수준의 신중함이 필요한가?"라는 판단 체계** 자체입니다.
> 이것은 에이전트 없이도 팀의 의사결정을 개선합니다.

---

## 정책 관리 (Hub & Spoke)

정책은 `claude-policies/`에서 중앙 관리합니다. Hub만 수정하면 모든 에이전트에 반영됩니다.

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
# 전체 구조 검증 (6개 시나리오, PASS/WARN/FAIL)
bash scripts/validate.sh all

# 개별 검증
bash scripts/validate.sh 1   # 자동 승격 (ask → verify)
bash scripts/validate.sh 2   # @design 단독 (Kiro 설계 품질)
bash scripts/validate.sh 3   # @build 스펙↔구현 정합성
bash scripts/validate.sh 4   # @mobilize 단계 간 데이터 흐름
bash scripts/validate.sh 5   # 타임아웃 fallback
bash scripts/validate.sh 6   # @verify 결과 일치 시 판정

# 시나리오 시뮬레이션 (실제 CLI 없이 흐름 재현)
bash scripts/simulate.sh scan        # SG 전수 검사
bash scripts/simulate.sh verify      # IAM 교차 검증
bash scripts/simulate.sh build       # Lambda@Edge canary 배포
bash scripts/simulate.sh mobilize    # RDS 메이저 업그레이드
bash scripts/simulate.sh downgrade   # 자동 다운그레이드 시연
bash scripts/simulate.sh all         # 전체 시나리오
```

---

## 제거

```bash
# 대화형 제거 (프로젝트/사용자 레벨 모두 감지)
bash uninstall.sh

# 또는 수동 제거
rm -rf ~/.claude/plugins/multi-agent      # 사용자 레벨
rm -rf .claude/plugins/multi-agent        # 프로젝트 레벨
```

---

---

<a id="english"></a>

# English

> Orchestrate 4 AI CLI agents to produce results that exceed any single agent's capabilities

## Table of Contents

- [Overview](#overview)
- [Why Multi-Agent?](#why-multi-agent)
- [Architecture](#architecture-1)
  - [Agent Roles](#agent-roles)
  - [System Flow](#system-flow)
  - [Agent Configuration Options](#agent-configuration-options)
- [Hybrid Mode System](#hybrid-mode-system)
  - [Auto-Detect (Default)](#auto-detect-default)
  - [Manual Override (@mode)](#manual-override-mode)
  - [Auto-Detect Keyword Mapping](#auto-detect-keyword-mapping)
- [7 Execution Modes](#7-execution-modes)
  - [Mode Details](#mode-details)
  - [Mode Selection Guide](#mode-selection-guide-1)
  - [Mode Execution Flows](#mode-execution-flows)
- [Auto Escalation/De-escalation](#auto-escalationde-escalation)
- [4-Block Output Format](#4-block-output-format)
- [Installation](#installation)
  - [Method A: Claude Code Plugin](#method-a-claude-code-plugin)
  - [Method B: Interactive Install Script](#method-b-interactive-install-script)
  - [Method C: Manual Clone](#method-c-manual-clone)
  - [Prerequisites](#prerequisites)
- [Usage](#usage)
  - [Inside Claude Code (Recommended)](#inside-claude-code-recommended)
  - [Direct CLI Execution](#direct-cli-execution)
- [Project Structure](#project-structure-1)
- [Usecase Catalog](#usecase-catalog)
- [Practical Application Guide](#practical-application-guide)
  - [Immediately Actionable Usecases](#immediately-actionable-usecases)
  - [Usecases Requiring AWS Integration](#usecases-requiring-aws-integration)
  - [Where Multi-Agent Clearly Outperforms Solo](#where-multi-agent-clearly-outperforms-solo)
  - [Where Master Solo is More Efficient](#where-master-solo-is-more-efficient)
  - [The System's Fundamental Value](#the-systems-fundamental-value)
- [Policy Management (Hub & Spoke)](#policy-management-hub--spoke)
- [Validation & Simulation](#validation--simulation)
- [Uninstall](#uninstall)

---

## Overview

Multi-Agent CLI is an orchestration system where **Claude (Master)** coordinates three Slave agents — **Gemini (Speed)**, **Codex (Precision)**, and **Kiro (Spec)** — to produce results that exceed what any single agent can achieve alone.

**Core Principles:**
- One agent gives 80% of the answer. Multi-agent catches the remaining 20% — the difference between an incident and a near-miss.
- All outputs follow the 4-Block Format (Conclusion / Rationale / Risks / Action Plan).
- Just type your prompt — Master **auto-detects** the optimal mode. No need to memorize modes.
- Slaves are read-only. Only Master executes changes with user approval.

---

## Why Multi-Agent?

| Scenario | Single Agent | Multi-Agent |
|----------|-------------|-------------|
| IAM policy review | "Syntax is valid" | Gemini detects pattern + Codex writes PoC → **kms:* wildcard caught** |
| Production incident | "Check RDS, also Redis" | Kiro triages → Codex finds root cause → Gemini analyzes impact → **10min MTTR** |
| Terraform refactoring | "Split the modules" (state broken) | Kiro designs split → Codex writes state mv script → **Safe migration** |
| DB migration | "ALTER TABLE" | Kiro designs strategy → Codex writes pre-check → Gemini analyzes impact → **Go/No-Go verdict** |

---

## Architecture

### Agent Roles

| Agent | Role | Strengths | Timeout |
|-------|------|-----------|---------|
| **Claude** (Master) | Orchestration / Final Judge | Complex reasoning, auto-detect, synthesis | - |
| **Gemini** (Speed) | Fast analysis | Bulk queries, log analysis, AWS API calls | 45s |
| **Codex** (Precision) | Precise operations | Code changes, security review, test generation | 90s |
| **Kiro** (Spec) | Design & specification | Requirements analysis, architecture design, task decomposition | 120s |

### System Flow

```
User Prompt (auto-detect or @mode override)
    │
    ▼
┌─────────────────────────────────────┐
│           Claude (Master)            │
│                                      │
│  1. Check @mode prefix → use if set │
│  2. Otherwise, auto-detect keywords │
│  3. Apply escalation/de-escalation  │
│  4. Delegate to Slaves or solo      │
└──────────┬──────────────────────────┘
           │
     ┌─────┼──────────┬──────────────┐
     │     │          │              │
     ▼     ▼          ▼              ▼
   @ask  @scan     @craft         @design
  Master  Gemini    Codex           Kiro
  solo    (45s)     (90s)          (120s)
           │         │               │
           ▼         ▼               ▼
     ┌─────┴─────────┴───────────────┘
     │
     ▼
  @verify          @mobilize               @build
  Gemini+Codex     Kiro→Codex→Gemini       Kiro→Codex
  (parallel→       (sequential→            (spec→implement
   compare)         Go/No-Go)               →gap analysis)
     │                │                     │
     └────────────────┼─────────────────────┘
                      ▼
               Master Final Verdict
               (4-Block Format)
```

### Agent Configuration Options

You don't need all CLIs installed. Choose the configuration that matches your toolset.

| Config | Agents | Available Modes | Best For |
|--------|--------|----------------|----------|
| **2-Agent** | Claude + Gemini | ask, scan | Quick analysis, no Codex/Kiro |
| **3-Agent** | Claude + Gemini + Codex | ask, scan, craft, verify | Code work + cross-validation |
| **4-Agent** | Claude + Gemini + Codex + Kiro | **All 7 modes** | Full design + implement + validate pipeline |

The `install.sh` script lets you choose interactively.

---

## Hybrid Mode System

No need to memorize modes. **Auto by default, manual when needed.**

### Auto-Detect (Default)

Just type your prompt. Master analyzes keywords and selects the optimal mode.

```
Review this IAM policy
  → [verify mode] IAM security change detected → Running Gemini + Codex cross-validation.

Analyze CloudWatch logs quickly
  → [scan mode] Log + speed detected → Running Gemini speed-first.

Add column to production DB — 50M rows
  → [mobilize mode] Production + DB change detected → Running 4-Agent full pipeline.
```

### Manual Override (@mode)

Override auto-detection when you know exactly which mode you want.

```
@scan Check production logs quickly       ← Forces scan even if auto would pick mobilize
@verify Double-check this code            ← Forces verify even if auto would pick craft
```

### Auto-Detect Keyword Mapping

| Priority | Keyword Pattern | Selected Mode |
|----------|----------------|---------------|
| 1 | production + (deploy/rollback/delete/migrate/incident/P1) | **mobilize** |
| 2 | (IAM/SG/security/auth/encryption) + (review/change/add) | **verify** |
| 3 | (design/architecture/requirements/split/runbook) + new | **design** |
| 4 | (refactor/migrate/implement) + design needed | **build** |
| 5 | (log/cost/bulk/query/summary) + speed implied | **scan** |
| 6 | (code/test/config/fix/optimize) + precision needed | **craft** |
| 7 | Default (no match) | **ask** |

---

## 7 Execution Modes

### Mode Details

| Mode | Name | Agent(s) | Execution | Best For |
|------|------|----------|-----------|----------|
| `@ask` | Solo | Claude | Master solo | Simple questions, file edits |
| `@scan` | Speed First | Gemini | Single (45s) | Log analysis, cost queries, bulk data |
| `@craft` | Precision First | Codex | Single (90s) | Code changes, tests, config validation |
| `@design` | Design First | Kiro | Single (120s) | Requirements, architecture, runbooks |
| `@verify` | Cross-Validation | Gemini + Codex | Parallel → Compare | IAM policies, security, code review |
| `@mobilize` | Full Pipeline | Kiro → Codex → Gemini | Sequential | Production incidents, deployments, DB migrations |
| `@build` | Spec-to-Impl | Kiro → Codex | Sequential | Refactoring, API migration, new features |

### Mode Selection Guide

```
"I need this fast"              → @scan
"This must be exact"            → @craft
"Design it first"               → @design
"Double-check this"             → @verify
"This cannot fail"              → @mobilize
"Design then implement"         → @build
"Just a quick thing"            → @ask
```

### Mode Execution Flows

**@verify (Cross-Validation)**
```
User request → Master
  ├─→ Gemini (fast 1st pass)    ─┐
  └─→ Codex  (precise 2nd pass) ─┤
                                   ▼
                       Master comparison
                       ├ Identify differences
                       ├ Judge each with rationale
                       └ Merge optimal version
```

**@mobilize (Full Pipeline)**
```
User request → Master
  1→ Kiro (design/checklist)
       ▼ pass design
  2→ Codex (code/config validation)
       ▼ pass validation
  3→ Gemini (impact analysis)
       ▼ integrate all 3 stages
  Master → Go/No-Go final verdict
```

**@build (Spec-to-Impl)**
```
User request → Master
  1→ Kiro (spec/design generation)
       ▼ pass spec
  2→ Codex (spec-based implementation)
       ▼ compare spec vs impl
  Master → Coverage verdict + gap analysis
```

---

## Auto Escalation/De-escalation

Even after auto-detection or manual selection, Master may adjust the mode based on task characteristics.

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

- Slave timeout → Master falls back to `@ask`
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

| Benefit | Description |
|---------|-------------|
| Consistency | Same structure regardless of mode or agent |
| Decision acceleration | Read "Conclusion" and act |
| Audit trail | Directly usable in postmortems |
| Master synthesis | Structured input = structured verdict |

---

## Installation

Three installation methods available. Choose what fits your situation.

### Method A: Claude Code Plugin

No project directory pollution. Use in any project instantly.

```bash
# Install from GitHub
claude plugins add github:whchoi98/multi-agent/plugin

# Or install from local path
git clone https://github.com/whchoi98/multi-agent.git
claude plugins add ./multi-agent/plugin
```

After installation, use in any project:
```
cd ~/any-project
claude
> Review this IAM policy    ← Auto-detects @verify
```

### Method B: Interactive Install Script

Choose **installation scope** (project/user) and **agent count** (2/3/4-Agent) interactively.

```bash
git clone https://github.com/whchoi98/multi-agent.git
cd multi-agent
bash install.sh
```

```
╔════════════════════════════════════════════════════╗
║       Multi-Agent CLI Installer v1.0.0            ║
╚════════════════════════════════════════════════════╝

  Select installation scope:
    1) Project (.claude/)  — Current project only
    2) User    (~/.claude/) — All projects

  Select agent configuration:
    1) 2-Agent  Claude + Gemini               — ask, scan
    2) 3-Agent  Claude + Gemini + Codex       — + craft, verify
    3) 4-Agent  Claude + Gemini + Codex + Kiro — All 7 modes
```

After installation, use the CLI wrapper:
```bash
multi-agent scan "Analyze CloudWatch logs"
multi-agent verify "Review IAM policy"
multi-agent --info    # Show installation info
```

### Method C: Manual Clone

```bash
git clone https://github.com/whchoi98/multi-agent.git
cd multi-agent
bash scripts/ai-delegate.sh verify "Review IAM policy"
```

### Prerequisites

| Tool | Purpose | Required For | Install |
|------|---------|-------------|---------|
| [Claude Code](https://claude.ai/claude-code) | Master | All configs | `npm install -g @anthropic-ai/claude-code` |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli) | Speed Slave | All configs | `npm install -g @google/gemini-cli` |
| [Codex CLI](https://github.com/openai/codex) | Precision Slave | 3/4-Agent | `npm install -g @openai/codex` |
| [Kiro CLI](https://kiro.dev) | Spec Slave | 4-Agent only | See Kiro official install guide |

---

## Usage

### Inside Claude Code (Recommended)

**Auto-detect** — Just type your prompt. Master selects the optimal mode.

```
Review this IAM policy
  → [verify mode] Running Gemini + Codex cross-validation.

Analyze CloudWatch error patterns from the last hour
  → [scan mode] Running Gemini speed-first analysis.

Add phone_number column to production users table. 50M rows, zero downtime.
  → [mobilize mode] Running 4-Agent full pipeline.
```

**Manual override** — Prefix with `@mode` to force a specific mode.

```
@scan Check production logs quickly
@verify Double-check this code
@mobilize Validate production deployment
@build Refactor Terraform modules
```

### Direct CLI Execution

```bash
# Slave delegation (ai-delegate.sh)
bash scripts/ai-delegate.sh scan "Analyze CloudWatch logs"
bash scripts/ai-delegate.sh verify "Review IAM policy"
bash scripts/ai-delegate.sh mobilize "Validate production deployment"
bash scripts/ai-delegate.sh build "Refactor Terraform modules"

# CLI wrapper (if installed via install.sh)
multi-agent scan "Analyze CloudWatch logs"
multi-agent verify "Review IAM policy"

# Simulation (dry run — replays flows without actual CLIs)
bash scripts/simulate.sh all

# Structure validation
bash scripts/validate.sh all
```

---

## Project Structure

```
multi-agent/
├── CLAUDE.md                          # Master (Claude) config + auto-detect rules
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
│   ├── simulate.sh                    # 5-scenario simulation
│   └── validate.sh                    # 6-scenario validation (PASS/WARN/FAIL)
│
├── plugin/                            # Claude Code Plugin (distributable)
│   ├── plugin.json                    #   Plugin manifest
│   ├── agents/                        #   6 agent definitions
│   ├── skills/                        #   6 user-invocable skills
│   ├── hooks/auto-detect.md           #   Auto mode detection hook
│   ├── policies/                      #   Policies (Hub mirror)
│   └── scripts/ai-delegate.sh         #   Orchestrator (CLAUDE_PLUGIN_ROOT support)
│
├── install.sh                         # Interactive installer (scope/agent selection)
├── uninstall.sh                       # Removal + PATH cleanup
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
│   └── skills/                        # Custom skills (code-review, refactor, etc.)
│
└── tools/
    ├── scripts/                       # Utility scripts
    └── prompts/                       # Prompt templates
```

---

## Usecase Catalog

15 real-world usecases organized by role. Each follows: Pain Point → Single-agent limit → Multi-agent solution → Example output (4-Block).

Full document: [`docs/superpowers/specs/2026-03-26-usecase-catalog-design.md`](docs/superpowers/specs/2026-03-26-usecase-catalog-design.md)

### DevOps (UC1-5)

| UC | Scenario | Mode | Key Value |
|----|---------|------|-----------|
| UC1 | IAM policy review | `@verify` | Gemini catches fast, Codex fixes precisely |
| UC2 | CloudWatch bulk log analysis (100K lines) | `@scan` | OOMKilled root cause in 37 seconds |
| UC3 | Terraform module refactoring | `@build` | Kiro designs → Codex writes state mv script |
| UC4 | CI/CD pipeline incident | `@mobilize` | 3 agents investigate from different angles |
| UC5 | ECS autoscaling tuning | `@craft` | Specific numbers: "70→60, cooldown 300→60" |

### SRE (UC6-10)

| UC | Scenario | Mode | Key Value |
|----|---------|------|-----------|
| UC6 | Production P1 incident | `@mobilize` | MTTR 30min → 10min (parallel thinking) |
| UC7 | SLO-based alerting setup | `@verify` | Gemini(framework) + Codex(math precision) merged |
| UC8 | Cost anomaly ($15K→$28K) | `@scan` | Top 3 causes + savings plan in 28 seconds |
| UC9 | Disaster recovery runbook | `@design` | Runbook with actual endpoints, ready to execute |
| UC10 | Security audit (87 items) | `@verify`→`@mobilize` | Auto-escalation, 72 items auto-checked |

### Developer (UC11-15)

| UC | Scenario | Mode | Key Value |
|----|---------|------|-----------|
| UC11 | Legacy SOAP→REST migration | `@build` | Strangler Fig design + proxy implementation |
| UC12 | Bulk unit test generation (47 functions) | `@craft` | Coverage 23%→84%, meaningful assertions |
| UC13 | PR code review automation | `@verify` | SQL injection PoC + missing auth detected |
| UC14 | New microservice design | `@design` | Boundary decisions + event-driven transition |
| UC15 | Production DB migration (50M rows) | `@mobilize` | Aurora Instant DDL + pre-check + impact analysis |

---

## Practical Application Guide

> An honest reality check of all 15 usecases. Where you get immediate value, and where additional setup is needed.

### Immediately Actionable Usecases

Tasks where the input is **code/config files/text** and the output is **analysis/code/documentation** work right out of the box.

| UC | Scenario | Mode | Why It Works Now |
|----|---------|------|-----------------|
| UC1 | IAM policy review | `@verify` | JSON text analysis → cross-validation works immediately |
| UC3 | Terraform refactoring | `@build` | File-based design→implementation. No external dependencies |
| UC5 | Autoscaling tuning | `@craft` | Config file analysis + concrete recommendations |
| UC9 | DR runbook creation | `@design` | Reads Terraform/CloudFormation and generates design docs |
| UC11 | API migration | `@build` | Design→implementation pipeline. Code generation is the core |
| UC12 | Bulk test generation | `@craft` | Source analysis → test code generation. **Most practical** |
| UC13 | PR code review | `@verify` | Git diff text-based analysis. Ready to use |
| UC14 | Microservice design | `@design` | Code analysis → design docs. Kiro's core strength |

### Usecases Requiring AWS Integration

Tasks that require **real-time AWS API calls** or **external system access** need additional setup.

| UC | Scenario | Mode | Constraint |
|----|---------|------|-----------|
| UC2 | CloudWatch log analysis | `@scan` | Gemini CLI needs AWS network/auth configuration |
| UC4 | CI/CD incident response | `@mobilize` | Cross-referencing GitHub Actions + Terraform state + git log — Master solo may be faster |
| UC6 | P1 incident response | `@mobilize` | Needs real-time AWS metrics. Slave timeouts (45~120s) are constraining |
| UC8 | Cost analysis | `@scan` | Needs Cost Explorer API. Codex has sandbox network limitations |
| UC10 | Security audit | `@mobilize` | Bulk AWS API calls — aws cli scripts may be more practical |
| UC15 | DB migration | `@mobilize` | Pre-check scripts are useful, but execution requires DBA hands |

### Where Multi-Agent Clearly Outperforms Solo

```
1. Cross-validation (@verify)
   → The "second pair of eyes" delivers real value in IAM reviews and code reviews
   → Gemini misses auth gaps that Codex catches; Codex misses conventions that Gemini catches

2. Design-to-Implementation pipeline (@build)
   → "Does the implementation match the spec?" becomes structurally verifiable
   → A single agent struggles to find gaps in its own output

3. Bulk code generation/analysis (@craft)
   → Tasks that are repetitive yet must be precise: test generation, refactoring
   → Business-logic-aware meaningful tests vs "assert is not None"
```

### Where Master Solo is More Efficient

```
1. Real-time AWS queries
   → Claude calling MCP/tools directly is faster than Slave delegation

2. First 5 minutes of incident response
   → Waiting for Slave timeouts while the situation worsens
   → Master does quick triage first, then delegates deep analysis to Slaves

3. Context-heavy tasks
   → Conversation history, prior work context — hard to pass to Slaves

4. Simple questions/edits
   → 3-Agent orchestration overhead only delays the response
```

### The System's Fundamental Value

The **real value** of the usecase catalog isn't whether specific scenarios execute — it's three structural advantages.

| Value | Description | Applicable Without Agents? |
|-------|-------------|--------------------------|
| **Thinking Framework** | Structured approach to "What should I do first in this situation?" | Yes — the mode selection guide alone improves decision quality |
| **4-Block Format** | Conclusion→Rationale→Risks→Action Plan forces structured decisions | Yes — immediately applicable to postmortems and design reviews |
| **Auto-Escalation Rules** | "This needs more caution" as a system-level judgment | Yes — used as a checklist, it improves human judgment too |

> **Key Insight**: Of the 15 usecases, **8 are immediately practical** and **7 require AWS integration setup**.
> But the greatest value isn't in executing individual scenarios — it's the **judgment framework of "What level of caution does this task require?"** itself.
> This improves team decision-making even without any agents running.

---

## Policy Management (Hub & Spoke)

Policies are centrally managed in `claude-policies/`. Modify the Hub once, all agents reflect the change.

```
claude-policies/  ← Hub (Single Source of Truth)
├── common/
│   ├── 4-block-format.md       ← Output format (all agents reference)
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
# Full structure validation (6 scenarios, PASS/WARN/FAIL)
bash scripts/validate.sh all

# Individual validations
bash scripts/validate.sh 1   # Auto escalation (ask → verify)
bash scripts/validate.sh 2   # @design solo (Kiro design quality)
bash scripts/validate.sh 3   # @build spec↔impl consistency
bash scripts/validate.sh 4   # @mobilize inter-stage data flow
bash scripts/validate.sh 5   # Timeout fallback
bash scripts/validate.sh 6   # @verify result agreement

# Scenario simulation (replays flows without actual CLIs)
bash scripts/simulate.sh scan        # SG full scan
bash scripts/simulate.sh verify      # IAM cross-validation
bash scripts/simulate.sh build       # Lambda@Edge canary deployment
bash scripts/simulate.sh mobilize    # RDS major upgrade
bash scripts/simulate.sh downgrade   # Auto de-escalation demo
bash scripts/simulate.sh all         # All scenarios
```

---

## Uninstall

```bash
# Interactive removal (detects both project and user installations)
bash uninstall.sh

# Or manual removal
rm -rf ~/.claude/plugins/multi-agent      # User-level
rm -rf .claude/plugins/multi-agent        # Project-level
```
