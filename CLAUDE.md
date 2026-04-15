# Azure Terraform 프로젝트 지시사항

※ 이 레포의 Claude 설정은 교육용 예제 기준이며, 실제 운영 환경에서는 권한과 훅을 별도로 강화해야 한다.

## 프로젝트 개요
- 목적: Azure Hub-Spoke 아키텍처 Terraform 배포
- 환경: dev / staging / prod
- 백엔드: 로컬 (terraform.tfstate를 각 환경 디렉토리에서 관리)
- 아키텍처 시각화: Miro MCP 자동 생성

## 참고 파일
See @terraform/variables.tf for variable definitions

## 민감정보 (Claude Code)

- **읽기 차단**: 루트 [`.claudeignore`](.claudeignore)에 `tfvars`·`.env`·키 등이 있으면 Claude가 해당 파일을 컨텍스트로 읽지 않는다.
- **행동 규칙**: [`.claude/rules/secrets.md`](.claude/rules/secrets.md) — 답변·코드·memory 인용 시 비밀 실값 금지, 마스킹·변수 참조만.

## 폴더 구조

```
cc_edu/
├── CLAUDE.md                          # 프로젝트 전역 지시사항
├── .gitignore
├── .mcp.json                          # MCP 서버 (Terraform · Azure · Miro; GitHub는 팀/설정 시 선택)
├── .claude/                           # Claude Code 설정 → .claude/CLAUDE.md 참조
├── .cursor/                           # Cursor: hooks.json + hooks/ + rules/ (Claude 훅·권한과 유사하게 맞춤)
└── terraform/                         # Terraform 코드 → terraform/CLAUDE.md 참조
```

## Cursor (에이전트·CLI)

- 훅: [`.cursor/hooks.json`](.cursor/hooks.json) 이 `.claude/hooks/*.sh` 를 Cursor 이벤트에 연결한다.
- 권한: [`.cursor/cli.json`](.cursor/cli.json) · [`.cursor/rules/cc-edu-claude-parity.mdc`](.cursor/rules/cc-edu-claude-parity.mdc)
- 스킬: [`.cursor/rules/cc-edu-claude-skills.mdc`](.cursor/rules/cc-edu-claude-skills.mdc) → 정본은 `.claude/skills/*/SKILL.md` 만 Read
- 에이전트 역할: [`.cursor/rules/cc-edu-claude-agents.mdc`](.cursor/rules/cc-edu-claude-agents.mdc) (`.claude/agents/*/AGENT.md` 를 필요 시 Read)

## Claude Code 권한·배포 (교육 자료 “MCP apply/destroy 금지”와의 관계)

- [`.claude/settings.json`](.claude/settings.json)에서 **`mcp__terraform__terraform_apply` / `mcp__terraform__terraform_destroy` 는 거부(deny)** 한다. 즉 Terraform **배포·삭제를 MCP 한 방으로 호출하지 않는다.**
- **`/tf-apply`** 는 **`terraform apply tfplan` 등 Bash**로 적용하므로, MCP apply를 막아도 **스킬 흐름은 정상 동작**한다. MCP는 주로 `plan`·`validate`·`state_list`·registry 검색 등에 쓴다.
- **`/tf-destroy`** 는 `terraform destroy` 문자열이 PreToolUse 훅에 걸릴 수 있어, **`terraform plan -destroy -out=tfplan` 후 `terraform apply tfplan`** 절차를 쓴다 ([`tf-destroy` 스킬](.claude/skills/tf-destroy/SKILL.md)).

## 비용

- **예상 비용만** [`infracost`](https://www.infracost.io/) (`/tf-plan` 워크플로의 `infracost breakdown --path tfplan`)로 본다. **실청구·실비용·Azure Cost Management 조회는 하지 않는다.**

## State 백엔드

- 이 프로젝트는 **로컬 state**(환경별 디렉터리의 `terraform.tfstate`)를 전제로 한다. 교육 HTML 등에 나오는 **원격 `azurerm` backend 예시는 참고용**이며, 본 레포의 운영 표준이 아니다.
