#!/usr/bin/env bash
# Cursor beforeMCPExecution — Terraform MCP apply/destroy 직접 호출 차단 (Claude permissions deny 미러)
set -euo pipefail
INPUT=$(cat)
NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
case "$NAME" in
  terraform_apply|terraform_destroy)
    MSG="Terraform MCP 로 ${NAME} 는 사용하지 않는다. Bash terraform apply tfplan 또는 /tf-destroy 스킬(plan -destroy + apply)을 사용하세요."
    jq -n --arg u "$MSG" --arg a "$MSG" '{permission:"deny",user_message:$u,agent_message:$a}'
    exit 0
    ;;
esac
echo '{"permission":"allow"}'
exit 0
