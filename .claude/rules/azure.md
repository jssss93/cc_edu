---
globs: "**/*.tf,**/*.tfvars"
---
## Azure 인프라 규칙

### 리소스 명명 규칙
- 기본 패턴: `{약어}-{역할}-{프로젝트}-{환경}-{리전}`
- Storage Account 예외: 소문자+숫자만, 하이픈 없음 → `st{역할}{프로젝트}{환경}`

| 약어 | 리소스 타입 |
|------|-------------|
| rg | Resource Group |
| vnet | Virtual Network |
| snet | Subnet |
| nsg | Network Security Group |
| asp | App Service Plan |
| func | Function App |
| st | Storage Account |
| pe | Private Endpoint |
| pip | Public IP |
| lb | Load Balancer |

### 네트워크 규칙
- VNet CIDR: Hub 10.0.0.0/16, Spoke 10.{n}.0.0/16
- Private Endpoint는 VNet Peering 이후에 설정
- NSG는 모든 Subnet에 필수 적용

### 필수 태그
- 모든 리소스에 `environment`, `owner`, `project` 태그 필수

## 하드코딩 금지
- Azure 리소스 코드에 하드코딩은 하나도 허용하지 않는다
- 구독 ID, 테넌트 ID, 리소스 이름, CIDR, IP, SKU, 리전 등 모든 값은 반드시 `variables.tf`에 변수로 정의하고 `terraform.tfvars`에서 주입한다
- 민감한 값(subscription_id, 비밀번호, 키 등)은 변수에 `sensitive = true` 속성을 반드시 추가한다
- 코드 리뷰 시 하드코딩 발견 즉시 변수화 후 진행한다
