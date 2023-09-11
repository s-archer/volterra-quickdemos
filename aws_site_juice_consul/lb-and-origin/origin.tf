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
      service_name   = "sentence-colors.sentence-app"
      inside_network = true

      site_locator {

        site {
          namespace = "system"
          name      = "aws-site"
        }
      }
    }
  }
}
