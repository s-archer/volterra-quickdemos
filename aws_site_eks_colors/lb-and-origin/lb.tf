resource "volterra_http_loadbalancer" "colors" {
  name        = "sentence-colors"
  namespace   = var.volterra_namespace
  description = "Colours microservice designed to decorate a sentence"
  domains     = [format("sentence-colors.%s", data.terraform_remote_state.eks.outputs.aks-namespace)]
  
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
      name      = volterra_origin_pool.colors.name
    }
  }
}