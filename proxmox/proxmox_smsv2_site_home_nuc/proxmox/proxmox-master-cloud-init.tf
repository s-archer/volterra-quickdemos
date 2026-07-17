resource "proxmox_cloud_init_disk" "master-ci" {
  name     = format("%s-coud-init", var.f5xc_sms_name)
  pve_node = var.pm_target_node
  storage  = var.iso_storage_pool

  meta_data = yamlencode({
    instance_id    = sha1(var.f5xc_sms_name)
    local-hostname = var.f5xc_sms_name
  })

  user_data = templatefile("${path.module}/templates/user-data.tpl", {
    token = volterra_token.smsv2-token.id
  })
}