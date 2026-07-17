output "proxmox" {
  value = {
    securemesh = module.securemesh-v2-site
  }
  sensitive = true
}

output "vsite" {
  value = local.f5xc_sms_name
}