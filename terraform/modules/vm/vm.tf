#################################
# Virtual machines
################################
resource "azurerm_public_ip" "vm_ip" {
  name                = "${var.prefix}-${var.env}-vm-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "vm_nic" {
  name                = "${var.prefix}-${var.env}-vm-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.public_subnet_id
    public_ip_address_id          = azurerm_public_ip.vm_ip.id
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = "${var.prefix}-${var.env}-vm"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  priority            = "Regular"
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password
  timezone            = "Tokyo Standard Time"
  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]

  os_disk {
    name                 = "${var.prefix}-${var.env}-vm-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_id = var.source_image_id
}

