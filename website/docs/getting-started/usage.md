---
sidebar_position: 3
title: 사용법
description: Multi-Agent CLI를 Claude Code 내부 또는 CLI로 직접 사용하는 방법
---

# 사용법

## Claude Code 내에서 (권장)

### 자동 감지 — 프롬프트만 입력

프롬프트를 입력하면 Master가 키워드를 분석하여 **최적 모드를 자동 선택**합니다.

```
이 IAM 정책 검토해줘
  → [verify 모드] IAM 보안 변경 감지 → Gemini + Codex 교차검증으로 실행합니다.

최근 1시간 CloudWatch 로그에서 에러 패턴 분석해줘
  → [scan 모드] 로그 + 속도 감지 → Gemini 속도우선으로 실행합니다.

프로덕션 DB에 phone_number 컬럼 추가. 5천만 건, 무중단 필수.
  → [mobilize 모드] 프로덕션 + DB 변경 감지 → 4-Agent 총동원으로 실행합니다.
```

:::tip 자동 감지의 동작 원리
Master는 프롬프트에서 키워드 패턴을 분석합니다. 예를 들어:
- "IAM" + "검토" → **보안 관련** → `@verify`
- "프로덕션" + "배포" → **위험 작업** → `@mobilize`
- "로그" + "빨리" → **속도 우선** → `@scan`

자세한 키워드 매핑은 [하이브리드 모드](/modes/hybrid-mode)에서 확인할 수 있습니다.
:::

### 수동 오버라이드 — `@모드` 접두어

자동 감지를 무시하고 특정 모드를 **강제 지정**할 때 사용합니다.

```
@scan 프로덕션 로그 빨리 확인해줘         ← 자동이면 mobilize지만 scan 강제
@verify 이 코드 한 번 더 봐줘             ← 자동이면 craft지만 verify 강제
@mobilize 프로덕션 배포 검증해줘
@build Terraform 모듈 리팩토링해줘
```

---

## CLI 직접 실행

### ai-delegate.sh

Slave 위임 오케스트레이터 스크립트를 직접 호출합니다.

```bash
# 형식
bash scripts/ai-delegate.sh <mode> "<prompt>"

# 예제
bash scripts/ai-delegate.sh scan "CloudWatch 로그 분석"
bash scripts/ai-delegate.sh verify "IAM 정책 검토"
bash scripts/ai-delegate.sh mobilize "프로덕션 배포 검증"
bash scripts/ai-delegate.sh build "Terraform 리팩토링"
bash scripts/ai-delegate.sh craft "ECS 오토스케일링 최적화"
bash scripts/ai-delegate.sh design "알림 마이크로서비스 설계"
```

### CLI Wrapper (install.sh로 설치한 경우)

```bash
multi-agent scan "CloudWatch 로그 분석"
multi-agent verify "IAM 정책 검토"
multi-agent --info    # 설치 정보
multi-agent --help    # 도움말
```

### 시뮬레이션 (Dry Run)

실제 CLI 없이 실행 흐름을 재현합니다. **데모나 학습 목적**에 적합합니다.

```bash
bash scripts/simulate.sh scan        # SG 전수 검사
bash scripts/simulate.sh verify      # IAM 교차 검증
bash scripts/simulate.sh build       # Lambda@Edge canary 배포
bash scripts/simulate.sh mobilize    # RDS 메이저 업그레이드
bash scripts/simulate.sh downgrade   # 자동 다운그레이드 시연
bash scripts/simulate.sh all         # 전체 시나리오
```

---

## 실행 결과 예시

모든 결과는 **4-Block Format**으로 출력됩니다:

```
## 결론
IAM 정책에 2건의 고위험 이슈 발견. 수정 없이 적용 불가.

## 근거
- Gemini: 5초 만에 kms:* 와일드카드를 감지
- Codex: kms:* → kms:Decrypt, kms:GenerateDataKey로 축소 권고

## 리스크
- kms:* 유지 시: 모든 KMS 키에 대한 전체 작업 가능 (키 삭제 포함)

## 실행안
1. kms:* → kms:Decrypt, kms:GenerateDataKey로 변경
2. Condition 블록에 aws:SourceVpc 제한 추가
```
