resource "volterra_http_loadbalancer" "arcadia_lb" {
  name      = "arcadia-frontend-azure"
  namespace = var.volterra_namespace
  domains = ["arcadia.archf5.com"]

  advertise_on_public_default_vip = true

  https_auto_cert {
    port                  = 443
    add_hsts              = true
    http_redirect         = true
    no_mtls               = true
    default_header        = true
    enable_path_normalize = true

    tls_config {
      default_security = true
    }
  }

  default_route_pools {
    pool {
      namespace = var.volterra_namespace
      name      = volterra_origin_pool.arcadia-frontend.name
      tenant    = "f5-emea-ent-bceuutam"
    }
    weight = 1
    priority = 1
  }

  routes {
    simple_route {
      http_method = "ANY"
      path {
        prefix = "/v1/user"
      }
      origin_pools {
        pool {
          name      = volterra_origin_pool.arcadia-users.name
          namespace = var.volterra_namespace
        }
        priority = 1
        weight   = 1
      }
      headers {
        name  = "Host"
        exact = "arcadia.archf5.com"
      }
    }
  }

  routes {
    simple_route {
      http_method = "ANY"
      path {
        prefix = "/v1/login"
      }
      origin_pools {
        pool {
          name      = volterra_origin_pool.arcadia-login.name
          namespace = var.volterra_namespace
          tenant    = "f5-emea-ent-bceuutam"
        }
        priority = 1
        weight   = 1
      }
      headers {
        name  = "Host"
        exact = "arcadia.archf5.com"
      }
    }
  }

  routes {
    simple_route {
      http_method = "ANY"
      path {
        prefix = "/v1/stockt"
      }
      origin_pools {
        pool {
          name      = volterra_origin_pool.arcadia-stock-transaction.name
          namespace = var.volterra_namespace
          tenant    = "f5-emea-ent-bceuutam"
        }
        priority = 1
        weight   = 1
      }
      headers {
        name  = "Host"
        exact = "arcadia.archf5.com"
      }
    }
  }

  routes {
    simple_route {
      http_method = "ANY"
      path {
        prefix = "/v1/stock"
      }
      origin_pools {
        pool {
          name      = volterra_origin_pool.arcadia-stocks.name
          namespace = var.volterra_namespace
          tenant    = "f5-emea-ent-bceuutam"
        }
        priority = 1
        weight   = 1
      }
      headers {
        name  = "Host"
        exact = "arcadia.archf5.com"
      }
    }
  }

  routes {
    simple_route {
      http_method = "ANY"
      path {
        prefix = "/v1/ai-rag"
      }
      origin_pools {
        pool {
          name      = volterra_origin_pool.arcadia-ai-rag.name
          namespace = var.volterra_namespace
          tenant    = "f5-emea-ent-bceuutam"
        }
        priority = 1
        weight   = 1
      }
      headers {
        name  = "Host"
        exact = "arcadia.archf5.com"
      }
    }
  }

  routes {
    simple_route {
      http_method = "ANY"
      path {
        prefix = "/v1/ai"
      }
      origin_pools {
        pool {
          name      = volterra_origin_pool.arcadia-ai.name
          namespace = var.volterra_namespace
          tenant    = "f5-emea-ent-bceuutam"
        }
        priority = 1
        weight   = 1
      }
      headers {
        name  = "Host"
        exact = "arcadia.archf5.com"
      }
    }
  }

  routes {
    simple_route {
      http_method = "ANY"
      path {
        prefix = "/ollama"
      }
      origin_pools {
        pool {
          name      = volterra_origin_pool.arcadia-ollama.name
          namespace = var.volterra_namespace
          tenant    = "f5-emea-ent-bceuutam"
        }
        priority = 1
        weight   = 1
      }
      headers {
        name  = "Host"
        exact = "arcadia.archf5.com"
      }
    }
  }
}
