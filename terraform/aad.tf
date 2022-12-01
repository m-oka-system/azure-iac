################################
# User Assigned Managed ID
################################
data "azurerm_subscription" "primary" {
}

# VM
locals {
  app_roles = [
    "Reader",
    "Key Vault Secrets User",
  ]
}
resource "azurerm_user_assigned_identity" "app" {
  name                = "${var.prefix}-${var.env}-app-mngid"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
}

resource "azurerm_role_assignment" "app" {
  count                = length(local.app_roles)
  scope                = "${data.azurerm_subscription.primary.id}/resourceGroups/${azurerm_resource_group.rg.name}"
  role_definition_name = local.app_roles[count.index]
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

# Application Gateway
resource "azurerm_user_assigned_identity" "appgw" {
  name                = "${var.prefix}-${var.env}-appgw-mngid"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
}

resource "azurerm_role_assignment" "kv_reader" {
  scope                = "${data.azurerm_subscription.primary.id}/resourceGroups/${azurerm_resource_group.rg.name}"
  role_definition_name = "Key Vault Reader"
  principal_id         = azurerm_user_assigned_identity.appgw.principal_id
}

# Web App for Containers
locals {
  webappcontainer_roles = [
    "AcrPull",
    "Key Vault Secrets User",
  ]
}
resource "azurerm_user_assigned_identity" "webappcontainer" {
  name                = "${var.prefix}-${var.env}-webappcontainer-mngid"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
}

resource "azurerm_role_assignment" "webappcontainer" {
  count                = length(local.webappcontainer_roles)
  scope                = "${data.azurerm_subscription.primary.id}/resourceGroups/${azurerm_resource_group.rg.name}"
  role_definition_name = local.webappcontainer_roles[count.index]
  principal_id         = azurerm_user_assigned_identity.webappcontainer.principal_id
}

################################
# Key Vault
################################
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "app" {
  name                       = "${var.prefix}-${var.env}-vault"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = var.location
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization  = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  access_policy              = []

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = var.allowed_cidr
    virtual_network_subnet_ids = [
      azurerm_subnet.spoke1_web.id,
      azurerm_subnet.spoke1_app.id,
      azurerm_subnet.spoke2_web.id,
      azurerm_subnet.spoke2_app.id,
    ]
  }
}

# Secret
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

# Certificate
resource "azurerm_key_vault_certificate" "appgw" {
  name         = "${var.prefix}-${var.env}-appgw-selfcert"
  key_vault_id = azurerm_key_vault.app.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry  = 0
        lifetime_percentage = 80
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      extended_key_usage = [
        "1.3.6.1.5.5.7.3.1",
        "1.3.6.1.5.5.7.3.2",
      ]
      key_usage = [
        "digitalSignature",
        "keyEncipherment",
      ]
      subject            = "CN=${var.custom_domain_host_name}.${var.dns_zone_name}"
      validity_in_months = 12

      subject_alternative_names {
        dns_names = [
          "${var.dns_zone_name}",
        ]
      }
    }
  }
}
