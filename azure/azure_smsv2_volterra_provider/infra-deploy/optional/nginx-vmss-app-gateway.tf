resource "azurerm_virtual_machine_scale_set" "vmss" {
  name                = "arch-nginx-scaleset"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  upgrade_policy_mode = "Automatic"

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
    custom_data = templatefile("${path.module}/templates/nginx.tpl", {
      azure_region       = var.location
      server_number      = "scale-set"
      tailscale_auth_key = var.tailscale_auth_key
      tailscale_hostname = "${var.prefix}-nginx-scale-set"
    })
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
      application_gateway_backend_address_pool_ids = [
        for pool in azurerm_application_gateway.nginx.backend_address_pool : pool.id
        if pool.name == format("%s-backend-pool", var.prefix)
      ]

      public_ip_address_configuration {
        name              = "${var.prefix}-public"
        domain_name_label = azurerm_resource_group.rg.name
        idle_timeout      = 4
      }
    }
  }

  tags = {
    Name   = "nginx-autoscale"
    Source = "terraform"
    Owner  = "s.archer@f5.com"
  }
}

resource "azurerm_subnet" "app-gw" {
  name                 = "app-gw"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.uksouth.name
  address_prefixes     = ["192.168.5.0/24"]
}

resource "azurerm_public_ip" "nginx-app-gw" {
  name                = "nginx-app-gw"
  domain_name_label   = "${var.prefix}-${random_id.id.hex}-nginx"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "nginx" {
  name                = "arch-nginx-app-gw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }

  gateway_ip_configuration {
    name      = format("%s-gw-ip-config", var.prefix)
    subnet_id = azurerm_subnet.app-gw.id
  }

  frontend_port {
    name = format("%s-fe-port", var.prefix)
    port = 80
  }

  frontend_ip_configuration {
    name                 = format("%s-fe-ip-conf", var.prefix)
    public_ip_address_id = azurerm_public_ip.nginx-app-gw.id
  }

  backend_address_pool {
    name = format("%s-backend-pool", var.prefix)
  }

  backend_http_settings {
    name                  = format("%s-backend-http", var.prefix)
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = format("%s-http-listen", var.prefix)
    frontend_ip_configuration_name = format("%s-fe-ip-conf", var.prefix)
    frontend_port_name             = format("%s-fe-port", var.prefix)
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = format("%s-rrr", var.prefix)
    rule_type                  = "Basic"
    http_listener_name         = format("%s-http-listen", var.prefix)
    backend_address_pool_name  = format("%s-backend-pool", var.prefix)
    backend_http_settings_name = format("%s-backend-http", var.prefix)
    priority                   = 10
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

output "nginx_app_gw_ip" {
  value = azurerm_public_ip.nginx-app-gw.ip_address
}

output "nginx_app_gw_fqdn" {
  value = azurerm_public_ip.nginx-app-gw.fqdn
}
