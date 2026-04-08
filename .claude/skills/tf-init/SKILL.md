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

## 코드 생성 시 준수 규칙
- 주석은 한국어로 작성
- Azure Provider 버전: `~> 4.0` 이상
- Terraform 버전: `>= 1.5.0`
- `providers.tf`의 `provider "azurerm"` 블록에 `subscription_id` 직접 기입 (환경변수 방식 사용 안 함)
- 모든 리소스에 `tags` 블록 필수 포함 (environment, owner, project)
- 변수는 `variables.tf`에 정의, 값은 `terraform.tfvars`에 분리

## Azure 인프라 규칙
- 리소스 그룹 명명: `rg-{project}-{env}-{region}`
- VNet CIDR: Hub `10.0.0.0/16`, Spoke `10.{n}.0.0/16`
- Private Endpoint는 VNet Peering 이후에 설정
- NSG는 모든 Subnet에 필수 적용

## MCP 활용
- 신규 리소스 코드 작성 전 반드시 Terraform MCP로 Registry 검색
- 코드 생성 후 Terraform MCP로 validate 실행
