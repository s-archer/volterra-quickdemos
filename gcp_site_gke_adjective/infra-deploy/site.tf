
resource "volterra_gcp_vpc_site" "site" {
  name      = var.site_name
  namespace = "system"
  ssh_key   = tls_private_key.demo.public_key_openssh
  cloud_credentials {
    name      = var.gcp_cred_name
    namespace = "system"
  }

  gcp_region    = var.gcp_region
  instance_type = var.gcp_instance_type
  ingress_egress_gw {
    gcp_certified_hw = "gcp-byol-multi-nic-voltmesh"
    # gcp_zone_names   = [var.gcp_az]
    # node_number = 1
    gcp_zone_names   = var.gcp_azs
    node_number = 3

    # outside_network {
    #   existing_network {
    #     name = google_compute_network.vpc-outside.name
    #   }
    # } 

    # outside_subnet {
    #     existing_subnet {
    #       subnet_name = google_compute_subnetwork.subnet-outside.name
    #     }
    # }

    # inside_network {
    #   existing_network {
    #     name = google_compute_network.vpc-inside.name
    #   }
    # }

    # inside_subnet {
    #     existing_subnet {
    #       subnet_name = google_compute_subnetwork.subnet-inside.name
    #     }
    # }
    outside_network {
      existing_network {
        name = google_compute_network.vpc-outside.name
      }
    } 

    outside_subnet {
        existing_subnet {
          subnet_name = google_compute_subnetwork.subnet-outside.name
        }
    }

    inside_network {
      existing_network {
        name = google_compute_network.vpc-inside.name
      }
    }

    inside_subnet {
        existing_subnet {
          subnet_name = google_compute_subnetwork.subnet-inside.name
        }
    }

    inside_static_routes {
      static_route_list {
        custom_static_route {
          subnets {
            ipv4 {
              prefix = "10.0.0.0"
              plen = 8
            }
          }
          nexthop {
            type = "NEXT_HOP_DEFAULT_GATEWAY"
            nexthop_address {
              ipv4 {
                addr = "10.0.2.1"
              }
            }
          }
          labels = {}
          attrs  = ["ROUTE_ATTR_INSTALL_FORWARDING"]
        }
      }
    }
  }
  
  lifecycle {
    ignore_changes = [labels]
  }
}

resource "volterra_tf_params_action" "apply_gcp_vpc" {
  site_name        = volterra_gcp_vpc_site.site.name
  site_kind        = "gcp_vpc_site"
  action           = "apply"
  wait_for_action  = true
  ignore_on_update = true
}