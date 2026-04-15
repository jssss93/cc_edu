---
globs: "**/*.tf,**/*.tfvars,**/.env*,**/.mcp.json,**/.claude/settings.json"
---
## 민감정보·비밀 노출 방지

### 읽기·컨텍스트
- **`*.tfvars`**, **`*.auto.tfvars`**, **`.env`**, **자격증명 JSON**, **키·PEM**은 루트 [`.claudeignore`](../../.claudeignore)로 Claude `Read` 대상에서 제외된다. 이 경로를 우회해 읽으려 하지 말 것.
- 예시만 다룰 때는 `*.example`, `terraform.tfvars.example` 등 **샘플 파일**만 참고한다.

### 답변·코드·커밋
- **subscription_id**, **tenant id**, **client secret**, **storage key**, **connection string**, **Miro/GitHub 토큰** 등은 답변·코드 블록·주석·PR 본문에 **실값을 넣지 않는다**. 필요 시 `variables.tf` 변수명, `azurerm_key_vault_secret` 참조, 또는 `<redacted>` / `***` 로만 표기한다.
- 터미널·MCP·Terraform 출력에 비밀이 섞이면 **요약·리소스 타입 수준**만 인용하고, 로그 전체를 그대로 붙여넣지 않는다.

### Memory·산출물
- `~/.claude/projects/.../memory/terraform_state.md` 등 훅이 쓰는 memory는 **외부 채팅·이슈·위키에 원문 붙여넣기 금지**(필요 시 민감 필드 제거 후).
- `plan`/`state` 인용 시 **민감 속성**(커넥션 문자열 등)이 보이면 마스킹한다.

### MCP·비용
- **실청구·청구 API·구독별 비밀번호식 키**를 조회하거나 출력하지 않는다 — 프로젝트 [mcp.md](mcp.md)의 infracost·비용 정책을 따른다.
