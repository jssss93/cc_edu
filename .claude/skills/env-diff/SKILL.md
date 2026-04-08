---
name: env-diff
description: dev/staging/prod 환경 간 Terraform state 리소스 구성 차이 비교
argument-hint: "[비교할 환경 쌍: dev:staging | staging:prod | dev:prod | all]"
allowed-tools: Bash, Read
---

Terraform state를 기준으로 환경 간 리소스 구성 차이를 비교한다.
인수가 없으면 dev/staging/prod 전체 비교(all)를 수행한다.

환경 디렉토리: `terraform/environments/{env}`

1. **각 환경 state 조회**
   - `terraform -chdir=.../{env} state list 2>/dev/null` 로 리소스 목록 수집
   - tfstate 없는 환경은 "미배포" 로 표시

2. **리소스 수 비교표 출력**
   | 환경 | 리소스 수 | 배포 상태 |
   |------|---------|---------|
   | dev | N | 배포됨 |
   | staging | N | 미배포 |
   | prod | N | 미배포 |

3. **리소스 유형별 차이 분석**
   - dev 기준으로 staging/prod에 없는 리소스: `⊕ dev에만 존재`
   - staging/prod에만 있는 리소스: `⊖ {env}에만 존재`

4. **tfvars 값 차이 비교**
   - 각 환경의 `terraform.tfvars` 파일을 읽어 주요 변수값 차이 출력
   - (CIDR, SKU, instance_count 등 수치 변수 위주)

5. **최종 요약**
   - 환경 간 구성이 동일한 항목 / 다른 항목 목록
   - 권고사항: staging/prod 미배포 환경이 있으면 `/tf-init {env}` 먼저 실행 안내
