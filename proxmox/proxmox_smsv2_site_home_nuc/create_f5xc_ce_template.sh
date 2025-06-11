#!/bin/bash
# Frist, download the latest qcow2 image for F5 XC CE.  You can create a test smsv2 site in t7he XC UI and 
# then click the elipses ('...') and then 'Copy Image Name'.  That will give you the latest version of the 
# download URL, so the wget command example below can be updated accordingly:
#
# wget https://vesio.blob.core.windows.net/releases/rhel/9/x86_64/images/securemeshV2/f5xc-ce-9.2024.44-20250102051113.qcow2
#
# Run this on proxmox server!

# adjust full path to downloaded qcow2 file, target template id and storage ..

#qcow2=/root/f5xc-ce-9.2024.44-20250102051113.qcow2
qcow2=/root/f5xc-ce-9.2025.17-20250422074005.qcow2
id=9000
# storage=cephpool
storage=local-crucial-2tb-ssd

echo "resizing image to 100G ..."
qemu-img resize $qcow2 100G
echo "destroying existing VM $id (if present) ..."
qm destroy $id
echo "creating vm template $id from $image .."
qm create $id --memory 16384 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci
qm set $id --name f5xc-ce-template-2025-17
qm set $id --scsi0 $storage:0,import-from=$qcow2
qm set $id --boot order=scsi0
qm set $id --serial0 socket --vga serial0
qm template $id
