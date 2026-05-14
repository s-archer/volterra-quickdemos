# resource "volterra_api_credential" "api-creds" {
#   name                = format("%stoken", var.prefix)
#   api_credential_type = "API_TOKEN"
#   created_at          = timestamp()
#   lifecycle {
#     ignore_changes = [
#       created_at
#     ]
#   }
# }

# data "http" "site" {
#   depends_on = [ volterra_securemesh_site_v2.site ]
#   url = format("%s%s%s", var.f5xc_api_url, "/config/namespaces/system/sites/", volterra_securemesh_site_v2.site[0].name)

#   request_headers = {
#     Accept        = "application/json"
#     Authorization = format("APIToken %s", volterra_api_credential.api-creds.data)
#   }
# }

# locals {
#   data_site_response = jsondecode(data.http.site.response_body)
#   data_site_uid      = local.data_site_response.system_metadata.uid
# }

# data "http" "software_os_version" {
#   url    = format("%s%s", var.f5xc_api_url, "/maurice/software_os_version")
#   method = "POST"

#   request_headers = {
#     Accept        = "application/json"
#     Authorization = format("APIToken %s", volterra_api_credential.api-creds.data)
#   }

#   request_body = jsonencode({
#     uids = [local.data_site_uid]
#   })
# }

# locals {
  # data_software_response = jsondecode(data.http.software_os_version.response_body)
  # data_copy_image_name = local.data_software_response.images[local.data_site_uid].copy_image_name
# }

data "aws_ami" "f5xc" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.f5xc_ami]
    # values = [format("%s*", local.data_copy_image_name)]
  }
  # owners = ["434481986642"] # F5 Networks, Inc.
  # owners = ["679593333241"] # F5 XC Public AMIs
  owners = ["434481986642", "679593333241"]
}

resource "aws_instance" "xc" {
  count         = var.f5xc_sms_node_count
  ami           = data.aws_ami.f5xc.id
  instance_type = "m5.2xlarge"

  user_data = templatefile("${path.module}/templates/user-data.tpl", {
    cluster_name = format("%s-node-%s", local.f5xc_sms_name, count.index),
    token        = volterra_token.smsv2-token[count.index].id
  })

  root_block_device {
    volume_size           = 100
    volume_type           = "gp2"
    delete_on_termination = true
  }

  key_name = aws_key_pair.demo.key_name

  network_interface {
    network_interface_id = aws_network_interface.f5xc-outside[count.index].id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.f5xc-inside[count.index].id
    device_index         = 1
  }

  tags = {
    Name                                           = format("%s-node-%s", local.f5xc_sms_name, count.index)
    ves-io-site-name                               = volterra_securemesh_site_v2.site[count.index].name
    "kubernetes.io/cluster/${local.f5xc_sms_name}" = local.f5xc_sms_name
    UK-SE                                          = var.uk_se_name

  }
}

locals {
  xc_egress_domains = [
    # Domains current as of Feb-2026 https://docs.cloud.f5.com/docs-v2/multi-cloud-network-connect/reference/ce-ip-dom-ref
    # waiting for these names to be available as json or via API.
    "register.ves.volterra.io",
    "register-tls.ves.volterra.io",
    "myip.volterra.io",
    "downloads.volterra.io",
    "gcr.download.volterra.io",
    "blindfold.ves.volterra.io",
    "identityauthority.ves.volterra.io"
  ]
  xc_egress_re_cidrs = [
    # pa4
    "5.182.212.0/25",
    # pa2
    "5.182.213.0/25",
    # ams9
    "5.182.213.128/25",
    # tn2
    "5.182.214.0/25",
    # fr4
    "185.56.154.0/25",
  ]
  # convert the resolved dns names inot a sorted list if cidrs for the SG egress rules.
  all_ips              = flatten([for r in data.dns_a_record_set.xc : r.addrs])
  unique_ips           = distinct(local.all_ips)
  sorted_ips           = sort(local.unique_ips)
  sorted_unique_ips_32 = [for ip in local.sorted_ips : "${ip}/32"]
  all_egress_cidrs = sort(
    distinct(
      concat(
        local.sorted_unique_ips_32,
        local.xc_egress_re_cidrs
      )
    )
  )
}

data "dns_cname_record_set" "xc" {
  count = length(local.xc_egress_domains)
  host  = local.xc_egress_domains[count.index]
}

data "dns_a_record_set" "xc" {
  count = length(data.dns_cname_record_set.xc)
  host  = data.dns_cname_record_set.xc[count.index].cname
}

