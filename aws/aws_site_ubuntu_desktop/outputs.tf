output "ubuntu_url" {
  description = "Domain VIP to access Ubuntu"
  value       = format("https://%s", var.ubuntu_domain)
}

output "ubuntu_password" {
  description = "Domain VIP to access Ubuntu"
  value       = module.ubuntu[0].ubuntu_password
}