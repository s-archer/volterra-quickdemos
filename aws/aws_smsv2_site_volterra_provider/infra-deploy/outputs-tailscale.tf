output "tailscale-router-ui" {
  value = "https://${aws_eip.tailscale_router_mgmt.public_ip}"
}

output "tailscale-router-ssh" {
  value = "ssh ubuntu@${aws_eip.tailscale_router_mgmt.public_ip} -i ssh-key.pem"
}

output "tailscale-router-internal" {
  value = aws_network_interface.tailscale_router_internal.private_ip
}

output "tailscale-advertise-routes" {
  value = local.tailscale_advertise_routes
}

output "tailscale-router-ipsec-psk" {
  value     = local.tailscale_subnet_router_ipsec_psk
  sensitive = true
}
