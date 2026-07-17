data "http" "myip" {
  url = "https://ifconfig.me/ip"
}

# Create the Network Security group Module to associate with BIGIP-outside-Nic
#
module "outside-network-security-group" {
  source              = "Azure/network-security-group/azurerm"
  resource_group_name = azurerm_resource_group.rg.name
  security_group_name = format("%s-outside-nsg-%s", var.prefix, random_id.id.hex)
  tags = {
    environment = "dev"
    costcenter  = "terraform"
  }
}

#
# Create the Network Security group Module to associate with BIGIP-inside-Nic
#
module "inside-network-security-group-public" {
  source              = "Azure/network-security-group/azurerm"
  resource_group_name = azurerm_resource_group.rg.name
  security_group_name = format("%s-inside-nsg-%s", var.prefix, random_id.id.hex)
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
  network_security_group_name = format("%s-outside-nsg-%s", var.prefix, random_id.id.hex)
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
  network_security_group_name = format("%s-outside-nsg-%s", var.prefix, random_id.id.hex)
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
  network_security_group_name = format("%s-outside-nsg-%s", var.prefix, random_id.id.hex)
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
  network_security_group_name = format("%s-inside-nsg-%s", var.prefix, random_id.id.hex)
  depends_on                  = [module.inside-network-security-group-public]
}

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
  network_security_group_name = format("%s-inside-nsg-%s", var.prefix, random_id.id.hex)
  depends_on                  = [module.inside-network-security-group-public]
}