resource "aws_security_group" "outside" {
  name        = "${var.prefix}outside"
  description = "Allow outbound only"
  vpc_id      = aws_vpc.f5xc.id

  # ingress {
  #   # Aloow Site Mesh Group to form over Internet
  #   description = "Allow IPSec from anywhere"
  #   from_port   = 4500
  #   to_port     = 4500
  #   protocol    = "udp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
    # cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 65500
    to_port     = 65500
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
    # cidr_blocks = ["10.0.0.0/16"]
  }

  # === EGRESS RULES (from F5 XC documentation) ===

  # Allow All (for debug)
  # egress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # All Geographies - Global F5 Service
  egress {
    description = "All Geographies TCP 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["159.60.141.140/32"]
  }

  # Europe TCP (HTTP/HTTPS)
  egress {
    description = "Europe TCP 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = local.xc_egress_re_cidrs
  }

  egress {
    description = "Europe TCP 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.all_egress_cidrs
  }

  # Europe UDP (IPSec / NTP)
  egress {
    description = "Europe UDP 4500"
    from_port   = 4500
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = local.xc_egress_re_cidrs
  }

  egress {
    description = "Europe UDP 123"
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = local.xc_egress_re_cidrs
  }

  # DNS (Google Public DNS)
  egress {
    description = "DNS TCP 53"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["8.8.8.8/32", "8.8.4.4/32"]
  }

  egress {
    description = "DNS UDP 53"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["8.8.8.8/32", "8.8.4.4/32"]
  }

  tags = {
    Name  = "${var.prefix}external",
    UK-SE = var.uk_se_name
  }
}

resource "aws_security_group" "inside" {
  name        = "${var.prefix}inside"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = aws_vpc.f5xc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "${var.prefix}inside",
    UK-SE = var.uk_se_name
  }
}

resource "aws_network_interface" "f5xc-outside" {
  count           = var.f5xc_sms_node_count
  subnet_id       = aws_subnet.eks_outside[count.index].id
  security_groups = [aws_security_group.outside.id]
  # private_ips     = ["10.0.0.100"]
  private_ips_count = 0

  tags = {
    Name = "outside-interface"
  }
}

resource "aws_network_interface" "f5xc-inside" {
  count             = var.f5xc_sms_node_count
  subnet_id         = aws_subnet.eks_inside[count.index].id
  security_groups   = [aws_security_group.inside.id]
  private_ips_count = 0

  tags = {
    Name = "inside-interface"
  }
}

resource "aws_eip" "f5xc-outside" {
  count             = var.f5xc_sms_node_count
  network_interface = aws_network_interface.f5xc-outside[count.index].id

  tags = {
    Name = "${var.prefix}-outside"
  }
}



resource "volterra_token" "smsv2-token" {
  count      = var.f5xc_sms_node_count
  depends_on = [volterra_securemesh_site_v2.site]
  name       = format("%s-token-%s", local.f5xc_sms_name, count.index)
  namespace  = "system"
  type       = 1
  site_name  = volterra_securemesh_site_v2.site[count.index].name
}

# Unhash the following block if you want to manage your own key, but make sure you change the `key` value
# resource "volterra_known_label_key" "key" {
#   key         = "virtual-site-terraform"
#   namespace   = "shared"
#   description = "Used to define lables for Virtual Sites "
# }

resource "volterra_known_label" "label" {
  # Unhash the following block if you want to manage your own key, but make sure you change the `key` value
  # key       = volterra_known_label_key.key.key
  key       = "virtual-site-terraform"
  namespace = "shared"
  value     = local.f5xc_sms_name
}

resource "volterra_virtual_site" "ce" {
  name      = local.f5xc_sms_name
  namespace = "shared"

  site_selector {
    # Unhash the following block if you want to manage your own key, but make sure you change the `key` value
    # expressions = [format("%s = %s", volterra_known_label_key.key.key, volterra_known_label.label.value)]
    expressions = [format("%s = %s", "virtual-site-terraform", volterra_known_label.label.value)]
  }

  site_type = "CUSTOMER_EDGE"
}

# resource "volterra_securemesh_site_v2" "site" {
#   count                   = var.f5xc_sms_node_count
#   name                    = format("%s-node-%s", local.f5xc_sms_name, count.index)
#   namespace               = "system"
#   description             = var.f5xc_sms_description
#   block_all_services      = false
#   logs_streaming_disabled = true
#   enable_ha               = false
#   admin_user_credentials {
#     ssh_key = tls_private_key.demo.public_key_openssh
#   }
#   labels = {
#     # Unhash the following block if you want to manage your own key, but make sure you change the `key` value
#     # (volterra_known_label_key.key.key) = (volterra_known_label.label.value)
#     ("virtual-site-terraform") = (volterra_known_label.label.value)
#     "ves.io/provider"                  = "ves-io-AWS"
#   }

#   re_select {
#     geo_proximity = true
#   }

