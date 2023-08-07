resource "volterra_origin_pool" "colors" {
  name                   = "sentence-colors"
  namespace              = var.volterra_namespace
  description            = "Colours microservice designed to decorate a sentence"
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"
  port                   = 80
  no_tls                 = true

  origin_servers {

    k8s_service {
      service_name   = format("sentence-colors.%s", data.terraform_remote_state.eks.outputs.eks-namespace)
      inside_network = true

      site_locator {

        site {
          namespace = "system"
          name      = "arch-aws-eks-site"
        }
      }
    }
  }
}
