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

## State 백엔드 (교육 예시와의 차이)

교육 자료의 **원격 Azure Storage(`azurerm` backend) 블록**은 일반적인 팀 운영 예시일 뿐이다. **본 저장소는 환경 디렉터리별 로컬 `terraform.tfstate`** 를 사용한다. 원격 state로 전환할 때는 백업·잠금·권한을 포함해 별도 설계한다.
