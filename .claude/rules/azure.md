## Azure 인프라 규칙
- 리소스 그룹 명명: `rg-{project}-{env}-{region}`
- VNet CIDR: Hub 10.0.0.0/16, Spoke 10.{n}.0.0/16
- Private Endpoint는 VNet Peering 이후에 설정
- NSG는 모든 Subnet에 필수 적용
