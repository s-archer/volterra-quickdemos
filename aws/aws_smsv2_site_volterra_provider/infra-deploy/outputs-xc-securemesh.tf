output "site-name" {
  value = volterra_securemesh_site_v2.site[0].name
}

output "virtual-site-name" {
  value = local.f5xc_sms_name
}

output "virtual-site-namespace" {
  value = volterra_virtual_site.ce.namespace
}

# output "secret-data" {
#   value     = data.kubernetes_secret_v1.f5xc-secret.data.token
#   sensitive = true
# }
