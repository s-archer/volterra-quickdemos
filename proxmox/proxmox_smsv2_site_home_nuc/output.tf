output "proxmox" {
  value = {
    securemesh = module.securemesh-v2-site
  }
  sensitive = true
}
