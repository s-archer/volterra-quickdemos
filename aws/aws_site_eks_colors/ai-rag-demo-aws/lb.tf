resource "volterra_http_loadbalancer" "ollama" {
  name        = "arcadia-ollama-gpu-aws"
  namespace   = var.volterra_namespace
  description = "Ollama model running on GPUs in AWS"
  domains     = ["ollama-aws.arcadiacrypto", "ollama-aws.arcadiacrypto.svc.cluster"]
  
  http {
    dns_volterra_managed = false
    port                 = "11434"
  }

  advertise_custom {
    advertise_where {
      site {
        network = "SITE_NETWORK_INSIDE"
        site {
          namespace = "system"
          name      = "arch-tf-azure-aks-site-75e1"
        }
      }
    }
    advertise_where {
      site {
        network = "SITE_NETWORK_INSIDE"
        site {
          namespace = "system"
          name      = "arch-aws-eks-site"
        }
      }
    }
  }

  default_route_pools {
    pool {
      namespace = var.volterra_namespace
      name      = volterra_origin_pool.ollama.name
    }
  }
}

resource "volterra_http_loadbalancer" "arcadia-ai" {
  name        = "arcadia-ai-aws"
  namespace   = var.volterra_namespace
  description = "Arcadia-ai running in EKS in AWS"
  domains     = ["arcadia-ai.arcadiacrypto"]
  
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
          name      = "arch-tf-azure-aks-site-75e1"
        }
      }
    }
  }

  default_route_pools {
    pool {
      namespace = var.volterra_namespace
      name      = volterra_origin_pool.arcadia-ai.name
    }
  }
}

resource "volterra_http_loadbalancer" "arcadia-ai-rag" {
  name        = "arcadia-ai-rag-aws"
  namespace   = var.volterra_namespace
  description = "arcadia-ai-rag running on EKS in AWS"
  domains     = ["arcadia-ai-rag.arcadiacrypto"]
  
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
          name      = "arch-tf-azure-aks-site-75e1"
        }
      }
    }
  }

  default_route_pools {
    pool {
      namespace = var.volterra_namespace
      name      = volterra_origin_pool.arcadia-ai-rag.name
    }
  }
}