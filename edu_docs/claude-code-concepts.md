# Claude Code 핵심 개념 교육 자료

> **이 문서의 목적**: Claude Code의 핵심 개념(용어 정의, 유사 개념 간 차이점)을 설명하고,  
> 이 프로젝트(Azure Hub-Spoke Terraform)에서 어떻게 실제로 적용되었는지를 보여준다.

---

## 목차

1. [Claude Code 란?](#1-claude-code-란)
2. [핵심 개념 용어 정의](#2-핵심-개념-용어-정의)
   - CLAUDE.md
   - settings.json
   - Hooks
   - Skills
   - Agents (Sub-agents)
   - MCP Servers
   - Permissions
   - .claudeignore
   - Memory
3. [헷갈리는 개념 쌍 비교](#3-헷갈리는-개념-쌍-비교)
   - CLAUDE.md vs rules/ vs settings.json
   - Hooks vs Skills
   - Skills vs Agents
   - MCP Tools vs 직접 CLI 호출
4. [내장 플러그인](#4-내장-플러그인)
   - Skill Creator
   - Code Review
   - Plugin Market
5. [이 프로젝트 적용 사례](#5-이-프로젝트-적용-사례)
6. [전체 개념 구조도](#6-전체-개념-구조도)

---

## 1. Claude Code 란?

Claude Code는 Anthropic이 만든 **AI 기반 CLI 도구**다. 단순한 챗봇과 다른 점은 다음과 같다.

| 일반 챗봇 | Claude Code |
|-----------|-------------|
| 대화만 가능 | 파일 읽기/편집/생성 가능 |
| 프로젝트 맥락 없음 | 프로젝트 디렉토리 전체 인식 |
| 매번 설명 필요 | CLAUDE.md로 규칙 영구 기억 |
| 외부 도구 연동 불가 | MCP로 Terraform/Azure/Miro 등 연동 |
| 사람이 항상 지시 | Hooks로 자동 트리거 |

쉽게 말하면 Claude Code는 **코드베이스를 이해하는 AI 개발 동료**이며, 이 프로젝트에서는 **Terraform 인프라 자동화 팀원**으로 활용된다.

---

## 2. 핵심 개념 용어 정의

---

### 2.1 CLAUDE.md

**정의**: Claude Code가 프로젝트를 열 때 자동으로 읽는 **지시사항 파일**. Claude에게 "이 프로젝트에서 이렇게 행동해라"를 영구적으로 주입하는 수단이다.

**핵심 특성**:

- 마크다운(`.md`) 형식으로 작성
- 프로젝트 디렉토리 어디에나 위치 가능 (계층 구조, 모두 동시 로드)
- `@파일경로` 문법으로 다른 파일을 인라인 포함(include) 가능
- 모든 대화에 자동으로 컨텍스트로 주입됨

**`@` include 문법**:
```
@terraform/variables.tf         → 해당 파일 내용을 그대로 주입
@.claude/rules/terraform.md     → 다른 md 파일 포함
```
> 이 프로젝트: `cc_edu/CLAUDE.md`가 `@terraform/variables.tf`를 include해  
> Claude가 변수 목록을 별도로 파일을 열지 않아도 자동 인식한다.

**계층 구조**:

```
~/.claude/CLAUDE.md          # 전역 (모든 프로젝트에 적용)
  └── @RTK.md                # 전역 확장 파일 (rtk 도구 사용 규칙)

cc_edu/CLAUDE.md             # 프로젝트 루트 (Azure Terraform 개요)
  └── @terraform/variables.tf  # 변수 정의 파일 참조

cc_edu/.claude/CLAUDE.md     # Claude 설정 폴더 (디렉토리 구조 설명)

cc_edu/terraform/CLAUDE.md   # Terraform 전용 (모듈 구조 안내)
```

> **로딩 규칙**: "모든 계층 동시 로드"가 아니다. 실제 동작은 **"루트는 항상 + 현재 작업 경로 기준 계층 선택 로드"**다.  
> - `~/.claude/CLAUDE.md`, 프로젝트 루트 `CLAUDE.md` → 항상 로드  
> - 하위 디렉토리 `CLAUDE.md` → 현재 작업 중인 파일의 경로 계층에 해당하는 것만 로드  
> - 관계없는 다른 디렉토리의 `CLAUDE.md` → 로드되지 않음  
>
> 예: `terraform/environments/dev/main.tf` 수정 중이면 `terraform/CLAUDE.md`는 로드되지만, 관계없는 다른 폴더의 것은 로드 안 됨.

---

### 2.2 settings.json

**정의**: Claude Code의 **런타임 동작을 제어하는 설정 파일**. "무엇을 허용/차단할지", "훅을 어떻게 연결할지"를 JSON으로 정의한다.

**위치 및 구분**:

| 파일 | 범위 | git 공유 |
|------|------|---------|
| `~/.claude/settings.json` | 전역 (모든 프로젝트) | 개인 설정 |
| `.claude/settings.json` | 프로젝트 공유 설정 | git에 커밋 |
| `.claude/settings.local.json` | 개인 오버라이드 | `.gitignore` 처리 |

> 이 프로젝트: `settings.json`은 팀 공통 설정(훅, 권한), `settings.local.json`은 개인별 추가 설정. `settings.local.json`은 `.claudeignore`에 포함되어 Claude가 직접 읽지 못하게 막는다.

**주요 항목**:

```json
{
  "model": "claude-sonnet-4-6",      // 사용할 AI 모델
  "defaultMode": "acceptEdits",      // 기본 권한 모드
  "autoMemoryEnabled": true,         // 자동 기억 활성화
  "permissions": {
    "allow": ["Bash(terraform fmt*)"], // 허용 명령어
    "deny": ["Bash(rm -rf *)"]        // 차단 명령어
  },
  "hooks": {                          // 이벤트 → 쉘 스크립트 연결
    "PreToolUse": [...],
    "PostToolUse": [...],
    "Stop": [...]
  }
}
```

**권한 모드 (defaultMode)**:

| 모드 | 동작 | 적합한 상황 |
|------|------|-------------|
| `default` | 파일 편집/명령 실행 모두 확인 요청 | 처음 사용 시 |
| `acceptEdits` | 파일 편집은 자동 승인, 명령 실행은 확인 | 일반 개발 |
| `bypassPermissions` | 모든 작업 자동 승인 | CI/CD 파이프라인 |

---

### 2.3 Hooks

**정의**: **특정 이벤트 발생 시 자동으로 실행되는 쉘 스크립트**. Claude가 도구를 사용하기 전후, 또는 응답을 완료했을 때 자동으로 트리거된다.

**이벤트 종류**:

| 이벤트 | 시점 | 반환 가능한 액션 |
|--------|------|-----------------|
| `PreToolUse` | 도구 실행 직전 | `block` (차단), `continue` (허용) |
| `PostToolUse` | 도구 실행 직후 | 부가 작업 실행 |
| `Stop` | Claude 응답 완료 후 | 알림, 로깅 등 |
| `Notification` | 허가 요청 시 | 사용자 알림 |

**입출력 메커니즘**:

훅 스크립트는 **stdin으로 JSON을 받고**, **stdout으로 JSON을 반환**한다.

```bash
# stdin으로 들어오는 데이터 (PreToolUse 예시)
{
  "tool_name": "Bash",
  "tool_input": { "command": "terraform destroy -auto-approve" }
}

# 차단 시 stdout 반환
{
  "decision": "block",
  "reason": "/tf-destroy 스킬을 통해 실행하세요."
}

# 허용 시: exit 0 (JSON 반환 불필요)
```

**동작 원리**:
```
사용자 요청
    ↓
Claude가 도구 실행 결정
    ↓
[PreToolUse Hook] stdin으로 도구명/인자 수신
  → exit 0: 허용 / exit 2 + JSON block: 차단
    ↓
도구 실행
    ↓
[PostToolUse Hook] stdin으로 도구 실행 결과 수신 → 후처리
    ↓
Claude 응답 완료
    ↓
[Stop Hook] 알림, 로깅 등
```

---

### 2.4 Skills

**정의**: **사용자가 `/명령어` 형태로 직접 호출하는 커스텀 프롬프트 슬래시 명령어**. 미리 작성된 상세 지시사항을 Claude에게 주입하여 복잡한 작업을 일관되게 수행하게 한다.

**핵심 이해**:

> Skills는 **코드를 실행하는 게 아니라, Claude에게 지시사항을 주입**한다.  
> "이렇게 행동해라"는 프롬프트가 Claude에게 전달되고, Claude가 그 지시대로 행동한다.

**구조**:
```
.claude/skills/
└── tf-plan/
    └── prompt.md    # 슬래시 명령 실행 시 Claude에게 주입되는 지시사항
```

**사용 방법**:
```
사용자: /tf-plan dev
   ↓
prompt.md 내용이 Claude 컨텍스트에 주입됨
   ↓
Claude가 지시사항에 따라 행동:
  1. terraform fmt 실행
  2. checkov 실행
  3. terraform plan 실행
  4. 결과 분석 및 보고
```

---

### 2.5 Agents (Sub-agents)

**정의**: **특정 전문 작업을 독립적으로 수행하는 전문화된 Claude 인스턴스**. 메인 Claude가 필요 시 에이전트를 생성(spawn)하여 특정 역할을 위임한다.

**핵심 이해**:
> Agents는 **메인 Claude의 컨텍스트를 오염시키지 않고** 별도 작업을 처리한다.  
> 메인 Claude → 에이전트 생성 → 작업 수행 → 결과 반환

**구조**:
```
.claude/agents/
└── azure-validator/
    └── prompt.md    # 에이전트의 역할과 행동 지침
```

**에이전트 특성**:
- 고유한 역할 정의 (validator, reviewer, optimizer 등)
- 특정 도구만 사용하도록 제한 가능
- 메인 대화와 별도의 컨텍스트 유지
- 병렬 실행 가능 (여러 에이전트 동시 실행)
- **자동 호출** 또는 **수동 위임** 가능

---

### 2.6 MCP Servers

**정의**: **Model Context Protocol 서버**. Claude Code가 외부 시스템(Azure, Terraform, Miro 등)과 통신하기 위한 표준 인터페이스.

**핵심 이해**:
> MCP는 Claude에게 새로운 "손"을 붙이는 것과 같다.  
> Claude는 기본적으로 파일 읽기/쓰기/명령 실행만 할 수 있지만,  
> MCP를 통해 Azure API 호출, Terraform state 조회, Miro 그리기 등이 가능해진다.

**연결 방식**:
```
Claude Code
    ↓ (MCP 프로토콜)
MCP 서버 프로세스 (npx/node/python 등)
    ↓ (REST API / SDK)
외부 서비스 (Azure, GitHub, Miro...)
```

**설정 위치**: `.mcp.json` (프로젝트 공유) 또는 `~/.claude/mcp.json` (전역)

---

### 2.7 Permissions

**정의**: Claude Code가 실행할 수 있는 **명령어와 도구의 범위를 제어하는 보안 설정**.

**allow/deny 패턴**:

```json
{
  "permissions": {
    "allow": [
      "Bash(terraform fmt*)",        // terraform fmt 계열 허용
      "mcp__azure__*",               // Azure MCP 전체 허용
      "Bash(git status)"             // git status만 허용
    ],
    "deny": [
      "Bash(rm -rf *)",              // 재귀 삭제 차단
      "Bash(az group delete *)"      // Azure 리소스 그룹 삭제 차단
    ]
  }
}
```

**패턴 문법**:

- `*` : 와일드카드 (뒤에 오는 모든 인자 허용)
- `Bash(cmd)` : 특정 bash 명령어
- `mcp__서버__도구명` : MCP 도구 접근

---

### 2.8 .claudeignore

**정의**: Claude Code가 **읽거나 참조하지 말아야 할 파일/디렉토리를 지정**하는 파일. `.gitignore`와 같은 문법이지만, git이 아니라 Claude의 파일 접근을 제한한다.

**역할**:
- 불필요한 파일이 컨텍스트로 로드되는 것을 차단
- 민감한 파일(tfstate, tfvars, 인증서 등)을 Claude로부터 보호
- 토큰 낭비 방지 (캐시 파일, 바이너리 등)

**이 프로젝트 `.claudeignore`**:
```
.terraform/              # 프로바이더 캐시 (대용량, 불필요)
*.tfstate                # state 파일 (민감 정보 포함)
*.tfstate.backup
terraform.tfvars         # 실제 비밀값 (subscription_id 등)
*.tfplan                 # plan 바이너리
.claude/settings.local.json  # 개인 설정
.claude/snapshots/       # 자동 생성 스냅샷
*.pem, *.key             # 인증서/키 파일
```

> `.gitignore`와 `.claudeignore`가 다를 수 있다. git에는 올리되 Claude에게는 보여주지 않아야 하는 파일이 있을 수 있다.

---

### 2.9 Memory

**정의**: Claude Code가 **세션 간 정보를 유지하기 위한 파일 기반 기억 시스템**.

**저장 위치**: `~/.claude/projects/{프로젝트경로}/memory/`

**기억 유형**:

| 유형 | 저장 내용 | 예시 |
|------|-----------|------|
| `user` | 사용자 역할, 선호, 지식 수준 | "DevOps 엔지니어, Go 전문가" |
| `feedback` | 사용자 교정/확인 사항 | "테스트는 실DB 사용, mock 금지" |
| `project` | 진행 중인 작업, 결정 사항 | "3월 배포 freeze 예정" |
| `reference` | 외부 리소스 위치 | "버그는 Linear INFRA 프로젝트에" |

---

## 3. 헷갈리는 개념 쌍 비교

---

### 3.1 CLAUDE.md vs rules/ vs settings.json

세 가지 모두 Claude의 동작을 제어하지만 **목적과 방식이 다르다**.

| 구분 | CLAUDE.md | rules/ (md 파일) | settings.json |
|------|-----------|-----------------|---------------|
| **형식** | 마크다운 | 마크다운 | JSON |
| **목적** | 프로젝트 컨텍스트 전달 | 특정 작업 규칙 정의 | 런타임 동작 설정 |
| **내용** | "이 프로젝트는 무엇인가" | "어떻게 코드를 작성해야 하나" | "무엇을 허용/차단할 것인가" |
| **적용 시점** | 대화 시작 시 자동 로드 | `.claude/rules/`에 두면 **자동 로드** (CLAUDE.md 참조 불필요) | Claude Code 실행 내내 |
| **변경 영향** | 즉시 (다음 대화부터) | 즉시 | 즉시 |

**비유**:
- **CLAUDE.md** = 신입 직원 온보딩 문서 ("우리 팀은 이런 팀이야")
- **rules/** = 코딩 컨벤션 가이드 ("코드는 이렇게 써야 해")
- **settings.json** = 사무실 보안 규정 ("이것만 접근 가능해")

**이 프로젝트 구조**:
```
CLAUDE.md (루트)          → "Azure Terraform 프로젝트입니다, 환경은 dev/staging/prod"
  ↓ @terraform/variables.tf  → 변수 목록 자동 참조
.claude/CLAUDE.md         → ".claude/ 디렉토리 구조 안내"
.claude/rules/terraform.md → "fmt → checkov → plan 순서 필수"
.claude/rules/azure.md    → "NSG 필수, 하드코딩 금지"
.claude/rules/mcp.md      → "az login 사용, terraform-mcp-server 패키지명"
settings.json             → "terraform destroy 차단, .tf 편집 후 리뷰 트리거"
```

---

### 3.2 Hooks vs Skills

**공통점**: 둘 다 Claude의 행동을 확장한다.

**차이점**:

| 구분 | Hooks | Skills |
|------|-------|--------|
| **트리거** | 자동 (이벤트 기반) | 수동 (`/명령어` 입력) |
| **작성 언어** | 쉘 스크립트 (.sh) | 마크다운 프롬프트 (.md) |
| **실행 주체** | OS 쉘 (Claude 개입 없음) | Claude (프롬프트 해석 후 실행) |
| **역할** | 감시/차단/알림/로깅 | 복잡한 워크플로우 실행 |
| **제어 방향** | 시스템 → Claude | 사용자 → Claude |

**비유**:

- **Hooks** = 공장 자동화 센서 (자동으로 감지하고 반응)
- **Skills** = 직원 교육 매뉴얼 (사람이 요청할 때 따르는 절차)

**이 프로젝트 예시**:

```
[Hooks - 자동 실행]
tf 파일 저장됨 (PostToolUse Edit/Write)
  → post-tf-edit-review.sh 자동 실행
  → "terraform-reviewer 에이전트 실행 권장" 메시지 출력

terraform destroy 명령 감지 (PreToolUse)
  → pre-destroy-guard.sh 자동 실행
  → 명령 차단, "/tf-destroy 스킬 사용 권장" 안내

[Skills - 수동 실행]
사용자: /tf-plan dev
  → tf-plan/prompt.md가 Claude에게 주입
  → Claude가 fmt → checkov → plan → 비용분석 순서대로 실행
```

---

### 3.3 Skills vs Agents

**공통점**: 둘 다 복잡한 작업을 체계적으로 처리하기 위해 설계된다.

**차이점**:

| 구분 | Skills | Agents |
|------|--------|--------|
| **호출 방식** | 사용자가 `/명령어`로 직접 호출 | 메인 Claude가 필요 시 자동 위임 |
| **컨텍스트** | 메인 대화 컨텍스트 안에서 실행 | 별도 컨텍스트에서 독립 실행 |
| **역할** | 반복 작업의 표준화된 절차 | 전문화된 역할의 독립 실행 |
| **사용자 인식** | 사용자가 명시적으로 실행 | 메인 Claude가 판단해서 실행 |
| **병렬 실행** | 불가 | 가능 (여러 에이전트 동시) |

**비유**:
- **Skills** = SOP(표준 운영 절차) 매뉴얼 — 담당자가 꺼내서 따른다
- **Agents** = 외주 전문팀 — 팀장(메인 Claude)이 필요할 때 파견 요청한다

**이 프로젝트 협업 구조**:
```
사용자: /tf-plan dev
   ↓
[Skill: tf-plan] 실행
   ↓
Claude: terraform plan 실행 후 변경사항 감지
   ↓
Claude: 4개 에이전트 병렬 실행 위임
   ├── [Agent: terraform-reviewer] → 영향도 분석
   ├── [Agent: plan-validator]    → 검증 체크리스트 생성
   ├── [Agent: cost-optimizer]    → SKU 최적화 제안
   └── (infracost 직접 실행)     → 예상 비용
```

> **핵심**: Skills가 에이전트들을 오케스트레이션하는 상위 워크플로우 역할을 한다.

---

### 3.4 MCP Tools vs 직접 CLI 호출

**공통점**: 둘 다 외부 시스템과 상호작용하는 방법이다.

**차이점**:

| 구분 | MCP Tools | 직접 CLI (Bash) |
|------|-----------|-----------------|
| **방식** | 구조화된 API 호출 | 쉘 명령어 실행 |
| **결과 형식** | JSON (파싱 용이) | 텍스트 (파싱 필요) |
| **오류 처리** | 표준화된 에러 코드 | exit code + stderr |
| **인증** | MCP 서버가 처리 | 사전 로그인 필요 |
| **토큰 효율** | 필요한 데이터만 | 전체 출력 포함 |

**이 프로젝트 선택 기준**:

```
MCP를 우선 사용:
  - Azure 리소스 조회 → mcp__azure__group_resource_list
  - Terraform plan/apply → mcp__terraform__terraform_plan
  - Miro 다이어그램 → mcp__miro__diagram_create

CLI fallback (MCP 실패 시):
  - az resource list --resource-group rg-xxx
  - terraform state list
```

**규칙 배경** (`.claude/rules/mcp.md`):
> "plan/apply/state 조회는 Terraform MCP 우선 사용 (CLI 직접 호출 지양)"  
> → MCP는 Claude가 결과를 구조화해서 받을 수 있어 분석이 정확하다.

---

## 4. 이 프로젝트 적용 사례

---

### 4.1 CLAUDE.md 계층 설계

**문제**: Azure Terraform 프로젝트에서 Claude가 매번 프로젝트 구조, 규칙, 도구를 다시 설명받아야 하는 비효율.

**해결 방법**: CLAUDE.md를 3계층으로 분리

```
계층 1 (루트): cc_edu/CLAUDE.md
  - 프로젝트 목적: "Azure Hub-Spoke Terraform 배포"
  - 환경 정보: dev/staging/prod
  - 폴더 구조 개요
  - @terraform/variables.tf 참조 → 변수 목록 자동 주입

계층 2 (Claude 설정): .claude/CLAUDE.md
  - .claude/ 디렉토리 구조 상세 설명
  - 각 하위 디렉토리 역할

계층 3 (Terraform 전용): terraform/CLAUDE.md
  - 모듈 구조 (hub-vnet, spoke-vnet, vnet-peering)
  - 환경별 디렉토리 구성
```

**효과**: Claude는 프로젝트를 열자마자 전체 컨텍스트를 파악한다.

---

### 4.2 Hooks 설계 패턴

이 프로젝트의 4개 훅은 각각 다른 목적으로 설계되었다.

**훅 1: pre-destroy-guard.sh** — 안전 가드

- 이벤트: `PreToolUse` / 대상: `Bash`
- 역할: 실수로 인한 인프라 삭제 방지
- 동작: stdin JSON에서 `terraform destroy` 명령 감지 → `decision: block` 반환

```bash
INPUT=$(cat)  # stdin으로 JSON 수신
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

if echo "$COMMAND" | grep -q "terraform destroy"; then
  echo '{"decision":"block","reason":"/tf-destroy 스킬을 통해 실행하세요."}'
  exit 2
fi
```

**훅 2: post-apply-snapshot.sh** — 자동 백업

- 이벤트: `PostToolUse` / 대상: `Bash`
- 역할: 배포 후 state 자동 스냅샷
- 동작: apply 성공 감지 → `terraform state list` 결과를 snapshots/ 에 저장

```bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

if echo "$COMMAND" | grep -q "terraform apply"; then
  TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
  terraform state list > ".claude/snapshots/state-${TIMESTAMP}.txt"
fi
```

**훅 3: post-tf-edit-review.sh** — 코드 리뷰 유도

- 이벤트: `PostToolUse` / 대상: `Edit`, `Write`
- 역할: tf 파일 변경 시 리뷰 습관화
- 동작: 편집된 파일 경로에서 `.tf` 확장자 감지 → 안내 메시지 출력

```bash
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

if echo "$FILE" | grep -q "\.tf$"; then
  echo "terraform-reviewer 에이전트 코드 리뷰를 권장합니다." >&2
fi
```

**훅 4: notify-on-stop.sh** — 사용자 알림

- 이벤트: `Stop`
- 역할: 장시간 작업 완료 알림
- 동작: macOS 알림 전송

```bash
osascript -e 'display notification "응답이 완료되었습니다." with title "Claude Code" sound name "Glass"'
```

---

### 4.3 Skills 설계 패턴

**원칙**: 복잡한 멀티스텝 작업을 표준화된 명령 하나로 실행

**tf-plan 스킬 상세**:

```
사용자: /tf-plan dev

[프롬프트 주입 내용]
1. 환경 확인: environments/dev/ 디렉토리로 이동
2. terraform fmt -recursive 실행
   - 통과: "✅ fmt 검사 통과" 보고
   - 실패: 자동 수정 후 재시도
3. checkov -d . --framework terraform --quiet 실행
   - 미설치: 경고 후 계속
   - FAILED 있으면: 목록 보고 후 계속 여부 확인
4. terraform plan -out=tfplan 실행
5. 변경사항 표로 정리 (create/update/destroy/replace)
6. 변경사항 있을 시 4개 분석 병렬 실행:
   - terraform-reviewer (영향도)
   - plan-validator (체크리스트 → JSON 저장)
   - infracost breakdown (예상 비용)
   - cost-optimizer (SKU 최적화)
```

**설계 이유**:

- fmt → checkov → plan 순서 강제 (규칙 준수 자동화)
- plan-validator가 체크리스트를 미리 생성 → apply 후 validator가 활용
- 비용/영향도 분석을 plan 시점에 실행 → apply 전 의사결정 지원

---

### 4.4 Agents 설계 패턴

**원칙**: 전문화된 역할을 분리하여 메인 컨텍스트를 깨끗하게 유지

**에이전트별 역할 분리**:

| 에이전트 | 전문 역할 | 호출 시점 | 사용 도구 |
|---------|----------|-----------|----------|
| azure-validator | Azure 실제 리소스 상태 검증 | apply 직후 | Azure MCP |
| terraform-reviewer | Terraform 코드 리뷰 + 영향도 | plan 후 / tf 편집 후 | Glob, Grep, Read |
| plan-validator | plan 결과 → 체크리스트 JSON | plan 완료 후 | Bash, Write |
| cost-optimizer | SKU/크기 최적화 제안 | plan 후 | Azure MCP Pricing |

**azure-validator 동작 흐름**:

```
tf-apply 스킬 실행
   ↓
terraform apply 완료
   ↓
azure-validator 에이전트 생성 (메인 컨텍스트와 독립)
   ↓
1. validation-checklist-dev.json 읽기 (plan-validator가 생성한 파일)
2. 체크리스트 항목별 Azure MCP 호출
   - VNet 존재 확인
   - Peering 연결 상태
   - NSG 연결 상태
   - 태그 검증
3. 결과 보고: ✅ 통과 / ❌ 불일치 / ⚠️ 경고
   ↓
메인 Claude에게 결과 반환
```

---

### 4.5 MCP 연동 구조

**이 프로젝트의 4개 MCP 역할**:

```
.mcp.json
├── terraform (stdio)
│   - 실행: npx -y terraform-mcp-server
│   - 환경변수: TF_WORKSPACE_PATH=./terraform/environments/dev
│   - 역할: plan/apply/state를 CLI 없이 MCP로 처리
│
├── azure (stdio)  
│   - 실행: npx -y @azure/mcp@latest server start
│   - 인증: az login (환경변수 불사용)
│   - 역할: 리소스 조회, 헬스 체크, 비용 조회
│
├── github (http)
│   - 엔드포인트: https://api.githubcopilot.com/mcp/
│   - 역할: PR 생성, 브랜치 관리, 커밋 이력
│
└── miro (stdio)
    - 실행: npx -y @mirohq/mcp-server
    - 환경변수: MIRO_ACCESS_TOKEN, MIRO_BOARD_ID
    - 역할: 아키텍처 다이어그램 자동 생성
```

**mcp.md의 핵심 규칙**:
```
규칙: Azure MCP 인증은 환경변수 방식 사용 안 함 → az login 사용
이유: 환경변수에 민감한 토큰을 저장하면 .mcp.json이 git에 노출될 위험

규칙: Terraform MCP 패키지명은 terraform-mcp-server (hashicorp 접두사 없음)
이유: 실제 패키지명이 다름 (흔한 실수 방지)

규칙: MCP 연결 실패 시 az account show 먼저 확인
이유: 로그인 만료가 가장 흔한 원인
```

---

### 4.6 Permissions 설계

**허용 목록 설계 원칙**: 필요한 것만 명시적으로 허용

```
[Terraform 작업]
"Bash(terraform fmt*)"      "Bash(terraform init*)"
"Bash(terraform plan*)"     "Bash(terraform validate*)"
"Bash(terraform state*)"    "Bash(terraform output*)"
"Bash(terraform apply*)"    "Bash(terraform destroy*)"

[검증 도구]
"Bash(tflint*)"   "Bash(checkov*)"   "Bash(infracost*)"

[Azure CLI - MCP fallback]
"Bash(az *)"

[MCP 전체]
"mcp__azure__*"   "mcp__terraform__*"   "mcp__miro__*"   "mcp__github__*"

[VCS]
"Bash(git status)"   "Bash(git log*)"   "Bash(git diff*)"
```

**차단 목록 설계 원칙**: 돌이킬 수 없는 작업은 명시적으로 차단

```
"Bash(rm -rf *)"         → 재귀 삭제
"Bash(az group delete *)" → 리소스 그룹 삭제
```

> **주의**: `terraform destroy`는 deny하지 않는다.  
> 대신 Hooks의 `pre-destroy-guard.sh`가 차단하고,  
> `/tf-destroy` 스킬을 통해서만 안전하게 실행하도록 유도한다.

---

## 5. 전체 개념 구조도

```
┌─────────────────────────────────────────────────────────────┐
│                    사용자 (User)                             │
│                                                             │
│  /tf-plan dev    /tf-apply dev    /tf-destroy dev          │
└──────────┬────────────┬──────────────┬────────────────────┘
           │            │              │
           ▼            ▼              ▼
┌─────────────────────────────────────────────────────────────┐
│                 Skills (슬래시 명령어)                       │
│  .claude/skills/                                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐      │
│  │ tf-plan  │ │ tf-apply │ │tf-destroy│ │ env-diff │ ...  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘      │
│                 ↓ 프롬프트 주입                              │
└─────────────────────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────────┐
│                 메인 Claude 인스턴스                         │
│                                                             │
│  컨텍스트:                                                  │
│  ├── CLAUDE.md (루트/claude/terraform)  ← 프로젝트 규칙     │
│  ├── rules/ (terraform/azure/mcp.md)   ← 작업 규칙         │
│  └── 대화 히스토리                                          │
│                                                             │
│  도구 사용:              Agents 위임:                       │
│  ├── Bash (CLI)          ├── terraform-reviewer             │
│  ├── Read/Edit/Write     ├── plan-validator                 │
│  ├── MCP Tools           ├── azure-validator                │
│  └── Agent (spawn)       └── cost-optimizer                 │
└────────────┬───────────────────┬───────────────────────────┘
             │                   │
             ▼                   ▼
┌──────────────────┐   ┌────────────────────────────────────┐
│  Hooks (자동)    │   │  MCP Servers                       │
│  settings.json   │   │  .mcp.json                         │
│                  │   │                                    │
│ PreToolUse       │   │  ┌─────────┐  ┌──────────┐        │
│ → destroy-guard  │   │  │Terraform│  │  Azure   │        │
│                  │   │  └─────────┘  └──────────┘        │
│ PostToolUse(Bash)│   │  ┌─────────┐  ┌──────────┐        │
│ → apply-snapshot │   │  │ GitHub  │  │   Miro   │        │
│                  │   │  └─────────┘  └──────────┘        │
│ PostToolUse(Edit)│   │                                    │
│ → tf-edit-review │   │         ↓ 외부 API                 │
│                  │   │  Azure / Terraform Registry        │
│ Stop             │   │  GitHub / Miro Board               │
│ → notify-on-stop │   └────────────────────────────────────┘
└──────────────────┘

┌─────────────────────────────────────────────────────────────┐
│               Permissions (settings.json)                   │
│                                                             │
│  allow: terraform*, az*, mcp__*, git*, tflint*, checkov*   │
│  deny: rm -rf*, az group delete*                           │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. 내장 플러그인

Claude Code에는 별도 설치 없이 바로 쓸 수 있는 **공식 내장 플러그인**이 존재한다.  
커스텀 Skills/Agents와 달리 Claude Code가 직접 제공하는 기능이다.

---

### 4.1 Skill Creator (스킬 크리에이터)

**정의**: 커스텀 스킬을 생성하는 데 특화된 내장 플러그인.

**특성**:
- "스킬 만들어줘"라고 말하면 자동 트리거
- 사용자의 의도를 파악해 스킬 구조 설계 + 파일 생성까지 수행
- `.claude/skills/` 디렉토리에 스킬 파일 자동 생성

**사용 예시**:
```
사용자: "PR 올리기 전에 린트 돌리고 테스트 실행하는 스킬 만들어줘"
  → Skill Creator 자동 트리거
  → /pre-pr 스킬 설계 및 생성
```

---

### 4.2 Code Review (코드 리뷰)

**정의**: PR 생성 시 코드 품질을 자동으로 검토하는 내장 플러그인.

**특성**:
- GitHub PR에 **인라인 코멘트**로 리뷰 결과를 직접 작성
- 내부적으로 **여러 리뷰 에이전트를 병렬 실행**하여 검증
- **Severity 레벨** 표시: `critical` / `major` / `minor`
- `REVIEW.md` 파일로 리뷰 기준 커스터마이징 가능
- Team / Enterprise 플랜 필요

**리뷰 항목**:
- 설계 충돌 및 아키텍처 위반
- 버그 가능성 및 엣지 케이스 누락
- 보안 취약점
- 코드 컨벤션 위반

**커스터마이징**:
```markdown
# REVIEW.md
- 모든 Service 클래스는 인터페이스를 통해 접근해야 한다
- 직접 DB 접근은 Repository 레이어에서만 허용한다
- JWT 토큰은 절대 로그에 출력하지 않는다
```

---

### 4.3 Plugin Market (플러그인 마켓)

**정의**: `/plugins` 명령어로 접근하는 플러그인 탐색 및 설치 공간.

**특성**:
- Claude 공식 플러그인 + 커뮤니티 플러그인 검색 가능
- 필요한 기능을 직접 만들기 전에 기존 플러그인 먼저 탐색 권장
- 설치된 플러그인은 즉시 슬래시 명령어로 사용 가능

**사용 방법**:
```
/plugins          → 마켓 진입
/plugins search [키워드]  → 플러그인 검색
/plugins install [이름]   → 설치
```

---

### 내장 플러그인 vs 커스텀 Skills/Agents

| 구분 | 내장 플러그인 | 커스텀 Skills/Agents |
|------|-------------|---------------------|
| 제공 주체 | Anthropic 공식 | 프로젝트 팀 직접 작성 |
| 설치 | 불필요 (즉시 사용) | `.claude/` 디렉토리에 파일 생성 |
| 커스터마이징 | 제한적 (REVIEW.md 등) | 완전 자유 |
| 적합한 용도 | 범용 작업 (리뷰, 스킬 생성 등) | 프로젝트 특화 작업 |

---

## 요약 정리

| 개념 | 한 줄 정의 | 이 프로젝트 예시 |
|------|------------|-----------------|
| **CLAUDE.md** | 프로젝트 지시사항 파일 | Azure Hub-Spoke 구조, 환경 정보 |
| **settings.json** | 런타임 권한/훅 설정 | terraform destroy 차단, 편집 후 리뷰 트리거 |
| **Hooks** | 이벤트 기반 자동 실행 스크립트 | apply 후 스냅샷, destroy 가드 |
| **Skills** | 사용자 호출 커스텀 명령어 | /tf-plan, /tf-apply, /tf-destroy |
| **Agents** | 전문화된 독립 Claude 인스턴스 | azure-validator, terraform-reviewer |
| **MCP Servers** | 외부 시스템 연동 인터페이스 | Azure, Terraform, Miro, GitHub |
| **Permissions** | 허용/차단 도구 범위 | Bash 명령어 allowlist, MCP 접근 제어 |
| **Memory** | 세션 간 정보 유지 | 사용자 역할, 피드백, 프로젝트 맥락 |
| **Skill Creator** | 커스텀 스킬 자동 생성 플러그인 | "스킬 만들어줘" 트리거 |
| **Code Review** | PR 코드 자동 리뷰 플러그인 | 병렬 에이전트 기반 인라인 리뷰 |
| **Plugin Market** | 플러그인 탐색/설치 마켓 | `/plugins` 명령어로 접근 |

