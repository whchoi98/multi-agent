# Multi-Agent CLI 유스케이스 카탈로그

> **4-Agent 오케스트레이션이 실무에서 어떻게 쓰이는가?**
> 각 유스케이스는 Pain Point(현실의 고통) → 단독 처리 한계 → Multi-Agent 해법 → 예제 출력 순서로 전개합니다.

---

## 목차

| 편 | 유스케이스 | 모드 | 핵심 가치 |
|----|-----------|------|----------|
| **DevOps편** | UC1. IAM 정책 변경 검토 | `#cross` 교차검증 | 보안 실수 원천 차단 |
| | UC2. CloudWatch 로그 대량 분석 | `#quick` 속도우선 | 10만 줄 로그를 45초 만에 |
| | UC3. Terraform 모듈 리팩토링 | `#plan` 스펙→구현 | 설계 없는 리팩토링은 재앙 |
| | UC4. CI/CD 파이프라인 장애 대응 | `#critical` 풀파이프라인 | 장애 시 4-Agent 총동원 |
| | UC5. ECS 서비스 오토스케일링 튜닝 | `#precise` 정밀분석 | 숫자 하나가 비용을 좌우 |
| **SRE편** | UC6. 프로덕션 P1 장애 대응 | `#critical` 풀파이프라인 | 분 단위 의사결정 |
| | UC7. SLO 기반 알림 설정 | `#cross` 교차검증 | 알림 폭풍 vs 누락 사이 |
| | UC8. 비용 이상 탐지 분석 | `#quick` 속도우선 | 과금 폭탄 조기 발견 |
| | UC9. 재해복구(DR) 런북 작성 | `#spec` 설계먼저 | 런북은 설계의 산물 |
| | UC10. 보안 감사 대응 자동화 | `#cross`→`#critical` 자동승격 | 감사 대응은 교차검증+풀파이프라인 |
| **개발자편** | UC11. 레거시 API → REST 마이그레이션 | `#plan` 스펙→구현 | 스펙 없는 마이그레이션은 실패 |
| | UC12. 유닛 테스트 일괄 생성 | `#precise` 정밀분석 | 커버리지 80% 달성 |
| | UC13. PR 코드 리뷰 자동화 | `#cross` 교차검증 | 두 눈보다 네 눈 |
| | UC14. 신규 마이크로서비스 설계 | `#spec` 설계먼저 | 설계 먼저, 코드는 나중에 |
| | UC15. 프로덕션 DB 마이그레이션 | `#critical` 풀파이프라인 | 데이터는 되돌릴 수 없다 |

---

# DevOps편

---

## UC1. IAM 정책 변경 검토

### Pain Point

> "S3 버킷 접근 권한을 추가했는데, 리뷰어가 `s3:*` 와일드카드를 놓쳤습니다.
> 3일 뒤 보안팀에서 연락이 왔습니다 — 전체 버킷이 퍼블릭 읽기 가능 상태였습니다."

IAM 정책 변경은 **가장 흔하면서도 가장 위험한** DevOps 작업입니다.
JSON 한 줄의 실수가 조직 전체의 보안 경계를 무너뜨립니다.

### 단독 처리의 한계

단일 에이전트에게 IAM 정책 리뷰를 맡기면:
- 문법적으로는 맞지만 **과도한 권한**을 간과
- `Condition` 블록 누락을 지적하지 못함
- 최소 권한 원칙(Least Privilege) 위반을 탐지하지만, **실제 서비스에 필요한 권한**과 혼동

### Multi-Agent 해법: `#cross` (교차검증)

```
사용자: #cross 이 IAM 정책을 검토해줘
```

**왜 `#cross`인가?** IAM은 보안 관련 코드 변경 → `solo → cross` 자동 승격 대상입니다.
Gemini(속도)가 빠르게 패턴 매칭, Codex(정밀)가 로직 검증 → Master가 최종 판정.

### 예제 입력

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3DataAccess",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::prod-data-*",
        "arn:aws:s3:::prod-data-*/*"
      ]
    },
    {
      "Sid": "AllowKMSDecrypt",
      "Effect": "Allow",
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
```

### 예제 출력 (Master 최종 판정)

```
## 결론
IAM 정책에 **2건의 고위험 이슈** 발견. 수정 없이 적용 불가.

| # | 위험도 | 항목 | Gemini | Codex | 채택 |
|---|--------|------|--------|-------|------|
| 1 | 🔴 Critical | kms:* 와일드카드 | ⚠ 감지 | ✅ 상세 분석 | Codex |
| 2 | 🟡 Medium | s3:DeleteObject 포함 | ✅ 감지 | ✅ 감지 | 합의 |
| 3 | 🟢 Low | Condition 블록 부재 | ❌ 누락 | ✅ 감지 | Codex |

## 근거
- **Gemini**: 5초 만에 kms:* 와일드카드를 감지했으나, 구체적 대안 제시 부족
- **Codex**: kms:* → kms:Decrypt, kms:GenerateDataKey로 축소 권고.
  추가로 Condition 블록에 `aws:SourceVpc` 제한 필요성 지적 (Gemini는 누락)
- **Master 판정**: Codex가 더 정밀. Gemini의 속도 + Codex의 깊이를 병합

## 리스크
- kms:* 유지 시: 모든 KMS 키에 대한 전체 작업 가능 (키 삭제 포함)
- DeleteObject 유지 시: 실수로 프로덕션 데이터 삭제 가능
- Condition 미설정 시: VPC 외부에서도 접근 가능

## 실행안
수정된 정책:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3DataAccess",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::prod-data-lake",
        "arn:aws:s3:::prod-data-lake/*"
      ],
      "Condition": {
        "StringEquals": { "aws:SourceVpc": "vpc-0abc123def456" }
      }
    },
    {
      "Sid": "AllowKMSDecrypt",
      "Effect": "Allow",
      "Action": ["kms:Decrypt", "kms:GenerateDataKey"],
      "Resource": "arn:aws:kms:ap-northeast-2:123456789:key/mrk-xxx"
    }
  ]
}
```

> ★ **Insight**: 단독 에이전트는 kms:*를 지적할 수 있지만, "그러면 뭘 써야 하는데?"에 대한
> 실용적 대안은 교차검증에서 나옵니다. Gemini가 빠르게 잡고, Codex가 정밀하게 고칩니다.

---

## UC2. CloudWatch 로그 대량 분석

### Pain Point

> "새벽 3시에 알림이 울렸습니다. ECS 태스크가 OOMKilled로 반복 재시작 중.
> CloudWatch에 10만 줄의 로그가 쌓여있는데, grep으로는 패턴을 못 찾겠습니다."

대규모 로그 분석은 **속도가 생명**입니다. 장애 상황에서 90초 기다릴 여유가 없습니다.

### 단독 처리의 한계

- Claude 단독: 로그 파일을 읽을 수는 있지만, 10만 줄을 컨텍스트에 넣으면 느리고 비용 낭비
- Codex: 정밀하지만 45초 안에 끝내야 하는 상황에서 오버킬
- Kiro: 설계 에이전트에게 로그 분석은 역할 외

### Multi-Agent 해법: `#quick` (속도우선)

```
사용자: #quick 최근 1시간 CloudWatch 로그에서 OOMKilled 패턴 분석해줘
```

Gemini(Speed)가 대량 데이터를 빠르게 스캔하여 패턴을 추출합니다.

### 예제 출력 (Gemini → Master 검증)

```
## 결론
**OOMKilled 원인: 메모리 누수 (30분 주기 배치 잡이 메모리 해제 실패)**

최근 1시간 로그 108,432줄 분석 완료 (37초)

| 시간대 | OOMKilled 횟수 | 메모리 피크 | 트리거 |
|--------|---------------|------------|--------|
| 02:00-02:15 | 0 | 412MB / 512MB | - |
| 02:15-02:30 | 3 | 509MB → Kill | batch-processor cron |
| 02:30-02:45 | 5 | 511MB → Kill | batch-processor cron |
| 02:45-03:00 | 8 | 512MB → Kill | batch-processor cron |

## 근거
1. OOMKilled 패턴이 **정확히 15분 간격**으로 발생 → cron job 연관
2. 로그에서 `batch-processor` 컨테이너의 힙 사용량이 단조 증가
3. GC 로그 없음 → 메모리 해제 실패 (stream 미종료 추정)
4. 다른 컨테이너(api-server, worker)는 정상 범위

핵심 로그 라인:
```
02:15:03 batch-processor | java.lang.OutOfMemoryError: Java heap space
02:15:03 batch-processor | at com.example.BatchJob.processStream(BatchJob.java:142)
02:15:03 batch-processor | Caused by: stream not closed in finally block
```

## 리스크
- batch-processor 재시작 루프가 ECS 클러스터 리소스를 잠식 중
- 15분마다 악화 → 1시간 내 다른 서비스에도 영향 가능

## 실행안
1. **즉시**: batch-processor ECS 서비스 desired count → 0 (출혈 차단)
   ```bash
   aws ecs update-service --cluster prod --service batch-processor --desired-count 0
   ```
2. **코드 수정**: BatchJob.java:142 stream을 try-with-resources로 변경
3. **메모리 증설**: Task Definition에서 512MB → 1024MB (임시 완화)
4. **모니터링**: ContainerInsights 메모리 알림 임계값 80% 설정
```

> ★ **Insight**: `#quick` 모드는 "일단 빨리 파악"이 목적입니다. 만약 Gemini 결과에서
> 보안 리스크가 감지되면 Master가 자동으로 `#cross`로 승격합니다.
> 이 경우는 순수한 성능 이슈이므로 Gemini 단독으로 충분합니다.

---

## UC3. Terraform 모듈 리팩토링

### Pain Point

> "VPC 모듈이 800줄짜리 monolith입니다. 서브넷, NAT, 라우팅이 전부 한 파일에.
> 팀원이 서브넷만 바꾸려다 NAT Gateway가 날아갔습니다."

Terraform 리팩토링은 **설계 없이 시작하면 재앙**입니다. state drift, dependency graph 파괴, 리소스 재생성 — 모두 설계 부재에서 비롯됩니다.

### 단독 처리의 한계

- 단일 에이전트: 코드를 분리할 수는 있지만, state 이동 계획이 빠짐
- 설계 없이 `terraform apply` → 리소스 destroy & recreate 발생

### Multi-Agent 해법: `#plan` (스펙→구현)

```
사용자: #plan VPC 모듈을 서브넷/NAT/라우팅 3개 모듈로 분리해줘
```

