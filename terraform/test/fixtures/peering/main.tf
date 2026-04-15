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

variable "hub_resource_group_name" {
  type = string
}

variable "spoke_resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "koreacentral"
}

variable "hub_vnet_name" {
  type = string
}

variable "spoke_vnet_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "azurerm_resource_group" "hub" {
  name     = var.hub_resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "spoke" {
  name     = var.spoke_resource_group_name
  location = var.location
  tags     = var.tags
}

module "hub_vnet" {
  source = "../../../modules/hub-vnet"

  resource_group_name = azurerm_resource_group.hub.name
  location            = var.location
  vnet_name           = var.hub_vnet_name
  tags                = var.tags
}

module "spoke_vnet" {
  source = "../../../modules/spoke-vnet"

  resource_group_name = azurerm_resource_group.spoke.name
  location            = var.location
  vnet_name           = var.spoke_vnet_name
  tags                = var.tags
}

module "vnet_peering" {
  source = "../../../modules/vnet-peering"

  hub_vnet_name             = module.hub_vnet.vnet_name
  hub_vnet_id               = module.hub_vnet.vnet_id
  hub_resource_group_name   = azurerm_resource_group.hub.name
  spoke_vnet_name           = module.spoke_vnet.vnet_name
  spoke_vnet_id             = module.spoke_vnet.vnet_id
  spoke_resource_group_name = azurerm_resource_group.spoke.name

  depends_on = [module.hub_vnet, module.spoke_vnet]
}

output "hub_vnet_id" {
  value = module.hub_vnet.vnet_id
}

output "spoke_vnet_id" {
  value = module.spoke_vnet.vnet_id
}

output "hub_to_spoke_peering_id" {
  value = module.vnet_peering.hub_to_spoke_peering_id
}

output "spoke_to_hub_peering_id" {
  value = module.vnet_peering.spoke_to_hub_peering_id
}
