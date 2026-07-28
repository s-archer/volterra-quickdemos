# Tailscale Regional Edge Load Balancer

This Terraform layer creates a public F5 Distributed Cloud Regional Edge HTTP load balancer for NGINX instances that are reachable over Tailscale.

It creates:

- `tailnet-nginx-aws` origin pool for AWS NGINX Tailscale IPs.
- `tailnet-nginx-azure` origin pool for Azure NGINX Tailscale IPs.
- `tailscale-nginxs` HTTPS load balancer on the public default VIP.

The AWS and Azure environments can be deployed in either order. Enable remote state only for the environment that already exists. The layer reads the NGINX Tailscale hostnames from remote state and resolves the current `100.x` addresses with the Tailscale Terraform provider.

## How Tailscale IPs Are Found

The NGINX Tailscale IPs are assigned by Tailscale after first boot. They are not Azure or AWS resource attributes, so the cloud providers cannot output them directly.

This layer uses two pieces of information:

- CE site names from `infra-deploy` remote state.
- NGINX Tailscale hostnames from `infra-deploy` remote state.

Then the `tailscale_device` data source resolves each hostname to the current Tailscale IPv4 address. After destroying and recreating AWS or Azure, re-apply that cloud's `infra-deploy`, wait for the NGINX VMs to join Tailscale, then re-apply this layer.

You need Tailscale provider credentials in your environment, for example:

```bash
export TAILSCALE_OAUTH_CLIENT_ID='<oauth-client-id>'
export TAILSCALE_OAUTH_CLIENT_SECRET='<oauth-client-secret>'
export TAILSCALE_TAILNET='-'
```

An API key also works via `TAILSCALE_API_KEY`, but Tailscale recommends OAuth/trust credentials for automation.

## Usage

```bash
cd lb-deployments/tailscale-lb
cp terraform.tfvars.example terraform.tfvars
export VES_P12_PASSWORD='<p12-passphrase>'
export TAILSCALE_TAILNET='-'
terraform init
terraform validate
terraform plan
terraform apply
```

For AWS only:

```hcl
enable_aws_remote_state   = true
enable_azure_remote_state = false

enable_tailscale_device_lookup = true
```

For Azure only:

```hcl
enable_aws_remote_state   = false
enable_azure_remote_state = true

enable_tailscale_device_lookup = true
```

For both clouds, enable both remote states and provide both IP lists.

## Remote State Contract

This layer reads:

- AWS site name from `aws/aws_smsv2_site_volterra_provider/infra-deploy` output `site-name`.
- AWS NGINX Tailscale hostnames from output `nginx-tailnet-hostnames`.
- Azure site name from `azure/azure_smsv2_volterra_provider/infra-deploy` output `azure-site-name`.
- Azure NGINX Tailscale hostnames from output `nginx-tailnet-hostnames`.

If you do not want to read remote state, set `enable_aws_remote_state` or `enable_azure_remote_state` to `false` and provide `aws_site_name` or `azure_site_name` plus `aws_nginx_tailnet_hostnames` or `azure_nginx_tailnet_hostnames` explicitly.

If you need to bypass Tailscale lookup, set `enable_tailscale_device_lookup = false` and provide `aws_nginx_tailnet_ips` or `azure_nginx_tailnet_ips` manually.
