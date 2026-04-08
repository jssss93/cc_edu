#!/bin/bash
# .tf 파일 편집 후 terraform-reviewer 자동 트리거 안내

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null || echo "")
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")

# Edit/Write 도구가 아니면 종료
[[ "$TOOL" != "Edit" && "$TOOL" != "Write" ]] && exit 0

# .tf 파일이 아니면 종료
[[ "$FILE" != *.tf ]] && exit 0

# 에러 응답이면 종료
IS_ERROR=$(echo "$INPUT" | jq -r '.tool_response.isError // false' 2>/dev/null || echo "false")
[ "$IS_ERROR" = "true" ] && exit 0

echo "🔍 .tf 파일 변경 감지: $(basename "$FILE") — terraform-reviewer 코드 리뷰를 실행합니다"
exit 0
