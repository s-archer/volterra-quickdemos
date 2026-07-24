data "http" "myip" {
  url = "https://ifconfig.me/ip"
}

# Create the Network Security group Module to associate with BIGIP-outside-Nic
#
module "outside-network-security-group" {
  depends_on          = [azurerm_resource_group.rg]
  source              = "Azure/network-security-group/azurerm"
  resource_group_name = azurerm_resource_group.rg.name
  security_group_name = format("%s-outside-nsg", var.prefix)
  tags = {
    environment = "dev"
    costcenter  = "terraform"
  }
}

#
# Create the Network Security group Module to associate with BIGIP-inside-Nic
#
module "inside-network-security-group-public" {
  depends_on          = [azurerm_resource_group.rg]
  source              = "Azure/network-security-group/azurerm"
  resource_group_name = azurerm_resource_group.rg.name
  security_group_name = format("%s-inside-nsg", var.prefix)
  tags = {
    environment = "dev"
    costcenter  = "terraform"
  }
}

resource "azurerm_network_security_rule" "outside_allow_https" {
  name                        = "Allow_Https"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  destination_address_prefix  = "*"
  source_address_prefixes     = ["0.0.0.0/0"]
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = format("%s-outside-nsg", var.prefix)
  depends_on                  = [module.outside-network-security-group]
}

resource "azurerm_network_security_rule" "outside_allow_ssh" {
  name                       = "Allow_ssh"
  priority                   = 201
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  destination_address_prefix = "*"
  source_address_prefixes    = ["${data.http.myip.response_body}/32"]
  # source_address_prefixes     = ["90.255.235.127/32"]
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = format("%s-outside-nsg", var.prefix)
  depends_on                  = [module.outside-network-security-group]
}

resource "azurerm_network_security_rule" "outside_allow_ipsec" {
  name                       = "Allow_ipsec"
  priority                   = 202
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Udp"
  source_port_range          = "*"
  destination_port_range     = "4500"
  destination_address_prefix = "*"
  # source_address_prefixes     = ["${data.http.myip.response_body}/32"]
  source_address_prefixes     = ["0.0.0.0/0"]
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = format("%s-outside-nsg", var.prefix)
  depends_on                  = [module.outside-network-security-group]
}

resource "azurerm_network_security_rule" "outside_allow_ipsec_ike" {
  name                        = "Allow_ipsec_ike"
  priority                    = 203
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "500"
  destination_address_prefix  = "*"
  source_address_prefixes     = ["0.0.0.0/0"]
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = format("%s-outside-nsg", var.prefix)
  depends_on                  = [module.outside-network-security-group]
}

resource "azurerm_network_security_rule" "outside_allow_ipsec_esp" {
  name                        = "Allow_ipsec_esp"
  priority                    = 204
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Esp"
  source_port_range           = "*"
  destination_port_range      = "*"
  destination_address_prefix  = "*"
  source_address_prefixes     = ["0.0.0.0/0"]
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = format("%s-outside-nsg", var.prefix)
  depends_on                  = [module.outside-network-security-group]
}

resource "azurerm_network_security_rule" "inside_allow_https" {
  name                        = "Allow_Https"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  destination_address_prefix  = "192.168.0.0/16"
  source_address_prefixes     = ["192.168.0.0/16"]
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = format("%s-inside-nsg", var.prefix)
  depends_on                  = [module.inside-network-security-group-public]
}

resource "azurerm_network_security_group" "nginx_vms" {
  name                = "${var.prefix}-nginx_vms-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    Name   = "nginx_vms"
    Source = "terraform"
    Owner  = var.uk_se_name
  }
}

resource "azurerm_network_security_rule" "nginx_vms_allow_ssh" {
  name                        = "Allow_ssh_nginx"
  priority                    = 201
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  destination_address_prefix  = "*"
  source_address_prefixes     = ["${data.http.myip.response_body}/32"]
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nginx_vms.name
}

resource "azurerm_network_security_rule" "nginx_vms_allow_all_egress" {
  name                        = "Allow_all_egress_nginx"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nginx_vms.name
}

resource "azurerm_network_interface_security_group_association" "nginx_vms" {
  count                     = var.vm_count
  network_interface_id      = azurerm_network_interface.nginx[count.index].id
  network_security_group_id = azurerm_network_security_group.nginx_vms.id
}

resource "azurerm_network_security_group" "tailscale_subnet_router" {
  name                = "${var.prefix}-tailscale-subnet-router-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    Name   = "tailscale-subnet-router"
    Source = "terraform"
    Owner  = var.uk_se_name
  }
}

resource "azurerm_network_security_rule" "tailscale_subnet_router_allow_ssh" {
  name                        = "Allow_ssh_tailscale"
  priority                    = 201
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  destination_address_prefix  = "*"
  source_address_prefixes     = ["${data.http.myip.response_body}/32"]
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.tailscale_subnet_router.name
}

resource "azurerm_network_security_rule" "tailscale_subnet_router_allow_all_egress" {
  name                        = "Allow_all_egress_tailscale"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.tailscale_subnet_router.name
}

resource "azurerm_network_interface_security_group_association" "tailscale_subnet_router" {
  network_interface_id      = azurerm_network_interface.tailscale_subnet_router.id
  network_security_group_id = azurerm_network_security_group.tailscale_subnet_router.id
}

resource "azurerm_network_interface_security_group_association" "outside_security" {
  count                     = var.f5xc_sms_node_count
  network_interface_id      = azurerm_network_interface.outside_nic[count.index].id
  network_security_group_id = module.outside-network-security-group.network_security_group_id
}

resource "azurerm_network_interface_security_group_association" "inside_security" {
  count                     = var.f5xc_sms_node_count
  network_interface_id      = azurerm_network_interface.inside_nic[count.index].id
  network_security_group_id = module.inside-network-security-group-public.network_security_group_id
}

# resource "azurerm_network_interface_security_group_association" "other_security" {
#   count                     = var.f5xc_sms_node_count
#   network_interface_id      = azurerm_network_interface.other_nic[count.index].id
#   network_security_group_id = module.inside-network-security-group-public.network_security_group_id
# }

resource "azurerm_network_security_rule" "inside_allow_bgp" {
  name                        = "Allow_BGP"
  priority                    = 201
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "179"
  destination_address_prefix  = "192.168.0.0/16"
  source_address_prefixes     = ["192.168.0.0/16"]
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = format("%s-inside-nsg", var.prefix)
  depends_on                  = [module.inside-network-security-group-public]
}
