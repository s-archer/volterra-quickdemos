
resource "volterra_origin_pool" "arcadia-frontend" {
  name                   = "arcadia-frontend"
  namespace              = var.volterra_namespace
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"
  port                   = 80
  no_tls                 = true

  origin_servers {

    k8s_service {
      service_name   = "arcadia-frontend.arcadiacrypto"
      inside_network = true

      site_locator {
        site {
          namespace = "system"
          tenant    = "f5-emea-ent-bceuutam"
          name      = data.terraform_remote_state.aks.outputs.azure-site-name
        }
      }
    }
  }
}

resource "volterra_origin_pool" "arcadia-users" {
  name                   = "arcadia-users"
  namespace              = var.volterra_namespace
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"
  port                   = 80
  no_tls                 = true

  origin_servers {

    k8s_service {
      service_name   = "arcadia-users.arcadiacrypto"
      inside_network = true

      site_locator {
        site {
          namespace = "system"
          tenant    = "f5-emea-ent-bceuutam"
          name      = data.terraform_remote_state.aks.outputs.azure-site-name
        }
      }
    }
  }
}

resource "volterra_origin_pool" "arcadia-login" {
  name                   = "arcadia-login"
  namespace              = var.volterra_namespace
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"
  port                   = 80
  no_tls                 = true

  origin_servers {

    k8s_service {
      service_name   = "arcadia-login.arcadiacrypto"
      inside_network = true

      site_locator {
        site {
          namespace = "system"
          tenant    = "f5-emea-ent-bceuutam"
          name      = data.terraform_remote_state.aks.outputs.azure-site-name
        }
      }
    }
  }
}

resource "volterra_origin_pool" "arcadia-stocks" {
  name                   = "arcadia-stocks"
  namespace              = var.volterra_namespace
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"
  port                   = 80
  no_tls                 = true

  origin_servers {

    k8s_service {
      service_name   = "arcadia-stocks.arcadiacrypto"
      inside_network = true

      site_locator {
        site {
          namespace = "system"
          tenant    = "f5-emea-ent-bceuutam"
          name      = data.terraform_remote_state.aks.outputs.azure-site-name
        }
      }
    }
  }
}

resource "volterra_origin_pool" "arcadia-stock-transaction" {
  name                   = "arcadia-stock-transaction"
  namespace              = var.volterra_namespace
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"
  port                   = 80
  no_tls                 = true

  origin_servers {

    k8s_service {
      service_name   = "arcadia-stock-transaction.arcadiacrypto"
      inside_network = true

      site_locator {
        site {
          namespace = "system"
          tenant    = "f5-emea-ent-bceuutam"
          name      = data.terraform_remote_state.aks.outputs.azure-site-name
        }
      }
    }
  }
}

resource "volterra_origin_pool" "arcadia-ai" {
  name                   = "arcadia-ai"
  namespace              = var.volterra_namespace
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"
  port                   = 80
  no_tls                 = true

  origin_servers {

    k8s_service {
      service_name   = "arcadia-ai.arcadiacrypto"
      inside_network = true

      site_locator {
        site {
          namespace = "system"
          tenant    = "f5-emea-ent-bceuutam"
          name      = data.terraform_remote_state.aks.outputs.azure-site-name
        }
      }
    }
  }
}

resource "volterra_origin_pool" "arcadia-ai-rag" {
  name                   = "arcadia-ai-rag"
  namespace              = var.volterra_namespace
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"
  port                   = 80
  no_tls                 = true

  origin_servers {

    k8s_service {
      service_name   = "arcadia-ai-rag.arcadiacrypto"
      inside_network = true

      site_locator {
        site {
          namespace = "system"
          tenant    = "f5-emea-ent-bceuutam"
          name      = data.terraform_remote_state.aks.outputs.azure-site-name
        }
      }
    }
  }
}

resource "volterra_origin_pool" "arcadia-ollama" {
  name                   = "arcadia-ollama"
  namespace              = var.volterra_namespace
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"
  port                   = 11434
  no_tls                 = true

  origin_servers {

    k8s_service {
      service_name   = "ollama.arcadiacrypto"
      inside_network = true

      site_locator {
        site {
          namespace = "system"
          tenant    = "f5-emea-ent-bceuutam"
          name      = data.terraform_remote_state.aks.outputs.azure-site-name
        }
      }
    }
  }
}