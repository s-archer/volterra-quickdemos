resource "volterra_external_connector" "tailscale_azure" {
  name        = volterra_securemesh_site_v2.site[0].name
  namespace   = "system"
  description = "Using SLO!!  Reminder to update to SLI"

  ce_site_reference {
    name      = volterra_securemesh_site_v2.site[0].name
    namespace = "system"
    tenant    = "f5-emea-ent-bceuutam"
  }

  ipsec {
    ike_parameters {
      ike_phase1_profile {
        name      = "ves-io-f5-ike-phase1-default-profile"
        namespace = "shared"
        tenant    = "ves-io"
      }

      ike_phase2_profile {
        name      = "ves-io-f5-ike-phase2-default-profile-pfs"
        namespace = "shared"
        tenant    = "ves-io"
      }

      initiator                 = true
      use_default_local_ike_id  = true
      use_default_remote_ike_id = true

      dpd_keep_alive_timer {
        timeout = 3
      }
    }

    ipsec_tunnel_parameters {
      psk        = random_password.tailscale_subnet_router_ipsec_psk.result
      tunnel_mtu = 1200

      peer_ip_address {
        addr = azurerm_network_interface.tailscale_subnet_router.private_ip_address
      }

      tunnel_eps {
        node             = "${local.f5xc_node_name_prefix}-0"
        interface        = format("ves-io-securemesh-site-v2-%s-network-%s-eth0-0", volterra_securemesh_site_v2.site[0].name, "${local.f5xc_node_name_prefix}-0")
        local_tunnel_ip  = "172.16.1.1/24"
        remote_tunnel_ip = "172.16.1.2/24"
      }

      segment {
        refs {
          name      = "arch-vodafone"
          namespace = "system"
          tenant    = "f5-emea-ent-bceuutam"
        }
      }
    }
  }
}

resource "volterra_bgp" "tailscale_azure" {
  name      = volterra_securemesh_site_v2.site[0].name
  namespace = "system"

  bgp_parameters {
    asn           = "64500"
    local_address = true
  }

  peers {
    metadata {
      name = "tailscale-router"
    }

    passive_mode_disabled = true

    external {
      asn                = "64510"
      external_connector = true
      disable_v6         = true
      port               = 179
      no_authentication  = true

      family_inet {
        enable {}
      }

      family_inet_v6 {
        disable = true
      }

      interface {
        tenant    = "f5-emea-ent-bceuutam"
        namespace = "system"
        name      = format("ves-io-external-connector-%s", volterra_external_connector.tailscale_azure.name)
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
