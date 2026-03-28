---
sidebar_position: 3
title: 개발자편 (UC11-15)
description: API 마이그레이션, 테스트 생성, 코드 리뷰, 마이크로서비스 설계, DB 마이그레이션
---

# 개발자편 (UC11-15)

## UC11. 레거시 API → REST 마이그레이션 — `@build`

### Pain Point

> *"5년 된 SOAP API가 아직 운영 중입니다. 클라이언트 3개 팀이 사용 중이고, 문서는 없고, 테스트는 없고, 원작자는 퇴사했습니다."*

### @build 파이프라인

**Step 1: Kiro** — Strangler Fig 패턴 기반 점진적 마이그레이션 설계

| Phase | 기간 | 내용 |
|-------|------|------|
| 1. 현행 분석 | 1주 | SOAP 엔드포인트 → REST 매핑표 작성 |
| 2. 프록시 레이어 | 2주 | API Gateway + Lambda 변환 프록시 (클라이언트 변경 없이) |
| 3. 클라이언트 마이그레이션 | 4주 | 모바일(2주), 웹(1주), 파트너(호환 프록시 유지) |
| 4. SOAP 폐기 | 2주 | 트래픽 0건 확인 → 서비스 종료 |

**Step 2: Codex** — 변환 프록시(Lambda) + REST API(FastAPI) 구현

**Master 판정**: 충족률 90%, 2건 보완 필요 (5개 중 3개 Operation만 구현, 인증 전환 미구현)

:::tip Insight
`@build` 모드에서 Master의 핵심 역할은 **갭 분석**입니다. Kiro가 5개 Operation을 설계했는데 Codex가 3개만 구현 — 이 차이를 Master가 잡아냅니다.
:::

---

## UC12. 유닛 테스트 일괄 생성 — `@craft`

### Pain Point

> *"코드 커버리지가 23%입니다. PM이 '80% 달성해주세요'라고 합니다. 서비스 레이어 함수 47개에 테스트가 없습니다."*

### Codex 분석 결과

| 서비스 | 함수 수 | 테스트 수 | 커버리지 변화 |
|--------|---------|----------|-------------|
| user_service.py | 12 | 38 | 18% → 82% |
| order_service.py | 15 | 52 | 12% → 85% |
| payment_service.py | 8 | 31 | 30% → 78% |
| notification_service.py | 7 | 22 | 0% → 88% |
| product_service.py | 5 | 13 | 45% → 91% |
| **합계** | **47** | **156** | **23% → 84%** |

### 테스트 품질의 차이

**단독 에이전트의 테스트:**
```python
def test_create_order():
    result = service.create_order(user_id="u-1", product_id="p-1", qty=2)
    assert result is not None  # 무의미한 assertion
```

**@craft (Codex)의 테스트:**
```python
async def test_create_order_payment_failure_rollback(self, service):
    """결제 실패 시 재고 복원 (보상 트랜잭션)"""
    service.inventory_client.check_stock.return_value = True
    service.payment_client.charge.side_effect = PaymentError("Declined")

    with pytest.raises(PaymentError):
        await service.create_order(user_id="u-1", product_id="p-1", qty=2)

    # 핵심: 결제 실패 시 재고가 복원되는가?
    service.inventory_client.restore_stock.assert_called_once_with("p-1", 2)
```

:::tip Insight
`@craft` 모드가 테스트 생성에 최적인 이유는 **비즈니스 로직을 이해**하기 때문입니다. "결제 실패 시 재고가 복원되는가?" 같은 테스트는 코드의 분기문과 예외 처리를 정밀 분석해야만 작성 가능합니다.
:::

---

## UC13. PR 코드 리뷰 자동화 — `@verify`

### Pain Point

> *"주니어 개발자가 올린 PR에 SQL injection 취약점이 있었는데, 바쁜 시니어가 'LGTM' 찍고 머지했습니다."*

### Gemini vs Codex 발견 비교

| # | 이슈 | Gemini | Codex | 심각도 |
|---|------|--------|-------|--------|
| 1 | SQL injection (raw query) | ✅ 감지 | ✅ **PoC 제공** | Critical |
| 2 | 인증 체크 누락 (admin endpoint) | ❌ 누락 | ✅ 감지 | Major |
| 3 | N+1 쿼리 (loop 내 DB 호출) | ✅ 감지 | ✅ **수정안 제공** | Major |
| 4 | 미사용 import | ✅ 감지 | ✅ 감지 | Minor |
| 5 | 변수명 컨벤션 위반 | ✅ 감지 | ❌ 누락 | Minor |
| 6 | docstring 누락 | ✅ 감지 | ❌ (설계 외) | Minor |

