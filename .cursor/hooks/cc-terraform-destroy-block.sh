#!/usr/bin/env bash
# Cursor beforeShellExecution → Claude pre-destroy-guard 와 동일 정책 (terraform destroy 직접 실행 차단)
set -euo pipefail
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.command // ""')
SYNTH=$(jq -n --arg c "$CMD" '{tool_input:{command:$c}}')
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
set +e
OUT=$(echo "$SYNTH" | bash "$ROOT/.claude/hooks/pre-destroy-guard.sh" 2>&1)
EC=$?
set -euo pipefail
if [ "$EC" -eq 2 ]; then
  REASON=$(echo "$OUT" | jq -r '.reason // "terraform destroy 직접 실행 금지"' 2>/dev/null || echo "$OUT")
  jq -n --arg u "$REASON" --arg a "$REASON" '{permission:"deny",user_message:$u,agent_message:$a}'
  exit 0
fi
echo '{"permission":"allow"}'
exit 0
