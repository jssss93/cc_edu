---
name: tf-destroy
description: Terraform destroy 실행 (다중 확인 후)
argument-hint: "[환경명: dev|staging|prod]"
allowed-tools: Bash, Read
---

⚠️ 경고: 이 스킬은 $ARGUMENTS 환경의 모든 리소스를 삭제한다.

1. 삭제될 리소스 목록 표시
2. "환경명을 입력하여 확인" 방식으로 2차 승인
3. `terraform destroy` 실행
4. 삭제 완료 확인
