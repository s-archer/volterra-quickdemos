data "terraform_remote_state" "eks" {
  backend = "local"
  config = {
    path = "../infra-deploy/terraform.tfstate"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.97.0"
    }
    volterra = {
      source  = "volterraedge/volterra"
      version = "0.11.46"
    }
  }
}

provider "volterra" {
  api_p12_file = var.f5xc_api_p12_file
  url          = var.f5xc_api_url
}

provider "aws" {
  #shared_credentials_file = "~/.aws/credentials"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "default"
  region                   = var.region
}