Kiro(설계) → Codex(구현) → Master(검증) 파이프라인이 실행됩니다.

### 예제 출력

**Step 1: Kiro (Spec) — 모듈 분리 설계**
```
## 결론
VPC monolith를 3개 하위 모듈로 분리하는 설계를 작성합니다.

모듈 구조:
modules/
├── vpc-network/          # VPC + 서브넷
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── vpc-nat/              # NAT Gateway + EIP
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── vpc-routing/          # Route Table + Association
    ├── main.tf
    ├── variables.tf
    └── outputs.tf

## 근거
- 변경 빈도 분석: 서브넷(주 2회) > 라우팅(월 1회) > NAT(분기 1회)
- 변경 빈도가 다른 리소스를 분리해야 blast radius 최소화
- 모듈 간 의존성: network → nat → routing (단방향)

## 리스크
- `terraform state mv` 실패 시 리소스 orphan 발생
- 모듈 간 output 참조 누락 시 apply 에러

## 실행안
State 이동 계획 (순서 중요):
1. vpc-network 모듈 생성 + state mv (aws_subnet, aws_vpc)
2. vpc-nat 모듈 생성 + state mv (aws_nat_gateway, aws_eip)
3. vpc-routing 모듈 생성 + state mv (aws_route_table, aws_route_table_association)
4. 각 단계 후 `terraform plan` → "No changes" 확인 필수
```

**Step 2: Codex (Precision) — 구현**
```
## 결론
Kiro 스펙 기반으로 3개 모듈 코드와 state 이동 스크립트를 생성합니다.

### modules/vpc-network/main.tf
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(var.tags, { Name = "${var.project}-vpc" })
}

resource "aws_subnet" "public" {
  for_each          = var.public_subnets
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = merge(var.tags, { Name = "${var.project}-pub-${each.key}" })
}

resource "aws_subnet" "private" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = merge(var.tags, { Name = "${var.project}-priv-${each.key}" })
}

### state 이동 스크립트 (migrate-state.sh)
#!/bin/bash
set -euo pipefail
echo "=== Step 1: VPC + Subnet → vpc-network ==="
terraform state mv 'aws_vpc.main' 'module.vpc-network.aws_vpc.this'
terraform state mv 'aws_subnet.public["a"]' 'module.vpc-network.aws_subnet.public["a"]'
terraform state mv 'aws_subnet.public["c"]' 'module.vpc-network.aws_subnet.public["c"]'
# ... (전체 서브넷)
terraform plan -detailed-exitcode  # exit 0 = no changes
echo "=== Step 2: NAT → vpc-nat ==="
terraform state mv 'aws_eip.nat' 'module.vpc-nat.aws_eip.this'
terraform state mv 'aws_nat_gateway.main' 'module.vpc-nat.aws_nat_gateway.this'
terraform plan -detailed-exitcode
echo "=== Step 3: Routing → vpc-routing ==="
terraform state mv 'aws_route_table.public' 'module.vpc-routing.aws_route_table.public'
terraform state mv 'aws_route_table.private' 'module.vpc-routing.aws_route_table.private'
terraform plan -detailed-exitcode
echo "✅ 모든 state 이동 완료. No changes 확인됨."

## 리스크
- for_each 키가 기존 리소스 주소와 불일치 시 destroy/recreate 발생
- state mv 전 반드시 state backup 필요: terraform state pull > backup.tfstate
```

**Master 최종 판정:**
```
## 결론
Kiro 스펙 충족률 **95%**. 1건 보완 필요.

| 스펙 항목 | Codex 구현 | 판정 |
|----------|-----------|------|
| 3개 모듈 분리 | ✅ | Pass |
| 단방향 의존성 | ✅ | Pass |
| state mv 스크립트 | ✅ | Pass |
| 각 단계 plan 검증 | ✅ | Pass |
| state backup 절차 | ⚠ 언급만 | 보완 필요 |

## 실행안
- migrate-state.sh 첫 줄에 `terraform state pull > backup-$(date +%s).tfstate` 추가
- 실행 전 `terraform plan` 한 번 더 돌려 현재 상태 clean 확인
```

> ★ **Insight**: `#plan` 모드의 핵심은 **Kiro가 "왜 이렇게 분리하는가"를 설계**하고,
> **Codex가 "정확히 어떻게 구현하는가"를 코드로 작성**한다는 것입니다.
> Master는 둘 사이의 **갭(gap)**을 찾아 보완합니다.

---

## UC4. CI/CD 파이프라인 장애 대응

### Pain Point

> "GitHub Actions 워크플로우가 deploy 스텝에서 실패합니다. 에러 로그는
> `Error: No hosted workload identity pool configured`인데, 어제까지 잘 됐습니다.
> 인프라 변경? 코드 변경? 권한 만료? 원인 모를 때가 가장 무섭습니다."

CI/CD 장애는 **팀 전체의 배포를 차단**합니다. 원인이 코드인지, 인프라인지, 권한인지 — 빠르게 좁혀야 합니다.

### 단독 처리의 한계

- 단일 에이전트: 에러 메시지만 보고 "OIDC 설정 확인하세요" 같은 일반적 답변
- 실제로는 최근 Terraform 변경에서 workload identity pool이 교체되었는데, 이를 파악하려면 git log + Terraform state + GitHub Actions 설정을 교차 확인해야 함

### Multi-Agent 해법: `#critical` (풀파이프라인)

```
사용자: #critical GitHub Actions deploy 실패 — "No hosted workload identity pool configured"
```

CI/CD 장애는 배포 차단이므로 `solo → critical` 자동 승격 대상입니다.

### 예제 출력

**Step 1: Kiro (Spec) — 장애 범위 분석 및 체크리스트**
```
## 결론
Workload Identity Pool 관련 장애. 점검 영역을 3개로 분류합니다.

### 장애 분류 체크리스트
- [ ] GitHub Actions: `.github/workflows/deploy.yml` OIDC 설정
- [ ] Terraform: Workload Identity Pool/Provider 리소스 상태
- [ ] IAM: Service Account 바인딩 및 권한
- [ ] 최근 변경 이력: git log --since="2d" 범위 확인

## 근거
에러 메시지 "No hosted workload identity pool configured"는 3가지 원인 가능:
1. Pool 자체가 삭제/교체됨 (Terraform)
2. Pool과 GitHub repo 매핑이 변경됨 (Provider attribute)
3. SA 바인딩이 끊어짐 (IAM)
```

**Step 2: Codex (Precision) — 코드/설정 검증**
```
## 결론
**근본 원인 발견**: 2일 전 Terraform 변경에서 Pool ID가 교체됨.
GitHub Actions의 `workload_identity_provider`가 구 Pool을 참조 중.

### 증거
1. `git log --since="2d" -- terraform/` 결과:
   - commit abc123: "refactor: rename workload identity pool"
   - `google_iam_workload_identity_pool.github` → `google_iam_workload_identity_pool.cicd`
   - Pool ID 변경: `github-pool` → `cicd-pool`

2. `.github/workflows/deploy.yml` line 34:
   ```yaml
   workload_identity_provider: projects/123/locations/global/workloadIdentityPools/github-pool/providers/github
   ```
   ↑ 구 Pool ID "github-pool" 참조 중 (현재는 "cicd-pool")

## 실행안
`.github/workflows/deploy.yml` line 34 수정:
github-pool → cicd-pool
```

**Step 3: Gemini (Speed) — 영향도 분석**
```
## 결론
영향 범위: deploy workflow만 영향. 다른 워크플로우는 무관.

### 영향 분석
| 워크플로우 | OIDC 사용 | 영향 |
|-----------|----------|------|
| deploy.yml | ✅ github-pool | 🔴 장애 |
| test.yml | ❌ | ✅ 정상 |
| lint.yml | ❌ | ✅ 정상 |
| staging-deploy.yml | ✅ cicd-pool | ✅ 정상 (이미 수정됨) |

staging-deploy.yml은 이미 cicd-pool을 참조 → 누군가 staging은 고쳤지만 prod를 놓침
```

**Master 최종 판정:**
```
## 결론
**Go — 수정 승인**. 단일 라인 변경으로 해결 가능.

## 근거
- Kiro: 3가지 가능한 원인 중 정확한 범위를 설정
- Codex: 근본 원인을 git log + 코드 대조로 정확히 특정
- Gemini: staging은 이미 수정된 사실을 발견 → 누락된 prod만 수정하면 됨
- 3-Agent 결과 간 모순 없음. 일관된 진단.

## 리스크
- 낮음: 단순 문자열 교체. 기능 변경 없음
- 주의: 향후 Terraform에서 Pool 이름 변경 시 workflow도 자동 업데이트되는 구조 필요

## 실행안
1. `.github/workflows/deploy.yml` L34: `github-pool` → `cicd-pool` 수정
2. PR 생성 후 deploy 재실행으로 검증
3. (후속) Terraform output → GitHub Actions 환경변수 연동으로 하드코딩 제거
```

> ★ **Insight**: `#critical`의 위력은 **각 에이전트가 다른 각도에서 문제를 봅니다**.
> Kiro는 "어디를 봐야 하는가", Codex는 "무엇이 잘못되었는가", Gemini는 "어디까지 영향이 있는가".
> Master는 이 세 관점을 **통합하여 Go/No-Go를 판정**합니다.

---

## UC5. ECS 서비스 오토스케일링 튜닝

### Pain Point

> "CPU Target Tracking 70%로 설정했는데, 트래픽 피크 때 스케일아웃이 너무 느립니다.
> Step Scaling으로 바꿔야 하나? 숫자를 어떻게 잡아야 하나?"

오토스케일링은 **숫자 하나가 비용과 가용성을 좌우**합니다. 감으로 잡으면 비용 폭탄 또는 서비스 다운.

### 단독 처리의 한계

- 일반적 답변: "Target Tracking 50%로 낮추세요" — 실제 트래픽 패턴 무시
- 비용 영향 분석 누락: 스케일아웃이 빨라지면 비용이 얼마나 증가하는지 모름

### Multi-Agent 해법: `#precise` (정밀분석)

```
사용자: #precise ECS api-server 서비스의 오토스케일링 설정 최적화해줘
```

Codex(Precision)가 현재 설정과 메트릭을 정밀 분석합니다.

### 예제 출력 (Codex → Master 검증)

