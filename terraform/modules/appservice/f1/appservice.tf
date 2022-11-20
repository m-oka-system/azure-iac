resource "azurerm_windows_web_app" "this" {
  name                = "${var.prefix}-${var.env}-app-${var.random}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.this.id
  https_only          = true

  site_config {
    always_on  = false
    ftps_state = "Disabled"

    virtual_application {
      physical_path = "site\\wwwroot"
      preload       = false
      virtual_path  = "/"
    }

    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v6.0"
    }
  }
}

resource "azurerm_service_plan" "this" {
  name                = "${var.prefix}-${var.env}-plan"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Windows"
  sku_name            = "F1"
}
