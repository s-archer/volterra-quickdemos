variable "f5xc_api_url" {
  type        = string
  description = "F5 XC tenant API URL."
  default     = "https://example.console.ves.volterra.io/api"
}

variable "f5xc_api_p12_file" {
  type        = string
  description = "Path to the local F5 XC API certificate."
  default     = "../../../../creds/example.console.ves.volterra.io.api-creds.p12"
}

variable "f5xc_tenant" {
  type        = string
  description = "Full F5 XC tenant name used in object references."
  default     = "example-tenant"
}

variable "f5xc_namespace" {
  type        = string
  description = "F5 XC namespace for the load balancer and origin pools."
  default     = "example-namespace"
}

variable "lb_name" {
  type        = string
  description = "Name of the Regional Edge HTTP load balancer."
  default     = "tailscale-nginxs"
}

variable "lb_domains" {
  type        = list(string)
  description = "Domains served by the Regional Edge load balancer."
  default     = ["tailscale.example.com"]
}

variable "app_firewall_name" {
  type        = string
  description = "Existing app firewall name to attach to the load balancer."
  default     = "example-waf"
}

variable "app_firewall_namespace" {
  type        = string
  description = "Namespace containing the app firewall."
  default     = "shared"
}

variable "healthcheck_name" {
  type        = string
  description = "Existing HTTP healthcheck to attach to both origin pools."
  default     = "arch-http-generic"
}

variable "healthcheck_namespace" {
  type        = string
  description = "Namespace containing the healthcheck."
  default     = "example-namespace"
}

variable "tailscale_tailnet" {
  type        = string
  description = "Tailscale tailnet ID/name. Use '-' to use the default tailnet from the Tailscale credential."
  default     = "-"
}

variable "enable_tailscale_device_lookup" {
  type        = bool
  description = "Resolve NGINX Tailscale IPs from Tailscale device hostnames."
  default     = true
}

variable "enable_aws_remote_state" {
  type        = bool
  description = "Read AWS CE site name from the AWS infra-deploy terraform state."
  default     = false
}

variable "enable_azure_remote_state" {
  type        = bool
  description = "Read Azure CE site name from the Azure infra-deploy terraform state."
  default     = false
}

variable "aws_remote_state_path" {
  type        = string
  description = "Path to the AWS infra-deploy terraform.tfstate file."
  default     = "../../aws/aws_smsv2_site_volterra_provider/infra-deploy/terraform.tfstate"
}

variable "azure_remote_state_path" {
  type        = string
  description = "Path to the Azure infra-deploy terraform.tfstate file."
  default     = "../../azure/azure_smsv2_volterra_provider/infra-deploy/terraform.tfstate"
}

variable "aws_site_name" {
  type        = string
  description = "Optional explicit AWS CE site name. Used when enable_aws_remote_state is false."
  default     = ""
}

variable "azure_site_name" {
  type        = string
  description = "Optional explicit Azure CE site name. Used when enable_azure_remote_state is false."
  default     = ""
}

variable "aws_nginx_tailnet_ips" {
  type        = list(string)
  description = "Fallback Tailscale IPv4 addresses for the AWS NGINX instances when Tailscale device lookup is disabled."
  default     = []
}

variable "azure_nginx_tailnet_ips" {
  type        = list(string)
  description = "Fallback Tailscale IPv4 addresses for the Azure NGINX instances when Tailscale device lookup is disabled."
  default     = []
}

variable "aws_nginx_tailnet_hostnames" {
  type        = list(string)
  description = "Fallback AWS NGINX Tailscale hostnames when AWS remote state is disabled."
  default     = []
}

variable "azure_nginx_tailnet_hostnames" {
  type        = list(string)
  description = "Fallback Azure NGINX Tailscale hostnames when Azure remote state is disabled."
  default     = []
}
