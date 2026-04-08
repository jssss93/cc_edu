---
name: tf-apply
description: Terraform apply 실행 (plan 검토 후 배포)
argument-hint: "[환경명: dev|staging|prod]"
allowed-tools: Bash, Read
---

$ARGUMENTS 환경에 Terraform 배포를 실행한다.

1. plan 파일 존재 확인 (없으면 /tf-plan 먼저 실행)
2. `terraform apply tfplan` 즉시 실행 (사용자 승인 대기 없이 바로 실행)
3. apply 실패 시: 에러 메시지를 분석하여 원인 파악 → 코드 자동 수정 시도 → 수정된 파일명과 변경 내용(before/after 코드 스니펫) 출력 → **/tf-plan 스킬을 호출하여 plan부터 재수행** (최대 2회 재시도)
   - 재시도 성공: "✅ apply 자동 수정 후 성공 (N회 시도)" 보고 후 다음 단계 진행
   - 2회 재시도 후에도 실패: 에러 내용과 시도한 수정 내역 출력 후 중단하고 사용자에게 보고
4. 완료 후 output 표시
5. azure-validator 에이전트를 호출하여 배포된 리소스 상태 검증:
   - 에이전트에게 환경명($ARGUMENTS)과 Terraform state 리소스 목록을 전달
   - 에이전트 검증 결과(리소스 상태, NSG, VNet Peering, 태그 등)를 사용자에게 그대로 출력
   - 불일치 또는 이상 발견 시 반드시 사용자에게 보고
6. Miro 다이어그램 업데이트:
   - `echo $MIRO_AUTO_UPDATE` 로 환경변수 값 확인
   - 값이 `true`이면: `/miro-update` 스킬 자동 호출
   - 값이 없거나 `true`가 아니면: "💡 Miro 업데이트 건너뜀 (MIRO_AUTO_UPDATE=true 로 활성화 가능)" 출력 후 종료