### 핵심: SQL Injection PoC (Codex)

```python
# PR #142, file: api/routes/search.py, line 45
# 위험한 코드:
results = db.execute(f"SELECT * FROM products WHERE name LIKE '%{query}%'")

# Codex PoC:
# GET /api/search?q='; DROP TABLE products; --
# → SQL: SELECT * FROM products WHERE name LIKE '%'; DROP TABLE products; --%'
```

:::tip Insight
코드 리뷰에서 `@verify`의 가치는 **상호 보완**입니다. Gemini는 넓게(6개 이슈), Codex는 깊게(PoC + 수정안). **"두 눈보다 네 눈"** — 이것이 교차검증의 본질입니다.
:::

---

## UC14. 신규 마이크로서비스 설계 — `@design`

### Pain Point

> *"'알림 서비스를 별도 마이크로서비스로 분리해주세요.' 설계 없이 시작하면 분산 모놀리스가 됩니다."*

### Kiro의 설계 결과

**의존성 분석:**
```
order   ──→ notification.send_order_confirmation()
payment ──→ notification.send_payment_receipt()
user    ──→ notification.send_welcome_email()
auth    ──→ notification.send_2fa_code()
```

**점진적 분리 로드맵:**

| Phase | 기간 | 작업 | 롤백 |
|-------|------|------|------|
| 1 | 1주 | 이벤트 발행 추가 (기존 동기 호출 유지) | ✅ |
| 2 | 2주 | 알림 서비스 배포 + 이벤트 수신 시작 | ✅ |
| 3 | 1주 | 동기 호출 제거, 이벤트만 사용 | ✅ |
| 4 | 1주 | 데이터 마이그레이션 + 모놀리스 코드 삭제 | ⚠ 주의 |

:::warning 중요한 설계 판단
2FA 코드는 **실시간 전달 필수** → EventBridge가 아닌 직접 API 호출 유지. 이런 판단은 설계 단계에서만 가능합니다.
:::

---

## UC15. 프로덕션 DB 마이그레이션 — `@mobilize`

### Pain Point

> *"users 테이블에 phone_number 컬럼을 추가해야 합니다. 레코드 5천만 건. 데이터는 되돌릴 수 없습니다."*

### 3-Agent 분담

| Step | Agent | 결과 |
|------|-------|------|
| 1 | **Kiro** | 3가지 전략 비교 → Aurora Online DDL(Instant) 선택 |
| 2 | **Codex** | Pre-check 스크립트 + 실행 + 롤백 + 검증 쿼리 |
| 3 | **Gemini** | 영향 분석: ORM/API/캐시 업데이트 필요 + 배포 순서 |

### 전략 비교 (Kiro)

| 전략 | 다운타임 | 소요 시간 | 리스크 |
|------|---------|----------|--------|
| A. 직접 ALTER TABLE | 10-30분 | 10분 | **서비스 중단** |
| B. pt-online-schema-change | 0 | 2-4시간 | 트리거 기반, 복잡 |
| C. **Aurora Online DDL** | **0** | **1초 미만** | Aurora 전용 |

### Master 판정

```
## 결론
Go — Aurora Instant DDL 실행 승인.
5천만 건이든 5억 건이든 동일 속도 (메타데이터만 변경).

## 실행 체크리스트
- [ ] Aurora 스냅샷 생성 완료
- [ ] staging 리허설 완료
- [ ] Pre-check 스크립트 실행 — 모두 Pass
- [ ] Instant DDL 실행 (예상 소요: 1초 미만)
- [ ] 검증 쿼리 실행
- [ ] 백엔드 PR 머지 + 배포
- [ ] Redis 캐시 무효화
- [ ] 1시간 모니터링
```

:::tip Insight
DB 마이그레이션에서 `@mobilize`가 필수인 이유: Kiro가 전략을 설계하고, Codex가 안전장치(Pre-check, 롤백)를 만들고, Gemini가 파급 효과를 분석합니다. **코드는 git revert로 1초 만에 되돌리지만, 데이터는 그렇지 않습니다.**
:::
