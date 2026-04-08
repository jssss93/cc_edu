output "hub_resource_group_name" {
  description = "Hub 리소스 그룹 이름"
  value       = azurerm_resource_group.hub.name
}

output "spoke_resource_group_name" {
  description = "Spoke 리소스 그룹 이름"
  value       = azurerm_resource_group.spoke.name
}

output "hub_vnet_id" {
  description = "Hub VNet ID"
  value       = module.hub_vnet.vnet_id
}

output "spoke_vnet_id" {
  description = "Spoke VNet ID"
  value       = module.spoke_vnet.vnet_id
}

output "app_subnet_id" {
  description = "애플리케이션 서브넷 ID"
  value       = module.spoke_vnet.app_subnet_id
}

output "db_subnet_id" {
  description = "데이터베이스 서브넷 ID"
  value       = module.spoke_vnet.db_subnet_id
}

output "function_app_name" {
  description = "Function App 이름"
  value       = azurerm_linux_function_app.main.name
}

output "function_app_hostname" {
  description = "Function App 기본 호스트명"
  value       = azurerm_linux_function_app.main.default_hostname
}
