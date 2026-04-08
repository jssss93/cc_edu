#!/bin/bash
# 툴콜링 / MCP 호출 / 에이전트 호출 시 macOS 알림

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")

if [[ "$TOOL" == mcp__* ]]; then
  SERVICE=$(echo "$TOOL" | awk -F'__' '{print $2}')
  METHOD=$(echo "$TOOL" | awk -F'__' '{print $3}')
  TITLE="Claude Code: MCP 호출"
  MSG="[${SERVICE}] ${METHOD}"
elif [[ "$TOOL" == "Agent" ]]; then
  TITLE="Claude Code: 에이전트 호출"
  MSG="서브 에이전트 시작"
else
  TITLE="Claude Code: 툴 호출"
  MSG="$TOOL"
fi

osascript -e "display notification \"$MSG\" with title \"$TITLE\"" 2>/dev/null
exit 0
