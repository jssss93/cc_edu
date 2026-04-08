---
name: tf-plan
description: Terraform plan 실행 및 변경사항 분석
argument-hint: "[환경명: dev|staging|prod]"
allowed-tools: Bash, Read
---

$ARGUMENTS 환경의 terraform plan을 실행하고 변경사항과 예상 비용을 분석한다.

환경명이 지정되지 않은 경우 dev를 기본값으로 사용한다.

작업 디렉토리: `/Users/jongsu/git/js_project/cc_edu/terraform/environments/${ENV:-dev}`

1. 해당 디렉토리로 이동 후 `terraform fmt -recursive -list=true`로 포맷 검사:
   - 문제 없으면: "✅ terraform fmt 검사 통과" 보고
   - 문제 있으면: 수정된 파일 목록 보고 후 `terraform fmt -recursive`로 자동 수정 → 수정 전/후 diff(`git diff` 또는 `diff`) 출력 → 재검사 실행 (최대 2회 반복)
     - 재검사 통과: "✅ terraform fmt 자동 수정 후 통과 (N회 시도)" 보고 후 다음 단계 진행
     - 2회 재시도 후에도 실패: "❌ terraform fmt 자동 수정 실패 (2회 시도)" 및 남은 오류 파일 목록 보고 후 중단
2. Checkov 보안 검사: 환경 디렉토리 및 모듈 전체 스캔
   - Checkov 설치 확인: `checkov --version`
   - 설치된 경우: `checkov -d ../.. --framework terraform --quiet` (environments + modules 전체 포함, `../..`는 `terraform/` 루트)
   - 검사 통과: "✅ Checkov 보안 검사 통과" 보고 후 다음 단계 진행
   - 검사 실패: FAILED 항목을 아래 형식으로 표 출력 (PASSED/FAILED/SKIPPED 건수 요약 포함):
     | Check ID | 설명 | 파일 | 리소스 |
     → 각 FAILED 항목에 대해 코드를 자동 수정 시도 → 수정된 파일명과 변경 내용(before/after 코드 스니펫) 출력 → 재검사 실행 (최대 2회 반복)
     - 재검사 통과: "✅ Checkov 자동 수정 후 통과 (N회 시도)" 보고 후 다음 단계 진행
     - 2회 재시도 후에도 실패: 남은 FAILED 항목 목록과 시도한 수정 내역 출력 후 중단
   - Checkov 미설치: "⚠️ Checkov 미설치 - 보안 검사 생략 (`pip install checkov`으로 설치 가능)" 보고 후 계속 진행
3. `terraform plan -out=tfplan` 실행 (Terraform MCP 우선 사용, CLI는 MCP 불가 시 fallback)
   - 모든 리소스에 `tags` 블록(environment, owner, project)이 포함되어 있는지 확인
   - plan 실패 시: 에러 메시지를 분석하여 원인 파악 → 코드 자동 수정 시도 → 수정된 파일명과 변경 내용(before/after 코드 스니펫) 출력 → `terraform plan -out=tfplan` 재실행 (최대 2회 재시도)
     - 재실행 성공: "✅ terraform plan 자동 수정 후 성공 (N회 시도)" 보고 후 다음 단계 진행
     - 2회 재시도 후에도 실패: 에러 내용과 시도한 수정 내역을 출력 후 중단
4. 변경될 리소스 목록을 아래 형식으로 표 출력:
   - 구분 (create/update/destroy/replace)
   - 리소스 타입
   - 리소스 이름
   - 주요 변경 속성 (update/replace 시)
5. 위험한 변경사항(destroy/replace) 하이라이트
6. 총 변경 건수 요약 (create N, update N, destroy N, replace N)
7. **영향도 분석 (update/destroy/replace 존재 시)**: update, destroy, replace 중 하나라도 있으면 `terraform-reviewer` 에이전트를 호출하여 영향도 분석 수행
   - 에이전트에게 전달할 컨텍스트: plan 결과 전문, 변경 리소스 목록, 환경명
   - 에이전트 분석 완료 후 결과를 사용자에게 출력
   - create만 있는 경우: 이 단계 생략
8. **검증 체크리스트 생성 (변경사항 존재 시 항상 실행)**: `plan-validator` 에이전트를 호출하여 `azure-validator`가 배포 후 실행할 검증 항목을 동적으로 생성
   - 에이전트에게 전달할 컨텍스트: 환경명, 변경 리소스 목록 (유형/이름/변경 구분 포함)
   - 에이전트가 `.claude/snapshots/validation-checklist-{env}.json` 파일로 저장
   - 에이전트 완료 후 생성된 검증 항목 요약을 사용자에게 출력
9. Infracost로 예상 월 비용 산출:
   - `infracost breakdown --path tfplan --format table` 실행
   - 총 월 예상 비용 강조 출력
10. **비용 최적화 분석 (변경사항 존재 시 항상 실행)**: `cost-optimizer` 에이전트를 호출하여 현재 배포된 리소스의 SKU/크기 최적화 방안 분석
    - 에이전트에게 전달할 컨텍스트: 환경명, plan 변경 리소스 목록
    - 에이전트 분석 완료 후 결과를 사용자에게 출력
