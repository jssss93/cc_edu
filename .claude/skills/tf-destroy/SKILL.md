---
name: tf-destroy
description: Terraform destroy 실행 (다중 확인 후)
argument-hint: "[환경명: dev|staging|prod]"
allowed-tools: Bash, Read
---

⚠️ 경고: 이 스킬은 $ARGUMENTS 환경의 모든 리소스를 삭제한다.

1. 해당 환경 디렉터리(`terraform/environments/<환경>/`)에서 삭제될 리소스 목록 표시 (`terraform plan -destroy` 출력 요약)
2. "환경명을 입력하여 확인" 방식으로 2차 승인
3. **`terraform plan -destroy -out=tfplan` 후 `terraform apply tfplan`** 으로 삭제 적용 (직접 `terraform destroy` 문자열은 PreToolUse 훅에서 차단될 수 있음)
4. 삭제 완료 확인 (`terraform state list`가 비어 있는지 등)
