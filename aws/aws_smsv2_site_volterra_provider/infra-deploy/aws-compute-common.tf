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

locals {
  internal_vpc_cidr                   = aws_vpc.f5xc.cidr_block
  tailscale_advertise_routes          = var.tailscale_advertise_routes
  tailscale_subnet_router_ipsec_peer  = var.f5xc_ce_ipsec_peer_ip != "" ? var.f5xc_ce_ipsec_peer_ip : aws_network_interface.f5xc-outside[0].private_ip
  tailscale_subnet_router_ipsec_psk   = var.f5xc_ce_ipsec_psk != "" ? var.f5xc_ce_ipsec_psk : random_password.tailscale_subnet_router_ipsec_psk.result
  tailscale_subnet_router_tunnel_cidr = split("/", var.f5xc_ce_ipsec_local_tunnel_ip)[1]
}
