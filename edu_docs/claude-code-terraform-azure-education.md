# Claude Code × Terraform × Azure 교육자료

> **최종 목표:** Claude Code로 Terraform 기반 Azure 배포와 Miro 다이어그램 자동화를 익히고, **배포 전 예상 비용(infracost)** 까지 워크플로에 포함한다. (실청구·실비용 자동 조회는 범위에 포함하지 않음.)

---

## 문서 구성 (Phase)

| Phase | 범위 | 내용 |
|-------|------|------|
| **Phase 1** | Module 01–06 | Claude Code·프로젝트 설정·MCP·Hooks·Skills/Agents |
| **Phase 2** | Module 07–10 | Azure Terraform 실습·Miro·예상 비용(infracost)·실전 워크플로 |

---

## 목차

### Phase 1 — Claude Code 운영 기반

1. [Module 01 — Claude Code 기초](#module-01--claude-code-기초)
2. [Module 02 — 프로젝트 설정](#module-02--프로젝트-설정)
3. [Module 03 — MCP Server 연동](#module-03--mcp-server-연동)
4. [Module 04 — MCP 적극 활용 전략](#module-04--mcp-적극-활용-전략)
5. [Module 05 — Hooks & 자동화](#module-05--hooks--자동화)
6. [Module 06 — Skills & Agents 구성](#module-06--skills--agents-구성)

### Phase 2 — Terraform × Azure 실전

7. [Module 07 — Azure Terraform 환경 셋업 실습](#module-07--azure-terraform-환경-셋업-실습)
8. [Module 08 — Miro MCP 아키텍처 자동화](#module-08--miro-mcp-아키텍처-자동화)
9. [Module 09 — 예상 비용 (infracost) · cc_edu 정책](#module-09--예상-비용-infracost--cc_edu-정책)
10. [Module 10 — 실전 워크플로우](#module-10--실전-워크플로우)

---

## Phase 1 — Claude Code 운영 기반

### Module 01 — Claude Code 기초

#### 01.1 Claude Code란?

Claude Code는 터미널 기반의 AI 코딩 에이전트로, 일반 Claude와 달리 **파일 시스템 접근, 명령어 실행, MCP 도구 연동**이 가능하다.

| 구분 | 일반 Claude (claude.ai) | Claude Code |
|------|------------------------|-------------|
| 파일 읽기/쓰기 | ❌ | ✅ |
| 터미널 명령 실행 | ❌ | ✅ |
| MCP 도구 연동 | 제한적 | ✅ 완전 지원 |
| 프로젝트 컨텍스트 유지 | ❌ | ✅ CLAUDE.md |
| 세션 간 기억 | ❌ | ✅ Memory 시스템 |

#### 01.2 설치 및 초기 설정

**사전 요구사항**

```bash
# Node.js 18+ 필요
node --version   # v18 이상 확인

# Claude Code 설치
npm install -g @anthropic-ai/claude-code

# 인증
claude auth login
```

**설치 확인**

```bash
claude --version
claude doctor   # 진단 실행
```

#### 01.3 기본 UI 구조 및 키보드 단축키

| 키 | 동작 |
|----|------|
| `Enter` | 메시지 전송 |
| `Shift+Tab` | 모드 전환 (default ↔ acceptEdits) |
| `Escape` | 취소/중단 |
| `Ctrl+T` | 태스크 목록 토글 |
| `Ctrl+R` | 히스토리 검색 |
| `Ctrl+C` | 인터럽트 |

#### 01.4 권한 모드 이해

| 모드 | 설명 | Terraform 작업 시 활용 |
|------|------|----------------------|
| `default` | 도구 사용 시 승인 요청 | 초기 학습 단계 |
| `acceptEdits` | 파일 편집 자동 승인 | 코드 작성 단계 |
| `plan` | 읽기 전용 (분석만) | `terraform plan` 검토 단계 |
| `dontAsk` | 사전 허용된 것만 실행 | CI/CD 자동화 |
| `bypassPermissions` | 모든 권한 생략 | 격리 환경 전용 |

> **출처:** Anthropic Claude Code 공식 문서 / 첨부 가이드 문서

---

### Module 02 — 프로젝트 설정

#### 02.1 디렉토리 구조

```
terraform-azure-project/
├── CLAUDE.md                       # 프로젝트 지시사항 (git 공유)
├── .claudeignore                   # 무시 파일 패턴
├── .mcp.json                       # MCP 서버 설정 (git 공유)
└── .claude/
    ├── settings.json               # 프로젝트 설정 (git 공유)
    ├── settings.local.json         # 로컬 오버라이드 (.gitignore)
    ├── skills/                     # Terraform 작업 스킬
    │   ├── tf-init/
    │   ├── tf-plan/
    │   ├── tf-apply/
    │   └── tf-destroy/
    ├── agents/                     # 전문 에이전트
    │   ├── terraform-reviewer/
    │   └── azure-validator/
    └── hooks/                      # 자동화 훅 스크립트
        ├── pre-terraform.sh
        └── post-terraform.sh
```

#### 02.2 CLAUDE.md 작성 — Terraform/Azure 프로젝트

```markdown
# Azure Terraform 프로젝트 지시사항

## 프로젝트 개요
- 목적: Azure Hub-Spoke 아키텍처 Terraform 배포
- 환경: dev / staging / prod
- 백엔드: Azure Storage Account (tfstate)
- 아키텍처 시각화: Miro MCP 자동 생성

## Terraform 작업 규칙
- 항상 `terraform fmt`를 실행 후 코드를 저장한다
- `terraform plan` 결과를 반드시 검토 후 apply 진행
- 모든 리소스에 `tags` 블록 포함 필수 (environment, owner, project)
- 변수는 반드시 `variables.tf`에 정의, 값은 `terraform.tfvars`에 분리
- `terraform destroy`는 반드시 사용자 확인 후 실행

## Azure 인프라 규칙
- 리소스 그룹 명명: `rg-{project}-{env}-{region}`
- VNet CIDR: Hub 10.0.0.0/16, Spoke 10.{n}.0.0/16
- Private Endpoint는 VNet Peering 이후에 설정
- NSG는 모든 Subnet에 필수 적용

## 코드 생성 규칙
- 한국어로 주석 작성
- Azure Provider 버전: ~> 3.0 이상
- Terraform 버전: >= 1.5.0

## 참고 파일
See @README.md for project overview
See @terraform/variables.tf for variable definitions
```

#### 02.3 Settings.json 구성

```json
{
  "defaultMode": "acceptEdits",
  "model": "claude-sonnet-4-6",
  "autoMemoryEnabled": true,
  "language": "korean",
  "permissions": {
    "allow": [
      "Read",
      "Write",
      "Bash(terraform *)",
      "Bash(az *)",
      "Bash(git *)",
      "Bash(tflint *)",
      "Bash(checkov *)"
    ],
    "deny": [
      "Bash(terraform destroy)",
      "Bash(rm -rf *)",
      "Bash(az group delete *)"
    ]
  }
}
```

#### 02.4 .claudeignore 설정

```gitignore
# Terraform 생성 파일
.terraform/
*.tfstate
*.tfstate.backup
.terraform.lock.hcl
terraform.tfplan

# 민감 정보
*.tfvars
!terraform.tfvars.example
.env
*.pem
*.key

# 로그
*.log
crash.log

# OS
.DS_Store
Thumbs.db
```

> **출처:** 첨부 가이드 문서 §11 .claudeignore / §2 CLAUDE.md / §4 Settings

---

### Module 03 — MCP Server 연동

#### 03.1 MCP 전체 아키텍처

MCP(Model Context Protocol)는 Claude Code가 외부 도구/서비스와 통신하는 표준 프로토콜이다. 이 프로젝트에서는 **4가지 MCP**를 조합하여 코드 생성부터 배포·시각화까지 자동화한다. **비용은 실청구 데이터가 아니라 `infracost`(주로 `/tf-plan` 단계)로 예상치만 본다.**

```
Claude Code
    │
    ├── Terraform MCP     → tf 파일 분석/검증/상태 조회 (핵심, apply/destroy는 settings에서 deny)
    ├── Azure MCP         → Azure 리소스·구독·토폴로지 조회 (실비용·청구 조회는 사용하지 않음)
    ├── GitHub MCP        → Terraform 코드 PR/커밋/버전 관리
    └── Miro MCP          → 아키텍처 다이어그램 자동 생성/업데이트
```

| MCP | 주요 역할 | 연동 시점 |
|-----|----------|----------|
| **Terraform MCP** | plan 분석, state 조회, 모듈 검색 | 코드 작성 ~ 배포 전 |
| **Azure MCP** | 리소스 상태·구독·네트워크 토폴로지 | 배포 중 ~ 배포 후 |
| **GitHub MCP** | 코드 리뷰 PR, 브랜치 관리, Actions 트리거 | 코드 작성 ~ 배포 전 |
| **Miro MCP** | 아키텍처 다이어그램 자동 렌더링 | 배포 완료 후 |

---

#### 03.2 Terraform MCP 상세

#### 개요

Terraform MCP Server는 Claude Code가 Terraform 코드와 상태를 **직접 이해하고 조작**할 수 있게 해주는 MCP다. 단순히 `terraform` CLI를 래핑하는 것이 아니라, HCL 코드 분석과 Registry 연동까지 지원한다.

**주요 제공 기능:**

| 기능 | 설명 |
|------|------|
| `terraform_plan` | plan 실행 및 구조화된 변경사항 반환 |
| `terraform_apply` | apply 실행 및 결과 반환 |
| `terraform_state_list` | 현재 state 리소스 목록 조회 |
| `terraform_state_show` | 특정 리소스 상세 속성 조회 |
| `terraform_validate` | 코드 문법/논리 검증 |
| `terraform_fmt` | 코드 포맷팅 |
| `terraform_output` | output 값 조회 |
| `registry_search` | Terraform Registry 모듈/프로바이더 검색 |
| `registry_module_details` | 특정 모듈 상세 정보 및 예제 조회 |

#### 설치 및 등록

```bash
# Terraform MCP Server 설치 (Python 기반)
pip install terraform-mcp-server
# 또는
npx -y @hashicorp/terraform-mcp-server

# Claude Code에 등록
claude mcp add --transport stdio terraform -- npx -y @hashicorp/terraform-mcp-server

# 또는 Python 방식
claude mcp add --transport stdio terraform -- python -m terraform_mcp_server
```

#### Terraform MCP 활용 프롬프트 예시

```
# Registry에서 검증된 Azure 모듈 검색
"terraform registry에서 Azure Hub-Spoke 아키텍처 모듈 검색해줘"
→ Terraform MCP: registry_search("azure hub spoke")

# Plan 결과 구조화 분석
"현재 dev 환경 terraform plan 실행하고 변경될 리소스를 유형별로 정리해줘"
→ Terraform MCP: terraform_plan() → 결과 분석 → 한국어 요약

# State에서 특정 리소스 속성 조회
"배포된 Hub VNet의 실제 CIDR과 Subnet 목록 조회해줘"
→ Terraform MCP: terraform_state_show("azurerm_virtual_network.hub")

# 코드 검증 + 포맷팅 동시 실행
"모든 tf 파일 검증하고 포맷팅 해줘"
→ Terraform MCP: terraform_validate() + terraform_fmt()
```

---

#### 03.3 Azure MCP 상세

#### 주요 제공 기능

| 기능 | 설명 |
|------|------|
| `azure_resource_list` | 구독/리소스그룹 내 리소스 목록 조회 |
| `azure_resource_show` | 특정 리소스 상세 속성 조회 |
| (청구 API) | **cc_edu 정책:** Azure Cost/Consumption 실비용 조회는 문서·워크플로에 포함하지 않음. 예상 비용은 **infracost** |
| `azure_monitor_metrics` | Azure Monitor 메트릭 조회 |
| `azure_network_topology` | 네트워크 토폴로지 조회 |

#### 활용 프롬프트 예시

```
# 배포 후 실제 리소스 상태 확인
"dev 리소스 그룹에 배포된 전체 리소스 목록과 상태 확인해줘"
→ Azure MCP: azure_resource_list(resource_group="rg-project-dev-krc")

# 예상 비용 (배포 전)
"/tf-plan dev 실행해서 infracost 예상 월 비용까지 확인해줘"
→ Bash: `infracost breakdown --path tfplan` (`/tf-plan` 스킬에 포함)

# 네트워크 연결 검증
"Hub VNet과 Spoke VNet의 Peering 상태 확인해줘"
→ Azure MCP: azure_network_topology(subscription_id="...")
```

---

#### 03.4 .mcp.json 전체 구성

```json
{
  "mcpServers": {
    "terraform": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@hashicorp/terraform-mcp-server"],
      "env": {
        "TF_WORKSPACE_PATH": "${PWD}",
        "TF_LOG": "WARN"
      }
    },
    "azure": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@azure/mcp-server"],
      "env": {
        "AZURE_SUBSCRIPTION_ID": "${AZURE_SUBSCRIPTION_ID}",
        "AZURE_TENANT_ID": "${AZURE_TENANT_ID}",
        "AZURE_CLIENT_ID": "${AZURE_CLIENT_ID}",
        "AZURE_CLIENT_SECRET": "${AZURE_CLIENT_SECRET}"
      }
    },
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    },
    "miro": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@mirohq/mcp-server"],
      "env": {
        "MIRO_ACCESS_TOKEN": "${MIRO_ACCESS_TOKEN}",
        "MIRO_BOARD_ID": "${MIRO_BOARD_ID}"
      }
    }
  }
}
```

#### 03.5 MCP 서버 일괄 등록 (CLI)

```bash
# Terraform MCP
claude mcp add --transport stdio terraform -- npx -y @hashicorp/terraform-mcp-server

# Azure MCP
claude mcp add --transport stdio azure -- npx -y @azure/mcp-server

# GitHub MCP
claude mcp add --transport http github https://api.githubcopilot.com/mcp/

# Miro MCP
claude mcp add --transport stdio miro -- npx -y @mirohq/mcp-server

# 등록 확인
claude mcp list
```

#### 03.6 환경 변수 설정

```bash
# .env (git 미공유 — .claudeignore에 포함)
export AZURE_SUBSCRIPTION_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export AZURE_TENANT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export AZURE_CLIENT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export AZURE_CLIENT_SECRET="your-secret"
export MIRO_ACCESS_TOKEN="your-miro-token"
export MIRO_BOARD_ID="your-board-id"
```

> **출처:** Terraform MCP Server (https://github.com/hashicorp/terraform-mcp-server) / Azure MCP Server (https://github.com/Azure/azure-mcp) / Miro Developer Documentation (https://developers.miro.com/docs) / 첨부 가이드 문서 §6 MCP Servers

---

### Module 04 — MCP 적극 활용 전략

#### 04.1 MCP 조합 활용 원칙

Claude Code는 단일 MCP만 사용하는 것이 아니라 **여러 MCP를 동시에 조합**하여 복잡한 작업을 자동화할 수 있다. 요청 시 아래 원칙을 따른다.

```
요청 유형별 MCP 우선순위

[코드 작성/수정 요청]
  1순위: Terraform MCP (registry 검색, validate)
  2순위: GitHub MCP (기존 코드 참조)

[배포/상태 확인 요청]
  1순위: Terraform MCP (plan, apply, state)
  2순위: Azure MCP (실제 리소스 검증)

[비용 분석 요청]
  1순위: Azure MCP (cost query)
  2순위: Terraform MCP (plan으로 추가될 리소스 파악)

[아키텍처 문서화 요청]
  1순위: Terraform MCP (state 조회)
  2순위: Azure MCP (실제 토폴로지)
  3순위: Miro MCP (다이어그램 생성)
```

---

#### 04.2 시나리오별 MCP 활용 패턴

#### 시나리오 1: 신규 리소스 배포 요청

```
사용자: "koreacentral에 AKS 클러스터 추가해줘. 기존 Hub-Spoke에 연결하고"

Claude Code 동작:
  [Terraform MCP] registry_search("azure aks module")
      → 검증된 AKS 모듈 확인
  [Terraform MCP] terraform_state_show("azurerm_virtual_network.hub")
      → 기존 Hub VNet CIDR / Subnet 정보 조회
  [GitHub MCP] get_file("terraform/modules/spoke-vnet/main.tf")
      → 기존 Spoke 모듈 패턴 참조
  → AKS Terraform 코드 생성 (기존 아키텍처에 맞게)
  [Terraform MCP] terraform_validate() + terraform_fmt()
      → 코드 검증 및 포맷팅 자동 실행
```

#### 시나리오 2: 배포 후 전체 상태 리포트

```
사용자: "dev 환경 배포 완료됐는지 전체 상태 리포트 만들어줘"

Claude Code 동작:
  [Terraform MCP] terraform_state_list()
      → 전체 배포 리소스 목록
  [Terraform MCP] terraform_output()
      → endpoint, IP 등 output 값 수집
  [Azure MCP] azure_resource_list(resource_group="rg-project-dev-krc")
      → 실제 Azure 리소스 Running 상태 확인
  [Azure MCP] azure_network_topology()
      → VNet Peering 연결 상태 확인
  → 상태 리포트 마크다운 생성
  [Miro MCP] create_frame() + create_shapes()
      → Miro 보드에 현재 아키텍처 자동 업데이트
```

#### 시나리오 3: 코드 변경 → PR 생성 → 배포 전체 자동화

```
사용자: "NSG에 443 포트 인바운드 규칙 추가하고 PR 만들어줘"

Claude Code 동작:
  [GitHub MCP] get_branch("main")
      → 현재 브랜치 상태 확인
  [Terraform MCP] terraform_state_show("azurerm_network_security_group.*")
      → 현재 NSG 규칙 목록 조회
  → NSG 규칙 Terraform 코드 수정
  [Terraform MCP] terraform_validate()
      → 변경 코드 검증
  [GitHub MCP] create_branch("feature/nsg-443-inbound")
  [GitHub MCP] create_commit(files=["terraform/nsg.tf"])
  [GitHub MCP] create_pull_request(title="NSG 443 포트 인바운드 추가")
      → PR 자동 생성 (변경사항 설명 포함)
```

#### 시나리오 4: 배포 전 예상 비용 확인 (cc_edu 정책)

```
사용자: "이번 plan으로 월 예상 비용이 얼마나 되는지 알려줘"

Claude Code 동작:
  [Bash] /tf-plan 또는 terraform plan -out=tfplan 후
  [Bash] infracost breakdown --path tfplan --format table
      → 예상 월 비용(소매 단가 기준, 실청구 아님)
  [에이전트] cost-optimizer — SKU/크기 최적화 아이디어(선택)
  ※ 실제 청구·Consumption 조회는 이 프로젝트 범위에서 다루지 않음
```

---

#### 04.3 CLAUDE.md에 MCP 활용 지침 추가

```markdown
## MCP 활용 규칙 (CLAUDE.md에 추가)

### Terraform 작업 시
- 신규 리소스 코드 작성 전 반드시 Terraform MCP로 Registry 검색
- plan/apply/state 조회는 Terraform MCP 우선 사용 (CLI 직접 호출 지양)
- 코드 생성 후 항상 Terraform MCP로 validate 실행

### 배포 후 상태 확인 시
- Terraform state와 Azure 실제 리소스를 모두 확인 (Terraform MCP + Azure MCP)
- 불일치 발견 시 반드시 사용자에게 보고

### 비용 관련 요청 시
- **실비용·청구 데이터는 조회하지 않는다.** 예상 비용은 **`infracost breakdown --path tfplan`** (`/tf-plan`에 포함)
- Azure MCP `pricing` 등은 SKU 비교 보조용으로만 활용 가능

### 아키텍처 변경 시
- 변경 완료 후 Miro MCP로 다이어그램 자동 업데이트
- 변경 내역은 GitHub MCP로 커밋 메시지에 기록
```

---

#### 04.4 MCP 권한 설정 (settings.json) — cc_edu 현행

실제 레포는 저장소 루트의 `.claude/settings.json`을 따른다. 요지만 요약하면 다음과 같다.

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Write",
      "Bash(terraform fmt*)",
      "Bash(terraform init*)",
      "Bash(terraform plan*)",
      "Bash(terraform validate*)",
      "Bash(terraform state*)",
      "Bash(terraform output*)",
      "Bash(terraform apply*)",
      "Bash(terraform destroy*)",
      "Bash(az *)",
      "Bash(git *)",
      "Bash(tflint *)",
      "Bash(checkov *)",
      "Bash(infracost *)",
      "mcp__terraform__terraform_plan",
      "mcp__terraform__terraform_validate",
      "mcp__terraform__terraform_fmt",
      "mcp__terraform__terraform_state_list",
      "mcp__terraform__terraform_state_show",
      "mcp__terraform__terraform_output",
      "mcp__terraform__registry_search",
      "mcp__terraform__registry_module_details",
      "mcp__azure__group_list",
      "mcp__azure__group_resource_list",
      "mcp__azure__pricing",
      "mcp__azure__subscription_list",
      "mcp__azure__monitor",
      "mcp__azure__advisor",
      "mcp__azure__resourcehealth",
      "mcp__github__get_file_contents",
      "mcp__github__create_pull_request",
      "mcp__github__create_branch",
      "mcp__github__push_files",
      "mcp__miro__create_board_item",
      "mcp__miro__update_board_item",
      "mcp__miro__get_board_items"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(az group delete *)",
      "mcp__terraform__terraform_apply",
      "mcp__terraform__terraform_destroy"
    ]
  }
}
```

> **⚠️ 참고:** MCP `terraform_apply` / `terraform_destroy` 는 **deny**. 배포·삭제는 **Bash**로 `terraform apply tfplan`, `plan -destroy` + `apply tfplan` 등 **스킬(`/tf-apply`, `/tf-destroy`)** 경로를 사용한다.

> **출처:** 첨부 가이드 문서 §6 MCP Servers / §12 권한 시스템 / Terraform MCP Server GitHub (https://github.com/hashicorp/terraform-mcp-server)

---

### Module 05 — Hooks & 자동화

#### 05.1 Hooks 개념

Hooks는 특정 이벤트 발생 시 자동으로 실행되는 스크립트다. Terraform 워크플로우에서 **배포 전 검증 자동화**에 핵심적으로 활용된다.

```
사용자 요청
    │
    ▼
[PreToolUse Hook]  ← tflint, checkov 자동 실행
    │
    ▼
terraform plan / apply 실행
    │
    ▼
[PostToolUse Hook] ← 배포 결과 검증, 비용 계산, Miro 아키텍처 업데이트
```

#### 05.2 settings.json — Hooks 설정

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash(terraform apply*)",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/pre-terraform.sh",
            "timeout": 120
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash(terraform apply*)",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/post-terraform.sh",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

#### 05.3 pre-terraform.sh — 배포 전 검증

```bash
#!/bin/bash
# .claude/hooks/pre-terraform.sh
# terraform apply 실행 전 자동 검증

set -e

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

echo "🔍 Terraform 사전 검증 시작..."

# tflint 실행
if command -v tflint &>/dev/null; then
  echo "▶ tflint 실행 중..."
  tflint --recursive
  echo "✅ tflint 통과"
else
  echo "⚠️  tflint 미설치 — 건너뜀"
fi

# checkov 보안 검사
if command -v checkov &>/dev/null; then
  echo "▶ checkov 보안 검사 중..."
  checkov -d . --quiet --compact
  echo "✅ checkov 통과"
else
  echo "⚠️  checkov 미설치 — 건너뜀"
fi

# terraform destroy 가드
if echo "$COMMAND" | grep -q "destroy"; then
  echo '{"continue": false, "decision": "block", "stopReason": "terraform destroy는 직접 실행 금지. /tf-destroy 스킬을 사용하세요."}'
  exit 2
fi

echo "✅ 사전 검증 완료"
exit 0
```

#### 05.4 post-terraform.sh — 배포 후 상태 확인 (기본)

```bash
#!/bin/bash
# .claude/hooks/post-terraform.sh
# terraform apply 성공 후 실행

echo "📊 배포 후 상태 확인..."

# terraform output 저장
terraform output -json > .claude/last-output.json 2>/dev/null || true

# 배포된 리소스 요약
echo "▶ 배포된 리소스 목록:"
terraform state list 2>/dev/null | head -20

echo "✅ 상태 확인 완료"
echo "→ 예상 비용: /tf-plan 단계의 infracost 결과 참고"
echo "→ 아키텍처 시각화: /miro-update 스킬 실행"
exit 0
```

> **출처:** 첨부 가이드 문서 §5 Hooks

---

### Module 06 — Skills & Agents 구성

#### 06.1 Terraform 핵심 스킬

#### `/tf-init` — 초기화 스킬

```
.claude/skills/tf-init/
├── SKILL.md
└── backend.tf.template
```

**SKILL.md:**

```yaml
---
name: tf-init
description: Terraform 초기화 및 Azure 백엔드 설정
argument-hint: "[환경명: dev|staging|prod]"
allowed-tools: Bash, Read, Write
---

$ARGUMENTS 환경으로 Terraform을 초기화한다.

1. backend 설정 파일 생성 (Azure Storage Account)
2. `terraform init` 실행
3. provider 버전 확인
4. `.terraform.lock.hcl` 생성 확인

백엔드 설정 참고: [backend.tf.template](backend.tf.template)
```

---

#### `/tf-plan` — 플랜 검토 스킬

**SKILL.md:**

```yaml
---
name: tf-plan
description: Terraform plan 실행 및 변경사항 분석
argument-hint: "[환경명]"
allowed-tools: Bash, Read
---

$ARGUMENTS 환경의 terraform plan을 실행하고 변경사항을 분석한다.

1. `terraform plan -out=tfplan` 실행
2. 변경될 리소스 목록 추출 및 한국어로 요약
3. 위험한 변경사항(destroy) 하이라이트
4. 승인 여부 사용자에게 확인
```

---

#### `/tf-apply` — 환경별 배포 스킬

**SKILL.md:**

```yaml
---
name: tf-apply
description: Terraform apply 실행 (plan 검토 후 배포)
argument-hint: "[환경명: dev|staging|prod]"
allowed-tools: Bash, Read
context: fork
agent: general-purpose
---

$ARGUMENTS 환경에 Terraform 배포를 실행한다.

1. plan 파일 존재 확인 (없으면 /tf-plan 먼저 실행)
2. 변경사항 최종 요약 표시
3. 사용자 승인 대기
4. `terraform apply tfplan` 실행
5. 완료 후 output 표시
6. /miro-update 스킬 자동 호출 (아키텍처 다이어그램 업데이트)
```

---

#### `/tf-destroy` — 안전 삭제 스킬

**SKILL.md:**

```yaml
---
name: tf-destroy
description: Terraform destroy 실행 (다중 확인 후)
argument-hint: "[환경명]"
allowed-tools: Bash, Read
---

⚠️ 경고: 이 스킬은 $ARGUMENTS 환경의 모든 리소스를 삭제한다.

1. 삭제될 리소스 목록 표시
2. "환경명을 입력하여 확인" 방식으로 2차 승인
3. `terraform destroy` 실행
4. 삭제 완료 확인
```

---

#### 06.2 Subagent 구성

#### `terraform-reviewer` — 코드 리뷰 에이전트

```
.claude/agents/terraform-reviewer/
└── AGENT.md
```

**AGENT.md:**

```yaml
---
name: terraform-reviewer
description: Terraform 코드 리뷰 전문가. tf 파일 변경 후 자동 사용.
tools: Read, Grep, Glob, Bash
model: sonnet
maxTurns: 15
---

시니어 Azure Terraform 엔지니어로서 다음 항목을 중점 검토한다.

## 검토 항목
- 보안: NSG 규칙, 공개 IP 노출, 키 하드코딩 여부
- 비용: 불필요한 리소스, 적절한 SKU 선택
- 네이밍: Azure 명명 규칙 준수
- 태그: 필수 태그 (environment, owner, project) 포함 여부
- Private Endpoint: VNet Peering 이후 설정 순서 확인
- 변수화: 하드코딩된 값 변수 분리 권고
```

---

#### `azure-validator` — Azure 리소스 검증 에이전트

**AGENT.md:**

```yaml
---
name: azure-validator
description: 배포된 Azure 리소스 상태 검증 전문가
tools: Bash, Read
model: sonnet
maxTurns: 10
---

배포 완료 후 Azure CLI를 사용하여 실제 리소스 상태를 검증한다.

## 검증 항목
- 리소스 존재 및 Running 상태 확인
- NSG 규칙 실제 적용 여부
- Private DNS Zone 연결 상태
- VNet Peering 연결 상태
- 태그 적용 여부
```

> **출처:** 첨부 가이드 문서 §3 Skills / §15 Subagent 시스템

---

## Phase 2 — Terraform × Azure 실전

### Module 07 — Azure Terraform 환경 셋업 실습

#### 07.1 Azure 인증 설정

**Service Principal 생성 (Azure CLI)**

```bash
# 서비스 프린시팔 생성
az ad sp create-for-rbac \
  --name "sp-terraform-claudecode" \
  --role Contributor \
  --scopes /subscriptions/${SUBSCRIPTION_ID}

# 출력값을 환경변수로 설정
export ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
export ARM_TENANT_ID="$(az account show --query tenantId -o tsv)"
export ARM_CLIENT_ID="<appId>"
export ARM_CLIENT_SECRET="<password>"
```

**Terraform Provider 설정**

```hcl
# terraform/providers.tf
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate-prod-koreacentral"
    storage_account_name = "sttfstateprod001"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
```

#### 07.2 Terraform Backend — Azure Storage Account 생성

```bash
# 스크립트로 백엔드 인프라 사전 생성
RESOURCE_GROUP="rg-tfstate-prod-koreacentral"
STORAGE_ACCOUNT="sttfstateprod001"
CONTAINER_NAME="tfstate"
LOCATION="koreacentral"

az group create --name $RESOURCE_GROUP --location $LOCATION

az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob

az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT
```

#### 07.3 Hub-Spoke 기본 구조 생성 실습

```
Claude Code 프롬프트 예시:

"Hub-Spoke 아키텍처를 Terraform으로 생성해줘.
- Hub VNet: 10.0.0.0/16 (koreacentral)
- Spoke1 VNet: 10.1.0.0/16 (앱 서버용)
- Spoke2 VNet: 10.2.0.0/16 (DB 서버용)
- Hub에 Azure Bastion, Azure Firewall 포함
- VNet Peering 설정
- 모든 리소스에 environment=dev 태그 추가"
```

**생성되는 Terraform 구조 예시:**

```
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── modules/
│   ├── hub-vnet/
│   │   ├── main.tf
│   │   └── variables.tf
│   ├── spoke-vnet/
│   │   ├── main.tf
│   │   └── variables.tf
│   └── vnet-peering/
│       └── main.tf
└── environments/
    ├── dev/
    ├── staging/
    └── prod/
```

#### 07.4 Plan Mode 활용

```bash
# Plan Mode로 진입하여 변경사항만 분석
claude --permission-mode plan

# 또는 대화 중
/plan
"Hub VNet에 새로운 Subnet을 추가하면 어떤 리소스가 영향을 받아?"
/exitplan
```

#### 07.5 Memory 시스템 활용

Claude Code가 프로젝트 컨텍스트를 자동으로 메모리에 저장한다.

```
~/.claude/projects/<project-path>/memory/
├── MEMORY.md           # 인덱스
├── azure_context.md    # Azure 구독, 리소스 그룹 정보
├── terraform_state.md  # 배포된 리소스 현황
└── decisions.md        # 아키텍처 결정사항 기록
```

> **출처:** Terraform Azure Provider 공식 문서 (https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) / 첨부 가이드 문서 §2 Memory / §14 Plan Mode

---

### Module 08 — Miro MCP 아키텍처 자동화

#### 08.1 Miro MCP 개요

Miro MCP Server를 통해 Terraform 배포 완료 후 **Azure 아키텍처 다이어그램을 Miro 보드에 자동으로 생성/업데이트**할 수 있다.

```
terraform apply 완료
        │
        ▼
terraform state list (리소스 목록 추출)
        │
        ▼
Claude Code (아키텍처 분석)
        │
        ▼
Miro MCP Server (다이어그램 자동 생성)
        │
        ▼
Miro 보드에 Hub-Spoke 다이어그램 렌더링
```

#### 08.2 Miro 토큰 발급

```
1. https://miro.com/app/settings/user-profile/apps 접속
2. "Create new app" 클릭
3. App 이름: "Claude Code Terraform Visualizer"
4. 권한: boards:read, boards:write 선택
5. Access Token 복사 → MIRO_ACCESS_TOKEN 환경변수 설정
6. 대상 보드 URL에서 Board ID 추출:
   https://miro.com/app/board/uXjVI_XXXXXXX=/ → uXjVI_XXXXXXX=
```

#### 08.3 `/miro-update` 스킬 작성

```
.claude/skills/miro-update/
├── SKILL.md
└── diagram-template.md
```

**SKILL.md:**

```yaml
---
name: miro-update
description: Terraform 배포 리소스를 Miro 보드에 아키텍처 다이어그램으로 자동 생성
allowed-tools: Bash, Read, mcp__miro__*
context: fork
agent: general-purpose
---

배포된 Terraform 리소스를 분석하여 Miro 보드에 Azure 아키텍처 다이어그램을 생성한다.

## 실행 순서

1. terraform state list로 전체 리소스 목록 추출
2. 리소스를 유형별로 분류 (VNet, Subnet, NSG, VM, PaaS 등)
3. Hub-Spoke 토폴로지 분석
4. Miro MCP를 사용하여 다이어그램 요소 생성:
   - 각 VNet을 큰 컨테이너 박스로 표현
   - Subnet을 내부 박스로 표현
   - 리소스를 Azure 아이콘 스티커로 표현
   - VNet Peering을 화살표 연결선으로 표현
   - 색상 규칙: Hub=파란색, Spoke=초록색, 보안 리소스=빨간색
5. 다이어그램 레이아웃 자동 정렬
6. 완성된 보드 URL 출력

참고 템플릿: [diagram-template.md](diagram-template.md)
```

#### 08.4 Miro MCP 활용 프롬프트 예시

```
# 배포 후 자동 아키텍처 생성
/miro-update dev

# 수동으로 요청하는 경우
"현재 terraform state에 있는 리소스를 분석해서
 Miro 보드에 Hub-Spoke 아키텍처 다이어그램을 그려줘.
 Hub VNet과 Spoke VNet의 연결관계, 각 Subnet 내 리소스,
 NSG 규칙도 함께 표시해줘"
```

#### 08.5 Miro 다이어그램 구성 요소

| Azure 리소스 | Miro 표현 방식 | 색상 |
|-------------|---------------|------|
| Resource Group | 큰 테두리 프레임 | 회색 |
| VNet (Hub) | 큰 컨테이너 박스 | 파란색 |
| VNet (Spoke) | 큰 컨테이너 박스 | 초록색 |
| Subnet | 내부 박스 | 연한 색상 |
| VNet Peering | 양방향 화살표 | 검정색 |
| Azure Firewall | 아이콘 스티커 | 빨간색 |
| Azure Bastion | 아이콘 스티커 | 주황색 |
| VM / VMSS | 아이콘 스티커 | 파란색 |
| Private Endpoint | 점선 연결 | 보라색 |
| NSG | 보안 배지 | 빨간색 테두리 |

#### 08.6 자동화 통합 — PostToolUse Hook 확장

```bash
#!/bin/bash
# .claude/hooks/post-terraform.sh (확장판)

echo "📊 배포 후 처리 시작..."

# terraform state 저장
terraform state list > /tmp/tf-state-resources.txt
terraform output -json > .claude/last-output.json 2>/dev/null || true

# 리소스 수 계산
RESOURCE_COUNT=$(wc -l < /tmp/tf-state-resources.txt)
echo "✅ 총 ${RESOURCE_COUNT}개 리소스 배포 완료"

echo ""
echo "🎨 다음 스킬을 순서대로 실행하세요:"
echo "  1. (배포 전) /tf-plan — infracost 예상 비용 포함"
echo "  2. /miro-update  — 아키텍처 다이어그램 업데이트"

exit 0
```

> **출처:** Miro Developer Documentation (https://developers.miro.com/docs/rest-api-reference) / 첨부 가이드 문서 §3 Skills / §5 Hooks

---

### Module 09 — 예상 비용 (infracost) · cc_edu 정책

#### 09.1 전략 개요

**cc_edu**에서는 **실청구·실비용(Consumption/Cost Management API)을 자동 조회하지 않는다.**  
비용은 **`terraform plan -out=tfplan` 이후 `infracost breakdown --path tfplan`** 으로 얻는 **예상 월 비용(소매 단가 기준)** 만 다룬다. 이 흐름은 **`/tf-plan` 스킬**에 포함된다.

```
/tf-plan
  → plan 산출물(tfplan)
  → infracost breakdown --path tfplan
  → (병렬) cost-optimizer 에이전트 — SKU·크기 최적화 아이디어 (실청구 아님)

terraform apply 성공 후(PostHook)
  → state 스냅샷 · stdout으로 infracost·/miro-update 안내 (자동 청구 조회 없음)
```

---

#### 09.2 에이전트·도구 (저장소 기준)

| 항목 | 역할 |
|------|------|
| **`infracost` CLI** | `Bash(infracost *)` 허용 — plan 대비 예상 비용 표 |
| **cost-optimizer** (`.claude/agents/cost-optimizer/`) | plan 변경 리소스 기준 SKU·크기 점검 (청구 데이터 조회 없음) |
| **Azure MCP `pricing`** | (선택) 단가 비교 보조 — 실비용 조회 도구 아님 |

---

#### 09.3 실비용 스킬·cost-reports

과거 초안에 있던 **`/cost-report` 스킬·`.claude/cost-reports/`** 는 **본 저장소에서 제거**되었다. 실비용 리포트가 필요하면 Azure Portal·별도 FinOps 프로세스를 사용한다.

---

#### 09.4 PostHook (현행: 안내 중심)

실제 레포는 **`post-apply-snapshot.sh`** 가 `terraform apply` 성공 시 `memory/terraform_state.md` 를 갱신하고, **예상 비용은 `/tf-plan`의 infracost를 참고하라는 한 줄 안내**와 Miro 권고를 출력한다.  
`post-deploy-full.sh` + `az consumption` 같은 **자동 실비용 조회 스크립트는 사용하지 않는다.**

---

#### 09.5 프롬프트 예시 (예상 비용·최적화)

```
# plan 기준 예상 비용
"/tf-plan dev 돌리고 infracost 결과까지 요약해줘"

# SKU 점검
"이번 plan에서 cost-optimizer 관점으로 VM SKU 다운그레이드 여지 있어?"

# (실청구는 범위 밖)
# → "이번 달 청구액" 같은 요청은 이 교육 범위에서 자동화하지 않음
```

---

#### 09.6 디렉토리 구조 (cc_edu)

```
.claude/
├── agents/
│   ├── terraform-reviewer/
│   ├── plan-validator/
│   ├── cost-optimizer/
│   └── azure-validator/
├── skills/
│   ├── tf-init/ · tf-plan/ · tf-apply/ · tf-destroy/
│   ├── tf-validate/ · miro-update/ · env-diff/
├── scripts/
│   └── memory-dir.sh              # ~/.claude/projects/…/memory 경로 출력
├── hooks/
│   ├── pre-destroy-guard.sh · post-apply-snapshot.sh · …
```

에이전트 산출물·apply 후 state 요약은 `bash .claude/scripts/memory-dir.sh` 가 가리키는 `~/.claude/projects/<slug>/memory/` 에 저장한다.

> **참고:** infracost — https://www.infracost.io/

---

### Module 10 — 실전 워크플로우

#### 10.1 전체 파이프라인

```
1. 요구사항 입력
   └─ "Hub-Spoke 구조로 dev 환경 VNet 배포해줘"

2. 코드 작성 (Terraform MCP + GitHub MCP)
   └─ registry_search → validate + fmt
   └─ terraform-reviewer (선택)

3. 비용 예측 (예상만 — infracost)
   └─ /tf-plan dev → tfplan + infracost breakdown + cost-optimizer(병렬)
   └─ 실청구 조회 없음

4. 배포
   └─ PreHook: destroy 가드 등
   └─ /tf-apply dev → Bash terraform apply tfplan (MCP apply는 deny)

5. 배포 후 (PostHook)
   └─ post-apply-snapshot: memory/terraform_state.md 갱신 + infracost·Miro 안내 stdout
   └─ azure-validator

6. 시각화 (선택)
   └─ /miro-update dev
```

---

#### 10.2 멀티 환경 관리

```bash
claude "/tf-init dev"
claude "/tf-plan dev"      # infracost 예상 비용 포함
claude "/tf-apply dev"
claude "/miro-update dev"  # 필요 시

# 환경별 plan 예상 비교 (infracost — 실청구 아님)
claude "/tf-plan staging 후 infracost만 dev와 숫자 비교해줘"
```

---

#### 10.3 트러블슈팅 패턴

| 상황 | 활용 MCP | Claude Code 프롬프트 예시 |
|------|---------|------------------------|
| terraform apply 에러 | Terraform MCP | "에러 메시지 분석하고 수정 코드 제안해줘" |
| Private Endpoint DNS 오류 | Azure MCP + Terraform MCP | "Private DNS Zone 연결 상태 확인해줘" |
| VNet Peering 실패 | Terraform MCP | "Peering 의존성 순서 검토해줘" |
| 예상 비용 이상 (plan) | infracost + cost-optimizer | "이번 tfplan infracost가 전주 대비 튀는 리소스만 짚어줘" |
| tfstate 잠금 | Azure MCP | "Storage Account Blob 잠금 해제 방법 알려줘" |
| 리소스 drift 감지 | Terraform MCP + Azure MCP | "tfstate와 실제 Azure 리소스 상태 차이 비교해줘" |
| 아키텍처 문서 최신화 | Miro MCP + Terraform MCP | "현재 state 기준으로 Miro 다이어그램 전체 재생성해줘" |

---

#### 10.4 팀 협업 설정 — git 공유 파일 분리

| 파일 | git 공유 | 용도 |
|------|---------|------|
| `CLAUDE.md` | ✅ | 팀 공통 프로젝트 지시 + MCP 활용 규칙 |
| `.claude/settings.json` | ✅ | 팀 공통 설정 + Hooks + 권한 |
| `.mcp.json` | ✅ | MCP 서버 4종 설정 (토큰 제외) |
| `.claude/skills/` | ✅ | tf-init/plan/apply/destroy/tf-validate/miro-update/env-diff |
| `.claude/agents/` | ✅ | terraform-reviewer/plan-validator/cost-optimizer/azure-validator |
| `.claudeignore` | ✅ | 무시 패턴 |
| `.claude/settings.local.json` | ❌ | 개인 오버라이드 |
| `.env` | ❌ | Azure/Miro 토큰 |
| `terraform.tfvars` | ❌ | 환경별 실제 값 |
| `~/.claude/projects/<slug>/memory/` | ❌ | plan 검증 JSON·apply 후 state 요약 (레포 밖) |

---

#### 10.5 권장 초기 셋업 순서

```bash
# ── 1단계: Claude Code 설치 ──
npm install -g @anthropic-ai/claude-code
claude auth login

# ── 2단계: 프로젝트 초기화 ──
mkdir terraform-azure-project && cd terraform-azure-project
git init
claude /init     # CLAUDE.md 자동 생성

# ── 3단계: MCP 4종 등록 ──
claude mcp add --transport stdio terraform -- npx -y @hashicorp/terraform-mcp-server
claude mcp add --transport stdio azure    -- npx -y @azure/mcp-server
claude mcp add --transport http  github      https://api.githubcopilot.com/mcp/
claude mcp add --transport stdio miro     -- npx -y @mirohq/mcp-server
claude mcp list   # 4개 확인

# ── 4단계: 디렉토리 구조 생성 ──
mkdir -p .claude/{skills,agents,hooks,scripts}
mkdir -p .claude/skills/{tf-init,tf-plan,tf-apply,tf-destroy,tf-validate,miro-update,env-diff}
mkdir -p .claude/agents/{terraform-reviewer,plan-validator,cost-optimizer,azure-validator}

# ── 5단계: Azure 백엔드 인프라 생성 ──
bash scripts/create-backend.sh

# ── 6단계: 첫 번째 배포 ──
claude "/tf-init dev"
claude "/tf-plan dev"          # 예상 비용 포함 출력
claude "/tf-apply dev"         # PostHook 자동 실행

# ── 7단계: 결과 확인 ──
claude "/miro-update dev"
# 예상 비용은 이미 /tf-plan의 infracost로 확인함
```

---

## 부록 — 참고 자료

| 항목 | URL |
|------|-----|
| Claude Code 공식 문서 | https://docs.anthropic.com/en/docs/claude-code |
| Terraform Azure Provider | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs |
| **Terraform MCP Server** | https://github.com/hashicorp/terraform-mcp-server |
| Azure MCP Server | https://github.com/Azure/azure-mcp |
| Miro Developer Docs | https://developers.miro.com/docs |
| Miro MCP Server | https://github.com/miroapp/mcp-server |
| Azure Pricing API | https://prices.azure.com/api/retail/prices (참고 — infracost가 활용) |
| infracost | https://www.infracost.io/ |
| tflint | https://github.com/terraform-linters/tflint |
| checkov | https://www.checkov.io |
| Azure Hub-Spoke 아키텍처 | https://learn.microsoft.com/ko-kr/azure/architecture/networking/architecture/hub-spoke |

---

> **문서 버전:** v2.2
> **주요 변경:** Module 09–10·부록을 **infracost 예상 비용만**·**실비용/cost-report 제거** 기준으로 정리. Phase / Module 01 형식 유지
> **작성 기준:** Claude Code 가이드 문서 (첨부) + Anthropic 공식 문서 + Azure/Miro/Terraform 공식 문서
> **대상 독자:** KT AX Engineering Team — Azure 인프라 아키텍트
