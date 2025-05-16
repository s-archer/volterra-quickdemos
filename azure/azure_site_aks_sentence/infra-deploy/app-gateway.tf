resource "azurerm_public_ip" "nginx-app-gw" {
  name                = "nginx-app-gw"
  domain_name_label   = "arch-nginx-app-gw"
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
    name         = format("%s-backend-pool", var.prefix)
    ip_addresses = data.azurerm_virtual_machine_scale_set.vmss.instances[*].public_ip_address
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
