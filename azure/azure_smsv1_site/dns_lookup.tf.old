provider "dns" {
}

# unable to resolve "*.ves.volterra.io", "*.blob.core.windows.net", "*.gcr.io", "update.release.core-os.net"
locals {
  dns_names = toset(["api.bcti.brightcloud.com", "blindfold.ves.volterra.io", "docker.com", "docker.io", "downloads.volterra.io", "fedex-onepurple.console.ves.volterra.io", "gcr.io", "identityauthority.ves.volterra.io", "k8s.gcr.io", "localdb-ip-daily.brightcloud.com", "localdb-ip-rtu.brightcloud.com", "localdb-url-daily.brightcloud.com", "localdb-url-rtu.brightcloud.com", "login.ves.volterra.io", "quay.io", "register-tls.ves.volterra.io", "register.ves.volterra.io", "storage.googleapis.com", "vesio.azureedge.net", "volterra.azurecr.io", "waferdatasetsprod.blob.core.windows.net", "www.google.com"])
  resolved_ips = sort(flatten([
    for each_name in data.dns_a_record_set.resolved :
    each_name.addrs
  ]))
  cidrs = distinct(sort(flatten([
    for each_ip in local.resolved_ips :
    format("%s.%s.0.0/16", element(split(".", each_ip), 0), element(split(".", each_ip), 1))
  ])))
}

data "dns_a_record_set" "resolved" {
  for_each = local.dns_names
  host     = each.value
}

output "ip_list" {
  value = local.cidrs
}