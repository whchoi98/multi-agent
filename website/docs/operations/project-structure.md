---
sidebar_position: 2
title: 프로젝트 구조
description: Multi-Agent CLI 프로젝트의 전체 디렉토리 구조와 각 파일의 역할
---

# 프로젝트 구조

```
multi-agent/
├── CLAUDE.md                          # Master(Claude) 설정 + 자동 감지 규칙
├── GEMINI.md                          # Gemini Speed Slave 설정
├── .codex/AGENTS.md                   # Codex Precision Slave 설정
├── .kiro/steering/steering.md         # Kiro Spec Slave 설정
│
├── claude-policies/                   # 정책 Hub (Single Source of Truth)
│   ├── common/
│   │   ├── 4-block-format.md          #   출력 형식 정의
│   │   ├── aws-conventions.md         #   AWS 네이밍/태깅 컨벤션
│   │   └── security-baseline.md       #   보안 기준선
│   └── multi-agent/
│       ├── modes.md                   #   7가지 모드 정의
│       └── escalation-rules.md        #   승격/다운그레이드 규칙
│
├── scripts/
│   ├── ai-delegate.sh                 # Slave 위임 오케스트레이터
│   ├── simulate.sh                    # 5개 시나리오 시뮬레이션
│   └── validate.sh                    # 6개 검증 시나리오 (PASS/WARN/FAIL)
│
├── plugin/                            # Claude Code Plugin (배포용)
│   ├── plugin.json                    #   플러그인 매니페스트
│   ├── agents/                        #   6개 에이전트 정의
│   ├── skills/                        #   6개 사용자 호출 스킬
│   ├── hooks/auto-detect.md           #   자동 모드 감지 훅
│   ├── policies/                      #   정책 (Hub 미러)
│   └── scripts/ai-delegate.sh         #   오케스트레이터 (CLAUDE_PLUGIN_ROOT)
│
├── install.sh                         # 대화형 설치 (범위/에이전트 수 선택)
├── uninstall.sh                       # 제거 + PATH 정리
│
├── docs/
│   ├── architecture.md                # 시스템 아키텍처 문서
│   ├── decisions/                     # ADR (Architecture Decision Records)
│   ├── runbooks/                      # 운영 런북
│   └── superpowers/specs/             # 유스케이스 카탈로그
│
├── website/                           # Docusaurus 문서 사이트
│   ├── docs/                          #   마크다운 문서 소스
│   ├── docusaurus.config.js           #   사이트 설정
│   └── sidebars.js                    #   사이드바 구조
│
├── .claude/
│   ├── settings.json                  # 훅 설정 (doc-sync 자동 감지)
│   ├── hooks/check-doc-sync.sh        # 문서 동기화 감지 훅
│   └── skills/                        # 커스텀 스킬
│
└── tools/
    ├── scripts/                       # 보조 스크립트
    └── prompts/                       # 프롬프트 템플릿
```

---

## 핵심 파일 역할

### 에이전트 설정

| 파일 | 에이전트 | 역할 |
|------|---------|------|
| `CLAUDE.md` | Claude (Master) | 자동 감지 규칙, 승격/다운그레이드, Judge 역할 |
| `GEMINI.md` | Gemini (Speed) | 속도 최적화, 45초 가드레일 |
| `.codex/AGENTS.md` | Codex (Precision) | 정밀도 우선, sandbox 제약 |
| `.kiro/steering/steering.md` | Kiro (Spec) | 설계 품질 기준, 스펙 템플릿 |

### 스크립트

| 파일 | 용도 |
|------|------|
| `scripts/ai-delegate.sh` | 7가지 모드의 Slave 위임 실행 |
| `scripts/simulate.sh` | 5개 시나리오 dry run |
| `scripts/validate.sh` | 6개 검증 시나리오 |
| `install.sh` | 대화형 설치 (scope + agent 선택) |
| `uninstall.sh` | 제거 + PATH 정리 |
