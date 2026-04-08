#!/bin/bash
# git commit 전 코드 리뷰 강제 — 리뷰 완료 플래그 없으면 차단

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")

# git commit 명령이 아니면 통과
if ! echo "$COMMAND" | grep -qE '(^|&&|\|\||;)\s*git\s+commit\b'; then
  exit 0
fi

# staged 변경사항 없으면 통과
STAGED=$(git diff --staged --name-only 2>/dev/null)
if [ -z "$STAGED" ]; then
  exit 0
fi

# 리뷰 완료 플래그 확인
HASH=$(git diff --staged | md5 | awk '{print $1}')
FLAG="/tmp/cc_review_done_${HASH}"

if [ -f "$FLAG" ]; then
  rm "$FLAG"
  exit 0
fi

echo "{\"decision\":\"block\",\"reason\":\"커밋 전 코드 리뷰가 필요합니다.\\n\\nstaged 파일 목록:\\n${STAGED}\\n\\ngit diff --staged 를 확인하고 버그 및 규칙 위반 여부를 리뷰해주세요. 이상 없으면 'touch ${FLAG}' 실행 후 git commit을 재시도해주세요.\"}"
exit 2
