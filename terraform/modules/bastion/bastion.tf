################################
# Bastion
################################
resource "azurerm_public_ip" "this" {
  name                = "${var.prefix}-${var.env}-bastion-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

resource "azurerm_bastion_host" "this" {
  name                = "HubBastion"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  scale_units         = 2

  copy_paste_enabled     = true
  ip_connect_enabled     = true
  tunneling_enabled      = true
  file_copy_enabled      = true
  shareable_link_enabled = false

  ip_configuration {
    name                 = "IpConf"
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.this.id
  }
}