```
## 결론
Target Tracking 단독 → **Target Tracking + Step Scaling 혼합** 전략 권장.

### 현재 설정 분석
| 항목 | 현재값 | 문제 |
|------|--------|------|
| Policy | Target Tracking | 반응 느림 (cooldown 300s) |
| CPU Target | 70% | 피크 시 이미 포화 |
| Min/Max | 2 / 10 | Max 부족 (피크 시 12 필요) |
| Cooldown | 300s (기본) | 스케일아웃까지 5분 지연 |

### 권장 설정
| 항목 | 변경값 | 이유 |
|------|--------|------|
| Target Tracking CPU | 60% | 여유분 10% 확보 |
| Step Scaling (추가) | CPU>80%→+4, CPU>90%→+6 | 급격한 스파이크 대응 |
| Max Capacity | 2 → 15 | 피크 시 12 + 버퍼 3 |
| Scale-out Cooldown | 300s → 60s | 빠른 반응 |
| Scale-in Cooldown | 300s → 300s (유지) | 플래핑 방지 |

### 비용 영향
| 시나리오 | 월간 비용 | 변화 |
|---------|----------|------|
| 현재 (평균 3대) | $180 | - |
| 변경 후 (평균 4대) | $240 | +$60 (+33%) |
| 피크 시 (최대 12대) | $720/일 비례 | 일시적 |

## 근거
최근 30일 CloudWatch 메트릭 분석:
- 평일 10-12시, 14-16시 피크 (CPU 85-95%)
- 스케일아웃 시작까지 평균 5분 12초 (cooldown 300s + 반응 지연)
- 이 5분간 P99 latency 2.3초 → 8.7초 급등

## 리스크
- Step Scaling + Target Tracking 혼합 시 스케일 경합 가능 → Step이 우선
- Scale-in cooldown이 너무 짧으면 플래핑 발생 (300s 유지로 방어)
- Max 15로 증가 시 Fargate vCPU 서비스 쿼터 확인 필요

## 실행안
1. CloudFormation / Terraform 설정 업데이트
2. 비피크 시간에 부하 테스트 (k6 또는 Artillery)로 스케일 반응 검증
3. 1주일 모니터링 후 숫자 재조정

### Terraform 예시
resource "aws_appautoscaling_policy" "cpu_target" {
  name               = "cpu-target-tracking"
  service_namespace  = "ecs"
  resource_id        = "service/prod/api-server"
  scalable_dimension = "ecs:service:DesiredCount"
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    target_value       = 60
    scale_out_cooldown = 60
    scale_in_cooldown  = 300
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
```

> ★ **Insight**: `#precise` 모드는 **숫자가 중요한 작업**에 최적입니다.
> Codex는 현재 설정을 읽고 → 메트릭과 대조하고 → 구체적인 숫자를 제시합니다.
> "대략 낮추세요"가 아니라 "70→60, cooldown 300→60"처럼 명확합니다.

---

# SRE편

---

## UC6. 프로덕션 P1 장애 대응

### Pain Point

> "금요일 오후 5시. 결제 서비스 API 응답시간이 30초를 넘겼습니다.
> PagerDuty가 울리고, Slack이 폭발하고, PM이 '언제 복구돼요?'라고 물어봅니다.
> RDS? Redis? 네트워크? 코드 배포? 원인을 모르는 상태에서 시계는 돌아갑니다."

P1 장애는 **MTTR(평균 복구 시간)이 곧 매출 손실**입니다. 30분 지연 = 수천만 원 손실.

### 단독 처리의 한계

- 단일 에이전트: "RDS 커넥션 풀 확인하세요, Redis 메모리도 보세요" — 모든 가능성을 나열만 함
- 장애 상황에서 필요한 건 나열이 아니라 **좁혀가기(narrowing down)**
- 하나의 에이전트가 설계, 검증, 영향도 분석을 순차적으로 하면 너무 느림

### Multi-Agent 해법: `#critical` (풀파이프라인)

```
사용자: #critical 결제 API P99 latency 30초 초과. 즉시 원인 분석 및 복구 방안
```

### 예제 출력

**Step 1: Kiro (Spec) — 장애 트리아지 체크리스트**
```
## 결론
P1 장애 트리아지 프레임워크를 제공합니다. 5개 레이어 순차 점검.

### 트리아지 체크리스트
Layer 1 — 인프라 (먼저 확인, 원인 가능성 40%)
- [ ] RDS: CPU, 커넥션 수, slow query log
- [ ] Redis: 메모리 사용률, eviction count, 커넥션 수
- [ ] ALB: 5xx 에러율, 타겟 그룹 healthy count

Layer 2 — 네트워크 (원인 가능성 20%)
- [ ] VPC Flow Logs: 드롭된 패킷
- [ ] NAT Gateway: 에러 카운트, 패킷 드롭
- [ ] Security Group: 최근 변경 이력

Layer 3 — 애플리케이션 (원인 가능성 25%)
- [ ] 최근 배포 이력 (1시간 내)
- [ ] ECS 태스크 상태, OOM 이벤트
- [ ] 애플리케이션 로그 에러 패턴

Layer 4 — 외부 의존성 (원인 가능성 10%)
- [ ] 3rd party API (PG사, 본인인증) 응답 시간
- [ ] AWS 서비스 상태 (status.aws.amazon.com)

Layer 5 — 데이터 (원인 가능성 5%)
- [ ] 테이블 lock, deadlock
- [ ] 비정상 데이터 유입 (대량 insert)
```

**Step 2: Codex (Precision) — 레이어별 검증**
```
## 결론
**근본 원인: RDS 커넥션 풀 고갈** (Layer 1)

### 검증 결과
| Layer | 항목 | 상태 | 증거 |
|-------|------|------|------|
| 1 | RDS CPU | 🔴 98% | CloudWatch CPUUtilization |
| 1 | RDS Connections | 🔴 450/450 (max) | DatabaseConnections metric |
| 1 | Slow Query | 🔴 12건/분 | slow_query_log |
| 1 | Redis | ✅ 정상 (메모리 62%) | - |
| 2 | Network | ✅ 정상 | Flow Logs clean |
| 3 | 최근 배포 | ⚠ 4시간 전 배포 | commit def789 |

### 근본 원인 체인
1. 4시간 전 배포(def789)에 N+1 쿼리 도입
2. 트래픽 증가와 함께 slow query 급증 (평균 2.3초 → 18초)
3. 커넥션 반환 지연 → 커넥션 풀 고갈 (450/450)
4. 새 요청이 커넥션 획득 대기 → 타임아웃 30초

### 문제 코드 (commit def789)
# 변경 전: JOIN으로 한 번에 조회
SELECT o.*, p.name FROM orders o JOIN products p ON o.product_id = p.id WHERE o.user_id = ?

# 변경 후: N+1 패턴
orders = Order.where(user_id: user_id)
orders.each { |o| o.product = Product.find(o.product_id) }  # ← N+1!
```

**Step 3: Gemini (Speed) — 영향도 및 복구 시나리오**
```
## 결론
영향 범위 및 3가지 복구 시나리오를 제시합니다.

### 영향 범위
| 서비스 | 영향 | 이유 |
|--------|------|------|
| 결제 API | 🔴 장애 | 직접 원인 |
| 주문 조회 | 🔴 장애 | 같은 RDS 사용 |
| 회원 서비스 | 🟡 지연 | 간접 영향 (커넥션 경합) |
| 상품 서비스 | ✅ 정상 | 별도 RDS |

### 복구 시나리오
| 옵션 | 소요 시간 | 리스크 |
|------|----------|--------|
| A. 롤백 (def789 이전) | 5분 | 낮음 (4시간 전 버전) |
| B. N+1 핫픽스 배포 | 30분 | 중간 (테스트 필요) |
| C. RDS max_connections 증가 | 2분 | 높음 (근본 해결 아님) |

권장: **옵션 A (즉시 롤백)** → 옵션 B (핫픽스) 순차 진행
```

**Master 최종 판정:**
```
## 결론
**Go — 옵션 A 즉시 실행 (롤백)**

3-Agent 결과 종합:
- Kiro의 트리아지 프레임워크 → Layer 1에서 조기 포착 (효율적)
- Codex의 코드 레벨 근본 원인 특정 → commit def789의 N+1 쿼리
- Gemini의 영향 분석 → 결제+주문 2개 서비스 영향, 롤백이 최선

## 근거
- 3-Agent 모두 **RDS 커넥션 고갈**을 지목 → 높은 신뢰도
- 롤백 대상(4시간 전)이 충분히 최신이고 안정적
- Gemini가 제시한 옵션 C(max_connections 증가)는 **근본 해결이 아님** → 기각

## 리스크
- 롤백 시 4시간 내 다른 변경사항도 함께 롤백됨 → git log 확인 필요
- 롤백 후에도 기존 커넥션이 완전히 해제되기까지 1-2분 소요

## 실행안
### 즉시 (MTTR 목표: 10분)
1. ECS 롤백: 이전 Task Definition revision 배포
   aws ecs update-service --cluster prod --service payment-api \
     --task-definition payment-api:42  # def789 이전 revision
2. RDS 커넥션 모니터링: 450 → 정상 수준(~150) 복귀 확인
3. P99 latency 모니터링: 30초 → <500ms 복귀 확인

### 후속 (24시간 내)
4. N+1 쿼리 핫픽스 PR 생성 + 리뷰
5. 핫픽스 배포 후 롤백 해제
6. 포스트모템 작성: N+1 탐지 CI 룰 추가 논의
```

> ★ **Insight**: P1 장애에서 `#critical`이 빛나는 이유는 **병렬 사고**입니다.
> 사람 한 명이 Layer 1~5를 순서대로 점검하면 30분. 3-Agent가 각자 다른 레이어를 맡으면 10분.
> Master의 역할은 "이 중 누구 말이 맞나?" 판정입니다.

---

## UC7. SLO 기반 알림 설정

### Pain Point

> "알림이 하루에 200개 옵니다. 대부분 무의미한 CPU 60% 알림입니다.
> 진짜 중요한 알림은 노이즈에 묻혀서, 정작 P1 발생 시 '또 거짓 양성이겠지' 하고 무시했습니다."

알림 설정은 **알림 폭풍(Alert Fatigue) vs 알림 누락** 사이의 줄타기입니다.
SLO 기반으로 전환하면 "비즈니스에 영향이 있을 때만" 알림이 울립니다.

### 단독 처리의 한계

- 단일 에이전트: SLO 개념은 설명하지만, **현재 서비스의 실제 SLI 데이터**를 기반으로 임계값을 계산하지 못함
- Error Budget 소진율 계산에서 수학적 오류 발생 가능
- 알림 설정 코드가 문법적으로 맞아도 **실제로 발동 조건이 적절한지** 검증 누락

