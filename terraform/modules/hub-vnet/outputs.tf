output "vnet_id" {
  description = "Hub VNet ID"
  value       = azurerm_virtual_network.hub.id
}

output "vnet_name" {
  description = "Hub VNet 이름"
  value       = azurerm_virtual_network.hub.name
}

output "gateway_subnet_id" {
  description = "GatewaySubnet ID"
  value       = azurerm_subnet.gateway.id
}

output "firewall_subnet_id" {
  description = "AzureFirewallSubnet ID"
  value       = azurerm_subnet.firewall.id
}

output "management_subnet_id" {
  description = "관리 서브넷 ID"
  value       = azurerm_subnet.management.id
}
