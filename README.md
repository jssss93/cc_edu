# Azure Hub-Spoke Terraform + Claude Code

Azure Hub-Spoke 네트워크 아키텍처를 Terraform으로 배포하고, Claude Code로 자동화한 프로젝트입니다.

## 아키텍처

```
Hub VNet (10.0.0.0/16)          Spoke VNet (10.1.0.0/16)
├── GatewaySubnet          ◄──► ├── snet-app
└── AzureFirewallSubnet         ├── snet-func (Function App VNet integration)
                                └── Storage Account (VNet 잠금)
                                    └── Linux Function App (EP1)
```

## 환경

| 환경 | 경로 |
|------|------|
| dev | `terraform/environments/dev/` |
| staging | `terraform/environments/staging/` |
| prod | `terraform/environments/prod/` |

## 사전 요구사항

| 도구 | 버전 | 설치 |
|------|------|------|
| Terraform | >= 1.5.0 | `brew install terraform` |
| Azure CLI | 최신 | `brew install azure-cli` |
| tflint | 최신 | `brew install tflint` |
| checkov | 최신 | `pip install checkov` |
| infracost | 최신 | `brew install infracost` |
| Node.js | >= 18 | `brew install node` |
| jq | 최신 | `brew install jq` |

## 빠른 시작

```bash
# 1. Azure 로그인
az login

# 2. 변수 파일 생성 (gitignore 대상)
cp terraform/environments/dev/terraform.tfvars.example \
   terraform/environments/dev/terraform.tfvars
# terraform.tfvars에 subscription_id 등 실제 값 입력

# 3. Claude Code에서 초기화 및 배포
/tf-init dev
/tf-plan dev
/tf-apply dev
```

## Claude Code 스킬

| 명령어 | 설명 |
|--------|------|
| `/tf-init [env]` | Terraform 초기화 및 백엔드 설정 |
| `/tf-plan [env]` | fmt → checkov → plan → **infracost 예상 비용** (실비용/청구 조회 없음) |
| `/tf-apply [env]` | staleness 체크 → apply → 리소스 검증 |
| `/tf-destroy [env]` | 다중 확인 후 destroy |
| `/tf-validate` | fmt + tflint + checkov 빠른 검증 |
| `/miro-update` | 배포 리소스 Miro 다이어그램 자동 생성 |
| `/env-diff` | dev/staging/prod 환경 간 리소스 차이 비교 |

## MCP 서버

| MCP | 용도 | 인증 |
|-----|------|------|
| Azure | 리소스 조회/검증 (비용은 infracost만, 실청구 조회 안 함) | `az login` |
| Terraform | plan/apply/state 조회 | 자동 |
| GitHub | PR 생성/브랜치 관리 | `gh auth login` |
| Miro | 아키텍처 다이어그램 생성 | `MIRO_ACCESS_TOKEN` 환경변수 |

```bash
# Miro 환경변수 설정 (셸 프로파일에 추가)
export MIRO_ACCESS_TOKEN=your_token
export MIRO_BOARD_ID=your_board_id
export MIRO_AUTO_UPDATE=true   # apply 후 자동 다이어그램 업데이트
```

## 자동화 훅

| 훅 | 트리거 | 동작 |
|----|--------|------|
| `pre-destroy-guard.sh` | terraform destroy 실행 전 | 실행 차단 가드 |
| `post-apply-snapshot.sh` | terraform apply 성공 후 | state 스냅샷 저장 + infracost·Miro **안내** (자동 실행 아님) |
| `post-tf-edit-review.sh` | .tf 파일 편집 후 | terraform-reviewer 트리거 |
| `notify-on-stop.sh` | Claude 응답 완료 시 | macOS 알림 |

## 코딩 규칙

- 모든 값은 `variables.tf` 정의 + `terraform.tfvars` 주입 (하드코딩 금지)
- 민감 값(`subscription_id` 등)은 `sensitive = true` 필수
- 모든 리소스에 `environment`, `owner`, `project` 태그 필수
- 리소스 그룹 명명: `rg-{project}-{role}-{env}-{region}`
- NSG는 모든 서브넷에 필수 적용
