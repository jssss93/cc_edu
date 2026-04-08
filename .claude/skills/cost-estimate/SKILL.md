---
name: cost-estimate
description: Infracost로 Terraform plan 기반 인프라 예상 비용 산출
argument-hint: "[환경명: dev|staging|prod]"
allowed-tools: Bash, Read
---

$ARGUMENTS 환경의 Terraform plan을 분석하여 인프라 예상 월 비용을 산출한다.

1. 환경 디렉토리 확인 (`terraform/environments/$ARGUMENTS`)
2. tfplan 파일 없으면 `terraform plan -out=tfplan` 먼저 실행
3. `infracost breakdown --path tfplan` 실행하여 리소스별 비용 산출
4. 아래 형식으로 결과 출력:
   - 리소스별 월 예상 비용 표
   - 총 월 예상 비용
   - 이전 상태 대비 증감 (`infracost diff` 활용, tfplan 비교)
5. 비용 최적화 제안 (고비용 리소스가 있는 경우)

> 참고: Infracost는 Terraform plan 기반으로 배포 전 비용을 예측하므로 Azure 청구 지연(24~48시간) 없이 즉시 결과를 반환한다.
