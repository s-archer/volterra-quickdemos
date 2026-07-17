resource "volterra_discovery" "bip" {
  # count     = var.f5xc_sms_node_count
  # name      = "${var.prefix}sentence-${count.index}"
  name      = "${data.terraform_remote_state.eks.outputs.prefix}-bip"
  namespace = var.f5xc_namespace

  discovery_cbip {
    cbip_clusters {
      metadata {
        name = "${data.terraform_remote_state.eks.outputs.prefix}-bip"
      }
      cbip_devices {
        cbip_mgmt_ip = aws_network_interface.mgmt.private_ip
        cbip_certificate_authority {
          skip_server_verification = true
        }
        admin_credentials {
          username = "admin"
          password {
            clear_secret_info {
              url = "string:///${base64encode(random_string.password.result)}"
            }
          }
        }
      }
      cbip_mgmt_ips = [aws_network_interface.mgmt.private_ip]
      cbip_certificate_authority {
        skip_server_verification = true
      }
      admin_credentials {
        username = "admin"
        password {
          clear_secret_info {
            url = "string:///${base64encode(random_string.password.result)}"
          }
        }
      }
    }
  }
  where {
    # virtual_site {
    #   ref {
    #     name      = data.terraform_remote_state.eks.outputs.virtual-site-name
    #     namespace = data.terraform_remote_state.eks.outputs.virtual-site-namespace
    #   }
    # }
    site {
      ref {
        name      = data.terraform_remote_state.eks.outputs.site-name
        namespace = "system"
      }
      network_type = "VIRTUAL_NETWORK_SITE_LOCAL_INSIDE"
    }
  }
}
