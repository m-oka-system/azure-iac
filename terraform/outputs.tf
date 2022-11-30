output "dns_zone_name_servers" {
  value = azurerm_dns_zone.public.name_servers
}
