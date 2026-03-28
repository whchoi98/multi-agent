---
sidebar_position: 1
title: DevOps편 (UC1-5)
description: IAM 정책 검토, 로그 분석, Terraform 리팩토링, CI/CD 장애, 오토스케일링 튜닝
---

# DevOps편 (UC1-5)

## UC1. IAM 정책 변경 검토 — `@verify`

### Pain Point

> *"S3 버킷 접근 권한을 추가했는데, 리뷰어가 `s3:*` 와일드카드를 놓쳤습니다. 3일 뒤 보안팀에서 연락이 왔습니다 — 전체 버킷이 퍼블릭 읽기 가능 상태였습니다."*

IAM 정책 변경은 **가장 흔하면서도 가장 위험한** DevOps 작업입니다.

### 왜 `@verify`인가?

- IAM은 보안 관련 코드 변경 → `@ask → @verify` 자동 승격 대상
- Gemini(속도)가 빠르게 패턴 매칭, Codex(정밀)가 로직 검증 → Master가 최종 판정

### 예제 출력 (Master 최종 판정)

```
## 결론
IAM 정책에 2건의 고위험 이슈 발견. 수정 없이 적용 불가.

| # | 위험도 | 항목 | Gemini | Codex | 채택 |
|---|--------|------|--------|-------|------|
| 1 | Critical | kms:* 와일드카드 | ⚠ 감지 | ✅ 상세 분석 | Codex |
| 2 | Medium | s3:DeleteObject 포함 | ✅ 감지 | ✅ 감지 | 합의 |
| 3 | Low | Condition 블록 부재 | ❌ 누락 | ✅ 감지 | Codex |

## 근거
- Gemini: 5초 만에 kms:* 와일드카드를 감지했으나, 구체적 대안 제시 부족
- Codex: kms:* → kms:Decrypt, kms:GenerateDataKey로 축소 권고
- Master 판정: Codex가 더 정밀. Gemini의 속도 + Codex의 깊이를 병합

## 리스크
- kms:* 유지 시: 모든 KMS 키에 대한 전체 작업 가능 (키 삭제 포함)
- DeleteObject 유지 시: 실수로 프로덕션 데이터 삭제 가능

## 실행안
kms:* → kms:Decrypt, kms:GenerateDataKey로 변경
Condition 블록에 aws:SourceVpc 제한 추가
```

:::tip Insight
단독 에이전트는 kms:*를 지적할 수 있지만, "그러면 뭘 써야 하는데?"에 대한 실용적 대안은 **교차검증에서** 나옵니다.
:::

---

## UC2. CloudWatch 로그 대량 분석 — `@scan`

### Pain Point

> *"새벽 3시에 알림이 울렸습니다. ECS 태스크가 OOMKilled로 반복 재시작 중. CloudWatch에 10만 줄의 로그가 쌓여있습니다."*

### 왜 `@scan`인가?

대규모 로그 분석은 **속도가 생명**입니다. Gemini(Speed)가 대량 데이터를 빠르게 스캔합니다.

### 예제 출력

```
## 결론
OOMKilled 원인: 메모리 누수 (30분 주기 배치 잡이 메모리 해제 실패)
최근 1시간 로그 108,432줄 분석 완료 (37초)

| 시간대 | OOMKilled 횟수 | 메모리 피크 | 트리거 |
|--------|---------------|------------|--------|
| 02:00-02:15 | 0 | 412MB / 512MB | - |
| 02:15-02:30 | 3 | 509MB → Kill | batch-processor cron |
| 02:30-02:45 | 5 | 511MB → Kill | batch-processor cron |

## 근거
1. OOMKilled 패턴이 정확히 15분 간격으로 발생 → cron job 연관
2. batch-processor 컨테이너의 힙 사용량이 단조 증가
3. GC 로그 없음 → 메모리 해제 실패 (stream 미종료 추정)

## 실행안
1. 즉시: batch-processor desired count → 0 (출혈 차단)
2. 코드 수정: BatchJob.java:142 stream을 try-with-resources로 변경
3. 메모리 증설: 512MB → 1024MB (임시 완화)
```

