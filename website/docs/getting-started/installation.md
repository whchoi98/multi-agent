---
sidebar_position: 2
title: 설치
description: Multi-Agent CLI 설치 방법 — Plugin, 대화형 스크립트, 수동 클론
---

# 설치

3가지 설치 방법을 제공합니다. 상황에 맞게 선택하세요.

---

## 방법 A: Claude Code Plugin (권장)

프로젝트 디렉토리를 오염시키지 않고, **어떤 프로젝트에서든 즉시 사용**할 수 있습니다.

```bash
# GitHub에서 설치
claude plugins add github:whchoi98/multi-agent/plugin

# 또는 로컬 경로로 설치
git clone https://github.com/whchoi98/multi-agent.git
claude plugins add ./multi-agent/plugin
```

설치 후 아무 프로젝트에서 바로 사용:

```bash
cd ~/any-project
claude
> 이 IAM 정책 검토해줘    # 자동으로 @verify 실행
```

:::tip Plugin의 장점
- 프로젝트별 설정 파일 불필요
- 자동 업데이트 지원
- `CLAUDE_PLUGIN_ROOT` 기반으로 경로 자동 해석
:::

---

## 방법 B: 대화형 설치 스크립트

**설치 범위**(프로젝트/사용자)와 **에이전트 구성**(2/3/4-Agent)을 대화형으로 선택합니다.

```bash
git clone https://github.com/whchoi98/multi-agent.git
cd multi-agent
bash install.sh
```

```
╔════════════════════════════════════════════════════╗
║       Multi-Agent CLI Installer v1.0.0            ║
╚════════════════════════════════════════════════════╝

  설치 범위를 선택하세요:
    1) 프로젝트 (.claude/)  — 현재 프로젝트에서만 사용
    2) 사용자   (~/.claude/) — 모든 프로젝트에서 사용

  에이전트 구성을 선택하세요:
    1) 2-Agent  Claude + Gemini               — ask, scan
    2) 3-Agent  Claude + Gemini + Codex       — + craft, verify
    3) 4-Agent  Claude + Gemini + Codex + Kiro — 전체 7모드
```

설치 후 CLI wrapper로 직접 실행:

```bash
multi-agent scan "CloudWatch 로그 분석"
multi-agent verify "IAM 정책 검토"
multi-agent --info    # 설치 정보 확인
```

---

## 방법 C: 수동 클론

가장 단순한 방법입니다. 클론 후 스크립트를 직접 실행합니다.

```bash
git clone https://github.com/whchoi98/multi-agent.git
cd multi-agent
bash scripts/ai-delegate.sh verify "IAM 정책 검토"
```

---

## 설치 확인

어떤 방법으로 설치했든, 아래 명령으로 구조를 검증할 수 있습니다:

```bash
bash scripts/validate.sh all
```

```
[PASS] 자동 승격 규칙 — ask → verify 정상 동작
[PASS] @design 단독 — Kiro 설계 품질 검증
[PASS] @build 스펙↔구현 — 정합성 검증
[PASS] @mobilize 단계 간 — 데이터 흐름 검증
[PASS] 타임아웃 fallback — 정상 동작
[PASS] @verify 결과 일치 — 판정 검증
```
