resource "volterra_external_connector" "tailscale_aws" {
  name        = volterra_securemesh_site_v2.site[count.index].name
  count       = var.f5xc_sms_node_count
  namespace   = "system"
  description = "Tailscale subnet router IPsec connector"

  ce_site_reference {
    name      = volterra_securemesh_site_v2.site[count.index].name
    namespace = "system"
    tenant    = var.f5xc_tenant
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
      psk        = local.tailscale_subnet_router_ipsec_psk
      tunnel_mtu = 1200

      peer_ip_address {
        addr = aws_network_interface.tailscale_router_internal.private_ip
      }

      tunnel_eps {
        node             = format("node-%s", count.index)
        interface        = format("ves-io-securemesh-site-v2-%s-network-%s-ens5-0", volterra_securemesh_site_v2.site[0].name, format("node-%s", count.index))
        local_tunnel_ip  = format("%s/%s", var.f5xc_ce_ipsec_remote_tunnel_ip, local.tailscale_subnet_router_tunnel_cidr)
        remote_tunnel_ip = var.f5xc_ce_ipsec_local_tunnel_ip
      }

      segment {
        refs {
          name      = "arch-vodafone"
          namespace = "system"
          tenant    = var.f5xc_tenant
        }
      }
    }
  }
}

resource "volterra_bgp" "tailscale_aws" {
  name      = volterra_securemesh_site_v2.site[count.index].name
  count     = var.f5xc_sms_node_count
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
        tenant    = var.f5xc_tenant
        namespace = "system"
        name      = format("ves-io-external-connector-%s", volterra_external_connector.tailscale_aws[count.index].name)
      }
    }
  }

  where {
    site {
      disable_internet_vip = true
      network_type         = "VIRTUAL_NETWORK_SITE_LOCAL"

      ref {
        name      = volterra_securemesh_site_v2.site[count.index].name
        namespace = "system"
      }
    }
  }
}
