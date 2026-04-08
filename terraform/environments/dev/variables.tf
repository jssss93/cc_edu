variable "project" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "배포 환경"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure 리전"
  type        = string
  default     = "koreacentral"
}

variable "owner" {
  description = "리소스 소유자"
  type        = string
}

variable "hub_vnet_address_space" {
  description = "Hub VNet CIDR"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "spoke_vnet_address_space" {
  description = "Spoke VNet CIDR"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "runner_ip" {
  description = "Terraform 러너 공인 IP (Storage ip_rules 등록용, plan/apply 시 자동 주입)"
  type        = string
  default     = ""
}
