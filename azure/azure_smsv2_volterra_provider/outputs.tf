output "ssh_f5_username" {
  value = "volterra-admin"
}

output "ssh_f5_password" {
  value = random_string.password.result
}

output "ssh_f5-1" {
  value = var.f5xc_sms_node_count > 0 ? "ssh admin@${azurerm_public_ip.outside_public_ip[0].ip_address}" : null
}

