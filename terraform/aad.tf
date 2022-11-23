################################
# User Assigned Managed ID
################################
resource "azurerm_user_assigned_identity" "app" {
  name                = "${var.prefix}-${var.env}-app-mngid"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
}

data "azurerm_subscription" "primary" {
}

resource "azurerm_role_assignment" "reader" {
  scope                = "${data.azurerm_subscription.primary.id}/resourceGroups/${azurerm_resource_group.rg.name}"
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = "${data.azurerm_subscription.primary.id}/resourceGroups/${azurerm_resource_group.rg.name}"
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

################################
# Key Vault
################################
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "app" {
  name                       = "tf-dev-vault"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = var.location
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization  = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  access_policy              = []

  network_acls {
    bypass         = "None"
    default_action = "Deny"
    ip_rules       = var.allowed_cidr
    virtual_network_subnet_ids = [
      azurerm_subnet.app.id
    ]
  }
}

resource "azurerm_key_vault_secret" "docker_username" {
  name         = "DOCKER-USERNAME"
  value        = var.docker_username
  key_vault_id = azurerm_key_vault.app.id
}

resource "azurerm_key_vault_secret" "docker_password" {
  name         = "DOCKER-PASSWORD"
  value        = var.docker_password
  key_vault_id = azurerm_key_vault.app.id
}

resource "azurerm_key_vault_secret" "secret_key_base" {
  name         = "SECRET-KEY-BASE"
  value        = var.secret_key_base
  key_vault_id = azurerm_key_vault.app.id
}
