resource "volterra_healthcheck" "juice-tf" {
  name      = "${var.uk_se_name}-juice-tf"
  namespace = var.volterra_namespace

  // One of the arguments from this list "http_health_check tcp_health_check" must be set

  http_health_check {
    headers = {
      "Connection" = "close"
    }

    // One of the arguments from this list "use_origin_server_name host_header" must be set
    use_origin_server_name = true
    path                   = "/"

    request_headers_to_remove = ["user-agent"]
    use_http2                 = false
  }
  healthy_threshold   = 2
  interval            = 10
  timeout             = 1
  unhealthy_threshold = 5
}

resource "volterra_origin_pool" "juice-tf" {
  name                   = "${var.uk_se_name}-juice-tf"
  namespace              = var.volterra_namespace
  description            = "${var.uk_se_name}-juice-tf"
  loadbalancer_algorithm = "LB_OVERRIDE"
  origin_servers {
    consul_service {
      inside_network = true
      service_name   = "nginx"
      site_locator {
        site {
          name      = volterra_aws_vpc_site.site.name
          namespace = "system"
        }
      }
    }
  }
  port               = 80
  endpoint_selection = "LOCAL_PREFERRED"
  no_tls             = true
  healthcheck {
      name      = volterra_healthcheck.juice-tf.name
      namespace = var.volterra_namespace
  }
}

resource "volterra_http_loadbalancer" "juice-tf" {
  name      = "${var.uk_se_name}-juice-tf"
  namespace = var.volterra_namespace
  domains   = [var.app_domain]

  advertise_on_public_default_vip = true
  no_challenge                    = true
  round_robin                     = true
  disable_rate_limit              = true
  no_service_policies             = true
  # disable_waf                     = true
  multi_lb_app                    = true
  user_id_client_ip               = true

  https_auto_cert {
    add_hsts               = false
    http_redirect          = true
    no_mtls                = true
    default_header         = true
    enable_path_normalize  = true

    tls_config {
      default_security = true
    }
  }

  default_route_pools {
    pool {
      name      = volterra_origin_pool.juice-tf.name
      namespace = var.volterra_namespace
    }
    weight = 1
  }

  routes {
    custom_route_object {
      route_ref {
        name      = volterra_route.juice-route-tf.name
        namespace = var.volterra_namespace
      }
    }
  }

  app_firewall {
    name      = "${var.uk_se_name}-juice-tf"
    namespace = var.volterra_namespace
  }
}

resource "volterra_route" "juice-route-tf" {
  name      = "${var.uk_se_name}-juice-route-tf"
  namespace = var.volterra_namespace

  routes {
    match {
      http_method = "ANY"
      path {
        prefix = "/socket.io/"
      }
    }
    route_destination {
      auto_host_rewrite = true
      timeout           = 3600
      destinations {
        cluster {
          name      = format("ves-io-origin-pool-%s", volterra_origin_pool.juice-tf.name)
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

resource "volterra_app_firewall" "example" {
  name      = "${var.uk_se_name}-juice-tf"
  namespace = var.volterra_namespace

  // One of the arguments from this list "allow_all_response_codes allowed_response_codes" must be set
  allow_all_response_codes = true

  // One of the arguments from this list "default_anonymization custom_anonymization disable_anonymization" must be set
  default_anonymization = true

  // One of the arguments from this list "use_default_blocking_page blocking_page" must be set
  use_default_blocking_page = true

  // One of the arguments from this list "default_bot_setting bot_protection_setting" must be set
  default_bot_setting = true

  // One of the arguments from this list "default_detection_settings detection_settings" must be set
  default_detection_settings = true

  // One of the arguments from this list "use_loadbalancer_setting blocking monitoring" must be set
  use_loadbalancer_setting = true
}