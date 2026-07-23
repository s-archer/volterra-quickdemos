resource "aws_network_interface" "mgmt" {
  count = var.linux_server_count

  subnet_id       = aws_subnet.eks_bip_mgmt[0].id
  private_ips     = [cidrhost(aws_subnet.eks_bip_mgmt[0].cidr_block, 10 + count.index)]
  security_groups = [aws_security_group.mgmt.id]

  tags = {
    Name  = var.linux_server_count == 1 ? "${var.prefix}linux-mgmt" : "${var.prefix}linux-${count.index + 1}-mgmt"
    UK-SE = var.uk_se_name
  }
}

resource "aws_network_interface" "internal" {
  count = var.linux_server_count

  subnet_id       = aws_subnet.eks_bip_inside[0].id
  security_groups = [aws_security_group.internal.id]

  tags = {
    Name  = var.linux_server_count == 1 ? "${var.prefix}linux-internal" : "${var.prefix}linux-${count.index + 1}-internal"
    UK-SE = var.uk_se_name
  }
}

resource "aws_eip" "mgmt" {
  count = var.linux_server_count

  domain                    = "vpc"
  network_interface         = aws_network_interface.mgmt[count.index].id
  associate_with_private_ip = aws_network_interface.mgmt[count.index].private_ip

  tags = {
    Name  = var.linux_server_count == 1 ? "${var.prefix}linux-mgmt" : "${var.prefix}linux-${count.index + 1}-mgmt"
    UK-SE = var.uk_se_name
  }
}

resource "aws_instance" "linux" {
  count = var.linux_server_count

  ami = data.aws_ami.ubuntu.id
  user_data = base64encode(templatefile("${path.module}/templates/nginx.tpl", {
    hostname                   = var.linux_server_count == 1 ? "linux-server" : "linux-server-${count.index + 1}"
    server_number              = count.index + 1
    aws_region                 = var.region
    mgmt_mac                   = aws_network_interface.mgmt[count.index].mac_address
    internal_mac               = aws_network_interface.internal[count.index].mac_address
    mgmt_gateway               = cidrhost(aws_subnet.eks_bip_mgmt[0].cidr_block, 1)
    internal_gateway           = cidrhost(aws_subnet.eks_bip_inside[0].cidr_block, 1)
    internal_vpc_cidr          = local.internal_vpc_cidr
    internal_private_ip        = aws_network_interface.internal[count.index].private_ip
    tailscale_auth_key         = var.tailscale_auth_key
    tailscale_advertise_routes = join(",", local.tailscale_advertise_routes)
    internal_extra_routes      = ""
  }))
  instance_type = "t3.small"
  key_name      = aws_key_pair.demo.key_name
  root_block_device { delete_on_termination = true }

  network_interface {
    network_interface_id = aws_network_interface.mgmt[count.index].id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.internal[count.index].id
    device_index         = 1
  }

  tags = {
    Name  = var.linux_server_count == 1 ? "${var.prefix}open-vpn-server" : "${var.prefix}open-vpn-server-${count.index + 1}"
    Env   = "aws"
    UK-SE = var.uk_se_name
  }

  lifecycle {
    ignore_changes = [
      ami
    ]
  }
}
