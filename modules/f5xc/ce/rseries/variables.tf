variable "status_check_type" {
  type    = string
  default = "token"
  validation {
    condition = contains(["token", "cert"], var.status_check_type)
    error_message = format("Valid values for status_check_type: token or cert")
  }
}

variable "is_sensitive" {
  type        = bool
  default     = false
  description = "Whether to mask sensitive data in output or not"
}

variable "wait_for_online" {
  type        = bool
  default     = true
  description = "enable wait_for_online status check. This will wait till CE fully operational"
}

variable "f5os_tenant" {
  type = string
}

variable "f5os_tenant_config_type" {
  type    = string
  default = "GENERIC"
}

variable "f5os_tenant_config_nodes" {
  type = list(number)
}

variable "f5os_tenant_config_image" {
  type = string
}

variable "f5os_tenant_config_dag_ipv6_prefix_length" {
  type    = number
  default = 128
}

variable "f5os_tenant_config_dhcp_enabled" {
  type    = bool
  default = true
}

variable "f5os_tenant_config_vlans" {
  type = list(number)
}

variable "f5os_tenant_config_vcpu_cores_per_node" {
  type = number
}

variable "f5os_tenant_config_memory" {
  type    = number
  default = 0
}

variable "f5os_tenant_config_storage_size" {
  type = number
}

variable "f5os_tenant_config_l2_inline_mac_block_size" {
  type    = string
  default = "small"
}

variable "f5os_tenant_config_running_state" {
  type    = string
  default = "deployed"
}

variable "f5os_tenant_config_cryptos" {
  type    = string
  default = "enabled"
}

variable "f5os_tenant_config_metadata" {
  type = list(string)
}

variable "f5os_tenant_base_uri" {
  type    = string
  default = "/f5-tenants:tenants"
}

variable "f5os_tenant_delete_path" {
  type    = string
  default = "/tenant="
}

variable "f5xc_api_schema" {
  type    = string
  default = "https"
}

variable "f5xc_namespace" {
  type = string
}

variable "f5xc_api_url" {
  type = string
}

variable "f5xc_api_token" {
  type = string
}

variable "f5xc_site_name" {
  type = string
}

variable "f5xc_sms_provider_name" {
  type = string
}

variable "f5xc_sms_master_nodes_count" {
  type = number
}

variable "f5xc_sms_perf_mode_l7_enhanced" {
  type = bool
}

variable "f5xc_tenant" {
  description = "F5 XC tenant"
  type        = string
}

variable "f5xc_api_p12_file" {
  description = "F5 XC api ca cert"
  type        = string
  default     = ""
}

variable "f5xc_api_p12_cert_password" {
  description = "XC API cert file password used later in status module to retrieve site status"
  type        = string
  default     = ""
}

variable "f5xc_sms_labels" {
  type = map(string)
  default = {}
}

variable "f5xc_dc_cluster_group_slo_name" {
  type    = string
  default = null
}

variable "f5xc_dc_cluster_group_sli_name" {
  type    = string
  default = null
}

variable "f5xc_ce_gw_type" {
  type = string
}

variable "f5xc_ce_gateway_type_ingress_egress" {
  type    = string
  default = "ingress_egress_gateway"
}

variable "f5xc_ce_interface_list" {
  type = list(object({
    mtu           = string
    name          = string
    labels        = map(string)
    monitor       = optional(string, "Disabled")
    priority      = number
    is_primary    = bool
    dhcp_client   = bool
    description   = string
    is_management = bool
    network_option = object({
      site_local_inside_network = bool
    })
    vlan_interface = object({
      device  = string
      vlan_id = string
    })
  }))
  default = []
}