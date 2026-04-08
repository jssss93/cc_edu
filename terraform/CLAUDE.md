# Terraform 코드 구조

```
terraform/
├── environments/
│   ├── dev/                       # 개발 환경
│   │   ├── main.tf                # 모듈 호출
│   │   ├── providers.tf           # Azure Provider (subscription_id는 변수 참조)
│   │   ├── variables.tf           # 변수 정의
│   │   ├── outputs.tf             # 출력값
│   │   └── terraform.tfvars       # 실제 변수값 (gitignore로 보호)
│   ├── staging/                   # 스테이징 환경 (구조 동일)
│   └── prod/                      # 프로덕션 환경 (구조 동일)
└── modules/
    ├── hub-vnet/                  # Hub VNet 모듈
    ├── spoke-vnet/                # Spoke VNet 모듈
    └── vnet-peering/              # VNet 피어링 모듈
```

## 환경별 작업 디렉토리

| 환경 | 경로 |
|------|------|
| dev | `terraform/environments/dev/` |
| staging | `terraform/environments/staging/` |
| prod | `terraform/environments/prod/` |

## 모듈 역할

| 모듈 | 역할 |
|------|------|
| hub-vnet | Hub VNet, 서브넷, NSG 생성 |
| spoke-vnet | Spoke VNet, 서브넷, NSG 생성 |
| vnet-peering | Hub ↔ Spoke VNet 피어링 연결 |
