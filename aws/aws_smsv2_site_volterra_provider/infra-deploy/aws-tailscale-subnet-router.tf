resource "aws_network_interface" "tailscale_router_mgmt" {
  subnet_id       = aws_subnet.eks_bip_mgmt[0].id
  private_ips     = [cidrhost(aws_subnet.eks_bip_mgmt[0].cidr_block, 250)]
  security_groups = [aws_security_group.mgmt.id]

  tags = {
    Name  = "${var.prefix}tailscale-router-mgmt"
    UK-SE = var.uk_se_name
  }
}

resource "aws_network_interface" "tailscale_router_internal" {
  subnet_id         = aws_subnet.eks_bip_inside[0].id
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
  user_data = base64encode(templatefile("${path.module}/templates/tailscale-subnet-router.tpl", {
    hostname                       = "tailscale-subnet-router"
    server_number                  = 0
    aws_region                     = var.region
    mgmt_mac                       = aws_network_interface.tailscale_router_mgmt.mac_address
    internal_mac                   = aws_network_interface.tailscale_router_internal.mac_address
    mgmt_gateway                   = cidrhost(aws_subnet.eks_bip_mgmt[0].cidr_block, 1)
    internal_gateway               = cidrhost(aws_subnet.eks_bip_inside[0].cidr_block, 1)
    internal_vpc_cidr              = local.internal_vpc_cidr
    internal_private_ip            = aws_network_interface.tailscale_router_internal.private_ip
    enable_tailscale_subnet_router = true
    tailscale_auth_key             = var.tailscale_auth_key
    tailscale_tag                  = var.tailscale_tag
    tailscale_advertise_routes     = join(",", local.tailscale_advertise_routes)
    internal_extra_routes          = join(" ", tolist(setsubtract(toset(local.tailscale_advertise_routes), toset(var.f5xc_ce_ipsec_remote_routes))))
    enable_f5xc_ce_ipsec           = true
    f5xc_ce_ipsec_peer_ip          = local.tailscale_subnet_router_ipsec_peer
    f5xc_ce_ipsec_psk              = local.tailscale_subnet_router_ipsec_psk
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
