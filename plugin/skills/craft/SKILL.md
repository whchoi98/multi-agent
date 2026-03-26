---
name: craft
description: "정밀분석 — Codex에게 코드 변경, 테스트 작성, 설정 검증 등 정확도 우선 작업을 위임합니다"
---

사용자가 정밀도 우선 작업을 요청했습니다.

1. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/ai-delegate.sh" craft "<사용자 프롬프트>"` 실행
2. Codex 결과를 4-Block Format으로 검증
3. 결과에 보안 이슈 발견 시 `@verify`로 승격 고려
