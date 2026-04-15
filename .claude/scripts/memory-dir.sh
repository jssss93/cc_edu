#!/usr/bin/env bash
# ~/.claude/projects/<slug>/memory — Claude Code 프로젝트 메모리 디렉터리 (절대경로 출력)
# 인자: 레포 루트(선택). 없으면 CLAUDE_PROJECT_DIR, 그것도 없으면 pwd.
set -euo pipefail
ROOT="${1:-${CLAUDE_PROJECT_DIR:-}}"
if [ -z "$ROOT" ]; then
  ROOT="$(pwd)"
fi
ROOT="$(cd "$ROOT" && pwd)"
SLUG="-$(echo "${ROOT#/}" | tr '/' '-' | tr '_' '-')"
echo "${HOME}/.claude/projects/${SLUG}/memory"
