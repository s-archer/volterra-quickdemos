resource "volterra_http_loadbalancer" "sentence-vk8s" {
  name        = "sentence-vk8s-internal"
  namespace   = var.xc_namespace
  description = "Internal LB for vk8s sentence app"
  domains     = ["sentence.local"]
  labels      = { "ves.io/app_type" : "arch-demo-all-features" }

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
          name      = "arch-igw"
        }
      }
    }
  }

  default_route_pools {
    pool {
      namespace = var.xc_namespace
      name      = volterra_origin_pool.sentence-vk8s.name
    }
  }
}

resource "volterra_origin_pool" "sentence-vk8s" {
  name                   = "sentence-vk8s-internal"
  namespace              = var.xc_namespace
  description            = "Sentence app Frontend"
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"
  port                   = 80
  no_tls                 = true

  origin_servers {

    k8s_service {
      service_name   = format("sentence-frontend.%s", var.xc_namespace)
      vk8s_networks = true

      site_locator {

        virtual_site {
          namespace = "shared"
          name      = "arch-sentence-main"
        }
      }
    }
  }
}

# resource "volterra_app_type" "sentence-ai" {
#   name      = "arch-sentence-api"
#   namespace = "shared"
#   features {
#     type = "BUSINESS_LOGIC_MARKUP"
#   }
#   features {
#     type = "USER_BEHAVIOR_ANALYSIS"
#   }
#   features {
#     type = "PER_REQ_ANOMALY_DETECTION"
#   }
#   features {
#     type = "TIMESERIES_ANOMALY_DETECTION"
#   }
#   business_logic_markup_setting {
#     enable = true
#   }
# }