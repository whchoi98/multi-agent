# Claude Policies Module (Hub)

## Role
모든 에이전트가 참조하는 공통 정책의 Single Source of Truth.
Hub & Spoke 구조에서 Hub 역할. 정책 변경 시 이곳만 수정.

## Key Files
- `common/4-block-format.md` — 4-Block 출력 형식 정의
- `common/aws-conventions.md` — AWS 네이밍/태깅 컨벤션
- `common/security-baseline.md` — 보안 기준선
- `multi-agent/modes.md` — 7가지 실행 모드 정의
- `multi-agent/escalation-rules.md` — 자동 승격/다운그레이드 규칙

## Rules
- 정책 파일은 Markdown 형식
- 에이전트별 설정 파일(CLAUDE.md, GEMINI.md 등)은 Hub 정책을 참조만 하고 복사하지 않음
- 정책 변경 시 모든 에이전트 설정 파일의 호환성 확인 필요
