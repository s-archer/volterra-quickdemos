resource "proxmox_vm_qemu" "master-vm" {
  depends_on  = [proxmox_cloud_init_disk.master-ci]
  name        = var.f5xc_sms_name
  target_node = var.pm_target_node
  clone       = var.pm_clone
  pool        = var.pm_pool
  memory      = var.secure_mesh_memory
  os_type     = "cloud-init"
  scsihw      = "virtio-scsi-pci"
  serial {
    id = 0
    type = "socket"
  }
  agent     = 1
  onboot    = true
  skip_ipv6 = true # required until https://github.com/Telmate/terraform-provider-proxmox/issues/1015 is fixed
  # # Enable hugepages with custom QEMU args
  # args = "-mem-prealloc -mem-path /dev/hugepages"

  cpu {
    sockets = 1
    cores   = var.master_cpus
    type    = "host"

  }

  network {
    id     = 0
    bridge = var.outside_network
    model  = "virtio"
    # macaddr           = ""
    tag = var.outside_network_vlan
  }

  dynamic "network" {
    for_each = var.inside_network == "" ? [] : [var.inside_network]
    content {
      id     = 1
      bridge = var.inside_network
      model  = "virtio"
      tag    = var.inside_network_vlan
    }
  }

  disks {
    scsi {
      scsi0 {
        disk {
          storage = var.pm_storage_pool
          size    = "100G"
        }
      }
    }
    ide {
      ide2 {
        cdrom {
          iso = proxmox_cloud_init_disk.master-ci.id
        }
      }
    }
  }

  lifecycle {
    ignore_changes = all
  }
}
