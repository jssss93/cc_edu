#!/usr/bin/env bash
# Cursor afterFileEdit → Claude post-tf-edit-review (.tf 변경 시 안내)
set -euo pipefail
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.file_path // ""')
[[ "$FILE" != *.tf ]] && { echo '{}'; exit 0; }
SYNTH=$(jq -n --arg t "Write" --arg f "$FILE" '{tool_name:$t,tool_input:{file_path:$f},tool_response:{isError:false}}')
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
HINT=$(echo "$SYNTH" | bash "$ROOT/.claude/hooks/post-tf-edit-review.sh" 2>&1 || true)
if [ -n "${HINT// }" ]; then
  printf '%s\n' "$HINT" >&2
fi
echo '{}'
exit 0
