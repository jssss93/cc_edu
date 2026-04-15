#!/usr/bin/env bash
# Cursor beforeShellExecution → Claude pre-push-tf-check (git push 전 fmt/validate/checkov)
set -euo pipefail
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.command // ""')
[[ "$CMD" != *"git push"* ]] && { echo '{"permission":"allow"}'; exit 0; }
SYNTH=$(jq -n --arg c "$CMD" '{tool_input:{command:$c}}')
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
set +e
OUT=$(echo "$SYNTH" | bash "$ROOT/.claude/hooks/pre-push-tf-check.sh" 2>&1)
EC=$?
set -euo pipefail
if [ "$EC" -eq 2 ]; then
  REASON=$(echo "$OUT" | jq -r '.reason // empty' 2>/dev/null || echo "$OUT")
  jq -n --arg u "$REASON" --arg a "$REASON" '{permission:"deny",user_message:$u,agent_message:$a}'
  exit 0
fi
echo '{"permission":"allow"}'
exit 0
