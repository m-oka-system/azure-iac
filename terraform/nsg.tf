#################################
# Network security group
################################
# Web
resource "azurerm_network_security_group" "web" {
  name                = "web-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.network_rg.name
}

resource "azurerm_network_security_rule" "http" {
  name                        = "AllowAnyHTTPInbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.network_rg.name
  network_security_group_name = azurerm_network_security_group.web.name
}

resource "azurerm_network_security_rule" "https" {
  name                        = "AllowAnyHTTPSInbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.network_rg.name
  network_security_group_name = azurerm_network_security_group.web.name
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.web.id
}

# Bastion
resource "azurerm_network_security_group" "bastion" {
  name                = "bastion-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.network_rg.name
}

resource "azurerm_network_security_rule" "rdp" {
  name                        = "AllowMyIpAddressRDPInbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefixes     = var.allowed_cidr
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.network_rg.name
  network_security_group_name = azurerm_network_security_group.bastion.name
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "AllowMyIpAddressSSHInbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = var.allowed_cidr
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.network_rg.name
  network_security_group_name = azurerm_network_security_group.bastion.name
}

## When deploying from a local machine
# data "http" "ipify" {
#   url = "http://api.ipify.org"
# }

# locals {
#   myip         = chomp(data.http.ipify.response_body)
#   allowed_cidr = "${local.myip}/32"
# }
