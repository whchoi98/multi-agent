---
sidebar_position: 1
title: Hub & Spoke 정책 관리
description: 중앙 집중 정책 관리 — Hub만 수정하면 모든 에이전트에 반영
---

# Hub & Spoke 정책 관리

## 구조

정책은 `claude-policies/`에서 **중앙 관리**합니다. Hub만 수정하면 모든 에이전트에 반영됩니다.

```
claude-policies/  ← Hub (Single Source of Truth)
├── common/
│   ├── 4-block-format.md       ← 출력 형식 (모든 에이전트 참조)
│   ├── aws-conventions.md      ← AWS 네이밍/태깅 규칙
│   └── security-baseline.md    ← 보안 기준선
└── multi-agent/
    ├── modes.md                ← 7가지 모드 정의
    └── escalation-rules.md     ← 승격/다운그레이드 규칙
```

### Spoke (에이전트별 설정)

```
CLAUDE.md   ──┐
GEMINI.md   ──┼── 각자 Hub 정책을 "참조"만 (복사하지 않음)
AGENTS.md   ──┤
steering.md ──┘
```

---

## 왜 Hub & Spoke인가?

| 문제 | Hub & Spoke 해법 |
|------|----------------|
| 정책이 에이전트마다 다르게 적용됨 | Hub가 **Single Source of Truth** |
| 정책 변경 시 모든 파일을 수동 업데이트 | Hub만 수정하면 자동 반영 |
| 어떤 정책이 최신인지 모름 | Hub가 항상 최신 |
| 에이전트 추가 시 정책 복사 필요 | 새 에이전트도 Hub만 참조 |

---

## 정책 파일 상세

### 4-Block Format (`common/4-block-format.md`)

모든 에이전트 출력이 따라야 하는 **필수 형식**입니다.

```markdown
## 결론
의사결정자가 이 블록만 읽고도 행동할 수 있어야 합니다.

## 근거
분석 과정, 참고 데이터, 대안 비교.

## 리스크
기술적/비즈니스/운영 리스크.

## 실행안
즉시 실행 항목, 후속 확인, 담당자 권장.
```

### AWS Conventions (`common/aws-conventions.md`)

- 리소스 네이밍: `{project}-{env}-{service}-{resource}`
- 태깅 표준: `Project`, `Environment`, `Owner`, `CostCenter`
- 리전 표기: `ap-northeast-2` (서울)

### Security Baseline (`common/security-baseline.md`)

- IAM: 최소 권한 원칙, MFA 필수
- 네트워크: SG 0.0.0.0/0 인바운드 금지
- 암호화: 저장/전송 중 암호화 필수
- 로깅: CloudTrail 전체 리전 활성화

---

## 정책 변경 절차

```
1. claude-policies/ Hub 파일 수정
2. 영향받는 에이전트 설정 확인 (참조가 유효한지)
3. bash scripts/validate.sh all (구조 검증)
4. 변경 사항 커밋
```

:::caution 정책 불일치 주의
에이전트 설정 파일에 정책을 **직접 작성하지 마세요**. 항상 Hub를 참조하도록 유지해야 합니다. 직접 작성하면 시간이 지나면서 Hub와 불일치가 발생합니다.
:::
