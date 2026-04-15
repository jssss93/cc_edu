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

variable "subscription_id" {
  description = "Azure 구독 ID"
  type        = string
  sensitive   = true
}

variable "runner_ip" {
  description = "Terraform 러너 공인 IP (Storage ip_rules 등록용, plan/apply 시 자동 주입)"
  type        = string
  default     = ""
}

variable "acr_sku" {
  description = "Azure Container Registry SKU (Basic, Standard, Premium)"
  type        = string
  default     = "Basic"
}

variable "static_web_app_sku" {
  description = "Static Web App SKU 티어 (Free, Standard)"
  type        = string
  default     = "Free"
}

variable "static_web_app_location" {
  description = "Static Web App 리전 (koreacentral 미지원 — westus2/centralus/eastus2/westeurope/eastasia 중 선택)"
  type        = string
  default     = "eastasia"
}
