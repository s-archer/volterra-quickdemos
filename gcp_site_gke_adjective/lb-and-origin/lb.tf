resource "volterra_http_loadbalancer" "adjectives" {
  name        = "sentence-adjectives"
  namespace   = var.volterra_namespace
  description = "Adjectives microservice designed to decorate a sentence"
  domains     = [format("sentence-adjectives.%s", data.terraform_remote_state.gke.outputs.aks-namespace)]
  
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
          name      = "arch-azure-aks-site"
        }
      }
    }
  }

  default_route_pools {
    pool {
      namespace = var.volterra_namespace
      name      = volterra_origin_pool.adjectives.name
    }
  }
}