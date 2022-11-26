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
  app_subnet_id       = azurerm_subnet.app.id
  vm_size             = var.vm_size
  vm_admin_username   = var.vm_admin_username
  vm_admin_password   = var.vm_admin_password
  source_image_id     = data.azurerm_image.win2022_ja.id
  app_managed_id      = azurerm_user_assigned_identity.app.id
}

module "linux_vm" {
  source = "./modules/vm/linux"

  count               = local.create_count
  prefix              = var.prefix
  suffix              = format("%02d", count.index + 1)
  env                 = var.env
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  app_subnet_id       = azurerm_subnet.app.id
  vm_size             = "Standard_DS1_v2"
  vm_admin_username   = var.vm_admin_username
  app_managed_id      = azurerm_user_assigned_identity.app.id
  depends_on          = [module.mysqlfs]
}

module "vmss" {
  source = "./modules/vmss"

  count                   = local.create_count
  prefix                  = var.prefix
  env                     = var.env
  resource_group_name     = azurerm_resource_group.rg.name
  location                = azurerm_resource_group.rg.location
  app_subnet_id           = azurerm_subnet.app.id
  vm_size                 = "Standard_DS1_v2"
  vm_admin_username       = var.vm_admin_username
  app_managed_id          = azurerm_user_assigned_identity.app.id
  backend_address_pool_id = module.appgw[0].application_gateway_backend_address_pool_id
  depends_on = [
    module.mysqlfs,
    module.appgw,
  ]
}

module "mysqlfs" {
  source = "./modules/mysql"

  count               = local.create_count
  prefix              = var.prefix
  env                 = var.env
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  db_subnet_id        = azurerm_subnet.db.id
  db_name             = var.db_name
  db_admin_username   = var.db_admin_username
  db_admin_password   = var.db_admin_password
  db_size             = var.db_size
  virtual_network_id  = azurerm_virtual_network.spoke1.id
  random              = random_integer.num.result
  app_keyvault_id     = azurerm_key_vault.app.id
}

module "appservice" {
  source = "./modules/appservice/f1"

  count               = local.create_count
  prefix              = var.prefix
  env                 = var.env
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  random              = random_integer.num.result
}

module "bastion" {
  source = "./modules/bastion"

  count               = local.create_count
  prefix              = var.prefix
  env                 = var.env
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  bastion_subnet_id   = azurerm_subnet.bastion.id

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

module "appgw" {
  source = "./modules/applicationgateway"

  count                              = local.create_count
  prefix                             = var.prefix
  env                                = var.env
  resource_group_name                = azurerm_resource_group.rg.name
  location                           = azurerm_resource_group.rg.location
  web_subnet_id                      = azurerm_subnet.web.id
  appgw_managed_id                   = azurerm_user_assigned_identity.appgw.id
  app_selfcert_name                  = azurerm_key_vault_certificate.appgw.name
  app_selfcert_versionless_secret_id = azurerm_key_vault_certificate.appgw.versionless_secret_id
}

module "dns" {
  source = "./modules/dns"

  count               = local.create_count
  prefix              = var.prefix
  env                 = var.env
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  dns_zone_name       = var.dns_zone_name
  target_resource_id  = module.appgw[0].appgw_public_ip
  depends_on          = [module.appgw]
}

module "vpngw" {
  source = "./modules/vpngw"

  count               = local.create_count
  prefix              = var.prefix
  env                 = var.env
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  gateway_subnet_id   = azurerm_subnet.gateway.id
}

module "webappcontainer" {
  source = "./modules/appservice/container"

  count                      = local.create_count
  prefix                     = var.prefix
  env                        = var.env
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  webappcontainer_managed_id = azurerm_user_assigned_identity.webappcontainer.id
}
