# Deploy F5 Distributed Cloud Site on Proxmox VE

Example Terraform scripts to deploy F5XC Secure Mesh sites (v2) on Proxmox Virtual Environment.

## Requirements


### F5XC CE VM Template

* For the timebeing you must use the EA image https://downloads.volterra.io/releases/rhel/9/x86_64/images/securemeshV2/f5xc-ce-9.2025.17-20250422074005.qcow2

Once the supported version has exceeded the above version, you can follow the instructions in the next bullet instead.

- Download the latest qcow2 image.  Easiest way to do this is to create a quick clickops SMSv2 KVM site and click `...` > `Copy Image Name`.  Then directly on your Proxmox server, run `wget <image name>`
- Create a template from the download qcow2 image file on your Proxmox server, adjusting the full (!) path to the downloaded qcow2 image, the template id and the Proxmox iso storage to save it.  Use the [create template script](create_f5xc_ce_template.sh) directly on the Proxmox server.

## Create terraform.tfvars

Copy [terraform.tfvars.example](terraform.tfvars.example) to terraform.tvars and adjust accordingly.

## Deploy Site

Deploy with 

```
terraform init
terraform plan
terraform apply
```

Terraform will create the site in your F5XC Tenant, clone and launch the VM.  You need to wait for the site to become ONLINE.

##  Arch Note.

If I want BGP to work :
- Check that the Edge Router (192.168.1.2) has the correct peer address.  Check that SGW still has a static route to 192.168.10.0/24:
- Check that XC objects are correct:
  - Virtual network:  arch-bgp-outside  # check it exists.
  - Network Interface: arch-bgp-slo  # check it exists
  - BGPs :  arch-igw-bgp (old name, bvut should work) make sure refers to home NUC app-stack site and Network Interface above.
- Create VIPs on 192.168.10.0/24