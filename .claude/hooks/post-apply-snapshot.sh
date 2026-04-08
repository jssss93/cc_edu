#!/bin/bash
# terraform apply 성공 후 state 스냅샷 자동 저장

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")
IS_ERROR=$(echo "$INPUT" | jq -r '.tool_response.isError // false' 2>/dev/null || echo "false")

# terraform apply 명령이 아니면 종료
echo "$COMMAND" | grep -qE 'terraform\b.*\bapply\b' || exit 0

# apply 실패 시 종료
[ "$IS_ERROR" = "true" ] && exit 0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SNAPSHOT_DIR="$PROJECT_ROOT/.claude/snapshots"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# CWD 추출
CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)
[ -z "$CWD" ] && CWD="$PWD"

mkdir -p "$SNAPSHOT_DIR"
SAFE_TS="${TIMESTAMP//[ :]/-}"
terraform -chdir="$CWD" state list > "${SNAPSHOT_DIR}/state-${SAFE_TS}.txt" 2>/dev/null || true
terraform -chdir="$CWD" output -json > "$PROJECT_ROOT/.claude/last-output.json" 2>/dev/null || true

RESOURCE_COUNT=$(terraform -chdir="$CWD" state list 2>/dev/null | wc -l | tr -d ' ')
echo "📋 스냅샷 저장 완료 — 리소스 ${RESOURCE_COUNT}개 (${TIMESTAMP})"

exit 0