---

## UC3. Terraform 모듈 리팩토링 — `@build`

### Pain Point

> *"VPC 모듈이 800줄짜리 monolith입니다. 팀원이 서브넷만 바꾸려다 NAT Gateway가 날아갔습니다."*

### 왜 `@build`인가?

Terraform 리팩토링은 **설계 없이 시작하면 재앙**입니다. Kiro가 설계 → Codex가 구현 → Master가 갭 분석.

### 예제 흐름

**Step 1: Kiro** — 변경 빈도 분석 기반 모듈 분리 설계

```
modules/
├── vpc-network/    # VPC + 서브넷 (변경 빈도: 주 2회)
├── vpc-nat/        # NAT Gateway + EIP (변경 빈도: 분기 1회)
└── vpc-routing/    # Route Table (변경 빈도: 월 1회)
```

**Step 2: Codex** — 코드 + state 이동 스크립트

```bash
#!/bin/bash
set -euo pipefail
terraform state mv 'aws_vpc.main' 'module.vpc-network.aws_vpc.this'
terraform plan -detailed-exitcode  # exit 0 = no changes
```

**Master 판정**: 충족률 95%, state backup 절차 보완 필요

:::tip Insight
`@build` 모드의 핵심은 Kiro가 **"왜 이렇게 분리하는가"를 설계**하고, Codex가 **"정확히 어떻게 구현하는가"를 코드로 작성**한다는 것입니다. Master는 둘 사이의 **갭(gap)**을 찾아 보완합니다.
:::

---

## UC4. CI/CD 파이프라인 장애 대응 — `@mobilize`

### Pain Point

> *"GitHub Actions 워크플로우가 deploy 스텝에서 실패합니다. 어제까지 잘 됐습니다. 인프라 변경? 코드 변경? 권한 만료?"*

### 왜 `@mobilize`인가?

CI/CD 장애는 **팀 전체의 배포를 차단**합니다. 3-Agent가 각자 다른 각도에서 분석합니다.

### 예제 흐름

| Step | Agent | 관점 | 결과 |
|------|-------|------|------|
| 1 | Kiro | 어디를 봐야 하는가 | 3개 영역 체크리스트 (GitHub/Terraform/IAM) |
| 2 | Codex | 무엇이 잘못되었는가 | 2일 전 Terraform에서 Pool ID 변경, workflow가 구 ID 참조 |
| 3 | Gemini | 어디까지 영향이 있는가 | staging은 이미 수정됨, prod만 누락 |

**Master: Go** — 단일 라인 변경으로 해결 (`github-pool` → `cicd-pool`)

---

## UC5. ECS 서비스 오토스케일링 튜닝 — `@craft`

### Pain Point

> *"CPU Target Tracking 70%로 설정했는데, 트래픽 피크 때 스케일아웃이 너무 느립니다."*

### 왜 `@craft`인가?

오토스케일링은 **숫자 하나가 비용과 가용성을 좌우**합니다. Codex(Precision)가 메트릭을 정밀 분석합니다.

### 핵심 결과

| 항목 | 현재값 → 변경값 | 이유 |
|------|---------------|------|
| CPU Target | 70% → 60% | 여유분 10% 확보 |
| Step Scaling (추가) | - → CPU>80% +4, >90% +6 | 급격한 스파이크 대응 |
| Max Capacity | 10 → 15 | 피크 시 12 + 버퍼 3 |
| Scale-out Cooldown | 300s → 60s | 빠른 반응 |
| 비용 영향 | $180/월 → $240/월 | +$60 (+33%) |

:::tip Insight
`@craft` 모드는 **숫자가 중요한 작업**에 최적입니다. "대략 낮추세요"가 아니라 "70→60, cooldown 300→60"처럼 **명확한 숫자**를 제시합니다.
:::
