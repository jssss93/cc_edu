---
name: tf-validate
description: Terraform 코드 빠른 검증 (fmt + tflint + checkov)
argument-hint: "[환경명: dev|staging|prod]"
allowed-tools: Bash, Read
---

$ARGUMENTS 환경의 Terraform 코드를 plan 없이 빠르게 검증한다.
환경명이 지정되지 않은 경우 dev를 기본값으로 사용한다.

작업 디렉토리: `terraform/environments/${ENV:-dev}`

1. **terraform fmt 검사**
   - `terraform fmt -recursive -list=true` 실행
   - 문제 없으면: "✅ terraform fmt 검사 통과" 보고
   - 문제 있으면: 수정 파일 목록 보고 후 `terraform fmt -recursive` 자동 수정

2. **terraform validate 실행**
   - `terraform validate` 실행
   - 통과: "✅ terraform validate 통과" 보고
   - 실패: 오류 메시지 출력 후 중단

3. **tflint 검사**
   - `tflint --recursive` 실행
   - 미설치 시: "⚠️ tflint 미설치 — 건너뜀" 보고 후 계속 진행

4. **checkov 보안 검사**
   - `checkov -d ../.. --framework terraform --quiet` 실행 (terraform/ 루트 기준)
   - 미설치 시: "⚠️ Checkov 미설치 — 건너뜀" 보고 후 계속 진행
   - 실패 시: FAILED 항목 표로 출력

5. 최종 요약 출력:
   | 검사 | 결과 |
   |------|------|
   | fmt | ✅/❌ |
   | validate | ✅/❌ |
   | tflint | ✅/⚠️/❌ |
   | checkov | ✅/⚠️/❌ |
