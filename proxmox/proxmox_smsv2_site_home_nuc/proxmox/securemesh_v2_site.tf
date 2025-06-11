resource "volterra_securemesh_site_v2" "site" {
  name                    = var.f5xc_sms_name
  namespace               = "system"
  description             = "Terraform deployment of SMSv2 site with single NIC on Proxmox NUC"
  block_all_services      = true
  logs_streaming_disabled = true
  enable_ha               = false
  labels = {
    # (volterra_known_label_key.key.key) = (volterra_known_label.label.value)
    "ves.io/provider" = "ves-io-KVM"
  }

  re_select {
    geo_proximity = true
  }

  kvm {
    not_managed {}
  }

  local_vrf {
    sli_config {
      static_routes {
        static_routes {
          ip_prefixes = ["10.1.0.0/16", "10.2.0.0/16"]
          ip_address  = "192.168.2.3"
          attrs       = ["ROUTE_ATTR_INSTALL_FORWARDING"]
        }
      }
    }
  }


  lifecycle {
    ignore_changes = [
      labels
    ]
  }
}

resource "volterra_token" "smsv2-token" {
  depends_on = [volterra_securemesh_site_v2.site]
  name       = format("%s-token", var.f5xc_sms_name)
  namespace  = "system"
  type       = 1
  site_name  = volterra_securemesh_site_v2.site.name
}