#!/bin/bash
# git push 전 Terraform 검증 (fmt + validate + checkov)
# 실패 시 Claude에게 자동 수정 지시 (최대 2회)

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")

# git push 명령이 아니면 통과
[[ "$CMD" != *"git push"* ]] && exit 0

# 스크립트 위치 기준으로 프로젝트 루트 계산
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TF_DIR="$PROJECT_DIR/terraform"

# .tf 파일 없으면 통과
TF_FILES=$(find "$TF_DIR" -name "*.tf" -not -path "*/.terraform/*" 2>/dev/null | head -1)
[ -z "$TF_FILES" ] && exit 0

FAILED_ITEMS=()

# 1. terraform fmt 검사
if command -v terraform &>/dev/null; then
  FMT_OUTPUT=$(terraform fmt -check -recursive "$TF_DIR" 2>&1)
  if [ $? -ne 0 ]; then
    FAILED_ITEMS+=("❌ [fmt] 포맷 오류:\n${FMT_OUTPUT}")
  fi
else
  FAILED_ITEMS+=("⚠️ [fmt] terraform 미설치 — 검사 생략")
fi

# 2. 초기화된 환경만 validate
if command -v terraform &>/dev/null; then
  for ENV_DIR in "$TF_DIR"/environments/*/; do
    [ -d "${ENV_DIR}.terraform" ] || continue
    ENV_NAME=$(basename "$ENV_DIR")
    VALIDATE_OUTPUT=$(cd "$ENV_DIR" && terraform validate 2>&1)
    if [ $? -ne 0 ]; then
      FAILED_ITEMS+=("❌ [validate] ${ENV_NAME}:\n${VALIDATE_OUTPUT}")
    fi
  done
fi

# 3. checkov 검사
if command -v checkov &>/dev/null; then
  CHECKOV_OUTPUT=$(checkov -d "$TF_DIR" --framework terraform --quiet 2>&1)
  if [ $? -ne 0 ]; then
    FAILED_ITEMS+=("❌ [checkov] 보안 검사 실패:\n${CHECKOV_OUTPUT}")
  fi
fi

# ❌ 항목 없으면 통과
HAS_ERROR=false
for item in "${FAILED_ITEMS[@]}"; do
  [[ "$item" == ❌* ]] && HAS_ERROR=true && break
done

if [ "$HAS_ERROR" = false ]; then
  echo "✅ Terraform 검증 통과 — 푸시를 진행합니다"
  exit 0
fi

# 차단 메시지 구성
REASON="🚫 git push 차단 — Terraform 검증 실패\n\n"
for item in "${FAILED_ITEMS[@]}"; do
  REASON+="${item}\n\n"
done
REASON+="🔧 자동 수정 지시 (수정 후 반드시 기존 커밋에 포함시킬 것):\n"
REASON+="  - fmt 오류  : terraform fmt -recursive 실행\n"
REASON+="  - validate  : 오류 메시지를 분석하여 코드 수정\n"
REASON+="  - checkov   : FAILED 항목 코드 수정 또는 checkov:skip 주석 추가\n\n"
REASON+="수정 완료 후 다음 순서로 실행:\n"
REASON+="  1. git add <수정된 파일들>\n"
REASON+="  2. git commit --amend --no-edit\n"
REASON+="  3. git push 재시도\n\n"
REASON+="최대 2회까지 자동 수정을 시도하며, 2회 모두 실패 시 사용자에게 보고하고 중단합니다."

# JSON 이스케이프 후 차단
REASON_ESCAPED=$(echo -e "$REASON" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))")
echo "{\"decision\": \"block\", \"reason\": $REASON_ESCAPED}"
exit 2
