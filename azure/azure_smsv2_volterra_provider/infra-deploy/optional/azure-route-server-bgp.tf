resource "volterra_bgp" "bgp-node" {
  name      = format("%s-bgp", local.f5xc_sms_name)
  namespace = "system"

  bgp_parameters {
    asn           = "65503"
    local_address = true
  }

  peers {
    metadata {
      description = "Azure Route Server"
      # disable = false
      name = "arure-rs1"
    }
    passive_mode_disabled = true
    external {
      address           = sort(tolist(azurerm_route_server.router.virtual_router_ips))[0]
      port              = 179
      disable_v6        = true
      asn               = "65515"
      no_authentication = true
      family_inet {
        enable = true
      }
      family_inet_v6 {
        disable = true
      }
      interface {
        # system/ves-io-securemesh-site-v2-arch-azure-smsv2-vt-prov-site-e3c7-node-0-network-arch-azure-smsv2-vt-prov-node-0-eth1-0
        name      = format("ves-io-securemesh-site-v2-%s-network-%s-eth1-0", volterra_securemesh_site_v2.site[0].name, "${var.prefix}-node-0")
        namespace = "system"
      }
    }
  }

  where {
    site {
      disable_internet_vip = true
      network_type         = "VIRTUAL_NETWORK_SITE_LOCAL"

      ref {
        name      = volterra_securemesh_site_v2.site[0].name
        namespace = "system"
      }
    }
  }
}

resource "azurerm_subnet" "RouteServerSubnet" {
  name                 = "RouteServerSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.uksouth.name
  address_prefixes     = ["192.168.5.0/24"]
}

resource "azurerm_public_ip" "router-ip" {
  name                = "arch-router-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_route_server" "router" {
  name                             = "arch-routerserver"
  resource_group_name              = azurerm_resource_group.rg.name
  location                         = azurerm_resource_group.rg.location
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.router-ip.id
  subnet_id                        = azurerm_subnet.RouteServerSubnet.id
  branch_to_branch_traffic_enabled = true
  # hub_routing_preference           = "ASPath"
}

resource "azurerm_route_server_bgp_connection" "bgp" {
  count           = var.f5xc_sms_node_count
  name            = "arch-rs-bgpconnection"
  route_server_id = azurerm_route_server.router.id
  peer_asn        = 65503
  peer_ip         = azurerm_network_interface.inside_nic[count.index].private_ip_address
}

# resource "azurerm_route_map" "filter_vnet" {
#   name                = "filter-vnet-prefixes"
#   resource_group_name = azurerm_resource_group.example.name
#   location            = azurerm_resource_group.example.location
#   route_server_id     = azurerm_route_server.rs.id
# }

# resource "azurerm_route_map_rule" "allow_subnet103" {
#   name         = "allow-subnet103"
#   route_map_id = azurerm_route_map.filter_vnet.id
#   sequence     = 103
#   action       = "Permit"

#   match_criteria {
#     match_condition = "Equals"
#     route_prefix    = "192.168.3.0/24"
#   }
# }

# resource "azurerm_route_map_rule" "allow_subnet104" {
#   name         = "allow-subnet104"
#   route_map_id = azurerm_route_map.filter_vnet.id
#   sequence     = 104
#   action       = "Permit"

#   match_criteria {
#     match_condition = "Equals"
#     route_prefix    = "192.168.4.0/24"
#   }
# }

# resource "azurerm_route_map_rule" "deny_others" {
#   name         = "deny-others"
#   route_map_id = azurerm_route_map.filter_vnet.id
#   sequence     = 200
#   action       = "Deny"
# }