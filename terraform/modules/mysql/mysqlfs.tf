##########################################
# Azure Database for MySQL Flexible Server
##########################################
locals {
  mysql_flexible_server_name = "${var.prefix}-${var.env}-mysql${var.random}"
}

resource "azurerm_mysql_flexible_server" "this" {
  name                   = local.mysql_flexible_server_name
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password
  sku_name               = var.db_size
  version                = "8.0.21"
  zone                   = "1"

  backup_retention_days        = 7
  delegated_subnet_id          = var.db_subnet_id
  private_dns_zone_id          = azurerm_private_dns_zone.this.id
  geo_redundant_backup_enabled = false

  storage {
    auto_grow_enabled = true
    iops              = 360
    size_gb           = 20
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.this]
}

resource "azurerm_mysql_flexible_database" "this" {
  name                = var.db_name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.this.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_0900_ai_ci"
}

resource "azurerm_mysql_flexible_server_configuration" "this" {
  name                = "require_secure_transport"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.this.name
  value               = "OFF"
}

resource "azurerm_private_dns_zone" "this" {
  name                = "${local.mysql_flexible_server_name}.private.mysql.database.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  name                  = "mysqlfsVnetZone"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = var.virtual_network_id
}

################################
# Key Vault secrets
################################
resource "azurerm_key_vault_secret" "mysql_host" {
  name         = "MYSQL-HOST"
  value        = azurerm_mysql_flexible_server.this.fqdn
  key_vault_id = var.app_keyvault_id
}

resource "azurerm_key_vault_secret" "mysql_username" {
  name         = "MYSQL-USERNAME"
  value        = var.db_admin_username
  key_vault_id = var.app_keyvault_id
}

resource "azurerm_key_vault_secret" "mysql_password" {
  name         = "MYSQL-PASSWORD"
  value        = var.db_admin_password
  key_vault_id = var.app_keyvault_id
}
