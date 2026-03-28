---
sidebar_position: 1
title: 사전 요구사항
description: Multi-Agent CLI를 사용하기 위해 필요한 도구와 환경 설정
---

# 사전 요구사항

## 필수 도구

| 도구 | 용도 | 필요 구성 | 설치 |
|------|------|----------|------|
| [Claude Code](https://claude.ai/claude-code) | Master | 2/3/4-Agent 모두 | `npm install -g @anthropic-ai/claude-code` |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli) | Speed Slave | 2/3/4-Agent 모두 | `npm install -g @google/gemini-cli` |
| [Codex CLI](https://github.com/openai/codex) | Precision Slave | 3/4-Agent | `npm install -g @openai/codex` |
| [Kiro CLI](https://kiro.dev) | Spec Slave | 4-Agent만 | Kiro 공식 설치 가이드 |

:::info 모든 CLI를 설치할 필요 없습니다
보유한 도구에 맞게 2/3/4-Agent로 구성할 수 있습니다. 최소 구성은 Claude + Gemini (2-Agent)입니다.
:::

---

## 에이전트 구성 옵션

| 구성 | 에이전트 | 사용 가능 모드 | 적합한 상황 |
|------|---------|--------------|-----------|
| **2-Agent** | Claude + Gemini | `@ask`, `@scan` | 빠른 분석 위주, Codex/Kiro 미설치 환경 |
| **3-Agent** | Claude + Gemini + Codex | `@ask`, `@scan`, `@craft`, `@verify` | 코드 작업 + 교차검증 필요 |
| **4-Agent** | Claude + Gemini + Codex + Kiro | **전체 7모드** | 설계 + 구현 + 검증 풀 파이프라인 |

---

## 환경 확인

설치 후 아래 명령으로 각 CLI의 동작을 확인할 수 있습니다:

```bash
# Claude Code
claude --version

# Gemini CLI
gemini --version

# Codex CLI (설치한 경우)
codex --version

# Node.js (18.0 이상 필요)
node --version
```

---

## API 키 설정

각 CLI는 해당 서비스의 API 키가 필요합니다:

| CLI | 환경 변수 | 발급처 |
|-----|----------|--------|
| Claude Code | `ANTHROPIC_API_KEY` | [Anthropic Console](https://console.anthropic.com/) |
| Gemini CLI | `GEMINI_API_KEY` | [Google AI Studio](https://aistudio.google.com/) |
| Codex CLI | `OPENAI_API_KEY` | [OpenAI Platform](https://platform.openai.com/) |

```bash
# .bashrc 또는 .zshrc에 추가
export ANTHROPIC_API_KEY="sk-ant-..."
export GEMINI_API_KEY="AI..."
export OPENAI_API_KEY="sk-..."
```

:::caution API 키 보안
API 키를 Git에 커밋하지 마세요. `.env` 파일을 사용하는 경우 반드시 `.gitignore`에 추가하세요.
:::
