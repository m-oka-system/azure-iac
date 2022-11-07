terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "http" {}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-${var.env}-rg"
  location = var.location
}

module "vm" {
  source = "./modules/vm"

  count               = local.create_count
  prefix              = var.prefix
  env                 = var.env
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  public_subnet_id    = azurerm_subnet.public.id
  vm_size             = var.vm_size
  vm_admin_username   = var.vm_admin_username
  vm_admin_password   = var.vm_admin_password
  source_image_id     = data.azurerm_image.win2022_ja.id
}

module "loadbalancer" {
  source = "./modules/loadbalancer"

  count                = local.create_count
  prefix               = var.prefix
  env                  = var.env
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  network_interface_id = module.vm[0].network_interface_id
}
