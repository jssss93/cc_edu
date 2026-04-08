---
name: cost-report
description: 배포된 Azure 리소스의 실제 비용을 Azure MCP로 조회하여 리포트 생성
argument-hint: "[환경명: dev|staging|prod] [기간: today|week|month]"
allowed-tools: Bash, Read, Write, mcp__azure__pricing, mcp__terraform__terraform_state_list
context: fork
agent: general-purpose
---

$0 환경의 $1 기간 실제 Azure 비용을 조회하고 리포트를 생성한다.

## 실행 순서

1. Azure MCP로 비용 데이터 조회
   - mcp__azure__pricing 으로 서비스별 단가 및 비용 조회
   - resource_group="rg-project-$0-krc" 기준

2. Terraform MCP로 현재 배포 리소스 목록 조회
   - terraform_state_list()로 리소스 수 파악

3. 비용 분석 및 리포트 생성
   - 서비스별 비용 TOP 5
   - 리소스별 비용 TOP 10
   - 전일/전주 대비 증감률
   - 월말 예상 총 비용 (현재 소비 기반 프로젝션)

4. 비용 이상 감지 (임계값 초과 시 경고)
   - 일 비용 $50 초과: ⚠️ 경고
   - 월 비용 $1,000 초과: 🚨 알림

5. 리포트를 .claude/cost-reports/{날짜}-{환경}.md 로 저장

6. (선택) Miro 보드에 비용 요약 스티커 추가
