---
sidebar_position: 2
title: 시스템 흐름도
description: 사용자 프롬프트부터 최종 판정까지의 전체 처리 흐름
---

# 시스템 흐름도

## 전체 처리 흐름

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

---

## 단독 모드 흐름

### @ask — Master 단독

```
사용자 → Master → 직접 처리 → 4-Block 출력
```

가장 단순한 흐름입니다. Slave 위임 없이 Master가 직접 답변합니다.

### @scan — Gemini 단독

```
사용자 → Master → Gemini (45초 제한)
                      │
                      ▼
                  Master 검증 → 4-Block 출력
```

Gemini의 결과를 Master가 검증한 후 출력합니다. 보안 리스크가 감지되면 `@verify`로 자동 승격될 수 있습니다.

### @craft — Codex 단독

```
사용자 → Master → Codex (90초 제한)
                      │
                      ▼
                  Master 검증 → 4-Block 출력
```

### @design — Kiro 단독

```
사용자 → Master → Kiro (120초 제한)
                      │
                      ▼
                  Master 검증 → 4-Block 출력
```

---

## 복합 모드 흐름

### @verify — 교차검증 (병렬)

```
사용자 → Master
             │
     ┌───────┴───────┐
     ▼               ▼
  Gemini           Codex
  (빠른 1차)      (정밀 2차)
     │               │
     └───────┬───────┘
             ▼
     Master 비교 판정
     ├ 차이점 식별
     ├ 각 차이에 대해 근거 기반 채택
     ├ 필요시 두 결과 병합
     └ 4-Block Format 출력
```

:::info 교차검증의 핵심 가치
Gemini와 Codex가 **동시에 독립적으로** 분석합니다. 서로의 결과를 보지 않으므로, 진정한 "두 번째 눈"이 됩니다. Master는 두 결과의 차이점을 식별하고, 각 이슈별로 더 적절한 쪽을 채택합니다.
:::

### @mobilize — 풀파이프라인 (순차)

```
사용자 → Master
             │
     Step 1: Kiro (설계/체크리스트)
             │ 설계 결과 전달
             ▼
     Step 2: Codex (코드/설정 검증)
             │ 검증 결과 전달
             ▼
     Step 3: Gemini (영향도 분석)
             │
             ▼
     Master 종합
     ├ 3단계 결과 통합
     ├ 단계 간 모순/누락 식별
     ├ Go/No-Go 판정
     └ 통합 체크리스트 + 4-Block 출력
```

:::warning 각 단계의 결과는 다음 단계의 입력이 됩니다
@mobilize는 **순차 파이프라인**입니다. Kiro의 설계가 Codex의 검증 범위를 결정하고, Codex의 검증 결과가 Gemini의 영향도 분석 범위를 결정합니다.
:::

### @build — 스펙→구현 (순차)

```
사용자 → Master
             │
     Step 1: Kiro (스펙/설계 생성)
             │ 스펙 전달
             ▼
     Step 2: Codex (스펙 기반 구현)
             │
             ▼
     Master 검증
     ├ 스펙 ↔ 구현 대조
     ├ 충족률 산출
     ├ 미충족 항목(갭) 식별
     └ 보완 사항 + 4-Block 출력
```

---

## Fallback 흐름

```
Slave 실행
    │
    ├─ 정상 완료 → Master 검증 → 출력
    │
    ├─ 타임아웃 → Master가 @ask로 fallback
    │
    ├─ 2회 연속 실패 → 해당 Slave 세션 비활성화
    │
    └─ 전체 Slave 실패 → Master 단독 + 사용자에게 상황 보고
```

Fallback은 **자동**입니다. 사용자가 개입할 필요 없이 Master가 판단하여 가장 적절한 대안을 선택합니다.
