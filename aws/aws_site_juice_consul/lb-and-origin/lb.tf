resource "volterra_http_loadbalancer" "colors" {
  name        = "arch-juice-other"
  namespace   = var.volterra_namespace
  description = "arch test LB"
  domains     = ["juice.otherdomain.com"]

  http {
    dns_volterra_managed = false
    port                 = "80"
  }

  https_auto_cert {
    http_redirect = false
    add_hsts      = false
    port          = 443
    tls_config {
      default_security = true
    }
    no_mtls                  = true
    default_header           = true
    enable_path_normalize    = true
    non_default_loadbalancer = true
    header_transformation_type {
      default_header_transformation = true
    }
    connection_idle_timeout = 120000
  }

  advertise_custom {
    advertise_where {
      site {
        network = "SITE_NETWORK_INSIDE"
        site {
          namespace = "system"
          name      = "azure-site"
        }
      }
    }
  }

  default_route_pools {
    pool {
      namespace = var.volterra_namespace
      name      = volterra_origin_pool.colors.name
    }
  }
}