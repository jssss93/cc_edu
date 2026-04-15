---
name: tf-plan
description: Terraform plan 실행 및 변경사항 분석
argument-hint: "[환경명: dev|staging|prod]"
allowed-tools: Bash, Read
---

$ARGUMENTS 환경의 terraform plan을 실행하고 변경사항과 예상 비용을 분석한다.

환경명이 지정되지 않은 경우 dev를 기본값으로 사용한다.

작업 디렉토리: `terraform/environments/${ENV:-dev}`

1. 해당 디렉토리로 이동 후 `terraform fmt -recursive -list=true`로 포맷 검사:
   - 문제 없으면: "✅ terraform fmt 검사 통과" 보고
   - 문제 있으면: 수정된 파일 목록 보고 후 `terraform fmt -recursive`로 자동 수정 → 수정 전/후 diff(`git diff` 또는 `diff`) 출력 → 재검사 실행 (최대 2회 반복)
     - 재검사 통과: "✅ terraform fmt 자동 수정 후 통과 (N회 시도)" 보고 후 다음 단계 진행
     - 2회 재시도 후에도 실패: "❌ terraform fmt 자동 수정 실패 (2회 시도)" 및 남은 오류 파일 목록 보고 후 중단
2. `terraform validate` 실행:
   - 통과: "✅ terraform validate 통과" 보고 후 다음 단계 진행
   - 실패: 오류 메시지 분석 → 코드 자동 수정 시도 → 재실행 (최대 2회)
     - 재실행 성공: "✅ terraform validate 자동 수정 후 통과 (N회 시도)" 보고 후 다음 단계 진행
     - 2회 재시도 후에도 실패: 오류 내용 보고 후 중단
3. Checkov 보안 검사: 환경 디렉토리 및 모듈 전체 스캔
   - Checkov 설치 확인: `checkov --version`
   - 설치된 경우: `checkov -d ../.. --framework terraform --quiet` (environments + modules 전체 포함, `../..`는 `terraform/` 루트)
   - 검사 통과: "✅ Checkov 보안 검사 통과" 보고 후 다음 단계 진행
   - 검사 실패: FAILED 항목을 아래 형식으로 표 출력 (PASSED/FAILED/SKIPPED 건수 요약 포함):
     | # | Check ID | 설명 | 파일 | 리소스 | 권장 조치 |
     → **각 FAILED 항목마다 사용자에게 직접 결정을 요청한다 (human-in-the-loop)**:
       - "1) 코드 수정으로 해결  2) checkov:skip 추가  3) 이 항목 무시하고 계속"
       - **checkov:skip은 Claude가 자동으로 추가하지 않는다** — 사용자가 2번을 선택한 경우에만 추가
       - 사용자 선택에 따라 조치 후 해당 항목 재검사
     - 모든 항목 처리 완료 후: 결과 요약 (수정 N, skip N, 무시 N) 보고 후 다음 단계 진행
     - 사용자가 중단을 원하는 경우: 즉시 중단
   - Checkov 미설치: "⚠️ Checkov 미설치 - 보안 검사 생략 (`pip install checkov`으로 설치 가능)" 보고 후 계속 진행
4. `terraform plan -out=tfplan` 실행 (Terraform MCP 우선 사용, CLI는 MCP 불가 시 fallback)
   - 모든 리소스에 `tags` 블록(environment, owner, project)이 포함되어 있는지 확인
   - plan 실패 시: 에러 메시지를 분석하여 원인 파악 → 코드 자동 수정 시도 → 수정된 파일명과 변경 내용(before/after 코드 스니펫) 출력 → `terraform plan -out=tfplan` 재실행 (최대 2회 재시도)
     - 재실행 성공: "✅ terraform plan 자동 수정 후 성공 (N회 시도)" 보고 후 다음 단계 진행
     - 2회 재시도 후에도 실패: 에러 내용과 시도한 수정 내역을 출력 후 중단
5. 변경될 리소스 목록을 아래 형식으로 표 출력:
   - 구분 (create/update/destroy/replace)
   - 리소스 타입
   - 리소스 이름
   - 주요 변경 속성 (update/replace 시)
6. 위험한 변경사항(destroy/replace) 하이라이트
7. 총 변경 건수 요약 (create N, update N, destroy N, replace N)
8. **병렬 분석 (변경사항 존재 시 아래 4가지를 동시에 실행)**:
   - **[terraform-reviewer]** update/destroy/replace 존재 시: plan 결과 전문 + 변경 리소스 목록 + 환경명을 전달하여 영향도 분석 수행. create만 있는 경우 생략
   - **[plan-validator]** 환경명 + 변경 리소스 목록(유형/이름/변경 구분)을 전달하여 검증 체크리스트 생성 → `bash .claude/scripts/memory-dir.sh` 출력 디렉터리 아래 `validation-checklist-{env}.json` 저장
   - **[infracost]** `infracost breakdown --path tfplan --format table` 실행하여 **예상** 월 비용만 산출 (실청구·실비용 조회 없음)
   - **[cost-optimizer]** 환경명 + 변경 리소스 목록을 전달하여 SKU/크기 최적화 방안 분석
   - 4가지 모두 완료 후 결과를 순서대로 사용자에게 출력
