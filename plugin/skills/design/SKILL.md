---
name: design
description: "설계먼저 — Kiro에게 요구사항 분석, 아키텍처 설계, 태스크 분해, 런북 작성을 위임합니다"
---

사용자가 설계/스펙 작업을 요청했습니다.

1. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/ai-delegate.sh" design "<사용자 프롬프트>"` 실행
2. Kiro 결과를 4-Block Format으로 검증
3. 구현이 필요하면 `@build`로 연결 제안
