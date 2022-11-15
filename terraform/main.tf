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

resource "random_integer" "num" {
  min = 10000
  max = 99999
}

module "windows_vm" {
  source = "./modules/vm/windows"

  count               = local.create_count
  prefix              = var.prefix
  env                 = var.env
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  public_subnet_id    = azurerm_subnet.web.id
  vm_size             = var.vm_size
  vm_admin_username   = var.vm_admin_username
  vm_admin_password   = var.vm_admin_password
  source_image_id     = data.azurerm_image.win2022_ja.id
}

module "linux_vm" {
  source = "./modules/vm/linux"

  count               = local.create_count
  prefix              = var.prefix
  env                 = var.env
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  public_subnet_id    = azurerm_subnet.web.id
  vm_size             = "Standard_DS1_v2"
  vm_admin_username   = var.vm_admin_username
}

module "loadbalancer" {
  source = "./modules/loadbalancer"

  count                = local.create_count
  prefix               = var.prefix
  env                  = var.env
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  network_interface_id = module.windows_vm[0].network_interface_id
}

module "mysql" {
  source = "./modules/mysql"

  count               = 0
  prefix              = var.prefix
  env                 = var.env
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  db_subnet_id        = azurerm_subnet.db.id
  db_name             = var.db_name
  db_admin_username   = var.db_admin_username
  db_admin_password   = var.db_admin_password
  db_size             = var.db_size
  db_subnet_cidr      = trimsuffix(cidrsubnet(azurerm_subnet.db.address_prefixes[0], 8, 4), "/32") #10.0.2.0/24 -> 10.0.2.4
  virtual_network_id  = azurerm_virtual_network.vnet.id
  random              = random_integer.num.result
}