### Multi-Agent 해법: `#cross` (교차검증)

```
사용자: #cross 결제 서비스의 SLO 기반 알림을 설정해줘. 현재 99.9% SLO 목표.
```

Gemini가 빠르게 SLO 계산 + 알림 설정 초안, Codex가 수학적 정확성 + 코드 검증.

### 예제 출력 (Master 최종 판정)

```
## 결론
SLO 99.9% 기반 **3-tier 알림 체계** 설정. 두 Slave 결과를 병합.

### Gemini vs Codex 비교
| 항목 | Gemini | Codex | 채택 |
|------|--------|-------|------|
| Error Budget 계산 | 월 43.2분 | 월 43.83분 | Codex (더 정밀) |
| Burn Rate 임계값 | 14.4x, 6x, 1x | 14.4x, 6x, 3x, 1x | Codex (4-tier) |
| 알림 채널 | Slack only | Slack + PagerDuty 분리 | Codex |
| CloudWatch 코드 | ✅ 작동 | ✅ 작동 + 테스트 포함 | Codex |
| 설명 가독성 | ★★★★★ | ★★★ | Gemini |

### 최종 알림 체계 (병합 버전)
| Tier | Burn Rate | Error Budget 소진 | 알림 | 채널 |
|------|-----------|-------------------|------|------|
| P1 | 14.4x | 1시간에 2% | 즉시 | PagerDuty |
| P2 | 6x | 6시간에 5% | 긴급 | Slack #incidents |
| P3 | 3x | 3일에 10% | 경고 | Slack #sre-alerts |
| P4 | 1x | 30일에 100% | 정보 | Slack #sre-metrics |

### Error Budget 계산 (Codex 채택)
- SLO: 99.9%
- Error Budget: 0.1% = 월 30일 × 24시간 × 60분 × 0.001 = **43.83분/월**
- Burn Rate 14.4x = 43.83분 ÷ (30일 × 24시간 ÷ 14.4) = 1시간에 약 2% 소진

## 근거
- Gemini: 30초 만에 전체 프레임워크를 잡았고, 설명이 탁월
- Codex: Error Budget 43.83분(Gemini의 43.2분은 30일=43200분에서 오산)
- Codex의 4-tier가 3-tier보다 세밀 (P3 경고 단계 추가로 조기 감지)
- PagerDuty 분리는 실무에서 필수 (Slack만으로는 새벽에 못 깨움)

## 리스크
- Burn Rate 알림은 **윈도우 크기**에 민감 — 5분 윈도우 vs 1시간 윈도우
- 초기에는 임계값이 너무 민감할 수 있음 → 2주 관찰 후 조정
- Error Budget이 빠르게 소진되면 feature freeze 의사결정 필요

## 실행안
### CloudWatch Alarm (Terraform)
resource "aws_cloudwatch_metric_alarm" "slo_p1_burn_rate" {
  alarm_name          = "payment-slo-p1-burn-14.4x"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5xxErrorRate"
  namespace           = "Custom/Payment"
  period              = 300  # 5분 윈도우
  statistic           = "Average"
  threshold           = 1.44  # 0.1% × 14.4 = 1.44%
  alarm_actions       = [aws_sns_topic.pagerduty.arn]
  ok_actions          = [aws_sns_topic.pagerduty.arn]
  treat_missing_data  = "notBreaching"
}

### 기존 알림 정리
- CPU 60% 알림 → 삭제 (SLI 아님)
- 디스크 80% 알림 → 유지 (인프라 기반, SLO와 별개)
- 5xx > 1% 알림 → SLO 알림으로 대체 → 삭제
```

> ★ **Insight**: `#cross`에서 Gemini는 "숲"을, Codex는 "나무"를 봅니다.
> SLO 설정은 **프레임워크(숲)**와 **수학적 정확성(나무)** 둘 다 필요하므로
> 교차검증이 최적입니다. Master는 둘을 병합하여 최선의 결과를 만듭니다.

---

## UC8. 비용 이상 탐지 분석

### Pain Point

> "월 AWS 비용이 갑자기 $15,000 → $28,000으로 뛰었습니다.
> Cost Explorer를 열어봤는데 서비스가 너무 많아서 어디서 튄 건지 모르겠습니다.
> 빨리 찾아야 CFO에게 보고할 수 있습니다."

비용 이상은 **빠른 탐지**가 핵심입니다. 하루 늦으면 하루치 과금이 더 쌓입니다.

### 단독 처리의 한계

- 단일 에이전트: Cost Explorer API를 호출할 수는 있지만, 50개 서비스의 비용 데이터를 분석하는 데 시간이 걸림
- 비용 급증의 원인을 "EC2 비용이 늘었습니다" 수준으로만 답변 — **왜** 늘었는지 drill-down 부족

### Multi-Agent 해법: `#quick` (속도우선)

```
사용자: #quick 이번 달 AWS 비용 급증 원인 분석해줘
```

Gemini(Speed)가 Cost Explorer API를 대량 호출하여 빠르게 이상치를 찾습니다.

### 예제 출력 (Gemini → Master 검증)

```
## 결론
**비용 급증 원인 Top 3 식별** (분석 소요: 28초)

### 비용 증가 분해 (전월 대비 +$13,000)
| 순위 | 서비스 | 전월 | 이번 달 | 증가분 | 기여율 |
|------|--------|------|---------|--------|--------|
| 1 | EC2-Instances | $4,200 | $11,800 | +$7,600 | 58% |
| 2 | RDS | $3,100 | $5,900 | +$2,800 | 22% |
| 3 | NAT Gateway | $800 | $2,300 | +$1,500 | 12% |
| - | 기타 | $6,900 | $8,000 | +$1,100 | 8% |

### Drill-Down: EC2 (+$7,600)
| 원인 | 상세 | 금액 |
|------|------|------|
| GPU 인스턴스 (p3.2xlarge × 4) | ML팀 실험용, 3월 5일부터 상시 가동 | +$5,200 |
| 스팟 → 온디맨드 전환 | 3월 12일 스팟 용량 부족으로 fallback | +$2,400 |

### Drill-Down: RDS (+$2,800)
| 원인 | 상세 | 금액 |
|------|------|------|
| Read Replica 추가 (3개 → 5개) | 성능 이슈 대응으로 3월 8일 추가 | +$1,800 |
| Storage Auto Scaling 발동 | 500GB → 800GB | +$1,000 |

### Drill-Down: NAT Gateway (+$1,500)
| 원인 | 상세 | 금액 |
|------|------|------|
| 데이터 전송량 급증 | Lambda → 외부 API 호출 3배 증가 | +$1,500 |

## 근거
- Cost Explorer GetCostAndUsage API 12회 호출 (서비스별, 일별, 태그별)
- EC2 상세: DescribeInstances로 인스턴스 유형별 분류
- 시계열 분석: 3월 5일, 8일, 12일이 비용 점프 포인트

## 리스크
- GPU 인스턴스가 계속 가동되면 월 $5,200 × 12 = 연 $62,400 추가
- NAT Gateway 비용은 Lambda 호출 패턴과 연동 — 트래픽 증가 시 더 오를 수 있음

## 실행안
### 즉시 절감 가능 ($8,700/월)
1. GPU 인스턴스: 스케줄링 적용 (업무시간만 가동) → -$3,400
2. 스팟 용량 문제: 다중 인스턴스 유형 설정으로 스팟 유지 → -$2,400
3. NAT Gateway: VPC Endpoint 추가로 S3/DynamoDB 트래픽 우회 → -$900
4. Read Replica: 3월 이후 성능 안정화 시 5개 → 4개로 축소 → -$900

### CFO 보고용 요약
"3월 비용 증가 $13,000 중 $8,700(67%)는 즉시 최적화 가능.
GPU 실험 인스턴스 스케줄링, 스팟 인스턴스 복원, VPC Endpoint 추가가 핵심."
```

> ★ **Insight**: `#quick`이 비용 분석에 최적인 이유는 **API 호출 속도**입니다.
> Gemini는 12개 Cost Explorer API를 병렬 호출하여 28초 만에 분석을 완료합니다.
> Codex는 정밀하지만 sandbox 네트워크 제한으로 AWS API 호출이 어려워
> 이 작업에서는 `#cross → #quick` 다운그레이드가 발생합니다.

---

## UC9. 재해복구(DR) 런북 작성

### Pain Point

> "DR 훈련 날짜가 다음 주입니다. 런북이 2년 전에 작성된 것인데,
> 그 사이 아키텍처가 완전히 바뀌었습니다. 누군가 업데이트해야 하는데
> 현재 아키텍처를 완전히 파악하고 있는 사람이 없습니다."

런북은 **설계의 산물**입니다. 현재 아키텍처를 모르면 런북을 쓸 수 없고,
런북이 잘못되면 DR 훈련은 실패합니다.

### 단독 처리의 한계

- 단일 에이전트: 일반적인 DR 런북 템플릿은 생성하지만, **현재 인프라에 맞춤화**되지 않음
- "RDS 리전 전환" 같은 일반 절차만 나열 — 실제 엔드포인트, 파라미터 그룹, 보안 그룹은 빠짐

### Multi-Agent 해법: `#spec` (설계먼저)

```
사용자: #spec 현재 프로덕션 아키텍처 기반으로 DR 런북 작성해줘
```

Kiro(Spec)가 현재 인프라를 분석하고, 아키텍처에 맞춤화된 런북을 설계합니다.

### 예제 출력 (Kiro → Master 검증)

