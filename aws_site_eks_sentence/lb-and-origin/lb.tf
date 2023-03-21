resource "volterra_http_loadbalancer" "colors" {
  name        = "sentence-colors"
  namespace   = "f5-app-success-colors"
  description = "Colours microservice designed to decorate a sentence"
  domains     = ["sentence-colors.api"]

  http {
    dns_volterra_managed = false
    port                 = "80"
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
      namespace = "f5-app-success-colors"
      name      = volterra_origin_pool.colors.name
    }
  }
}