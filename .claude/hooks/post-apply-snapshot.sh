#!/bin/bash
# terraform apply/destroy 성공 후 ~/.claude/projects/…/memory/terraform_state.md 갱신 또는 정리

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
MEMORY_DIR="$(bash "$PROJECT_ROOT/.claude/scripts/memory-dir.sh" "$PROJECT_ROOT")"

# CWD 추출
CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)
[ -z "$CWD" ] && CWD="$PWD"

write_terraform_state_md() {
  local header_note="$1"
  mkdir -p "$MEMORY_DIR"
  local tmp
  tmp="$(mktemp)"
  terraform -chdir="$CWD" state list >"$tmp" 2>/dev/null || true
  local resource_count
  resource_count=$(wc -l <"$tmp" | tr -d ' ')
  {
    echo "# Terraform 배포 현황"
    echo
    echo "${header_note}"
    echo
    echo "| 항목 | 값 |"
    echo "|------|-----|"
    echo "| 기록 시각 | ${TIMESTAMP} |"
    echo "| terraform -chdir | \`${CWD}\` |"
    echo "| 리소스 수(비공란 줄) | ${resource_count} |"
    echo
    echo "## 리소스 목록 (\`terraform state list\`)"
    echo
    echo '```'
    cat "$tmp"
    echo '```'
  } >"${MEMORY_DIR}/terraform_state.md"
  rm -f "$tmp"
}

if [ "$IS_DESTROY" = "true" ]; then
  # destroy 성공 → memory 기록 + output 삭제
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
  write_terraform_state_md "**destroy 성공** 직후 스냅샷. state가 비었을 수 있다."
  rm -f "$PROJECT_ROOT/.claude/last-output.json"
  echo "🗑️ destroy 완료 — \`${MEMORY_DIR}/terraform_state.md\` 갱신"
else
  # apply 성공 → Claude 프로젝트 memory/terraform_state.md 갱신 (타임스탬프 파일 대신 단일 문서)
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
  write_terraform_state_md "이 내용은 **\`post-apply-snapshot.sh\`** 가 apply 성공 시 자동 기록한다."
  terraform -chdir="$CWD" output -json >"$PROJECT_ROOT/.claude/last-output.json" 2>/dev/null || true
  RESOURCE_COUNT=$(terraform -chdir="$CWD" state list 2>/dev/null | wc -l | tr -d ' ')
  echo "📋 \`${MEMORY_DIR}/terraform_state.md\` 갱신 완료 — 리소스 ${RESOURCE_COUNT}개 (${TIMESTAMP})"
  echo "💡 권장(수동): 예상 비용은 \`/tf-plan\` 단계의 infracost 결과를 참고. 다이어그램은 필요 시 \`/miro-update\` (또는 MIRO_AUTO_UPDATE=true 시 tf-apply 흐름)."
fi

exit 0
