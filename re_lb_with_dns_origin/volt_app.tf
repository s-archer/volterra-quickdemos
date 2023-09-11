resource "volterra_origin_pool" "origin" {
  name                   = var.name
  namespace              = var.namespace
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"

  origin_servers {
    public_name {
      dns_name = var.origin_fqdn
    }
  }
  port = 443
}

resource "volterra_http_loadbalancer" "lb" {
  name                            = var.name
  namespace                       = var.namespace
  domains                         = [var.lb_fqdn]
  advertise_on_public_default_vip = true

  app_firewall {
    name      = var.waf_name
    namespace = var.waf_namespace
  }

  https_auto_cert {
    tls_config {
      default_security = true
    }
  }

  default_route_pools {
    pool {
      name      = volterra_origin_pool.origin.name
      namespace = var.namespace
    }
  }
}

