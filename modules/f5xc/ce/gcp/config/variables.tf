variable "cluster_type" {
  type    = string
  default = "ce"
}

variable "maurice_endpoint" {
  type = string
}

variable "maurice_mtls_endpoint" {
  type = string
}

variable "f5xc_ce_gateway_type" {
  type = string
}

variable "f5xc_cluster_latitude" {
  type = string
}

variable "f5xc_cluster_longitude" {
  type = string
}

variable "f5xc_ce_hosts_public_name" {
  type    = string
}

variable "f5xc_ce_http_proxy" {
  type    = string
  default = ""
}

variable "f5xc_ce_https_proxy" {
  type    = string
  default = ""
}

variable "f5xc_ce_no_proxy" {
  type = list(string)
  default = ["10.0.0.0/8","172.16.0.0/12","192.168.0.0/16","100.127.0.0/18","100.127.192.0/18","169.254.0.0/16","int.ves.io","localhost"]
}

variable "slo_nic" {
  type    = string
  default = "eth0"
}

variable "private_network_name" {
  default = ""
}

variable "f5xc_ce_hosts_public_address" {
  type    = string
}

variable "certified_hardware_endpoint" {
  type    = string
  default = "https://vesio.blob.core.windows.net/releases/certified-hardware/gcp.yml"
}

variable "cluster_name" {
  type = string
}

variable "cluster_token" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "cluster_labels" {
  type = map(string)
}