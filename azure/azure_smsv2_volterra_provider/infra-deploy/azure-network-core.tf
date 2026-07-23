resource "azurerm_resource_group" "rg" {
  name     = format("%s-rg", var.prefix)
  location = var.location
}

resource "azurerm_virtual_network" "uksouth" {
  name                = "${var.prefix}1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["192.168.0.0/16"]
  # dns_servers         = ["8.8.8.8", "8.8.4.4"]

  tags = {
    environment = "${var.prefix}-demo"
    owner       = var.owner
  }
}

resource "azurerm_subnet" "outside" {
  name                 = "outside"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.uksouth.name
  address_prefixes     = ["192.168.1.0/24"]
}

resource "azurerm_subnet" "inside" {
  name                 = "inside"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.uksouth.name
  address_prefixes     = ["192.168.2.0/24"]
}

resource "azurerm_subnet" "workers" {
  name                 = "workers"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.uksouth.name
  address_prefixes     = ["192.168.3.0/24"]
}

resource "azurerm_subnet" "other" {
  name                 = "other"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.uksouth.name
  address_prefixes     = ["192.168.4.0/24"]
}

# resource "azurerm_subnet" "app-gw" {
#   name                 = "app-gw"
#   resource_group_name  = azurerm_resource_group.rg.name
#   virtual_network_name = azurerm_virtual_network.uksouth.name
#   address_prefixes     = ["192.168.0.0/24"]
# }

# resource "azurerm_subnet" "dns-endpoint" {
#   name                 = "dns-endpoints"
#   resource_group_name  = azurerm_resource_group.rg.name
#   virtual_network_name = azurerm_virtual_network.uksouth.name
#   address_prefixes     = ["192.168.53.0/24"]
#
#   delegation {
#     name = "Microsoft.Network.dnsResolvers"
#     service_delegation {
#       actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
#       name    = "Microsoft.Network/dnsResolvers"
#     }
#   }
# }
