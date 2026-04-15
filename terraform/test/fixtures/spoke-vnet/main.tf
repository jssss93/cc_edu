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
  default = ["10.1.0.0/16"]
}

variable "app_subnet_prefix" {
  type    = string
  default = "10.1.0.0/24"
}

variable "db_subnet_prefix" {
  type    = string
  default = "10.1.1.0/24"
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

module "spoke_vnet" {
  source = "../../../modules/spoke-vnet"

  resource_group_name = azurerm_resource_group.test.name
  location            = var.location
  vnet_name           = var.vnet_name
  vnet_address_space  = var.vnet_address_space
  app_subnet_prefix   = var.app_subnet_prefix
  db_subnet_prefix    = var.db_subnet_prefix
  tags                = var.tags
}

output "vnet_id" {
  value = module.spoke_vnet.vnet_id
}

output "vnet_name" {
  value = module.spoke_vnet.vnet_name
}

output "app_subnet_id" {
  value = module.spoke_vnet.app_subnet_id
}

output "db_subnet_id" {
  value = module.spoke_vnet.db_subnet_id
}
