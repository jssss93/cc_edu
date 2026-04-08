#!/usr/bin/env bash
# .claude/hooks/post-terraform-plan.sh
# terraform plan 성공 후 — infracost 자동 비용 계산

set +e
trap 'exit 0' EXIT

INPUT=$(cat 2>/dev/null || true)

# plan 실패 시 종료
IS_ERROR=$(echo "$INPUT" | jq -r '.tool_response.isError // false' 2>/dev/null)
[ "$IS_ERROR" = "true" ] && exit 0

# infracost 미설치 시 종료
command -v infracost &>/dev/null || exit 0

# terraform plan -out= 명령인지 확인 (RTK 리라이트 포함)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)
echo "$COMMAND" | grep -qE '(terraform|rtk)\b.*plan\b.*-out=' || exit 0

# tfplan 파일명 추출
TFPLAN_NAME=$(echo "$COMMAND" | grep -oE '\-out=[^ ]+' | sed 's/-out=//' | head -1)
TFPLAN_NAME="${TFPLAN_NAME:-tfplan}"

# CWD 기준으로 tfplan 경로 결정
CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)
[ -z "$CWD" ] && CWD="$PWD"

TFPLAN_PATH="$CWD/$TFPLAN_NAME"
[ -f "$TFPLAN_PATH" ] || exit 0

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💰 Infracost 예상 월 비용"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
infracost breakdown --path "$TFPLAN_PATH" --format table 2>/dev/null || echo "⚠️ Infracost 분석 실패"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
