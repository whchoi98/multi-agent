# 멀티에이전트 모드 정의

> **모드 선택 방식 (Hybrid)**
> 기본: 자동 감지 / 수동 오버라이드: @모드 접두어

## 모드 매트릭스

| 모드 | 에이전트 | 실행 방식 | 타임아웃 | 용도 |
|------|---------|----------|---------|------|
| `@ask` | Claude | 단독 | - | 단순 작업 |
| `@scan` | Gemini | 단독 | 45s | 속도 우선 |
| `@craft` | Codex | 단독 | 90s | 정밀도 우선 |
| `@design` | Kiro | 단독 | 120s | 설계/스펙 |
| `@verify` | Gemini + Codex | 병렬 | 45s + 90s | 교차 검증 |
| `@mobilize` | Kiro → Codex → Gemini | 순차 | 120s + 90s + 45s | 최고 위험 |
| `@build` | Kiro → Codex | 순차 | 120s + 90s | 스펙 기반 구현 |

## 모드 선택 기준

```
위험도 낮음 + 단순     → @ask
위험도 낮음 + 대량     → @scan
위험도 중간 + 코드     → @craft
위험도 중간 + 신규     → @design
위험도 높음 + 보안     → @verify
위험도 최고 + 프로덕션  → @mobilize
신규 기능 + 구현 필요   → @build
```

## Kiro가 추가하는 가치

| 기존 (3-Agent) | 확장 (4-Agent with Kiro) |
|---------------|------------------------|
| @mobilize: Codex→Gemini→Claude | @mobilize: **Kiro**→Codex→Gemini→Claude |
| 설계 없이 바로 구현/검증 | 설계 먼저 → 스펙 기반 구현/검증 |
| 장애 대응 중심 | 장애 대응 + **사전 설계** |
| verify: 코드 교차 검증 | verify + **@build: 스펙↔구현 적합성 검증** |
