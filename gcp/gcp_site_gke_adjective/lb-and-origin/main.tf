data "terraform_remote_state" "gke" {
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
  api_p12_file = var.volt_api_p12_file
  url          = var.volt_api_url
}