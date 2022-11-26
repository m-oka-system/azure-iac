#################################
# Virtual machine Scale Sets
################################
locals {
  virtual_machine_scale_set_name = "${var.prefix}-${var.env}-vmss"
}

resource "azurerm_linux_virtual_machine_scale_set" "this" {
  name                 = local.virtual_machine_scale_set_name
  computer_name_prefix = "${var.prefix}-${var.env}-vm"
  resource_group_name  = var.resource_group_name
  location             = var.location
  sku                  = var.vm_size
  instances            = 1
  admin_username       = var.vm_admin_username

  priority        = "Spot"
  max_bid_price   = -1
  eviction_policy = "Deallocate"

  disable_password_authentication = true
  overprovision                   = false
  encryption_at_host_enabled      = false
  upgrade_mode                    = "Manual"
  scale_in_policy                 = "Default"
  secure_boot_enabled             = false
  vtpm_enabled                    = false
  zone_balance                    = true
  zones                           = ["1", "2", "3"]
  custom_data                     = filebase64("${path.module}/userdata.sh")

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  network_interface {
    name    = "${local.virtual_machine_scale_set_name}-nic"
    primary = true

    ip_configuration {
      name                                         = "ipconfig1"
      primary                                      = true
      subnet_id                                    = var.app_subnet_id
      version                                      = "IPv4"
      application_gateway_backend_address_pool_ids = [var.backend_address_pool_id]

      public_ip_address {
        name                    = "${local.virtual_machine_scale_set_name}-ip"
        idle_timeout_in_minutes = 15
      }
    }
  }

  boot_diagnostics {}

  os_disk {
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

resource "azurerm_monitor_autoscale_setting" "this" {
  name                = "${local.virtual_machine_scale_set_name}-autoscale"
  enabled             = true
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.this.id

  profile {
    name = "Profile1"

    capacity {
      default = 1
      minimum = 1
      maximum = 2
    }

    rule {
      metric_trigger {
        metric_name              = "Percentage CPU"
        metric_resource_id       = azurerm_linux_virtual_machine_scale_set.this.id
        divide_by_instance_count = true
        statistic                = "Average"
        time_window              = "PT10M"
        operator                 = "GreaterThan"
        threshold                = 80
        time_grain               = "PT1M"
        time_aggregation         = "Average"
      }

      scale_action {
        cooldown  = "PT1M"
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1
      }
    }

    rule {
      metric_trigger {
        metric_name              = "Percentage CPU"
        metric_resource_id       = azurerm_linux_virtual_machine_scale_set.this.id
        divide_by_instance_count = true
        statistic                = "Average"
        time_window              = "PT10M"
        operator                 = "LessThan"
        threshold                = 20
        time_grain               = "PT1M"
        time_aggregation         = "Average"
      }

      scale_action {
        cooldown  = "PT1M"
        direction = "Decrease"
        type      = "ChangeCount"
        value     = 1
      }
    }
  }
}
