data "tailscale_device" "aws_nginx" {
  for_each = (
    var.enable_tailscale_device_lookup
    ? toset(local.aws_nginx_tailnet_hostnames)
    : toset([])
  )

  hostname = each.value
  wait_for = "120s"
}

data "tailscale_device" "azure_nginx" {
  for_each = (
    var.enable_tailscale_device_lookup
    ? toset(local.azure_nginx_tailnet_hostnames)
    : toset([])
  )

  hostname = each.value
  wait_for = "120s"
}
