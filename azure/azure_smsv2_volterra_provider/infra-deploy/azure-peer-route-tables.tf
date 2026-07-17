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
