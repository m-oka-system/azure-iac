resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.region
}

module "vnet" {
  source = "./modules/vnet"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  vnet_name           = "${var.prefix}-vnet"
  public_subnet_name  = "public-subnet"
}
