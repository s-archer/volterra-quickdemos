output "load_balancer_name" {
  value = try(volterra_http_loadbalancer.tailscale_nginxs[0].name, null)
}

output "load_balancer_domains" {
  value = var.lb_domains
}

output "aws_origin_pool_name" {
  value = try(volterra_origin_pool.aws_nginx[0].name, null)
}

output "azure_origin_pool_name" {
  value = try(volterra_origin_pool.azure_nginx[0].name, null)
}

output "aws_site_name" {
  value = local.aws_site_name
}

output "azure_site_name" {
  value = local.azure_site_name
}

output "aws_nginx_tailnet_hostnames" {
  value = local.aws_nginx_tailnet_hostnames
}

output "azure_nginx_tailnet_hostnames" {
  value = local.azure_nginx_tailnet_hostnames
}

output "aws_nginx_tailnet_ips" {
  value = local.aws_nginx_tailnet_ips
}

output "azure_nginx_tailnet_ips" {
  value = local.azure_nginx_tailnet_ips
}
