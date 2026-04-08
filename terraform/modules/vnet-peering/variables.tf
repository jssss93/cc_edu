variable "hub_vnet_name" {
  description = "Hub VNet 이름"
  type        = string
}

variable "hub_vnet_id" {
  description = "Hub VNet ID"
  type        = string
}

variable "hub_resource_group_name" {
  description = "Hub 리소스 그룹 이름"
  type        = string
}

variable "spoke_vnet_name" {
  description = "Spoke VNet 이름"
  type        = string
}

variable "spoke_vnet_id" {
  description = "Spoke VNet ID"
  type        = string
}

variable "spoke_resource_group_name" {
  description = "Spoke 리소스 그룹 이름"
  type        = string
}
