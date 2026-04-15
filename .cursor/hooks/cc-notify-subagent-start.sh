#!/usr/bin/env bash
# Cursor subagentStart → Claude SubagentStart 알림과 유사
set -euo pipefail
INPUT=$(cat)
TYPE=$(echo "$INPUT" | jq -r '.subagent_type // "subagent"')
TASK=$(echo "$INPUT" | jq -r '.task // ""' | head -c 120)
SAFE=$(printf '%s' "[$TYPE] $TASK" | head -c 160 | tr '"' "'" | tr '\n' ' ')
osascript -e "display notification \"$SAFE\" with title \"Cursor: 서브에이전트\"" 2>/dev/null || true
echo '{"permission":"allow"}'
exit 0
