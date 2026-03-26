#!/usr/bin/env bash
# simulate.sh — Multi-Agent CLI 시뮬레이션
# 실제 CLI 없이 4-Agent 오케스트레이션 흐름을 재현합니다.

set -euo pipefail

# --- 색상 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
DIM='\033[2m'
NC='\033[0m'
BOLD='\033[1m'

# --- 유틸 ---
slow_print() {
    local text="$1"
    local delay="${2:-0.01}"
    while IFS= read -r -n1 char; do
        printf '%s' "$char"
        sleep "$delay"
    done <<< "$text"
    echo
}

type_effect() {
    local text="$1"
    printf "${DIM}"
    for ((i=0; i<${#text}; i++)); do
        printf '%s' "${text:$i:1}"
        sleep 0.02
    done
    printf "${NC}\n"
}

separator() {
    echo -e "${DIM}$(printf '─%.0s' {1..70})${NC}"
}

agent_header() {
    local agent="$1"
    local color="$2"
    local role="$3"
    local time="$4"
    echo ""
    echo -e "${color}┌──────────────────────────────────────────────────────┐${NC}"
    echo -e "${color}│  ${BOLD}${agent}${NC}${color} — ${role} (${time})${NC}"
    echo -e "${color}└──────────────────────────────────────────────────────┘${NC}"
}

master_judge() {
    echo ""
    echo -e "${RED}┌──────────────────────────────────────────────────────┐${NC}"
    echo -e "${RED}│  ${BOLD}Claude (Master) — 최종 판정${NC}"
    echo -e "${RED}└──────────────────────────────────────────────────────┘${NC}"
}

wait_spinner() {
    local duration="$1"
    local label="$2"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    local end=$((SECONDS + duration))
    while [ $SECONDS -lt $end ]; do
        printf "\r  ${DIM}${spin:i++%${#spin}:1} ${label}${NC}"
        sleep 0.1
    done
    printf "\r  ${GREEN}✓${NC} ${label}\n"
}

prompt_input() {
    echo ""
    echo -e "${WHITE}${BOLD}Claude Code CLI${NC}"
    echo -ne "${GREEN}❯${NC} "
    type_effect "$1"
    echo ""
}

# ============================================================
# 시나리오 1: @scan — Security Group 전수 검사
# ============================================================
scenario_scan() {
    echo ""
    echo -e "${BOLD}${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  시나리오 1: @scan — Security Group 전수 검사${NC}"
    echo -e "${BOLD}${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    prompt_input "@scan sso-prod 프로파일로 모든 SG에서 0.0.0.0/0 인바운드가 열린 항목 찾고 리소스 매핑해줘"

    echo -e "${BLUE}[Master]${NC} 모드 감지: ${GREEN}@scan${NC} → Gemini 단독 위임"
    echo -e "${BLUE}[Master]${NC} ai-delegate.sh scan 호출..."
    sleep 1

    agent_header "Gemini CLI" "$CYAN" "Speed Slave" "45s timeout"
    echo -e "  ${DIM}gemini --approval-mode yolo --prompt \"...\"${NC}"
    wait_spinner 2 "AWS CLI: describe-security-groups 실행 중..."
    wait_spinner 1 "38개 SG 스캔, 인바운드 규칙 분석..."
    wait_spinner 1 "연결 리소스 매핑..."
    echo -e "  ${GREEN}✓${NC} ${BOLD}12초${NC} 만에 완료"

    echo ""
    separator
    cat << 'EOF'

## 결론
12개 SG에서 0.0.0.0/0 인바운드 발견. 즉시 조치 필요 3건.

## 근거
| SG ID | 포트 | 연결 리소스 | 판정 |
|-------|------|-----------|------|
| sg-0a1b2c3d | 80/443 | ALB (imweb-prod-web) | ✅ 정상 |
| sg-1a2b3c4d | 80/443 | ALB (imweb-prod-api) | ✅ 정상 |
| ... (6개 추가 ALB) | | | ✅ 정상 |
| sg-9x8y7z6w | 22 | bastion-legacy | ⚠️ 위험 |
| sg-8w7v6u5t | 3306 | rds-legacy-replica | 🔴 위험 |
| sg-7v6u5t4s | 5432 | - (미사용) | 🟡 삭제 권장 |

## 리스크
- sg-9x8y7z6w: SSH 22번 포트 전체 오픈. bastion이지만 SSM 전환 권장
- sg-8w7v6u5t: MySQL 3306 전체 오픈. 즉시 VPC CIDR로 제한 필요
- sg-7v6u5t4s: 연결 리소스 없음. 삭제 시 영향 없음

## 실행안
1. [긴급] sg-8w7v6u5t MySQL 포트 → VPC CIDR(10.0.0.0/8)로 즉시 제한
2. [금주] sg-9x8y7z6w SSH → SSM 전환 후 인바운드 제거
3. [금주] sg-7v6u5t4s 미사용 SG 삭제

EOF

    echo -e "${BLUE}[Master]${NC} Gemini 결과 확인 완료. 추가 검증 불필요 (읽기 전용 조회)"
    echo -e "${BLUE}[Master]${NC} ${GREEN}MySQL 포트 오픈은 보안 사고 위험 → 즉시 조치를 권고합니다.${NC}"
}

# ============================================================
# 시나리오 2: @verify — IAM 정책 교차 검증
# ============================================================
scenario_verify() {
    echo ""
    echo -e "${BOLD}${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  시나리오 2: @verify — IAM 정책 교차 검증${NC}"
    echo -e "${BOLD}${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    prompt_input "@verify payment-processor Lambda에 S3 devops-receipts 읽기 + DynamoDB payment-log 읽기/쓰기 최소 권한 정책 작성해줘"

    echo -e "${BLUE}[Master]${NC} 모드 감지: ${YELLOW}@verify${NC} → Gemini + Codex 병렬 실행"
    echo -e "${BLUE}[Master]${NC} ai-delegate.sh verify 호출..."
    sleep 1

    # 병렬 표시
    echo ""
    echo -e "  ${CYAN}Gemini${NC} ━━━▶ ${DIM}병렬 실행 중...${NC}"
    echo -e "  ${PURPLE}Codex${NC}  ━━━▶ ${DIM}병렬 실행 중...${NC}"
    echo ""

    wait_spinner 2 "Gemini: IAM 정책 생성 중..."
    echo -e "  ${CYAN}✓ Gemini 완료 (22초)${NC}"
    echo ""
    wait_spinner 2 "Codex: IAM 정책 생성 + 보안 검증 중..."
    echo -e "  ${PURPLE}✓ Codex 완료 (51초)${NC}"

    separator
    agent_header "Gemini" "$CYAN" "Speed Slave 결과" "22초"
    cat << 'EOF'

## 결론
최소 권한 IAM 정책 생성 완료.

## 근거
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::devops-receipts",
        "arn:aws:s3:::devops-receipts/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": ["dynamodb:GetItem", "dynamodb:PutItem",
                  "dynamodb:UpdateItem", "dynamodb:Query"],
      "Resource": "arn:aws:dynamodb:ap-northeast-2:*:table/payment-log"
    }
  ]
}
```

## 리스크
- Account ID 하드코딩 대신 * 사용 → 멀티 계정 환경에서 위험

## 실행안
Account ID를 실제 값으로 교체 후 적용

EOF

    separator
    agent_header "Codex" "$PURPLE" "Precision Slave 결과" "51초"
    cat << 'EOF'

## 결론
보안 강화된 최소 권한 IAM 정책 생성 완료.

## 근거
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3ReadReceipts",
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": "arn:aws:s3:::devops-receipts/*"
    },
    {
      "Sid": "S3ListReceipts",
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::devops-receipts",
      "Condition": {
        "StringLike": { "s3:prefix": ["receipts/*", "invoices/*"] }
      }
    },
    {
      "Sid": "DynamoDBReadWrite",
      "Effect": "Allow",
      "Action": ["dynamodb:GetItem", "dynamodb:PutItem",
                  "dynamodb:UpdateItem", "dynamodb:Query"],
      "Resource": [
        "arn:aws:dynamodb:ap-northeast-2:123456789012:table/payment-log",
        "arn:aws:dynamodb:ap-northeast-2:123456789012:table/payment-log/index/*"
      ]
    }
  ]
}
```

## 리스크
- Condition의 prefix 경로가 실제 키 구조와 일치하는지 확인 필요
- BatchWriteItem이 필요한 경우 Action 추가 필요

## 실행안
1. S3 키 구조 확인 후 prefix Condition 조정
2. Lambda 코드에서 BatchWriteItem 사용 여부 확인
3. terraform plan으로 dry-run 후 적용

EOF

    separator
    master_judge
    sleep 1
    echo ""
    echo -e "  ${DIM}두 결과 비교 분석 중...${NC}"
    wait_spinner 2 "차이점 3건 식별"
    echo ""
    cat << 'EOF'

## 결론
**Codex 버전 채택** (3가지 차이점에서 모두 Codex 우위)

## 근거
| # | 차이점 | Gemini | Codex | 판정 |
|---|--------|--------|-------|------|
| 1 | Sid 명시 | ❌ 없음 | ✅ 있음 | Codex — 감사 추적 가능 |
| 2 | S3 Condition | ❌ 없음 | ✅ prefix 제한 | Codex — 더 최소 권한 |
| 3 | DynamoDB GSI | ❌ 누락 | ✅ index/* 포함 | Codex — Query 시 GSI 필요 |

보안 정책(claude-policies/common/security-baseline.md) 기준:
- "Sid 명시" 규칙 → Codex 충족, Gemini 미충족
- "GSI/인덱스 포함" 규칙 → Codex 충족, Gemini 미충족

## 리스크
- Codex의 Condition prefix `["receipts/*", "invoices/*"]`가 실제 S3 키 구조와 맞는지 미확인
- Account ID `123456789012`는 실제 값으로 교체 필요

## 실행안
1. `aws s3 ls s3://devops-receipts/ --profile sso-prod`로 키 구조 확인
2. prefix Condition 조정
3. Account ID 교체 후 terraform plan 실행

EOF
}

# ============================================================
# 시나리오 3: @build — Kiro 스펙 → Codex 구현 (NEW)
# ============================================================
scenario_build() {
    echo ""
    echo -e "${BOLD}${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  시나리오 3: @build — Kiro 스펙 기반 구현 (NEW)${NC}"
    echo -e "${BOLD}${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    prompt_input "@build Lambda@Edge로 canary 배포 라우팅 구현해줘. 10% 트래픽을 v2로 보내야 해"

    echo -e "${BLUE}[Master]${NC} 모드 감지: ${CYAN}@build${NC} → Kiro(스펙) → Codex(구현) 순차 실행"
    echo -e "${BLUE}[Master]${NC} ai-delegate.sh build 호출..."
    sleep 1

    # Step 1: Kiro
    agent_header "Kiro CLI" "$CYAN" "Spec Slave — Step 1/2" "120s timeout"
    echo -e "  ${DIM}kiro-cli --non-interactive --prompt \"...\"${NC}"
    wait_spinner 2 "요구사항 분석 중..."
    wait_spinner 2 "기술 설계 작성 중..."
    wait_spinner 1 "태스크 분해 중..."
    echo -e "  ${CYAN}✓ Kiro 완료 (38초)${NC}"
    echo ""

    cat << 'EOF'

## 결론
Lambda@Edge Canary 라우팅 설계 완료. 3개 컴포넌트, 5개 태스크.

## 근거

### 요구사항 분석
- **기능**: CloudFront 요청의 10%를 v2 오리진으로 라우팅
- **비기능**: 지연시간 추가 <1ms, 롤백 즉시 가능, 비율 동적 조정

### 기술 설계
```
Client → CloudFront → Lambda@Edge (viewer-request)
                          │
                     ┌────┴────┐
                     │ random  │
                     │ < 0.10? │
                     └────┬────┘
                    yes   │   no
                     ┌────┴────┐
                     ▼         ▼
               Origin v2   Origin v1
               (canary)    (stable)
```

**컴포넌트:**
1. `canary-router` Lambda@Edge (viewer-request)
2. SSM Parameter `/canary/ratio` (비율 동적 조정)
3. CloudFront Origin Group (v1 + v2)

### 태스크 분해
- [ ] T1: Lambda@Edge 함수 작성 (canary-router)
- [ ] T2: SSM Parameter 생성 (/canary/ratio = 0.10)
- [ ] T3: CloudFront distribution에 Lambda@Edge 연결
- [ ] T4: Origin Group 설정 (v1-stable, v2-canary)
- [ ] T5: 모니터링 대시보드 (v1/v2 트래픽 비교)

### 검증 체크리스트
- [ ] 배포 전: v2 오리진 health check 통과 확인
- [ ] 배포 중: CloudFront 캐시 무효화 여부 확인
- [ ] 배포 후: v2 트래픽 비율이 10% ± 2% 범위인지 5분간 모니터링

## 리스크
- Lambda@Edge는 us-east-1에서만 배포 가능 (리전 제약)
- SSM Parameter 조회 시 콜드스타트 지연 가능 → 캐싱 필요
- viewer-request 트리거는 본문 접근 불가 (필요 시 origin-request로 변경)

## 실행안
1. Codex가 T1~T4 구현 (이 스펙 기반)
2. T5 모니터링은 별도 @scan으로 Datadog 대시보드 생성
3. 구현 후 staging 환경에서 트래픽 비율 검증

EOF

    separator
    echo -e "  ${BLUE}[Master]${NC} Kiro 스펙을 Codex에 전달..."
    sleep 1

    # Step 2: Codex
    agent_header "Codex CLI" "$PURPLE" "Precision Slave — Step 2/2" "90s timeout"
    echo -e "  ${DIM}codex --dangerously-bypass-approvals-and-sandbox --prompt \"...\"${NC}"
    echo -e "  ${DIM}[입력: Kiro 스펙 + 원본 요청]${NC}"
    wait_spinner 2 "T1: Lambda@Edge 함수 작성..."
    wait_spinner 2 "T2: SSM Parameter + T3: CloudFront 설정..."
    wait_spinner 1 "T4: Terraform 코드 생성..."
    echo -e "  ${PURPLE}✓ Codex 완료 (67초)${NC}"
    echo ""

    cat << 'EOF'

## 결론
Kiro 스펙 기반 4개 태스크 구현 완료. Terraform + Lambda 코드 생성.

## 근거

**T1: canary-router Lambda@Edge**
```javascript
// canary-router/index.js
const { SSMClient, GetParameterCommand } = require('@aws-sdk/client-ssm');

let cachedRatio = null;
let cacheExpiry = 0;
const CACHE_TTL = 300000; // 5분 캐시 (Kiro 리스크 반영)

async function getCanaryRatio() {
  if (cachedRatio !== null && Date.now() < cacheExpiry) return cachedRatio;
  const ssm = new SSMClient({ region: 'us-east-1' });
  const res = await ssm.send(new GetParameterCommand({
    Name: '/canary/ratio'
  }));
  cachedRatio = parseFloat(res.Parameter.Value);
  cacheExpiry = Date.now() + CACHE_TTL;
  return cachedRatio;
}

exports.handler = async (event) => {
  const request = event.Records[0].cf.request;
  const ratio = await getCanaryRatio();

  if (Math.random() < ratio) {
    request.origin = {
      custom: {
        domainName: 'v2.api.example.com',
        port: 443,
        protocol: 'https',
        path: '',
        sslProtocols: ['TLSv1.2'],
        readTimeout: 30,
        keepaliveTimeout: 5
      }
    };
    request.headers['x-canary'] = [{ key: 'X-Canary', value: 'true' }];
  }
  return request;
};
```

**T2~T4: Terraform**
```hcl
resource "aws_ssm_parameter" "canary_ratio" {
  name  = "/canary/ratio"
  type  = "String"
  value = "0.10"
  tags  = { Environment = "prod", ManagedBy = "terraform" }
}

resource "aws_lambda_function" "canary_router" {
  function_name = "canary-router"
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  publish       = true  # Lambda@Edge requires versioned
  # ... (생략)
}
```

## 리스크
- SSM GetParameter IAM 권한이 Lambda@Edge 실행 역할에 필요
- us-east-1 배포 필수 (Kiro 스펙 리스크 항목 반영 ✓)
- Math.random() 분포는 대수의 법칙에 의존 → 소량 트래픽 시 편차 클 수 있음

## 실행안
1. Lambda 실행 역할에 SSM GetParameter 권한 추가
2. staging CloudFront에 먼저 배포
3. `X-Canary: true` 헤더로 v2 트래픽 필터링 모니터링

EOF

    separator
    master_judge
    sleep 1
    echo ""
    echo -e "  ${DIM}Kiro 스펙 ↔ Codex 구현 대조 중...${NC}"
    wait_spinner 2 "스펙 충족 여부 판정"
    echo ""

    cat << 'EOF'

## 결론
**스펙 충족률 95%** — 구현 채택, 1건 보완 필요

## 근거
| 스펙 항목 | Codex 구현 | 충족 |
|----------|-----------|------|
| T1: Lambda@Edge | ✅ viewer-request 핸들러 | ✅ |
| T2: SSM Parameter | ✅ Terraform 리소스 | ✅ |
| T3: CloudFront 연결 | ⚠️ Terraform 일부만 | 부분 |
| T4: Origin Group | ✅ 코드에 v2 오리진 설정 | ✅ |
| 콜드스타트 캐싱 | ✅ 5분 TTL 캐시 구현 | ✅ |
| 리전 제약 반영 | ✅ us-east-1 명시 | ✅ |

**미충족 1건:** CloudFront distribution 리소스 자체의 Terraform 정의가 생략됨
→ 기존 distribution에 연결하는 것이면 OK, 신규라면 추가 필요

## 리스크
- 기존 CloudFront가 없으면 distribution 리소스 추가 필요

## 실행안
1. 기존 CloudFront distribution ID 확인
2. 있으면 → `aws_cloudfront_distribution` data source로 참조
3. 없으면 → Codex에게 distribution 리소스 추가 요청 (@craft)

EOF
}

# ============================================================
# 시나리오 4: @mobilize — 장애 대응 4-Agent 순차
# ============================================================
scenario_mobilize() {
    echo ""
    echo -e "${BOLD}${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  시나리오 4: @mobilize — RDS 메이저 업그레이드 (4-Agent 순차)${NC}"
    echo -e "${BOLD}${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    prompt_input "@mobilize imweb-prod-main RDS MySQL 8.0 → 8.4 메이저 업그레이드 계획 수립. 다운타임 최소화."

    echo -e "${BLUE}[Master]${NC} 모드 감지: ${RED}@mobilize${NC} → 4-Agent 순차 실행"
    echo -e "${BLUE}[Master]${NC} ${RED}프로덕션 데이터베이스 변경 → mobilize 모드 확인됨${NC}"
    echo -e "${BLUE}[Master]${NC} 파이프라인: Kiro(설계) → Codex(검증) → Gemini(영향도) → Master(판정)"
    echo -e "${BLUE}[Master]${NC} ai-delegate.sh mobilize 호출..."
    sleep 1

    # Step 1: Kiro
    agent_header "Kiro CLI" "$CYAN" "Step 1/3 — 설계 및 체크리스트" "120s"
    wait_spinner 3 "업그레이드 설계 문서 작성 중..."
    echo -e "  ${CYAN}✓ Kiro 완료 (52초)${NC}"
    echo ""
    cat << 'EOF'
## 결론
Blue-Green 방식 RDS 메이저 업그레이드 설계. 예상 다운타임 90초.

## 근거
### 업그레이드 전략: Blue-Green Deployment
```
[Blue: MySQL 8.0]  ──snapshot──▶  [Green: MySQL 8.4]
       │                                │
  현재 프로덕션                    업그레이드 + 검증
       │                                │
       └────── switchover (90초) ────────┘
```

### 사전 검증 태스크
- [ ] P1: 호환성 — deprecated SQL 모드, 제거된 함수 확인
- [ ] P2: 파라미터 그룹 — 8.0 → 8.4 diff 분석
- [ ] P3: 리플리카 — Read Replica 호환성 확인
- [ ] P4: 애플리케이션 — connection string, driver 버전 확인

### 실행 윈도우
- 권장: 화요일 02:00~04:00 KST (트래픽 최저)
- 롤백 포인트: switchover 전까지 무중단 롤백 가능

## 리스크
- `utf8mb3` → `utf8mb4` 암묵적 변환 시 인덱스 크기 초과 가능
- Group Replication 플러그인 호환성 미확인
- Blue-Green switchover 중 in-flight 트랜잭션 유실 가능

## 실행안
Codex가 P1~P4 사전 검증 수행 → Gemini가 트래픽/영향도 분석
EOF

    separator
    echo -e "  ${BLUE}[Master]${NC} Kiro 설계를 Codex에 전달..."
    sleep 1

    # Step 2: Codex
    agent_header "Codex CLI" "$PURPLE" "Step 2/3 — 코드 및 설정 검증" "90s"
    echo -e "  ${DIM}[입력: Kiro 설계 결과]${NC}"
    wait_spinner 2 "P1: deprecated SQL 함수 스캔..."
    wait_spinner 2 "P2: 파라미터 그룹 diff 생성..."
    wait_spinner 1 "P3~P4: 호환성 체크..."
    echo -e "  ${PURPLE}✓ Codex 완료 (71초)${NC}"
    echo ""
    cat << 'EOF'
## 결론
사전 검증 4건 중 2건 주의사항 발견. 업그레이드 가능하나 조치 필요.

## 근거
| 검증 | 결과 | 상세 |
|------|------|------|
| P1 deprecated SQL | ⚠️ 주의 | `SQL_CALC_FOUND_ROWS` 3곳 사용 중 |
| P2 파라미터 그룹 | ⚠️ 주의 | `innodb_undo_tablespaces` 기본값 변경 |
| P3 Read Replica | ✅ 호환 | Multi-AZ 리플리카 정상 |
| P4 애플리케이션 | ✅ 호환 | mysql2 드라이버 3.x 호환 확인 |

**P1 상세:** `SQL_CALC_FOUND_ROWS`는 8.0.17에서 deprecated, 8.4에서 경고 발생
```sql
-- 변경 필요 파일:
-- app/models/board.php:142
-- app/models/product.php:89
-- app/models/order.php:231
SELECT SQL_CALC_FOUND_ROWS * FROM ... → SELECT COUNT(*) OVER() ...
```

## 리스크
- P1 미조치 시 8.4에서 경고 로그 폭발 (기능은 동작)
- innodb_undo_tablespaces 변경으로 스토리지 일시 증가 가능

## 실행안
1. P1: 3개 파일 SQL 수정 → 사전 배포 (업그레이드 전)
2. P2: 커스텀 파라미터 그룹에 innodb_undo_tablespaces=2 명시
3. Blue-Green 생성 전 스냅샷 추가 백업
EOF

    separator
    echo -e "  ${BLUE}[Master]${NC} Kiro 설계 + Codex 검증을 Gemini에 전달..."
    sleep 1

    # Step 3: Gemini
    agent_header "Gemini CLI" "$CYAN" "Step 3/3 — 영향도 분석" "45s"
    echo -e "  ${DIM}[입력: Kiro 설계 + Codex 검증 결과]${NC}"
    wait_spinner 2 "현재 트래픽 패턴 분석 (Datadog)..."
    wait_spinner 1 "의존 서비스 매핑..."
    echo -e "  ${CYAN}✓ Gemini 완료 (18초)${NC}"
    echo ""
    cat << 'EOF'
## 결론
화요일 02:00 KST 업그레이드 최적. 영향 서비스 4개, 직접 영향 사용자 ~200명.

## 근거
- 02:00~04:00 평균 RPS: 45 (피크 대비 3%)
- DB 의존 서비스: api-server, batch-worker, admin-panel, event-processor
- switchover 90초 동안 영향받는 예상 요청: ~4,050건
- 재시도 로직 있는 서비스: api-server(✅), batch-worker(✅)
- 재시도 로직 없는 서비스: admin-panel(❌), event-processor(❌)

## 리스크
- admin-panel: DB 연결 끊김 시 500 에러 → 관리자 수동 새로고침 필요
- event-processor: 이벤트 유실 가능 → SQS DLQ에서 재처리 필요

## 실행안
1. 업그레이드 30분 전: event-processor 일시 중지 (SQS에 적재)
2. switchover 완료 후: event-processor 재시작 → DLQ 확인
3. admin-panel: 공지 배너 "02:00~02:30 점검" 표시
EOF

    separator
    master_judge
    sleep 1
    echo ""
    echo -e "  ${DIM}3단계 결과 통합 중...${NC}"
    wait_spinner 3 "Go/No-Go 판정"
    echo ""

    cat << 'EOF'

## 결론
**Go — 조건부 승인** (P1 SQL 수정 사전 배포 완료 조건)

## 근거
| 단계 | 에이전트 | 핵심 발견 | 판정 |
|------|---------|----------|------|
| 설계 | Kiro | Blue-Green 전략, 90초 다운타임 | ✅ |
| 검증 | Codex | SQL_CALC_FOUND_ROWS 3곳 수정 필요 | ⚠️ 사전 조치 |
| 영향도 | Gemini | 02:00 최적, event-processor 일시 중지 필요 | ⚠️ 운영 조치 |

**종합 판정:**
- Kiro의 Blue-Green 전략은 적절함 (다운타임 최소화)
- Codex가 발견한 SQL 호환성 이슈는 **업그레이드 전 사전 배포 필수**
- Gemini의 트래픽 분석으로 최적 시간대와 운영 절차 확정

## 리스크
1. [높음] P1 SQL 미수정 시 경고 로그 폭발
2. [중간] event-processor 이벤트 유실 → DLQ 재처리로 커버
3. [낮음] admin-panel 일시 500 → 자동 복구

## 실행안 (통합 체크리스트)

### D-7 (사전 준비)
- [ ] P1: SQL_CALC_FOUND_ROWS 3곳 수정 PR → 리뷰 → 배포
- [ ] 커스텀 파라미터 그룹 8.4용 생성 (innodb_undo_tablespaces=2)
- [ ] admin-panel 점검 배너 코드 준비

### D-1 (전일)
- [ ] RDS 수동 스냅샷 생성
- [ ] Blue-Green 배포 생성 (AWS 콘솔 또는 Terraform)
- [ ] Green 인스턴스 정상 동작 확인

### D-Day 02:00
- [ ] 01:30 — event-processor 일시 중지
- [ ] 01:45 — admin-panel 점검 배너 활성화
- [ ] 02:00 — Blue-Green switchover 실행
- [ ] 02:02 — 연결 정상 확인 (api-server, batch-worker)
- [ ] 02:05 — event-processor 재시작
- [ ] 02:10 — Datadog 대시보드에서 에러율 확인
- [ ] 02:30 — 점검 배너 해제, 정상 운영 선언

### 롤백 기준
- switchover 후 5분 내 5xx 비율 > 5% → 즉시 롤백
- DB 연결 실패 > 10건/분 → 즉시 롤백

EOF
}

# ============================================================
# 시나리오 5: 자동 다운그레이드 시연
# ============================================================
scenario_downgrade() {
    echo ""
    echo -e "${BOLD}${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  시나리오 5: 자동 다운그레이드 (@verify → @ask)${NC}"
    echo -e "${BOLD}${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    prompt_input "@verify EC2 레거시 서버에서 config_common.php 설정 로딩 체인 추적해줘"

    echo -e "${BLUE}[Master]${NC} 모드 감지: ${YELLOW}@verify${NC} → Gemini + Codex 병렬 실행"
    sleep 1

    echo ""
    echo -e "  ${CYAN}Gemini${NC} ━━━▶ ${DIM}실행 중...${NC}"
    echo -e "  ${PURPLE}Codex${NC}  ━━━▶ ${DIM}실행 중...${NC}"
    wait_spinner 2 "Slave 에이전트 작업 중..."

    echo ""
    echo -e "  ${CYAN}✗ Gemini: 파일 구조 파악 실패 — 엉뚱한 경로 제시${NC}"
    echo -e "  ${PURPLE}✗ Codex: sandbox에서 SSM 접근 불가 — 타임아웃${NC}"
    echo ""

    echo -e "${YELLOW}[Master]${NC} ${BOLD}⚡ 자동 다운그레이드 발동${NC}"
    echo -e "${YELLOW}[Master]${NC} 규칙: \"@verify → @ask: 대규모 레거시 코드베이스 탐색\""
    echo -e "${YELLOW}[Master]${NC} Slave가 파일 구조 파악에 실패 → Master 직접 처리"
    echo ""
    sleep 1

    agent_header "Claude (Master)" "$GREEN" "@ask 모드로 직접 처리" "제한 없음"
    wait_spinner 1 "SSM으로 서버 접속..."
    echo -e "  ${DIM}\$ aws ssm start-session --target i-0abc123def456${NC}"
    wait_spinner 1 "grep -r 'config_common' /var/www/html/"
    wait_spinner 1 "설정 로딩 체인 추적..."
    echo -e "  ${GREEN}✓ 5분 만에 해결${NC}"
    echo ""

    cat << 'EOF'
## 결론
config_common.php는 3단계 체인으로 로드됨:
`index.php` → `bootstrap.php` → `config_common.php`

## 근거
```
/var/www/html/index.php:3        require_once('bootstrap.php')
/var/www/html/bootstrap.php:17   require_once('config/config_common.php')
/var/www/html/config/config_common.php:1   (DB 연결, 캐시 설정 등)
```

## 리스크
- config_common.php 변경 시 모든 요청에 영향 (index.php에서 로드)
- 파일 경로 하드코딩 — autoloader 미사용

## 실행안
- 설정 변경 시 staging에서 먼저 검증
- 장기적으로 PSR-4 autoloader 도입 검토

EOF

    echo -e "${BLUE}[Master]${NC} ${DIM}교훈: 멀티에이전트가 항상 좋은 건 아닙니다.${NC}"
    echo -e "${BLUE}[Master]${NC} ${DIM}적절한 도구를 적절한 상황에 쓰는 게 핵심입니다.${NC}"
}

# ============================================================
# 메인
# ============================================================
main() {
    echo ""
    echo -e "${BOLD}${WHITE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${WHITE}║  Multi-Agent CLI Simulation (4-Agent Architecture)      ║${NC}"
    echo -e "${BOLD}${WHITE}║  Claude(Master) + Gemini(Speed) + Codex(Craft)           ║${NC}"
    echo -e "${BOLD}${WHITE}║                + Kiro(Design) ← NEW                      ║${NC}"
    echo -e "${BOLD}${WHITE}╚══════════════════════════════════════════════════════════╝${NC}"

    local scenario="${1:-all}"

    case "$scenario" in
        1|scan)      scenario_scan ;;
        2|verify)    scenario_verify ;;
        3|build)     scenario_build ;;
        4|mobilize)  scenario_mobilize ;;
        5|downgrade) scenario_downgrade ;;
        all)
            scenario_scan
            echo ""; echo ""; sleep 2
            scenario_verify
            echo ""; echo ""; sleep 2
            scenario_build
            echo ""; echo ""; sleep 2
            scenario_mobilize
            echo ""; echo ""; sleep 2
            scenario_downgrade
            ;;
        *)
            echo "Usage: simulate.sh [1|2|3|4|5|all]"
            echo "  1/scan      - @scan SG 전수 검사"
            echo "  2/verify    - @verify IAM 교차 검증"
            echo "  3/build     - @build Kiro 스펙 → Codex 구현"
            echo "  4/mobilize  - @mobilize RDS 업그레이드 4-Agent"
            echo "  5/downgrade - 자동 다운그레이드 시연"
            echo "  all         - 전체 시나리오 (기본)"
            ;;
    esac

    echo ""
    separator
    echo -e "${DIM}Simulation complete.${NC}"
    echo ""
}

main "$@"
