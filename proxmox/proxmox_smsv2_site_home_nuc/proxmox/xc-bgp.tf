resource "volterra_bgp" "bgp-node" {
  count     = var.bgp_enable ? 1 : 0
  name      = format("%s-bgp", var.f5xc_sms_name)
  namespace = "system"

  bgp_parameters {
    asn           = "65001"
    local_address = true
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
        name      = format("ves-io-securemesh-site-v2-%s-network-%s-ens19-0", volterra_securemesh_site_v2.site.name, volterra_securemesh_site_v2.site.name)
        namespace = "system"
      }
    }
  }

  where {
    site {
      disable_internet_vip = true
      network_type         = "VIRTUAL_NETWORK_SITE_LOCAL"

      ref {
        name      = volterra_securemesh_site_v2.site.name
        namespace = "system"
      }
    }
  }
}
