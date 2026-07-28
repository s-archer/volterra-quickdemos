resource "volterra_origin_pool" "aws_nginx" {
  count = local.create_aws_origin_pool ? 1 : 0

  name                   = "tailnet-nginx-aws"
  namespace              = var.f5xc_namespace
  description            = "Nginx instances in AWS tailnet"
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"
  port                   = 80
  no_tls                 = true

  dynamic "origin_servers" {
    for_each = local.aws_nginx_tailnet_ips

    content {
      private_ip {
        ip             = origin_servers.value
        inside_network = true

        site_locator {
          site {
            tenant    = var.f5xc_tenant
            namespace = "system"
            name      = local.aws_site_name
          }
        }
      }
    }
  }

  healthcheck {
    tenant    = var.f5xc_tenant
    namespace = var.healthcheck_namespace
    name      = var.healthcheck_name
  }

  advanced_options {
    connection_timeout = 2000
    http_idle_timeout  = 300000

    outlier_detection {
      consecutive_5xx             = 3
      interval                    = 3000
      base_ejection_time          = 12000
      max_ejection_percent        = 100
      consecutive_gateway_failure = 3
    }

    no_panic_threshold               = true
    disable_subsets                  = true
    auto_http_config                 = true
    disable_lb_source_ip_persistance = true
    disable_proxy_protocol           = true
    no_request_limit_per_connection  = true
    default_circuit_breaker          = true
  }

  upstream_conn_pool_reuse_type {
    enable_conn_pool_reuse = true
  }
}

resource "volterra_origin_pool" "azure_nginx" {
  count = local.create_azure_origin_pool ? 1 : 0

  name                   = "tailnet-nginx-azure"
  namespace              = var.f5xc_namespace
  description            = "Nginx instances in AZURE tailnet"
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"
  port                   = 80
  no_tls                 = true

  dynamic "origin_servers" {
    for_each = local.azure_nginx_tailnet_ips

    content {
      private_ip {
        ip             = origin_servers.value
        inside_network = true

        site_locator {
          site {
            tenant    = var.f5xc_tenant
            namespace = "system"
            name      = local.azure_site_name
          }
        }
      }
    }
  }

  healthcheck {
    tenant    = var.f5xc_tenant
    namespace = var.healthcheck_namespace
    name      = var.healthcheck_name
  }

  advanced_options {
    connection_timeout = 2000
    http_idle_timeout  = 300000

    outlier_detection {
      consecutive_5xx             = 3
      interval                    = 3000
      base_ejection_time          = 12000
      max_ejection_percent        = 100
      consecutive_gateway_failure = 3
    }

    no_panic_threshold               = true
    disable_subsets                  = true
    auto_http_config                 = true
    disable_lb_source_ip_persistance = true
    disable_proxy_protocol           = true
    no_request_limit_per_connection  = true
    default_circuit_breaker          = true
  }

  upstream_conn_pool_reuse_type {
    enable_conn_pool_reuse = true
  }
}
