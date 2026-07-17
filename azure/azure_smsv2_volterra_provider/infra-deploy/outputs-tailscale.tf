output "tailscale_subnet_router_ssh_command" {
  value = "ssh azureuser@${azurerm_public_ip.tailscale_subnet_router.ip_address}"
}

output "tailscale_subnet_router_public_ip" {
  value = azurerm_public_ip.tailscale_subnet_router.ip_address
}

output "tailscale_subnet_router_private_ip" {
  value = azurerm_network_interface.tailscale_subnet_router.private_ip_address
}

output "tailscale_subnet_router_ipsec_remote_ip" {
  value = azurerm_network_interface.inside_nic[0].private_ip_address
}

output "tailscale_subnet_router_ipsec_psk" {
  value     = random_password.tailscale_subnet_router_ipsec_psk.result
  sensitive = true
}
