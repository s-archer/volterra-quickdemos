resource "volterra_discovery" "consul" {
  name      = "consul"
  namespace = "system"

  // One of the arguments from this list "discovery_k8s discovery_consul" must be set

  discovery_consul {
    access_info {
      // One of the arguments from this list "kubeconfig_url connection_info in_cluster" must be set
      connection_info {
        api_server = format("%s:8500", module.consul[0].private_ip)
      }
    }

    publish_info {
      // One of the arguments from this list "disable publish publish_fqdns dns_delegation" must be set
      publish = true
    }
  }

  where {
    // One of the arguments from this list "virtual_network site virtual_site" must be set

    site {
      network_type = "VIRTUAL_NETWORK_SITE_LOCAL_INSIDE"

      ref {
        name      = volterra_aws_vpc_site.site.name
        namespace = volterra_aws_vpc_site.site.namespace
        tenant    = var.volt_tenant
      }
    }
  }
}


resource "volterra_origin_pool" "consul-tf" {
  name                   = "consul-tf"
  namespace              = var.volterra_namespace
  description            = "consul-tf"
  loadbalancer_algorithm = "LB_OVERRIDE"
  origin_servers {
    private_ip {
      ip             = module.consul[0].private_ip
      inside_network = true
      site_locator {
        site {
          name      = volterra_aws_vpc_site.site.name
          namespace = "system"
        }

      }
    }
  }
  port               = 8500
  endpoint_selection = "LOCAL_PREFERRED"
  no_tls             = true
}

resource "volterra_http_loadbalancer" "consul-tf" {
  name      = "consul-tf"
  namespace = var.volterra_namespace
  domains   = [var.consul_domain]

  advertise_on_public_default_vip = true
  no_challenge                    = true
  round_robin                     = true
  disable_rate_limit              = true
  no_service_policies             = true
  disable_waf                     = true
  multi_lb_app                    = true
  user_id_client_ip               = true

  https_auto_cert {
    add_hsts              = false
    http_redirect         = true
    no_mtls               = true
    default_header        = true
    enable_path_normalize = true

    tls_config {
      default_security = true
    }
  }

  default_route_pools {
    pool {
      name      = volterra_origin_pool.consul-tf.name
      namespace = var.volterra_namespace
    }
    weight = 1
  }
}