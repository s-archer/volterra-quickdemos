data "terraform_remote_state" "proxmox" {
  backend = "local"
  config = {
    path = "../terraform.tfstate"
  }
}

terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = ">= 0.11.43"
    }
  }
}

provider "volterra" {
  url          = local.f5xc_api_url
  api_p12_file = var.f5xc_api_p12_file
}