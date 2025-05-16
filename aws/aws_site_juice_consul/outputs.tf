output "app_url" {
  description = "Domain VIP to access the web app"
  value       = format("https://%s", var.app_domain)
}

output "consul_url" {
  description = "Domain VIP to access Consul"
  value       = format("https://%s", var.consul_domain)
}
