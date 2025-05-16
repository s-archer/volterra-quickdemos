resource "random_string" "password" {
  length      = 10
  special     = false
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
}

resource "azurerm_virtual_machine_scale_set" "vmss" {
  name                = "arch-nginx-we-scaleset"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  upgrade_policy_mode = "Manual"

  sku {
    name     = "Standard_DS1_v2"
    tier     = "Standard"
    capacity = 2
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
  }

  os_profile {
    computer_name_prefix = "vmlab"
    admin_username       = "azureuser"
    admin_password       = random_string.password.result
    custom_data          = file("./templates/nginx.tpl")
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  network_profile {
    name    = "terraformnetworkprofile"
    primary = true

    ip_configuration {
      name      = "IPConfiguration"
      subnet_id = azurerm_subnet.workers.id
      primary   = true
      public_ip_address_configuration {
        name              = "${var.prefix}-public"
        domain_name_label = azurerm_resource_group.rg.name
        idle_timeout      = 4
      }
    }
  }

  tags = {
    Name   = "nginx-autoscale-we"
    Source = "terraform"
    Owner  = "s.archer@f5.com"
  }
}

data "azurerm_virtual_machine_scale_set" "vmss" {
  name                = azurerm_virtual_machine_scale_set.vmss.name
  resource_group_name = azurerm_resource_group.rg.name
}

output "nginx_ips" {
  value = data.azurerm_virtual_machine_scale_set.vmss.instances[*].public_ip_address
}

output "nginx_username" {
  value = "azureuser"
}

output "nginx_password" {
  value = random_string.password.result
}