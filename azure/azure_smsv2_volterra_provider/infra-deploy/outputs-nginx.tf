output "ssh_commands" {
  value = {
    for i in range(var.vm_count) :
    "${var.prefix}-vm-${i + 1}" => "ssh azureuser@${azurerm_public_ip.nginx[i].ip_address}"
  }
}
