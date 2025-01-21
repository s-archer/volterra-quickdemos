resource "azurerm_lb" "lb" {
  name                = format("%s-lb-%s", var.prefix, random_id.id.hex)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "frontend-ip"
    subnet_id                     = azurerm_subnet.inside.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "allow-all"
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  disable_outbound_snat          = true
  frontend_ip_configuration_name = "frontend-ip"
  probe_id                       = azurerm_lb_probe.lb_probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_pool.id]
}

resource "azurerm_lb_backend_address_pool" "lb_pool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "ce-route-pool"
}

resource "azurerm_network_interface_backend_address_pool_association" "ce" {
  count                   = var.f5xc_sms_node_count
  network_interface_id    = azurerm_network_interface.inside_nic[count.index].id
  ip_configuration_name   = "${var.prefix}-inside-ip-${count.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_pool.id
}

resource "azurerm_lb_probe" "lb_probe" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "test-probe-sli"
  port            = 65450
}

