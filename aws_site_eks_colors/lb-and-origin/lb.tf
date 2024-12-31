resource "volterra_http_loadbalancer" "colors" {
  name        = "sentence-colors"
  namespace   = var.volterra_namespace
  description = "Colours microservice designed to decorate a sentence"
  domains     = [format("sentence-colors.%s", data.terraform_remote_state.eks.outputs.aks-namespace)]
  #domains     = ["sentence-colors.api"]
  
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

# resource "volterra_http_loadbalancer" "sentence-frontend" {
#   name        = "sentence-aws-frontend"
#   namespace   = var.volterra_namespace
#   description = "Sentence Application Frontend Load-Balancer"
#   domains     = [var.lb_domain]

#   advertise_on_public_default_vip = true

#   https_auto_cert {
#     port                  = 443
#     add_hsts              = true
#     http_redirect         = true
#     no_mtls               = true
#     default_header        = true
#     enable_path_normalize = true

#     tls_config {
#       default_security = true
#     }
#   }

#   app_firewall {
#     namespace = "shared"
#     name      = "arch-shared-waf"
#   }

#   default_route_pools {
#     pool {
#       namespace = var.volterra_namespace
#       name      = volterra_origin_pool.sentence.name
#     }
#   }
# }