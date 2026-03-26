# Scripts Module

## Role
Multi-Agent 오케스트레이션 실행 스크립트. Master(Claude)가 Slave 에이전트를 위임할 때 사용.

## Key Files
- `ai-delegate.sh` — Slave 위임 스크립트 (7 모드: quick/precise/spec/cross/critical/plan/guide)
- `simulate.sh` — 시나리오 시뮬레이션 (dry run)
- `validate.sh` — 구조 검증 (PASS/WARN/FAIL)

## Rules
- 모든 스크립트는 `set -euo pipefail`로 시작
- Slave 실행 결과는 `.multi-agent-results/`에 임시 저장 (실행마다 초기화)
- 타임아웃은 가드레일: quick=45s, precise=90s, spec=120s
- 4-Block Format 프롬프트 접미사를 모든 Slave 호출에 자동 추가
