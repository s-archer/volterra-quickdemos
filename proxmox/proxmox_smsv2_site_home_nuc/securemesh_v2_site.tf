module "securemesh-v2-site" {
  count            = 1
  source           = "./proxmox"
  f5xc_sms_name    = format("%s-node-%s", local.f5xc_sms_name, count.index)
  pm_clone         = var.pm_clone
  pm_storage_pool  = var.pm_storage_pool
  iso_storage_pool = var.iso_storage_pool

  master_cpus        = 4
  secure_mesh_memory = 32768

  latitude              = 51.99102
  longitude             = -0.66744
  volterra_certified_hw = "kvm-voltmesh"
  ssh_public_key        = var.ssh_public_key
  pm_target_node        = var.pm_target_nodes[count.index % length(var.pm_target_nodes)]
  outside_network       = "vmbr0"
  # set  to generate fixed  macaddr per node (last octet set to node index)
  # outside_macaddr       = "02:02:02:00:00:00"   

  f5xc_tenant    = var.f5xc_tenant
  f5xc_api_url   = var.f5xc_api_url
  f5xc_api_token = var.f5xc_api_token
}