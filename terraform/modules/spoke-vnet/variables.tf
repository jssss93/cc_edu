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
  description = "Spoke VNet 이름"
  type        = string
}

variable "vnet_address_space" {
  description = "Spoke VNet CIDR"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "app_subnet_prefix" {
  description = "애플리케이션 서브넷 CIDR"
  type        = string
  default     = "10.1.0.0/24"
}

variable "db_subnet_prefix" {
  description = "데이터베이스 서브넷 CIDR"
  type        = string
  default     = "10.1.1.0/24"
}

variable "tags" {
  description = "리소스 태그"
  type        = map(string)
  default     = {}
}
