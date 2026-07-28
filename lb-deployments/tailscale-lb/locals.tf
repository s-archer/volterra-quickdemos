locals {
  aws_site_name = (
    var.aws_site_name != ""
    ? var.aws_site_name
    : (
      var.enable_aws_remote_state
      ? data.terraform_remote_state.aws[0].outputs["site-name"]
      : ""
    )
  )

  azure_site_name = (
    var.azure_site_name != ""
    ? var.azure_site_name
    : (
      var.enable_azure_remote_state
      ? data.terraform_remote_state.azure[0].outputs["azure-site-name"]
      : ""
    )
  )

  aws_nginx_tailnet_hostnames = (
    length(var.aws_nginx_tailnet_hostnames) > 0
    ? var.aws_nginx_tailnet_hostnames
    : (
      var.enable_aws_remote_state
      ? try(data.terraform_remote_state.aws[0].outputs["nginx-tailnet-hostnames"], [])
      : []
    )
  )

  azure_nginx_tailnet_hostnames = (
    length(var.azure_nginx_tailnet_hostnames) > 0
    ? var.azure_nginx_tailnet_hostnames
    : (
      var.enable_azure_remote_state
      ? try(data.terraform_remote_state.azure[0].outputs["nginx-tailnet-hostnames"], [])
      : []
    )
  )

  aws_nginx_tailnet_ips_from_tailscale = [
    for device in data.tailscale_device.aws_nginx :
    one([for address in device.addresses : address if can(regex("^\\d+\\.", address))])
  ]

  azure_nginx_tailnet_ips_from_tailscale = [
    for device in data.tailscale_device.azure_nginx :
    one([for address in device.addresses : address if can(regex("^\\d+\\.", address))])
  ]

  aws_nginx_tailnet_ips = (
    var.enable_tailscale_device_lookup
    ? local.aws_nginx_tailnet_ips_from_tailscale
    : var.aws_nginx_tailnet_ips
  )

  azure_nginx_tailnet_ips = (
    var.enable_tailscale_device_lookup
    ? local.azure_nginx_tailnet_ips_from_tailscale
    : var.azure_nginx_tailnet_ips
  )

  create_aws_origin_pool   = length(local.aws_nginx_tailnet_ips) > 0 && local.aws_site_name != ""
  create_azure_origin_pool = length(local.azure_nginx_tailnet_ips) > 0 && local.azure_site_name != ""

  default_route_pools = concat(
    local.create_azure_origin_pool ? [{
      name     = volterra_origin_pool.azure_nginx[0].name
      priority = 1
      weight   = 1
    }] : [],
    local.create_aws_origin_pool ? [{
      name     = volterra_origin_pool.aws_nginx[0].name
      priority = 1
      weight   = 1
    }] : []
  )

  create_load_balancer = length(local.default_route_pools) > 0
}
