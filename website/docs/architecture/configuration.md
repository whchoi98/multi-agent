---
sidebar_position: 3
title: 구성 옵션
description: 2/3/4-Agent 구성별 사용 가능 모드 및 설정 파일 구조
---

# 구성 옵션

## 에이전트 수별 구성

모든 CLI를 설치할 필요 없습니다. 보유한 도구에 맞게 선택하세요.

### 2-Agent (Claude + Gemini)

| 사용 가능 모드 | 설명 |
|--------------|------|
| `@ask` | Master 단독 |
| `@scan` | Gemini 속도우선 |

**적합한 상황**: 빠른 분석 위주, Codex/Kiro 미설치 환경

### 3-Agent (Claude + Gemini + Codex)

| 사용 가능 모드 | 설명 |
|--------------|------|
| `@ask` | Master 단독 |
| `@scan` | Gemini 속도우선 |
| `@craft` | Codex 정밀분석 |
| `@verify` | Gemini + Codex 교차검증 |

**적합한 상황**: 코드 작업 + 교차검증이 필요한 환경

### 4-Agent (Claude + Gemini + Codex + Kiro)

| 사용 가능 모드 | 설명 |
|--------------|------|
| `@ask` | Master 단독 |
| `@scan` | Gemini 속도우선 |
| `@craft` | Codex 정밀분석 |
| `@design` | Kiro 설계먼저 |
| `@verify` | Gemini + Codex 교차검증 |
| `@build` | Kiro → Codex 스펙→구현 |
| `@mobilize` | Kiro → Codex → Gemini 총동원 |

**적합한 상황**: 설계 + 구현 + 검증 풀 파이프라인

---

## 설정 파일 구조

각 에이전트는 자체 설정 파일을 가지며, 공통 정책은 Hub에서 참조합니다.

```
multi-agent/
├── CLAUDE.md                     # Master(Claude) 설정
│                                  # - 자동 감지 키워드 매핑
│                                  # - 승격/다운그레이드 규칙
│                                  # - Judge 역할 정의
│
├── GEMINI.md                     # Gemini Speed Slave 설정
│                                  # - 속도 최적화 규칙
│                                  # - 45초 타임아웃 가드레일
│
├── .codex/AGENTS.md              # Codex Precision Slave 설정
│                                  # - 정밀도 우선 규칙
│                                  # - Sandbox 제약 사항
│
├── .kiro/steering/steering.md    # Kiro Spec Slave 설정
│                                  # - 설계 품질 기준
│                                  # - 스펙 템플릿
│
└── claude-policies/              # Hub 정책 (Single Source of Truth)
    ├── common/
    │   ├── 4-block-format.md     # 출력 형식
    │   ├── aws-conventions.md    # AWS 컨벤션
    │   └── security-baseline.md  # 보안 기준선
    └── multi-agent/
        ├── modes.md              # 7가지 모드 정의
        └── escalation-rules.md   # 승격/다운그레이드 규칙
```

:::tip Hub & Spoke 구조
정책 변경 시 `claude-policies/` Hub만 수정하면 됩니다. 각 에이전트 설정 파일은 Hub를 **참조**만 하므로, 정책 불일치가 발생하지 않습니다.
:::

---

## 타임아웃 설정

| 에이전트 | 기본값 | 최소값 | 최대 권장값 |
|---------|--------|--------|----------|
| Gemini | 45초 | 15초 | 60초 |
| Codex | 90초 | 30초 | 120초 |
| Kiro | 120초 | 60초 | 180초 |

타임아웃 초과 시 Master가 자동으로 `@ask`로 fallback합니다. 타임아웃은 **가드레일**이며, 작업 안전을 위한 설계입니다.
