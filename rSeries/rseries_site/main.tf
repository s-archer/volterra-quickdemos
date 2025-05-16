resource "random_id" "id" {
  byte_length = 2
}

locals {
  body = templatefile("${path.module}/body.tpl", { 
    tenant_name = local.f5xc_sms_name, 
    f5xc_sw_bundle = var.f5xc_sw_bundle,
    metadata = jsonencode([
      "primary-vlan:3206",
      "token:${volterra_token.smsv2-token.id}",
      "slo_ip: 10.130.206.62/24",
      "slo_gateway: 10.130.206.254",
      "slo_dns:172.30.104.10,8.8.8.8"
    ])
  })
}


resource "null_resource" "ce-rseries" {
  triggers = {
    f5os_api_url  = var.f5os_api_url
    f5os_base_uri = var.f5os_base_uri
    f5xc_sms_name = local.f5xc_sms_name
    auth          = base64encode(format("%s:%s", var.f5os_user, var.f5os_pass))
  }

  provisioner "local-exec" {
    when    = create
    command = <<EOT
curl -k --location --request POST "${var.f5os_api_url}${var.f5os_base_uri}" \
  --header "Authorization: Basic ${base64encode(format("%s:%s", var.f5os_user, var.f5os_pass))}" \
  --header "Content-Type: application/yang-data+json" \
  --data '${local.body}'
EOT
  }
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
curl -k --location --request DELETE "${self.triggers.f5os_api_url}${self.triggers.f5os_base_uri}/tenant=${self.triggers.f5xc_sms_name}" \
  --header "Authorization: Basic ${self.triggers.auth}" \
  --header "Content-Type: application/yang-data+json"
EOT
  }
}


resource "volterra_securemesh_site_v2" "site" {
  name                    = local.f5xc_sms_name
  namespace               = "system"
  description             = var.f5xc_sms_description
  block_all_services      = true
  logs_streaming_disabled = true
  enable_ha               = false

  re_select {
    geo_proximity = true
  }

  rseries {
    not_managed {}
  }

  f5_proxy = true
  dns_ntp_config {
    custom_dns {
      dns_servers = [
          "172.30.104.10",
          "8.8.8.8"
      ]
    }
    f5_ntp_default = true
  }

#   local_vrf {
#     sli_config {
#       static_routes {
#         static_routes {
#           ip_prefixes = ["10.1.0.0/16", "10.2.0.0/16"]
#           ip_address  = "10.0.102.1"
#           attrs       = ["ROUTE_ATTR_INSTALL_FORWARDING"]
#         }
#       }
#     }
#   }

#   active_enhanced_firewall_policies {
#     enhanced_firewall_policies {
#       name      = "arch-vsite-fw-policy"
#       namespace = "system"
#     }
#   }

  lifecycle {
    ignore_changes = [
      labels
    ]
  }
}

resource "volterra_token" "smsv2-token" {
  depends_on = [volterra_securemesh_site_v2.site]
  name       = format("%s-token", local.f5xc_sms_name)
  namespace  = "system"
  type       = 1
  site_name  = volterra_securemesh_site_v2.site.name
}
