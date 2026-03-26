# Multi-Agent CLI Plugin

4-Agent 오케스트레이션을 **어떤 프로젝트에서든** 사용할 수 있는 Claude Code 플러그인.

## 설치

```bash
# GitHub에서 직접 설치
claude plugins add github:whchoi98/multi-agent/plugin

# 또는 로컬 경로로 설치
claude plugins add /path/to/multi-agent/plugin
```

## 사용법

### 자동 감지 (기본)

프롬프트만 입력하면 Master가 최적 모드를 자동 선택합니다.

```
이 IAM 정책 검토해줘            → verify 자동 선택
CloudWatch 로그 빨리 분석해줘    → scan 자동 선택
프로덕션 DB 마이그레이션 계획    → mobilize 자동 선택
```

### 수동 오버라이드

`@모드`를 프롬프트 앞에 붙여 강제 지정합니다.

```
@scan 프로덕션 로그 확인
@verify IAM 정책 리뷰
@mobilize DB 스키마 변경
```

## 모드

| 모드 | 명칭 | 에이전트 | 용도 |
|------|------|---------|------|
| `@ask` | 단독처리 | Claude | 단순 작업 |
| `@scan` | 속도우선 | Gemini | 로그, 비용, 대량 분석 |
| `@craft` | 정밀분석 | Codex | 코드, 테스트, 설정 |
| `@design` | 설계먼저 | Kiro | 아키텍처, 요구사항 |
| `@verify` | 교차검증 | Gemini+Codex | 보안, IAM, 리뷰 |
| `@mobilize` | 총동원 | Kiro→Codex→Gemini | 프로덕션 장애/배포 |
| `@build` | 스펙→구현 | Kiro→Codex | 리팩토링, 신규 기능 |

## 사전 요구사항

| 도구 | 용도 |
|------|------|
| [Gemini CLI](https://github.com/google-gemini/gemini-cli) | Speed Slave |
| [Codex CLI](https://github.com/openai/codex) | Precision Slave |
| [Kiro CLI](https://kiro.dev) | Spec Slave |

## 구조

```
plugin/
├── plugin.json          # 플러그인 매니페스트
├── agents/              # 에이전트 정의
│   ├── scan.md          #   Gemini Speed
│   ├── craft.md         #   Codex Precision
│   ├── design.md        #   Kiro Spec
│   ├── verify.md        #   교차검증 오케스트레이터
│   ├── mobilize.md      #   총동원 오케스트레이터
│   └── build.md         #   스펙→구현 오케스트레이터
├── skills/              # 사용자 호출 가능 스킬
│   ├── scan/SKILL.md
│   ├── craft/SKILL.md
│   ├── design/SKILL.md
│   ├── verify/SKILL.md
│   ├── mobilize/SKILL.md
│   └── build/SKILL.md
├── hooks/               # 자동 감지 훅
│   └── auto-detect.md
├── policies/            # 정책 (4-Block, 보안, 승격 규칙)
└── scripts/
    └── ai-delegate.sh   # Slave 위임 오케스트레이터
```
