## MCP 설정 규칙
- Azure MCP 인증은 환경변수 방식 사용 안 함 → `az login` CLI 인증 사용
- Azure MCP 실행: `npx -y @azure/mcp@latest server start` (env 블록 비움)
- Terraform MCP 실행: `npx -y terraform-mcp-server` (패키지명: `terraform-mcp-server`, `@hashicorp/terraform-mcp-server` 아님)
- MCP 연결 실패 시 `az account show`로 로그인 상태 먼저 확인

## MCP 활용 규칙

### Terraform 작업 시
- 신규 리소스 코드 작성 전 반드시 Terraform MCP로 Registry 검색
- plan/apply/state 조회는 Terraform MCP 우선 사용 (CLI 직접 호출 지양)
- 코드 생성 후 항상 Terraform MCP로 validate 실행

### 배포 후 상태 확인 시
- Terraform state와 Azure 실제 리소스를 모두 확인 (Terraform MCP + Azure MCP)
- 불일치 발견 시 반드시 사용자에게 보고

### 비용 관련 요청 시
- Azure MCP cost query를 통해 실제 청구 데이터 기반으로 분석
- plan 단계에서는 추가될 리소스의 예상 비용도 함께 제시

### 아키텍처 변경 시
- 변경 완료 후 Miro MCP로 다이어그램 자동 업데이트
- 변경 내역은 GitHub MCP로 커밋 메시지에 기록

## Skills 동작 방식
- 스킬은 프롬프트 주입 방식 — 스킬이 직접 명령을 실행하는 것이 아니라 Claude가 스킬 지시를 받아 실행
- tf-apply/tf-destroy 스킬은 plan 파일 존재 여부를 먼저 확인하므로 tf-plan 선행 실행 필요
