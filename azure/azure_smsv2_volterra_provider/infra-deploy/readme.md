# Azure Secure Mesh Site v2 Demo

This deployment creates an Azure F5 Distributed Cloud Secure Mesh Site v2 environment with AKS, Linux NGINX origins, a Tailscale subnet router, and XC objects for service discovery and Tailscale/IPsec/BGP connectivity.

## What It Deploys

- Azure resource group, virtual network, subnets, peerings, route tables, and security groups.
- F5 Distributed Cloud CE virtual machine using Secure Mesh Site v2.
- AKS cluster and XC Kubernetes service discovery objects.
- Tailscale-enabled Linux NGINX virtual machines.
- Dedicated Tailscale subnet-router virtual machine.
- Route-based IPsec from the Tailscale subnet router to the CE.
- XC external connector and BGP peer for the Tailscale/IPsec path.

Optional components live in `optional/`.

## File Layout

Terraform files are grouped by ownership:

- `azure-network-core.tf` - resource group, VNet, and subnets.
- `azure-network-peerings.tf` - VNet peerings.
- `azure-peer-route-tables.tf` - peer route tables and routes.
- `azure-security-groups.tf` - security rules in one place.
- `azure-aks.tf` - AKS resources.
- `azure-ce-load-balancer.tf` - CE load-balancer resources.
- `azure-tailscale-nginx-vms.tf` - Linux NGINX servers that join Tailscale.
- `azure-tailscale-subnet-router.tf` - dedicated Tailscale subnet router VM.
- `xc-azure-smsv2.tf` - XC Secure Mesh Site v2 and CE VM resources.
- `xc-bgp-tailscale.tf` - XC external connector and BGP peer for the subnet router.
- `xc-k8s-service-discovery.tf` - Kubernetes and XC discovery objects.
- `outputs-*.tf` - Outputs split by topic.
- `templates/` - Cloud-init/user-data templates.

## Credentials And Variables

Copy the public-safe example file for local use:

```bash
cp variables.tf.example variables.tf
```

`variables.tf` is ignored by Git. Put real Azure, XC, and Tailscale values there or in a credentials file outside the repo.

Set the XC API certificate passphrase:

```bash
export VES_P12_PASSWORD='<p12-passphrase>'
```

Azure credentials can be supplied in a private tfvars file:

```hcl
subscription_id = "00000000-0000-0000-0000-000000000000"
client_secret   = "replace-with-private-value"
client_id       = "00000000-0000-0000-0000-000000000000"
tenant_id       = "00000000-0000-0000-0000-000000000000"
tailscale_auth_key = "replace-with-private-value"
```

Then apply with:

```bash
terraform apply -var-file=../../../../creds/azure_creds.tfvars
```

Important variables:

- `f5xc_api_url` and `f5xc_api_p12_file` - XC tenant API endpoint and local certificate path.
- `f5xc_tenant` - XC tenant name used in generated XC references.
- `tailscale_auth_key` - reusable ephemeral Tailscale auth key.
- `tailscale_tag` - subnet-router tag, default `tsr-azure`.
- `local_tailnet_routes` - routes exported from FRR/BGP to the CE, default `100.81.0.0/16`.
- `remote_tailnet_routes` - routes advertised by Tailscale into this tailnet, default includes the AWS tailnet and tunnel/VNet ranges.

## Azure Service Principal

Create an Azure app registration and client secret, then grant it access to the subscription:

1. Create an App Registration in Microsoft Entra ID.
2. Create a client secret and save the value immediately.
3. Use the Application client ID as `client_id`.
4. Use the Directory tenant ID as `tenant_id`.
5. Use the Azure subscription ID as `subscription_id`.
6. Grant the app an appropriate role, such as Contributor, on the target subscription or resource group.

## Deploy

```bash
cd azure/azure_smsv2_volterra_provider/infra-deploy
terraform init
terraform validate
terraform plan
terraform apply -var-file=../../../../creds/azure_creds.tfvars
```

## Redeploying The CE

XC CE names cannot be reused for 30 days after deletion. If rebuilding the CE, generate a new `random_id` so the CE site name, Azure VM hostname, and XC token are recreated together.

Use targeted replacement for the minimum destructive change, then review the full plan:

```bash
terraform plan \
  -replace=random_id.id \
  -replace=volterra_token.smsv2-token[0] \
  -replace=azurerm_virtual_machine.f5xc-nodes[0] \
  -replace=volterra_securemesh_site_v2.site[0]
```

Only apply once the plan shows the intended CE-related replacements. Preserve NICs and IPs where possible by replacing the VM and site objects rather than manually deleting dependent networking.

## Tailscale, IPsec, And BGP

The subnet-router user-data configures:

- Tailscale with an auth key and `tag:tsr-azure`.
- StrongSwan route-based IPsec using `ipsec0`.
- FRR BGP peering to the XC CE tunnel IP.
- A blackhole route for each local tailnet route so FRR can advertise it.
- A route-map so only the intended local tailnet routes are exported.

The NGINX servers join Tailscale but do not advertise routes.

## Safety Notes

Do not commit:

- `variables.tf`
- `*.tfvars`
- `*.tfstate`
- `*.tfplan`
- SSH keys
- `kube_config.yaml`

The checked-in `variables.tf.example` file should contain only public-safe placeholder values.
