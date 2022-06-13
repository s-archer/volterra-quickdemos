variable "subnet" {
  description = "supplied by module parent"
  default     = ""
}
variable "security_groups" {
  description = "supplied by module parent"
  default     = []
}
variable "key_name" {
  description = "supplied by module parent"
  default     = ""
}
variable "prefix" {
  description = "supplied by module parent"
  default     = ""
}

variable "volt_ip" {
  description = "supplied by module parent"
  default     = ""
}

variable "uk_se" {
  description = "UK SE name tag"
  default     = ""
}