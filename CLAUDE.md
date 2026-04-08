# Azure Terraform 프로젝트 지시사항

## 프로젝트 개요
- 목적: Azure Hub-Spoke 아키텍처 Terraform 배포
- 환경: dev / staging / prod
- 백엔드: 로컬 (terraform.tfstate를 각 환경 디렉토리에서 관리)
- 아키텍처 시각화: Miro MCP 자동 생성

## 참고 파일
See @terraform/variables.tf for variable definitions

## 폴더 구조

```
cc_edu/
├── CLAUDE.md                          # 프로젝트 전역 지시사항
├── .gitignore
├── .mcp.json                          # MCP 서버 설정 (Azure, Terraform, Miro, GitHub)
├── .claude/                           # Claude Code 설정 → .claude/CLAUDE.md 참조
└── terraform/                         # Terraform 코드 → terraform/CLAUDE.md 참조
```
