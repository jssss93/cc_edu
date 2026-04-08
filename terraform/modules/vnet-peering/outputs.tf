output "hub_to_spoke_peering_id" {
  description = "Hub → Spoke 피어링 ID"
  value       = azurerm_virtual_network_peering.hub_to_spoke.id
}

output "spoke_to_hub_peering_id" {
  description = "Spoke → Hub 피어링 ID"
  value       = azurerm_virtual_network_peering.spoke_to_hub.id
}
