################################
# Web App for Containers
################################
resource "azurerm_container_registry" "this" {
  name                = "${var.prefix}${var.env}acr"
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