```
## 결론
현재 아키텍처 기반 DR 런북 v2.0을 작성합니다.

### 현재 아키텍처 (자동 탐지)
| 컴포넌트 | Primary (ap-northeast-2) | DR (ap-northeast-1) |
|---------|-------------------------|---------------------|
| ECS Cluster | prod-cluster (Fargate) | dr-cluster (Fargate) |
| RDS | Aurora MySQL (writer + reader×2) | Aurora Global DB (reader) |
| Redis | ElastiCache r6g.large ×3 | ElastiCache r6g.large ×3 |
| S3 | prod-assets (CRR 활성) | dr-assets (복제본) |
| Route53 | api.example.com → ALB | Health Check 기반 failover |

### DR 런북 v2.0

#### Phase 1: 감지 및 선언 (목표: 5분)
| 단계 | 담당 | 명령어 | 확인 |
|------|------|--------|------|
| 1.1 | On-call | PagerDuty에서 리전 장애 확인 | AWS Health Dashboard |
| 1.2 | Incident Commander | DR 선언 | Slack #incident-war-room |
| 1.3 | SRE | 현재 RPO 확인 | Aurora lag: `aws rds describe-global-clusters` |

#### Phase 2: DNS Failover (목표: 10분)
| 단계 | 명령어 | 롤백 |
|------|--------|------|
| 2.1 | Aurora Global DB failover | aws rds failover-global-cluster --global-cluster-identifier prod-global --target-db-cluster-identifier arn:aws:rds:ap-northeast-1:123:cluster:dr-cluster |
| 2.2 | Route53 수동 failover (자동 실패 시) | aws route53 change-resource-record-sets ... (A record → DR ALB) |
| 2.3 | ECS 서비스 스케일업 | aws ecs update-service --cluster dr-cluster --service payment-api --desired-count 6 |

#### Phase 3: 검증 (목표: 15분)
| 체크 | 명령어 | 기대값 |
|------|--------|--------|
| API Health | curl https://api.example.com/health | 200 OK |
| DB 쓰기 | INSERT INTO dr_test VALUES (now()) | Success |
| Redis 연결 | redis-cli -h dr-redis.xxx.cache.amazonaws.com PING | PONG |
| 결제 E2E | /payment/test endpoint 호출 | transaction_id 반환 |

#### Phase 4: 커뮤니케이션 (목표: 즉시)
- 상태 페이지 업데이트: statuspage.io
- 고객 알림: "일시적 지연이 있었으나 현재 정상 운영 중"
- 내부 보고: Incident Commander → CTO

## 근거
- Terraform state / CloudFormation에서 현재 리소스 자동 탐지
- Aurora Global DB의 failover가 핵심 (RTO < 1분, RPO < 1초)
- Route53 Health Check이 자동 failover하지만, 수동 절차도 필요 (자동 실패 대비)

## 리스크
- Aurora failover 시 기존 커넥션 끊김 → 애플리케이션 재연결 로직 필수
- ElastiCache는 Global Datastore 미설정 시 **데이터 유실** → 확인 필요
- DR 리전의 서비스 쿼터가 Primary와 동일한지 사전 확인 필수

## 실행안
1. 이 런북을 `runbooks/dr-failover-v2.md`에 저장
2. DR 훈련 전 Pre-check 실행:
   - [ ] DR 리전 서비스 쿼터 확인
   - [ ] Aurora Global DB replication lag < 100ms 확인
   - [ ] DR ECS Task Definition이 최신 이미지 참조 확인
   - [ ] ElastiCache Global Datastore 상태 확인
3. 훈련 후 RTO/RPO 실측치를 런북에 기록
```

> ★ **Insight**: `#spec` 모드에서 Kiro는 **"무엇을 해야 하는가"를 설계**합니다.
> 일반적 DR 런북이 아니라, **현재 인프라의 실제 엔드포인트와 명령어**가 포함된
> 즉시 실행 가능한 런북입니다. 이것이 설계 에이전트의 가치입니다.

---

## UC10. 보안 감사 대응 자동화

### Pain Point

> "보안팀에서 SOC2 감사 체크리스트를 보내왔습니다. 87개 항목.
> '미사용 IAM 키 비활성화', '로그 보존 기간 확인', 'MFA 적용 현황'...
> 하나하나 수동으로 확인하면 일주일은 걸립니다."

보안 감사는 **범위가 넓고 정확해야** 합니다. 빠르게 현황을 파악하되, 하나라도 틀리면 감사 실패.

### 단독 처리의 한계

- 단일 에이전트: 체크리스트 중 일부만 자동화, 나머지는 "수동으로 확인하세요"
- AWS API 호출과 정책 분석을 동시에 해야 하므로 속도와 정밀 모두 필요

### Multi-Agent 해법: `#cross` → `#critical` (자동 승격)

```
사용자: #cross SOC2 감사 체크리스트 기반으로 보안 현황 점검해줘
```

보안 관련 작업이므로 Master가 `#cross → #critical` 자동 승격을 판단합니다.

### 예제 출력 (자동 승격 → Critical 실행)

```
⚠ 자동 승격: #cross → #critical
보안 감사 대응은 교차검증만으로 불충분. 설계(체크리스트 구조화) → 검증(정밀 점검) → 속도(대량 조회) 풀파이프라인 실행.
```

**Master 최종 판정 (3-Agent 종합):**
```
## 결론
87개 감사 항목 중 **72개 자동 점검 완료**. 15개는 수동 확인 필요.

### 감사 결과 요약
| 카테고리 | 항목 수 | ✅ Pass | ⚠ Warning | 🔴 Fail | 수동 |
|---------|---------|---------|-----------|---------|------|
| IAM | 23 | 18 | 3 | 2 | 0 |
| 로깅 | 15 | 12 | 1 | 0 | 2 |
| 네트워크 | 18 | 15 | 2 | 1 | 0 |
| 암호화 | 12 | 10 | 0 | 0 | 2 |
| 컴플라이언스 | 19 | 8 | 0 | 0 | 11 |

### 🔴 Fail 항목 (즉시 조치 필요)
| # | 항목 | 현황 | 조치 |
|---|------|------|------|
| 1 | 미사용 IAM Access Key (>90일) | 7개 키 발견 | 비활성화 스크립트 준비됨 |
| 2 | Root 계정 MFA | 미설정 | 즉시 설정 필요 |
| 3 | 퍼블릭 서브넷 SG 0.0.0.0/0 인바운드 | 2개 SG | 소스 IP 제한 |

### ⚠ Warning 항목 (권장 조치)
| # | 항목 | 현황 | 조치 |
|---|------|------|------|
| 1 | CloudTrail 로그 보존 | 90일 (권장 365일) | S3 lifecycle 변경 |
| 2 | 비밀번호 정책 최소 길이 | 8자 (권장 14자) | IAM 정책 업데이트 |
| 3 | VPC Flow Logs | 2개 VPC 미설정 | Flow Logs 활성화 |

## 근거
- **Kiro**: 87개 항목을 5개 카테고리로 구조화, 자동화 가능 항목 식별
- **Codex**: IAM, 네트워크, 암호화 항목을 AWS API + 정책 분석으로 정밀 점검
- **Gemini**: 대량 AWS API 호출로 72개 항목 현황 데이터 수집 (38초)
- 3-Agent 결과 간 불일치: 없음 (높은 신뢰도)

## 리스크
- 수동 확인 15개 항목 중 11개가 컴플라이언스 카테고리 (정책/프로세스 문서 확인)
- IAM 키 비활성화 시 사용 중인 서비스 확인 필수 (AccessAdvisor 확인 완료)

## 실행안
### 자동 조치 스크립트
#!/bin/bash
# 1. 미사용 IAM 키 비활성화
aws iam list-access-keys --user-name svc-legacy-1 | \
  jq -r '.AccessKeyMetadata[].AccessKeyId' | \
  xargs -I{} aws iam update-access-key --user-name svc-legacy-1 \
    --access-key-id {} --status Inactive

# 2. CloudTrail 로그 보존 연장
aws s3api put-bucket-lifecycle-configuration \
  --bucket cloudtrail-logs-prod \
  --lifecycle-configuration file://lifecycle-365days.json

# 3. VPC Flow Logs 활성화
aws ec2 create-flow-logs \
  --resource-type VPC \
  --resource-ids vpc-0abc123 vpc-0def456 \
  --traffic-type ALL \
  --log-destination-type cloud-watch-logs \
  --log-group-name /vpc/flow-logs

### 감사팀 제출용 보고서
감사팀에 제출할 JSON 보고서가 `.multi-agent-results/audit-report.json`에 저장되었습니다.
```

> ★ **Insight**: 이 유스케이스는 **자동 승격**의 실제 사례입니다.
> 사용자는 `#cross`를 요청했지만, Master가 보안 감사의 범위와 위험도를 판단하여
> `#critical`로 승격했습니다. 87개 항목을 3-Agent가 분담하여 처리 — 이것이
> "더 신중하게"의 의미입니다.

---

# 개발자편

---

## UC11. 레거시 API → REST 마이그레이션

### Pain Point

> "5년 된 SOAP API가 아직 운영 중입니다. 클라이언트 3개 팀이 사용 중이고,
> 문서는 없고, 테스트는 없고, 원작자는 퇴사했습니다.
> '그냥 REST로 바꿔주세요'라고 하는데, 무엇부터 해야 할지 모르겠습니다."

레거시 마이그레이션은 **스펙 없이 시작하면 실패 확률 90%**입니다.
기존 동작을 완벽히 이해하지 않으면, 새 API가 기존 클라이언트를 깨뜨립니다.

### 단독 처리의 한계

- 단일 에이전트: SOAP → REST 변환 코드는 생성하지만, **기존 클라이언트 호환성** 누락
- 엔드포인트 매핑표 없이 "대충 변환" → 클라이언트팀에서 항의
- 점진적 마이그레이션 전략(Strangler Fig) 없이 빅뱅 전환 시도

### Multi-Agent 해법: `#plan` (스펙→구현)

```
사용자: #plan legacy SOAP API를 REST로 마이그레이션해줘. 3개 클라이언트 팀 호환 필수.
```

### 예제 출력

**Step 1: Kiro (Spec) — 마이그레이션 스펙**
```
## 결론
Strangler Fig 패턴 기반 점진적 마이그레이션 설계.

### Phase 1: 현행 분석 (1주)
기존 SOAP 엔드포인트 매핑:
| SOAP Operation | HTTP Method | REST Endpoint | 파라미터 변환 |
|---------------|-------------|---------------|-------------|
| getUser | GET | /api/v2/users/{id} | XML → JSON |
| createOrder | POST | /api/v2/orders | XML body → JSON body |
| updatePayment | PUT | /api/v2/payments/{id} | XML → JSON + path param |
| searchProducts | GET | /api/v2/products?q={query} | XML → query string |
| deleteCart | DELETE | /api/v2/carts/{id} | XML → path param |

### Phase 2: 프록시 레이어 (2주)
클라이언트 → API Gateway → Lambda(변환) → 기존 SOAP 서비스
- SOAP 요청을 REST로, REST 응답을 SOAP으로 양방향 변환
- 클라이언트 변경 없이 내부적으로 REST 전환 시작

### Phase 3: 클라이언트 마이그레이션 (4주)
| 클라이언트 | 현재 | 전환 방식 | 기한 |
|-----------|------|----------|------|
| 모바일앱팀 | SOAP SDK | REST SDK 제공 + 병렬 운영 | 2주 |
| 웹 프론트 | SOAP 직접 호출 | REST endpoint 전환 | 1주 |
| 파트너 API | SOAP WSDL | 호환 프록시 유지 (6개월) | 별도 |

### Phase 4: SOAP 폐기 (2주)
- 트래픽 모니터링: SOAP 호출 0건 확인
- SOAP 서비스 종료
- 프록시 레이어 제거

## 근거
- Strangler Fig: 점진적 전환으로 빅뱅 리스크 제거
- 파트너 API는 외부이므로 호환 프록시 장기 유지 필요
- 각 Phase 완료 후 롤백 가능한 구조

## 리스크
- SOAP과 REST의 에러 코드 매핑이 1:1이 아님 (SOAP Fault → HTTP Status)
- 인증 방식 차이: WS-Security → OAuth2 / API Key
- XML 네임스페이스 처리 시 데이터 유실 가능
```

