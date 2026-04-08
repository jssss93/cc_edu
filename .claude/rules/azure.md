## Azure 인프라 규칙
- 리소스 그룹 명명: `rg-{project}-{env}-{region}`
- VNet CIDR: Hub 10.0.0.0/16, Spoke 10.{n}.0.0/16
- Private Endpoint는 VNet Peering 이후에 설정
- NSG는 모든 Subnet에 필수 적용

## 하드코딩 금지
- Azure 리소스 코드에 하드코딩은 하나도 허용하지 않는다
- 구독 ID, 테넌트 ID, 리소스 이름, CIDR, IP, SKU, 리전 등 모든 값은 반드시 `variables.tf`에 변수로 정의하고 `terraform.tfvars`에서 주입한다
- 민감한 값(subscription_id, 비밀번호, 키 등)은 변수에 `sensitive = true` 속성을 반드시 추가한다
- 코드 리뷰 시 하드코딩 발견 즉시 변수화 후 진행한다
