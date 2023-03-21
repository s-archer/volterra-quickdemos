variable "volt_api_url" {
  type        = string
  description = "Volterra tenant api url"
  # default     = "https://f5-emea-ent.console.ves.volterra.io/api"
  default = "https://f5-spda-emea.console.ves.volterra.io/api"
}

variable "volt_api_p12_file" {
  type        = string
  description = "Volterra tenant api key"
  # default     = "../../creds/f5-emea-ent.console.ves.volterra.io.api-creds.p12"
  default = "../../../creds/f5-spda-emea.console.ves.volterra.io.api-creds.p12"
}