**Step 2: Codex (Precision) — 핵심 구현**
```
## 결론
Kiro 스펙 기반 프록시 레이어 및 REST API 코드 생성.

### SOAP → REST 변환 프록시 (Lambda)
import xmltodict
import json

def handler(event, context):
    """SOAP 요청을 REST로 변환하는 API Gateway Lambda"""
    soap_body = event.get('body', '')

    # SOAP envelope 파싱
    parsed = xmltodict.parse(soap_body)
    soap_action = event['headers'].get('SOAPAction', '').strip('"')

    # 매핑 테이블
    OPERATION_MAP = {
        'getUser': {
            'method': 'GET',
            'path': '/api/v2/users/{id}',
            'extract': lambda d: {'id': d['Body']['getUser']['userId']}
        },
        'createOrder': {
            'method': 'POST',
            'path': '/api/v2/orders',
            'extract': lambda d: d['Body']['createOrder']
        },
        'updatePayment': {
            'method': 'PUT',
            'path': '/api/v2/payments/{id}',
            'extract': lambda d: {
                'id': d['Body']['updatePayment']['paymentId'],
                'body': d['Body']['updatePayment']
            }
        },
    }

    operation = OPERATION_MAP.get(soap_action)
    if not operation:
        return soap_fault('Client', f'Unknown operation: {soap_action}')

    # REST 호출
    rest_params = operation['extract'](parsed['Envelope'])
    rest_response = call_rest_api(
        method=operation['method'],
        path=operation['path'].format(**rest_params),
        body=rest_params.get('body')
    )

    # REST JSON → SOAP XML 변환
    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'text/xml'},
        'body': json_to_soap_response(soap_action, rest_response)
    }

### REST API (FastAPI)
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI(title="API v2", version="2.0.0")

class OrderCreate(BaseModel):
    user_id: str
    product_id: str
    quantity: int

@app.get("/api/v2/users/{user_id}")
async def get_user(user_id: str):
    user = await user_service.get(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@app.post("/api/v2/orders", status_code=201)
async def create_order(order: OrderCreate):
    return await order_service.create(order)

### 에러 코드 매핑
SOAP_TO_HTTP = {
    'Client': 400,
    'Server': 500,
    'MustUnderstand': 400,
    'VersionMismatch': 400,
}

## 리스크
- xmltodict는 대용량 XML에서 메모리 이슈 → lxml SAX 파서 고려
- Lambda cold start로 첫 요청 지연 → Provisioned Concurrency 설정
```

**Master 최종 판정:**
```
## 결론
스펙 충족률 **90%**. 2건 보완 필요.

| 스펙 항목 | Codex 구현 | 판정 |
|----------|-----------|------|
| Strangler Fig 프록시 | ✅ Lambda 구현 | Pass |
| 5개 Operation 매핑 | ⚠ 3개만 구현 | 보완 필요 |
| REST API (FastAPI) | ✅ 2개 엔드포인트 | Pass (나머지 패턴 동일) |
| 에러 코드 매핑 | ✅ | Pass |
| 인증 전환 (WS-Security→OAuth2) | ❌ 미구현 | 보완 필요 |

## 실행안
1. searchProducts, deleteCart Operation 매핑 추가
2. 인증 전환 레이어 설계 필요 → 후속 `#spec` 태스크 생성
3. 통합 테스트: SOAP 클라이언트 → 프록시 → REST → 프록시 → SOAP 응답 E2E
```

> ★ **Insight**: `#plan` 모드에서 Master의 핵심 역할은 **갭 분석**입니다.
> Kiro가 5개 Operation을 설계했는데 Codex가 3개만 구현 — 이 차이를 Master가 잡아냅니다.
> 단독 에이전트에서는 "설계한 것과 구현한 것이 일치하는가?"를 자체 검증하기 어렵습니다.

---

## UC12. 유닛 테스트 일괄 생성

### Pain Point

> "코드 커버리지가 23%입니다. PM이 '80% 달성해주세요'라고 합니다.
> 서비스 레이어 함수 47개에 테스트가 없습니다. 하나하나 작성하면 2주."

테스트 생성은 **정확도가 생명**입니다. 테스트가 잘못되면 False Green(통과하지만 실제로는 버그)이 됩니다.

### 단독 처리의 한계

- 단일 에이전트: 기계적으로 테스트를 생성하지만, **엣지케이스와 비즈니스 로직** 이해 부족
- `assert result is not None` 같은 무의미한 assertion으로 커버리지만 올림

### Multi-Agent 해법: `#precise` (정밀분석)

```
사용자: #precise services/ 디렉토리의 테스트 없는 함수들에 유닛 테스트 생성해줘
```

Codex(Precision)가 코드를 정밀 분석하여 의미 있는 테스트를 생성합니다.

### 예제 출력 (Codex → Master 검증)

```
## 결론
47개 함수 중 **42개에 대해 156개 테스트 케이스** 생성. 5개는 통합 테스트 필요.

### 생성된 테스트 요약
| 서비스 | 함수 수 | 테스트 수 | 커버리지 변화 |
|--------|---------|----------|-------------|
| user_service.py | 12 | 38 | 18% → 82% |
| order_service.py | 15 | 52 | 12% → 85% |
| payment_service.py | 8 | 31 | 30% → 78% |
| notification_service.py | 7 | 22 | 0% → 88% |
| product_service.py | 5 | 13 | 45% → 91% |
| **합계** | **47** | **156** | **23% → 84%** |

### 테스트 예시: order_service.py
import pytest
from unittest.mock import AsyncMock, patch
from services.order_service import OrderService
from models.order import Order, OrderStatus

class TestOrderService:
    @pytest.fixture
    def service(self):
        return OrderService(
            db=AsyncMock(),
            payment_client=AsyncMock(),
            inventory_client=AsyncMock()
        )

    # --- create_order ---
    async def test_create_order_success(self, service):
        """정상 주문 생성"""
        service.inventory_client.check_stock.return_value = True
        service.payment_client.charge.return_value = {"tx_id": "tx-123"}
        service.db.save.return_value = Order(id="ord-1", status=OrderStatus.CONFIRMED)

        result = await service.create_order(user_id="u-1", product_id="p-1", qty=2)

        assert result.status == OrderStatus.CONFIRMED
        service.inventory_client.check_stock.assert_called_once_with("p-1", 2)
        service.payment_client.charge.assert_called_once()

    async def test_create_order_out_of_stock(self, service):
        """재고 부족 시 OrderError 발생"""
        service.inventory_client.check_stock.return_value = False

        with pytest.raises(OrderError, match="Out of stock"):
            await service.create_order(user_id="u-1", product_id="p-1", qty=100)

        service.payment_client.charge.assert_not_called()  # 결제 시도하면 안 됨

    async def test_create_order_payment_failure_rollback(self, service):
        """결제 실패 시 재고 복원 (보상 트랜잭션)"""
        service.inventory_client.check_stock.return_value = True
        service.payment_client.charge.side_effect = PaymentError("Declined")

        with pytest.raises(PaymentError):
            await service.create_order(user_id="u-1", product_id="p-1", qty=2)

        service.inventory_client.restore_stock.assert_called_once_with("p-1", 2)

    async def test_create_order_zero_quantity(self, service):
        """수량 0 주문 시 ValidationError"""
        with pytest.raises(ValidationError, match="Quantity must be > 0"):
            await service.create_order(user_id="u-1", product_id="p-1", qty=0)

    async def test_create_order_negative_quantity(self, service):
        """음수 수량 주문 시 ValidationError"""
        with pytest.raises(ValidationError):
            await service.create_order(user_id="u-1", product_id="p-1", qty=-1)

### 통합 테스트 필요 항목 (5개)
| 함수 | 이유 |
|------|------|
| payment_service.process_webhook | 외부 PG사 웹훅 시뮬레이션 필요 |
| order_service.batch_process | DB 트랜잭션 검증 필요 |
| notification_service.send_sms | 외부 API 호출 (mock 불충분) |
| user_service.oauth_callback | OAuth 플로우 E2E 필요 |
| product_service.sync_inventory | 외부 ERP 연동 |

## 근거
- 각 함수의 시그니처, 분기문, 예외 처리를 분석하여 테스트 케이스 도출
- Happy path + 엣지케이스 + 에러 케이스 3종 세트로 구성
- Mock 전략: 외부 의존성만 mock, 내부 로직은 실제 실행

## 리스크
- Mock이 실제 동작과 다를 수 있음 → 통합 테스트로 보완
- async 테스트는 이벤트 루프 설정 필요 (pytest-asyncio)
- 기존 코드에 타입 힌트가 없으면 assertion이 부정확할 수 있음

## 실행안
1. `pip install pytest-asyncio pytest-cov` 확인
2. `pytest tests/ -v --cov=services --cov-report=html` 실행
3. 커버리지 리포트 확인 후 미달 함수 추가 작성
4. CI에 `--cov-fail-under=80` 게이트 추가
```

> ★ **Insight**: `#precise` 모드가 테스트 생성에 최적인 이유는 **코드를 깊이 이해**하기 때문입니다.
> "결제 실패 시 재고가 복원되는가?" 같은 비즈니스 로직 테스트는
> 코드의 분기문과 예외 처리를 정밀 분석해야만 작성 가능합니다.
> `#quick`으로는 `assert result is not None` 수준에 머뭅니다.

---

## UC13. PR 코드 리뷰 자동화

### Pain Point

> "주니어 개발자가 올린 PR에 SQL injection 취약점이 있었는데,
> 바쁜 시니어가 'LGTM' 찍고 머지했습니다. 1주일 뒤 보안 스캔에서 발견.
> 사람 리뷰어를 100% 신뢰할 수 없습니다."

