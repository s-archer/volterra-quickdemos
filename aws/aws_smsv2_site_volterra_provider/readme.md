# AWS Secure Mesh Site v2 Demo

This folder contains the AWS F5 Distributed Cloud Secure Mesh Site v2 demo. The main deployment is in `infra-deploy`.

## What It Deploys

`infra-deploy` creates:

- AWS VPC, subnets, route tables, security groups, and SSH key resources.
- F5 Distributed Cloud CE EC2 instance using Secure Mesh Site v2.
- EKS cluster and XC Kubernetes service discovery objects.
- Tailscale-enabled Linux NGINX servers.
- Dedicated Tailscale subnet-router EC2 instance.
- Route-based IPsec from the Tailscale subnet router to the CE.
- XC external connector and BGP configuration for the Tailscale/IPsec path.

Additional folders layer application and publishing workflows on top of `infra-deploy`:

- `big-ip-deploy` - BIG-IP and NGINX origin examples.
- `helm` - Helm deployment for microservice apps into EKS/AKS.
- `lb-and-origin` - XC load-balancer and origin objects that expose the Helm-deployed app.

## File Layout

The active AWS Terraform files are grouped by ownership:

- `aws-network-core.tf` - VPC, subnets, route tables, and cloud networking.
- `aws-security-groups.tf` - Security group rules in one place.
- `aws-compute-common.tf` - Shared compute data and locals.
- `aws-tailscale-nginx-vms.tf` - Linux NGINX origin servers that join Tailscale.
- `aws-tailscale-subnet-router.tf` - Dedicated Tailscale subnet router EC2 instance.
- `xc-aws-smsv2.tf` - XC Secure Mesh Site v2 and CE EC2 resources.
- `xc-bgp-tailscale.tf` - XC external connector and BGP peer for the subnet router.
- `xc-k8s-service-discovery.tf` - Kubernetes and XC discovery objects.
- `outputs-*.tf` - Outputs split by topic.
- `templates/` - Cloud-init/user-data templates.

## Credentials And Variables

Copy the example variables file and keep real values local:

```bash
cd infra-deploy
cp variables.tf.example variables.tf
```

`variables.tf` is ignored by Git. Put real AWS/XC/Tailscale-specific values there or in a private `.tfvars` file.

Set the XC API certificate passphrase before running Terraform:

```bash
export VES_P12_PASSWORD='<p12-passphrase>'
```

Important variables:

- `f5xc_api_url` and `f5xc_api_p12_file` - XC tenant API endpoint and local certificate path.
- `f5xc_tenant` - XC tenant name used in generated XC references.
- `f5xc_ami` - CE AMI name pattern copied from the XC UI.
- `tailscale_auth_key` - reusable ephemeral Tailscale auth key.
- `tailscale_tag` - subnet-router tag, default `tsr-aws`.
- `local_tailnet_routes` - routes exported from FRR/BGP to the CE, default `100.64.0.0/16`.
- `remote_tailnet_routes` - routes advertised by Tailscale into this tailnet, default includes the Azure tailnet and tunnel/VPC ranges.

## Deploy

```bash
cd aws/aws_smsv2_site_volterra_provider/infra-deploy
terraform init
terraform validate
terraform plan
terraform apply
```

If you keep credentials outside the repo:

```bash
terraform apply -var-file=../../../../creds/aws_creds.tfvars
```

## Redeploying The CE

XC CE names cannot be reused for 30 days after deletion. If rebuilding the CE, generate a new `random_id` so the CE site name, EC2 hostname, and XC token are recreated together.

Use targeted replacement for the minimum destructive change, then review the full plan:

```bash
terraform plan \
  -replace=random_id.id \
  -replace=volterra_token.smsv2-token[0] \
  -replace=aws_instance.xc[0] \
  -replace=volterra_securemesh_site_v2.site[0]
```

Only apply once the plan shows the intended CE-related replacements. Avoid manually deleting cloud objects unless Terraform state has already drifted and you are deliberately repairing it.

## Tailscale, IPsec, And BGP

The subnet-router user-data configures:

- Tailscale with an auth key and `tag:tsr-aws`.
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
- `ssh-key.pem`
- `kubeconfig.yaml`

The checked-in `variables.tf.example` file should contain only public-safe placeholder values.
