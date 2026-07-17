resource "volterra_http_loadbalancer" "http" {
  name        = replace(var.f5xc_lb_domains, "/[^A-Za-z0-9]/", "-")
  namespace   = var.f5xc_namespace
  description = "Internal LB to test BGP VIP Advertisement"
  domains     = [var.f5xc_lb_domains]

  http {
    port                 = var.f5xc_lb_port
    dns_volterra_managed = false
  }

  app_firewall {
    namespace = "shared"
    name      = "arch-shared-waf"
  }

  enable_malicious_user_detection = true
  enable_threat_mesh              = true
  add_location                    = true

  default_route_pools {
    pool {
      namespace = var.f5xc_namespace
      name      = var.f5xc_origin_pool_name
    }
  }
  advertise_custom {
    advertise_where {
      virtual_site_with_vip {
        network = "SITE_NETWORK_SPECIFIED_VIP_INSIDE"
        ip      = var.f5xc_lb_vip
        virtual_site {
          name      = data.terraform_remote_state.proxmox.outputs.vsite
          namespace = "shared"
        }
      }
    }
  }
}