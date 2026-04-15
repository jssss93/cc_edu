#!/usr/bin/env bash
# Cursor preToolUse — MCP / Task 호출 시 알림 (Claude notify-on-tool 축소판)
set -euo pipefail
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
SAFE=$(printf '%s' "$TOOL" | head -c 160 | tr '"' "'" | tr '\n' ' ')
if [[ "$TOOL" == MCP:* ]] || [[ "$TOOL" == mcp* ]]; then
  TITLE="Cursor: MCP"
else
  TITLE="Cursor: 도구"
fi
osascript -e "display notification \"$SAFE\" with title \"$TITLE\"" 2>/dev/null || true
echo '{"permission":"allow"}'
exit 0