#   # aws {
#   #   not_managed {}
#   # }
# # #   aws {
# # #     not_managed {
# # #       node_list {
# # #           # Node Identifier
# # #           hostname = format("%s-node-%s", local.f5xc_sms_name, count.index)
# # #           type     = "Control"
# # # #-------------------------------------------------------------------------------
# # # # ❗ IMPORTANT NOTE ON F5 XC AWS INTERFACE MAPPING:
# # # #
# # # # This explains how the Linux 'ens' names in your XC JSON or in the lines below correlate to AWS ENIs.
# # # #
# # # # "ens5": **Site Local Outside (SLO)**
# # # #    - AWS Device Index: 0 (Primary)
# # # #    - JSON Network Option: "site_local_network"
# # # #    - Role: Management, Public Connectivity (WAN)
# # # #
# # # # "ens6": **Site Local Inside (SLI)**
# # # #    - AWS Device Index: 1 (Secondary)
# # # #    - JSON Network Option: "site_local_inside_network"
# # # #    - Role: Workload Connectivity (LAN)
# # # #
# # # # KEY CONCEPT:
# # # # 'ens5' and 'ens6' are **Linux Kernel** names (Predictable Network Interface Names)
# # # # based on the PCI slot location on modern AWS Nitro instances, **not** AWS names.
# # # #-------------------------------------------------------------------------------
# # #           interface_list {
# # #               # --- Core Fields ---
# # #               name       = interface_list.value == 0 ? "ens5" : "ens6"
# # #               priority   = 0
# # #               mtu        = 0
# # #               dhcp_client = true

# # #               # --- Blocks for interface core config ---
# # #               ethernet_interface {
# # #                 device = interface_list.value == 0 ? "ens5" : "ens6"
# # #                 mac = ""
# # #               }

# # #               network_option {
# # #                 # SLI (ens5, index 0): site_local_network is TRUE, site_local_inside_network is FALSE
# # #                 site_local_network = interface_list.value == 0

# # #                 # SLI (ens6, index 1): site_local_network is FALSE, site_local_inside_network is TRUE
# # #                 site_local_inside_network = interface_list.value == 1
# # #               }
# # #             }
# # #           }
# # #         }
# # #       }
# # #     }
# # #   }

#   aws {
#     not_managed {
#       node_list {
#         # Node Identifier (single node)
#         hostname = "ip-${replace(aws_network_interface.f5xc-outside[count.index].private_ip, ".", "-")}"
#         type     = "Control"

#         # Interface 1: ens5 (site_local_network = true)
#         interface_list {
#           name        = "ens5"
#           priority    = 0
#           mtu         = 0
#           dhcp_client = true

#           ethernet_interface {
#             device = "ens5"
#             mac   = ""
#           }

#           network_option {
#             site_local_network        = true
#             site_local_inside_network = false
#           }
#         }

#         # Interface 2: ens6 (site_local_inside_network = true)
#         interface_list {
#           name        = "ens6"
#           priority    = 0
#           mtu         = 0
#           dhcp_client = true

#           ethernet_interface {
#             device = "ens6"
#             mac   = ""
#           }

#           network_option {
#             site_local_network        = false
#             site_local_inside_network = true
#           }
#         }
#       }
#     }
#   }


#   # local_vrf {
#   #   sli_config {
#   #     static_routes {
#   #       static_routes {
#   #         ip_prefixes = ["10.1.0.0/16", "10.2.0.0/16"]
#   #         ip_address  = "10.0.${count.index + 1}2.1"
#   #         attrs       = ["ROUTE_ATTR_INSTALL_FORWARDING"]
#   #       }
#   #     }
#   #   }
#   # }

#   # active_enhanced_firewall_policies {
#   #   enhanced_firewall_policies {
#   #     name = "arch-vsite-fw-policy"
#   #     # name      = "arch-ce-policy"
#   #     namespace = "system"
#   #   }
#   # }

#   lifecycle {
#     ignore_changes = [
#       labels
#     ]
#   }
# }

resource "volterra_securemesh_site_v2" "site" {
  count              = var.f5xc_sms_node_count
  name               = format("%s-node-%s", local.f5xc_sms_name, count.index)
  namespace          = "system"
  description        = var.f5xc_sms_description
  block_all_services = true
  disable_ha         = true

  logs_streaming_disabled = true
  labels = {
    "virtual-site-terraform" = volterra_known_label.label.value
    "ves.io/provider"        = "ves-io-AWS"
  }

  aws {
    not_managed {
      node_list {
        hostname = "ip-${replace(aws_network_interface.f5xc-outside[count.index].private_ip, ".", "-")}"
        type     = "Control"
        interface_list {
          name        = "ens5"
          priority    = 0
          mtu         = 0
          dhcp_client = true

          ethernet_interface {
            device = "ens5"
            mac    = ""
          }

          network_option {
            site_local_network        = true
            site_local_inside_network = false
          }
        }

        # Interface 2: ens6 (site_local_inside_network = true)
        interface_list {
          name        = "ens6"
          priority    = 0
          mtu         = 0
          dhcp_client = true

          ethernet_interface {
            device = "ens6"
            mac    = ""
          }

          network_option {
            site_local_network        = false
            site_local_inside_network = true
          }
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
