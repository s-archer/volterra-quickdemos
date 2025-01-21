data "http" "myip" {
  url = "https://ifconfig.me"
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
  name                        = "Allow_ssh"
  priority                    = 202
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  destination_address_prefix  = "*"
  source_address_prefixes     = ["${data.http.myip.response_body}/32"]
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
  destination_address_prefix  = "10.0.0.0/8"
  source_address_prefixes     = ["10.0.0.0/8"]
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = format("%s-inside-nsg-%s", var.prefix, random_id.id.hex)
  depends_on                  = [module.inside-network-security-group-public]
}