resource "volterra_origin_pool" "ollama" {
  name                   = "ollama-model-gpu"
  namespace              = var.volterra_namespace
  description            = "Ollama model running on GPUs in AWS"
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"
  port                   = 11434
  no_tls                 = true

  origin_servers {
  
    private_ip {
      ip             = aws_instance.ollama.private_ip
      inside_network = true

      site_locator {

        site {
          namespace = "system"
          name      = data.terraform_remote_state.eks.outputs.aws-site-name
          tenant    = "f5-emea-ent-bceuutam"
        }
      }
    }
  }
}

resource "volterra_origin_pool" "arcadia-ai" {
  name                   = "arcadia-ai-aws"
  namespace              = var.volterra_namespace
  description            = "arcadia-ai running in EKS in AWS"
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
          name      = "arch-aws-eks-site"
          tenant    = "f5-emea-ent-bceuutam"
        }
      }
    }
  }
}

resource "volterra_origin_pool" "arcadia-ai-rag" {
  name                   = "arcadia-ai-rag-aws"
  namespace              = var.volterra_namespace
  description            = "arcadia-ai-rag running in EKS in AWS"
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
          name      = "arch-aws-eks-site"
          tenant    = "f5-emea-ent-bceuutam"
        }
      }
    }
  }
}