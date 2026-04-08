#!/bin/bash
# terraform destroy 직접 실행 차단 → /tf-destroy 스킬 사용 강제

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")

# git, az 등 다른 명령이면 즉시 통과
if echo "$COMMAND" | grep -qE '^(git|az|infracost|checkov|tflint|rtk)\b'; then
  exit 0
fi

# terraform이 실제 실행 명령으로 등장할 때만 차단 (shell 연산자 이후 terraform destroy)
if echo "$COMMAND" | grep -qE '(^|&&|\|\||;)\s*(cd\s+\S+\s+&&\s+)?terraform\s+\S*destroy'; then
  echo '{"decision": "block", "reason": "terraform destroy 직접 실행 금지. /tf-destroy 스킬을 사용하세요."}'
  exit 2
fi

exit 0
