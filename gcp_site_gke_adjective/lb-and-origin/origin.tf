resource "volterra_origin_pool" "adjectives" {
  name                   = "sentence-adjectives"
  namespace              = var.volterra_namespace
  description            = "Adjectives microservice designed to decorate a sentence"
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"
  port                   = 80
  no_tls                 = true

  origin_servers {

    k8s_service {
      service_name   = format("sentence-adjectives.%s", data.terraform_remote_state.gke.outputs.gke-namespace)
      vk8s_networks = true

      site_locator {

        site {
          namespace = "system"
          name      = "arch-gcp-gke-site"
        }
      }
    }
  }
}
