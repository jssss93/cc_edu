#!/usr/bin/env bash
# Cursor postToolUse (Shell) → Claude post-apply-snapshot (memory/terraform_state.md)
set -euo pipefail
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // ""')
[[ "$TOOL" != "Shell" ]] && { echo '{}'; exit 0; }
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
if [ -z "$CWD" ]; then
  CWD=$(echo "$INPUT" | jq -r '.workspace_roots[0] // empty')
fi
# 성공한 postToolUse 만 호출되므로 isError 는 false
SYNTH=$(jq -n --arg cmd "$CMD" --arg cwd "$CWD" '{tool_input:{command:$cmd},cwd:$cwd,tool_response:{isError:false}}')
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
MSG=$(echo "$SYNTH" | bash "$ROOT/.claude/hooks/post-apply-snapshot.sh" 2>&1 | tr -d '\0' || true)
if [ -n "${MSG// }" ]; then
  MSG_ESC=$(printf '%s' "$MSG" | jq -Rs .)
  echo "{\"additional_context\":$MSG_ESC}"
else
  echo '{}'
fi
exit 0
