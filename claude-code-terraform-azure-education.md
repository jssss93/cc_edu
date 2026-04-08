# Claude Code × Terraform × Azure 교육자료

> **최종 목표:** Claude Code를 활용하여 Terraform으로 Azure 리소스를 자동 배포하고, Miro MCP로 아키텍처 다이어그램을 자동 생성하며, 배포 비용까지 자동으로 산출하는 완전 자동화 환경을 셋업한다.

---

## 목차

1. [Module 1 — Claude Code 기초](#module-1--claude-code-기초)
2. [Module 2 — 프로젝트 설정](#module-2--프로젝트-설정)
3. [Module 3 — MCP Server 연동](#module-3--mcp-server-연동)
4. [Module 4 — MCP 적극 활용 전략](#module-4--mcp-적극-활용-전략)
5. [Module 5 — Hooks & 자동화](#module-5--hooks--자동화)
6. [Module 6 — Skills & Agents 구성](#module-6--skills--agents-구성)
7. [Module 7 — Azure Terraform 환경 셋업 실습](#module-7--azure-terraform-환경-셋업-실습)
8. [Module 8 — Miro MCP 아키텍처 자동화](#module-8--miro-mcp-아키텍처-자동화)
9. [Module 9 — 비용 계산 자동화](#module-9--비용-계산-자동화)
10. [Module 10 — 실전 워크플로우](#module-10--실전-워크플로우)

---

## Module 1 — Claude Code 기초

### 1.1 Claude Code란?

Claude Code는 터미널 기반의 AI 코딩 에이전트로, 일반 Claude와 달리 **파일 시스템 접근, 명령어 실행, MCP 도구 연동**이 가능하다.

| 구분 | 일반 Claude (claude.ai) | Claude Code |
|------|------------------------|-------------|
| 파일 읽기/쓰기 | ❌ | ✅ |
| 터미널 명령 실행 | ❌ | ✅ |
| MCP 도구 연동 | 제한적 | ✅ 완전 지원 |
| 프로젝트 컨텍스트 유지 | ❌ | ✅ CLAUDE.md |
| 세션 간 기억 | ❌ | ✅ Memory 시스템 |

### 1.2 설치 및 초기 설정

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

### 1.3 기본 UI 구조 및 키보드 단축키

| 키 | 동작 |
|----|------|
| `Enter` | 메시지 전송 |
| `Shift+Tab` | 모드 전환 (default ↔ acceptEdits) |
| `Escape` | 취소/중단 |
| `Ctrl+T` | 태스크 목록 토글 |
| `Ctrl+R` | 히스토리 검색 |
| `Ctrl+C` | 인터럽트 |

### 1.4 권한 모드 이해

| 모드 | 설명 | Terraform 작업 시 활용 |
|------|------|----------------------|
| `default` | 도구 사용 시 승인 요청 | 초기 학습 단계 |
| `acceptEdits` | 파일 편집 자동 승인 | 코드 작성 단계 |
| `plan` | 읽기 전용 (분석만) | `terraform plan` 검토 단계 |
| `dontAsk` | 사전 허용된 것만 실행 | CI/CD 자동화 |
| `bypassPermissions` | 모든 권한 생략 | 격리 환경 전용 |

> **출처:** Anthropic Claude Code 공식 문서 / 첨부 가이드 문서

---

## Module 2 — 프로젝트 설정

### 2.1 디렉토리 구조

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

### 2.2 CLAUDE.md 작성 — Terraform/Azure 프로젝트

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

### 2.3 Settings.json 구성

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

### 2.4 .claudeignore 설정

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

## Module 3 — MCP Server 연동

### 3.1 MCP 전체 아키텍처

MCP(Model Context Protocol)는 Claude Code가 외부 도구/서비스와 통신하는 표준 프로토콜이다. 이 프로젝트에서는 **4가지 MCP**를 조합하여 코드 생성부터 배포, 시각화, 비용 산출까지 완전 자동화한다.

```
Claude Code
    │
    ├── Terraform MCP     → tf 파일 분석/검증/상태 조회 (핵심)
    ├── Azure MCP         → Azure 리소스 실시간 조회/관리/비용 조회
    ├── GitHub MCP        → Terraform 코드 PR/커밋/버전 관리
    └── Miro MCP          → 아키텍처 다이어그램 자동 생성/업데이트
```

| MCP | 주요 역할 | 연동 시점 |
|-----|----------|----------|
| **Terraform MCP** | plan 분석, state 조회, 모듈 검색 | 코드 작성 ~ 배포 전 |
| **Azure MCP** | 리소스 상태 확인, 비용 조회, 구독 관리 | 배포 중 ~ 배포 후 |
| **GitHub MCP** | 코드 리뷰 PR, 브랜치 관리, Actions 트리거 | 코드 작성 ~ 배포 전 |
| **Miro MCP** | 아키텍처 다이어그램 자동 렌더링 | 배포 완료 후 |

---

### 3.2 Terraform MCP 상세

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

### 3.3 Azure MCP 상세

#### 주요 제공 기능

| 기능 | 설명 |
|------|------|
| `azure_resource_list` | 구독/리소스그룹 내 리소스 목록 조회 |
| `azure_resource_show` | 특정 리소스 상세 속성 조회 |
| `azure_cost_query` | 비용 분석 (기간/리소스별) |
| `azure_monitor_metrics` | Azure Monitor 메트릭 조회 |
| `azure_network_topology` | 네트워크 토폴로지 조회 |

#### 활용 프롬프트 예시

```
# 배포 후 실제 리소스 상태 확인
"dev 리소스 그룹에 배포된 전체 리소스 목록과 상태 확인해줘"
→ Azure MCP: azure_resource_list(resource_group="rg-project-dev-krc")

# 비용 조회
"이번 달 dev 환경 비용 서비스별로 분류해서 보여줘"
→ Azure MCP: azure_cost_query(timeframe="MonthToDate", group_by="ServiceName")

# 네트워크 연결 검증
"Hub VNet과 Spoke VNet의 Peering 상태 확인해줘"
→ Azure MCP: azure_network_topology(subscription_id="...")
```

---

### 3.4 .mcp.json 전체 구성

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

### 3.5 MCP 서버 일괄 등록 (CLI)

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

### 3.6 환경 변수 설정

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

## Module 4 — MCP 적극 활용 전략

### 4.1 MCP 조합 활용 원칙

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

### 4.2 시나리오별 MCP 활용 패턴

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

#### 시나리오 4: 비용 이상 감지 → 원인 분석 → 최적화 제안

```
사용자: "이번 달 Azure 비용이 갑자기 올랐는데 원인 분석해줘"

Claude Code 동작:
  [Azure MCP] azure_cost_query(timeframe="MonthToDate", group_by="ServiceName")
      → 서비스별 비용 증가 항목 파악
  [Azure MCP] azure_cost_query(timeframe="MonthToDate", group_by="ResourceName")
      → 비용 급증 리소스 특정
  [Terraform MCP] terraform_state_show("<해당 리소스>")
      → 리소스 SKU, 크기, 설정 확인
  [Azure MCP] azure_monitor_metrics(resource="<해당 리소스>")
      → 실제 사용률 메트릭 확인
  → 원인 분석 + SKU 최적화 Terraform 코드 제안
```

---

### 4.3 CLAUDE.md에 MCP 활용 지침 추가

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
- Azure MCP cost query를 통해 실제 청구 데이터 기반으로 분석
- plan 단계에서는 추가될 리소스의 예상 비용도 함께 제시

### 아키텍처 변경 시
- 변경 완료 후 Miro MCP로 다이어그램 자동 업데이트
- 변경 내역은 GitHub MCP로 커밋 메시지에 기록
```

---

### 4.4 MCP 권한 설정 (settings.json)

```json
{
  "permissions": {
    "allow": [
      "mcp__terraform__terraform_plan",
      "mcp__terraform__terraform_validate",
      "mcp__terraform__terraform_fmt",
      "mcp__terraform__terraform_state_list",
      "mcp__terraform__terraform_state_show",
      "mcp__terraform__terraform_output",
      "mcp__terraform__registry_search",
      "mcp__terraform__registry_module_details",
      "mcp__azure__azure_resource_list",
      "mcp__azure__azure_resource_show",
      "mcp__azure__azure_cost_query",
      "mcp__azure__azure_network_topology",
      "mcp__azure__azure_monitor_metrics",
      "mcp__github__get_file_contents",
      "mcp__github__create_pull_request",
      "mcp__github__create_branch",
      "mcp__github__push_files",
      "mcp__miro__create_board_item",
      "mcp__miro__update_board_item",
      "mcp__miro__get_board_items"
    ],
    "deny": [
      "mcp__terraform__terraform_apply",
      "mcp__terraform__terraform_destroy",
      "mcp__azure__azure_resource_delete"
    ]
  }
}
```

> **⚠️ 참고:** `terraform_apply`와 `terraform_destroy`는 `deny`로 설정하여 반드시 `/tf-apply`, `/tf-destroy` 스킬을 통해 사용자 확인 후 실행하도록 강제한다.

> **출처:** 첨부 가이드 문서 §6 MCP Servers / §12 권한 시스템 / Terraform MCP Server GitHub (https://github.com/hashicorp/terraform-mcp-server)

---

## Module 5 — Hooks & 자동화

### 5.1 Hooks 개념

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

### 5.2 settings.json — Hooks 설정

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

### 5.3 pre-terraform.sh — 배포 전 검증

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

### 5.4 post-terraform.sh — 배포 후 상태 확인 (기본)

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
echo "→ 비용 계산: /cost-report 스킬 실행"
echo "→ 아키텍처 시각화: /miro-update 스킬 실행"
exit 0
```

> **출처:** 첨부 가이드 문서 §5 Hooks

---

## Module 6 — Skills & Agents 구성

### 6.1 Terraform 핵심 스킬

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

### 6.2 Subagent 구성

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

## Module 7 — Azure Terraform 환경 셋업 실습

### 7.1 Azure 인증 설정

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

### 7.2 Terraform Backend — Azure Storage Account 생성

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

### 7.3 Hub-Spoke 기본 구조 생성 실습

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

### 7.4 Plan Mode 활용

```bash
# Plan Mode로 진입하여 변경사항만 분석
claude --permission-mode plan

# 또는 대화 중
/plan
"Hub VNet에 새로운 Subnet을 추가하면 어떤 리소스가 영향을 받아?"
/exitplan
```

### 7.5 Memory 시스템 활용

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

## Module 8 — Miro MCP 아키텍처 자동화

### 8.1 Miro MCP 개요

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

### 8.2 Miro 토큰 발급

```
1. https://miro.com/app/settings/user-profile/apps 접속
2. "Create new app" 클릭
3. App 이름: "Claude Code Terraform Visualizer"
4. 권한: boards:read, boards:write 선택
5. Access Token 복사 → MIRO_ACCESS_TOKEN 환경변수 설정
6. 대상 보드 URL에서 Board ID 추출:
   https://miro.com/app/board/uXjVI_XXXXXXX=/ → uXjVI_XXXXXXX=
```

### 8.3 `/miro-update` 스킬 작성

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

### 8.4 Miro MCP 활용 프롬프트 예시

```
# 배포 후 자동 아키텍처 생성
/miro-update dev

# 수동으로 요청하는 경우
"현재 terraform state에 있는 리소스를 분석해서
 Miro 보드에 Hub-Spoke 아키텍처 다이어그램을 그려줘.
 Hub VNet과 Spoke VNet의 연결관계, 각 Subnet 내 리소스,
 NSG 규칙도 함께 표시해줘"
```

### 8.5 Miro 다이어그램 구성 요소

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

### 8.6 자동화 통합 — PostToolUse Hook 확장

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
echo "  1. /cost-report  — 비용 산출"
echo "  2. /miro-update  — 아키텍처 다이어그램 업데이트"

exit 0
```

> **출처:** Miro Developer Documentation (https://developers.miro.com/docs/rest-api-reference) / 첨부 가이드 문서 §3 Skills / §5 Hooks

---

## Module 9 — 비용 계산 자동화

### 9.1 비용 자동화 전략 개요

배포 비용은 **2단계**로 자동화한다.

```
[사전 비용 예측]                    [사후 비용 확인]
terraform plan 단계                 terraform apply 완료 후
        │                                   │
        ▼                                   ▼
Terraform MCP                       Azure MCP
terraform_plan() 분석               azure_cost_query()
추가될 리소스 목록 파악              실제 청구 데이터 조회
        │                                   │
        ▼                                   ▼
Azure Pricing API                   비용 리포트 생성
리소스별 단가 조회                  이상 비용 알림
        │                                   │
        ▼                                   ▼
예상 월 비용 리포트                  Miro 보드에 비용 레이어 추가
```

---

### 9.2 `cost-estimator` 에이전트

배포 **전** plan 결과를 분석하여 예상 비용을 산출하는 전문 에이전트다.

```
.claude/agents/cost-estimator/
└── AGENT.md
```

**AGENT.md:**

```yaml
---
name: cost-estimator
description: >
  Terraform plan 결과를 분석하여 Azure 리소스 예상 월 비용을 산출한다.
  /tf-plan 실행 후 자동으로 호출되거나, 수동으로 호출 가능.
tools: Bash, Read, mcp__terraform__terraform_plan, mcp__terraform__terraform_state_list, mcp__azure__azure_cost_query
model: sonnet
maxTurns: 20
---

Azure 비용 전문 아키텍트로서 다음을 수행한다.

## 분석 순서

### 1. 변경 리소스 파악
- Terraform MCP로 plan 결과 조회
- 추가(+), 변경(~), 삭제(-) 리소스 분류

### 2. 현재 비용 조회
- Azure MCP: azure_cost_query(timeframe="MonthToDate")
- 현재 월 누적 비용 파악

### 3. 신규 리소스 단가 조회
아래 Azure Pricing REST API를 Bash로 호출하여 단가 조회:
```bash
curl -s "https://prices.azure.com/api/retail/prices?\
\$filter=armRegionName eq 'koreacentral' \
and serviceName eq '{SERVICE_NAME}' \
and skuName eq '{SKU_NAME}'" | jq '.Items[0].retailPrice'
```

### 4. 월 예상 비용 계산
- 리소스별 단가 × 예상 사용 시간(월 730시간 기준)
- 데이터 전송, 스토리지 트랜잭션 등 부가 비용 포함

### 5. 비용 리포트 출력 형식

다음 형식으로 한국어 리포트를 작성한다:

---
## 💰 Azure 배포 예상 비용 리포트

### 변경 요약
| 구분 | 리소스 수 |
|------|---------|
| 신규 추가 | N개 |
| 변경 | N개 |
| 삭제 | N개 |

### 신규 리소스 예상 비용 (월)
| 리소스명 | 유형 | SKU | 단가/시간 | 월 예상 비용 |
|---------|------|-----|---------|------------|
| ... | ... | ... | $X.XX | $XX.XX |

### 현재 환경 월 비용: $XXX.XX
### 변경 후 예상 월 비용: $XXX.XX
### 변경으로 인한 증감: +$XX.XX (+X%)

### ⚠️ 비용 최적화 제안
- [있는 경우만 작성]
---
```

---

### 9.3 `/cost-report` 스킬 — 배포 후 실비용 리포트

```
.claude/skills/cost-report/
├── SKILL.md
└── cost-template.md
```

**SKILL.md:**

```yaml
---
name: cost-report
description: 배포된 Azure 리소스의 실제 비용을 Azure MCP로 조회하여 리포트 생성
argument-hint: "[환경명: dev|staging|prod] [기간: today|week|month]"
allowed-tools: Bash, Read, Write, mcp__azure__azure_cost_query, mcp__terraform__terraform_state_list
context: fork
agent: general-purpose
---

$0 환경의 $1 기간 실제 Azure 비용을 조회하고 리포트를 생성한다.

## 실행 순서

1. Azure MCP로 비용 데이터 조회
   - azure_cost_query(timeframe="$1", resource_group="rg-project-$0-krc")
   - group_by: ServiceName, ResourceName 두 가지로 조회

2. Terraform MCP로 현재 배포 리소스 목록 조회
   - terraform_state_list()로 리소스 수 파악

3. 비용 분석 및 리포트 생성
   - 서비스별 비용 TOP 5
   - 리소스별 비용 TOP 10
   - 전일/전주 대비 증감률
   - 월말 예상 총 비용 (현재 소비 기반 프로젝션)

4. 비용 이상 감지 (임계값 초과 시 경고)
   - 일 비용 $50 초과: ⚠️ 경고
   - 월 비용 $1,000 초과: 🚨 알림

5. 리포트를 .claude/cost-reports/{날짜}-{환경}.md 로 저장

6. (선택) Miro 보드에 비용 요약 스티커 추가
```

---

### 9.4 PostToolUse Hook — 비용 자동 트리거

`terraform apply` 완료 후 비용 확인을 **자동으로 실행**하도록 Hook을 확장한다.

**settings.json 업데이트:**

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
      },
      {
        "matcher": "mcp__terraform__terraform_apply",
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
            "command": ".claude/hooks/post-deploy-full.sh",
            "timeout": 180
          }
        ]
      }
    ]
  }
}
```

**post-deploy-full.sh — 비용 + 아키텍처 통합 PostHook:**

```bash
#!/bin/bash
# .claude/hooks/post-deploy-full.sh
# terraform apply 성공 후 — 비용 계산 + Miro 업데이트 통합 실행

INPUT=$(cat)
EXIT_CODE=$(echo "$INPUT" | jq -r '.exit_code // 0')

# apply 실패 시 중단
if [ "$EXIT_CODE" != "0" ]; then
  echo "⚠️ terraform apply 실패 — post-hook 건너뜀"
  exit 0
fi

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
ENV=${TF_VAR_environment:-"unknown"}

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║     🚀 배포 완료 — 자동 후처리 시작      ║"
echo "╚══════════════════════════════════════════╝"
echo "  환경: ${ENV}  |  시각: ${TIMESTAMP}"
echo ""

# ── Step 1: 리소스 현황 스냅샷 ──
echo "📋 [1/4] 리소스 현황 저장 중..."
terraform state list > .claude/snapshots/state-${TIMESTAMP//[:/ ]/-}.txt 2>/dev/null || true
terraform output -json > .claude/last-output.json 2>/dev/null || true
RESOURCE_COUNT=$(terraform state list 2>/dev/null | wc -l | tr -d ' ')
echo "  ✅ 총 ${RESOURCE_COUNT}개 리소스 확인"

# ── Step 2: Azure 비용 빠른 조회 (오늘 기준) ──
echo ""
echo "💰 [2/4] 오늘 비용 조회 중..."
if command -v az &>/dev/null; then
  TODAY_COST=$(az consumption usage list \
    --start-date $(date +%Y-%m-%d) \
    --end-date $(date +%Y-%m-%d) \
    --query "sum([].pretaxCost)" \
    --output tsv 2>/dev/null || echo "조회 실패")
  echo "  ✅ 오늘 비용: \$${TODAY_COST:-N/A}"

  MONTH_COST=$(az consumption usage list \
    --start-date $(date +%Y-%m-01) \
    --end-date $(date +%Y-%m-%d) \
    --query "sum([].pretaxCost)" \
    --output tsv 2>/dev/null || echo "조회 실패")
  echo "  ✅ 이번 달 누적: \$${MONTH_COST:-N/A}"

  # 비용 임계값 경고
  if (( $(echo "${MONTH_COST:-0} > 1000" | bc -l 2>/dev/null || echo 0) )); then
    echo "  🚨 월 비용 \$1,000 초과! /cost-report로 상세 분석 필요"
  fi
else
  echo "  ⚠️ Azure CLI 미설치 — 비용 조회 건너뜀"
fi

# ── Step 3: 비용 리포트 생성 요청 메시지 출력 ──
echo ""
echo "📊 [3/4] 상세 비용 리포트..."
echo "  → 상세 리포트: /cost-report ${ENV} month 실행 권장"

# ── Step 4: Miro 업데이트 알림 ──
echo ""
echo "🎨 [4/4] 아키텍처 다이어그램..."
echo "  → Miro 업데이트: /miro-update ${ENV} 실행 권장"

# ── 완료 요약 ──
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 배포 후처리 완료"
echo "   리소스: ${RESOURCE_COUNT}개  |  오늘 비용: \$${TODAY_COST:-N/A}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit 0
```

---

### 9.5 비용 관련 Claude Code 프롬프트 예시

```
# plan 전 예상 비용 확인 (cost-estimator 에이전트 자동 호출)
"dev 환경에 AKS 클러스터 추가하면 비용이 얼마나 늘어?"

# 배포 후 실비용 리포트
/cost-report dev month

# 특정 기간 비용 분석
"지난 주 staging 환경 비용을 서비스별로 분석하고
 전주 대비 증가한 항목 원인 파악해줘"

# 비용 최적화 제안
"현재 dev 환경에서 비용 절감할 수 있는 리소스 찾아줘.
 SKU 다운그레이드 또는 스케줄 기반 자동 정지 방안도 포함해줘"

# 멀티 환경 비용 비교
"dev / staging / prod 3개 환경 이번 달 비용 비교 테이블 만들어줘"
```

---

### 9.6 디렉토리 구조 업데이트

```
.claude/
├── agents/
│   ├── terraform-reviewer/   # 코드 리뷰
│   ├── azure-validator/      # 배포 검증
│   └── cost-estimator/       # 비용 예측 ← 신규
├── skills/
│   ├── tf-init/
│   ├── tf-plan/
│   ├── tf-apply/
│   ├── tf-destroy/
│   ├── miro-update/
│   └── cost-report/          # 비용 리포트 ← 신규
├── hooks/
│   ├── pre-terraform.sh
│   └── post-deploy-full.sh   # 비용+Miro 통합 ← 신규
└── snapshots/                # 배포 시점 state 스냅샷 ← 신규
    └── state-YYYY-MM-DD.txt
```

> **출처:** Azure Consumption REST API (https://learn.microsoft.com/ko-kr/rest/api/consumption/) / Azure Pricing API (https://prices.azure.com/api/retail/prices) / 첨부 가이드 문서 §3 Skills / §5 Hooks / §15 Subagent 시스템

---

## Module 10 — 실전 워크플로우

### 10.1 전체 파이프라인

```
1. 요구사항 입력
   └─ "Hub-Spoke 구조로 dev 환경 VNet 배포해줘"

2. 코드 작성 (Terraform MCP + GitHub MCP)
   └─ registry_search() → 검증된 모듈 검색
   └─ terraform_validate() + terraform_fmt() 자동 실행
   └─ terraform-reviewer 에이전트 코드 리뷰

3. 비용 예측 (cost-estimator 에이전트)
   └─ terraform_plan() → 추가 리소스 분석
   └─ Azure Pricing API → 예상 월 비용 산출
   └─ 사용자 비용 확인 후 진행 여부 결정

4. 배포 (PreToolUse Hook → Terraform MCP)
   └─ tflint + checkov 자동 검증 (pre-terraform.sh)
   └─ /tf-plan dev → 변경사항 최종 검토
   └─ /tf-apply dev → 배포 실행

5. 배포 후 자동화 (PostToolUse Hook)
   └─ state 스냅샷 저장
   └─ 오늘/이번달 Azure 비용 즉시 조회
   └─ azure-validator 에이전트 상태 검증

6. 비용 상세 리포트 (Azure MCP)
   └─ /cost-report dev month
   └─ 서비스별/리소스별 비용 분석
   └─ 이상 비용 감지 및 최적화 제안

7. 아키텍처 시각화 (Miro MCP)
   └─ /miro-update dev
   └─ Miro 보드에 Hub-Spoke 다이어그램 자동 생성
   └─ 비용 레이어 오버레이 추가
```

---

### 10.2 멀티 환경 관리

```bash
# dev 환경 전체 자동화
claude "/tf-init dev"
claude "/tf-plan dev"           # 비용 예측 포함
claude "/tf-apply dev"          # PostHook으로 비용+상태 자동 확인
claude "/cost-report dev month"
claude "/miro-update dev"

# staging 프로모션
claude "dev 환경 tfvars 기반으로 staging 환경 구성 생성하고
        배포 전 예상 비용과 dev와의 비용 차이도 알려줘"

# 멀티 환경 비용 비교
claude "dev / staging / prod 이번 달 비용 비교 테이블 만들어줘"
```

---

### 10.3 트러블슈팅 패턴

| 상황 | 활용 MCP | Claude Code 프롬프트 예시 |
|------|---------|------------------------|
| terraform apply 에러 | Terraform MCP | "에러 메시지 분석하고 수정 코드 제안해줘" |
| Private Endpoint DNS 오류 | Azure MCP + Terraform MCP | "Private DNS Zone 연결 상태 확인해줘" |
| VNet Peering 실패 | Terraform MCP | "Peering 의존성 순서 검토해줘" |
| 비용 이상 급증 | Azure MCP | "이번 주 비용 급증 리소스 특정하고 원인 분석해줘" |
| tfstate 잠금 | Azure MCP | "Storage Account Blob 잠금 해제 방법 알려줘" |
| 리소스 drift 감지 | Terraform MCP + Azure MCP | "tfstate와 실제 Azure 리소스 상태 차이 비교해줘" |
| 아키텍처 문서 최신화 | Miro MCP + Terraform MCP | "현재 state 기준으로 Miro 다이어그램 전체 재생성해줘" |

---

### 10.4 팀 협업 설정 — git 공유 파일 분리

| 파일 | git 공유 | 용도 |
|------|---------|------|
| `CLAUDE.md` | ✅ | 팀 공통 프로젝트 지시 + MCP 활용 규칙 |
| `.claude/settings.json` | ✅ | 팀 공통 설정 + Hooks + 권한 |
| `.mcp.json` | ✅ | MCP 서버 4종 설정 (토큰 제외) |
| `.claude/skills/` | ✅ | tf-init/plan/apply/destroy/cost-report/miro-update |
| `.claude/agents/` | ✅ | terraform-reviewer/azure-validator/cost-estimator |
| `.claudeignore` | ✅ | 무시 패턴 |
| `.claude/settings.local.json` | ❌ | 개인 오버라이드 |
| `.env` | ❌ | Azure/Miro 토큰 |
| `terraform.tfvars` | ❌ | 환경별 실제 값 |
| `.claude/snapshots/` | ❌ | 배포 시점 state 스냅샷 |
| `.claude/cost-reports/` | ❌ | 비용 리포트 히스토리 |

---

### 10.5 권장 초기 셋업 순서

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
mkdir -p .claude/{skills,agents,hooks,snapshots,cost-reports}
mkdir -p .claude/skills/{tf-init,tf-plan,tf-apply,tf-destroy,miro-update,cost-report}
mkdir -p .claude/agents/{terraform-reviewer,azure-validator,cost-estimator}

# ── 5단계: Azure 백엔드 인프라 생성 ──
bash scripts/create-backend.sh

# ── 6단계: 첫 번째 배포 ──
claude "/tf-init dev"
claude "/tf-plan dev"          # 예상 비용 포함 출력
claude "/tf-apply dev"         # PostHook 자동 실행

# ── 7단계: 결과 확인 ──
claude "/cost-report dev today"
claude "/miro-update dev"
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
| Azure Pricing API | https://prices.azure.com/api/retail/prices |
| Azure Consumption REST API | https://learn.microsoft.com/ko-kr/rest/api/consumption/ |
| Azure Cost Management | https://learn.microsoft.com/ko-kr/azure/cost-management-billing/ |
| tflint | https://github.com/terraform-linters/tflint |
| checkov | https://www.checkov.io |
| Azure Hub-Spoke 아키텍처 | https://learn.microsoft.com/ko-kr/azure/architecture/networking/architecture/hub-spoke |

---

> **문서 버전:** v2.0
> **주요 변경:** Terraform MCP 추가, MCP 적극 활용 전략(Module 4) 신설, 비용 계산 자동화(Module 9) 신설, PostHook 통합 확장
> **작성 기준:** Claude Code 가이드 문서 (첨부) + Anthropic 공식 문서 + Azure/Miro/Terraform 공식 문서
> **대상 독자:** KT AX Engineering Team — Azure 인프라 아키텍트
