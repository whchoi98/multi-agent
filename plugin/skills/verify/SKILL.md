---
name: verify
description: "교차검증 — Gemini + Codex를 병렬 실행하여 결과를 비교 판정합니다. IAM, 보안, 코드 리뷰에 최적"
---

사용자가 교차 검증이 필요한 작업을 요청했습니다.

1. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/ai-delegate.sh" verify "<사용자 프롬프트>"` 실행
2. Gemini와 Codex 결과의 **차이점** 식별
3. 각 차이점에 대해 어느 쪽이 적절한지 근거와 함께 판단
4. 최종 채택 버전을 4-Block Format으로 출력
5. 심각한 불일치 발견 시 `@mobilize`로 승격 고려
