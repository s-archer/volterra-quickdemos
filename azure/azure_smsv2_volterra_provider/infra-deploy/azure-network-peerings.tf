data "azurerm_virtual_network" "peer-1" {
  name                = "arch-peer-1"
  resource_group_name = "arch-peer-1-rg"
}

data "azurerm_virtual_network" "peer-2" {
  name                = "arch-peer-2"
  resource_group_name = "arch-peer-2-rg"
}

data "azurerm_subnet" "peer-1" {
  name                 = "default"
  virtual_network_name = "arch-peer-1"
  resource_group_name  = "arch-peer-1-rg"
}

data "azurerm_subnet" "peer-2" {
  name                 = "default"
  virtual_network_name = "arch-peer-2"
  resource_group_name  = "arch-peer-2-rg"
}

resource "azurerm_virtual_network_peering" "hub-to-peer1" {
  name                         = "hub-to-peer1"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.uksouth.name
  remote_virtual_network_id    = data.azurerm_virtual_network.peer-1.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "peer1-to-hub" {
  name                         = "peer1-to-hub"
  resource_group_name          = data.azurerm_virtual_network.peer-1.resource_group_name
  virtual_network_name         = data.azurerm_virtual_network.peer-1.name
  remote_virtual_network_id    = azurerm_virtual_network.uksouth.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "hub-to-peer2" {
  name                         = "hub-to-peer2"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.uksouth.name
  remote_virtual_network_id    = data.azurerm_virtual_network.peer-2.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "peer2-to-hub" {
  name                         = "peer2-to-hub"
  resource_group_name          = data.azurerm_virtual_network.peer-2.resource_group_name
  virtual_network_name         = data.azurerm_virtual_network.peer-2.name
  remote_virtual_network_id    = azurerm_virtual_network.uksouth.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}
