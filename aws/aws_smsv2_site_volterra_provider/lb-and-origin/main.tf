data "terraform_remote_state" "eks" {
  backend = "local"
  config = {
    path = "../infra-deploy/terraform.tfstate"
  }
}

terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = "0.11.19"
    }
  }
}

provider "volterra" {
  api_p12_file = var.f5xc_api_p12_file
  url          = var.f5xc_api_url
}