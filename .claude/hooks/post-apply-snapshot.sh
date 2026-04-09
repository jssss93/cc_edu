#!/bin/bash
# terraform apply/destroy 성공 후 스냅샷 저장 또는 정리

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")
IS_ERROR=$(echo "$INPUT" | jq -r '.tool_response.isError // false' 2>/dev/null || echo "false")

IS_APPLY=$(echo "$COMMAND" | grep -qE 'terraform\b.*\bapply\b' && echo "true" || echo "false")
IS_DESTROY=$(echo "$COMMAND" | grep -qE 'terraform\b.*\bdestroy\b' && echo "true" || echo "false")

# apply 또는 destroy 명령이 아니면 종료
[ "$IS_APPLY" = "false" ] && [ "$IS_DESTROY" = "false" ] && exit 0

# 실패 시 종료
[ "$IS_ERROR" = "true" ] && exit 0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SNAPSHOT_DIR="$PROJECT_ROOT/.claude/snapshots"

# CWD 추출
CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)
[ -z "$CWD" ] && CWD="$PWD"

if [ "$IS_DESTROY" = "true" ]; then
  # destroy 성공 → 스냅샷 및 output 파일 삭제
  DELETED=0
  if [ -d "$SNAPSHOT_DIR" ]; then
    COUNT=$(ls "$SNAPSHOT_DIR"/state-*.txt 2>/dev/null | wc -l | tr -d ' ')
    rm -f "$SNAPSHOT_DIR"/state-*.txt
    DELETED=$COUNT
  fi
  rm -f "$PROJECT_ROOT/.claude/last-output.json"
  echo "🗑️ 스냅샷 정리 완료 — ${DELETED}개 파일 삭제 (destroy 성공)"
else
  # apply 성공 → 스냅샷 저장
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
  mkdir -p "$SNAPSHOT_DIR"
  SAFE_TS="${TIMESTAMP//[ :]/-}"
  terraform -chdir="$CWD" state list > "${SNAPSHOT_DIR}/state-${SAFE_TS}.txt" 2>/dev/null || true
  terraform -chdir="$CWD" output -json > "$PROJECT_ROOT/.claude/last-output.json" 2>/dev/null || true
  RESOURCE_COUNT=$(terraform -chdir="$CWD" state list 2>/dev/null | wc -l | tr -d ' ')
  echo "📋 스냅샷 저장 완료 — 리소스 ${RESOURCE_COUNT}개 (${TIMESTAMP})"
  echo "💡 권장(수동): 예상 비용은 \`/tf-plan\` 단계의 infracost 결과를 참고. 다이어그램은 필요 시 \`/miro-update\` (또는 MIRO_AUTO_UPDATE=true 시 tf-apply 흐름)."
fi

exit 0
