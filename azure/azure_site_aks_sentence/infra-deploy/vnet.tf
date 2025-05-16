resource "azurerm_resource_group" "rg" {
  name     = format("%srg-%s", var.prefix, random_id.id.hex)
  location = var.location
}

resource "azurerm_virtual_network" "uksouth" {
  name                = "${var.prefix}1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  # dns_servers         = ["8.8.8.8", "8.8.4.4"]

  # subnet {
  #   name           = "outside"
  #   address_prefix = "10.0.101.0/24"
  # }

  # subnet {
  #   name           = "inside"
  #   address_prefix = "10.0.102.0/24"
  # }

  # subnet {
  #   name           = "workers"
  #   address_prefix = "10.0.103.0/24"
  # }

  # subnet {
  #   name           = "app-gw"
  #   address_prefix = "10.0.0.0/24"
  #   #security_group = azurerm_network_security_group.example.id
  # }

  tags = {
    environment = "${var.prefix}demo"
    uk-se       = var.uk_se_name
  }
}

resource "azurerm_subnet" "outside" {
  name                 = "outside"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.uksouth.name
  address_prefixes     = ["10.0.101.0/24"]
}

resource "azurerm_subnet" "inside" {
  name                 = "inside"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.uksouth.name
  address_prefixes     = ["10.0.102.0/24"]
}

resource "azurerm_subnet" "workers" {
  name                 = "workers"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.uksouth.name
  address_prefixes     = ["10.0.103.0/24"]
}

resource "azurerm_subnet" "app-gw" {
  name                 = "app-gw"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.uksouth.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "dns-endpoint" {
  name                 = "dns-endpoints"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.uksouth.name
  address_prefixes     = ["10.0.53.0/24"]

  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.Network/dnsResolvers"
    }
  }
}