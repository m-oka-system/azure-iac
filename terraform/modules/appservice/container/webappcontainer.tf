################################
# Web App for Containers
################################
locals {
  container_registry_name = "${var.prefix}${var.env}acr"
}

resource "azurerm_container_registry" "this" {
  name                = local.container_registry_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_service_plan" "this" {
  name                = "${var.prefix}-${var.env}-plan"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "this" {
  name                = "${var.prefix}-${var.env}-app-${var.random}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.this.id
  https_only          = true

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL"          = "https://${local.container_registry_name}.azurecr.io"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "WEBSITES_PORT"                       = "3000"
    "RAILS_ENV"                           = "production"
    "RAILS_SERVE_STATIC_FILES"            = "1"
    "RDS_HOST_NAME"                       = "@Microsoft.KeyVault(VaultName=${var.vault_name};SecretName=MYSQL-HOST)"
    "MYSQL_ROOT_USER"                     = "@Microsoft.KeyVault(VaultName=${var.vault_name};SecretName=MYSQL-USERNAME)"
    "MYSQL_ROOT_PASSWORD"                 = "@Microsoft.KeyVault(VaultName=${var.vault_name};SecretName=MYSQL-PASSWORD)"
    "SECRET_KEY_BASE"                     = "@Microsoft.KeyVault(SecretUri=${var.secret_key_base_uri})"
  }

  # Use Key Vault references for App Service
  # https://learn.microsoft.com/ja-jp/azure/app-service/app-service-key-vault-references
  key_vault_reference_identity_id = var.webappcontainer_managed_id

  identity {
    type = "UserAssigned"
    identity_ids = [
      var.webappcontainer_managed_id
    ]
  }

  site_config {
    always_on              = false
    ftps_state             = "Disabled"
    vnet_route_all_enabled = true # Vnet integration

    container_registry_use_managed_identity       = true
    container_registry_managed_identity_client_id = var.webappcontainer_client_id

    application_stack {
      docker_image     = "${azurerm_container_registry.this.login_server}/${var.docker_image_name}"
      docker_image_tag = var.docker_image_tag
    }
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "this" {
  app_service_id = azurerm_linux_web_app.this.id
  subnet_id      = var.webappcontainer_subnet_id
}
