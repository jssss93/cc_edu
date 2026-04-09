---
globs: "**/*.tf,**/*.tfvars,**/.terraform.lock.hcl"
---
## Terraform 작업 규칙
- 항상 `terraform fmt`를 실행 후 코드를 저장한다
- `terraform plan -out=tfplan` 실행 전 반드시 다음 순서로 수행한다:
  1. **fmt 검사**: `terraform fmt -recursive -list=true` 실행
     - 문제 없으면: "✅ terraform fmt 검사 통과" 보고
     - 문제 있으면: 수정된 파일 목록을 보고하고 `terraform fmt -recursive`로 자동 수정
  2. **validate 검사**: `terraform validate` 실행
     - 통과: "✅ terraform validate 통과" 보고
     - 실패: 오류 메시지 보고 후 중단
  3. **Checkov 보안 검사**: `checkov -d . --framework terraform --quiet` 실행
     - Checkov 미설치 시: "⚠️ Checkov 미설치 - 보안 검사 생략 (pip install checkov 로 설치 가능)" 보고 후 계속 진행
     - 검사 통과: "✅ Checkov 보안 검사 통과" 보고
     - 검사 실패: FAILED 항목 목록 보고 후 사용자에게 계속 진행 여부 확인
- `terraform plan -out=tfplan` 실행 후 반드시 다음 두 가지를 순서대로 수행한다:
  1. 변경사항 요약: create/update/destroy/replace 리소스 목록을 표로 정리하여 보고 (위험한 destroy/replace는 강조)
  2. 비용 분석: `infracost breakdown --path tfplan --format table` 실행하여 예상 월 비용 보고
- `terraform plan` 결과를 반드시 검토 후 apply 진행
- 모든 리소스에 `tags` 블록 포함 필수 (environment, owner, project)
- 변수는 반드시 `variables.tf`에 정의, 값은 `terraform.tfvars`에 분리
- `terraform destroy`는 반드시 사용자 확인 후 실행

## 코드 생성 규칙
- 한국어로 주석 작성
- Azure Provider 버전: ~> 4.0 이상
- Terraform 버전: >= 1.5.0
- `subscription_id`는 `variables.tf`에 `sensitive = true`로 정의하고, 실제 값은 `terraform.tfvars`에 기입 (환경변수 방식 사용 안 함)
