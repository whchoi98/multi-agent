---
sidebar_position: 1
title: 검증 및 시뮬레이션
description: 구조 검증 (6개 시나리오)과 시나리오 시뮬레이션 (5개 시나리오) 실행 방법
---

# 검증 및 시뮬레이션

## 구조 검증 (validate.sh)

6개 시나리오로 시스템 구조와 동작을 검증합니다.

```bash
# 전체 검증
bash scripts/validate.sh all

# 개별 검증
bash scripts/validate.sh 1   # 자동 승격 (ask → verify)
bash scripts/validate.sh 2   # @design 단독 (Kiro 설계 품질)
bash scripts/validate.sh 3   # @build 스펙↔구현 정합성
bash scripts/validate.sh 4   # @mobilize 단계 간 데이터 흐름
bash scripts/validate.sh 5   # 타임아웃 fallback
bash scripts/validate.sh 6   # @verify 결과 일치 시 판정
```

### 출력 형식

```
[PASS] 자동 승격 규칙 — ask → verify 정상 동작
[PASS] @design 단독 — Kiro 설계 품질 검증
[WARN] @build 스펙↔구현 — Codex 응답 시간 80초 (기준 90초)
[PASS] @mobilize 단계 간 — 데이터 흐름 검증
[PASS] 타임아웃 fallback — 정상 동작
[PASS] @verify 결과 일치 — 판정 검증
```

| 결과 | 의미 |
|------|------|
| `PASS` | 정상 동작 |
| `WARN` | 동작하지만 주의 필요 (타임아웃 근접 등) |
| `FAIL` | 동작하지 않음 — 수정 필요 |

---

## 시나리오 시뮬레이션 (simulate.sh)

실제 CLI 없이 **실행 흐름을 재현**합니다. 데모, 학습, 검증 목적에 적합합니다.

```bash
# 개별 시나리오
bash scripts/simulate.sh scan        # SG 전수 검사
bash scripts/simulate.sh verify      # IAM 교차 검증
bash scripts/simulate.sh build       # Lambda@Edge canary 배포
bash scripts/simulate.sh mobilize    # RDS 메이저 업그레이드
bash scripts/simulate.sh downgrade   # 자동 다운그레이드 시연

# 전체 시나리오
bash scripts/simulate.sh all
```

### 시뮬레이션 시나리오 상세

| 시나리오 | 모드 | 시뮬레이션 내용 |
|---------|------|-------------|
| `scan` | `@scan` | Security Group 0.0.0.0/0 인바운드 전수 검사 |
| `verify` | `@verify` | IAM 정책 Gemini/Codex 교차 검증 |
| `build` | `@build` | Lambda@Edge canary 배포 설계→구현 |
| `mobilize` | `@mobilize` | RDS 메이저 업그레이드 풀 파이프라인 |
| `downgrade` | 자동 | `@verify → @scan` 다운그레이드 시연 |

:::info 시뮬레이션은 실제 CLI를 호출하지 않습니다
simulate.sh는 각 에이전트의 예상 출력을 미리 정의된 템플릿으로 재현합니다. 실제 API 키나 CLI 설치가 불필요합니다.
:::
