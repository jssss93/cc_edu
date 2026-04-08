#!/bin/bash
# .claude/hooks/post-deploy-full.sh
# terraform apply 성공 후 — 스냅샷 + Miro 알림

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")

# terraform apply 포함 여부 확인
if ! echo "$COMMAND" | grep -qE 'terraform\b.*\bapply\b'; then
  exit 0
fi

# apply 실패 시 중단 (isError 필드 사용)
IS_ERROR=$(echo "$INPUT" | jq -r '.tool_response.isError // false' 2>/dev/null || echo "false")
if [ "$IS_ERROR" = "true" ]; then
  echo "⚠️ terraform apply 실패 — post-hook 건너뜀"
  exit 0
fi

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# 스크립트 위치 기준으로 PROJECT_ROOT 자동 계산
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# WORK_DIR 탐지 우선순위:
# 1. 명령어에 cd 경로 포함 (cd .../environments/dev && terraform apply)
# 2. 명령어에 /environments/ 패턴 직접 포함
# 3. PWD가 environments 하위 디렉토리인 경우
# 4. tfstate 파일이 존재하는 환경 디렉토리 자동 탐색
# 5. fallback: dev 환경

CD_DIR=$(echo "$COMMAND" | grep -oE 'cd [^ ;&]+' | sed 's/cd //' | head -1)
TF_DIR=$(echo "$COMMAND" | grep -oE '[^ ]+/environments/[a-z]+' | head -1)
PWD_ENV=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null | grep -oE 'environments/[a-z]+' | head -1)

if [ -n "$CD_DIR" ] && [ -d "$CD_DIR" ]; then
  WORK_DIR="$CD_DIR"
elif [ -n "$TF_DIR" ] && [ -d "$TF_DIR" ]; then
  WORK_DIR="$TF_DIR"
elif [ -n "$PWD_ENV" ]; then
  WORK_DIR="$PROJECT_ROOT/terraform/$PWD_ENV"
else
  # tfstate가 있는 환경 디렉토리 자동 탐색
  FOUND=$(find "$PROJECT_ROOT/terraform/environments" -name "terraform.tfstate" -not -empty 2>/dev/null | head -1)
  WORK_DIR=${FOUND:+$(dirname "$FOUND")}
  WORK_DIR=${WORK_DIR:-"$PROJECT_ROOT/terraform/environments/dev"}
fi

ENV=$(basename "$WORK_DIR")

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║     🚀 배포 완료 — 자동 후처리 시작      ║"
echo "╚══════════════════════════════════════════╝"
echo "  환경: ${ENV}  |  시각: ${TIMESTAMP}"
echo ""

# ── Step 1: 리소스 현황 스냅샷 ──
echo "📋 [1/3] 리소스 현황 저장 중..."
SNAPSHOT_DIR="$PROJECT_ROOT/.claude/snapshots"
mkdir -p "$SNAPSHOT_DIR"
SAFE_TS="${TIMESTAMP//[ :]/-}"
terraform -chdir="$WORK_DIR" state list > "${SNAPSHOT_DIR}/state-${SAFE_TS}.txt" 2>/dev/null || true
terraform -chdir="$WORK_DIR" output -json > "$PROJECT_ROOT/.claude/last-output.json" 2>/dev/null || true
RESOURCE_COUNT=$(terraform -chdir="$WORK_DIR" state list 2>/dev/null | wc -l | tr -d ' ')
echo "  ✅ 총 ${RESOURCE_COUNT}개 리소스 확인"

# ── Step 2: Infracost 비용 예측 ──
echo ""
echo "💰 [2/3] 배포된 리소스 비용 예측 중..."
if command -v infracost &>/dev/null; then
  TFPLAN="$WORK_DIR/tfplan"
  if [ -f "$TFPLAN" ]; then
    infracost breakdown --path "$TFPLAN" --format table 2>/dev/null || \
    infracost breakdown --path "$WORK_DIR" --format table 2>/dev/null || \
    echo "  ⚠️ Infracost 분석 실패"
  else
    infracost breakdown --path "$WORK_DIR" --format table 2>/dev/null || \
    echo "  ⚠️ Infracost 분석 실패 (tfplan 파일 없음)"
  fi
else
  echo "  ⚠️ infracost 미설치 — 건너뜀 (brew install infracost)"
fi

# ── Step 3: Miro 업데이트 알림 ──
echo ""
echo "🎨 [3/3] 아키텍처 다이어그램..."
echo "  → Miro 업데이트: /miro-update ${ENV} 실행 권장"

# ── 완료 요약 ──
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 배포 후처리 완료"
echo "   리소스: ${RESOURCE_COUNT}개  |  환경: ${ENV}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit 0
