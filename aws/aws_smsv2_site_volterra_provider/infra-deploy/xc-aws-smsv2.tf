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

  lifecycle {
    ignore_changes = all
  }
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
        hostname = format("node-%s", count.index)
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
