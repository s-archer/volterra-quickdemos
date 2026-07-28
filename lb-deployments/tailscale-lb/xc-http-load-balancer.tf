resource "volterra_http_loadbalancer" "tailscale_nginxs" {
  count = local.create_load_balancer ? 1 : 0

  name        = var.lb_name
  namespace   = var.f5xc_namespace
  domains     = var.lb_domains
  description = "Regional Edge load balancer for AWS and Azure NGINX instances reached over Tailscale"

  advertise_on_public_default_vip = true
  add_location                    = true

  https_auto_cert {
    port                  = 443
    add_hsts              = true
    http_redirect         = true
    no_mtls               = true
    default_header        = true
    enable_path_normalize = true

    tls_config {
      default_security = true
    }
  }

  app_firewall {
    tenant    = var.f5xc_tenant
    namespace = var.app_firewall_namespace
    name      = var.app_firewall_name
  }

  dynamic "default_route_pools" {
    for_each = local.default_route_pools

    content {
      pool {
        tenant    = var.f5xc_tenant
        namespace = var.f5xc_namespace
        name      = default_route_pools.value.name
      }

      priority = default_route_pools.value.priority
      weight   = default_route_pools.value.weight
    }
  }

  no_challenge                     = true
  user_id_client_ip                = true
  disable_rate_limit               = true
  service_policies_from_namespace  = true
  round_robin                      = true
  disable_trust_client_ip_headers  = true
  disable_malicious_user_detection = true
  disable_api_discovery            = true
  disable_bot_defense              = true
  default_sensitive_data_policy    = true
  disable_api_testing              = true
  disable_api_definition           = true
  disable_ip_reputation            = true
  disable_client_side_defense      = true
  disable_threat_mesh              = true
  disable_malware_protection       = true

  disable_caching = true

  l7_ddos_protection {
    clientside_action_none = true
    ddos_policy_none       = true
    default_rps_threshold  = true
    mitigation_block       = true
  }

  more_option {
    max_request_header_size = 60
    idle_timeout            = 30000

    no_request_limit_per_connection = true

    custom_errors = {
      3 = "string:///QXJjaCBlcnJvciE="
      4 = "string:///QXJjaCBlcnJvciE="
      5 = "string:///QXJjaCBlcnJvciE="
    }
  }

  lifecycle {
    precondition {
      condition     = local.create_load_balancer
      error_message = "At least one origin pool is required. Provide aws_nginx_tailnet_ips with an AWS site name, azure_nginx_tailnet_ips with an Azure site name, or enable the matching remote state."
    }
  }
}
