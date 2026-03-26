# 멀티에이전트 모드 정의

## 모드 매트릭스

| 모드 | 에이전트 | 실행 방식 | 타임아웃 | 용도 |
|------|---------|----------|---------|------|
| `#solo` | Claude | 단독 | - | 단순 작업 |
| `#quick` | Gemini | 단독 | 45s | 속도 우선 |
| `#precise` | Codex | 단독 | 90s | 정밀도 우선 |
| `#spec` | Kiro | 단독 | 120s | 설계/스펙 |
| `#cross` | Gemini + Codex | 병렬 | 45s + 90s | 교차 검증 |
| `#critical` | Kiro → Codex → Gemini | 순차 | 120s + 90s + 45s | 최고 위험 |
| `#plan` | Kiro → Codex | 순차 | 120s + 90s | 스펙 기반 구현 |

## 모드 선택 기준

```
위험도 낮음 + 단순     → #solo
위험도 낮음 + 대량     → #quick
위험도 중간 + 코드     → #precise
위험도 중간 + 신규     → #spec
위험도 높음 + 보안     → #cross
위험도 최고 + 프로덕션  → #critical
신규 기능 + 구현 필요   → #plan
```

## Kiro가 추가하는 가치

| 기존 (3-Agent) | 확장 (4-Agent with Kiro) |
|---------------|------------------------|
| #critical: Codex→Gemini→Claude | #critical: **Kiro**→Codex→Gemini→Claude |
| 설계 없이 바로 구현/검증 | 설계 먼저 → 스펙 기반 구현/검증 |
| 장애 대응 중심 | 장애 대응 + **사전 설계** |
| cross: 코드 교차 검증 | cross + **#plan: 스펙↔구현 적합성 검증** |
