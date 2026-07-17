output "proxmox" {
  value = {
    secure_mesh_single_nic = volterra_securemesh_site_v2.site
    master_vm              = proxmox_vm_qemu.master-vm
  }
  sensitive = true
}
