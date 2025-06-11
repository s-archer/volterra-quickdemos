resource "volterra_virtual_network" "bgp" {
  name      = format("%s-slo-bgp", var.prefix)
  namespace = "system"
  # single NIC SLO 
  site_local_network = true
}


resource "volterra_network_interface" "bgp" {
  name      = format("%s-slo-bgp", var.prefix)
  namespace = "system"

  dedicated_interface {
    device     = "eth0"
    is_primary = true
  }
}

# {
#   "metadata": {
#     "name": "arch-bgp-slo",
#     "namespace": "system",
#     "labels": {},
#     "annotations": {},
#     "description": "Used for home NUC",
#     "disable": false
#   },
#   "spec": {
#     "type": "NETWORK_INTERFACE_ETHERNET",
#     "mtu": 0,
#     "dhcp_address": "NETWORK_INTERFACE_DHCP_DISABLE",
#     "static_addresses": [],
#     "DHCP_server": "NETWORK_INTERFACE_DHCP_SERVER_DISABLE",
#     "vlan_tagging": "NETWORK_INTERFACE_VLAN_TAGGING_DISABLE",
#     "device_name": "eth0",
#     "vlan_tag": 0,
#     "priority": 0,
#     "interface_ip_map": {},
#     "is_primary": true,
#     "monitor_disabled": {},


resource "volterra_bgp" "bgp" {
  name      = format("%s-bgp", var.prefix)
  namespace = "system"

  bgp_parameters {
    asn = "65001"
    # bgp_router_id_type = "BGP_ROUTER_ID_FROM_IP_ADDRESS"
    ip_address = "192.168.2.3"
    # bgp_router_id {
    #   ipv4 {
    #     addr = "192.168.2.3"
    #   }
    # }
  }

  peers {
    metadata {
      description = "Home router"
      # disable = false
      name = "edge-router-x"
    }
    passive_mode_disabled = true
    # target_service = "frr"
    external {
      address           = "192.168.2.2"
      port              = 179
      disable_v6        = true
      asn               = "65000"
      no_authentication = true
      family_inet {
        enable = true
      }
      family_inet_v6 {
        disable = true
      }
      interface {
        name      = volterra_network_interface.bgp.name
        namespace = "system"
      }
    }
  }

  where {
    site {
      disable_internet_vip = true
      network_type         = "VIRTUAL_NETWORK_SITE_LOCAL"

      ref {
        name      = "arch-nuc-appstack-0"
        namespace = "system"
      }
    }
  }
}