코드 리뷰는 **보안과 품질 두 축**이 필요합니다. 하나의 시각으로는 한쪽을 놓칩니다.

### 단독 처리의 한계

- 단일 에이전트: 문법과 패턴은 잡지만, **비즈니스 로직의 보안 함의**를 놓침
- "f-string SQL" 같은 명확한 패턴은 감지하지만, ORM misuse나 인증 우회는 놓침

### Multi-Agent 해법: `#cross` (교차검증)

```
사용자: #cross PR #142 코드 리뷰해줘
```

Gemini(빠른 패턴 매칭) + Codex(심층 로직 분석) → Master가 최종 리뷰 판정.

### 예제 출력 (Master 최종 판정)

```
## 결론
PR #142에서 **1건 Critical, 2건 Major, 3건 Minor** 이슈 발견.

### Gemini vs Codex 발견 비교
| # | 이슈 | Gemini | Codex | 심각도 | 채택 |
|---|------|--------|-------|--------|------|
| 1 | SQL injection (raw query) | ✅ 감지 | ✅ 상세 PoC 제공 | Critical | 병합 |
| 2 | 인증 체크 누락 (admin endpoint) | ❌ 누락 | ✅ 감지 | Major | Codex |
| 3 | N+1 쿼리 (loop 내 DB 호출) | ✅ 감지 | ✅ 감지 + 수정안 | Major | Codex |
| 4 | 미사용 import | ✅ 감지 | ✅ 감지 | Minor | 합의 |
| 5 | 변수명 컨벤션 위반 | ✅ 감지 | ❌ 누락 | Minor | Gemini |
| 6 | docstring 누락 | ✅ 감지 | ❌ (설계 외) | Minor | Gemini |

### Critical: SQL Injection
```python
# PR #142, file: api/routes/search.py, line 45
# 변경 전 (안전):
results = db.query(Product).filter(Product.name.ilike(f"%{query}%")).all()

# 변경 후 (위험!):
results = db.execute(f"SELECT * FROM products WHERE name LIKE '%{query}%'").fetchall()
```

**Codex PoC**:
```
GET /api/search?q='; DROP TABLE products; --
→ SQL: SELECT * FROM products WHERE name LIKE '%'; DROP TABLE products; --%'
```

**수정안**:
```python
results = db.execute(
    text("SELECT * FROM products WHERE name LIKE :query"),
    {"query": f"%{query}%"}
).fetchall()
```

### Major: 인증 체크 누락
```python
# api/routes/admin.py, line 78
@app.delete("/api/admin/users/{user_id}")
async def delete_user(user_id: str):  # ← @require_admin 데코레이터 누락!
    await user_service.delete(user_id)
```

## 근거
- Gemini: 3초 만에 6개 패턴 매칭 기반 이슈 감지 (속도)
- Codex: SQL injection의 실제 exploit PoC까지 제공 + 인증 누락 감지 (깊이)
- Master 판정: Gemini가 놓친 인증 이슈는 **Codex만이 함수 호출 체인을 추적하여 발견**
- Codex가 놓친 컨벤션/docstring은 **Gemini의 패턴 매칭이 더 효율적**

## 리스크
- SQL injection이 머지되면 데이터 유출/삭제 위험
- 인증 누락이 머지되면 일반 사용자가 admin 기능 사용 가능

## 실행안
1. PR #142에 **Changes Requested** 설정
2. Critical/Major 3건 수정 후 재리뷰 (`#cross` 재실행)
3. CI에 `bandit` (Python 보안 린터) 추가 → SQL injection 자동 감지
4. `@require_admin` 데코레이터 미적용 감지 커스텀 룰 추가
```

> ★ **Insight**: 코드 리뷰에서 `#cross`의 가치는 **상호 보완**입니다.
> Gemini는 넓게(6개 이슈), Codex는 깊게(PoC + 수정안). 둘 중 하나만으로는
> 인증 누락(Codex만 감지)이나 컨벤션 위반(Gemini만 감지)을 놓칩니다.
> **"두 눈보다 네 눈"** — 이것이 교차검증의 본질입니다.

---

## UC14. 신규 마이크로서비스 설계

### Pain Point

> "'알림 서비스를 별도 마이크로서비스로 분리해주세요.'
> 모놀리스에서 꺼내야 하는데, 어디를 자르고, 데이터는 어떻게 분리하고,
> API 계약은 어떻게 맺어야 하는지... 설계 없이 시작하면 분산 모놀리스가 됩니다."

마이크로서비스 분리는 **설계가 80%, 코딩이 20%**인 작업입니다.

### 단독 처리의 한계

- 단일 에이전트: 일반적 마이크로서비스 패턴은 제시하지만, **현재 모놀리스의 의존성 그래프** 분석 부족
- "이벤트 드리븐으로 하세요" 같은 교과서적 답변 — 실제로 어떤 이벤트를, 어떤 순서로, 어떤 보장 수준으로?

### Multi-Agent 해법: `#spec` (설계먼저)

```
사용자: #spec 모놀리스에서 알림 서비스를 마이크로서비스로 분리 설계해줘
```

Kiro(Spec)가 현재 코드를 분석하고, 분리 설계를 체계적으로 작성합니다.

### 예제 출력 (Kiro → Master 검증)

```
## 결론
알림 서비스 분리 설계 문서. 3단계 점진적 분리 전략.

### 현재 의존성 분석

모놀리스 내 알림 관련 코드:
| 모듈 | 파일 수 | 의존성 방향 |
|------|---------|-----------|
| notification/ | 8 | ← order, payment, user, auth |
| templates/ | 12 | ← notification |
| channels/ (email, sms, push) | 6 | ← notification |

의존성 그래프:
order ──→ notification.send_order_confirmation()
payment ──→ notification.send_payment_receipt()
user ──→ notification.send_welcome_email()
auth ──→ notification.send_2fa_code()

### 분리 설계

#### 1. API 계약
새 알림 서비스의 인터페이스:

POST /api/v1/notifications
{
  "type": "order_confirmation | payment_receipt | welcome | 2fa_code",
  "recipient": { "user_id": "u-1", "channels": ["email", "push"] },
  "payload": { ... },
  "priority": "high | normal | low",
  "idempotency_key": "uuid-v4"
}

Response: 202 Accepted
{
  "notification_id": "notif-123",
  "status": "queued"
}

#### 2. 데이터 분리
| 테이블 | 현재 위치 | 분리 방법 |
|--------|---------|----------|
| notifications | 모놀리스 DB | → 알림 서비스 전용 DB |
| notification_templates | 모놀리스 DB | → 알림 서비스 전용 DB |
| notification_logs | 모놀리스 DB | → 알림 서비스 전용 DB |
| user_preferences | 모놀리스 DB | 공유 (읽기 전용 API) |

#### 3. 이벤트 드리븐 전환
| 현재 (동기 호출) | 변경 (비동기 이벤트) |
|----------------|-------------------|
| order_service.create() → notification.send() | order_service.create() → EventBridge: "order.created" |
| payment_service.charge() → notification.send() | payment_service.charge() → EventBridge: "payment.completed" |

EventBridge 이벤트 스키마:
{
  "source": "order-service",
  "detail-type": "order.created",
  "detail": {
    "order_id": "ord-123",
    "user_id": "u-1",
    "items": [...],
    "total": 45000
  }
}

#### 4. 점진적 분리 로드맵
| Phase | 기간 | 작업 | 롤백 가능 |
|-------|------|------|----------|
| 1 | 1주 | 이벤트 발행 추가 (기존 동기 호출 유지) | ✅ |
| 2 | 2주 | 알림 서비스 배포 + 이벤트 수신 시작 | ✅ |
| 3 | 1주 | 동기 호출 제거, 이벤트만 사용 | ✅ (Phase 1로) |
| 4 | 1주 | 데이터 마이그레이션 + 모놀리스 코드 삭제 | ⚠ 주의 |

## 근거
- 동기 → 비동기 전환: 알림은 eventual consistency 허용 (즉시 전달 불필요)
- EventBridge 선택 이유: SQS보다 라우팅 유연, SNS보다 스키마 검증 강점
- 4단계 분리: 각 단계 롤백 가능하여 리스크 최소화

## 리스크
- 2FA 코드는 **실시간 전달 필수** → EventBridge가 아닌 직접 API 호출 유지
- 이벤트 유실 시 알림 미전달 → DLQ(Dead Letter Queue) + 재처리 로직 필수
- 알림 서비스 장애 시 모놀리스 영향 없어야 함 → Circuit Breaker 패턴

## 실행안
1. 이 설계를 기반으로 `#plan` 모드 실행 → Codex가 구현
2. Phase 1부터 시작: 모놀리스에 이벤트 발행 코드 추가
3. 알림 서비스 인프라: ECS Fargate + SQS + Aurora Serverless
4. 모니터링: 이벤트 처리 지연, DLQ 메시지 수 알림 설정
```

> ★ **Insight**: `#spec` 모드의 진가는 **"무엇을 해야 하는가"를 구조화**하는 것입니다.
> 마이크로서비스 분리에서 가장 어려운 건 코딩이 아니라 **경계 결정**입니다.
> "알림은 비동기 OK, 2FA는 동기 필수" — 이런 판단은 설계 단계에서만 가능합니다.
> 이후 `#plan`으로 이어가면 Kiro의 설계를 Codex가 구현합니다.

---

## UC15. 프로덕션 DB 마이그레이션

### Pain Point

> "users 테이블에 `phone_number` 컬럼을 추가해야 합니다.
> 레코드 5천만 건. ALTER TABLE이 10분 이상 걸릴 수 있고,
> 그 동안 테이블 락이 걸리면 서비스 전체가 멈춥니다.
> '그냥 ALTER TABLE 하면 되잖아요' — 아뇨, 데이터는 되돌릴 수 없습니다."

프로덕션 DB 마이그레이션은 **가장 위험한 개발자 작업** 중 하나입니다.
롤백이 어렵고, 실수 시 서비스 다운타임과 데이터 유실이 동시에 발생합니다.

### 단독 처리의 한계

- 단일 에이전트: `ALTER TABLE ADD COLUMN` 한 줄 제시 — 무중단 전략 없음
- 5천만 건 테이블의 온라인 DDL 특성(InnoDB, Aurora 차이)을 모름
- 롤백 계획 없음

### Multi-Agent 해법: `#critical` (풀파이프라인)

```
사용자: #critical users 테이블에 phone_number 컬럼 추가. 5천만 건, 무중단 필수.
```

