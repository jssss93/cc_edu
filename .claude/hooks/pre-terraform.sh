#!/bin/bash
# .claude/hooks/pre-terraform.sh
# terraform 실행 전 자동 검증

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")

# ── destroy 가드 (최우선 검사) ──
# terraform destroy 직접 실행 차단 → /tf-destroy 스킬 사용 강제
if echo "$COMMAND" | grep -qE 'terraform\b.*\bdestroy\b'; then
  echo '{"decision": "block", "reason": "terraform destroy 직접 실행 금지. /tf-destroy 스킬을 사용하세요."}'
  exit 2
fi

# terraform apply 가 아니면 검사 불필요
if ! echo "$COMMAND" | grep -qE 'terraform\b.*\bapply\b'; then
  exit 0
fi

set -e

echo "🔍 Terraform 사전 검증 시작..."

# tflint 실행
if command -v tflint &>/dev/null; then
  echo "▶ tflint 실행 중..."
  tflint --recursive
  echo "✅ tflint 통과"
else
  echo "⚠️  tflint 미설치 — 건너뜀"
fi

# checkov 보안 검사
if command -v checkov &>/dev/null; then
  echo "▶ checkov 보안 검사 중..."
  checkov -d . --quiet --compact
  echo "✅ checkov 통과"
else
  echo "⚠️  checkov 미설치 — 건너뜀"
fi

echo "✅ 사전 검증 완료"
exit 0
