# volterra-quickdemos

Terraform examples and demo environments for F5 Distributed Cloud, cloud sites, load balancers, service discovery, and related lab infrastructure.

Each top-level cloud folder is intentionally self-contained. Most demos are independent Terraform deployments, so review the README in the specific folder before applying anything.

## Repository Layout

- `aws/` - AWS demos, including Secure Mesh Site v2, EKS, Linux origins, and BIG-IP examples.
- `azure/` - Azure demos, including Secure Mesh Site v2, AKS, Linux origins, and optional load-balancer components.
- `gcp/` - GCP site and GKE examples.
- `lb-automation/` - F5 Distributed Cloud load-balancer automation examples.
- `modules/` - Shared Terraform modules used by selected demos.
- `proxmox/` - Home/lab Proxmox site examples.
- `re_lb_with_dns_origin/` - Regional edge load-balancer examples using DNS origins.

## Current SMS v2 Reference Builds

The most actively maintained Secure Mesh Site v2 examples are:

- AWS: `aws/aws_smsv2_site_volterra_provider`
- Azure: `azure/azure_smsv2_volterra_provider/infra-deploy`

These deploy a cloud CE, Kubernetes cluster, Tailscale-enabled Linux NGINX servers, a Tailscale subnet router, and XC objects for service discovery and Tailscale/IPsec/BGP connectivity.

## Local Credentials

Do not commit real credentials, generated state, SSH keys, kubeconfigs, or Terraform plan files. The repo `.gitignore` is set up to ignore the usual local files, including:

- `variables.tf`
- `*.tfvars`
- `*.tfstate`
- `*.pem`
- `kubeconfig.yaml`
- `kube_config.yaml`
- Terraform plan files should also stay local.

Use the checked-in `variables.tf.example` files as public-safe templates, then keep real values in ignored `variables.tf` or an external credentials `.tfvars` file.

## General Workflow

For each Terraform deployment:

```bash
cd <demo-folder>
cp variables.tf.example variables.tf
terraform init
terraform validate
terraform plan
terraform apply
```

Many configs also expect an XC API certificate passphrase:

```bash
export VES_P12_PASSWORD='<p12-passphrase>'
```

Provider credentials and Tailscale auth keys should be supplied from local files outside the repo where possible.

## Notes

- F5 Distributed Cloud CE names cannot normally be reused after deletion, for 30 days. When deploying a CE, terraform generates a `random_id` which is used for the CE site name, node name, and token name.  If destroying and creating a new CE, please ensure that you also destroy the `random_id` and any dependent objects.
- The cloud-specific README files include the safest redeploy approach for the AWS and Azure SMS v2 demos.
- Run `terraform validate` before committing changes to any Terraform config.
