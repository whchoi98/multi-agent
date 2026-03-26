---
name: build
description: "스펙→구현 — Kiro가 스펙을 생성하고 Codex가 구현한 뒤 갭을 분석합니다. 리팩토링, 마이그레이션, 신규 기능에 사용"
---

사용자가 설계+구현 파이프라인을 요청했습니다.

1. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/ai-delegate.sh" build "<사용자 프롬프트>"` 실행
2. Kiro 스펙과 Codex 구현을 항목별 대조
3. 스펙 미충족 항목 식별 + 충족률 산출
4. 구현 품질 판정 + 보완 사항을 4-Block Format으로 출력
