data "aws_ami" "f5xc" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.f5xc_ami]
  }
  owners = ["434481986642"] # F5 Networks, Inc.
}

resource "aws_instance" "xc" {
  count         = var.f5xc_sms_node_count
  ami           = data.aws_ami.f5xc.id
  instance_type = "t3.xlarge"

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
    Name                                           = "${var.prefix}-ubuntu"
    ves-io-site-name                               = local.f5xc_sms_name
    "kubernetes.io/cluster/${local.f5xc_sms_name}" = local.f5xc_sms_name
    UK-SE                                          = var.uk_se_name

  }
}



resource "aws_security_group" "outside" {
  name        = "${var.prefix}outside"
  description = "Allow outbound only"
  vpc_id      = aws_vpc.f5xc.id

  # ingress {}

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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

resource "volterra_securemesh_site_v2" "site" {
  count                   = var.f5xc_sms_node_count
  name                    = format("%s-node-%s", local.f5xc_sms_name, count.index)
  namespace               = "system"
  description             = var.f5xc_sms_description
  block_all_services      = true
  logs_streaming_disabled = true
  enable_ha               = false
  labels = {
    (volterra_known_label_key.key.key) = (volterra_known_label.label.value)
    "ves.io/provider"                  = "ves-io-AWS"
  }

  re_select {
    geo_proximity = true
  }

  aws {
    not_managed {}
  }

  local_vrf {
    sli_config {
      static_routes {
        static_routes {
          ip_prefixes = ["10.1.0.0/16", "10.2.0.0/16"]
          ip_address  = "10.0.102.1"
          attrs       = ["ROUTE_ATTR_INSTALL_FORWARDING"]
        }
      }
    }
  }

  active_enhanced_firewall_policies {
    enhanced_firewall_policies {
      name = "arch-vsite-fw-policy"
      # name      = "arch-ce-policy"
      namespace = "system"
    }
  }

  lifecycle {
    ignore_changes = [
      labels
    ]
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

resource "volterra_known_label_key" "key" {
  key         = "virtual-site-terraform"
  namespace   = "shared"
  description = "Used to define lables for Virtual Sites "
}

resource "volterra_known_label" "label" {
  key       = volterra_known_label_key.key.key
  namespace = "shared"
  value     = local.f5xc_sms_name
}

resource "volterra_virtual_site" "ce" {
  name      = local.f5xc_sms_name
  namespace = "shared"

  site_selector {
    expressions = [format("%s = %s", volterra_known_label_key.key.key, volterra_known_label.label.value)]
  }

  site_type = "CUSTOMER_EDGE"
}