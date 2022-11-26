output "appgw_public_ip" {
  value = azurerm_public_ip.this.id
}

output "application_gateway_backend_address_pool_id" {
  value = tolist(azurerm_application_gateway.this.backend_address_pool).0.id
}