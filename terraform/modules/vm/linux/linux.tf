
#################################
# Virtual machines
################################
resource "azurerm_public_ip" "this" {
  name                = "${var.prefix}-${var.env}-linux-vm-ip-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = ["1", "2", "3"]
}

resource "azurerm_network_interface" "this" {
  name                = "${var.prefix}-${var.env}-linux-vm-nic-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.app_subnet_id
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = "${var.prefix}-${var.env}-linux-vm-${var.suffix}"
  computer_name       = "${var.prefix}${var.env}linuxvm${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.vm_admin_username
  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]

  priority        = "Spot"
  max_bid_price   = -1
  eviction_policy = "Deallocate"

  allow_extension_operations      = true
  disable_password_authentication = true
  encryption_at_host_enabled      = false
  patch_mode                      = "ImageDefault"
  secure_boot_enabled             = false
  vtpm_enabled                    = false
  custom_data                     = filebase64("${path.module}/userdata.sh")

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  boot_diagnostics {}

  os_disk {
    name                      = "${var.prefix}-${var.env}-linux-vm-osdisk-${var.suffix}"
    caching                   = "ReadWrite"
    storage_account_type      = "Standard_LRS"
    disk_size_gb              = 30
    write_accelerator_enabled = false
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      var.app_managed_id
    ]
  }

  source_image_reference {
    offer     = "0001-com-ubuntu-server-focal"
    publisher = "canonical"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

}

