resource "volterra_origin_pool" "sentence" {
  name                   = "sentence-app-frontend"
  namespace              = var.volterra_namespace
  description            = "Sentence Application Frontend"
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"
  port                   = 80
  no_tls                 = true

  origin_servers {

    k8s_service {
      service_name   = format("sentence-frontend.%s", data.terraform_remote_state.aks.outputs.aks-namespace)
      inside_network = true

      site_locator {

        site {
          namespace = "system"
          name      = "arch-azure-aks-site"
        }
      }
    }
  }
}
