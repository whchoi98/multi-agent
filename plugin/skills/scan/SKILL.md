---
name: scan
description: "속도우선 — Gemini에게 대량 분석, 로그 요약, AWS 조회 등 빠른 작업을 위임합니다"
---

사용자가 속도 우선 작업을 요청했습니다.

1. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/ai-delegate.sh" scan "<사용자 프롬프트>"` 실행
2. Gemini 결과를 4-Block Format으로 검증
3. 보안 리스크 감지 시 `@verify`로 자동 승격
