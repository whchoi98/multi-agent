---
name: mobilize
description: "총동원 — Kiro→Codex→Gemini 3단계 순차 실행 후 Go/No-Go 판정. 프로덕션 배포, 장애 대응, DB 마이그레이션에 사용"
---

사용자가 최고 위험 작업을 요청했습니다. 3-Agent 풀파이프라인을 실행합니다.

1. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/ai-delegate.sh" mobilize "<사용자 프롬프트>"` 실행
2. 3단계(Kiro→Codex→Gemini) 결과를 통합
3. 단계 간 모순이나 누락 식별
4. **Go/No-Go 판정** + 통합 체크리스트 생성
5. 4-Block Format으로 최종 리포트
