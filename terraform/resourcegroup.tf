resource "azurerm_resource_group" "network_rg" {
  name     = "${var.prefix}-network-rg"
  location = var.location
}

resource "azurerm_resource_group" "server_rg" {
  name     = "${var.prefix}-server-rg"
  location = var.location
}
