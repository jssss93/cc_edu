#!/usr/bin/env bash
# .claude/hooks/pre-terraform-plan.sh
# terraform plan 전 — fmt 자동 검사 및 수정

set +e
trap 'exit 0' EXIT

INPUT=$(cat 2>/dev/null || true)

# terraform/rtk plan 명령인지 확인
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)
echo "$COMMAND" | grep -qE '(terraform|rtk)\b.*plan\b' || exit 0

# CWD 추출
CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)
[ -z "$CWD" ] && CWD="$PWD"

# terraform fmt 실행 (-check로 먼저 확인)
FMT_OUTPUT=$(terraform -chdir="$CWD" fmt -recursive -write=false -list=true 2>/dev/null)

if [ -n "$FMT_OUTPUT" ]; then
  echo ""
  echo "⚠️  포맷 문제 발견 — 자동 수정 중..."
  echo "$FMT_OUTPUT" | while read -r f; do echo "  - $f"; done
  terraform -chdir="$CWD" fmt -recursive 2>/dev/null
  echo "✅ terraform fmt 완료 — plan 계속 진행"
else
  echo "✅ terraform fmt 검사 통과"
fi
