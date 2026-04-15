terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

variable "subscription_id" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "koreacentral"
}

variable "vnet_name" {
  type = string
}

variable "vnet_address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "gateway_subnet_prefix" {
  type    = string
  default = "10.0.0.0/27"
}

variable "firewall_subnet_prefix" {
  type    = string
  default = "10.0.1.0/26"
}

variable "management_subnet_prefix" {
  type    = string
  default = "10.0.2.0/24"
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "azurerm_resource_group" "test" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "hub_vnet" {
  source = "../../../modules/hub-vnet"

  resource_group_name      = azurerm_resource_group.test.name
  location                 = var.location
  vnet_name                = var.vnet_name
  vnet_address_space       = var.vnet_address_space
  gateway_subnet_prefix    = var.gateway_subnet_prefix
  firewall_subnet_prefix   = var.firewall_subnet_prefix
  management_subnet_prefix = var.management_subnet_prefix
  tags                     = var.tags
}

output "vnet_id" {
  value = module.hub_vnet.vnet_id
}

output "vnet_name" {
  value = module.hub_vnet.vnet_name
}

output "gateway_subnet_id" {
  value = module.hub_vnet.gateway_subnet_id
}

output "firewall_subnet_id" {
  value = module.hub_vnet.firewall_subnet_id
}

output "management_subnet_id" {
  value = module.hub_vnet.management_subnet_id
}
