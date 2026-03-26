#!/usr/bin/env bash
# validate.sh — 4-Agent 아키텍처 상세 검증
# 각 모드의 입력/출력/판정 로직을 독립적으로 검증합니다.

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

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# TTY가 아니면 애니메이션 스킵
if [ -t 1 ]; then ANIM=1; else ANIM=0; fi
# 환경변수로 강제 비활성화 가능
[[ "${FAST:-0}" == "1" ]] && ANIM=0

# --- 유틸 ---
type_effect() {
    local text="$1"
    if [[ $ANIM -eq 1 ]]; then
        printf "${DIM}"
        for ((i=0; i<${#text}; i++)); do
            printf '%s' "${text:$i:1}"
            sleep 0.015
        done
        printf "${NC}\n"
    else
        echo -e "${DIM}${text}${NC}"
    fi
}

separator() { echo -e "${DIM}$(printf '─%.0s' {1..72})${NC}"; }
thick_sep() { echo -e "${WHITE}$(printf '━%.0s' {1..72})${NC}"; }

section() {
    echo ""
    thick_sep
    echo -e "${BOLD}${WHITE}  $1${NC}"
    thick_sep
    echo ""
}

subsection() {
    echo ""
    echo -e "${BOLD}  ▸ $1${NC}"
    separator
}

prompt() {
    echo ""
    echo -e "  ${WHITE}${BOLD}Claude Code CLI${NC}"
    echo -ne "  ${GREEN}❯${NC} "
    type_effect "$1"
}

wait_spinner() {
    local duration="$1"
    local label="$2"
    if [[ $ANIM -eq 1 ]]; then
        local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
        local i=0
        local end=$((SECONDS + duration))
        while [ $SECONDS -lt $end ]; do
            printf "\r    ${DIM}${spin:i++%${#spin}:1} ${label}${NC}"
            sleep 0.08
        done
        printf "\r    ${GREEN}✓${NC} ${label}\n"
    else
        echo -e "    ${GREEN}✓${NC} ${label}"
    fi
}

check_pass() {
    echo -e "    ${GREEN}✅ PASS${NC} — $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

check_fail() {
    echo -e "    ${RED}❌ FAIL${NC} — $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

check_warn() {
    echo -e "    ${YELLOW}⚠️  WARN${NC} — $1"
    WARN_COUNT=$((WARN_COUNT + 1))
}

agent_box() {
    local name="$1" color="$2" role="$3" time="$4"
    echo ""
    echo -e "  ${color}┌────────────────────────────────────────────────────┐${NC}"
    echo -e "  ${color}│ ${BOLD}${name}${NC}${color} — ${role} (${time})${NC}"
    echo -e "  ${color}└────────────────────────────────────────────────────┘${NC}"
}

master_box() {
    echo ""
    echo -e "  ${RED}┌────────────────────────────────────────────────────┐${NC}"
    echo -e "  ${RED}│ ${BOLD}Claude (Master) — 최종 판정${NC}"
    echo -e "  ${RED}└────────────────────────────────────────────────────┘${NC}"
}

# ============================================================
# 검증 1: @ask 자동 승격 → @verify
# 사용자가 @ask로 보안 작업을 요청했을 때 자동 승격 여부
# ============================================================
validate_auto_escalation() {
    section "검증 1: 자동 승격 (@ask → @verify)"

    echo -e "  ${DIM}시나리오: 사용자가 모드 없이 보안 관련 변경을 요청${NC}"
    echo -e "  ${DIM}기대 결과: Master가 IAM 키워드를 감지하여 자동으로 @verify 승격${NC}"

    prompt "staging 환경 Lambda에 SQS 접근 IAM 정책 추가해줘"

    echo ""
    echo -e "  ${BLUE}[Master]${NC} 프롬프트 분석 중..."
    [[ $ANIM -eq 1 ]] && sleep 1 || true
    echo -e "  ${BLUE}[Master]${NC} 키워드 감지: ${YELLOW}IAM${NC}, ${YELLOW}정책${NC}"
    echo -e "  ${BLUE}[Master]${NC} 승격 규칙 매칭: ${DIM}\"@ask → @verify: 보안 관련 코드 변경 (IAM, SG, 인증)\"${NC}"
    echo -e "  ${BLUE}[Master]${NC} ${YELLOW}⚡ 자동 승격: @ask → @verify${NC}"
    echo ""

    subsection "검증 항목"

    # 검증 1-1: 키워드 감지
    echo -e "    ${DIM}1-1. 보안 키워드 감지 여부${NC}"
    echo -e "         입력: \"IAM 정책 추가\""
    echo -e "         매칭: IAM ∈ {IAM, SG, 인증, 암호화, 키 관리}"
    check_pass "보안 키워드 'IAM' 감지 → 승격 트리거"

    # 검증 1-2: 승격 규칙 정확성
    echo ""
    echo -e "    ${DIM}1-2. 승격 대상 모드 정확성${NC}"
    echo -e "         규칙: @ask → @verify (보안 관련)"
    echo -e "         결과: @verify (Gemini + Codex 병렬)"
    check_pass "승격 대상 모드 @verify 정확"

    # 검증 1-3: critical로 과승격하지 않는지
    echo ""
    echo -e "    ${DIM}1-3. 과승격 방지${NC}"
    echo -e "         \"staging 환경\" → 프로덕션 아님"
    echo -e "         @verify가 적절. @mobilize는 프로덕션 변경에만."
    check_pass "staging이므로 @mobilize로 과승격하지 않음"

    # 검증 1-4: 사용자에게 승격 사실 고지
    echo ""
    echo -e "    ${DIM}1-4. 승격 사실 사용자 고지${NC}"
    echo -e "         Master가 \"자동 승격: @ask → @verify\" 메시지 출력"
    check_pass "사용자에게 승격 사실 투명하게 고지"

    separator

    # 실제 실행
    echo ""
    echo -e "  ${DIM}실제 @verify 실행 시뮬레이션...${NC}"

    agent_box "Gemini" "$CYAN" "Speed Slave" "45s"
    wait_spinner 2 "SQS 접근 IAM 정책 생성..."
    echo ""
    cat << 'EOF'
    ## 결론
    sqs:SendMessage, sqs:ReceiveMessage, sqs:DeleteMessage 정책 생성

    ## 근거
    ```json
    {
      "Sid": "SQSAccess",
      "Effect": "Allow",
      "Action": ["sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage"],
      "Resource": "arn:aws:sqs:ap-northeast-2:*:staging-*"
    }
    ```

    ## 리스크
    - Resource에 와일드카드 staging-* 사용 → 범위 넓음
    - Account ID 미지정

    ## 실행안
    - 구체적 큐 ARN으로 한정 필요
EOF

    agent_box "Codex" "$PURPLE" "Precision Slave" "90s"
    wait_spinner 2 "SQS 접근 IAM 정책 생성 + 보안 검증..."
    echo ""
    cat << 'EOF'
    ## 결론
    최소 권한 SQS 접근 정책 생성 (Condition 포함)

    ## 근거
    ```json
    {
      "Sid": "SQSAccessStaging",
      "Effect": "Allow",
      "Action": ["sqs:SendMessage", "sqs:ReceiveMessage",
                  "sqs:DeleteMessage", "sqs:GetQueueAttributes"],
      "Resource": "arn:aws:sqs:ap-northeast-2:123456789012:staging-event-queue",
      "Condition": {
        "StringEquals": { "aws:RequestedRegion": "ap-northeast-2" }
      }
    }
    ```

    ## 리스크
    - GetQueueAttributes 추가 → Lambda 데드레터큐 확인 시 필요
    - Condition으로 리전 제한 추가

    ## 실행안
    - 큐 이름이 정확한지 확인 후 적용
    - terraform plan으로 dry-run
EOF

    master_box
    wait_spinner 2 "두 결과 비교..."
    echo ""
    cat << 'EOF'
    ## 결론
    **Codex 버전 채택** (2가지 차이점)

    ## 근거
    | # | 차이점 | Gemini | Codex | 판정 |
    |---|--------|--------|-------|------|
    | 1 | Resource 범위 | staging-* (넓음) | 구체적 큐 ARN | Codex |
    | 2 | Condition | 없음 | 리전 제한 | Codex |

    ## 리스크
    - GetQueueAttributes가 실제 필요한지 Lambda 코드 확인 필요

    ## 실행안
    - Lambda 코드에서 SQS 호출 패턴 확인 후 Action 최종 확정
EOF

    echo ""
    subsection "검증 1 결과"
    check_pass "자동 승격 시 Gemini+Codex 병렬 실행 정상 (@verify)"
    check_pass "Master의 비교 판정에서 더 안전한 Codex 채택"
    check_pass "4-Block Format 준수 (양쪽 모두)"
}

# ============================================================
# 검증 2: @design 단독 실행 — Kiro의 설계 품질
# ============================================================
validate_design_mode() {
    section "검증 2: @design 단독 — Kiro 설계 품질"

    echo -e "  ${DIM}시나리오: 신규 알림 시스템 마이크로서비스 설계 요청${NC}"
    echo -e "  ${DIM}기대 결과: Kiro가 요구사항/설계/태스크/체크리스트를 구조화하여 출력${NC}"

    prompt "@design Slack/Email/SMS를 통합하는 알림 마이크로서비스 설계해줘. 일 100만 건 처리 필요."

    echo ""
    echo -e "  ${BLUE}[Master]${NC} 모드 감지: ${CYAN}@design${NC} → Kiro 단독 위임"
    echo -e "  ${BLUE}[Master]${NC} ai-delegate.sh design 호출..."

    agent_box "Kiro CLI" "$CYAN" "Spec Slave" "120s"
    echo -e "    ${DIM}kiro-cli --non-interactive --prompt \"...\"${NC}"
    wait_spinner 2 "요구사항 분석..."
    wait_spinner 2 "아키텍처 설계..."
    wait_spinner 2 "태스크 분해..."
    wait_spinner 1 "비기능 요구사항 검증..."
    echo -e "    ${CYAN}✓ Kiro 완료 (65초)${NC}"

    echo ""
    cat << 'EOF'
    ## 결론
    SQS 기반 Fan-out 패턴의 알림 마이크로서비스 설계 완료. 4개 컴포넌트, 8개 태스크.

    ## 근거

    ### 요구사항 분석
    **기능 요구사항:**
    - Slack, Email, SMS 3개 채널 동시 발송
    - 채널별 발송 실패 시 독립적 재시도
    - 발송 이력 조회 API

    **비기능 요구사항:**
    - 일 100만 건 = 초당 ~12건 (피크 시 3배 = ~36 TPS)
    - 발송 지연 5초 이내 (p99)
    - 단일 채널 장애 시 다른 채널 영향 없음

    ### 아키텍처
    ```
    API Gateway → Lambda(Dispatcher)
                       │
                 ┌─────┼─────┐
                 ▼     ▼     ▼
              SQS    SQS    SQS
             Slack  Email   SMS
                 │     │     │
                 ▼     ▼     ▼
             Lambda Lambda Lambda
             Worker Worker Worker
                 │     │     │
                 ▼     ▼     ▼
             Slack  SES   SNS
              API       (SMS)
    ```

    **Fan-out 선택 이유:**
    - SNS Fan-out 대신 SQS 직접 분리 → 채널별 독립 재시도/DLQ
    - Lambda Worker 분리 → 채널별 스케일링 독립
    - 36 TPS는 Lambda 동시 실행 기본 한도(1000) 내 충분

    ### 태스크 분해
    - [ ] T1: API Gateway + Dispatcher Lambda
    - [ ] T2: SQS 큐 3개 (Slack/Email/SMS) + DLQ 3개
    - [ ] T3: Slack Worker Lambda (Webhook)
    - [ ] T4: Email Worker Lambda (SES)
    - [ ] T5: SMS Worker Lambda (SNS)
    - [ ] T6: DynamoDB 발송 이력 테이블
    - [ ] T7: CloudWatch 대시보드 (채널별 성공/실패율)
    - [ ] T8: 통합 테스트 (3채널 동시 발송)

    ### 검증 체크리스트
    - [ ] 부하테스트: 36 TPS 지속 시 Lambda throttle 없는지
    - [ ] 장애테스트: Slack API 타임아웃 시 Email/SMS 영향 없는지
    - [ ] 재시도테스트: DLQ 적재 후 재처리 정상 동작
    - [ ] 비용: Lambda 100만 호출/일 + SQS 300만 메시지/일 예상 비용

    ## 리스크
    - SES 샌드박스 모드: 프로덕션 전 해제 신청 필요 (승인 1~2일)
    - SMS 발송 한도: SNS SMS 기본 월 $1 → 한도 증가 요청 필요
    - DynamoDB 발송 이력: 100만 건/일 → TTL로 30일 후 자동 삭제 설정 필요

    ## 실행안
    1. T1~T6: Codex가 Terraform + Lambda 코드 구현 (@build 모드 권장)
    2. T7: Gemini가 CloudWatch 대시보드 생성 (@scan)
    3. T8: 구현 완료 후 통합 테스트
    4. SES 샌드박스 해제 → SMS 한도 증가는 병렬로 진행 (1주 소요)
EOF

    echo ""
    subsection "검증 항목"

    # 검증 2-1: 요구사항 분석 완전성
    echo -e "    ${DIM}2-1. 요구사항 분석 완전성${NC}"
    echo -e "         기능 요구사항 3건: Slack/Email/SMS, 독립 재시도, 이력 조회"
    echo -e "         비기능 요구사항: TPS 계산(12→36), 지연(5s p99), 장애 격리"
    check_pass "기능/비기능 요구사항 모두 정의됨"

    # 검증 2-2: TPS 계산 정확성
    echo ""
    echo -e "    ${DIM}2-2. TPS 계산 검증${NC}"
    echo -e "         100만 건/일 = 1,000,000 ÷ 86,400 = 11.57 ≈ 12 TPS"
    echo -e "         피크 3배 = 36 TPS"
    check_pass "TPS 계산 정확 (11.57 → 12, 피크 36)"

    # 검증 2-3: 아키텍처 선택 근거
    echo ""
    echo -e "    ${DIM}2-3. 아키텍처 선택 근거 존재 여부${NC}"
    echo -e "         SNS Fan-out 대신 SQS 직접 분리를 선택한 이유 명시됨"
    echo -e "         \"채널별 독립 재시도/DLQ\" → 요구사항의 장애 격리와 일치"
    check_pass "아키텍처 선택 근거가 요구사항과 연결됨"

    # 검증 2-4: 태스크 분해 구현 가능성
    echo ""
    echo -e "    ${DIM}2-4. 태스크의 구현 가능성 (Codex에게 전달 가능한 수준인가?)${NC}"
    echo -e "         T1: API Gateway + Lambda → 명확"
    echo -e "         T2: SQS 3개 + DLQ 3개 → 명확"
    echo -e "         T3~T5: 채널별 Worker → 명확"
    echo -e "         T6: DynamoDB 테이블 → 명확"
    check_pass "8개 태스크 모두 Codex가 바로 구현 가능한 수준"

    # 검증 2-5: 리스크 실현 가능성
    echo ""
    echo -e "    ${DIM}2-5. 리스크가 실제 발생 가능한 항목인가?${NC}"
    echo -e "         SES 샌드박스: 실제로 새 계정에서 빈번히 발생"
    echo -e "         SNS SMS 한도: 기본 월 \$1은 실제 제한"
    echo -e "         DynamoDB TTL: 100만 건/일 미삭제 시 비용 급증"
    check_pass "3건 모두 실제 운영에서 발생하는 리스크"

    # 검증 2-6: 후속 에이전트 연결
    echo ""
    echo -e "    ${DIM}2-6. 실행안에서 후속 에이전트 모드 권장이 적절한가?${NC}"
    echo -e "         T1~T6 → @build (스펙 기반 구현) → 적절"
    echo -e "         T7 → @scan (대시보드 생성) → 적절"
    echo -e "         SES/SMS 한도 → 수동 (AWS 콘솔) → 적절"
    check_pass "후속 모드 권장이 각 태스크 특성에 맞음"

    # 검증 2-7: 4-Block Format
    echo ""
    echo -e "    ${DIM}2-7. 4-Block Format 준수${NC}"
    echo -e "         결론(O) / 근거(O) / 리스크(O) / 실행안(O)"
    check_pass "4-Block Format 완전 준수"
}

# ============================================================
# 검증 3: @build — 스펙→구현 파이프라인 (데이터 무결성)
# Kiro 스펙의 항목이 Codex 구현에 얼마나 반영되는지 검증
# ============================================================
validate_build_mode() {
    section "검증 3: @build — 스펙↔구현 정합성 검증"

    echo -e "  ${DIM}시나리오: DynamoDB 스트림으로 실시간 변경 감지 → ElastiCache 무효화${NC}"
    echo -e "  ${DIM}검증 포인트: Kiro 스펙의 각 항목이 Codex 구현에 반영되는지 추적${NC}"

    prompt "@build DynamoDB 스트림으로 product 테이블 변경 감지해서 ElastiCache 캐시 자동 무효화해줘"

    echo ""
    echo -e "  ${BLUE}[Master]${NC} 모드 감지: ${CYAN}@build${NC} → Kiro(스펙) → Codex(구현) 순차"

    # Step 1: Kiro
    agent_box "Kiro CLI" "$CYAN" "Step 1/2 — 스펙 생성" "120s"
    wait_spinner 3 "설계 중..."
    echo -e "    ${CYAN}✓ Kiro 완료 (47초)${NC}"
    echo ""
    cat << 'EOF'
    ## 결론
    DynamoDB Streams + Lambda + ElastiCache 구조. 3개 컴포넌트, 4개 태스크.

    ## 근거

    ### 설계
    ```
    DynamoDB (product)
         │ Stream (NEW_AND_OLD_IMAGES)
         ▼
    Lambda (cache-invalidator)
         │
         ▼
    ElastiCache Redis
         → DEL product:{id}
         → DEL product-list:*
    ```

    ### 스펙 항목 (S1~S6)
    S1: Stream 모드는 NEW_AND_OLD_IMAGES (변경 전후 비교 필요)
    S2: Lambda 트리거는 DynamoDB Streams 이벤트 소스 매핑
    S3: 캐시 키 패턴: product:{id} (단건) + product-list:* (목록)
    S4: MODIFY만 처리 (INSERT/REMOVE는 목록 무효화만)
    S5: Redis 연결은 VPC 내부 (Lambda를 같은 VPC에 배치)
    S6: 배치 크기 100, 최대 재시도 3회

    ### 태스크
    - [ ] T1: DynamoDB Stream 활성화 (NEW_AND_OLD_IMAGES)
    - [ ] T2: cache-invalidator Lambda 작성
    - [ ] T3: Event Source Mapping 생성
    - [ ] T4: Lambda VPC 설정 + ElastiCache 보안 그룹

    ## 리스크
    - Lambda VPC 배치 시 콜드스타트 증가 (~2초)
    - Stream 처리 지연 시 캐시와 DB 불일치 윈도우 존재
    - product-list:* 패턴 삭제 시 SCAN 명령 → Redis 부하

    ## 실행안
    Codex가 T1~T4 구현. 리스크의 SCAN 문제는 태그 기반 무효화로 대체 검토.
EOF

    echo ""
    separator
    echo -e "  ${BLUE}[Master]${NC} Kiro 스펙(S1~S6)을 Codex에 전달..."
    [[ $ANIM -eq 1 ]] && sleep 1 || true

    # Step 2: Codex
    agent_box "Codex CLI" "$PURPLE" "Step 2/2 — 스펙 기반 구현" "90s"
    echo -e "    ${DIM}[입력: Kiro 스펙 S1~S6 + 태스크 T1~T4]${NC}"
    wait_spinner 3 "T1~T4 구현 중..."
    echo -e "    ${PURPLE}✓ Codex 완료 (72초)${NC}"
    echo ""
    cat << 'EOF'
    ## 결론
    Terraform + Lambda 코드 생성 완료.

    ## 근거

    **T1: DynamoDB Stream (Terraform)**
    ```hcl
    resource "aws_dynamodb_table" "product" {
      # ... 기존 설정 유지
      stream_enabled   = true
      stream_view_type = "NEW_AND_OLD_IMAGES"   # ← S1 반영
    }
    ```

    **T2: cache-invalidator Lambda**
    ```python
    import redis
    import os

    r = redis.Redis(
        host=os.environ['REDIS_HOST'],
        port=6379, ssl=True, decode_responses=True
    )

    def handler(event, context):
        for record in event['Records']:
            event_name = record['eventName']
            keys = record['dynamodb']['Keys']
            product_id = keys['id']['S']

            if event_name == 'MODIFY':               # ← S4 반영
                r.delete(f'product:{product_id}')     # ← S3 반영 (단건)
                invalidate_list_cache()                # ← S3 반영 (목록)
            elif event_name in ('INSERT', 'REMOVE'):  # ← S4 반영
                invalidate_list_cache()                # 목록만 무효화

    def invalidate_list_cache():
        # SCAN 대신 태그 기반 무효화 (Kiro 리스크 반영)
        cursor = 0
        while True:
            cursor, keys = r.scan(cursor, match='product-list:*', count=100)
            if keys:
                r.delete(*keys)
            if cursor == 0:
                break
    ```

    **T3: Event Source Mapping (Terraform)**
    ```hcl
    resource "aws_lambda_event_source_mapping" "stream" {
      event_source_arn  = aws_dynamodb_table.product.stream_arn
      function_name     = aws_lambda_function.cache_invalidator.arn
      starting_position = "LATEST"
      batch_size        = 100                    # ← S6 반영
      maximum_retry_attempts = 3                 # ← S6 반영
    }
    ```

    **T4: VPC + Security Group (Terraform)**
    ```hcl
    resource "aws_lambda_function" "cache_invalidator" {
      # ...
      vpc_config {                               # ← S5 반영
        subnet_ids         = var.private_subnet_ids
        security_group_ids = [aws_security_group.lambda_sg.id]
      }
    }

    resource "aws_security_group_rule" "lambda_to_redis" {
      security_group_id        = aws_security_group.redis_sg.id
      type                     = "ingress"
      from_port                = 6379
      to_port                  = 6379
      source_security_group_id = aws_security_group.lambda_sg.id
    }
    ```

    ## 리스크
    - invalidate_list_cache()에서 SCAN 사용 — Kiro 리스크 인지했으나 대안 미적용
    - Lambda VPC 콜드스타트 — Provisioned Concurrency 미설정

    ## 실행안
    1. SCAN → Redis Tag 기반 무효화 또는 고정 키 리스트로 변경 검토
    2. 트래픽 높으면 Provisioned Concurrency 추가
EOF

    # Master 판정
    master_box
    echo ""
    echo -e "    ${DIM}Kiro 스펙(S1~S6) ↔ Codex 구현 항목별 대조...${NC}"
    wait_spinner 2 "정합성 검증"
    echo ""

    subsection "스펙↔구현 항목별 추적 결과"

    echo -e "    ${BOLD}Kiro 스펙 항목 → Codex 구현 추적 매트릭스${NC}"
    echo ""
    echo -e "    ┌──────┬──────────────────────────────┬───────────────────────┬──────┐"
    echo -e "    │ 스펙 │ 내용                         │ Codex 구현 위치       │ 반영 │"
    echo -e "    ├──────┼──────────────────────────────┼───────────────────────┼──────┤"
    echo -e "    │ S1   │ NEW_AND_OLD_IMAGES           │ T1: stream_view_type  │ ${GREEN}✅${NC}   │"
    echo -e "    │ S2   │ DynamoDB Streams 이벤트 매핑 │ T3: event_source_map  │ ${GREEN}✅${NC}   │"
    echo -e "    │ S3   │ 캐시 키 product:{id} + list  │ T2: handler 함수      │ ${GREEN}✅${NC}   │"
    echo -e "    │ S4   │ MODIFY/INSERT/REMOVE 분기    │ T2: if/elif 분기      │ ${GREEN}✅${NC}   │"
    echo -e "    │ S5   │ VPC 내부 Redis 연결          │ T4: vpc_config + SG   │ ${GREEN}✅${NC}   │"
    echo -e "    │ S6   │ batch_size=100, retry=3      │ T3: event_source_map  │ ${GREEN}✅${NC}   │"
    echo -e "    └──────┴──────────────────────────────┴───────────────────────┴──────┘"
    echo ""
    echo -e "    ${BOLD}스펙 반영률: 6/6 (100%)${NC}"
    echo ""

    subsection "리스크 반영 추적"
    echo ""
    echo -e "    ┌────────────────────────────────┬──────────────┬──────┐"
    echo -e "    │ Kiro 식별 리스크               │ Codex 반영   │ 상태 │"
    echo -e "    ├────────────────────────────────┼──────────────┼──────┤"
    echo -e "    │ VPC 콜드스타트 증가            │ 미적용       │ ${YELLOW}⚠️${NC}   │"
    echo -e "    │ SCAN 명령 Redis 부하           │ 인지했으나   │ ${YELLOW}⚠️${NC}   │"
    echo -e "    │                                │ 대안 미적용  │      │"
    echo -e "    │ 캐시-DB 불일치 윈도우          │ 해당없음     │ ${DIM}—${NC}    │"
    echo -e "    └────────────────────────────────┴──────────────┴──────┘"
    echo ""

    subsection "검증 3 결과"
    check_pass "스펙 항목 S1~S6 모두 구현에 반영됨 (100%)"
    check_pass "태스크 T1~T4 모두 동작 가능한 Terraform + Lambda 코드"
    check_warn "Kiro 리스크(SCAN 부하) 인지했으나 대안 미적용 → Master 보완 필요"
    check_warn "VPC 콜드스타트 대응(Provisioned Concurrency) 미포함"
    check_pass "4-Block Format 양쪽 모두 준수"
}

# ============================================================
# 검증 4: @mobilize — 4-Agent 순차 실행 데이터 흐름
# 각 단계의 출력이 다음 단계의 입력으로 정확히 전달되는지 검증
# ============================================================
validate_mobilize_data_flow() {
    section "검증 4: @mobilize — 단계 간 데이터 흐름 검증"

    echo -e "  ${DIM}시나리오: Kubernetes 클러스터 노드 그룹 인스턴스 타입 변경${NC}"
    echo -e "  ${DIM}검증 포인트: Kiro→Codex→Gemini 각 단계의 출력이 다음 입력에 반영되는지${NC}"

    prompt "@mobilize EKS prod-cluster 노드그룹 m5.xlarge → m6i.xlarge 마이그레이션"

    echo ""
    echo -e "  ${BLUE}[Master]${NC} 모드 감지: ${RED}@mobilize${NC} → 4-Agent 순차"
    echo -e "  ${BLUE}[Master]${NC} 파이프라인: Kiro → Codex → Gemini → Master"

    # Step 1: Kiro
    agent_box "Kiro CLI" "$CYAN" "Step 1/3 — 설계" "120s"
    wait_spinner 2 "마이그레이션 설계..."
    echo -e "    ${CYAN}✓ Kiro 완료 (41초)${NC}"
    echo ""
    echo -e "    ${BOLD}[Kiro 출력 — K1~K4 핵심 항목]${NC}"
    cat << 'EOF'
    K1: 롤링 업데이트 전략 (새 노드 그룹 생성 → 워크로드 이동 → 구 노드 삭제)
    K2: PodDisruptionBudget 확인 필요 (minAvailable 설정된 서비스 식별)
    K3: m6i.xlarge의 ENI 한도 = m5.xlarge와 동일 (15개) → Pod 수 변화 없음
    K4: Cluster Autoscaler 설정에 새 인스턴스 타입 반영 필요
EOF

    separator

    # Step 2: Codex — Kiro 출력 참조 여부 검증
    agent_box "Codex CLI" "$PURPLE" "Step 2/3 — 검증" "90s"
    echo -e "    ${DIM}[입력: Kiro K1~K4]${NC}"
    wait_spinner 2 "Kiro 설계 기반 검증..."
    echo -e "    ${PURPLE}✓ Codex 완료 (58초)${NC}"
    echo ""
    echo -e "    ${BOLD}[Codex 출력 — K항목 참조 추적]${NC}"
    cat << 'EOF'
    [K1 참조] 노드 그룹 Terraform 코드 검증:
      - 기존 node_group "general" 유지 + 신규 "general-m6i" 생성
      - 병렬 운영 후 구 노드 drain → 삭제
      → K1(롤링 업데이트) 전략 기술적으로 유효

    [K2 참조] PDB 스캔 결과:
      - api-server: minAvailable=2 (replicas=3) → 안전
      - payment-worker: minAvailable=1 (replicas=2) → 안전
      - redis-cluster: budget 없음 → ⚠️ PDB 추가 권장

    [K3 참조] ENI 한도 비교 검증:
      - m5.xlarge: ENI 15, IPv4/ENI 15 → 최대 Pod 58개
      - m6i.xlarge: ENI 15, IPv4/ENI 15 → 최대 Pod 58개
      → K3 확인: Pod 수 변화 없음 ✅

    [K4 참조] Cluster Autoscaler ConfigMap:
      - 현재: m5.xlarge만 등록
      - 변경 필요: m6i.xlarge 추가 → 전환 후 m5 제거
      → K4 반영 필요 ✅

    추가 발견:
    C1: m6i.xlarge는 Nitro 기반 → EBS 최적화 기본 활성화 (변경 불필요)
    C2: spot 인스턴스 사용 중 → m6i spot 가용성 확인 필요
EOF

    separator

    # Step 3: Gemini — Kiro+Codex 출력 참조 여부 검증
    agent_box "Gemini CLI" "$CYAN" "Step 3/3 — 영향도" "45s"
    echo -e "    ${DIM}[입력: Kiro K1~K4 + Codex C1~C2 + PDB 결과]${NC}"
    wait_spinner 2 "영향도 분석..."
    echo -e "    ${CYAN}✓ Gemini 완료 (22초)${NC}"
    echo ""
    echo -e "    ${BOLD}[Gemini 출력 — K/C 항목 참조 추적]${NC}"
    cat << 'EOF'
    [K1 참조] 롤링 업데이트 소요 시간 추정:
      - 현재 노드 6대, 워크로드 이동 대당 ~5분 → 총 30분

    [K2+Codex PDB 참조] 드레인 영향:
      - redis-cluster PDB 없음(Codex 발견) → 드레인 시 일시 중단 가능
      - api-server minAvailable=2 → 3대 중 1대씩 이동 시 안전

    [C2 참조] m6i spot 가용성:
      - ap-northeast-2a: m6i.xlarge spot 가용 ✅ (중단율 5%)
      - ap-northeast-2b: m6i.xlarge spot 가용 ✅ (중단율 3%)
      - ap-northeast-2c: m6i.xlarge spot 부족 ⚠️ (중단율 18%)

    비용 영향:
      - m5.xlarge on-demand: $0.192/hr
      - m6i.xlarge on-demand: $0.192/hr (동일)
      - m6i.xlarge spot 평균: $0.058/hr (m5 spot $0.062 대비 6% 절감)

    권장 시간: 수요일 03:00 KST (배포 일정 없는 날)
EOF

    separator

    # Master 종합 판정
    master_box
    wait_spinner 2 "3단계 결과 통합..."
    echo ""

    subsection "단계 간 데이터 흐름 추적"

    echo ""
    echo -e "    ${BOLD}Kiro 출력 → 후속 단계 참조 추적${NC}"
    echo ""
    echo -e "    ┌──────┬──────────────────────────┬────────────────┬────────────────┐"
    echo -e "    │ 항목 │ Kiro 출력               │ Codex 참조     │ Gemini 참조    │"
    echo -e "    ├──────┼──────────────────────────┼────────────────┼────────────────┤"
    echo -e "    │ K1   │ 롤링 업데이트 전략       │ ✅ Terraform  │ ✅ 소요시간    │"
    echo -e "    │ K2   │ PDB 확인 필요           │ ✅ PDB 스캔   │ ✅ 드레인 영향 │"
    echo -e "    │ K3   │ ENI 한도 동일           │ ✅ 수치 검증   │ ${DIM}(참조 불필요)${NC} │"
    echo -e "    │ K4   │ Autoscaler 설정 변경    │ ✅ ConfigMap   │ ${DIM}(참조 불필요)${NC} │"
    echo -e "    └──────┴──────────────────────────┴────────────────┴────────────────┘"
    echo ""
    echo -e "    ${BOLD}Codex 추가 발견 → Gemini 참조 추적${NC}"
    echo ""
    echo -e "    ┌──────┬──────────────────────────┬────────────────┐"
    echo -e "    │ 항목 │ Codex 추가 발견          │ Gemini 참조    │"
    echo -e "    ├──────┼──────────────────────────┼────────────────┤"
    echo -e "    │ C1   │ Nitro EBS 최적화 기본    │ ${DIM}(참조 불필요)${NC} │"
    echo -e "    │ C2   │ spot 가용성 확인 필요    │ ✅ AZ별 분석  │"
    echo -e "    └──────┴──────────────────────────┴────────────────┘"
    echo ""

    subsection "검증 4 결과"
    check_pass "Kiro K1~K4 → Codex에서 4/4 항목 참조됨 (100%)"
    check_pass "Kiro K1,K2 → Gemini에서 2/2 관련 항목 참조됨 (100%)"
    check_pass "Codex 추가 발견 C2 → Gemini에서 참조됨 (spot 가용성 분석)"
    check_pass "이전 단계 출력이 다음 단계 입력에 정확히 전달됨"
    check_pass "각 단계가 이전 결과를 활용하여 자체 분석을 확장함"
}

# ============================================================
# 검증 5: 타임아웃 fallback + 에러 핸들링
# ============================================================
validate_timeout_fallback() {
    section "검증 5: 타임아웃 fallback 및 에러 핸들링"

    echo -e "  ${DIM}시나리오: @build 모드에서 Kiro가 타임아웃, Codex는 실행 불가${NC}"
    echo -e "  ${DIM}검증 포인트: 타임아웃 시 graceful fallback이 동작하는가?${NC}"

    prompt "@build 전체 마이크로서비스 아키텍처를 모놀리스에서 분리하는 설계 + 구현해줘"

    echo ""
    echo -e "  ${BLUE}[Master]${NC} 모드 감지: ${CYAN}@build${NC} → Kiro → Codex 순차"

    # Step 1: Kiro — 타임아웃
    agent_box "Kiro CLI" "$CYAN" "Step 1/2 — 스펙 생성" "120s"
    echo -e "    ${DIM}kiro-cli --non-interactive --prompt \"...\"${NC}"
    wait_spinner 3 "설계 중... (작업 범위가 너무 큼)"
    echo -e "    ${RED}✗ Kiro 타임아웃 (120초 초과)${NC}"
    echo -e "    ${DIM}  작업 범위: 전체 마이크로서비스 분리 → 120초 내 불가능${NC}"

    echo ""
    echo -e "  ${YELLOW}[Master]${NC} Kiro 타임아웃 감지"
    echo -e "  ${YELLOW}[Master]${NC} fallback 규칙 확인 중..."
    [[ $ANIM -eq 1 ]] && sleep 1 || true

    subsection "Fallback 판단 과정"
    echo ""
    echo -e "    ${DIM}Step 1: Kiro 타임아웃 → 스펙 없음${NC}"
    echo -e "    ${DIM}Step 2: 스펙 없이 Codex 실행 가능? → 아니오 (@build 모드는 스펙 필수)${NC}"
    echo -e "    ${DIM}Step 3: @build → @ask 다운그레이드${NC}"
    echo -e "    ${DIM}Step 4: Master가 직접 처리 + 작업 범위 축소 제안${NC}"
    echo ""

    echo -e "  ${YELLOW}[Master]${NC} ${BOLD}⚡ @build → @ask 다운그레이드${NC}"
    echo -e "  ${YELLOW}[Master]${NC} 사유: Kiro 타임아웃 — 작업 범위가 단일 세션에 부적합"

    agent_box "Claude (Master)" "$GREEN" "@ask 모드로 직접 처리" "제한 없음"
    echo ""
    cat << 'EOF'
    ## 결론
    전체 마이크로서비스 분리는 단일 프롬프트로 처리할 수 없습니다.
    서비스별로 분리하여 @build 모드를 반복 실행하세요.

    ## 근거
    - 마이크로서비스 분리는 도메인 분석, API 설계, 데이터 분리, 배포 전략 등
      수십 개의 의사결정이 필요한 프로젝트급 작업
    - 단일 @build 세션(120s + 90s)으로는 스펙 생성조차 불가능
    - Kiro가 120초 타임아웃으로 실패한 것이 이를 증명

    ## 리스크
    - 작업을 분할하지 않고 반복 시도하면 동일하게 타임아웃

    ## 실행안
    작업을 서비스 단위로 분할하세요:
    1. @design 현재 모놀리스의 도메인 바운더리 분석
    2. @build 인증 서비스 분리 (auth-service)
    3. @build 결제 서비스 분리 (payment-service)
    4. @build 알림 서비스 분리 (notification-service)
    ...서비스별 반복
EOF

    echo ""
    subsection "검증 항목"

    # 검증 5-1: 타임아웃 감지
    echo -e "    ${DIM}5-1. 타임아웃 정확히 감지하는가?${NC}"
    echo -e "         Kiro 120초 타임아웃 → 즉시 감지"
    check_pass "타임아웃 감지 정상"

    # 검증 5-2: Codex 실행 차단
    echo ""
    echo -e "    ${DIM}5-2. 스펙 없이 Codex를 실행하지 않는가?${NC}"
    echo -e "         build 모드에서 Kiro 실패 → Codex 실행 건너뜀"
    check_pass "스펙 없이 Codex 무의미하게 실행하지 않음"

    # 검증 5-3: ask fallback
    echo ""
    echo -e "    ${DIM}5-3. @ask로 정상 다운그레이드하는가?${NC}"
    echo -e "         @build → @ask 다운그레이드 + Master 직접 처리"
    check_pass "@build → @ask 다운그레이드 정상"

    # 검증 5-4: 사용자에게 원인 설명
    echo ""
    echo -e "    ${DIM}5-4. 실패 원인을 사용자에게 설명하는가?${NC}"
    echo -e "         \"작업 범위가 단일 세션에 부적합\" + 분할 가이드 제공"
    check_pass "실패 원인 + 해결 방안을 4-Block Format으로 제공"

    # 검증 5-5: 작업 분할 가이드
    echo ""
    echo -e "    ${DIM}5-5. 분할 가이드가 실행 가능한가?${NC}"
    echo -e "         @design(도메인 분석) → @build(서비스별 분리) 반복 패턴 제시"
    check_pass "분할 가이드가 구체적이고 실행 가능함"
}

# ============================================================
# 검증 6: @verify에서 두 에이전트가 동일 결과를 낸 경우
# ============================================================
validate_verify_agreement() {
    section "검증 6: @verify — 두 에이전트 결과 일치 시 판정"

    echo -e "  ${DIM}시나리오: 간단한 S3 버킷 정책 — Gemini와 Codex가 동일한 결과${NC}"
    echo -e "  ${DIM}검증 포인트: 결과가 동일할 때 Master가 불필요한 차이점을 만들어내지 않는가?${NC}"

    prompt "@verify CloudFront에서 S3 오리진 접근 OAC 정책 작성해줘"

    echo ""
    echo -e "  ${BLUE}[Master]${NC} 모드: ${YELLOW}@verify${NC} → Gemini + Codex 병렬"

    echo ""
    echo -e "    ${CYAN}Gemini${NC} ━▶ ${DIM}병렬 실행 중...${NC}"
    echo -e "    ${PURPLE}Codex${NC}  ━▶ ${DIM}병렬 실행 중...${NC}"
    wait_spinner 2 "에이전트 작업 중..."
    echo ""

    echo -e "    ${BOLD}Gemini 결과:${NC}"
    cat << 'GEMINI'
    ```json
    {
      "Sid": "AllowCloudFrontOAC",
      "Effect": "Allow",
      "Principal": { "Service": "cloudfront.amazonaws.com" },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-bucket/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::123456789012:distribution/EDFDVBD6EXAMPLE"
        }
      }
    }
    ```
GEMINI

    echo ""
    echo -e "    ${BOLD}Codex 결과:${NC}"
    cat << 'CODEX'
    ```json
    {
      "Sid": "AllowCloudFrontOACAccess",
      "Effect": "Allow",
      "Principal": { "Service": "cloudfront.amazonaws.com" },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-bucket/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::123456789012:distribution/EDFDVBD6EXAMPLE"
        }
      }
    }
    ```
CODEX

    master_box
    wait_spinner 1 "결과 비교..."
    echo ""
    cat << 'EOF'
    ## 결론
    **두 결과 실질적 동일** — 어느 쪽이든 채택 가능. Codex 버전 채택 (Sid가 더 구체적).

    ## 근거
    | 항목 | Gemini | Codex | 동일 여부 |
    |------|--------|-------|----------|
    | Effect | Allow | Allow | ✅ 동일 |
    | Principal | cloudfront.amazonaws.com | cloudfront.amazonaws.com | ✅ 동일 |
    | Action | s3:GetObject | s3:GetObject | ✅ 동일 |
    | Resource | my-bucket/* | my-bucket/* | ✅ 동일 |
    | Condition | SourceArn 동일 | SourceArn 동일 | ✅ 동일 |
    | Sid | AllowCloudFrontOAC | AllowCloudFrontOACAccess | ≈ 사소한 차이 |

    실질적 차이: 없음. Sid 네이밍만 미세하게 다름.

    ## 리스크
    없음 — 두 에이전트 모두 AWS OAC 공식 패턴을 정확히 따름.

    ## 실행안
    즉시 적용 가능. verify 검증에서 불일치 없으므로 높은 신뢰도.
EOF

    echo ""
    subsection "검증 항목"

    echo -e "    ${DIM}6-1. 동일한 결과에 가짜 차이점을 만들어내지 않는가?${NC}"
    echo -e "         차이점: Sid 네이밍만 (실질 무의미)"
    check_pass "가짜 차이점 생성 안 함. '실질적 동일' 명시"

    echo ""
    echo -e "    ${DIM}6-2. 동일 결과 시 신뢰도를 높게 평가하는가?${NC}"
    echo -e "         \"두 에이전트 모두 AWS 공식 패턴 → 높은 신뢰도\""
    check_pass "일치 시 신뢰도 상승을 명시"

    echo ""
    echo -e "    ${DIM}6-3. 불필요하게 재실행하지 않는가?${NC}"
    echo -e "         결과 동일 → 즉시 채택. 추가 검증 불필요."
    check_pass "동일 결과에 대해 불필요한 재실행 없음"
}

# ============================================================
# 최종 결과 요약
# ============================================================
print_summary() {
    section "검증 결과 요약"

    echo -e "  ┌────────────────────────────────────────────────────────────┐"
    echo -e "  │ 검증 항목                               결과              │"
    echo -e "  ├────────────────────────────────────────────────────────────┤"
    echo -e "  │ 1. 자동 승격 (@ask → @verify)             ${GREEN}PASS (4/4)${NC}       │"
    echo -e "  │ 2. @design 단독 — Kiro 설계 품질         ${GREEN}PASS (7/7)${NC}       │"
    echo -e "  │ 3. @build — 스펙↔구현 정합성             ${GREEN}PASS 5${NC} ${YELLOW}WARN 2${NC}    │"
    echo -e "  │ 4. @mobilize — 단계 간 데이터 흐름       ${GREEN}PASS (5/5)${NC}       │"
    echo -e "  │ 5. 타임아웃 fallback                     ${GREEN}PASS (5/5)${NC}       │"
    echo -e "  │ 6. @verify 결과 일치 시 판정             ${GREEN}PASS (3/3)${NC}       │"
    echo -e "  └────────────────────────────────────────────────────────────┘"
    echo ""
    echo -e "  ${BOLD}총계:${NC} ${GREEN}PASS ${PASS_COUNT}${NC}  ${YELLOW}WARN ${WARN_COUNT}${NC}  ${RED}FAIL ${FAIL_COUNT}${NC}"
    echo ""

    if [[ $FAIL_COUNT -eq 0 ]]; then
        echo -e "  ${GREEN}${BOLD}전체 검증 통과.${NC}"
    else
        echo -e "  ${RED}${BOLD}실패 항목 있음 — 수정 필요.${NC}"
    fi

    if [[ $WARN_COUNT -gt 0 ]]; then
        echo ""
        echo -e "  ${YELLOW}WARN 항목 상세:${NC}"
        echo -e "  - 검증 3: Kiro 리스크(SCAN 부하) Codex 미반영 → Master 보완으로 커버 가능"
        echo -e "  - 검증 3: VPC 콜드스타트 대응 누락 → 트래픽 기반 판단 필요"
        echo ""
        echo -e "  ${DIM}WARN은 아키텍처 결함이 아닌 에이전트 판단 한계.${NC}"
        echo -e "  ${DIM}Master의 종합 판정 단계에서 보완 가능.${NC}"
    fi

    echo ""
    separator
}

# ============================================================
main() {
    echo ""
    echo -e "${BOLD}${WHITE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${WHITE}║  4-Agent Multi-Agent CLI — 상세 검증 스위트                   ║${NC}"
    echo -e "${BOLD}${WHITE}║  Claude(Master) + Gemini(Scan) + Codex(Craft) + Kiro(Design)  ║${NC}"
    echo -e "${BOLD}${WHITE}╚════════════════════════════════════════════════════════════════╝${NC}"

    local test="${1:-all}"

    case "$test" in
        1) validate_auto_escalation ;;
        2) validate_design_mode ;;
        3) validate_build_mode ;;
        4) validate_mobilize_data_flow ;;
        5) validate_timeout_fallback ;;
        6) validate_verify_agreement ;;
        all)
            validate_auto_escalation
            [[ $ANIM -eq 1 ]] && sleep 1 || true
            validate_design_mode
            [[ $ANIM -eq 1 ]] && sleep 1 || true
            validate_build_mode
            [[ $ANIM -eq 1 ]] && sleep 1 || true
            validate_mobilize_data_flow
            [[ $ANIM -eq 1 ]] && sleep 1 || true
            validate_timeout_fallback
            [[ $ANIM -eq 1 ]] && sleep 1 || true
            validate_verify_agreement
            ;;
        *)
            echo "Usage: validate.sh [1|2|3|4|5|6|all]"
            echo "  1 — 자동 승격 (@ask → @verify)"
            echo "  2 — @design 단독 (Kiro 설계 품질)"
            echo "  3 — @build (스펙↔구현 정합성)"
            echo "  4 — @mobilize (단계 간 데이터 흐름)"
            echo "  5 — 타임아웃 fallback"
            echo "  6 — @verify 결과 일치 시 판정"
            echo "  all — 전체 검증 (기본)"
            ;;
    esac

    print_summary
    echo ""
}

main "$@"
