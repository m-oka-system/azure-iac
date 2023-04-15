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
  name                      = "${var.prefix}-${var.env}-app-${var.random}"
  resource_group_name       = var.resource_group_name
  location                  = var.location
  service_plan_id           = azurerm_service_plan.this.id
  virtual_network_subnet_id = var.webappcontainer_subnet_id
  https_only                = true

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL"          = "https://${local.container_registry_name}.azurecr.io"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "WEBSITES_PORT"                       = "3000"
    "RAILS_ENV"                           = "production"
    "RAILS_SERVE_STATIC_FILES"            = "1"
    "DB_HOST"                             = "@Microsoft.KeyVault(VaultName=${var.app_keyvault_name};SecretName=DB-HOST)"
    "DB_USERNAME"                         = "@Microsoft.KeyVault(VaultName=${var.app_keyvault_name};SecretName=DB-USERNAME)"
    "DB_PASSWORD"                         = "@Microsoft.KeyVault(VaultName=${var.app_keyvault_name};SecretName=DB-PASSWORD)"
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

    ip_restriction {
      name        = "AllowFrontDoorAddress"
      priority    = 100
      action      = "Allow"
      service_tag = "AzureFrontDoor.Backend"
      headers = [{
        x_azure_fdid      = [var.frontdoor_id] # Input Azure Front Door ID
        x_fd_health_probe = null
        x_forwarded_for   = null
        x_forwarded_host  = null
      }]
    }
  }

  lifecycle {
    ignore_changes = [site_config[0].application_stack[0].docker_image_tag]
  }
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "${azurerm_linux_web_app.this.name}-logs"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# az monitor diagnostic-settings categories list --resource {resource_id} --query value[].name -o tsv
data "azurerm_monitor_diagnostic_categories" "this" {
  resource_id = azurerm_linux_web_app.this.id
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = "${azurerm_linux_web_app.this.name}-diag-setting"
  target_resource_id         = azurerm_linux_web_app.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.this.log_category_types

    content {
      category = entry.value #AppServiceHTTPLogs/AppServiceConsoleLogs/AppServiceAppLogs/AppServiceAuditLogs/AppServiceIPSecAuditLogs/AppServicePlatformLogs/AllMetrics
      enabled  = true

      retention_policy {
        enabled = true
        days    = 30
      }
    }
  }

  dynamic "metric" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.this.metrics

    content {
      category = entry.value #AllMetrics
      enabled  = true

      retention_policy {
        enabled = true
        days    = 30
      }
    }
  }
}
