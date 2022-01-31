resource "volterra_origin_pool" "arch-ubuntu-tf" {
  name                   = "${var.uk_se_name}-ubuntu-tf"
  namespace              = var.volterra_namespace
  description            = "${var.uk_se_name}-ubuntu-tf"
  loadbalancer_algorithm = "LB_OVERRIDE"
  origin_servers {
    private_ip {
      ip             = module.ubuntu[0].private_ip
      inside_network = true
      site_locator {
        site {
          name      = volterra_aws_vpc_site.site.name
          namespace = "system"
        }
      }
    }
  }
  origin_servers {
    private_ip {
      ip             = "10.1.2.3"
      inside_network = true
      site_locator {
        site {
          name      = volterra_aws_vpc_site.site.name
          namespace = "system"
        }
      }
    }
  }
  port               = 443
  endpoint_selection = "LOCAL_PREFERRED"
  use_tls {
    no_mtls                  = true
    skip_server_verification = true
    tls_config {
      default_security = true
    }
    use_host_header_as_sni = true
  }
}

resource "volterra_http_loadbalancer" "arch-ubuntu-tf" {
  name      = "${var.uk_se_name}-ubuntu-tf"
  namespace = var.volterra_namespace
  domains   = [var.ubuntu_domain]

  advertise_on_public_default_vip = true
  no_challenge                    = true
  round_robin                     = true
  disable_rate_limit              = true
  no_service_policies             = true
  disable_waf                     = true
  multi_lb_app                    = true
  user_id_client_ip               = true

  https_auto_cert {
    add_hsts               = false
    http_redirect          = true
    no_mtls                = true
    default_header         = true
    disable_path_normalize = true
    

    tls_config {
      default_security = true
    }
  }

  default_route_pools {
    pool {
      name      = volterra_origin_pool.arch-ubuntu-tf.name
      namespace = var.volterra_namespace
    }
    weight = 1
  }
  routes {
    custom_route_object {
      route_ref {
        name      = volterra_route.ubuntu-route-tf.name
        namespace = var.volterra_namespace
      }
    }
  }
}

resource "volterra_route" "ubuntu-route-tf" {
  name      = "${var.uk_se_name}-ubuntu-route-tf"
  namespace = var.volterra_namespace

  routes {
    match {
      http_method = "ANY"
      path {
        prefix = "/ws"
      }
    }
    route_destination {
      auto_host_rewrite = true
      timeout           = 3600
      destinations {
        cluster {
          name      = format("ves-io-origin-pool-%s", volterra_origin_pool.arch-ubuntu-tf.name)
          namespace = var.volterra_namespace
        }
        weight = 1
      }
      web_socket_config {
        use_websocket = true
      }
    }
  }
}