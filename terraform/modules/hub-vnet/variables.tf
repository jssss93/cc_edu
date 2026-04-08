variable "resource_group_name" {
  description = "리소스 그룹 이름"
  type        = string
}

variable "location" {
  description = "Azure 리전"
  type        = string
  default     = "koreacentral"
}

variable "vnet_name" {
  description = "Hub VNet 이름"
  type        = string
}

variable "vnet_address_space" {
  description = "Hub VNet CIDR"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "gateway_subnet_prefix" {
  description = "GatewaySubnet CIDR"
  type        = string
  default     = "10.0.0.0/27"
}

variable "firewall_subnet_prefix" {
  description = "AzureFirewallSubnet CIDR"
  type        = string
  default     = "10.0.1.0/26"
}

variable "management_subnet_prefix" {
  description = "관리 서브넷 CIDR"
  type        = string
  default     = "10.0.2.0/24"
}

variable "tags" {
  description = "리소스 태그"
  type        = map(string)
  default     = {}
}
