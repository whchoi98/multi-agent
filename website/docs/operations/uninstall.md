---
sidebar_position: 3
title: 제거
description: Multi-Agent CLI를 깨끗하게 제거하는 방법
---

# 제거

## 대화형 제거 (권장)

프로젝트/사용자 레벨 설치를 모두 감지하여 제거합니다.

```bash
bash uninstall.sh
```

## 수동 제거

### Plugin 설치인 경우

```bash
# Claude Code Plugin 제거
claude plugins remove multi-agent
```

### 스크립트 설치인 경우

```bash
# 사용자 레벨
rm -rf ~/.claude/plugins/multi-agent

# 프로젝트 레벨
rm -rf .claude/plugins/multi-agent
```

### PATH 정리

`install.sh`로 설치한 경우 `~/.bashrc` 또는 `~/.zshrc`에 추가된 PATH를 제거합니다:

```bash
# .bashrc 또는 .zshrc에서 아래 라인 삭제
export PATH="$HOME/.local/bin/multi-agent:$PATH"
```

:::tip uninstall.sh가 자동으로 처리합니다
`bash uninstall.sh`를 실행하면 PATH 정리까지 포함하여 모든 흔적을 제거합니다.
:::
