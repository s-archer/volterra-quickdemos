output "app_url" {
  description = "Domain VIP to access Ubuntu"
  value       = format("https://%s", var.lb_fqdn)
}
