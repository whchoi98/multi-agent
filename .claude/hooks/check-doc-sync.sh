#!/bin/bash
# Detect documentation sync needs after file changes.
# Triggered by PostToolUse (Write|Edit) events.
# Adapted for multi-agent CLI project (scripts/, claude-policies/ instead of src/)

FILE_PATH="${1:-}"
[ -z "$FILE_PATH" ] && exit 0

# Detect missing CLAUDE.md in scripts/ subdirectories
if [[ "$FILE_PATH" == scripts/* ]]; then
    DIR=$(dirname "$FILE_PATH")
    if [ ! -f "$DIR/CLAUDE.md" ] && [ "$DIR" != "scripts" ]; then
        echo "[doc-sync] $DIR/CLAUDE.md is missing. Create module documentation."
    fi
fi

# Detect missing CLAUDE.md in claude-policies/ subdirectories
if [[ "$FILE_PATH" == claude-policies/* ]]; then
    DIR=$(dirname "$FILE_PATH")
    if [ ! -f "$DIR/CLAUDE.md" ] && [ "$DIR" != "claude-policies" ]; then
        echo "[doc-sync] Policy changed in $DIR. Verify all agent configs are in sync."
    fi
fi

# Alert if no ADRs exist when scripts or architecture files change
if [[ "$FILE_PATH" == scripts/* ]] || [[ "$FILE_PATH" == claude-policies/* ]] || [[ "$FILE_PATH" == docs/architecture.md ]]; then
    ADR_COUNT=$(find docs/decisions -name 'ADR-*.md' 2>/dev/null | wc -l)
    if [ "$ADR_COUNT" -eq 0 ]; then
        echo "[doc-sync] No ADRs found. Record architectural decisions in docs/decisions/."
    fi
fi
