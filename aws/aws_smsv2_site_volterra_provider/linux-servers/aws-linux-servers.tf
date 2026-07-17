data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    # values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
    # values = ["al2023-ami-ecs-hvm-2023*x86*"]
    values = ["*ubuntu-noble-24.04-amd64-server*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
  # owners = ["591542846629"] # AWS
}

data "aws_subnet" "mgmt" {
  id = data.terraform_remote_state.eks.outputs.subnet_id_bip_mgmt
}

data "aws_subnet" "internal" {
  id = data.terraform_remote_state.eks.outputs.subnet_id_bip_inside
}

data "aws_vpc" "main" {
  id = data.terraform_remote_state.eks.outputs.vpc_id
}

locals {
  internal_vpc_cidr          = data.aws_vpc.main.cidr_block
  tailscale_advertise_routes = var.tailscale_advertise_routes
}

resource "random_string" "password" {
  length  = 10
  special = false
}

resource "aws_network_interface" "mgmt" {
  count = var.linux_server_count

  subnet_id       = data.terraform_remote_state.eks.outputs.subnet_id_bip_mgmt
  private_ips     = [cidrhost(data.aws_subnet.mgmt.cidr_block, 10 + count.index)]
  security_groups = [aws_security_group.mgmt.id]

  tags = {
    Name  = var.linux_server_count == 1 ? "${var.prefix}linux-mgmt" : "${var.prefix}linux-${count.index + 1}-mgmt"
    UK-SE = var.uk_se_name
  }
}

resource "aws_network_interface" "internal" {
  count = var.linux_server_count

  subnet_id       = data.terraform_remote_state.eks.outputs.subnet_id_bip_inside
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
  user_data = base64encode(templatefile("${path.module}/scripts/linux.sh", {
    hostname                       = var.linux_server_count == 1 ? "linux-server" : "linux-server-${count.index + 1}"
    mgmt_mac                       = aws_network_interface.mgmt[count.index].mac_address
    internal_mac                   = aws_network_interface.internal[count.index].mac_address
    mgmt_gateway                   = cidrhost(data.aws_subnet.mgmt.cidr_block, 1)
    internal_gateway               = cidrhost(data.aws_subnet.internal.cidr_block, 1)
    internal_vpc_cidr              = local.internal_vpc_cidr
    internal_private_ip            = aws_network_interface.internal[count.index].private_ip
    enable_tailscale_subnet_router = false
    tailscale_auth_key             = var.tailscale_auth_key
    tailscale_advertise_routes     = join(",", local.tailscale_advertise_routes)
    internal_extra_routes          = ""
    enable_f5xc_ce_ipsec           = false
    f5xc_ce_ipsec_peer_ip          = ""
    f5xc_ce_ipsec_psk              = ""
    f5xc_ce_ipsec_remote_routes    = ""
    f5xc_ce_ipsec_interface_name   = var.f5xc_ce_ipsec_interface_name
    f5xc_ce_ipsec_interface_id     = var.f5xc_ce_ipsec_interface_id
    f5xc_ce_ipsec_local_tunnel_ip  = var.f5xc_ce_ipsec_local_tunnel_ip
    f5xc_ce_ipsec_remote_tunnel_ip = var.f5xc_ce_ipsec_remote_tunnel_ip
    f5xc_ce_ipsec_ike_proposals    = var.f5xc_ce_ipsec_ike_proposals
    f5xc_ce_ipsec_esp_proposals    = var.f5xc_ce_ipsec_esp_proposals
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

  # Checks that AS3 App is available
  # provisioner "local-exec" {
  #   command = "while [[ \"$(curl -ski http://${aws_eip.external-vs1.public_ip} | grep -Eoh \"^HTTP/1.1 200\")\" != \"HTTP/1.1 200\" ]]; do sleep 5; done"
  # }

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

resource "aws_network_interface" "tailscale_router_mgmt" {
  subnet_id       = data.terraform_remote_state.eks.outputs.subnet_id_bip_mgmt
  private_ips     = [cidrhost(data.aws_subnet.mgmt.cidr_block, 250)]
  security_groups = [aws_security_group.mgmt.id]

  tags = {
    Name  = "${var.prefix}tailscale-router-mgmt"
    UK-SE = var.uk_se_name
  }
}

resource "aws_network_interface" "tailscale_router_internal" {
  subnet_id         = data.terraform_remote_state.eks.outputs.subnet_id_bip_inside
  security_groups   = [aws_security_group.internal.id]
  source_dest_check = false

  tags = {
    Name  = "${var.prefix}tailscale-router-internal"
    UK-SE = var.uk_se_name
  }
}

resource "aws_eip" "tailscale_router_mgmt" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.tailscale_router_mgmt.id
  associate_with_private_ip = aws_network_interface.tailscale_router_mgmt.private_ip

  tags = {
    Name  = "${var.prefix}tailscale-router-mgmt"
    UK-SE = var.uk_se_name
  }
}

resource "aws_instance" "tailscale_router" {
  ami = data.aws_ami.ubuntu.id
  user_data = base64encode(templatefile("${path.module}/scripts/linux.sh", {
    hostname                       = "tailscale-subnet-router"
    mgmt_mac                       = aws_network_interface.tailscale_router_mgmt.mac_address
    internal_mac                   = aws_network_interface.tailscale_router_internal.mac_address
    mgmt_gateway                   = cidrhost(data.aws_subnet.mgmt.cidr_block, 1)
    internal_gateway               = cidrhost(data.aws_subnet.internal.cidr_block, 1)
    internal_vpc_cidr              = local.internal_vpc_cidr
    internal_private_ip            = aws_network_interface.tailscale_router_internal.private_ip
    enable_tailscale_subnet_router = true
    tailscale_auth_key             = var.tailscale_auth_key
    tailscale_advertise_routes     = join(",", local.tailscale_advertise_routes)
    internal_extra_routes          = join(" ", tolist(setsubtract(toset(local.tailscale_advertise_routes), toset(var.f5xc_ce_ipsec_remote_routes))))
    enable_f5xc_ce_ipsec           = var.f5xc_ce_ipsec_psk != ""
    f5xc_ce_ipsec_peer_ip          = var.f5xc_ce_ipsec_peer_ip
    f5xc_ce_ipsec_psk              = var.f5xc_ce_ipsec_psk
    f5xc_ce_ipsec_remote_routes    = join(",", var.f5xc_ce_ipsec_remote_routes)
    f5xc_ce_ipsec_interface_name   = var.f5xc_ce_ipsec_interface_name
    f5xc_ce_ipsec_interface_id     = var.f5xc_ce_ipsec_interface_id
    f5xc_ce_ipsec_local_tunnel_ip  = var.f5xc_ce_ipsec_local_tunnel_ip
    f5xc_ce_ipsec_remote_tunnel_ip = var.f5xc_ce_ipsec_remote_tunnel_ip
    f5xc_ce_ipsec_ike_proposals    = var.f5xc_ce_ipsec_ike_proposals
    f5xc_ce_ipsec_esp_proposals    = var.f5xc_ce_ipsec_esp_proposals
  }))
  instance_type = "t3.small"
  key_name      = aws_key_pair.demo.key_name
  root_block_device { delete_on_termination = true }

  network_interface {
    network_interface_id = aws_network_interface.tailscale_router_mgmt.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.tailscale_router_internal.id
    device_index         = 1
  }

  tags = {
    Name  = "${var.prefix}tailscale-subnet-router"
    Env   = "aws"
    UK-SE = var.uk_se_name
  }
  lifecycle {
    ignore_changes = [
      ami
    ]
  }
}
