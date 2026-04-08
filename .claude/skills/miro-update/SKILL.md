---
name: miro-update
description: Terraform 배포 리소스를 Miro 보드에 아키텍처 다이어그램으로 자동 생성
allowed-tools: Bash, Read, mcp__miro__*
context: fork
agent: general-purpose
---

배포된 Terraform 리소스를 분석하여 Miro 보드에 Azure 아키텍처 다이어그램을 생성한다.

## 실행 순서

1. terraform state list로 전체 리소스 목록 추출
2. 리소스를 유형별로 분류 (VNet, Subnet, NSG, VM, PaaS 등)
3. Hub-Spoke 토폴로지 분석
4. Miro MCP를 사용하여 다이어그램 요소 생성:
   - 각 VNet을 큰 컨테이너 박스로 표현
   - Subnet을 내부 박스로 표현
   - 리소스를 Azure 아이콘 스티커로 표현
   - VNet Peering을 화살표 연결선으로 표현
   - 색상 규칙: Hub=파란색, Spoke=초록색, 보안 리소스=빨간색
5. 다이어그램 레이아웃 자동 정렬
6. 완성된 보드 URL 출력
