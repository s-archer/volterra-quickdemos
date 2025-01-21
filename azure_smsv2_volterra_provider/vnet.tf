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

  tags = {
    environment = "${var.prefix}-demo"
    owner       = var.owner
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

# resource "azurerm_subnet" "app-gw" {
#   name                 = "app-gw"
#   resource_group_name  = azurerm_resource_group.rg.name
#   virtual_network_name = azurerm_virtual_network.uksouth.name
#   address_prefixes     = ["10.0.0.0/24"]
# }

# resource "azurerm_subnet" "dns-endpoint" {
#   name                 = "dns-endpoints"
#   resource_group_name  = azurerm_resource_group.rg.name
#   virtual_network_name = azurerm_virtual_network.uksouth.name
#   address_prefixes     = ["10.0.53.0/24"]

#   delegation {
#     name = "Microsoft.Network.dnsResolvers"
#     service_delegation {
#       actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
#       name    = "Microsoft.Network/dnsResolvers"
#     }
#   }
# }

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

resource "azurerm_route_table" "peer-1" {
  name                = "arch-peer-1-rt"
  location            = azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_virtual_network.peer-1.resource_group_name

  route {
    name                   = "default-route"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_lb.lb.private_ip_address
  }

  route {
    name           = "arch-home-route"
    address_prefix = "90.255.235.127/32"
    next_hop_type  = "Internet"
  }
}

resource "azurerm_route_table" "peer-2" {
  name                = "arch-peer-2-rt"
  location            = azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_virtual_network.peer-2.resource_group_name

  route {
    name                   = "default-route"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_lb.lb.private_ip_address
  }

  route {
    name           = "arch-home-route"
    address_prefix = "90.255.235.127/32"
    next_hop_type  = "Internet"
  }
}

resource "azurerm_subnet_route_table_association" "peer-1" {
  subnet_id      = data.azurerm_subnet.peer-1.id
  route_table_id = azurerm_route_table.peer-1.id
}

resource "azurerm_subnet_route_table_association" "peer-2" {
  subnet_id      = data.azurerm_subnet.peer-2.id
  route_table_id = azurerm_route_table.peer-2.id
}

# resource "azurerm_route_table" "peer-1" {
#   name                = "arch-peer-1-rt"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
# }

# resource "azurerm_route" "peer-1" {
#   name                = "default-route"
#   resource_group_name = azurerm_resource_group.rg.name
#   route_table_name    = azurerm_route_table.peer-1.name
#   address_prefix      = "0.0.0.0/0"
#   next_hop_type       = "VirtualAppliance"
#   next_hop_in_ip_address = azurerm_lb.lb.private_ip_address
# }

# resource "azurerm_route" "peer-1-home" {
#   name                = "arch-home-route"
#   resource_group_name = azurerm_resource_group.rg.name
#   route_table_name    = azurerm_route_table.peer-1.name
#   address_prefix      = "90.255.235.127/32"
#   next_hop_type       = "Internet"
# }

# resource "azurerm_route_table" "peer-2" {
#   name                = "arch-peer-2-rt"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
# }

# resource "azurerm_route" "peer-2" {
#   name                = "default-route"
#   resource_group_name = azurerm_resource_group.rg.name
#   route_table_name    = azurerm_route_table.peer-2.name
#   address_prefix      = "0.0.0.0/0"
#   next_hop_type       = "VirtualAppliance"
#   next_hop_in_ip_address = azurerm_lb.lb.private_ip_address
# }

# resource "azurerm_route" "peer-2-home" {
#   name                = "arch-home-route"
#   resource_group_name = azurerm_resource_group.rg.name
#   route_table_name    = azurerm_route_table.peer-2.name
#   address_prefix      = "90.255.235.127/32"
#   next_hop_type       = "Internet"
# }