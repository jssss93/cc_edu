# Azure Hub-Spoke Terraform + Claude Code

Azure Hub-Spoke 네트워크를 Terraform으로 배포하고, **Claude Code** 스킬·에이전트·MCP로 워크플로를 맞춘 교육·예제 레포입니다. **Cursor**에서는 `.cursor/` 훅·규칙으로 동일 정책을 거의 그대로 씁니다.

## 아키텍처 (요약)

```
Hub VNet (10.0.0.0/16)          Spoke VNet (10.1.0.0/16)
├── GatewaySubnet          ◄──► ├── snet-app
└── AzureFirewallSubnet         ├── snet-func (Function App VNet integration)
                                ├── Storage / ACR 등 Spoke 리소스
                                └── Linux Function App (EP1) 등
```

dev 환경에는 교육용으로 **Container Registry**, **Static Web App** 등이 추가될 수 있습니다. 세부는 `terraform/environments/dev/main.tf`를 본다.

## 저장소 구조

| 경로 | 역할 |
|------|------|
| [`CLAUDE.md`](CLAUDE.md) | 프로젝트 전역 지시 (MCP apply/destroy 금지, 비용·state 정책) |
| [`.claude/`](.claude/) | Claude Code: `settings.json`, `skills/`, `agents/`, `hooks/`, `rules/` |
| [`.cursor/`](.cursor/) | Cursor: 훅·CLI 권한·규칙 (Claude와 parity) |
| [`terraform/`](terraform/) | 환경별 `environments/{dev,staging,prod}/`, 공용 `modules/` |
| [`edu_docs/`](edu_docs/) | 교육용 HTML·마크다운 (Claude Read는 `.claudeignore`로 제외 가능) |
| [`terraform/backend.tf.template`](terraform/backend.tf.template) | 원격 `azurerm` backend **참고용** 예시 (팀 도입 시) |

## Terraform state

- **기본**: 환경 디렉터리별 **로컬** `terraform.tfstate` ([`CLAUDE.md`](CLAUDE.md)와 동일).
- **원격 backend**: 팀 표준으로 Azure Storage 등을 쓸 때만 [`terraform/backend.tf.template`](terraform/backend.tf.template)를 참고해 별도 구성한다.

## 환경

| 환경 | 경로 |
|------|------|
| dev | `terraform/environments/dev/` |
| staging | `terraform/environments/staging/` |
| prod | `terraform/environments/prod/` |

## 사전 요구사항

| 도구 | 용도 |
|------|------|
| Terraform >= 1.5.0 | 인프라 코드 |
| Azure CLI | 구독·리소스, Azure MCP는 `az login` 기반 |
| tflint / checkov | 정적 검사 (`/tf-plan`, `/tf-validate`) |
| infracost | **예상 비용만** (`/tf-plan` 워크플로) |
| Node.js >= 18 | MCP(`npx …`), Claude Code |
| jq | 스크립트·예시에서 사용 |
| Go 1.21+ | (선택) Terratest 실행 시 |

## 빠른 시작

```bash
# 1. Azure 로그인
az login

# 2. 변수 파일 (gitignore — 커밋 금지)
cp terraform/environments/dev/terraform.tfvars.example \
   terraform/environments/dev/terraform.tfvars
# terraform.tfvars에 subscription_id 등 실제 값 입력

# 3. Claude Code 스킬 (정본: .claude/skills/*/SKILL.md)
/tf-init dev
/tf-plan dev
/tf-apply dev
```

배포·삭제는 **Terraform MCP의 apply/destroy가 아니라** Bash + 스킬 절차를 쓴다([`CLAUDE.md`](CLAUDE.md)).

## Claude Code 스킬

| 명령어 | 설명 |
|--------|------|
| `/tf-init [env]` | `terraform init` — **로컬 state 기본**, 원격 backend는 팀 선택 |
| `/tf-plan [env]` | fmt → checkov → plan → **infracost 예상 비용** (실청구/청구 조회 없음) |
| `/tf-apply [env]` | plan 검토 후 `terraform apply` 등 Bash 적용 |
| `/tf-destroy [env]` | 다중 확인 후 destroy(스킬 절차 준수) |
| `/tf-validate` | fmt + tflint + checkov 빠른 검증 |
| `/miro-update` | state 기반 Miro 다이어그램(토큰·보드 ID 필요) |
| `/env-diff` | dev/staging/prod state 구성 차이 |
| `/tf-terratest` | (선택) 모듈별 Terratest |

## MCP 서버 (루트 `.mcp.json`)

| MCP | 용도 | 비고 |
|-----|------|------|
| **terraform** | plan/validate/state/registry 등 | `terraform-mcp-server`; **apply/destroy는 settings에서 deny** |
| **azure** | 리소스·구독 등 | `npx @azure/mcp@latest server start`, **실청구 API는 프로젝트 규칙상 미사용** |
| **miro** | 보드 아이템 | 아래 환경 변수 |

**GitHub MCP** 등은 팀에서 `.mcp.json` / 설정에 추가하는 **선택** 사항이다(기본 레포에는 미등록).

### Miro (선택)

```bash
export MIRO_ACCESS_TOKEN=your_token
export MIRO_BOARD_ID=your_board_id
export MIRO_AUTO_UPDATE=true   # apply 후 다이어그램 자동 갱신을 쓸 때만
```

## 자동화 훅 (`.claude/hooks/`)

| 스크립트 | 트리거(요약) | 동작 |
|----------|----------------|------|
| `pre-destroy-guard.sh` | PreToolUse / Bash | `terraform destroy` 패턴 차단 |
| `pre-push-tf-check.sh` | PreToolUse / Bash | `git push` 전 Terraform 관련 점검 |
| `notify-on-tool.sh` | PreToolUse | 도구 실행 알림(비동기) |
| `post-apply-snapshot.sh` | PostToolUse / Bash | `memory/terraform_state.md` 갱신 + infracost·Miro **안내** |
| `post-tf-edit-review.sh` | PostToolUse / Edit·Write | `.tf` 편집 후 리뷰 안내 |
| `notify-on-stop.sh` | Stop | 응답 완료 알림 |

`settings.json`에는 **SubagentStart** 등 추가 훅이 있을 수 있다. Cursor에서는 [`.cursor/hooks.json`](.cursor/hooks.json)이 같은 스크립트를 연결한다.

## 민감정보·비용

- **비밀**: `*.tfvars`, `.env` 등은 **gitignore** + [`.claudeignore`](.claudeignore); 답변·memory에서는 실값 대신 마스킹·변수 참조([`.claude/rules/secrets.md`](.claude/rules/secrets.md)).
- **비용**: **infracost 예상치만** 참고. Azure Cost Management·실청구 자동 조회는 하지 않는다.

## 코딩 규칙 (Terraform)

- 값은 `variables.tf` + `terraform.tfvars`; 민감 값은 `sensitive = true`.
- 리소스 태그: `environment`, `owner`, `project` 등(자세한 명명은 `.claude/rules/azure.md`).
- NSG·피어링 등은 모듈·환경 README 및 `terraform/CLAUDE.md`를 따른다.

## 교육 자료

- 슬라이드 덱: [`edu_docs/claude-code-full.html`](edu_docs/claude-code-full.html) (브라우저에서 열고 **← →** 또는 하단 페이징으로 이동).
- 상세 문서: [`edu_docs/claude-code-terraform-azure-education.md`](edu_docs/claude-code-terraform-azure-education.md).
