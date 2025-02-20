

resource "random_id" "id" {
  byte_length = 2
}

# resource "f5os_tenant" "ce-1" {
#   name              = "arch-ce-node-1"
# }

# resource "f5os_tenant" "ce-1" {
#   provider = f5os.reseries-2
#   name              = local.f5xc_sms_name
#   image_name        = "f5xc-ce-9.2024.44-20250102051113.qcow2.b345faa8.05.tar.bundle"
#   mgmt_ip           = "10.130.206.62"
#   mgmt_gateway      = "10.130.206.254"
#   mgmt_prefix       = 24
#   type              = "Generic"
#   cpu_cores         = 4
#   nodes             = [1]
#   vlans             = [3030, 3206]
#   running_state     = "deployed"
#   virtual_disk_size = 100
#   dag_ipv6_prefix_length = 128
#   mac_block_size = "small"
#   memory = 16969
# #   metadata = ""
# }

# resource "restful_resource" "f5os-tenant" {
#   provider      = restful.f5os_api
#   create_method = "POST"
#   create_header = {
#     Content-Type = "application/yang-data+json"
#     Accept       = "application/yang-data+json"
#     Arch         = "made-up-stuff"
#   }
#   path          = format("%s%s", var.f5os_api_url, var.f5os_base_uri)
# # https://clouddocs.f5.com/restconf/data/f5-tenants:tenants/tenant={tenant-name}
#   poll_create = {
#     status_locator = "code"
#     status = {
#       success = "200"
#     }
#   }

#   poll_delete = {
#     status_locator = "code"
#     status = {
#       success = "404"
#     }
#   }

#   header = {
#     Content-Type = "application/yang-data+json"
#     Accept       = "application/yang-data+json"
#     Arch         = "made-up-stuff"
#   }

#   body = {
#   #   name           = local.f5xc_sms_name

#   }

#   lifecycle {
#     ignore_changes = [
#       body
#     ]
#   }
# }


# data "base64_encode" "f5os_creds" {
#   content = "${var.f5os_user}:${var.f5os_pass}"
# }


# locals {
#   body = templatefile("${path.module}/body.tpl", { 
#     tenant_name = local.f5xc_sms_name, 
#     # metadata = format("[primary-vlan:%s, token:%s, slo_dns:%s]", "3206", "${volterra_token.smsv2-token.id}", "172.30.104.10,8.8.8.8")
#     metadata = format(
#       "[%s]",
#       join(", ", [
#         format("\"primary-vlan:%s\"", "3206"),
#         format("\"token:%s\"", volterra_token.smsv2-token.id),
#         format("\"slo_dns:%s\"", "172.30.104.10,8.8.8.8")
#       ])
#     )
#   })
# }

locals {
  body = templatefile("${path.module}/body.tpl", { 
    tenant_name = local.f5xc_sms_name, 
    f5xc_sw_bundle = var.f5xc_sw_bundle,
    metadata = jsonencode([
      "primary-vlan:3206",
      "token:${volterra_token.smsv2-token.id}",
      "slo_dns:172.30.104.10,8.8.8.8"
    ])
#     metadata = chomp(<<EOT
# ["primary-vlan:3206","token:${volterra_token.smsv2-token.id}","slo_dns:172.30.104.10,8.8.8.8"]
# EOT
#     )
  })
}



# resource "null_resource" "ce-rseries" {
#   provisioner "local-exec" {
#     when    = create
#     command = "curl --location --request POST '${f5os_api_url}/${f5os_base_uri}' --header 'Authorization: Basic ${base64encode(format("%s:%s", var.f5os_user, var.f5os_pass))}' --header 'Content-Type: application/yang-data+json' -d ${local.body}"
#   }
# }


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
#   labels = {
#     (volterra_known_label_key.key.key) = (volterra_known_label.label.value)
#     "ves.io/provider"                  = "ves-io-AZURE"
#   }

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
