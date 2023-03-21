locals {
  azs = [
    for each_az in var.azs_short : format("%s%s", var.region, each_az)
  ]
}

variable "region" {
  description = "AWS region name"
  default     = "eu-central-1"
}

variable "azs_short" {
  description = "Assumes three AZs within region.  Locals below will format the full AZ names based on Region"
  default     = ["a", "b", "c"]
}

variable "cidr" {
  description = "cidr used for AWS VPC"
  default     = "10.0.0.0/16"
}

variable "prefix" {
  description = "prefix used for naming objects created in AWS"
  default     = "arch-tf-eks-"
}

variable "uk_se_name" {
  description = "UK SE name tag"
  default     = "s.archer@f5.com"
}

variable "volterra_namespace_exists" {
  type        = string
  description = "Flag to create or use existing volterra namespace"
  default     = true
}

variable "volterra_namespace" {
  type        = string
  description = "Volterra app namespace where the object will be created. This cannot be system or shared ns."
  #default     = "s-archer"
  default     = "s-archer"
  
}

variable "site_name" {
  type        = string
  description = "Name of site to be created in Volterra and AWS"
  default     = "aws-site"
}

variable "base" {
  default = "eks"
}

variable "cloud_cred_name" {
  type        = string
  description = "The object name for your cloud credentials witin Volterra"
  default     = "arch-aws-corp"
}

variable "volt_tenant" {
  type        = string
  description = "Volterra tenant name"
  #default     = "f5-emea-ent-bceuutam"
  default     = "f5-spda-emea"
}

variable "volt_api_url" {
  type        = string
  description = "Volterra tenant api url"
  # default     = "https://f5-emea-ent.console.ves.volterra.io/api"
  default     = "https://f5-spda-emea.console.ves.volterra.io/api"
}

variable "volt_api_p12_file" {
  type        = string
  description = "Volterra tenant api key"
  # default     = "../../creds/f5-emea-ent.console.ves.volterra.io.api-creds.p12"
  default     = "../../../creds/f5-spda-emea.console.ves.volterra.io.api-creds.p12"
}

variable "sa_name" {
  default = "f5xc"
}