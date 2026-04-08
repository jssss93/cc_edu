output "vnet_id" {
  description = "Spoke VNet ID"
  value       = azurerm_virtual_network.spoke.id
}

output "vnet_name" {
  description = "Spoke VNet 이름"
  value       = azurerm_virtual_network.spoke.name
}

output "app_subnet_id" {
  description = "애플리케이션 서브넷 ID"
  value       = azurerm_subnet.app.id
}

output "db_subnet_id" {
  description = "데이터베이스 서브넷 ID"
  value       = azurerm_subnet.db.id
}