데이터 변경이므로 `solo → critical` 자동 승격 대상입니다.

### 예제 출력

**Step 1: Kiro (Spec) — 마이그레이션 전략 설계**
```
## 결론
3가지 전략을 비교 분석. Aurora MySQL 환경에서 **Online DDL**이 최적.

### 전략 비교
| 전략 | 다운타임 | 소요 시간 | 복잡도 | 리스크 |
|------|---------|----------|--------|--------|
| A. 직접 ALTER TABLE | 🔴 10-30분 | 10분 | 낮음 | 서비스 중단 |
| B. pt-online-schema-change | 🟢 0 | 2-4시간 | 높음 | 트리거 기반, 복제 지연 |
| C. Aurora Online DDL | 🟢 0 | 10-30초 | 낮음 | Aurora 전용 |

**권장: 전략 C (Aurora Online DDL)**

Aurora MySQL은 `ADD COLUMN`을 **instant DDL**로 처리합니다.
메타데이터만 변경하므로 테이블 크기와 무관하게 즉시 완료.

### 실행 절차 (7단계)
1. Pre-check: Aurora 버전 확인 (5.7.mysql_aurora.2.10+ 또는 8.0+)
2. Backup: 스냅샷 생성
3. 리허설: staging에서 동일 스키마 테스트
4. 실행: `ALTER TABLE users ADD COLUMN phone_number VARCHAR(20) DEFAULT NULL, ALGORITHM=INSTANT`
5. 검증: 컬럼 존재 + 기존 데이터 무결성 확인
6. 애플리케이션 배포: phone_number 사용 코드
7. 모니터링: 1시간 관찰

## 리스크
- ALGORITHM=INSTANT 미지원 시 INPLACE로 fallback (수 분 소요, 락 가능)
- DEFAULT NULL이 아닌 DEFAULT 'value' 사용 시 instant 불가 (전체 행 재작성)
- Aurora Serverless v1은 instant DDL 미지원
```

**Step 2: Codex (Precision) — 실행 스크립트 검증**
```
## 결론
Kiro 전략 C 기반 실행 스크립트 및 롤백 계획 작성.

### Pre-check 스크립트
#!/bin/bash
set -euo pipefail

echo "=== DB Migration Pre-check ==="

# 1. Aurora 버전 확인
VERSION=$(mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -e \
  "SELECT aurora_version();" -N -B)
echo "Aurora Version: $VERSION"

# 2. 테이블 현재 상태
ROW_COUNT=$(mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -e \
  "SELECT TABLE_ROWS FROM information_schema.TABLES \
   WHERE TABLE_NAME='users';" -N -B)
echo "Row Count: $ROW_COUNT"

# 3. 컬럼 존재 여부 (멱등성)
EXISTS=$(mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -e \
  "SELECT COUNT(*) FROM information_schema.COLUMNS \
   WHERE TABLE_NAME='users' AND COLUMN_NAME='phone_number';" -N -B)
if [ "$EXISTS" -gt 0 ]; then
  echo "⚠ phone_number 컬럼이 이미 존재합니다. 스킵."
  exit 0
fi

# 4. 진행 중인 장시간 트랜잭션 확인
LONG_TX=$(mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -e \
  "SELECT COUNT(*) FROM information_schema.INNODB_TRX \
   WHERE TIME_TO_SEC(TIMEDIFF(NOW(), trx_started)) > 60;" -N -B)
if [ "$LONG_TX" -gt 0 ]; then
  echo "🔴 장시간 트랜잭션 $LONG_TX건 발견. 마이그레이션 대기."
  exit 1
fi

echo "✅ Pre-check 통과. 마이그레이션 진행 가능."

### 마이그레이션 실행
ALTER TABLE users
  ADD COLUMN phone_number VARCHAR(20) DEFAULT NULL
  COMMENT '사용자 전화번호 (E.164 형식)',
  ALGORITHM=INSTANT;

### 롤백 (필요 시)
ALTER TABLE users
  DROP COLUMN phone_number,
  ALGORITHM=INSTANT;

### 검증 쿼리
-- 1. 컬럼 존재 확인
DESCRIBE users phone_number;

-- 2. 기존 데이터 무결성 (샘플)
SELECT id, email, phone_number FROM users LIMIT 10;
-- phone_number이 모두 NULL이면 정상

-- 3. 인덱스 영향 확인
SHOW INDEX FROM users;

## 리스크
- ALGORITHM=INSTANT 실패 시: `You cannot specify 'INSTANT' for this operation` 에러
  → ALGORITHM=INPLACE로 재시도 (이 경우 Master 승인 필요)
- VARCHAR(20)이 E.164 형식에 충분한지 확인 (+82-10-1234-5678 = 16자)
```

**Step 3: Gemini (Speed) — 영향도 분석**
```
## 결론
users 테이블 변경의 전체 영향 범위를 분석합니다.

### 영향 분석
| 영역 | 영향 | 상세 |
|------|------|------|
| ORM 모델 | ⚠ 업데이트 필요 | User 모델에 phone_number 필드 추가 |
| API | ⚠ 업데이트 필요 | GET /users/{id} 응답에 필드 추가 |
| 캐시 | ⚠ 무효화 필요 | Redis user:* 키 만료 처리 |
| 백업 | ✅ 자동 | Aurora 자동 백업에 포함 |
| 복제 | ✅ 자동 | Aurora Read Replica에 즉시 반영 |
| 배치잡 | ✅ 영향 없음 | users 테이블 직접 조회하지 않음 |

### 배포 순서
1. DB 마이그레이션 (스키마 변경)
2. 백엔드 배포 (ORM + API)
3. 프론트엔드 배포 (UI)
4. 캐시 무효화

순서가 중요: DB 먼저, 코드 나중. 역순은 에러 발생.
```

**Master 최종 판정:**
```
## 결론
**Go — Aurora Instant DDL 실행 승인.**

3-Agent 결과 종합:
- Kiro: 3가지 전략 중 Aurora Online DDL(전략 C) 선택 — 적절
- Codex: Pre-check + 실행 + 롤백 + 검증 스크립트 완비
- Gemini: ORM/API/캐시 영향 식별 + 배포 순서 명확화
- 3-Agent 모순 없음. 일관된 "Instant DDL + 순차 배포" 전략.

## 근거
- Aurora Instant DDL은 5천만 건이든 5억 건이든 동일 속도 (메타데이터만 변경)
- Codex의 Pre-check 스크립트가 장시간 트랜잭션 확인 — 안전장치
- Gemini의 배포 순서가 핵심: DB → 백엔드 → 프론트 → 캐시

## 리스크
- Instant DDL 실패 가능성 (극히 낮지만 존재) → INPLACE fallback 준비됨
- 캐시 무효화를 빠뜨리면 이전 스키마의 캐시된 데이터 반환 가능

## 실행안
### 실행 체크리스트
- [ ] Aurora 스냅샷 생성 완료
- [ ] staging 리허설 완료
- [ ] Pre-check 스크립트 실행 — 모두 Pass
- [ ] Instant DDL 실행 (예상 소요: <1초)
- [ ] 검증 쿼리 실행 — 컬럼 존재 + NULL 확인
- [ ] 백엔드 PR 머지 + 배포
- [ ] Redis 캐시 무효화: `redis-cli KEYS "user:*" | xargs redis-cli DEL`
- [ ] 프론트엔드 배포
- [ ] 1시간 모니터링: 에러율, 레이턴시, DB 커넥션
```

> ★ **Insight**: DB 마이그레이션에서 `#critical`이 필수인 이유는 **되돌릴 수 없기 때문**입니다.
> 코드는 git revert로 1초 만에 되돌리지만, 데이터는 그렇지 않습니다.
> Kiro가 전략을 설계하고, Codex가 안전장치(Pre-check, 롤백)를 만들고,
> Gemini가 파급 효과를 분석합니다. Master는 **Go/No-Go를 최종 판정**합니다.

---

# 부록

---

## A. 모드 선택 가이드 (빠른 참조)

```
"빨리 파악해야 해"          → #quick (속도우선)
"정확해야 해"              → #precise (정밀분석)
"설계부터 해야 해"          → #spec (설계먼저)
"두 번 확인해야 해"         → #cross (교차검증)
"절대 실패하면 안 돼"       → #critical (풀파이프라인)
"설계하고 바로 구현까지"     → #plan (스펙→구현)
"간단한 거"               → #solo (단독처리)
```

## B. 자동 승격 시각화

```
                    ┌─── 보안 변경 ───→ #cross
                    │
    #solo ──────────┼─── 프로덕션 배포 ──→ #critical
                    │
                    └─── 신규 설계 ───→ #spec

    #quick ─── 보안 리스크 감지 ──→ #cross

    #cross ─── 감사/규정 준수 ──→ #critical
```

## C. 유스케이스별 에이전트 활용 요약

| UC | 모드 | Kiro | Codex | Gemini | Master |
|----|------|------|-------|--------|--------|
| 1 | cross | - | 정밀 검증 | 패턴 매칭 | 병합 판정 |
| 2 | quick | - | - | 대량 분석 | 검증 |
| 3 | plan | 모듈 설계 | 코드 구현 | - | 갭 분석 |
| 4 | critical | 트리아지 | 근본 원인 | 영향도 | Go/No-Go |
| 5 | precise | - | 메트릭 분석 | - | 검증 |
| 6 | critical | 트리아지 | 코드 추적 | 영향도 | Go/No-Go |
| 7 | cross | - | 수학 검증 | 프레임워크 | 병합 |
| 8 | quick | - | - | API 대량 호출 | 검증 |
| 9 | spec | 런북 설계 | - | - | 검증 |
| 10 | critical | 구조화 | 정밀 점검 | 대량 조회 | 종합 판정 |
| 11 | plan | 마이그레이션 설계 | 프록시 구현 | - | 갭 분석 |
| 12 | precise | - | 테스트 생성 | - | 검증 |
| 13 | cross | - | 로직 분석 | 패턴 매칭 | 병합 판정 |
| 14 | spec | 서비스 설계 | - | - | 검증 |
| 15 | critical | 전략 설계 | 스크립트 검증 | 영향 분석 | Go/No-Go |

---

> **"혼자 해도 되지만, 함께하면 놓치지 않는다."**
> 단독 에이전트는 80%의 답을 줍니다. Multi-Agent는 나머지 20% — 바로 그 20%가
> 프로덕션 장애, 보안 사고, 데이터 유실의 차이를 만듭니다.
